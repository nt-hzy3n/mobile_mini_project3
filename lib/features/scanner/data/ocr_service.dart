import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  TextRecognizer? _textRecognizer;

  TextRecognizer get _recognizer {
    _textRecognizer ??= TextRecognizer(script: TextRecognitionScript.latin);
    return _textRecognizer!;
  }

  /// Nhận diện văn bản trên ảnh cục bộ bằng Google ML Kit Text Recognition
  Future<String> recognizeTextFromImagePath(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _recognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('Lỗi nhận diện văn bản OCR: $e');
    }
  }

  /// Giải phóng tài nguyên theo lifecycle
  Future<void> dispose() async {
    if (_textRecognizer != null) {
      await _textRecognizer!.close();
      _textRecognizer = null;
    }
  }
}
