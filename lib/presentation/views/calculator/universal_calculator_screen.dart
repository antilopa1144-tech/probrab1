import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/calculators/definitions.dart';
import '../../../domain/usecases/calculator_usecase.dart';
import '../../providers/price_provider.dart';
import '../../providers/calculation_provider.dart';
import '../material/material_comparison_screen.dart';
import '../labor/labor_cost_screen.dart';
import '../waste/waste_optimizer_screen.dart';
import '../weather/weather_advisor_screen.dart';
import '../savings/savings_calculator_screen.dart';
import '../expert/expert_recommendations_screen.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/errors/error_handler.dart';

/// Универсальный экран калькулятора.
///
/// Динамически строит форму из CalculatorDefinition.fields,
/// выполняет расчёт и показывает результаты + советы мастера.
class UniversalCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinition definition;

  const UniversalCalculatorScreen({
    super.key,
    required this.definition,
  });

  /// Создать экран по ID калькулятора.
  static Widget? fromId(String calculatorId) {
    try {
      final definition = calculators.firstWhere(
        (calc) => calc.id == calculatorId,
      );
      return UniversalCalculatorScreen(definition: definition);
    } catch (_) {
      return null;
    }
  }

  @override
  ConsumerState<UniversalCalculatorScreen> createState() =>
      _UniversalCalculatorScreenState();
}

class _UniversalCalculatorScreenState
    extends ConsumerState<UniversalCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  CalculatorResult? _result;
  Map<String, double>? _inputs;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    // Инициализируем контроллеры для всех полей
    for (final field in widget.definition.fields) {
      _controllers[field.key] = TextEditingController(
        text: field.defaultValue != 0
            ? field.defaultValue.toString()
            : '',
      );
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    final priceAsync = ref.read(priceListProvider);
    priceAsync.when(
      data: (prices) {
        if (!mounted) return;
        // Собираем входные данные
        final inputs = <String, double>{};
        for (final field in widget.definition.fields) {
          final value = double.tryParse(_controllers[field.key]!.text) ??
              field.defaultValue;
          inputs[field.key] = value;
        }

        // Выполняем расчёт
        final result = widget.definition.run(inputs, prices);

        if (mounted) {
          setState(() {
            _result = result;
            _inputs = inputs;
            _isCalculating = false;
          });
        }
      },
      loading: () {},
      error: (error, stackTrace) {
        if (!mounted) return;
        setState(() => _isCalculating = false);
        
        // Используем улучшенный ErrorHandler
        ErrorHandler.logError(error, stackTrace, 'UniversalCalculatorScreen._calculate');
        final message = ErrorHandler.getUserFriendlyMessage(error);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Повторить',
              onPressed: () => _calculate(),
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveCalculation() async {
    if (_result == null || _inputs == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Сначала выполните расчёт'),
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final notesController = TextEditingController();

    if (!mounted) return;
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Сохранить расчёт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Название расчёта',
                hintText: 'Например: Покраска стен в гостиной',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Заметки (необязательно)',
                hintText: 'Дополнительная информация',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (titleController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название')),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );

    if (shouldSave == true) {
      if (!mounted) return;
      final repo = ref.read(calculationRepositoryProvider);
      try {
        await repo.saveCalculation(
          title: titleController.text.trim(),
          calculatorId: widget.definition.id,
          calculatorName: widget.definition.titleKey,
          category: widget.definition.category,
          inputs: _inputs!,
          results: _result!.values,
          totalCost: _result!.totalPrice ?? 0,
          notes: notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Расчёт сохранён'),
              backgroundColor: Colors.green,
            ),
          );
          ref.invalidate(calculationsProvider);
        }
      } catch (e, stackTrace) {
        if (mounted) {
          ErrorHandler.logError(e, stackTrace, 'UniversalCalculatorScreen._saveCalculation');
          final message = ErrorHandler.getUserFriendlyMessage(e);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceAsync = ref.watch(priceListProvider);
    final loc = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate(widget.definition.titleKey)),
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.save_outlined),
              onPressed: _saveCalculation,
              tooltip: 'Сохранить расчёт',
            ),
        ],
      ),
      body: priceAsync.when(
        data: (_) => _buildForm(context, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) {
          ErrorHandler.logError(error, stackTrace, 'UniversalCalculatorScreen.build');
          final message = ErrorHandler.getUserFriendlyMessage(error);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(priceListProvider),
                  child: const Text('Повторить'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Поля ввода
            ...widget.definition.fields.map((field) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    controller: _controllers[field.key],
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.translate(field.labelKey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                    ),
                    validator: (value) {
                      // Проверка обязательности
                      if (field.required && (value == null || value.isEmpty)) {
                        return loc.translate('input.required');
                      }
                      
                      // Если поле не обязательное и пустое, используем значение по умолчанию
                      if (!field.required && (value == null || value.isEmpty)) {
                        return null;
                      }
                      
                      // Проверка формата числа
                      final num = double.tryParse(value!);
                      if (num == null) {
                        return loc.translate('input.invalid_number') ?? 'Введите корректное число';
                      }
                      
                      // Проверка на отрицательные числа (для большинства полей)
                      if (num < 0) {
                        return loc.translate('input.positive_number') ?? 'Введите положительное число';
                      }
                      
                      // Проверка на ноль для обязательных полей
                      if (field.required && num == 0) {
                        return loc.translate('input.cannot_be_zero') ?? 'Значение не может быть нулём';
                      }
                      
                      // Проверка минимального значения
                      if (field.minValue != null && num < field.minValue!) {
                        return '${loc.translate('input.min_value') ?? 'Минимальное значение'}: ${field.minValue}';
                      }
                      
                      // Проверка максимального значения
                      if (field.maxValue != null && num > field.maxValue!) {
                        return '${loc.translate('input.max_value') ?? 'Максимальное значение'}: ${field.maxValue}';
                      }
                      
                      // Проверка разумных значений для площади
                      if (field.key.contains('area') && num > 10000) {
                        return loc.translate('input.area_too_large') ?? 
                               'Проверьте значение. Слишком большое число для площади (макс. 10000 м²)';
                      }
                      
                      // Проверка разумных значений для объёма
                      if (field.key.contains('volume') && num > 1000) {
                        return loc.translate('input.volume_too_large') ?? 
                               'Проверьте значение. Слишком большое число для объёма (макс. 1000 м³)';
                      }
                      
                      // Проверка разумных значений для толщины
                      if (field.key.contains('thickness') && num > 500) {
                        return loc.translate('input.thickness_too_large') ?? 
                               'Проверьте значение. Слишком большая толщина (макс. 500 мм)';
                      }
                      
                      // Проверка разумных значений для периметра
                      if (field.key.contains('perimeter') && num > 1000) {
                        return loc.translate('input.perimeter_too_large') ?? 
                               'Проверьте значение. Слишком большой периметр (макс. 1000 м)';
                      }
                      
                      return null;
                    },
                  ),
                )),

            const SizedBox(height: 24),

            // Кнопка расчёта
            ElevatedButton.icon(
              onPressed: _isCalculating ? null : _calculate,
              icon: _isCalculating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.calculate),
              label: Text(_isCalculating ? 'Расчёт...' : loc.translate('button.calculate')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 32),
              _buildResults(theme),
              const SizedBox(height: 16),
              _buildAdditionalFeatures(context, theme),
              if (widget.definition.tips.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildTips(theme),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final loc = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Результаты',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._result!.values.entries.map((entry) {
              // Пытаемся найти локализованную метку
              final labelKey = widget.definition.resultLabels[entry.key] ??
                  entry.key;
              final label = loc.translate(labelKey);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                    Text(
                      entry.value.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (_result!.totalPrice != null) ...[
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Общая стоимость:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_result!.totalPrice!.toStringAsFixed(0)} ₽',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTips(ThemeData theme) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.12),
              theme.colorScheme.primary.withValues(alpha: 0.06),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Советы мастера',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...widget.definition.tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      tip,
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

  Widget _buildAdditionalFeatures(BuildContext context, ThemeData theme) {
    final firstValue = _result!.values.values.firstOrNull ?? 0.0;
    
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Дополнительные инструменты',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.compare_arrows, size: 18),
                  label: const Text('Сравнить материалы'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MaterialComparisonScreen(
                          calculatorId: widget.definition.id,
                          requiredQuantity: firstValue,
                        ),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.people, size: 18),
                  label: const Text('Трудозатраты'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LaborCostScreen(
                          calculatorId: widget.definition.id,
                          quantity: firstValue,
                        ),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.recycling, size: 18),
                  label: const Text('Оптимизация отходов'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WasteOptimizerScreen(
                          materialId: widget.definition.id,
                          requiredArea: firstValue,
                          standardSize: 1.0,
                        ),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.wb_sunny, size: 18),
                  label: const Text('Погода'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WeatherAdvisorScreen(
                          workType: widget.definition.subCategory,
                        ),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.savings, size: 18),
                  label: const Text('Экономия'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SavingsCalculatorScreen(
                          workType: widget.definition.subCategory,
                          materialCost: _result!.totalPrice ?? 0,
                        ),
                      ),
                    );
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.school, size: 18),
                  label: const Text('Экспертные советы'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ExpertRecommendationsScreen(
                          workType: widget.definition.subCategory,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

