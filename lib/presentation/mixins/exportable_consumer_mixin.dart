import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/models/calculator_result_payload.dart';
import '../../domain/models/shareable_content.dart';
import '../views/calculator/calculator_qr_share_screen.dart';

/// Миксин для добавления функциональности экспорта (share/copy) в Riverpod-калькуляторы.
///
/// Использование:
/// ```dart
/// class _MyCalculatorScreenState extends ConsumerState<MyCalculatorScreen>
///     with ExportableConsumerMixin {
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
mixin ExportableConsumerMixin<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  /// Локализация для получения переводов.
  AppLocalizations get loc;

  /// Тема письма/сообщения при отправке.
  String get exportSubject;

  /// Генерация текста для экспорта.
  /// Должен быть реализован в классе, использующем миксин.
  String generateExportText();

  /// Optional: Override if calculator should support saving to projects.
  /// Returns null by default (no project save support).
  CalculatorResultPayload? buildResultPayload() => null;

  /// Optional: Override to indicate if this calculator was opened from a project.
  /// Returns false by default.
  bool get isFromProject => false;

  /// Calculator ID for deep links (e.g., 'gypsum', 'brick', 'tile').
  /// Must be implemented by calculators that support QR code sharing.
  /// Returns null by default (no QR support).
  String? get calculatorId => null;

  /// Get current calculator inputs as `Map<String, dynamic>`.
  /// Must be implemented by calculators that support QR code sharing.
  /// Returns null by default (no QR support).
  Map<String, dynamic>? getCurrentInputs() => null;

  /// Share calculator state via QR code.
  /// Only works if calculatorId and getCurrentInputs are implemented.
  Future<void> shareAsQrCode() async {
    final calcId = calculatorId;
    final inputs = getCurrentInputs();

    if (calcId == null || inputs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('error.qr_not_supported')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Convert Map<String, dynamic> to Map<String, double>
    final inputsMap = inputs.map((key, value) {
      final doubleValue = value is num ? value.toDouble() : 0.0;
      return MapEntry(key, doubleValue);
    });

    final shareableCalc = ShareableCalculator(
      calculatorId: calcId,
      calculatorName: exportSubject,
      inputs: inputsMap,
    );

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalculatorQrShareScreen(
          calculator: shareableCalc,
          calculatorDisplayName: exportSubject,
        ),
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

  /// Save calculation to project and return to project screen
  void _saveToProject() {
    final payload = buildResultPayload();
    if (payload != null) {
      Navigator.pop(context, payload);
    }
  }

  /// Show "Save to Project" action if opened from project
  Widget? get saveToProjectAction {
    if (!isFromProject || buildResultPayload() == null) return null;

    return IconButton(
      icon: const Icon(Icons.save_rounded),
      onPressed: _saveToProject,
      tooltip: loc.translate('button.save_to_project'),
    );
  }

  /// Удобный геттер для получения действий экспорта (иконки share/copy/qr).
  List<Widget> get exportActions => [
        if (saveToProjectAction != null) saveToProjectAction!,
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
        if (calculatorId != null && getCurrentInputs() != null)
          IconButton(
            icon: const Icon(Icons.qr_code_2_rounded),
            onPressed: shareAsQrCode,
            tooltip: 'Поделиться QR-кодом',
          ),
      ];
}
