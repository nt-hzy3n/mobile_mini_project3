import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/features/scanner/data/heuristic_parser.dart';

void main() {
  group('Heuristic Parser Unit Tests (OCR Fallback & Banking Screenshots)', () {
    test('Parse full real-world bank transfer screenshot correctly', () {
      const screenshotOcrText = '''
Chuyển tiền thành công
1,000,000 VND
17:53 - 28/09/2026
NGUYEN THI THUONG
MBBank (MB)
41212106082002
NGUYEN THI HUYEN chuyen tien
''';

      final parsed = HeuristicParser.parse(screenshotOcrText);

      expect(parsed.amount, 1000000.0);
      expect(parsed.date, DateTime(2026, 9, 28));
      expect(parsed.time, '17:53');
      expect(parsed.merchant, 'NGUYEN THI THUONG');
      expect(parsed.bankName, 'MBBank');
      expect(parsed.bankCode, 'MB');
      expect(parsed.accountNumber, '41212106082002');
      expect(parsed.note, 'NGUYEN THI HUYEN chuyen tien');
    });

    test('Amount Parser: various Vietnamese currency formats and contexts', () {
      expect(HeuristicParser.normalizeAmount('1,000,000 VND'), 1000000.0);
      expect(HeuristicParser.normalizeAmount('1.000.000 VND'), 1000000.0);
      expect(HeuristicParser.normalizeAmount('1,000,000 VNĐ'), 1000000.0);
      expect(HeuristicParser.normalizeAmount('1.000.000 đ'), 1000000.0);
      expect(HeuristicParser.normalizeAmount('1000000 VND'), 1000000.0);
      expect(HeuristicParser.normalizeAmount('1000000'), 1000000.0);
      expect(HeuristicParser.normalizeAmount('150.000'), 150000.0);
      expect(HeuristicParser.normalizeAmount('150,000'), 150000.0);

      const textWithPrefix =
          'Giao dịch chuyển khoản\nSỐ TIỀN: 2,500,000 VND\nNội dung: Trả tiền nhà';
      final parsed = HeuristicParser.parse(textWithPrefix);
      expect(parsed.amount, 2500000.0);
    });

    test('Date Parser: DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY', () {
      expect(HeuristicParser.extractDate('28/09/2026'), DateTime(2026, 9, 28));
      expect(HeuristicParser.extractDate('28-09-2026'), DateTime(2026, 9, 28));
      expect(HeuristicParser.extractDate('28.09.2026'), DateTime(2026, 9, 28));
      expect(
        HeuristicParser.extractDate('17:53 - 28/09/2026'),
        DateTime(2026, 9, 28),
      );
    });

    test('Time Parser: extracts HH:mm correctly', () {
      expect(HeuristicParser.extractTime('17:53 - 28/09/2026'), '17:53');
      expect(HeuristicParser.extractTime('Thời gian: 08:30:15'), '08:30');
      expect(HeuristicParser.extractTime('20:45'), '20:45');
      expect(HeuristicParser.extractTime('Không có giờ'), isNull);
    });

    test(
      'Recipient Parser: extracts recipient and excludes status headers',
      () {
        const text = '''
Giao dịch thành công
500,000 VND
TRẦN VĂN AN
Vietcombank (VCB)
STK: 0123456789
''';
        final parsed = HeuristicParser.parse(text);
        expect(parsed.merchant, 'TRẦN VĂN AN');
        expect(parsed.bankName, 'Vietcombank');
        expect(parsed.accountNumber, '0123456789');
      },
    );

    test('Bank and Account Extraction for diverse banks', () {
      const text = '''
Chuyển tiền thành công
Techcombank (TCB)
Số tài khoản: 19034567891234
Số tiền: 350.000 đ
''';
      final parsed = HeuristicParser.parse(text);
      expect(parsed.bankName, 'Techcombank');
      expect(parsed.bankCode, 'TCB');
      expect(parsed.accountNumber, '19034567891234');
      expect(parsed.amount, 350000.0);
    });
  });
}
