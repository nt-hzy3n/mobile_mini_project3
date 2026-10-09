import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/core/utils/validators.dart';

void main() {
  group('Form Validation Unit Tests', () {
    test('Amount validation: required, numeric, > 0', () {
      expect(Validators.validateAmount(null), isNotNull);
      expect(Validators.validateAmount(''), isNotNull);
      expect(Validators.validateAmount('0'), isNotNull);
      expect(Validators.validateAmount('-50000'), isNotNull);
      expect(Validators.validateAmount('abc'), isNotNull);

      expect(Validators.validateAmount('1,000,000'), isNull);
      expect(Validators.validateAmount('50.000'), isNull);
      expect(Validators.validateAmount('27.000.000'), isNull);
      expect(Validators.validateAmount('150000'), isNull);
    });

    test('Merchant / Recipient validation: required, at least 2 chars', () {
      expect(Validators.validateMerchant(null), isNotNull);
      expect(Validators.validateMerchant(''), isNotNull);
      expect(Validators.validateMerchant('A'), isNotNull);
      expect(Validators.validateMerchant('MB'), isNull);
      expect(Validators.validateMerchant('NGUYEN THI THUONG'), isNull);
    });

    test('Date validation: valid date required', () {
      expect(Validators.validateDate(null), isNotNull);
      expect(Validators.validateDate(DateTime.now()), isNull);
    });

    test('Time validation: HH:mm format', () {
      expect(Validators.validateTime(null), isNull); // Optional
      expect(Validators.validateTime(''), isNull); // Optional
      expect(Validators.validateTime('17:53'), isNull);
      expect(Validators.validateTime('08:00'), isNull);
      expect(Validators.validateTime('25:00'), isNotNull);
      expect(Validators.validateTime('12:65'), isNotNull);
      expect(Validators.validateTime('abc'), isNotNull);
    });

    test('Note validation: character length limit', () {
      expect(Validators.validateNote(null), isNull);
      expect(Validators.validateNote('NGUYEN THI HUYEN chuyen tien'), isNull);
      final longString = 'A' * 300;
      expect(Validators.validateNote(longString), isNotNull);
    });
  });
}
