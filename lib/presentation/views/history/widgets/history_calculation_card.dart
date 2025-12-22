import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/calculation.dart';
import '../../../../domain/calculators/calculator_registry.dart';
import '../../../../domain/calculators/history_category.dart';
import '../../../utils/calculator_navigation_helper.dart';

/// Карточка расчёта в истории.
class HistoryCalculationCard extends StatelessWidget {
  final Calculation calculation;
  final HistoryCategory category;
  final String calculatorName;
  final VoidCallback onDelete;

  const HistoryCalculationCard({
    super.key,
    required this.calculation,
    required this.category,
    required this.calculatorName,
    required this.onDelete,
  });

  IconData _getCategoryIcon(HistoryCategory category) {
    switch (category) {
      case HistoryCategory.foundation:
        return Icons.foundation;
      case HistoryCategory.walls:
        return Icons.view_column;
      case HistoryCategory.roofing:
        return Icons.roofing;
      case HistoryCategory.finishing:
        return Icons.format_paint;
      case HistoryCategory.all:
        return Icons.calculate;
    }
  }

  Color _getCategoryColor(HistoryCategory category) {
    switch (category) {
      case HistoryCategory.foundation:
        return Colors.brown;
      case HistoryCategory.walls:
        return Colors.blue;
      case HistoryCategory.roofing:
        return Colors.red;
      case HistoryCategory.finishing:
        return Colors.green;
      case HistoryCategory.all:
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
          backgroundColor: _getCategoryColor(category).withValues(alpha: 0.2),
          child: Icon(
            _getCategoryIcon(category),
            color: _getCategoryColor(category),
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
            Text(calculatorName),
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
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => HistoryCalculationDetails(
              calculation: calculation,
              calculatorName: calculatorName,
            ),
          );
        },
      ),
    );
  }
}

class HistoryCalculationDetails extends StatelessWidget {
  final Calculation calculation;
  final String calculatorName;

  const HistoryCalculationDetails({
    super.key,
    required this.calculation,
    required this.calculatorName,
  });

  Map<String, double> _parseInitialInputs() {
    try {
      final inputs = jsonDecode(calculation.inputsJson) as Map<String, dynamic>;
      final parsed = <String, double>{};
      for (final entry in inputs.entries) {
        final value = entry.value;
        if (value is num) {
          parsed[entry.key] = value.toDouble();
        } else {
          final asNum = double.tryParse(value.toString());
          if (asNum != null) parsed[entry.key] = asNum;
        }
      }
      return parsed;
    } catch (_) {
      return const <String, double>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    final inputs = jsonDecode(calculation.inputsJson) as Map<String, dynamic>;
    final results = jsonDecode(calculation.resultsJson) as Map<String, dynamic>;
    final definition = CalculatorRegistry.getById(calculation.calculatorId);

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
                calculatorName,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: definition == null
                          ? null
                          : () {
                              final initialInputs = _parseInitialInputs();
                              final navigator = Navigator.of(context);
                              navigator.pop();
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                CalculatorNavigationHelper.navigateToCalculator(
                                  navigator.context,
                                  definition,
                                  initialInputs: initialInputs,
                                );
                              });
                            },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        definition == null
                            ? 'Калькулятор недоступен'
                            : 'Открыть калькулятор',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
