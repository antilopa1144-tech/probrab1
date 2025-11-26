import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/labor_cost.dart';

/// Экран расчёта трудозатрат.
class LaborCostScreen extends ConsumerStatefulWidget {
  final String calculatorId;
  final double quantity;

  const LaborCostScreen({
    super.key,
    required this.calculatorId,
    required this.quantity,
  });

  @override
  ConsumerState<LaborCostScreen> createState() => _LaborCostScreenState();
}

class _LaborCostScreenState extends ConsumerState<LaborCostScreen> {
  String _selectedRegion = 'Москва';
  final Map<String, LaborRate> _rates = {
    'Москва': const LaborRate(
      category: 'Отделка',
      region: 'Москва',
      pricePerUnit: 500,
      unit: 'м²',
      minPrice: 5000,
    ),
    'СПб': const LaborRate(
      category: 'Отделка',
      region: 'СПб',
      pricePerUnit: 450,
      unit: 'м²',
      minPrice: 4000,
    ),
    'Регион': const LaborRate(
      category: 'Отделка',
      region: 'Регион',
      pricePerUnit: 350,
      unit: 'м²',
      minPrice: 3000,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rate = _rates[_selectedRegion]!;
    final calculation = LaborCostCalculation.fromCalculator(
      widget.calculatorId,
      widget.quantity,
      rate,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Расчёт трудозатрат')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Выбор региона
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Регион',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      value: _selectedRegion,
                      isExpanded: true,
                      items: _rates.keys.map((region) {
                        return DropdownMenuItem(
                          value: region,
                          child: Text(region),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRegion = value!;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Результаты
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Расчёт',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ResultRow(
                      label: 'Объём работ',
                      value: '${widget.quantity.toStringAsFixed(2)} ${rate.unit}',
                    ),
                    const Divider(),
                    _ResultRow(
                      label: 'Оценка времени',
                      value: '${calculation.estimatedHours} часов',
                    ),
                    _ResultRow(
                      label: 'Оценка дней',
                      value: '${calculation.estimatedDays} дней',
                    ),
                    const Divider(),
                    _ResultRow(
                      label: 'Стоимость работ',
                      value: '${calculation.totalCost.toStringAsFixed(0)} ₽',
                      isHighlighted: true,
                    ),
                    _ResultRow(
                      label: 'Цена за единицу',
                      value: '${rate.pricePerUnit} ₽/${rate.unit}',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Информация
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Информация',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Расчёт основан на средних нормах времени для данного типа работ. '
                      'Фактическое время может отличаться в зависимости от сложности и опыта мастера.',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _ResultRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isHighlighted ? 16 : 14,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isHighlighted ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: isHighlighted ? Theme.of(context).colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}

