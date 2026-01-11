import 'package:flutter/material.dart';

/// Возможные действия при шаринге
enum ShareAction {
  /// Копировать в буфер обмена
  copy,

  /// Поделиться через системный диалог
  share,

  /// Показать QR код
  qr,
}

/// Диалог с опциями для шаринга результатов
class ShareOptionsDialog extends StatelessWidget {
  /// Показывать ли опцию QR кода
  final bool showQrOption;

  /// Заголовок диалога
  final String? title;

  /// Подзаголовок диалога
  final String? subtitle;

  /// Кастомный текст для кнопки копирования
  final String? copyLabel;

  /// Кастомный текст для кнопки шаринга
  final String? shareLabel;

  /// Кастомный текст для кнопки QR кода
  final String? qrLabel;

  const ShareOptionsDialog({
    super.key,
    this.showQrOption = false,
    this.title,
    this.subtitle,
    this.copyLabel,
    this.shareLabel,
    this.qrLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(title ?? 'Поделиться результатом'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
          ],
          _OptionTile(
            icon: Icons.copy_rounded,
            title: copyLabel ?? 'Копировать',
            subtitle: 'Скопировать текст в буфер обмена',
            onTap: () => Navigator.pop(context, ShareAction.copy),
          ),
          const SizedBox(height: 8),
          _OptionTile(
            icon: Icons.share_rounded,
            title: shareLabel ?? 'Поделиться',
            subtitle: 'Отправить через мессенджер или email',
            onTap: () => Navigator.pop(context, ShareAction.share),
          ),
          if (showQrOption) ...[
            const SizedBox(height: 8),
            _OptionTile(
              icon: Icons.qr_code_2_rounded,
              title: qrLabel ?? 'QR код',
              subtitle: 'Показать QR код для сканирования',
              onTap: () => Navigator.pop(context, ShareAction.qr),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
      ],
    );
  }
}

/// Элемент опции в диалоге
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.onPrimaryContainer,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

/// Функция для показа диалога шаринга
Future<ShareAction?> showShareOptionsDialog(
  BuildContext context, {
  bool showQrOption = false,
  String? title,
  String? subtitle,
}) {
  return showDialog<ShareAction>(
    context: context,
    builder: (context) => ShareOptionsDialog(
      showQrOption: showQrOption,
      title: title,
      subtitle: subtitle,
    ),
  );
}

/// Компактная версия диалога (только иконки)
class CompactShareOptionsDialog extends StatelessWidget {
  final bool showQrOption;

  const CompactShareOptionsDialog({
    super.key,
    this.showQrOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SimpleDialog(
      title: const Text('Поделиться'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, ShareAction.copy),
          child: Row(
            children: [
              Icon(Icons.copy_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              const Text('Копировать'),
            ],
          ),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.pop(context, ShareAction.share),
          child: Row(
            children: [
              Icon(Icons.share_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 16),
              const Text('Поделиться'),
            ],
          ),
        ),
        if (showQrOption)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, ShareAction.qr),
            child: Row(
              children: [
                Icon(Icons.qr_code_2_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 16),
                const Text('QR код'),
              ],
            ),
          ),
      ],
    );
  }
}
