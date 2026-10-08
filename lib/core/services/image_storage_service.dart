import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageStorageService {
  /// Lưu file ảnh vào thư mục riêng của app: `expense_<timestamp>.jpg`
  static Future<String> saveExpenseImage(File sourceFile) async {
    if (kIsWeb) return sourceFile.path;
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory(p.join(docsDir.path, 'expense_images'));
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(sourceFile.path).isNotEmpty
        ? p.extension(sourceFile.path)
        : '.jpg';
    final targetPath = p.join(imagesDir.path, 'expense_$timestamp$extension');

    final savedFile = await sourceFile.copy(targetPath);
    return savedFile.path;
  }

  /// Xóa file ảnh khi xóa khoản chi tiêu
  static Future<bool> deleteExpenseImage(String? imagePath) async {
    if (kIsWeb || imagePath == null || imagePath.isEmpty) return false;
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {
      // Ignore errors if file is already deleted or unreadable
    }
    return false;
  }

  /// Xóa toàn bộ ảnh đã lưu (dùng khi xóa toàn bộ dữ liệu)
  static Future<void> clearAllImages() async {
    if (kIsWeb) return;
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory(p.join(docsDir.path, 'expense_images'));
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
