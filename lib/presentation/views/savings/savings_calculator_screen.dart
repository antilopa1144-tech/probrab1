import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
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
    final loc = AppLocalizations.of(context);

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
      appBar: AppBar(title: Text(loc.translate('savings.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('savings.input'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _laborCostController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.translate('savings.field.labor_cost'),
                        prefixIcon: const Icon(Icons.people),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _timeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.translate('savings.field.self_time'),
                        prefixIcon: const Icon(Icons.access_time),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _hourlyRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.translate('savings.field.hourly_rate'),
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                            calculation.isWorthIt ? Icons.check_circle : Icons.info,
                            color: calculation.isWorthIt ? Colors.green : Colors.orange,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              loc.translate(
                                calculation.isWorthIt
                                    ? 'savings.status.self'
                                    : 'savings.status.hire',
                              ),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: calculation.isWorthIt ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          loc.translate(
                            calculation.recommendationKey,
                            calculation.recommendationParams,
                          ),
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
