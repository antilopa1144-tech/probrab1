import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_localizations.dart';
import '../services/pdf_export_service.dart';

/// Миксин для добавления функциональности экспорта (share/copy) в калькуляторы.
///
/// Использование:
/// ```dart
/// class _MyCalculatorScreenState extends State<MyCalculatorScreen>
///     with ExportableMixin {
///   @override
///   AppLocalizations get loc => _loc;
///
///   @override
///   String get exportSubject => loc.translate('my_calc.title');
///
///   @override
///   String generateExportText() {
///     return 'Результат расчёта...';
///   }
/// }
/// ```
mixin ExportableMixin<T extends StatefulWidget> on State<T> {
  /// Локализация для получения переводов.
  AppLocalizations get loc;

  /// Тема письма/сообщения при отправке.
  String get exportSubject;

  /// Генерация текста для экспорта.
  /// Должен быть реализован в классе, использующем миксин.
  String generateExportText();

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

  /// Экспорт результата в PDF (открыть диалог печати).
  Future<void> exportPdf() async {
    await PdfExportService.exportFromText(
      title: exportSubject,
      text: generateExportText(),
      saveLocally: false,
    );
  }

  /// Скачать результат как PDF файл локально.
  Future<void> downloadPdf() async {
    final filePath = await PdfExportService.exportFromText(
      title: exportSubject,
      text: generateExportText(),
      saveLocally: true,
    );

    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('common.pdf_saved_to', {'path': filePath})),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Удобный геттер для получения действий экспорта (иконки share/copy/pdf).
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
        IconButton(
          icon: const Icon(Icons.download_rounded),
          onPressed: downloadPdf,
          tooltip: loc.translate('common.download_pdf'),
        ),
      ];
}
