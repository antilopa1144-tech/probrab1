import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  ConsumerState<MaterialComparisonScreen> createState() => _MaterialComparisonScreenState();
}

class _MaterialComparisonScreenState extends ConsumerState<MaterialComparisonScreen> {
  final List<MaterialOption> _options = [];
  MaterialOption? _selectedOption;

  @override
  void initState() {
    super.initState();
    _loadDefaultOptions();
  }

  void _loadDefaultOptions() {
    // Загружаем варианты материалов для калькулятора
    // В реальном приложении это будет из базы данных
    setState(() {
      _options.addAll([
        MaterialOption(
          id: 'option1',
          name: 'Эконом вариант',
          category: 'Базовый',
          pricePerUnit: 500,
          unit: 'м²',
          properties: {'толщина': '10 мм', 'класс': 'Б'},
          durabilityYears: 5,
        ),
        MaterialOption(
          id: 'option2',
          name: 'Стандарт',
          category: 'Средний',
          pricePerUnit: 800,
          unit: 'м²',
          properties: {'толщина': '12 мм', 'класс': 'А'},
          durabilityYears: 10,
        ),
        MaterialOption(
          id: 'option3',
          name: 'Премиум',
          category: 'Высокий',
          pricePerUnit: 1200,
          unit: 'м²',
          properties: {'толщина': '15 мм', 'класс': 'А+'},
          durabilityYears: 20,
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_options.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Сравнение материалов')),
        body: const Center(child: Text('Нет вариантов для сравнения')),
      );
    }

    final comparison = MaterialComparison(
      calculatorId: widget.calculatorId,
      requiredQuantity: widget.requiredQuantity,
      options: _options,
      recommended: _options.first, // можно улучшить логику
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
              itemCount: _options.length,
              cacheExtent: 500,
              itemBuilder: (context, index) {
                final option = _options[index];
                final totalCost = option.calculateTotalCost(widget.requiredQuantity);
                final costPerYear = option.getCostPerYear(widget.requiredQuantity);

                return RepaintBoundary(
                  child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(option.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${option.pricePerUnit} ₽/${option.unit}'),
                        Text('Срок службы: ${option.durabilityYears} лет'),
                        Text(
                          'Общая стоимость: ${totalCost.toStringAsFixed(0)} ₽',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Стоимость/год: ${costPerYear.toStringAsFixed(0)} ₽',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    trailing: _selectedOption?.id == option.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
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

    final totalCost = option!.calculateTotalCost(quantity);

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
                  Text('${option!.name}: ${totalCost.toStringAsFixed(0)} ₽'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

