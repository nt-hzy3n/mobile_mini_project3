import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/auth_repository.dart';

class FirebaseStorageResult {
  final String imageUrl;
  final String imagePath;

  const FirebaseStorageResult({
    required this.imageUrl,
    required this.imagePath,
  });
}

class FirebaseStorageService {
  final FirebaseStorage? _customStorage;

  FirebaseStorageService({FirebaseStorage? storage}) : _customStorage = storage;

  FirebaseStorage? get _storage {
    try {
      return _customStorage ?? FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// Upload file ảnh giao dịch lên Firebase Storage theo đường dẫn User-scoped:
  /// `users/{userId}/expenses/{expenseId}/payment_image.jpg`
  Future<FirebaseStorageResult?> uploadExpenseImage({
    required String expenseId,
    required File imageFile,
    String? userId,
  }) async {
    try {
      // Nếu đang dùng cấu hình demo/placeholder hoặc chưa có Firebase Auth session thật,
      // bỏ qua Firebase Storage để tránh treo vòng lặp exponential backoff
      if (AuthRepository.isPlaceholderConfig) {
        debugPrint('Chế độ Demo/Placeholder: bỏ qua tải ảnh lên Firebase Storage.');
        return null;
      }
      try {
        if (FirebaseAuth.instance.currentUser == null) {
          debugPrint('Chưa đăng nhập Firebase Auth thật: bỏ qua tải ảnh Storage.');
          return null;
        }
      } catch (_) {
        return null;
      }

      final storageInstance = _storage;
      if (storageInstance == null) return null;

      if (!await imageFile.exists()) {
        debugPrint('File ảnh không tồn tại: ${imageFile.path}');
        return null;
      }

      final userPrefix = (userId != null && userId.isNotEmpty)
          ? 'users/$userId/'
          : '';
      final storagePath = '${userPrefix}expenses/$expenseId/payment_image.jpg';
      final storageRef = storageInstance.ref().child(storagePath);

      final metadataMap = <String, String>{
        'expenseId': expenseId,
        'uploadedAt': DateTime.now().toIso8601String(),
      };
      if (userId != null && userId.isNotEmpty) {
        metadataMap['userId'] = userId;
      }

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: metadataMap,
      );

      final uploadTask = await storageRef
          .putFile(imageFile, metadata)
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => throw TimeoutException('Tải ảnh Storage quá thời gian'),
          );
      final downloadUrl = await uploadTask.ref
          .getDownloadURL()
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () => throw TimeoutException('Lấy URL Storage quá thời gian'),
          );

      return FirebaseStorageResult(
        imageUrl: downloadUrl,
        imagePath: storagePath,
      );
    } catch (e) {
      debugPrint('Lỗi tải ảnh lên Firebase Storage: $e');
      return null;
    }
  }

  /// Xóa file ảnh giao dịch từ Firebase Storage khi khoản chi bị xóa
  Future<bool> deleteExpenseImage({String? imagePath, String? imageUrl}) async {
    if ((imagePath == null || imagePath.isEmpty) &&
        (imageUrl == null || imageUrl.isEmpty)) {
      return false;
    }

    if (AuthRepository.isPlaceholderConfig) {
      return false;
    }
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        return false;
      }
    } catch (_) {
      return false;
    }

    try {
      final storageInstance = _storage;
      if (storageInstance == null) return false;

      Reference? ref;
      if (imagePath != null &&
          imagePath.isNotEmpty &&
          (imagePath.startsWith('users/') ||
              imagePath.startsWith('expenses/'))) {
        ref = storageInstance.ref().child(imagePath);
      } else if (imageUrl != null && imageUrl.startsWith('http')) {
        ref = storageInstance.refFromURL(imageUrl);
      }

      if (ref != null) {
        await ref.delete();
        return true;
      }
    } catch (e) {
      debugPrint('Thông báo: Không thể xóa ảnh trên Firebase Storage ($e)');
    }
    return false;
  }
}
