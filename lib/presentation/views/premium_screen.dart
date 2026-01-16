import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/premium_provider.dart';
import '../../domain/models/premium_subscription.dart';
import '../../core/services/premium_service.dart';

/// Экран Premium подписки
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync = ref.watch(currentSubscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber.shade700,
            ),
            const SizedBox(width: 8),
            const Text('Premium'),
          ],
        ),
      ),
      body: subscriptionAsync.when(
        data: (subscription) {
          if (subscription.isActive && !subscription.isExpired) {
            return _PremiumActiveView(subscription: subscription);
          }
          return const _PremiumOffersView();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Ошибка загрузки: $error'),
            ],
          ),
        ),
      ),
    );
  }
}

/// Вид для активной Premium подписки
class _PremiumActiveView extends StatelessWidget {
  final PremiumSubscription subscription;

  const _PremiumActiveView({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Premium статус
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.amber.shade400,
                Colors.orange.shade600,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.workspace_premium_rounded,
                size: 64,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                'Premium активен',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getSubscriptionTypeText(subscription.type),
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha:0.9),
                ),
              ),
              if (subscription.expiryDate != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Действует до ${_formatDate(subscription.expiryDate!)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha:0.8),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Доступные функции
        Text(
          'Доступные функции',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        const _FeatureItem(
          icon: Icons.calculate_rounded,
          title: 'Расширенные калькуляторы',
          description: '3D панели, тёплый пол, деревянная вагонка и другие',
        ),
        const _FeatureItem(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Экспорт в PDF',
          description: 'Сохраняйте расчёты в PDF документы',
        ),
        const _FeatureItem(
          icon: Icons.list_alt_rounded,
          title: 'Детальные списки материалов',
          description: 'Полные списки с количеством',
        ),
        const _FeatureItem(
          icon: Icons.qr_code_rounded,
          title: 'QR-коды расчётов',
          description: 'Делитесь расчётами через QR-коды',
        ),
        const _FeatureItem(
          icon: Icons.mic_rounded,
          title: 'Голосовой ввод',
          description: 'Вводите размеры голосом',
        ),

        const SizedBox(height: 24),

        // Управление подпиской
        if (subscription.type != SubscriptionType.lifetime) ...[
          Consumer(
            builder: (context, ref, _) {
              return OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(premiumPurchaseProvider.notifier)
                      .cancelSubscription();
                },
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Управление подпиской'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  String _getSubscriptionTypeText(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.monthly:
        return 'Месячная подписка';
      case SubscriptionType.yearly:
        return 'Годовая подписка';
      case SubscriptionType.lifetime:
        return 'Пожизненная лицензия';
      case SubscriptionType.free:
        return 'Бесплатная версия';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}

/// Вид с предложениями Premium подписки
class _PremiumOffersView extends ConsumerWidget {
  const _PremiumOffersView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final productsAsync = ref.watch(availableProductsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Заголовок
        Text(
          'Получите Premium',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Разблокируйте все возможности приложения',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Функции Premium
        const _FeatureItem(
          icon: Icons.calculate_rounded,
          title: 'Расширенные калькуляторы',
          description: '3D панели, тёплый пол, деревянная вагонка и другие',
        ),
        const _FeatureItem(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Экспорт в PDF',
          description: 'Сохраняйте расчёты в PDF документы',
        ),
        const _FeatureItem(
          icon: Icons.list_alt_rounded,
          title: 'Детальные списки материалов',
          description: 'Полные списки с количеством',
        ),
        const _FeatureItem(
          icon: Icons.qr_code_rounded,
          title: 'QR-коды расчётов',
          description: 'Делитесь расчётами через QR-коды',
        ),
        const _FeatureItem(
          icon: Icons.mic_rounded,
          title: 'Голосовой ввод',
          description: 'Вводите размеры голосом',
        ),

        const SizedBox(height: 32),

        // Предложения подписок
        productsAsync.when(
          data: (products) {
            return Column(
              children: products.map((product) {
                return _ProductCard(product: product);
              }).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // Кнопка восстановления покупок
        Consumer(
          builder: (context, ref, _) {
            final purchaseState = ref.watch(premiumPurchaseProvider);

            return TextButton.icon(
              onPressed: purchaseState.isLoading
                  ? null
                  : () async {
                      await ref
                          .read(premiumPurchaseProvider.notifier)
                          .restorePurchases();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Покупки восстановлены'),
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Восстановить покупки'),
            );
          },
        ),
      ],
    );
  }
}

/// Карточка продукта
class _ProductCard extends ConsumerWidget {
  final PremiumProduct product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final purchaseState = ref.watch(premiumPurchaseProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: product.isRecommended ? 4 : 1,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      product.price,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                if (product.discount != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.discountText!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.green.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: purchaseState.isLoading
                        ? null
                        : () async {
                            await ref
                                .read(premiumPurchaseProvider.notifier)
                                .purchaseProduct(product.id);

                            if (context.mounted) {
                              final success = ref.read(premiumPurchaseProvider).value ?? false;
                              if (success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Premium активирован!'),
                                  ),
                                );
                                Navigator.of(context).pop();
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor: product.isRecommended
                          ? Colors.amber.shade600
                          : null,
                    ),
                    child: purchaseState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Купить'),
                  ),
                ),
              ],
            ),
          ),
          if (product.isRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade600,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Рекомендуем',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (product.isBestValue && !product.isRecommended)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade600,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Лучшая цена',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Элемент функции
class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.amber.shade700,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
