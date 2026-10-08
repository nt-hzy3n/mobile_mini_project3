import '../models/qr_payment_data.dart';
import '../models/scan_result.dart';
import 'heuristic_parser.dart';

class PaymentDataMerger {
  /// Kết hợp dữ liệu từ QR code và OCR text
  /// Priority: QR > OCR > manual
  static ScanResult merge({
    QrPaymentData? qrData,
    ParsedPaymentData? ocrData,
    String? imagePath,
    String? rawOcrText,
  }) {
    final hasValidQr = qrData != null && qrData.rawPayload.isNotEmpty;
    final hasValidOcr =
        ocrData != null &&
        ((ocrData.amount != null && ocrData.amount! > 0) ||
            (ocrData.merchant != null && ocrData.merchant!.isNotEmpty) ||
            ocrData.date != null ||
            (ocrData.bankName != null && ocrData.bankName!.isNotEmpty));

    // 1. Xác định Số tiền (Amount): Ưu tiên QR nếu có giá trị hợp lệ (> 0)
    double? amount;
    String? amountSource;
    if (qrData?.amount != null && qrData!.amount! > 0) {
      amount = qrData.amount;
      amountSource = 'QR';
    } else if (ocrData?.amount != null && ocrData!.amount! > 0) {
      amount = ocrData.amount;
      amountSource = 'OCR';
    }

    // 2. Xác định Người nhận (Merchant / Recipient): Ưu tiên QR nếu có
    String? merchant;
    String? merchantSource;
    if (qrData?.merchant != null && qrData!.merchant!.trim().isNotEmpty) {
      merchant = qrData.merchant!.trim();
      merchantSource = 'QR';
    } else if (ocrData?.merchant != null &&
        ocrData!.merchant!.trim().isNotEmpty) {
      merchant = ocrData.merchant!.trim();
      merchantSource = 'OCR';
    }

    // 3. Xác định Ngân hàng thụ hưởng: Ưu tiên QR nếu có
    String? bankName;
    String? bankCode;
    if (qrData?.bankName != null && qrData!.bankName!.trim().isNotEmpty) {
      bankName = qrData.bankName!.trim();
    } else if (ocrData?.bankName != null &&
        ocrData!.bankName!.trim().isNotEmpty) {
      bankName = ocrData.bankName!.trim();
      bankCode = ocrData.bankCode;
    }

    // 4. Xác định Số tài khoản: Ưu tiên QR nếu có
    String? accountNumber;
    if (qrData?.accountNumber != null &&
        qrData!.accountNumber!.trim().isNotEmpty) {
      accountNumber = qrData.accountNumber!.trim();
    } else if (ocrData?.accountNumber != null &&
        ocrData!.accountNumber!.trim().isNotEmpty) {
      accountNumber = ocrData.accountNumber!.trim();
    }

    // 5. Xác định Ngày giao dịch: Ưu tiên ngày từ OCR (biên lai) nếu có, fallback QR hoặc ngày hiện tại
    DateTime date = ocrData?.date ?? DateTime.now();
    String dateSource = ocrData?.date != null ? 'OCR' : 'System';

    // 6. Xác định Thời gian giao dịch (HH:mm)
    String? transactionTime = ocrData?.time;

    // 7. Xác định Ghi chú / Nội dung chuyển khoản
    String? note;
    if (qrData?.transactionDescription != null &&
        qrData!.transactionDescription!.trim().isNotEmpty) {
      note = qrData.transactionDescription!.trim();
    } else if (ocrData?.note != null && ocrData!.note!.trim().isNotEmpty) {
      note = ocrData.note!.trim();
    }

    // 8. Xác định Nguồn dữ liệu (Source Type: qr, ocr, hybrid, manual)
    String sourceType;
    if (hasValidQr && hasValidOcr) {
      if (amountSource == 'QR' && merchantSource == 'QR') {
        sourceType = 'qr';
      } else if (amountSource == 'OCR' &&
          (qrData.hasMerchant ||
              qrData.bankName != null ||
              qrData.accountNumber != null)) {
        sourceType = 'hybrid';
      } else if (amountSource == 'QR' && merchantSource == 'OCR') {
        sourceType = 'hybrid';
      } else {
        sourceType = 'hybrid';
      }
    } else if (hasValidQr) {
      sourceType = 'qr';
    } else if (hasValidOcr) {
      sourceType = 'ocr';
    } else {
      sourceType = 'manual';
    }

    return ScanResult(
      amount: amount,
      merchant: merchant,
      date: date,
      transactionTime: transactionTime,
      note: note,
      qrPayload: qrData?.rawPayload,
      sourceType: sourceType,
      imagePath: imagePath,
      rawOcrText: rawOcrText,
      bankName: bankName,
      bankCode: bankCode,
      accountNumber: accountNumber,
      amountSource: amountSource,
      merchantSource: merchantSource,
      dateSource: dateSource,
    );
  }
}
