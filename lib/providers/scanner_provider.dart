import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';

import '../core/services/image_storage_service.dart';
import '../features/scanner/data/heuristic_parser.dart';
import '../features/scanner/data/ocr_service.dart';
import '../features/scanner/data/payment_data_merger.dart';
import '../features/scanner/data/qr_decoder.dart';
import '../features/scanner/data/qr_parser.dart';
import '../features/scanner/models/qr_payment_data.dart';
import '../features/scanner/models/scan_result.dart';

enum ScannerStage {
  idle,
  detectingQr,
  parsingQr,
  runningOcr,
  mergingData,
  completed,
  error,
}

class ScannerState {
  final ScannerStage stage;
  final String statusMessage;
  final ScanResult? result;
  final String? errorMessage;
  final bool isBusy;

  const ScannerState({
    this.stage = ScannerStage.idle,
    this.statusMessage = '',
    this.result,
    this.errorMessage,
    this.isBusy = false,
  });

  ScannerState copyWith({
    ScannerStage? stage,
    String? statusMessage,
    ScanResult? result,
    String? errorMessage,
    bool? isBusy,
  }) {
    return ScannerState(
      stage: stage ?? this.stage,
      statusMessage: statusMessage ?? this.statusMessage,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
      isBusy: isBusy ?? this.isBusy,
    );
  }
}

final scannerProvider = StateNotifierProvider<ScannerNotifier, ScannerState>((
  ref,
) {
  return ScannerNotifier();
});

class ScannerNotifier extends StateNotifier<ScannerState> {
  final QrDecoder _qrDecoder = QrDecoder();
  final OcrService _ocrService = OcrService();

  ScannerNotifier() : super(const ScannerState());

  /// Xử lý khi live camera bắt được mã QR
  Future<ScanResult?> handleLiveQrDetected(
    String rawPayload, {
    String? capturedImagePath,
  }) async {
    state = state.copyWith(
      stage: ScannerStage.parsingQr,
      statusMessage: 'Đang giải mã thông tin thanh toán QR...',
      isBusy: true,
      errorMessage: null,
    );

    try {
      final qrData = QrPaymentParser.parse(rawPayload);

      String? savedImagePath;
      if (capturedImagePath != null) {
        final f = File(capturedImagePath);
        if (await f.exists()) {
          savedImagePath = await ImageStorageService.saveExpenseImage(f);
        }
      }

      ParsedPaymentData? ocrData;
      String? rawOcrText;

      // Nếu có ảnh và QR thiếu số tiền hoặc tên người nhận -> kích hoạt OCR fallback/hybrid
      if (savedImagePath != null &&
          (!qrData.hasAmount || !qrData.hasMerchant)) {
        state = state.copyWith(
          stage: ScannerStage.runningOcr,
          statusMessage: 'Đang quét văn bản bổ sung (OCR)...',
        );
        try {
          rawOcrText = await _ocrService.recognizeTextFromImagePath(
            savedImagePath,
          );
          ocrData = HeuristicParser.parse(rawOcrText);
        } catch (_) {}
      }

      state = state.copyWith(
        stage: ScannerStage.mergingData,
        statusMessage: 'Đang tổng hợp thông tin giao dịch...',
      );

      final merged = PaymentDataMerger.merge(
        qrData: qrData,
        ocrData: ocrData,
        imagePath: savedImagePath,
        rawOcrText: rawOcrText,
      );

      state = state.copyWith(
        stage: ScannerStage.completed,
        statusMessage: 'Hoàn tất phân tích!',
        result: merged,
        isBusy: false,
      );

      return merged;
    } catch (e) {
      state = state.copyWith(
        stage: ScannerStage.error,
        errorMessage: 'Lỗi khi xử lý mã QR: $e',
        isBusy: false,
      );
      return null;
    }
  }

  /// Xử lý phân tích toàn diện file ảnh (từ Thư viện ảnh Gallery hoặc chụp ảnh)
  Future<ScanResult?> processImageFile(File imageFile) async {
    state = state.copyWith(
      stage: ScannerStage.detectingQr,
      statusMessage: 'Đang phân tích giao dịch...',
      isBusy: true,
      errorMessage: null,
    );

    try {
      // 1. Lưu file ảnh cục bộ
      final savedImagePath = await ImageStorageService.saveExpenseImage(
        imageFile,
      );

      // 2. Thử tìm và decode mã QR trong ảnh
      state = state.copyWith(
        stage: ScannerStage.detectingQr,
        statusMessage: 'Đang quét mã QR từ ảnh...',
      );
      final rawQr = await _qrDecoder.decodeQrFromImagePath(savedImagePath);

      QrPaymentData? qrData;
      if (rawQr != null && rawQr.isNotEmpty) {
        state = state.copyWith(
          stage: ScannerStage.parsingQr,
          statusMessage: 'Đã tìm thấy QR. Đang đọc thông tin thanh toán...',
        );
        qrData = QrPaymentParser.parse(rawQr);
      }

      // 3. Quyết định chạy OCR:
      // - Nếu KHÔNG có QR: OCR là nguồn nhận diện chính
      // - Nếu CÓ QR nhưng thiếu số tiền hoặc thiếu tên: OCR bổ sung (Hybrid)
      ParsedPaymentData? ocrData;
      String? rawOcrText;

      final needOcr =
          qrData == null || !qrData.hasAmount || !qrData.hasMerchant;
      if (needOcr) {
        state = state.copyWith(
          stage: ScannerStage.runningOcr,
          statusMessage: qrData == null
              ? 'Không tìm thấy QR. Đang thử nhận diện văn bản...'
              : 'Đang phân tích văn bản bổ sung...',
        );

        try {
          rawOcrText = await _ocrService.recognizeTextFromImagePath(
            savedImagePath,
          );
          ocrData = HeuristicParser.parse(rawOcrText);
        } catch (_) {}
      }

      // 4. Tổng hợp dữ liệu bằng Hybrid Merge Engine
      state = state.copyWith(
        stage: ScannerStage.mergingData,
        statusMessage: 'Đang hoàn tất chuẩn bị chi tiêu...',
      );

      final merged = PaymentDataMerger.merge(
        qrData: qrData,
        ocrData: ocrData,
        imagePath: savedImagePath,
        rawOcrText: rawOcrText,
      );

      state = state.copyWith(
        stage: ScannerStage.completed,
        statusMessage: 'Phân tích thành công!',
        result: merged,
        isBusy: false,
      );

      return merged;
    } catch (e) {
      state = state.copyWith(
        stage: ScannerStage.error,
        errorMessage: 'Lỗi khi phân tích ảnh: $e',
        isBusy: false,
      );
      return null;
    }
  }

  void reset() {
    state = const ScannerState();
  }

  @override
  void dispose() {
    _qrDecoder.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}
