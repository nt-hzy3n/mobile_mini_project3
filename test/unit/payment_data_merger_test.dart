import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/features/scanner/data/heuristic_parser.dart';
import 'package:vku_expense_qr/features/scanner/data/payment_data_merger.dart';
import 'package:vku_expense_qr/features/scanner/models/qr_payment_data.dart';

void main() {
  group('PaymentDataMerger Unit Tests (QR + OCR Hybrid Merge)', () {
    test('Priority Amount: QR takes precedence over OCR when valid', () {
      final qr = QrPaymentData(
        amount: 250000.0,
        merchant: 'Highlands Coffee',
        rawPayload: 'sample_payload',
      );
      final ocr = ParsedPaymentData(
        amount: 150000.0,
        merchant: 'Highlands Coffee Da Nang',
        date: DateTime(2026, 9, 28),
      );

      final merged = PaymentDataMerger.merge(qrData: qr, ocrData: ocr);

      expect(merged.amount, 250000.0);
      expect(merged.amountSource, 'QR');
      expect(merged.merchant, 'Highlands Coffee');
      expect(merged.sourceType, 'qr');
    });

    test('Static QR (no amount) merges with OCR amount (Hybrid mode)', () {
      final staticQr = QrPaymentData(
        merchant: 'NGUYEN THI THUONG',
        bankName: 'MBBank',
        accountNumber: '41212106082002',
        rawPayload: '000201010211...',
      );
      final ocr = ParsedPaymentData(
        amount: 1000000.0,
        date: DateTime(2026, 9, 28),
        time: '17:53',
        note: 'NGUYEN THI HUYEN chuyen tien',
      );

      final merged = PaymentDataMerger.merge(qrData: staticQr, ocrData: ocr);

      expect(merged.amount, 1000000.0);
      expect(merged.amountSource, 'OCR');
      expect(merged.merchant, 'NGUYEN THI THUONG');
      expect(merged.bankName, 'MBBank');
      expect(merged.accountNumber, '41212106082002');
      expect(merged.transactionTime, '17:53');
      expect(merged.note, 'NGUYEN THI HUYEN chuyen tien');
      expect(merged.sourceType, 'hybrid');
    });

    test('OCR-only mode when QR code is absent', () {
      final ocr = ParsedPaymentData(
        amount: 50000.0,
        merchant: 'Cơm tấm Sài Gòn',
        date: DateTime(2026, 9, 30),
        time: '12:15',
        note: 'Ăn trưa',
      );

      final merged = PaymentDataMerger.merge(qrData: null, ocrData: ocr);

      expect(merged.amount, 50000.0);
      expect(merged.merchant, 'Cơm tấm Sài Gòn');
      expect(merged.sourceType, 'ocr');
      expect(merged.amountSource, 'OCR');
    });

    test('Masked account number helper returns secure format', () {
      final ocr = ParsedPaymentData(
        amount: 100000.0,
        accountNumber: '41212106082002',
      );
      final merged = PaymentDataMerger.merge(ocrData: ocr);
      expect(merged.maskedAccountNumber, '********2002');
    });
  });
}
