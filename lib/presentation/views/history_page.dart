import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/calculation_provider.dart';
import '../../core/widgets/staggered_animation.dart';
import '../../core/widgets/animated_empty_state.dart';
import '../utils/calculation_display.dart';
import '../../core/localization/app_localizations.dart';
import '../../domain/calculators/history_category.dart';
import 'history/widgets/history_calculation_card.dart';
import 'history/widgets/history_filter_chip.dart';
import 'history/widgets/history_stat_card.dart';

/// Страница истории расчётов
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _searchQuery = '';
  HistoryCategory _selectedCategory = HistoryCategory.all;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final calculationsAsync = ref.watch(calculationsProvider);
    final statistics = ref.watch(statisticsProvider);

    return Column(
      children: [
        // Статистика вверху
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          child: statistics.when(
            data: (stats) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                HistoryStatCard(
                  icon: Icons.calculate,
                  label: 'Расчётов',
                  value: '${stats['totalCalculations']}',
                  color: Colors.blue,
                ),
                // Цены временно скрыты до интеграции с магазинами
                // _StatCard(
                //   icon: Icons.monetization_on,
                //   label: 'Общая сумма',
                //   value: '${(stats['totalCost'] / 1000).toStringAsFixed(0)}k ₽',
                //   color: Colors.green,
                // ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const SizedBox(),
          ),
        ),

        // Поиск и фильтры
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Поиск расчётов...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    HistoryFilterChip(
                      label: loc.translate(HistoryCategory.all.translationKey),
                      selected: _selectedCategory == HistoryCategory.all,
                      onSelected: () =>
                          setState(() => _selectedCategory = HistoryCategory.all),
                    ),
                    HistoryFilterChip(
                      label: loc
                          .translate(HistoryCategory.foundation.translationKey),
                      selected: _selectedCategory == HistoryCategory.foundation,
                      onSelected: () =>
                          setState(() =>
                              _selectedCategory = HistoryCategory.foundation),
                    ),
                    HistoryFilterChip(
                      label: loc.translate(HistoryCategory.walls.translationKey),
                      selected: _selectedCategory == HistoryCategory.walls,
                      onSelected: () =>
                          setState(() =>
                              _selectedCategory = HistoryCategory.walls),
                    ),
                    HistoryFilterChip(
                      label:
                          loc.translate(HistoryCategory.roofing.translationKey),
                      selected: _selectedCategory == HistoryCategory.roofing,
                      onSelected: () =>
                          setState(() =>
                              _selectedCategory = HistoryCategory.roofing),
                    ),
                    HistoryFilterChip(
                      label: loc
                          .translate(HistoryCategory.finishing.translationKey),
                      selected: _selectedCategory == HistoryCategory.finishing,
                      onSelected: () =>
                          setState(() =>
                              _selectedCategory = HistoryCategory.finishing),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Список расчётов
        Expanded(
          child: calculationsAsync.when(
            data: (calculations) {
              final displayItems = calculations
                  .map(
                    (c) => (
                      calculation: c,
                      category: CalculationDisplay.historyCategory(c),
                      calculatorName: CalculationDisplay.calculatorName(
                        context,
                        c,
                      ),
                    ),
                  )
                  .toList(growable: false);

              var filtered = displayItems;

              // Фильтр по категории
              if (_selectedCategory != HistoryCategory.all) {
                filtered = filtered
                    .where((c) => c.category == _selectedCategory)
                    .toList();
              }

              // Поиск
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                filtered = filtered
                    .where(
                      (c) =>
                          c.calculation.title.toLowerCase().contains(q) ||
                          c.calculatorName.toLowerCase().contains(q),
                    )
                    .toList();
              }

              if (filtered.isEmpty) {
                return AnimatedEmptyState(
                  icon: Icons.calculate_outlined,
                  title: 'Нет расчётов',
                  subtitle: _searchQuery.isNotEmpty
                      ? 'Попробуйте изменить поисковый запрос'
                      : 'Создайте первый расчёт, чтобы он появился здесь',
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(calculationsProvider);
                },
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  cacheExtent: 500, // Кэширование для плавной прокрутки
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return StaggeredAnimation(
                      index: index,
                      child: RepaintBoundary(
                        child: HistoryCalculationCard(
                          calculation: item.calculation,
                          category: item.category,
                          calculatorName: item.calculatorName,
                          onDelete: () async {
                            final repo = ref.read(
                              calculationRepositoryProvider,
                            );
                            await repo.deleteCalculation(item.calculation.id);
                            ref.invalidate(calculationsProvider);
                            ref.invalidate(statisticsProvider);
                          },
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                Center(child: Text('Ошибка загрузки: $error')),
          ),
        ),
      ],
    );
  }
}
