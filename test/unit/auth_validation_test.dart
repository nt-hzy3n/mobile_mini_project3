import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vku_expense_qr/data/repositories/auth_repository.dart';

void main() {
  group('Authentication Validation & Error Mapping Unit Tests', () {
    test('Email format validation rules', () {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

      // Invalid emails
      expect(emailRegex.hasMatch(''), isFalse);
      expect(emailRegex.hasMatch('notanemail'), isFalse);
      expect(emailRegex.hasMatch('test@'), isFalse);
      expect(emailRegex.hasMatch('@domain.com'), isFalse);
      expect(emailRegex.hasMatch('test@domain'), isFalse);

      // Valid emails
      expect(emailRegex.hasMatch('user@gmail.com'), isTrue);
      expect(emailRegex.hasMatch('student.23it110@vku.udn.vn'), isTrue);
      expect(emailRegex.hasMatch('huyen@vku.edu.vn'), isTrue);
    });

    test('Password validation and minimum length', () {
      String? validatePassword(String? val) {
        if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
        if (val.length < 6) return 'Mật khẩu phải có tối thiểu 6 ký tự';
        return null;
      }

      expect(validatePassword(null), 'Vui lòng nhập mật khẩu');
      expect(validatePassword(''), 'Vui lòng nhập mật khẩu');
      expect(validatePassword('12345'), 'Mật khẩu phải có tối thiểu 6 ký tự');
      expect(validatePassword('123456'), isNull);
      expect(validatePassword('StrongP@ss2026'), isNull);
    });

    test('Register validation: Name length & Password confirmation match', () {
      String? validateName(String? val) {
        if (val == null || val.trim().isEmpty) return 'Vui lòng nhập họ và tên';
        if (val.trim().length < 2) return 'Họ tên phải có ít nhất 2 ký tự';
        return null;
      }

      String? validateConfirmPassword(String? password, String? confirm) {
        if (confirm == null || confirm.isEmpty) {
          return 'Vui lòng xác nhận lại mật khẩu';
        }
        if (confirm != password) {
          return 'Mật khẩu xác nhận không trùng khớp';
        }
        return null;
      }

      // Name validation
      expect(validateName(''), 'Vui lòng nhập họ và tên');
      expect(validateName('A'), 'Họ tên phải có ít nhất 2 ký tự');
      expect(validateName('Nguyen Thi Huyen'), isNull);

      // Password confirmation match
      expect(
        validateConfirmPassword('pass123', 'pass456'),
        'Mật khẩu xác nhận không trùng khớp',
      );
      expect(validateConfirmPassword('pass123', 'pass123'), isNull);
    });

    test('Firebase Auth error mapping produces clear Vietnamese messages', () {
      expect(
        AuthRepository.mapAuthException(
          FirebaseAuthException(code: 'user-not-found'),
        ),
        'Không tìm thấy tài khoản với email này.',
      );

      expect(
        AuthRepository.mapAuthException(
          FirebaseAuthException(code: 'wrong-password'),
        ),
        'Mật khẩu không chính xác.',
      );

      expect(
        AuthRepository.mapAuthException(
          FirebaseAuthException(code: 'invalid-credential'),
        ),
        'Email hoặc mật khẩu không chính xác.',
      );

      expect(
        AuthRepository.mapAuthException(
          FirebaseAuthException(code: 'email-already-in-use'),
        ),
        'Email này đã được sử dụng cho một tài khoản khác.',
      );

      expect(
        AuthRepository.mapAuthException(
          FirebaseAuthException(code: 'weak-password'),
        ),
        'Mật khẩu chưa đủ mạnh (yêu cầu tối thiểu 6 ký tự).',
      );

      expect(
        AuthRepository.mapAuthException(
          FirebaseAuthException(code: 'network-request-failed'),
        ),
        'Không thể kết nối mạng. Vui lòng kiểm tra lại đường truyền internet.',
      );
    });

    test('AuthRepository signOut clears session', () async {
      final authRepo = AuthRepository();
      await authRepo.signOut();
      expect(authRepo.currentUser, isNull);
    });
  });
}
