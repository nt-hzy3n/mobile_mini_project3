import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/services/permission_service.dart';
import '../../../providers/scanner_provider.dart';
import '../../../widgets/loading_overlay.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _cameraController;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTorchOn = false;
  bool _hasCameraPermission = true;
  late AnimationController _animController;
  late Animation<double> _laserAnim;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _laserAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final granted = await PermissionService.requestCameraPermission();
    if (mounted) {
      setState(() {
        _hasCameraPermission = granted;
      });
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetect(BarcodeCapture capture) async {
    final scannerState = ref.read(scannerProvider);
    if (scannerState.isBusy) return;

    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
        final raw = barcode.rawValue!;
        // Pause camera while processing
        await _cameraController.stop();

        final result = await ref
            .read(scannerProvider.notifier)
            .handleLiveQrDetected(raw);

        if (mounted && result != null) {
          context.pushReplacement('/review');
          return;
        } else {
          // Resume if failed
          await _cameraController.start();
        }
        break;
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final granted = await PermissionService.requestPhotosPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng cấp quyền truy cập ảnh trong Cài đặt'),
          ),
        );
      }
      return;
    }

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );

      if (picked != null) {
        await _cameraController.stop();

        final result = await ref
            .read(scannerProvider.notifier)
            .processImageFile(File(picked.path));

        if (mounted && result != null) {
          context.pushReplacement('/review');
        } else {
          await _cameraController.start();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể chọn ảnh: $e')));
      }
    }
  }

  Future<void> _captureImageFromCamera() async {
    final granted = await PermissionService.requestCameraPermission();
    if (!granted) return;

    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );

      if (picked != null) {
        await _cameraController.stop();

        final result = await ref
            .read(scannerProvider.notifier)
            .processImageFile(File(picked.path));

        if (mounted && result != null) {
          context.pushReplacement('/review');
        } else {
          await _cameraController.start();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Không thể chụp ảnh: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerProvider);
    final size = MediaQuery.of(context).size;
    final frameSize = size.width * 0.72;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera View
          if (_hasCameraPermission)
            MobileScanner(
              controller: _cameraController,
              onDetect: _onBarcodeDetect,
              errorBuilder: (context, error) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Không thể khởi động camera: ${error.errorCode}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            )
          else
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: Colors.white54,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Cần cấp quyền Camera để quét mã QR',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _checkPermission,
                    child: const Text('Cấp quyền'),
                  ),
                ],
              ),
            ),

          // 2. Darkness Mask with Frame Hole
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6),
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, -0.15),
                  child: Container(
                    width: frameSize,
                    height: frameSize,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. QR Frame Border with Corner Guides & Laser
          Align(
            alignment: const Alignment(0, -0.15),
            child: SizedBox(
              width: frameSize,
              height: frameSize,
              child: Stack(
                children: [
                  // Corner Guides
                  CustomPaint(
                    size: Size(frameSize, frameSize),
                    painter: QrFramePainter(color: Colors.white),
                  ),
                  // Animated Scanning Laser Line
                  AnimatedBuilder(
                    animation: _laserAnim,
                    builder: (context, child) {
                      return Positioned(
                        top: _laserAnim.value * (frameSize - 20) + 10,
                        left: 14,
                        right: 14,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color(0xFF64B5F6),
                                Colors.white,
                                Color(0xFF64B5F6),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF64B5F6).withOpacity(0.8),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 4. Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Đóng',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    'Quét thanh toán',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    tooltip: _isTorchOn ? 'Tắt đèn pin' : 'Bật đèn pin',
                    icon: Icon(
                      _isTorchOn
                          ? Icons.flash_on_rounded
                          : Icons.flash_off_rounded,
                      color: _isTorchOn ? Colors.amber : Colors.white,
                    ),
                    onPressed: () async {
                      await _cameraController.toggleTorch();
                      setState(() {
                        _isTorchOn = !_isTorchOn;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // 5. Instruction Text & Action Buttons at Bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Căn chỉnh mã QR hoặc ảnh chuyển khoản vào khung hình',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery Button
                        _buildActionButton(
                          icon: Icons.photo_library_rounded,
                          label: 'Từ thư viện',
                          onTap: _pickImageFromGallery,
                        ),
                        // Camera Capture Button
                        _buildActionButton(
                          icon: Icons.camera_alt_rounded,
                          label: 'Chụp ảnh',
                          onTap: _captureImageFromCamera,
                        ),
                        // Switch Camera Button
                        _buildActionButton(
                          icon: Icons.flip_camera_ios_rounded,
                          label: 'Đổi camera',
                          onTap: () async {
                            await _cameraController.switchCamera();
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 6. Loading Overlay when analyzing
          if (scannerState.isBusy)
            LoadingOverlay(message: scannerState.statusMessage),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30, width: 1.5),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class QrFramePainter extends CustomPainter {
  final Color color;

  QrFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const cornerLength = 36.0;
    const strokeWidth = 4.5;
    const radius = 24.0;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-Left
    final pathTL = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..quadraticBezierTo(0, 0, radius, 0)
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTL, paint);

    // Top-Right
    final pathTR = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, radius)
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(pathTR, paint);

    // Bottom-Left
    final pathBL = Path()
      ..moveTo(0, size.height - cornerLength)
      ..lineTo(0, size.height - radius)
      ..quadraticBezierTo(0, size.height, radius, size.height)
      ..lineTo(cornerLength, size.height);
    canvas.drawPath(pathBL, paint);

    // Bottom-Right
    final pathBR = Path()
      ..moveTo(size.width - cornerLength, size.height)
      ..lineTo(size.width - radius, size.height)
      ..quadraticBezierTo(
        size.width,
        size.height,
        size.width,
        size.height - radius,
      )
      ..lineTo(size.width, size.height - cornerLength);
    canvas.drawPath(pathBR, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
