import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Yêu cầu quyền truy cập Camera
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    return result.isGranted;
  }

  /// Yêu cầu quyền truy cập Thư viện ảnh / Storage
  static Future<bool> requestPhotosPermission() async {
    // Android 13+ (API 33+) dùng photos, cũ hơn dùng storage
    final photosStatus = await Permission.photos.status;
    if (photosStatus.isGranted || photosStatus.isLimited) return true;

    final storageStatus = await Permission.storage.status;
    if (storageStatus.isGranted) return true;

    final photosResult = await Permission.photos.request();
    if (photosResult.isGranted || photosResult.isLimited) return true;

    final storageResult = await Permission.storage.request();
    return storageResult.isGranted;
  }

  /// Mở cài đặt hệ thống nếu người dùng từ chối vĩnh viễn
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }
}
