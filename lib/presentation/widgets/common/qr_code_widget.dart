import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Виджет для отображения QR кода с настраиваемыми параметрами
class QrCodeWidget extends StatelessWidget {
  /// Данные для генерации QR кода
  final String data;

  /// Размер QR кода (по умолчанию 200)
  final double size;

  /// Цвет фона (по умолчанию белый)
  final Color backgroundColor;

  /// Цвет QR кода (по умолчанию чёрный)
  final Color foregroundColor;

  /// Уровень коррекции ошибок
  final int errorCorrectionLevel;

  /// Встроенное изображение (логотип в центре)
  final ImageProvider? embeddedImage;

  /// Размер встроенного изображения
  final Size? embeddedImageSize;

  /// Отступы вокруг QR кода
  final EdgeInsetsGeometry? padding;

  /// Скругление углов контейнера
  final BorderRadius? borderRadius;

  /// Тень контейнера
  final List<BoxShadow>? boxShadow;

  /// Показывать ли контейнер с фоном
  final bool showContainer;

  const QrCodeWidget({
    super.key,
    required this.data,
    this.size = 200,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
    this.embeddedImage,
    this.embeddedImageSize,
    this.padding,
    this.borderRadius,
    this.boxShadow,
    this.showContainer = true,
  });

  /// Конструктор для QR кода без контейнера
  const QrCodeWidget.plain({
    super.key,
    required this.data,
    this.size = 200,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.errorCorrectionLevel = QrErrorCorrectLevel.M,
    this.embeddedImage,
    this.embeddedImageSize,
  })  : padding = null,
        borderRadius = null,
        boxShadow = null,
        showContainer = false;

  /// Конструктор для маленького QR кода
  const QrCodeWidget.small({
    super.key,
    required this.data,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.errorCorrectionLevel = QrErrorCorrectLevel.L,
    this.embeddedImage,
    this.showContainer = false,
  })  : size = 100,
        embeddedImageSize = const Size(20, 20),
        padding = null,
        borderRadius = null,
        boxShadow = null;

  /// Конструктор для большого QR кода с декорацией
  QrCodeWidget.large({
    super.key,
    required this.data,
    this.backgroundColor = Colors.white,
    this.foregroundColor = Colors.black,
    this.errorCorrectionLevel = QrErrorCorrectLevel.H,
    this.embeddedImage,
  })  : size = 300,
        embeddedImageSize = const Size(60, 60),
        padding = const EdgeInsets.all(24),
        borderRadius = BorderRadius.circular(16),
        boxShadow = [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        showContainer = true;

  @override
  Widget build(BuildContext context) {
    final qrImageView = QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: backgroundColor,
      eyeStyle: QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: foregroundColor,
      ),
      dataModuleStyle: QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: foregroundColor,
      ),
      errorCorrectionLevel: errorCorrectionLevel,
      embeddedImage: embeddedImage,
      embeddedImageStyle: embeddedImage != null
          ? QrEmbeddedImageStyle(
              size: embeddedImageSize ?? Size(size * 0.2, size * 0.2),
            )
          : null,
    );

    if (!showContainer) {
      return qrImageView;
    }

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
      ),
      child: qrImageView,
    );
  }
}

/// Расширение для удобного создания QR кодов с предустановленными стилями
extension QrCodeStyles on QrCodeWidget {
  /// Стиль для проектов
  static QrCodeWidget forProject({
    required String data,
    ImageProvider? logo,
  }) {
    return QrCodeWidget.large(
      data: data,
      embeddedImage: logo,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  /// Стиль для калькуляторов
  static QrCodeWidget forCalculator({
    required String data,
    ImageProvider? logo,
  }) {
    return QrCodeWidget(
      data: data,
      size: 250,
      embeddedImage: logo,
      embeddedImageSize: const Size(50, 50),
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );
  }

  /// Стиль для превью (маленький)
  static QrCodeWidget preview({
    required String data,
  }) {
    return QrCodeWidget.small(
      data: data,
      showContainer: true,
    );
  }
}
