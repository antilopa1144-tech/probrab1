import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/repositories/material_repository.dart';
import '../../../domain/entities/material_comparison.dart';

/// Экран сравнения материалов.
class MaterialComparisonScreen extends ConsumerStatefulWidget {
  final String calculatorId;
  final double requiredQuantity;

  const MaterialComparisonScreen({
    super.key,
    required this.calculatorId,
    required this.requiredQuantity,
  });

  @override
  ConsumerState<MaterialComparisonScreen> createState() =>
      _MaterialComparisonScreenState();
}

class _MaterialComparisonScreenState
    extends ConsumerState<MaterialComparisonScreen> {
  MaterialOption? _selectedOption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final materialsAsync =
        ref.watch(materialsForCalculatorProvider(widget.calculatorId));

    return materialsAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Сравнение материалов')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text('Сравнение материалов')),
        body: const Center(child: Text('Не удалось загрузить материалы')),
      ),
      data: (options) {
        if (options.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Сравнение материалов')),
            body: const Center(child: Text('Нет вариантов для сравнения')),
          );
        }

        final selectedOption = (_selectedOption != null &&
                options.any((option) => option.id == _selectedOption!.id))
            ? _selectedOption!
            : options.first;

        final comparison = MaterialComparison(
          calculatorId: widget.calculatorId,
          requiredQuantity: widget.requiredQuantity,
          options: options,
          recommended: options.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Сравнение материалов'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddOptionDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Рекомендации
              Container(
                padding: const EdgeInsets.all(16),
                color: theme.colorScheme.primaryContainer,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Рекомендации',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _RecommendationCard(
                      title: 'Самое дешёвое',
                      option: comparison.cheapest,
                      quantity: widget.requiredQuantity,
                    ),
                    const SizedBox(height: 8),
                    _RecommendationCard(
                      title: 'Самое долговечное',
                      option: comparison.mostDurable,
                      quantity: widget.requiredQuantity,
                    ),
                    const SizedBox(height: 8),
                    _RecommendationCard(
                      title: 'Оптимальное',
                      option: comparison.optimal,
                      quantity: widget.requiredQuantity,
                    ),
                  ],
                ),
              ),
              // Список вариантов
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: options.length,
                  cacheExtent: 500,
                  itemBuilder: (context, index) {
                    final option = options[index];

                    return RepaintBoundary(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(option.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Цены временно скрыты до интеграции с магазинами
                              // Text('${option.pricePerUnit} ?/${option.unit}'),
                              Text('Срок службы: ${option.durabilityYears} лет'),
                              // Text(
                              //   'Общая стоимость: ${totalCost.toStringAsFixed(0)} ?',
                              //   style: const TextStyle(fontWeight: FontWeight.bold),
                              // ),
                              // Text(
                              //   'Стоимость/год: ${costPerYear.toStringAsFixed(0)} ?',
                              //   style: TextStyle(color: Colors.grey.shade600),
                              // ),
                            ],
                          ),
                          trailing: selectedOption.id == option.id
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : IconButton(
                                  icon: const Icon(Icons.check_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      _selectedOption = option;
                                    });
                                  },
                                ),
                          onTap: () {
                            setState(() {
                              _selectedOption = option;
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOptionDialog(BuildContext context) {
    // Диалог добавления нового варианта
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить вариант'),
        content: const Text('Функция в разработке'),
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

class _RecommendationCard extends StatelessWidget {
  final String title;
  final MaterialOption? option;
  final double quantity;

  const _RecommendationCard({
    required this.title,
    required this.option,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    if (option == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.star, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Цены временно скрыты до интеграции с магазинами
                  // Text('${option!.name}: ${totalCost.toStringAsFixed(0)} ?'),
                  Text(option!.name),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
