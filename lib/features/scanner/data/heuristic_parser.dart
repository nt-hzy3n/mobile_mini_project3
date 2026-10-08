class ParsedPaymentData {
  final double? amount;
  final String? merchant; // recipient / merchant
  final DateTime? date;
  final String? time; // e.g. '17:53'
  final String? bankName; // e.g. 'MBBank'
  final String? bankCode; // e.g. 'MB'
  final String? accountNumber; // e.g. '41212106082002'
  final String? note; // transfer description / note
  final String? rawText;

  const ParsedPaymentData({
    this.amount,
    this.merchant,
    this.date,
    this.time,
    this.bankName,
    this.bankCode,
    this.accountNumber,
    this.note,
    this.rawText,
  });

  @override
  String toString() {
    return 'ParsedPaymentData(amount: $amount, merchant: $merchant, date: $date, time: $time, bank: $bankName, acc: $accountNumber, note: $note)';
  }
}

class HeuristicParser {
  /// Keywords ưu tiên tìm số tiền
  static final _amountPrefixPattern = RegExp(
    r'(?:tổng\s*tiền|tổng\s*cộng|thành\s*tiền|số\s*tiền|thanh\s*toán|chuyển\s*tiền|chuyển\s*khoản|total\s*amount|total|amount|payment|grand\s*total)[\s:=-]*([0-9.,\s]+(?:\s*(?:vnd|vnđ|đ|d))?)',
    caseSensitive: false,
  );

  /// Pattern tìm số tiền kèm đơn vị tiền tệ ở bất kỳ vị trí nào
  static final _currencyAmountPattern = RegExp(
    r'(\b\d{1,3}(?:[.,]\d{3})+(?:\s*(?:vnd|vnđ|đ))|\b\d{4,9}\s*(?:vnd|vnđ|đ))',
    caseSensitive: false,
  );

  /// Pattern tìm ngày tháng DD/MM/YYYY, DD-MM-YYYY hoặc DD.MM.YYYY
  static final _datePattern = RegExp(
    r'\b(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})\b|\b(\d{4})[/.-](\d{1,2})[/.-](\d{1,2})\b',
  );

  /// Pattern tìm thời gian HH:mm hoặc HH:mm:ss
  static final _timePattern = RegExp(
    r'\b([01]?\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?\b',
  );

  /// Các từ khóa loại trừ khi nhận diện Người nhận / Merchant
  static final _merchantBlacklist = RegExp(
    r'(chuyển\s*tiền\s*thành\s*công|giao\s*dịch\s*thành\s*công|thanh\s*toán\s*thành\s*công|tổng\s*cộng|tổng\s*tiền|thành\s*tiền|số\s*tiền|thanh\s*toán|hóa\s*đơn|phiếu\s*thu|biên\s*lai|receipt|invoice|bill|payment|qr\s*code|vietqr|momo|zalopay|vnpay|ngân\s*hàng|bank|ngày|date|time|giờ|thời\s*gian|ngày\s*giao\s*dịch|stk|số\s*tài\s*khoản|chuyển\s*khoản|giao\s*dịch|transaction|mã\s*gd|mã\s*giao\s*dịch|ref|id|cảm\s*ơn|thank\s*you|vat|thuế|vnd|vnđ|thành\s*công|tài\s*khoản\s*nguồn|tài\s*khoản\s*trích\s*nợ|người\s*chuyển)',
    caseSensitive: false,
  );

  /// Danh sách các ngân hàng phổ biến tại Việt Nam
  static final List<_BankRule> _knownBanks = [
    _BankRule(
      'MBBank',
      'MB',
      RegExp(
        r'\b(mbbank|ngân hàng quân đội|mb bank|\bmb\b)',
        caseSensitive: false,
      ),
    ),
    _BankRule(
      'Vietcombank',
      'VCB',
      RegExp(r'\b(vietcombank|vcb|ngoại thương)', caseSensitive: false),
    ),
    _BankRule(
      'VietinBank',
      'CTG',
      RegExp(r'\b(vietinbank|vietin bank|công thương)', caseSensitive: false),
    ),
    _BankRule(
      'BIDV',
      'BIDV',
      RegExp(r'\b(bidv|đầu tư và phát triển)', caseSensitive: false),
    ),
    _BankRule(
      'Techcombank',
      'TCB',
      RegExp(r'\b(techcombank|tcb|kỹ thương)', caseSensitive: false),
    ),
    _BankRule('ACB', 'ACB', RegExp(r'\b(acb|á châu)', caseSensitive: false)),
    _BankRule(
      'VPBank',
      'VPB',
      RegExp(r'\b(vpbank|vpb|việt nam thịnh vượng)', caseSensitive: false),
    ),
    _BankRule(
      'TPBank',
      'TPB',
      RegExp(r'\b(tpbank|tpb|tiên phong)', caseSensitive: false),
    ),
    _BankRule(
      'Agribank',
      'VBA',
      RegExp(r'\b(agribank|nông nghiệp)', caseSensitive: false),
    ),
    _BankRule(
      'Sacombank',
      'STB',
      RegExp(r'\b(sacombank|sài gòn thương tín)', caseSensitive: false),
    ),
    _BankRule('VIB', 'VIB', RegExp(r'\b(vib|quốc tế)', caseSensitive: false)),
    _BankRule(
      'HDBank',
      'HDB',
      RegExp(r'\b(hdbank|phát triển tp\.?hcm)', caseSensitive: false),
    ),
    _BankRule(
      'SHB',
      'SHB',
      RegExp(r'\b(shb|sài gòn - hà nội)', caseSensitive: false),
    ),
    _BankRule('MSB', 'MSB', RegExp(r'\b(msb|hàng hải)', caseSensitive: false)),
    _BankRule(
      'OCB',
      'OCB',
      RegExp(r'\b(ocb|phương đông)', caseSensitive: false),
    ),
    _BankRule(
      'SeABank',
      'SSB',
      RegExp(r'\b(seabank|đông nam á)', caseSensitive: false),
    ),
    _BankRule(
      'LPBank',
      'LPB',
      RegExp(r'\b(lpbank|lộc phát|bưu điện liên việt)', caseSensitive: false),
    ),
    _BankRule(
      'Eximbank',
      'EIB',
      RegExp(r'\b(eximbank|xuất nhập khẩu)', caseSensitive: false),
    ),
    _BankRule(
      'Nam A Bank',
      'NAB',
      RegExp(r'\b(nam a bank|nam á)', caseSensitive: false),
    ),
    _BankRule(
      'VietCapitalBank',
      'BVBank',
      RegExp(r'\b(bản việt|bvbank)', caseSensitive: false),
    ),
  ];

  static ParsedPaymentData parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const ParsedPaymentData();
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final amount = extractAmount(rawText, lines);
    final date = extractDate(rawText);
    final time = extractTime(rawText);
    final (bankName, bankCode) = extractBank(rawText, lines);
    final accountNumber = extractAccountNumber(rawText, lines, amount);
    final merchant = extractRecipient(lines, bankName, accountNumber);
    final note = extractNote(lines, merchant, bankName);

    return ParsedPaymentData(
      amount: amount,
      merchant: merchant,
      date: date,
      time: time,
      bankName: bankName,
      bankCode: bankCode,
      accountNumber: accountNumber,
      note: note,
      rawText: rawText,
    );
  }

  /// Trích xuất số tiền
  static double? extractAmount(String rawText, List<String> lines) {
    // 1. Tìm theo từ khóa ưu tiên (TỔNG TIỀN, THÀNH TIỀN, TOTAL, SỐ TIỀN, CHUYỂN TIỀN...)
    final prefixMatch = _amountPrefixPattern.firstMatch(rawText);
    if (prefixMatch != null) {
      final valueStr = prefixMatch.group(1);
      if (valueStr != null) {
        final parsed = normalizeAmount(valueStr);
        if (parsed != null && parsed > 0 && parsed <= 5000000000) return parsed;
      }
    }

    // 2. Tìm theo đơn vị tiền tệ rõ ràng (vd: 1,000,000 VND, 1.000.000 đ)
    final currencyMatches = _currencyAmountPattern.allMatches(rawText);
    for (final match in currencyMatches) {
      final text = match.group(0);
      if (text != null) {
        final parsed = normalizeAmount(text);
        if (parsed != null && parsed > 0 && parsed <= 5000000000) return parsed;
      }
    }

    // 3. Quét từng dòng tìm số lượng có phân cách hàng nghìn (1,000,000 hoặc 1.000.000)
    for (final line in lines) {
      // Bỏ qua dòng là số tài khoản hoặc ngày tháng
      if (_isAccountNumberLine(line) || _datePattern.hasMatch(line)) continue;

      final match = RegExp(r'\b\d{1,3}(?:[.,]\d{3})+\b').firstMatch(line);
      if (match != null) {
        final parsed = normalizeAmount(match.group(0)!);
        if (parsed != null && parsed >= 1000 && parsed <= 5000000000) {
          return parsed;
        }
      }
    }

    // 4. Quét số nguyên thuần (từ 5 đến 9 chữ số, ví dụ 1000000)
    for (final line in lines) {
      if (_isAccountNumberLine(line) || _datePattern.hasMatch(line)) continue;
      final match = RegExp(r'\b\d{5,9}\b').firstMatch(line);
      if (match != null) {
        final parsed = double.tryParse(match.group(0)!);
        if (parsed != null && parsed >= 1000 && parsed <= 5000000000) {
          return parsed;
        }
      }
    }

    return null;
  }

  /// Chuẩn hóa số tiền từ chuỗi có dấu chấm/phẩy/khoảng trắng
  static double? normalizeAmount(String text) {
    var clean = text
        .replaceAll(RegExp(r'(?:vnd|vnđ|đ|d)', caseSensitive: false), '')
        .trim();

    // Xử lý khoảng cách giữa các số: 1 000 000 -> 1000000
    clean = clean.replaceAll(' ', '');

    // Kiểm tra định dạng có cả dấu chấm và phẩy: vd 1,500.00 hoặc 1.500,00
    if (clean.contains('.') && clean.contains(',')) {
      if (clean.lastIndexOf('.') > clean.lastIndexOf(',')) {
        // Dấu chấm là thập phân: 1,500.00
        clean = clean.replaceAll(',', '');
      } else {
        // Dấu phẩy là thập phân: 1.500,00
        clean = clean.replaceAll('.', '').replaceAll(',', '.');
      }
    } else if (clean.contains('.')) {
      // 1.000.000 (phân cách hàng nghìn)
      final parts = clean.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        clean = clean.replaceAll('.', '');
      }
    } else if (clean.contains(',')) {
      // 1,000,000 (phân cách hàng nghìn)
      final parts = clean.split(',');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length == 3)) {
        clean = clean.replaceAll(',', '');
      } else {
        clean = clean.replaceAll(',', '.');
      }
    }

    return double.tryParse(clean);
  }

  /// Trích xuất ngày giao dịch (DD/MM/YYYY, DD-MM-YYYY hoặc YYYY-MM-DD)
  static DateTime? extractDate(String rawText) {
    final match = _datePattern.firstMatch(rawText);
    if (match != null) {
      if (match.group(1) != null) {
        // DD/MM/YYYY
        final day = int.tryParse(match.group(1)!);
        final month = int.tryParse(match.group(2)!);
        final year = int.tryParse(match.group(3)!);
        if (day != null && month != null && year != null) {
          if (day >= 1 &&
              day <= 31 &&
              month >= 1 &&
              month <= 12 &&
              year >= 2000) {
            return DateTime(year, month, day);
          }
        }
      } else if (match.group(4) != null) {
        // YYYY-MM-DD
        final year = int.tryParse(match.group(4)!);
        final month = int.tryParse(match.group(5)!);
        final day = int.tryParse(match.group(6)!);
        if (day != null && month != null && year != null) {
          if (day >= 1 &&
              day <= 31 &&
              month >= 1 &&
              month <= 12 &&
              year >= 2000) {
            return DateTime(year, month, day);
          }
        }
      }
    }
    return null;
  }

  /// Trích xuất thời gian giao dịch HH:mm (ví dụ: '17:53' từ '17:53 - 28/09/2026')
  static String? extractTime(String rawText) {
    final match = _timePattern.firstMatch(rawText);
    if (match != null) {
      final hour = match.group(1)?.padLeft(2, '0');
      final minute = match.group(2);
      if (hour != null && minute != null) {
        return '$hour:$minute';
      }
    }
    return null;
  }

  /// Trích xuất thông tin Ngân hàng thụ hưởng
  static (String?, String?) extractBank(String rawText, List<String> lines) {
    // 1. Kiểm tra từng ngân hàng trong danh mục chuẩn
    for (final bank in _knownBanks) {
      if (bank.pattern.hasMatch(rawText)) {
        return (bank.name, bank.code);
      }
    }

    // 2. Kiểm tra dòng có chứa Bank hoặc Ngân hàng
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('ngân hàng') || lower.contains('bank')) {
        // Trích xuất mã viết tắt trong ngoặc nếu có: vd MBBank (MB) -> MBBank, MB
        final codeMatch = RegExp(r'\(([^)]+)\)').firstMatch(line);
        final code = codeMatch?.group(1);
        final name = line.replaceAll(RegExp(r'\([^)]+\)'), '').trim();
        if (name.isNotEmpty) {
          return (name, code);
        }
      }
    }

    return (null, null);
  }

  /// Trích xuất Số tài khoản thụ hưởng (8 - 18 chữ số)
  static String? extractAccountNumber(
    String rawText,
    List<String> lines,
    double? amount,
  ) {
    final amountIntStr = amount != null ? amount.toInt().toString() : '';

    // 1. Ưu tiên dòng có từ khóa STK / Số tài khoản
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('stk') ||
          lower.contains('số tài khoản') ||
          lower.contains('tài khoản nhận') ||
          lower.contains('tài khoản thụ hưởng') ||
          lower.contains('tài khoản')) {
        final match = RegExp(r'\b\d{8,18}\b').firstMatch(line);
        if (match != null && match.group(0) != amountIntStr) {
          return match.group(0);
        }
      }
    }

    // 2. Tìm dãy số từ 8 đến 18 chữ số không phải số tiền
    for (final line in lines) {
      final match = RegExp(r'\b\d{8,18}\b').firstMatch(line);
      if (match != null) {
        final val = match.group(0)!;
        if (val != amountIntStr && !_datePattern.hasMatch(line)) {
          return val;
        }
      }
    }

    return null;
  }

  /// Trích xuất Người nhận / Cửa hàng
  static String? extractRecipient(
    List<String> lines,
    String? bankName,
    String? accountNumber,
  ) {
    // 1. Ưu tiên dòng theo sau các nhãn người nhận: "Người nhận", "Đến", "Tên người nhận", "Tài khoản nhận"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower == 'người nhận' ||
          lower == 'tên người nhận' ||
          lower == 'đến' ||
          lower == 'người thụ hưởng' ||
          lower == 'tài khoản thụ hưởng' ||
          lower.startsWith('người nhận:') ||
          lower.startsWith('đến:')) {
        // Nếu cùng dòng có dấu hai chấm: "Người nhận: NGUYEN THI THUONG"
        final parts = line.split(RegExp(r'[:=-]'));
        if (parts.length > 1 && parts[1].trim().length >= 3) {
          final candidate = parts[1].trim();
          if (!_isInvalidRecipient(candidate, bankName, accountNumber)) {
            return candidate;
          }
        }
        // Hoặc dòng tiếp theo
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (!_isInvalidRecipient(nextLine, bankName, accountNumber)) {
            return nextLine;
          }
        }
      }
    }

    // 2. Tìm dòng chữ in hoa tên người (VD: NGUYEN THI THUONG)
    for (final line in lines) {
      if (_isUppercaseName(line) &&
          !_isInvalidRecipient(line, bankName, accountNumber)) {
        return line;
      }
    }

    // 3. Fallback: Dòng đầu tiên hợp lệ không bị blacklist
    for (final line in lines) {
      if (line.length >= 3 &&
          line.length <= 60 &&
          !_merchantBlacklist.hasMatch(line) &&
          !_isInvalidRecipient(line, bankName, accountNumber)) {
        return line;
      }
    }

    return null;
  }

  /// Trích xuất Ghi chú / Nội dung chuyển khoản
  static String? extractNote(
    List<String> lines,
    String? recipient,
    String? bankName,
  ) {
    // 1. Dòng có từ khóa "nội dung", "lời nhắn", "note", "nội dung chuyển khoản"
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('nội dung') ||
          lower.contains('lời nhắn') ||
          lower.contains('ghi chú') ||
          lower.contains('description') ||
          lower.contains('note')) {
        final parts = line.split(RegExp(r'[:=-]'));
        if (parts.length > 1 && parts.sublist(1).join(':').trim().isNotEmpty) {
          return parts.sublist(1).join(':').trim();
        }
        if (i + 1 < lines.length) {
          final nextLine = lines[i + 1].trim();
          if (nextLine.isNotEmpty && !_merchantBlacklist.hasMatch(nextLine)) {
            return nextLine;
          }
        }
      }
    }

    // 2. Tìm dòng chứa cụm từ chuyển khoản phổ biến (vd: "chuyen tien", "thanh toan", "tien an", "ck")
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('chuyen tien') ||
          lower.contains('chuyển tiền') ||
          lower.contains('thanh toan') ||
          lower.contains('thanh toán') ||
          lower.contains('tien ') ||
          lower.contains('tiền ')) {
        if (line != recipient && !_merchantBlacklist.hasMatch(line)) {
          return line;
        }
      }
    }

    return null;
  }

  static bool _isAccountNumberLine(String line) {
    final lower = line.toLowerCase();
    return lower.contains('stk') ||
        lower.contains('số tài khoản') ||
        lower.contains('tài khoản');
  }

  static bool _isUppercaseName(String line) {
    if (line.length < 5 || line.length > 50) return false;
    // Kiểm tra có ít nhất 2 từ
    final words = line.trim().split(RegExp(r'\s+'));
    if (words.length < 2) return false;
    // Chỉ gồm chữ cái in hoa tiếng Việt hoặc tiếng Anh
    return RegExp(r'^[A-ZÀ-Ỹ\s]+$').hasMatch(line.trim());
  }

  static bool _isInvalidRecipient(
    String text,
    String? bankName,
    String? accountNumber,
  ) {
    if (text.length < 3) return true;
    if (_merchantBlacklist.hasMatch(text)) return true;
    if (accountNumber != null && text.contains(accountNumber)) return true;
    if (bankName != null &&
        text.toLowerCase().contains(bankName.toLowerCase())) {
      return true;
    }
    if (RegExp(r'^[\d\s.,:/-]+$').hasMatch(text)) return true;
    return false;
  }
}

class _BankRule {
  final String name;
  final String code;
  final RegExp pattern;

  _BankRule(this.name, this.code, this.pattern);
}
