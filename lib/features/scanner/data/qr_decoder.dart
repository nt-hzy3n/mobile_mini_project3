import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';

class QrDecoder {
  BarcodeScanner? _scanner;

  BarcodeScanner get _barcodeScanner {
    _scanner ??= BarcodeScanner(formats: [BarcodeFormat.qrCode]);
    return _scanner!;
  }

  /// Quét và giải mã QR code từ file ảnh tĩnh
  Future<String?> decodeQrFromImagePath(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final barcodes = await _barcodeScanner.processImage(inputImage);

      for (final barcode in barcodes) {
        if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
          return barcode.rawValue;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Giải phóng tài nguyên
  Future<void> dispose() async {
    if (_scanner != null) {
      await _scanner!.close();
      _scanner = null;
    }
  }
}
