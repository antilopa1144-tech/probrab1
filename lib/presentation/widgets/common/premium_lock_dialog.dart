import 'package:flutter/material.dart';
import '../../views/premium_screen.dart';

/// Диалог блокировки Premium функций
class PremiumLockDialog extends StatelessWidget {
  final String featureName;
  final String? description;

  const PremiumLockDialog({
    super.key,
    required this.featureName,
    this.description,
  });

  /// Показать диалог и вернуть true если пользователь перешёл на экран Premium
  static Future<bool> show(
    BuildContext context, {
    required String featureName,
    String? description,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumLockDialog(
        featureName: featureName,
        description: description,
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber.shade400,
                  Colors.orange.shade600,
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            featureName,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description ?? 'Эта функция доступна только в Premium версии',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Расширенные калькуляторы',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Неограниченное число проектов',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Экспорт в PDF',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 20,
                color: Colors.green,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'И многое другое...',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton.icon(
          onPressed: () {
            Navigator.of(context).pop(true);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PremiumScreen(),
              ),
            );
          },
          icon: const Icon(Icons.workspace_premium_rounded),
          label: const Text('Получить Premium'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.amber.shade600,
          ),
        ),
      ],
    );
  }
}
