import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_field.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../core/validation/field_validator.dart';
import '../../../core/validation/input_sanitizer.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/enums/unit_type.dart';
import '../../providers/price_provider.dart';
import '../../widgets/hint_card.dart';
import '../../widgets/result_card.dart';

/// Универсальный экран калькулятора V2.
///
/// Поддерживает:
/// - Динамическое построение формы из CalculatorDefinitionV2
/// - Группировку полей
/// - Условное отображение полей (dependencies)
/// - Подсказки до/после расчёта
/// - Валидацию через FieldValidator
/// - Отображение результатов через ResultCard
class UniversalCalculatorV2Screen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;

  const UniversalCalculatorV2Screen({
    super.key,
    required this.definition,
  });

  /// Создать экран по ID калькулятора
  static Widget? fromId(String calculatorId) {
    final definition = CalculatorRegistry.getById(calculatorId);
    if (definition == null) return null;
    return UniversalCalculatorV2Screen(definition: definition);
  }

  @override
  ConsumerState<UniversalCalculatorV2Screen> createState() =>
      _UniversalCalculatorV2ScreenState();
}

class _UniversalCalculatorV2ScreenState
    extends ConsumerState<UniversalCalculatorV2Screen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _currentInputs = {};
  Map<String, double>? _results;
  bool _isCalculating = false;
  bool _hasCalculated = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final field in widget.definition.fields) {
      final controller = TextEditingController(
        text: field.defaultValue != 0
            ? InputSanitizer.formatNumber(field.defaultValue)
            : '',
      );

      controller.addListener(() {
        _updateCurrentInputs();
      });

      _controllers[field.key] = controller;
      _currentInputs[field.key] = field.defaultValue;
    }
  }

  void _updateCurrentInputs() {
    setState(() {
      for (final field in widget.definition.fields) {
        final text = _controllers[field.key]?.text ?? '';
        _currentInputs[field.key] =
            InputSanitizer.parseDouble(text) ?? field.defaultValue;
      }
    });
  }

  void _calculate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCalculating = true);

    try {
      final priceList = await ref.read(priceListProvider.future);

      // Собираем входные данные
      final inputs = <String, double>{};
      for (final field in widget.definition.fields) {
        final value = InputSanitizer.parseDouble(
          _controllers[field.key]?.text ?? '',
        );
        inputs[field.key] = value ?? field.defaultValue;
      }

      // Валидация логических ограничений
      final logicalError = FieldValidator.validateLogical(inputs);
      if (logicalError != null && mounted) {
        GlobalErrorHandler.showErrorSnackBar(context, logicalError);
        setState(() => _isCalculating = false);
        return;
      }

      // Выполняем расчёт
      final result = widget.definition.calculate(inputs, priceList);

      if (mounted) {
        setState(() {
          _results = result.values;
          _isCalculating = false;
          _hasCalculated = true;
        });

        // Прокручиваем к результатам
        _scrollToResults();
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isCalculating = false);
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Calculate in ${widget.definition.id}',
          onRetry: _calculate,
        );
      }
    }
  }

  void _scrollToResults() {
    // TODO: Implement scroll to results section
  }

  void _clearForm() {
    for (final field in widget.definition.fields) {
      _controllers[field.key]?.clear();
    }
    setState(() {
      _results = null;
      _hasCalculated = false;
      _currentInputs.clear();
      for (final field in widget.definition.fields) {
        _currentInputs[field.key] = field.defaultValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate(widget.definition.titleKey)),
        actions: [
          if (_hasCalculated)
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Поделиться',
              onPressed: () {
                // TODO: Implement share
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: loc.translate('common.clear'),
            onPressed: _clearForm,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Описание калькулятора
            if (widget.definition.descriptionKey != null) ...[
              Text(
                loc.translate(widget.definition.descriptionKey!),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ],

            // Подсказки ДО расчёта
            if (!_hasCalculated) ...[
              HintsList(
                hints: widget.definition.getBeforeHints(_currentInputs),
              ),
              const SizedBox(height: 16),
            ],

            // Поля ввода
            ..._buildInputFields(),

            const SizedBox(height: 24),

            // Кнопка расчёта
            FilledButton(
              onPressed: _isCalculating ? null : _calculate,
              child: _isCalculating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.translate('common.calculate')),
            ),

            // Результаты
            if (_hasCalculated && _results != null) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 24),

              Text(
                'Результаты расчёта',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              ..._buildResults(),

              const SizedBox(height: 24),

              // Подсказки ПОСЛЕ расчёта
              HintsList(
                hints: widget.definition.getAfterHints(
                  _currentInputs,
                  _results!,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildInputFields() {
    final visibleFields = widget.definition.getVisibleFields(_currentInputs);
    final groupedFields = <String, List<CalculatorField>>{};

    // Группируем поля
    for (final field in visibleFields) {
      final group = field.group ?? 'main';
      groupedFields.putIfAbsent(group, () => []);
      groupedFields[group]!.add(field);
    }

    final widgets = <Widget>[];

    // Основная группа всегда первая
    if (groupedFields.containsKey('main')) {
      widgets.addAll(_buildFieldGroup('main', groupedFields['main']!));
      groupedFields.remove('main');
    }

    // Остальные группы
    for (final entry in groupedFields.entries) {
      widgets.add(const SizedBox(height: 16));
      widgets.addAll(_buildFieldGroup(entry.key, entry.value));
    }

    return widgets;
  }

  List<Widget> _buildFieldGroup(String groupName, List<CalculatorField> fields) {
    final widgets = <Widget>[];
    final loc = AppLocalizations.of(context);

    // Заголовок группы (кроме main)
    if (groupName != 'main') {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Text(
            _getGroupTitle(groupName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
      );
    }

    // Поля группы
    for (final field in fields) {
      widgets.add(_buildInputField(field));
      widgets.add(const SizedBox(height: 12));
    }

    return widgets;
  }

  Widget _buildInputField(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final controller = _controllers[field.key]!;

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: loc.translate(field.labelKey),
        hintText: field.hintKey != null ? loc.translate(field.hintKey!) : null,
        suffixText: field.unitType.symbol,
        prefixIcon: field.iconName != null
            ? Icon(_getIconForField(field.iconName!))
            : null,
      ),
      validator: (value) {
        final parsed = InputSanitizer.parseDouble(value ?? '');
        final error = FieldValidator.validate(field, parsed);
        return error?.getUserMessage();
      },
      onFieldSubmitted: (_) => _calculate(),
    );
  }

  List<Widget> _buildResults() {
    if (_results == null) return [];

    final widgets = <Widget>[];
    final loc = AppLocalizations.of(context);

    // Преобразуем результаты в формат для ResultsList
    final resultsData = <String, (double, UnitType, String)>{};

    _results!.forEach((key, value) {
      // Определяем единицу измерения и label на основе ключа
      final (unit, label) = _inferUnitAndLabel(key);
      resultsData[key] = (value, unit, label);
    });

    // Используем ResultsList
    if (resultsData.isNotEmpty) {
      widgets.add(
        ResultsList(
          results: resultsData,
          primaryResultKey: resultsData.keys.first, // Первый результат - главный
        ),
      );
    }

    return widgets;
  }

  (UnitType, String) _inferUnitAndLabel(String key) {
    // Определяем единицу измерения по ключу результата
    if (key.contains('area')) return (UnitType.squareMeters, 'Площадь');
    if (key.contains('volume')) return (UnitType.cubicMeters, 'Объём');
    if (key.contains('length')) return (UnitType.meters, 'Длина');
    if (key.contains('liters') || key.endsWith('_l')) {
      return (UnitType.liters, 'Количество');
    }
    if (key.contains('kg') || key.endsWith('_kg')) {
      return (UnitType.kilograms, 'Вес');
    }
    if (key.contains('bags')) return (UnitType.bags, 'Мешков');
    if (key.contains('packages') || key.contains('packs')) {
      return (UnitType.packages, 'Упаковок');
    }
    if (key.contains('rolls')) return (UnitType.rolls, 'Рулонов');
    if (key.contains('pieces') || key.endsWith('_pcs')) {
      return (UnitType.pieces, 'Штук');
    }
    if (key.contains('price') || key.contains('cost')) {
      return (UnitType.rubles, 'Стоимость');
    }

    return (UnitType.pieces, key); // По умолчанию
  }

  IconData _getIconForField(String iconName) {
    // Маппинг названий иконок на IconData
    switch (iconName) {
      case 'square_foot':
      case 'area':
        return Icons.square_foot_rounded;
      case 'window':
        return Icons.window_rounded;
      case 'door_front':
      case 'door':
        return Icons.door_front_door_rounded;
      case 'layers':
        return Icons.layers_rounded;
      case 'opacity':
        return Icons.opacity_rounded;
      case 'add_circle_outline':
        return Icons.add_circle_outline_rounded;
      case 'height':
        return Icons.height_rounded;
      case 'straighten':
        return Icons.straighten_rounded;
      default:
        return Icons.edit_rounded;
    }
  }

  String _getGroupTitle(String groupName) {
    switch (groupName) {
      case 'openings':
        return 'Проёмы';
      case 'advanced':
        return 'Дополнительно';
      case 'dimensions':
        return 'Размеры';
      case 'materials':
        return 'Материалы';
      default:
        return groupName;
    }
  }
}
