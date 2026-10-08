import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  // In-memory user state for unit tests or offline environments
  static User? _mockCurrentUser;

  AuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _customAuth = auth,
      _customFirestore = firestore;

  FirebaseAuth? get _auth {
    try {
      return _customAuth ?? FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _firestore {
    try {
      return _customFirestore ?? FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Lắng nghe luồng thay đổi trạng thái xác thực
  Stream<User?> get authStateChanges {
    final a = _auth;
    if (a != null) {
      return a.authStateChanges();
    }
    return Stream.value(_mockCurrentUser);
  }

  /// Người dùng hiện tại đang đăng nhập
  User? get currentUser {
    final a = _auth;
    if (a != null) {
      return a.currentUser;
    }
    return _mockCurrentUser;
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    final a = _auth;
    if (a == null) {
      // Mocked sign-in for tests
      return null;
    }

    try {
      final credential = await a.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi đăng nhập: $e';
    }
  }

  /// Đăng ký tài khoản mới bằng Email và Mật khẩu
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final a = _auth;
    if (a == null) {
      return null;
    }

    try {
      final credential = await a.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = credential.user;
      if (user != null) {
        // Cập nhật tên hiển thị trong Firebase Auth
        await user.updateDisplayName(displayName.trim());

        // Tạo document hồ sơ người dùng trong Firestore: users/{uid}
        final f = _firestore;
        if (f != null) {
          try {
            await f.collection('users').doc(user.uid).set({
              'email': user.email,
              'displayName': displayName.trim(),
              'createdAt': Timestamp.now(),
              'updatedAt': Timestamp.now(),
            });
          } catch (e) {
            debugPrint('Lỗi tạo hồ sơ người dùng trong Firestore: $e');
          }
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      throw 'Đã xảy ra lỗi đăng ký: $e';
    }
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    final a = _auth;
    if (a != null) {
      await a.signOut();
    }
    _mockCurrentUser = null;
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail({required String email}) async {
    final a = _auth;
    if (a == null) return;

    try {
      await a.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      throw 'Không thể gửi email đặt lại mật khẩu: $e';
    }
  }

  /// Chuyển đổi mã lỗi FirebaseAuthException sang thông báo tiếng Việt thân thiện
  static String mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Không tìm thấy tài khoản với email này.';
      case 'wrong-password':
        return 'Mật khẩu không chính xác.';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác.';
      case 'email-already-in-use':
        return 'Email này đã được sử dụng cho một tài khoản khác.';
      case 'invalid-email':
        return 'Địa chỉ email không đúng định dạng.';
      case 'weak-password':
        return 'Mật khẩu chưa đủ mạnh (yêu cầu tối thiểu 6 ký tự).';
      case 'user-disabled':
        return 'Tài khoản này đã bị khóa hoặc vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều lần thử thất bại. Vui lòng thử lại sau ít phút.';
      case 'network-request-failed':
        return 'Không thể kết nối mạng. Vui lòng kiểm tra lại đường truyền internet.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt trên hệ thống.';
      default:
        return e.message ??
            'Đã xảy ra lỗi xác thực (${e.code}). Vui lòng thử lại.';
    }
  }
}
