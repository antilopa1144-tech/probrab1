import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../common/share_options_dialog.dart';

/// Callback для генерации текста экспорта
typedef GenerateExportText = String Function();

/// Callback для генерации данных QR кода
typedef GenerateQrData = String? Function();

/// Кнопка для шаринга результатов калькулятора с расширенными опциями
class CalculatorShareButton extends StatelessWidget {
  /// Генератор текста для экспорта
  final GenerateExportText generateExportText;

  /// Генератор данных для QR кода (опционально)
  final GenerateQrData? generateQrData;

  /// Тема сообщения при шаринге
  final String? subject;

  /// Показывать как IconButton (по умолчанию true)
  final bool asIconButton;

  /// Иконка кнопки (по умолчанию Icons.share)
  final IconData icon;

  /// Подсказка при наведении
  final String? tooltip;

  /// Метка кнопки (если asIconButton = false)
  final String? label;

  /// Callback при успешном копировании
  final VoidCallback? onCopied;

  /// Callback при успешном шаринге
  final VoidCallback? onShared;

  /// Callback при открытии QR кода
  final VoidCallback? onQrOpened;

  const CalculatorShareButton({
    super.key,
    required this.generateExportText,
    this.generateQrData,
    this.subject,
    this.asIconButton = true,
    this.icon = Icons.share,
    this.tooltip,
    this.label,
    this.onCopied,
    this.onShared,
    this.onQrOpened,
  });

  @override
  Widget build(BuildContext context) {
    if (asIconButton) {
      return IconButton(
        icon: Icon(icon),
        onPressed: () => _showShareOptions(context),
        tooltip: tooltip ?? 'Поделиться',
      );
    }

    return FilledButton.icon(
      onPressed: () => _showShareOptions(context),
      icon: Icon(icon),
      label: Text(label ?? 'Поделиться'),
    );
  }

  Future<void> _showShareOptions(BuildContext context) async {
    final hasQrSupport = generateQrData != null;

    final result = await showDialog<ShareAction>(
      context: context,
      builder: (context) => ShareOptionsDialog(
        showQrOption: hasQrSupport,
      ),
    );

    if (result != null && context.mounted) {
      await _handleShareAction(context, result);
    }
  }

  Future<void> _handleShareAction(
    BuildContext context,
    ShareAction action,
  ) async {
    switch (action) {
      case ShareAction.copy:
        await _copyToClipboard(context);
        break;
      case ShareAction.share:
        await _share(context);
        break;
      case ShareAction.qr:
        _showQrCode(context);
        break;
    }
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final text = generateExportText();
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Скопировано в буфер обмена'),
          duration: Duration(seconds: 2),
        ),
      );
      onCopied?.call();
    }
  }

  Future<void> _share(BuildContext context) async {
    final text = generateExportText();
    onShared?.call();
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }

  void _showQrCode(BuildContext context) {
    final qrData = generateQrData?.call();
    if (qrData == null || qrData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR код недоступен для текущих данных'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    onQrOpened?.call();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR код расчёта'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Отсканируйте QR код для импорта данных',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code_2,
                size: 200,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Данные: ${qrData.length} символов',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }
}

/// Кнопка для быстрого копирования (без диалога)
class CalculatorCopyButton extends StatelessWidget {
  final GenerateExportText generateExportText;
  final String? tooltip;
  final VoidCallback? onCopied;

  const CalculatorCopyButton({
    super.key,
    required this.generateExportText,
    this.tooltip,
    this.onCopied,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.copy),
      onPressed: () => _copyToClipboard(context),
      tooltip: tooltip ?? 'Копировать',
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    final text = generateExportText();
    await Clipboard.setData(ClipboardData(text: text));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Скопировано в буфер обмена'),
          duration: Duration(seconds: 2),
        ),
      );
      onCopied?.call();
    }
  }
}

/// Кнопка для быстрого шаринга (без диалога)
class CalculatorQuickShareButton extends StatelessWidget {
  final GenerateExportText generateExportText;
  final String? subject;
  final String? tooltip;
  final VoidCallback? onShared;

  const CalculatorQuickShareButton({
    super.key,
    required this.generateExportText,
    this.subject,
    this.tooltip,
    this.onShared,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: _share,
      tooltip: tooltip ?? 'Поделиться',
    );
  }

  Future<void> _share() async {
    final text = generateExportText();
    onShared?.call();
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: subject,
      ),
    );
  }
}
