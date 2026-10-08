class QrPaymentData {
  final String rawPayload;
  final double? amount;
  final String? merchant;
  final String? bankName;
  final String? accountNumber;
  final String? transactionDescription;
  final String? transactionReference;
  final String qrType; // 'VietQR', 'EMVCo', 'URL', 'Custom', 'Unknown'

  const QrPaymentData({
    required this.rawPayload,
    this.amount,
    this.merchant,
    this.bankName,
    this.accountNumber,
    this.transactionDescription,
    this.transactionReference,
    this.qrType = 'Unknown',
  });

  bool get hasAmount => amount != null && amount! > 0;
  bool get hasMerchant => merchant != null && merchant!.trim().isNotEmpty;
  bool get hasDescription =>
      transactionDescription != null &&
      transactionDescription!.trim().isNotEmpty;

  /// Hiển thị số tài khoản đã che bảo mật: ví dụ ****1234
  String? get maskedAccountNumber {
    if (accountNumber == null || accountNumber!.isEmpty) return null;
    if (accountNumber!.length <= 4) return '****$accountNumber';
    final lastFour = accountNumber!.substring(accountNumber!.length - 4);
    return '****$lastFour';
  }

  @override
  String toString() {
    return 'QrPaymentData(type: $qrType, amount: $amount, merchant: $merchant, desc: $transactionDescription)';
  }
}
