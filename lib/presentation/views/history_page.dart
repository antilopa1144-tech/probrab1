import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../providers/calculation_provider.dart';
import '../../data/models/calculation.dart';
import '../../core/widgets/staggered_animation.dart';
import '../../core/widgets/animated_empty_state.dart';

/// Страница истории расчётов
class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _searchQuery = '';
  String _selectedCategory = 'Все';

  @override
  Widget build(BuildContext context) {
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
                _StatCard(
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
                    _FilterChip(
                      label: 'Все',
                      selected: _selectedCategory == 'Все',
                      onSelected: () =>
                          setState(() => _selectedCategory = 'Все'),
                    ),
                    _FilterChip(
                      label: 'Фундамент',
                      selected: _selectedCategory == 'Фундамент',
                      onSelected: () =>
                          setState(() => _selectedCategory = 'Фундамент'),
                    ),
                    _FilterChip(
                      label: 'Стены',
                      selected: _selectedCategory == 'Стены',
                      onSelected: () =>
                          setState(() => _selectedCategory = 'Стены'),
                    ),
                    _FilterChip(
                      label: 'Кровля',
                      selected: _selectedCategory == 'Кровля',
                      onSelected: () =>
                          setState(() => _selectedCategory = 'Кровля'),
                    ),
                    _FilterChip(
                      label: 'Отделка',
                      selected: _selectedCategory == 'Отделка',
                      onSelected: () =>
                          setState(() => _selectedCategory = 'Отделка'),
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
              var filtered = calculations;

              // Фильтр по категории
              if (_selectedCategory != 'Все') {
                filtered = filtered
                    .where((c) => c.category == _selectedCategory)
                    .toList();
              }

              // Поиск
              if (_searchQuery.isNotEmpty) {
                filtered = filtered
                    .where(
                      (c) =>
                          c.title.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          c.calculatorName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
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
                    final calc = filtered[index];
                    return StaggeredAnimation(
                      index: index,
                      child: RepaintBoundary(
                        child: _CalculationCard(
                          calculation: calc,
                          onDelete: () async {
                            final repo = ref.read(
                              calculationRepositoryProvider,
                            );
                            await repo.deleteCalculation(calc.id);
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

class _StatCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: _StatCardWidget(
        icon: widget.icon,
        label: widget.label,
        value: widget.value,
        color: widget.color,
      ),
    );
  }
}

class _StatCardWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCardWidget({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _CalculationCard extends StatelessWidget {
  final Calculation calculation;
  final VoidCallback onDelete;

  const _CalculationCard({required this.calculation, required this.onDelete});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Фундамент':
        return Icons.foundation;
      case 'Стены':
        return Icons.view_column;
      case 'Кровля':
        return Icons.roofing;
      case 'Отделка':
        return Icons.format_paint;
      default:
        return Icons.calculate;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Фундамент':
        return Colors.brown;
      case 'Стены':
        return Colors.blue;
      case 'Кровля':
        return Colors.red;
      case 'Отделка':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(
            calculation.category,
          ).withValues(alpha: 0.2),
          child: Icon(
            _getCategoryIcon(calculation.category),
            color: _getCategoryColor(calculation.category),
          ),
        ),
        title: Text(
          calculation.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(calculation.calculatorName),
            // Цены временно скрыты до интеграции с магазинами
            // const SizedBox(height: 4),
            // Text(
            //   '${calculation.totalCost.toStringAsFixed(0)} ₽',
            //   style: TextStyle(
            //     color: Theme.of(context).colorScheme.primary,
            //     fontWeight: FontWeight.bold,
            //   ),
            // ),
            // const SizedBox(height: 4),
            Text(
              dateFormat.format(calculation.updatedAt),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Удалить расчёт?'),
                content: Text('Удалить "${calculation.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Отмена'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onDelete();
                    },
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            );
          },
        ),
        onTap: () {
          // Показать детали расчёта
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => _CalculationDetails(calculation: calculation),
          );
        },
      ),
    );
  }
}

class _CalculationDetails extends StatelessWidget {
  final Calculation calculation;

  const _CalculationDetails({required this.calculation});

  @override
  Widget build(BuildContext context) {
    final inputs = jsonDecode(calculation.inputsJson) as Map<String, dynamic>;
    final results = jsonDecode(calculation.resultsJson) as Map<String, dynamic>;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      calculation.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                calculation.calculatorName,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),

              // Входные данные
              const Text(
                'Введённые данные:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...inputs.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text(
                        '${e.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 32),

              // Результаты
              const Text(
                'Результаты:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...results.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key),
                      Text(
                        double.parse(e.value.toString()).toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Цены временно скрыты до интеграции с магазинами
              // const Divider(height: 32),
              //
              // // Общая стоимость
              // Container(
              //   padding: const EdgeInsets.all(16),
              //   decoration: BoxDecoration(
              //     color:
              //         Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //     children: [
              //       const Text(
              //         'Общая стоимость:',
              //         style: TextStyle(
              //           fontSize: 18,
              //           fontWeight: FontWeight.bold,
              //         ),
              //       ),
              //       Text(
              //         '${calculation.totalCost.toStringAsFixed(0)} ₽',
              //         style: TextStyle(
              //           fontSize: 24,
              //           fontWeight: FontWeight.bold,
              //           color: Theme.of(context).colorScheme.primary,
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
              if (calculation.notes != null &&
                  calculation.notes!.isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  'Заметки:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(calculation.notes!),
              ],
            ],
          ),
        );
      },
    );
  }
}
