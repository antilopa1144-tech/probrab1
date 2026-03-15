import 'package:flutter/material.dart';
import '../../views/premium_screen.dart';
import '../../../core/localization/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);

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
            description ?? loc.translate('premium.lock.description_default'),
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
                  loc.translate('premium.lock.feature_advanced_calculators'),
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
                  loc.translate('premium.lock.feature_unlimited_projects'),
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
                  loc.translate('premium.lock.feature_pdf_export'),
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
                  loc.translate('premium.lock.feature_more'),
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
          child: Text(loc.translate('button.cancel')),
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
          label: Text(loc.translate('premium.get')),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.amber.shade600,
          ),
        ),
      ],
    );
  }
}

