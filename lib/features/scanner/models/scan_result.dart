import '../../../data/models/expense_model.dart';
import '../../../core/constants/category_constants.dart';

class ScanResult {
  final double? amount;
  final String? merchant;
  final DateTime? date;
  final String? transactionTime; // e.g. '17:53'
  final String? note;
  final String? qrPayload;
  final String sourceType; // 'qr', 'ocr', 'hybrid', 'manual'
  final String? imagePath;
  final String? rawOcrText;
  final String? bankName;
  final String? bankCode;
  final String? accountNumber;
  final String? amountSource; // 'QR' or 'OCR'
  final String? merchantSource; // 'QR' or 'OCR'
  final String? dateSource; // 'QR' or 'OCR'

  const ScanResult({
    this.amount,
    this.merchant,
    this.date,
    this.transactionTime,
    this.note,
    this.qrPayload,
    this.sourceType = 'manual',
    this.imagePath,
    this.rawOcrText,
    this.bankName,
    this.bankCode,
    this.accountNumber,
    this.amountSource,
    this.merchantSource,
    this.dateSource,
  });

  bool get hasAmount => amount != null && amount! > 0;
  bool get hasMerchant => merchant != null && merchant!.trim().isNotEmpty;
  bool get hasQr => qrPayload != null && qrPayload!.isNotEmpty;
  bool get hasOcr => rawOcrText != null && rawOcrText!.isNotEmpty;

  String? get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.trim().isEmpty) return null;
    final acc = accountNumber!.trim();
    if (acc.length <= 4) return '****$acc';
    final suffix = acc.substring(acc.length - 4);
    return '********$suffix';
  }

  Expense toExpense() {
    final effectiveMerchant = (merchant != null && merchant!.trim().isNotEmpty)
        ? merchant!.trim()
        : 'Cửa hàng chưa xác định';

    final effectiveCategory = ExpenseCategory.suggestFromText(
      '$effectiveMerchant ${note ?? ''}',
    );

    return Expense(
      amount: amount ?? 0.0,
      merchant: effectiveMerchant,
      category: effectiveCategory,
      date: date ?? DateTime.now(),
      transactionTime: transactionTime,
      bank: bankName,
      accountNumber: accountNumber,
      note: note ?? '',
      paymentMethod: 'QR Payment',
      qrPayload: qrPayload,
      sourceType: sourceType,
      imagePath: imagePath,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  ScanResult copyWith({
    double? amount,
    String? merchant,
    DateTime? date,
    String? transactionTime,
    String? note,
    String? qrPayload,
    String? sourceType,
    String? imagePath,
    String? rawOcrText,
    String? bankName,
    String? bankCode,
    String? accountNumber,
    String? amountSource,
    String? merchantSource,
    String? dateSource,
  }) {
    return ScanResult(
      amount: amount ?? this.amount,
      merchant: merchant ?? this.merchant,
      date: date ?? this.date,
      transactionTime: transactionTime ?? this.transactionTime,
      note: note ?? this.note,
      qrPayload: qrPayload ?? this.qrPayload,
      sourceType: sourceType ?? this.sourceType,
      imagePath: imagePath ?? this.imagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      bankName: bankName ?? this.bankName,
      bankCode: bankCode ?? this.bankCode,
      accountNumber: accountNumber ?? this.accountNumber,
      amountSource: amountSource ?? this.amountSource,
      merchantSource: merchantSource ?? this.merchantSource,
      dateSource: dateSource ?? this.dateSource,
    );
  }
}
