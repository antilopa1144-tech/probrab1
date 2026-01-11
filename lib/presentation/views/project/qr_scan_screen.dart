import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/services/deep_link_service.dart';

/// Экран сканирования QR кодов
class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  bool _isProcessing = false;
  bool _torchOn = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleTorch() {
    setState(() {
      _torchOn = !_torchOn;
    });
    _controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканировать QR код'),
        actions: [
          IconButton(
            onPressed: _toggleTorch,
            icon: Icon(
              _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            ),
          ),
          IconButton(
            onPressed: () => _controller.switchCamera(),
            icon: const Icon(Icons.flip_camera_android_rounded),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Камера
          MobileScanner(
            controller: _controller,
            onDetect: _onQRDetected,
          ),

          // Рамка сканирования
          CustomPaint(
            painter: _ScannerOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Инструкция внизу
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha:0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Наведите камеру на QR код',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'QR код будет отсканирован автоматически',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha:0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          // Индикатор загрузки
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha:0.5),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  void _onQRDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final qrData = barcodes.first.rawValue;
    if (qrData == null || qrData.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      // Парсинг QR кода
      final deepLinkData = await DeepLinkService.instance.parseQRCode(qrData);

      if (deepLinkData == null) {
        if (mounted) {
          _showError('Неверный QR код', 'Этот QR код не является ссылкой на проект');
        }
        return;
      }

      // Обработать Deep Link
      if (mounted) {
        final handler = DeepLinkHandler(context);
        await handler.handle(deepLinkData);

        // Закрыть экран сканирования после успешной обработки
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка', 'Не удалось обработать QR код: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.orange),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Рисует рамку сканирования поверх камеры
class _ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scanAreaSize = size.width * 0.7;
    final left = (size.width - scanAreaSize) / 2;
    final top = (size.height - scanAreaSize) / 2;

    // Затемнение фона
    final backgroundPaint = Paint()..color = Colors.black.withValues(alpha:0.5);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      backgroundPaint,
    );

    // Прозрачная область для сканирования
    final clearPaint = Paint()..blendMode = BlendMode.clear;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, scanAreaSize, scanAreaSize),
        const Radius.circular(16),
      ),
      clearPaint,
    );

    // Рамка
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const cornerLength = 30.0;

    // Верхний левый угол
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top),
      Offset(left, top + cornerLength),
      borderPaint,
    );

    // Верхний правый угол
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize - cornerLength, top),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top),
      Offset(left + scanAreaSize, top + cornerLength),
      borderPaint,
    );

    // Нижний левый угол
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left + cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left, top + scanAreaSize),
      Offset(left, top + scanAreaSize - cornerLength),
      borderPaint,
    );

    // Нижний правый угол
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize - cornerLength, top + scanAreaSize),
      borderPaint,
    );
    canvas.drawLine(
      Offset(left + scanAreaSize, top + scanAreaSize),
      Offset(left + scanAreaSize, top + scanAreaSize - cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
