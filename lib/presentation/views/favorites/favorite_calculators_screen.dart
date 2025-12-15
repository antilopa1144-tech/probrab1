import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../providers/favorites_provider.dart';
import '../../utils/calculator_navigation_helper.dart';
import '../calculator/calculator_catalog_screen.dart';

class FavoriteCalculatorsScreen extends ConsumerWidget {
  const FavoriteCalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final favorites = ref.watch(favoritesProvider);
    final items = [
      for (final id in favorites) (id: id, calc: CalculatorRegistry.getById(id)),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
        actions: [
          IconButton(
            tooltip: 'Все калькуляторы',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CalculatorCatalogScreen(),
                ),
              );
            },
            icon: const Icon(Icons.apps_rounded),
          ),
        ],
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Добавьте калькуляторы в избранное, чтобы быстро открывать их здесь.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: items.length,
              separatorBuilder: (context, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final calc = item.calc;

                if (calc == null) {
                  return _UnavailableFavoriteCard(
                    calculatorId: item.id,
                    onRemove: () => ref
                        .read(favoritesProvider.notifier)
                        .toggleFavorite(item.id),
                  );
                }
                return _CalculatorListCard(
                  calc: calc,
                  title: loc.translate(calc.titleKey),
                  subtitle: loc.translate('subcategory.${calc.subCategory}'),
                  isFavorite: true,
                  onToggleFavorite: () => ref
                      .read(favoritesProvider.notifier)
                      .toggleFavorite(calc.id),
                  onOpen: () => CalculatorNavigationHelper.navigateToCalculator(
                    context,
                    calc,
                  ),
                );
              },
            ),
    );
  }
}

class _UnavailableFavoriteCard extends StatelessWidget {
  final String calculatorId;
  final VoidCallback onRemove;

  const _UnavailableFavoriteCard({
    required this.calculatorId,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.help_outline_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Калькулятор недоступен',
                    style: theme.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    calculatorId,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Удалить из избранного',
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalculatorListCard extends StatelessWidget {
  final CalculatorDefinitionV2 calc;
  final String title;
  final String subtitle;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onOpen;

  const _CalculatorListCard({
    required this.calc,
    required this.title,
    required this.subtitle,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Убрать из избранного' : 'В избранное',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
