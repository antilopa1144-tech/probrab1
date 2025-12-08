import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/savings_calculation.dart';

/// Экран калькулятора экономии.
class SavingsCalculatorScreen extends ConsumerStatefulWidget {
  final String workType;
  final double materialCost;

  const SavingsCalculatorScreen({
    super.key,
    required this.workType,
    required this.materialCost,
  });

  @override
  ConsumerState<SavingsCalculatorScreen> createState() => _SavingsCalculatorScreenState();
}

class _SavingsCalculatorScreenState extends ConsumerState<SavingsCalculatorScreen> {
  final TextEditingController _laborCostController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _hourlyRateController = TextEditingController(text: '0');

  @override
  void dispose() {
    _laborCostController.dispose();
    _timeController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final laborCost = double.tryParse(_laborCostController.text) ?? 0;
    final timeHours = double.tryParse(_timeController.text) ?? 0;
    final hourlyRate = double.tryParse(_hourlyRateController.text) ?? 0;

    SavingsCalculation? calculation;
    if (laborCost > 0 && timeHours > 0) {
      calculation = SavingsCalculation.calculate(
        workType: widget.workType,
        materialCost: widget.materialCost,
        laborCost: laborCost,
        selfWorkTimeHours: timeHours,
        hourlyRate: hourlyRate,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Калькулятор экономии')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ввод данных
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Входные данные',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _laborCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Стоимость работы мастеров (₽)',
                        prefixIcon: Icon(Icons.people),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _timeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Время самостоятельной работы (часы)',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hourlyRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Ваша почасовая ставка (₽/час, 0 = не учитывать)',
                        prefixIcon: Icon(Icons.attach_money),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Результаты
            if (calculation != null)
              Card(
                color: calculation.isWorthIt 
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            calculation.isWorthIt 
                                ? Icons.check_circle
                                : Icons.info,
                            color: calculation.isWorthIt 
                                ? Colors.green
                                : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              calculation.isWorthIt
                                  ? 'Выгодно делать самостоятельно'
                                  : 'Рекомендуется нанять мастеров',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: calculation.isWorthIt 
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Цены временно скрыты до интеграции с магазинами
                      // _ResultRow(
                      //   label: 'Стоимость материалов',
                      //   value: '${widget.materialCost.toStringAsFixed(0)} ₽',
                      // ),
                      // const Divider(),
                      // _ResultRow(
                      //   label: 'Стоимость работы мастеров',
                      //   value: '${calculation.laborCost.toStringAsFixed(0)} ₽',
                      // ),
                      // _ResultRow(
                      //   label: 'Стоимость вашего времени',
                      //   value: '${calculation.timeCost.toStringAsFixed(0)} ₽',
                      // ),
                      // const Divider(),
                      // _ResultRow(
                      //   label: 'Общая стоимость (мастера)',
                      //   value: '${(widget.materialCost + calculation.laborCost).toStringAsFixed(0)} ₽',
                      // ),
                      // _ResultRow(
                      //   label: 'Общая стоимость (самостоятельно)',
                      //   value: '${(widget.materialCost + calculation.timeCost).toStringAsFixed(0)} ₽',
                      // ),
                      // const Divider(),
                      // _ResultRow(
                      //   label: 'Экономия',
                      //   value: '${calculation.savings.toStringAsFixed(0)} ₽',
                      //   isHighlighted: true,
                      //   color: calculation.savings > 0 ? Colors.green : Colors.red,
                      // ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          calculation.getRecommendation(),
                          style: theme.textTheme.bodyMedium,
                        ),
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

/// Виджет для отображения строки результата (скрыт до интеграции с магазинами).
// class _ResultRow extends StatelessWidget {
//   final String label;
//   final String value;
//   final bool isHighlighted;
//   final Color? color;
//
//   const _ResultRow({
//     required this.label,
//     required this.value,
//     this.isHighlighted = false,
//     this.color,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               fontSize: isHighlighted ? 16 : 14,
//               fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontSize: isHighlighted ? 18 : 16,
//               fontWeight: FontWeight.bold,
//               color: color ?? (isHighlighted ? Theme.of(context).colorScheme.primary : null),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

