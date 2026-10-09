import '../../../core/utils/currency_formatter.dart';
import '../models/qr_payment_data.dart';

/// Bộ phân tích TLV (Tag - Length - Value) chuẩn EMVCo QR Code
class EmvQrParser {
  /// Phân tích chuỗi EMVCo thành Map<String, String> cấp 1
  static Map<String, String> parseTlv(String raw) {
    final result = <String, String>{};
    int index = 0;

    while (index + 4 <= raw.length) {
      final tag = raw.substring(index, index + 2);
      final lengthStr = raw.substring(index + 2, index + 4);
      final length = int.tryParse(lengthStr);

      if (length == null || index + 4 + length > raw.length) {
        break;
      }

      final value = raw.substring(index + 4, index + 4 + length);
      result[tag] = value;
      index += 4 + length;
    }

    return result;
  }

  /// Phân tích sub-TLV lồng nhau (như Tag 38 hoặc Tag 62)
  static Map<String, String> parseSubTlv(String subRaw) {
    return parseTlv(subRaw);
  }
}

/// Parser chuyên biệt cho chuẩn VietQR / NAPAS247
class VietQrParser {
  static const Map<String, String> bankBinMap = {
    '970422': 'MBBank (Quân Đội)',
    '970415': 'VietinBank (Công Thương)',
    '970436': 'Vietcombank (Ngoại Thương)',
    '970405': 'Agribank (Nông Nghiệp)',
    '970407': 'Techcombank (Kỹ Thương)',
    '970418': 'BIDV (Đầu tư & Phát triển)',
    '970423': 'TPBank (Tiên Phong)',
    '970432': 'VPBank (Việt Nam Thịnh Vượng)',
    '970448': 'OCB (Phương Đông)',
    '970454': 'VietCapitalBank (Bản Việt)',
    '970429': 'SCB (Sài Gòn)',
    '970441': 'VIB (Quốc Tế)',
    '970403': 'Sacombank (Sài Gòn Thương Tín)',
    '970416': 'ACB (Á Châu)',
    '970437': 'HDBank (Phát triển TP.HCM)',
    '970443': 'SHB (Sài Gòn - Hà Nội)',
    '970452': 'Kienlongbank (Kiên Long)',
    '970449': 'LPBank (Lộc Phát)',
    '970431': 'Eximbank (Xuất Nhập Khẩu)',
    '970426': 'MSB (Hàng Hải)',
    '970428': 'Nam A Bank (Nam Á)',
    '970430': 'PGBank (Xăng Dầu Petrolimex)',
    '970438': 'BaoVietBank (Bảo Việt)',
    '970414': 'OceanBank (Đại Dương)',
    '970425': 'ABBANK (An Bình)',
    '970427': 'VietABank (Việt Á)',
    '970433': 'VietBank (Việt Nam Thương Tín)',
    '970400': 'SaigonBank (Sài Gòn Công Thương)',
    '970440': 'SeABank (Đông Nam Á)',
    '970408': 'GPBank (Dầu Khí Toàn Cầu)',
  };

  /// Phân tích dữ liệu VietQR dạng EMVCo Tag 38
  static QrPaymentData? parseVietQrEmv(String raw, Map<String, String> tags) {
    // Tag 38 chứa thông tin người thụ hưởng NAPAS
    final tag38 = tags['38'];
    if (tag38 == null) return null;

    final sub38 = EmvQrParser.parseSubTlv(tag38);
    final guid = sub38['00']; // Phải là A000000727 cho NAPAS
    if (guid != null && !guid.contains('A000000727')) {
      // Vẫn có thể là tổ chức thanh toán khác theo EMV
    }

    String? bankBin;
    String? accountNumber;

    // Subtag 01 trong Tag 38 chứa thông tin ngân hàng & số tài khoản
    final beneficiaryInfo = sub38['01'];
    if (beneficiaryInfo != null) {
      final subBen = EmvQrParser.parseSubTlv(beneficiaryInfo);
      bankBin = subBen['00'];
      accountNumber = subBen['01'];
    }

    // Tag 54: Số tiền giao dịch (nếu có trong dynamic QR)
    double? amount;
    if (tags['54'] != null) {
      amount = double.tryParse(tags['54']!);
    }

    // Tag 59: Tên người thụ hưởng / Cửa hàng
    String? merchant = tags['59'];

    // Tag 62: Additional Data (Nội dung chuyển khoản, mã đơn)
    String? description;
    String? reference;
    if (tags['62'] != null) {
      final sub62 = EmvQrParser.parseSubTlv(tags['62']!);
      description = sub62['08']; // Purpose of transaction
      reference = sub62['05'] ?? sub62['01']; // Reference label or bill number
    }

    final bankName = bankBin != null
        ? bankBinMap[bankBin] ?? 'Ngân hàng ($bankBin)'
        : null;

    return QrPaymentData(
      rawPayload: raw,
      amount: amount,
      merchant: merchant,
      bankName: bankName,
      accountNumber: accountNumber,
      transactionDescription: description,
      transactionReference: reference,
      qrType: 'VietQR',
    );
  }

  /// Phân tích URL định dạng VietQR hoặc URL thanh toán
  static QrPaymentData? parseVietQrUrl(String raw) {
    try {
      final uri = Uri.parse(raw);
      if (!uri.hasScheme) return null;

      final query = uri.queryParameters;
      double? amount;
      if (query.containsKey('amount')) {
        amount = double.tryParse(query['amount']!);
      }

      String? merchant =
          query['accountName'] ?? query['merchant'] ?? query['receiver'];
      String? description = query['addInfo'] ?? query['note'] ?? query['desc'];
      String? accountNumber = query['accountNumber'] ?? query['acc'];
      String? bankName = query['bank'] ?? query['bankCode'];

      // Hỗ trợ link VietQR format: img.vietqr.io/image/<BANK>-<ACC>-...
      if (uri.host.contains('vietqr.io') && uri.pathSegments.length >= 2) {
        final segment = uri.pathSegments[1]; // ví dụ MB-0123456789-compact2.png
        final parts = segment.split('-');
        if (parts.length >= 2) {
          bankName ??= parts[0];
          accountNumber ??= parts[1];
        }
      }

      if (amount != null || merchant != null || description != null) {
        return QrPaymentData(
          rawPayload: raw,
          amount: amount,
          merchant: merchant,
          bankName: bankName,
          accountNumber: accountNumber,
          transactionDescription: description,
          qrType: 'VietQR_URL',
        );
      }
    } catch (_) {}
    return null;
  }
}

/// Bộ phân tích tổng hợp QR Payment (EMVCo, VietQR, Key-Value, Plain Text)
class QrPaymentParser {
  static QrPaymentData parse(String rawPayload) {
    final trimmed = rawPayload.trim();

    // 1. Kiểm tra chuẩn EMVCo QR Code (Bắt đầu bằng 000201...)
    if (trimmed.startsWith('000201') ||
        (trimmed.length > 10 && trimmed.startsWith('00'))) {
      final tags = EmvQrParser.parseTlv(trimmed);
      if (tags.isNotEmpty) {
        // Thử parse VietQR trước
        final vietQrResult = VietQrParser.parseVietQrEmv(trimmed, tags);
        if (vietQrResult != null) return vietQrResult;

        // Parse EMVCo thông thường (quốc tế hoặc ví điện tử khác)
        double? amount;
        if (tags['54'] != null) {
          amount = double.tryParse(tags['54']!);
        }
        final merchant = tags['59'];
        String? description;
        if (tags['62'] != null) {
          final sub62 = EmvQrParser.parseSubTlv(tags['62']!);
          description = sub62['08'] ?? sub62['05'];
        }

        return QrPaymentData(
          rawPayload: trimmed,
          amount: amount,
          merchant: merchant,
          transactionDescription: description,
          qrType: 'EMVCo',
        );
      }
    }

    // 2. Kiểm tra định dạng URL (VietQR URL, MoMo, ZaloPay link)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final urlResult = VietQrParser.parseVietQrUrl(trimmed);
      if (urlResult != null) return urlResult;

      return QrPaymentData(rawPayload: trimmed, qrType: 'URL');
    }

    // 3. Kiểm tra định dạng Key-Value (ví dụ: amount=150000;merchant=Highlands;note=cafe)
    if (trimmed.contains('=') &&
        (trimmed.contains(';') ||
            trimmed.contains('&') ||
            trimmed.contains('\n'))) {
      final delimiter = trimmed.contains(';')
          ? ';'
          : trimmed.contains('&')
          ? '&'
          : '\n';
      final pairs = trimmed.split(delimiter);
      final map = <String, String>{};
      for (final pair in pairs) {
        final idx = pair.indexOf('=');
        if (idx > 0) {
          final key = pair.substring(0, idx).trim().toLowerCase();
          final val = pair.substring(idx + 1).trim();
          map[key] = val;
        }
      }

      double? amount;
      for (final k in ['amount', 'tien', 'sotien', 'total', 'price']) {
        if (map.containsKey(k)) {
          amount = CurrencyFormatter.parseAmount(map[k]!);
          if (amount != null) break;
        }
      }

      String? merchant;
      for (final k in [
        'merchant',
        'cuahang',
        'nguoinhan',
        'receiver',
        'name',
        'store',
      ]) {
        if (map.containsKey(k)) {
          merchant = map[k];
          break;
        }
      }

      String? note;
      for (final k in ['note', 'noidung', 'description', 'desc', 'info']) {
        if (map.containsKey(k)) {
          note = map[k];
          break;
        }
      }

      return QrPaymentData(
        rawPayload: trimmed,
        amount: amount,
        merchant: merchant,
        transactionDescription: note,
        qrType: 'KeyValue',
      );
    }

    // 4. Fallback: QR dạng chuỗi thuần túy
    return QrPaymentData(rawPayload: trimmed, qrType: 'Unknown');
  }
}
