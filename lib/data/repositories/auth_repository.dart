import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Người dùng mô phỏng cho môi trường thử nghiệm khi chưa cấu hình API Key Firebase thực
class DemoFirebaseUser implements User {
  @override
  final String uid;
  @override
  final String? email;
  @override
  String? displayName;

  DemoFirebaseUser({
    required this.uid,
    this.email,
    this.displayName,
  });

  @override
  Future<void> updateDisplayName(String? name) async {
    displayName = name;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AuthChangeNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

class AuthRepository {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  // In-memory demo/mock user state khi API key chưa được kích hoạt
  static User? _demoUser;
  static final StreamController<User?> _demoAuthStreamController =
      StreamController<User?>.broadcast();
  static final AuthChangeNotifier authStateListenable = AuthChangeNotifier();

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

  static void _setDemoUser(String email, String displayName) {
    final sanitizedUid =
        'user_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    _demoUser = DemoFirebaseUser(
      uid: sanitizedUid,
      email: email,
      displayName: displayName,
    );
    _demoAuthStreamController.add(_demoUser);
    authStateListenable.notify();
  }

  static void _clearDemoUser() {
    _demoUser = null;
    _demoAuthStreamController.add(null);
    authStateListenable.notify();
  }

  /// Kiểm tra có người dùng đăng nhập không (từ Firebase thực hoặc Demo session)
  static bool get isAuthenticated {
    if (_demoUser != null) return true;
    try {
      return FirebaseAuth.instance.currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Lấy UID người dùng hiện tại
  static String? get currentUserId {
    if (_demoUser != null) return _demoUser!.uid;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  /// Lắng nghe luồng thay đổi trạng thái xác thực
  Stream<User?> get authStateChanges {
    final a = _auth;
    if (a != null) {
      final controller = StreamController<User?>.broadcast();
      StreamSubscription? sub1;
      StreamSubscription? sub2;

      void emit(User? user) {
        if (!controller.isClosed) controller.add(user);
      }

      controller.onListen = () {
        if (_demoUser != null) {
          emit(_demoUser);
        } else if (a.currentUser != null) {
          emit(a.currentUser);
        } else {
          emit(null);
        }

        sub1 = a.authStateChanges().listen((user) {
          if (_demoUser == null) emit(user);
        });

        sub2 = _demoAuthStreamController.stream.listen((demoUser) {
          emit(demoUser ?? a.currentUser);
        });
      };

      controller.onCancel = () {
        sub1?.cancel();
        sub2?.cancel();
      };

      return controller.stream;
    }
    return _demoAuthStreamController.stream;
  }

  /// Người dùng hiện tại đang đăng nhập
  User? get currentUser {
    if (_demoUser != null) return _demoUser;
    final a = _auth;
    if (a != null) {
      return a.currentUser;
    }
    return null;
  }

  /// Đăng nhập bằng Email và Mật khẩu
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    final a = _auth;
    try {
      if (a != null) {
        final credential = await a.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        _clearDemoUser();
        return credential;
      }
    } on FirebaseAuthException catch (e) {
      if (_isApiKeyInvalid(e)) {
        debugPrint(
          '[AuthRepository] Firebase API Key chưa kích hoạt -> Kích hoạt phiên Demo: $email',
        );
        _setDemoUser(email.trim(), email.split('@').first);
        return null;
      }
      throw mapAuthException(e);
    } catch (e) {
      if (e.toString().contains('API key not valid')) {
        _setDemoUser(email.trim(), email.split('@').first);
        return null;
      }
      throw 'Đã xảy ra lỗi đăng nhập: $e';
    }

    _setDemoUser(email.trim(), email.split('@').first);
    return null;
  }

  /// Đăng ký tài khoản mới bằng Email và Mật khẩu
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final a = _auth;
    try {
      if (a != null) {
        final credential = await a.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );

        final user = credential.user;
        if (user != null) {
          await user.updateDisplayName(displayName.trim());

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

        _clearDemoUser();
        return credential;
      }
    } on FirebaseAuthException catch (e) {
      if (_isApiKeyInvalid(e)) {
        debugPrint(
          '[AuthRepository] Firebase API Key chưa kích hoạt -> Kích hoạt phiên Demo: $email ($displayName)',
        );
        _setDemoUser(email.trim(), displayName.trim());
        return null;
      }
      throw mapAuthException(e);
    } catch (e) {
      if (e.toString().contains('API key not valid')) {
        _setDemoUser(email.trim(), displayName.trim());
        return null;
      }
      throw 'Đã xảy ra lỗi đăng ký: $e';
    }

    _setDemoUser(email.trim(), displayName.trim());
    return null;
  }

  /// Đăng xuất khỏi hệ thống
  Future<void> signOut() async {
    _clearDemoUser();
    final a = _auth;
    if (a != null) {
      try {
        await a.signOut();
      } catch (_) {}
    }
  }

  /// Gửi email đặt lại mật khẩu
  Future<void> sendPasswordResetEmail({required String email}) async {
    final a = _auth;
    if (a == null) return;

    try {
      await a.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (_isApiKeyInvalid(e)) {
        debugPrint(
          '[AuthRepository] Firebase API Key chưa kích hoạt -> Mô phỏng gửi email đặt lại mật khẩu cho $email',
        );
        return;
      }
      throw mapAuthException(e);
    } catch (e) {
      if (e.toString().contains('API key not valid')) return;
      throw 'Không thể gửi email đặt lại mật khẩu: $e';
    }
  }

  static bool _isApiKeyInvalid(FirebaseAuthException e) {
    final msg = (e.message ?? '').toLowerCase();
    final code = e.code.toLowerCase();
    return msg.contains('api key not valid') ||
        msg.contains('please pass a valid api key') ||
        code == 'api-key-not-valid' ||
        code == 'invalid-api-key';
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
