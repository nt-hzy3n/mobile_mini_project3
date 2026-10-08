import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/features/scanner/data/qr_parser.dart';

void main() {
  group('QR Payment Parser Tests', () {
    test('Parse standard VietQR EMVCo payload with amount and merchant', () {
      // Sample VietQR payload:
      // 000201 (Format)
      // 010212 (Dynamic)
      // 38540010A00000072701240006970422011003456789010208QRIBFTTA (NAPAS MBBank)
      // 5303704 (VND)
      // 5406150000 (Amount: 150000)
      // 5802VN
      // 5916HIGHLANDS COFFEE (Merchant)
      // 62190815Thanh toan cafe (Description)
      const payload =
          '00020101021238540010A00000072701240006970422011003456789010208QRIBFTTA530370454061500005802VN5916HIGHLANDS COFFEE62190815Thanh toan cafe6304E8A9';

      final result = QrPaymentParser.parse(payload);

      expect(result.qrType, 'VietQR');
      expect(result.amount, 150000.0);
      expect(result.merchant, 'HIGHLANDS COFFEE');
      expect(result.transactionDescription, 'Thanh toan cafe');
      expect(result.bankName, contains('MBBank'));
      expect(result.accountNumber, '0345678901');
      expect(result.maskedAccountNumber, '****8901');
    });

    test('Parse VietQR URL with query parameters', () {
      const url =
          'https://img.vietqr.io/image/970422-0987654321-compact2.png?amount=250000&accountName=NGUYEN%20VAN%20A&addInfo=Tien%20an%20trua';

      final result = QrPaymentParser.parse(url);

      expect(result.amount, 250000.0);
      expect(result.merchant, 'NGUYEN VAN A');
      expect(result.transactionDescription, 'Tien an trua');
    });

    test('Parse Key-Value QR payload format', () {
      const kvPayload =
          'amount=750000;merchant=GearVN Da Nang;note=Ban phim co;bank=VCB';

      final result = QrPaymentParser.parse(kvPayload);

      expect(result.amount, 750000.0);
      expect(result.merchant, 'GearVN Da Nang');
      expect(result.transactionDescription, 'Ban phim co');
      expect(result.qrType, 'KeyValue');
    });

    test('Handle QR without amount gracefully (amount is null)', () {
      // Static VietQR without tag 54
      const staticPayload =
          '00020101021138540010A00000072701240006970422011003456789010208QRIBFTTA53037045802VN5910TRAN VAN B6304A1B2';

      final result = QrPaymentParser.parse(staticPayload);

      expect(result.amount, isNull);
      expect(result.merchant, 'TRAN VAN B');
      expect(result.hasAmount, isFalse);
    });

    test('Handle plain / unknown QR payload gracefully', () {
      const plainPayload = 'WIFI:S:VKU_Student;T:WPA;P:12345678;;';

      final result = QrPaymentParser.parse(plainPayload);

      expect(result.amount, isNull);
      expect(result.merchant, isNull);
      expect(result.qrType, 'Unknown');
    });
  });
}
