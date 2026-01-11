import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/premium_provider.dart';

/// Badge показывающий Premium статус пользователя
class PremiumBadge extends ConsumerWidget {
  final bool showLabel;
  final double iconSize;
  final EdgeInsets? padding;

  const PremiumBadge({
    super.key,
    this.showLabel = true,
    this.iconSize = 20,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);

    if (!isPremium) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade400,
            Colors.orange.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: iconSize,
            color: Colors.white,
          ),
          if (showLabel) ...[
            const SizedBox(width: 6),
            Text(
              'PREMIUM',
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Кнопка-приглашение на Premium (для бесплатных пользователей)
class PremiumUpgradeButton extends ConsumerWidget {
  final VoidCallback? onTap;
  final bool compact;

  const PremiumUpgradeButton({
    super.key,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPremium = ref.watch(isPremiumProvider);

    if (isPremium) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return IconButton(
        onPressed: onTap,
        icon: Icon(
          Icons.workspace_premium_outlined,
          color: Colors.amber.shade700,
        ),
        tooltip: 'Получить Premium',
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade400,
              Colors.orange.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.shade200.withValues(alpha:0.5),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Получить Premium',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Разблокировать все функции',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha:0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Карточка-блокировка для Premium функций
class PremiumFeatureCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? onUpgrade;

  const PremiumFeatureCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
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
              child: Icon(
                icon,
                size: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_rounded,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Получить Premium'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Индикатор окончания подписки
class SubscriptionExpiryIndicator extends ConsumerWidget {
  const SubscriptionExpiryIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);

    return subscriptionAsync.when(
      data: (subscription) {
        if (!subscription.isActive || subscription.expiryDate == null) {
          return const SizedBox.shrink();
        }

        final daysLeft = subscription.daysUntilExpiry;
        if (daysLeft == null || daysLeft > 7) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade900,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  daysLeft > 0
                      ? 'Подписка истекает через $daysLeft ${_getDaysWord(daysLeft)}'
                      : 'Подписка истекла',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  String _getDaysWord(int days) {
    if (days % 10 == 1 && days % 100 != 11) {
      return 'день';
    } else if (days % 10 >= 2 && days % 10 <= 4 && (days % 100 < 10 || days % 100 >= 20)) {
      return 'дня';
    } else {
      return 'дней';
    }
  }
}
