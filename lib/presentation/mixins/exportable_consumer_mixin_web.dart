// Веб-версия миксина для экспорта результатов калькуляторов
// Без зависимостей от Isar (сохранение в проекты и QR-шаринг отключены)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_localizations.dart';

/// Веб-версия типа CalculatorResultPayload (заглушка)
/// Используется только для совместимости интерфейса миксина
class CalculatorResultPayload {
  const CalculatorResultPayload._();
}

/// Веб-версия миксина для экспорта результатов калькуляторов.
/// Без поддержки сохранения в проекты и QR-шаринга (Isar-зависимости отключены).
mixin ExportableConsumerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Локализация для получения переводов.
  AppLocalizations get loc;

  /// Тема письма/сообщения при отправке.
  String get exportSubject;

  /// Генерация текста для экспорта.
  /// Должен быть реализован в классе, использующем миксин.
  String generateExportText();

  /// На вебе сохранение в проекты не поддерживается - всегда возвращает null.
  CalculatorResultPayload? buildResultPayload() => null;

  /// На вебе всегда false - проекты не поддерживаются.
  bool get isFromProject => false;

  /// Calculator ID for deep links - на вебе не используется.
  String? get calculatorId => null;

  /// Get current calculator inputs - на вебе не используется.
  Map<String, dynamic>? getCurrentInputs() => null;

  /// QR-шаринг на вебе отключён.
  Future<void> shareAsQrCode() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('error.qr_not_supported')),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// Поделиться результатом расчёта.
  void shareCalculation() {
    final text = generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: exportSubject));
  }

  /// Скопировать результат в буфер обмена.
  void copyToClipboard() {
    final text = generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// На вебе сохранение в проекты не поддерживается
  Widget? get saveToProjectAction => null;

  /// Удобный геттер для получения действий экспорта (иконки share/copy).
  /// QR отключён на вебе.
  List<Widget> get exportActions => [
        IconButton(
          icon: const Icon(Icons.copy_rounded),
          onPressed: copyToClipboard,
          tooltip: loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: shareCalculation,
          tooltip: loc.translate('common.share'),
        ),
        // QR-шаринг отключён на вебе из-за Isar-зависимостей
      ];
}
