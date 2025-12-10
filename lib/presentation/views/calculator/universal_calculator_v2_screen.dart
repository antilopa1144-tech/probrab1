import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_field.dart';
import '../../../domain/calculators/calculator_registry.dart';
import '../../../core/validation/field_validator.dart';
import '../../../core/validation/input_sanitizer.dart';
import '../../../core/errors/global_error_handler.dart';
import '../../../core/exceptions/calculation_exception.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/enums/unit_type.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../domain/models/project_v2.dart';
import '../../providers/price_provider.dart';
import '../../providers/project_v2_provider.dart';
import '../../widgets/hint_card.dart';
import '../../widgets/result_card.dart';
import '../../styles/calculator_styles.dart';
import '../project/project_details_screen.dart';

/// Универсальный экран калькулятора V2.
///
/// Динамически генерирует форму ввода и отображает результаты на основе
/// `CalculatorDefinitionV2`. Поддерживает все типы полей, валидацию,
/// подсказки и интеграцию с проектами.
///
/// ## Основные возможности:
///
/// ### Типы полей ввода:
/// - **Number**: числовое поле с единицами измерения
/// - **Select**: выпадающий список опций
/// - **Checkbox**: чекбокс (true/false)
/// - **Switch**: переключатель
/// - **Radio**: радио-кнопки для выбора одной опции
///
/// ### Функции:
/// - Автоматическая генерация формы из `CalculatorDefinitionV2`
/// - Валидация полей в реальном времени
/// - Группировка полей по категориям
/// - Условное отображение полей (зависимости)
/// - Подсказки до и после расчёта
/// - Сохранение результатов в проекты
/// - Поделиться результатами
/// - Предзаполнение данных при открытии из проекта
///
/// ## Пример использования:
///
/// ```dart
/// final calcDef = CalculatorRegistry.getById('wall_paint');
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => UniversalCalculatorV2Screen(
///       definition: calcDef!,
///       initialInputs: {'area': 50.0}, // Опционально
///     ),
///   ),
/// );
/// ```
///
/// ## Интеграция с проектами:
///
/// После расчёта пользователь может:
/// - Сохранить расчёт в существующий проект
/// - Создать новый проект и сохранить туда
/// - Открыть сохранённый расчёт для пересчёта
class UniversalCalculatorV2Screen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const UniversalCalculatorV2Screen({
    super.key,
    required this.definition,
    this.initialInputs,
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
  final _scrollController = ScrollController();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, double> _currentInputs = {};
  Map<String, double>? _results;
  bool _isCalculating = false;
  bool _hasCalculated = false;
  final GlobalKey _resultsKey = GlobalKey();
  Timer? _autoCalculateTimer;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _autoCalculateTimer?.cancel();
    _scrollController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeControllers() {
    for (final field in widget.definition.fields) {
      // Используем initialInputs, если они есть, иначе defaultValue
      final initialValue =
          widget.initialInputs?[field.key] ?? field.defaultValue;
      final controller = TextEditingController(
        text: initialValue != 0
            ? InputSanitizer.formatNumber(initialValue)
            : '',
      );

      controller.addListener(() {
        _updateCurrentInputs();
      });

      _controllers[field.key] = controller;
      _currentInputs[field.key] = initialValue;
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

    // Автоматический расчёт с задержкой (debounce)
    _autoCalculateTimer?.cancel();
    _autoCalculateTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && _formKey.currentState!.validate()) {
        _calculate();
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
    } on CalculationException catch (e, stack) {
      if (mounted) {
        setState(() => _isCalculating = false);
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Ошибка расчёта в ${widget.definition.id}',
          onRetry: _calculate,
          useDialog: true, // Используем диалог для критических ошибок расчёта
        );
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isCalculating = false);
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: 'Неожиданная ошибка в ${widget.definition.id}',
          onRetry: _calculate,
        );
      }
    }
  }

  void _scrollToResults() {
    if (_resultsKey.currentContext != null) {
      Scrollable.ensureVisible(
        _resultsKey.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _shareResults() async {
    final loc = AppLocalizations.of(context);
    
    if (_results == null || !_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('snackbar.calculate_first')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final calculatorName = loc.translate(widget.definition.titleKey);
    final date = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());

    // Формируем текст для шаринга
    final buffer = StringBuffer();
    buffer.writeln(calculatorName);
    buffer.writeln('${loc.translate('share.date')}: $date');
    buffer.writeln('');
    buffer.writeln('${loc.translate('share.inputs')}:');
    for (final entry in _currentInputs.entries) {
      final field = widget.definition.fields.firstWhere(
        (f) => f.key == entry.key,
        orElse: () => widget.definition.fields.first,
      );
      final label = loc.translate(field.labelKey);
      buffer.writeln('$label: ${entry.value} ${field.unitType.symbol}');
    }
    buffer.writeln('');
    buffer.writeln('${loc.translate('share.results')}:');
    for (final entry in _results!.entries) {
      final (unit, label) = _inferUnitAndLabel(entry.key);
      buffer.writeln('$label: ${entry.value} ${unit.symbol}');
    }

    try {
      await Share.share(buffer.toString(), subject: calculatorName);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('share.error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToProject() async {
    final loc = AppLocalizations.of(context);
    
    if (_results == null || !_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.translate('snackbar.calculate_first')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Получаем список проектов (ждём загрузки данных)
      final projects = await ref.read(allProjectsProvider.future);

      // Показываем диалог выбора/создания проекта
      final selectedProject = await _showProjectSelectionDialog(projects);

      if (selectedProject == null) return; // Пользователь отменил

      // Создаём ProjectCalculation
      final calculation = ProjectCalculation()
        ..calculatorId = widget.definition.id
        ..name = _getCalculationName()
        ..setInputsFromMap(_currentInputs)
        ..setResultsFromMap(_results!)
        ..materialCost = _getTotalPrice()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      // Сохраняем в проект
      final repository = ref.read(projectRepositoryV2Provider);
      await repository.addCalculationToProject(selectedProject.id, calculation);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${loc.translate('snackbar.calculation_saved')} "${selectedProject.name}"'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: loc.translate('common.open'),
              onPressed: () {
                Navigator.of(context).pop(); // Закрываем текущий экран
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ProjectDetailsScreen(projectId: selectedProject.id),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e, stack) {
      if (mounted) {
        GlobalErrorHandler.handle(
          context,
          e,
          stackTrace: stack,
          contextMessage: loc.translate('error.save_calculation'),
        );
      }
    }
  }

  String _getCalculationName() {
    final loc = AppLocalizations.of(context);
    final calculatorName = loc.translate(widget.definition.titleKey);
    final date = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return '$calculatorName ($date)';
  }

  double? _getTotalPrice() {
    // Пытаемся найти общую стоимость в результатах
    if (_results == null) return null;

    // Ищем ключи, которые могут содержать цену
    final priceKeys = [
      'totalPrice',
      'totalCost',
      'cost',
      'price',
      'materialCost',
    ];
    for (final key in priceKeys) {
      if (_results!.containsKey(key)) {
        return _results![key];
      }
    }

    return null;
  }

  Future<ProjectV2?> _showProjectSelectionDialog(
    List<ProjectV2> projects,
  ) async {
    return showDialog<ProjectV2>(
      context: context,
      builder: (context) => _ProjectSelectionDialog(projects: projects),
    );
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
              tooltip: loc.translate('common.share'),
              onPressed: _shareResults,
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
          controller: _scrollController,
          padding: CalculatorStyles.screenPadding,
          children: [
            // Описание калькулятора
            if (widget.definition.descriptionKey != null) ...[
              Text(
                loc.translate(widget.definition.descriptionKey!),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: CalculatorStyles.paddingXLarge),
            ],

            // Подсказки ДО расчёта
            if (!_hasCalculated) ...[
              HintsList(
                hints: widget.definition.getBeforeHints(_currentInputs),
              ),
              const SizedBox(height: CalculatorStyles.paddingLarge),
            ],

            // Поля ввода
            ..._buildInputFields(),

            const SizedBox(height: CalculatorStyles.paddingXLarge),

            // Кнопка расчёта
            FilledButton(
              onPressed: _isCalculating ? null : _calculate,
              style: CalculatorStyles.filledButtonStyle,
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
              const SizedBox(height: CalculatorStyles.paddingXXLarge),
              const Divider(),
              const SizedBox(height: CalculatorStyles.paddingXLarge),

              Text(
                loc.translate('result.title'),
                key: _resultsKey,
                style: CalculatorStyles.sectionTitleStyle(theme),
              ),
              const SizedBox(height: CalculatorStyles.paddingLarge),

              ..._buildResults(),

              const SizedBox(height: 24),

              // Кнопка сохранения в проект
              OutlinedButton.icon(
                onPressed: _saveToProject,
                icon: const Icon(Icons.folder_outlined),
                label: Text(loc.translate('button.save_to_project')),
                style: CalculatorStyles.outlinedButtonStyle,
              ),

              const SizedBox(height: CalculatorStyles.paddingXLarge),

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
      widgets.add(const SizedBox(height: CalculatorStyles.paddingLarge));
      widgets.addAll(_buildFieldGroup(entry.key, entry.value));
    }

    return widgets;
  }

  List<Widget> _buildFieldGroup(
    String groupName,
    List<CalculatorField> fields,
  ) {
    final widgets = <Widget>[];

    // Для группы "advanced" делаем сворачиваемую секцию
    if (groupName == 'advanced' || groupName == 'additional') {
      return [
        ExpansionTile(
          title: Text(
            _getGroupTitle(groupName),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          initiallyExpanded: false, // Свёрнуто по умолчанию
          children: [
            ...fields.map(
              (field) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _buildInputField(field),
              ),
            ),
          ],
        ),
      ];
    }

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
      widgets.add(const SizedBox(height: CalculatorStyles.paddingMedium));
    }

    return widgets;
  }

  Widget _buildInputField(CalculatorField field) {
    switch (field.inputType) {
      case FieldInputType.number:
        return _buildNumberField(field);
      case FieldInputType.select:
        return _buildSelectField(field);
      case FieldInputType.checkbox:
        return _buildCheckboxField(field);
      case FieldInputType.switch_:
        return _buildSwitchField(field);
      case FieldInputType.radio:
        return _buildRadioField(field);
    }
  }

  Widget _buildNumberField(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final controller = _controllers[field.key]!;
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        labelText: loc.translate(field.labelKey),
        hintText: field.hintKey != null ? loc.translate(field.hintKey!) : null,
        suffixText: _getSuffixText(field),
        prefixIcon: field.iconName != null
            ? Icon(_getIconForField(field.iconName!))
            : null,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            CalculatorStyles.borderRadiusMedium,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            CalculatorStyles.borderRadiusMedium,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            CalculatorStyles.borderRadiusMedium,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CalculatorStyles.paddingLarge,
          vertical: CalculatorStyles.paddingMedium,
        ),
      ),
      validator: (value) {
        final parsed = InputSanitizer.parseDouble(value ?? '');
        final error = FieldValidator.validate(field, parsed);
        return error?.getUserMessage();
      },
      onFieldSubmitted: (_) => _calculate(),
    );
  }

  Widget _buildSelectField(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;

    if (field.options == null || field.options!.isEmpty) {
      return _buildNumberField(field); // Fallback to number if no options
    }

    return DropdownButtonFormField<double>(
      initialValue: currentValue,
      decoration: InputDecoration(
        labelText: loc.translate(field.labelKey),
        hintText: field.hintKey != null ? loc.translate(field.hintKey!) : null,
        suffixText: _getSuffixText(field),
        prefixIcon: field.iconName != null
            ? Icon(_getIconForField(field.iconName!))
            : null,
      ),
      items: field.options!.map((option) {
        return DropdownMenuItem<double>(
          value: option.value,
          child: Text(loc.translate(option.labelKey)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _currentInputs[field.key] = value;
            _controllers[field.key]?.text = InputSanitizer.formatNumber(value);
          });
        }
      },
      validator: field.required
          ? (value) {
              if (value == null) {
                final message = loc.translate('input.required');
                return message;
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildCheckboxField(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;
    final isChecked = currentValue != 0;

    return CheckboxListTile(
      title: Text(loc.translate(field.labelKey)),
      subtitle: field.hintKey != null
          ? Text(loc.translate(field.hintKey!))
          : null,
      value: isChecked,
      onChanged: (value) {
        setState(() {
          _currentInputs[field.key] = (value ?? false) ? 1.0 : 0.0;
          _controllers[field.key]?.text = InputSanitizer.formatNumber(
            _currentInputs[field.key]!,
          );
        });
      },
      secondary: field.iconName != null
          ? Icon(_getIconForField(field.iconName!))
          : null,
    );
  }

  Widget _buildSwitchField(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;
    final isOn = currentValue != 0;

    return SwitchListTile(
      title: Text(loc.translate(field.labelKey)),
      subtitle: field.hintKey != null
          ? Text(loc.translate(field.hintKey!))
          : null,
      value: isOn,
      onChanged: (value) {
        setState(() {
          _currentInputs[field.key] = value ? 1.0 : 0.0;
          _controllers[field.key]?.text = InputSanitizer.formatNumber(
            _currentInputs[field.key]!,
          );
        });
      },
      secondary: field.iconName != null
          ? Icon(_getIconForField(field.iconName!))
          : null,
    );
  }

  Widget _buildRadioField(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;

    if (field.options == null || field.options!.isEmpty) {
      return _buildNumberField(field); // Fallback to number if no options
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            loc.translate(field.labelKey),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (field.hintKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              loc.translate(field.hintKey!),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ...field.options!.map((option) {
          return RadioListTile<double>(
            title: Text(loc.translate(option.labelKey)),
            subtitle: option.descriptionKey != null
                ? Text(loc.translate(option.descriptionKey!))
                : null,
            value: option.value,
            groupValue: currentValue,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentInputs[field.key] = value;
                  _controllers[field.key]?.text = InputSanitizer.formatNumber(
                    value,
                  );
                });
              }
            },
          );
        }),
      ],
    );
  }

  List<Widget> _buildResults() {
    if (_results == null) return [];

    final widgets = <Widget>[];

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
          primaryResultKey:
              resultsData.keys.first, // Первый результат - главный
        ),
      );
    }

    return widgets;
  }

  (UnitType, String) _inferUnitAndLabel(String key) {
    final loc = AppLocalizations.of(context);
    
    // Сначала пробуем найти точное совпадение ключа результата
    final resultKey = 'result.$key';
    final translated = loc.translate(resultKey);
    if (translated != resultKey) {
      // Нашли перевод, теперь определяем единицу измерения
      if (key.contains('area') || key.contains('Area')) {
        return (UnitType.squareMeters, translated);
      }
      if (key.contains('volume') || key.contains('Volume')) {
        return (UnitType.cubicMeters, translated);
      }
      if (key.contains('length') || key.contains('Length')) {
        return (UnitType.meters, translated);
      }
      if (key.contains('weight') || key.contains('Weight') || key.contains('kg')) {
        return (UnitType.kilograms, translated);
      }
      if (key.contains('price') || key.contains('cost') || key.contains('Cost')) {
        return (UnitType.rubles, translated);
      }
      if (key.contains('packs') || key.contains('Packs')) {
        return (UnitType.packages, translated);
      }
      if (key.contains('rolls') || key.contains('Rolls')) {
        return (UnitType.rolls, translated);
      }
      if (key.contains('pieces') || key.contains('Pieces') || key.contains('Needed')) {
        return (UnitType.pieces, translated);
      }
      return (UnitType.pieces, translated);
    }
    
    // Если точного перевода нет, используем общие правила
    if (key.contains('area')) {
      return (UnitType.squareMeters, loc.translate('result.area'));
    }
    if (key.contains('volume')) {
      return (UnitType.cubicMeters, loc.translate('result.volume'));
    }
    if (key.contains('length')) {
      return (UnitType.meters, loc.translate('result.length'));
    }
    if (key.contains('liters') || key.endsWith('_l')) {
      return (UnitType.liters, loc.translate('result.quantity'));
    }
    if (key.contains('kg') || key.endsWith('_kg')) {
      return (UnitType.kilograms, loc.translate('result.weight'));
    }
    if (key.contains('bags')) {
      return (UnitType.bags, loc.translate('result.bags'));
    }
    if (key.contains('packages') || key.contains('packs')) {
      return (UnitType.packages, loc.translate('result.packages'));
    }
    if (key.contains('rolls')) {
      return (UnitType.rolls, loc.translate('result.rolls'));
    }
    if (key.contains('pieces') || key.endsWith('_pcs')) {
      return (UnitType.pieces, loc.translate('result.pieces'));
    }
    if (key.contains('price') || key.contains('cost')) {
      return (UnitType.rubles, loc.translate('result.cost'));
    }

    // Если ничего не подошло, возвращаем ключ (будет видно, что не переведено)
    return (UnitType.pieces, key);
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
    final loc = AppLocalizations.of(context);
    switch (groupName) {
      case 'openings':
        return loc.translate('field.group.openings');
      case 'advanced':
        return loc.translate('field.group.advanced');
      case 'dimensions':
        return loc.translate('field.group.dimensions');
      case 'materials':
        return loc.translate('field.group.materials');
      default:
        return groupName;
    }
  }

  /// Получить текст суффикса с учётом специальных единиц измерения
  String _getSuffixText(CalculatorField field) {
    // Специальная обработка для мощности (Вт/м²)
    if (field.key == 'power' && field.unitType == UnitType.pieces) {
      return 'Вт/м²';
    }
    return field.unitType.symbol;
  }
}

/// Диалог выбора проекта для сохранения расчёта.
class _ProjectSelectionDialog extends StatefulWidget {
  final List<ProjectV2> projects;

  const _ProjectSelectionDialog({required this.projects});

  @override
  State<_ProjectSelectionDialog> createState() =>
      _ProjectSelectionDialogState();
}

class _ProjectSelectionDialogState extends State<_ProjectSelectionDialog> {
  int? _selectedProjectId;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isCreatingNew = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(loc.translate('dialog.save_to_project.title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Переключатель: выбрать существующий / создать новый
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(loc.translate('dialog.save_to_project.existing')),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(loc.translate('dialog.save_to_project.new')),
                ),
              ],
              selected: {_isCreatingNew},
              onSelectionChanged: (Set<bool> selection) {
                setState(() {
                  _isCreatingNew = selection.first;
                  _selectedProjectId = null;
                });
              },
            ),

            const SizedBox(height: 16),

            if (!_isCreatingNew) ...[
              // Список существующих проектов
              if (widget.projects.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc.translate('dialog.save_to_project.no_projects'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.projects.length,
                    itemBuilder: (context, index) {
                      final project = widget.projects[index];
                      return RadioListTile<int>(
                        title: Text(project.name),
                        subtitle: project.description != null
                            ? Text(project.description!)
                            : null,
                        value: project.id,
                        groupValue: _selectedProjectId,
                        onChanged: (value) {
                          setState(() {
                            _selectedProjectId = value;
                          });
                        },
                        secondary: project.isFavorite
                            ? const Icon(Icons.star, color: Colors.amber)
                            : null,
                      );
                    },
                  ),
                ),
            ] else ...[
              // Форма создания нового проекта
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: loc.translate('input.project_name'),
                  hintText: loc.translate('input.project_name.hint'),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: loc.translate('input.project_description'),
                  hintText: loc.translate('input.project_description.hint'),
                ),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(loc.translate('common.cancel')),
        ),
        FilledButton(
          onPressed: _canSave() ? _handleSave : null,
          child: Text(loc.translate('common.save')),
        ),
      ],
    );
  }

  bool _canSave() {
    if (!_isCreatingNew) {
      return _selectedProjectId != null;
    } else {
      return _nameController.text.trim().isNotEmpty;
    }
  }

  Future<void> _handleSave() async {
    if (!_isCreatingNew && _selectedProjectId != null) {
      final project = widget.projects.firstWhere(
        (p) => p.id == _selectedProjectId,
      );
      if (mounted) {
        Navigator.of(context).pop(project);
      }
    } else if (_isCreatingNew) {
      // Создаём новый проект
      final newProject = ProjectV2()
        ..name = _nameController.text.trim()
        ..description = _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim()
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      // Сохраняем проект через репозиторий
      final repository = ProviderScope.containerOf(
        context,
      ).read(projectRepositoryV2Provider);
      final projectId = await repository.createProject(newProject);

      // Загружаем созданный проект
      final createdProject = await repository.getProjectById(projectId);
      if (createdProject != null && mounted) {
        Navigator.of(context).pop(createdProject);
      }
    }
  }
}
// ignore_for_file: deprecated_member_use
