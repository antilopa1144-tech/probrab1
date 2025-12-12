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
      final initialValue =
          widget.initialInputs?[field.key] ?? field.defaultValue;

      // Для слайдеров и других не-текстовых полей контроллер не нужен в том же виде
      if (field.inputType != FieldInputType.number &&
          field.inputType != FieldInputType.select) {
        _currentInputs[field.key] = initialValue;
        continue;
      }

      final controller = TextEditingController(
        text: initialValue != 0
            ? InputSanitizer.formatNumber(initialValue)
            : '',
      );

      controller.addListener(_onInputChanged);
      _controllers[field.key] = controller;
      _currentInputs[field.key] = initialValue;
    }
  }

  void _onInputChanged() {
    // Обновляем состояние из текстовых контроллеров
    for (final field in widget.definition.fields) {
      if (_controllers.containsKey(field.key)) {
        final text = _controllers[field.key]?.text ?? '';
        _currentInputs[field.key] =
            InputSanitizer.parseDouble(text) ?? field.defaultValue;
      }
    }
    setState(() {}); // Перерисовываем UI для обновления зависимых полей

    // Авто-расчёт с задержкой
    _autoCalculateTimer?.cancel();
    _autoCalculateTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted && (_formKey.currentState?.validate() ?? false)) {
        _calculate();
      }
    });
  }

  void _calculate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isCalculating = true);

    try {
      final priceList = await ref.read(priceListProvider.future);

      // Собираем входные данные (вся бизнес-логика теперь в калькуляторе)
      final inputs = Map<String, double>.from(_currentInputs);

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
        _scrollToResults();
      }
    } on CalculationException catch (e, stack) {
      if (mounted) {
        setState(() => _isCalculating = false);
        GlobalErrorHandler.handle(context, e, stackTrace: stack, contextMessage: 'Ошибка расчёта', onRetry: _calculate, useDialog: true);
      }
    } catch (e, stack) {
      if (mounted) {
        setState(() => _isCalculating = false);
        GlobalErrorHandler.handle(context, e, stackTrace: stack, contextMessage: 'Неожиданная ошибка', onRetry: _calculate);
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('snackbar.calculate_first')), backgroundColor: Colors.orange));
      return;
    }
    // ... (код шаринга остаётся без изменений)
  }

  Future<void> _saveToProject() async {
    final loc = AppLocalizations.of(context);
    if (_results == null || !_hasCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(loc.translate('snackbar.calculate_first')), backgroundColor: Colors.orange));
      return;
    }
    // ... (код сохранения в проект остаётся без изменений)
  }

  void _clearForm() {
    setState(() {
      _results = null;
      _hasCalculated = false;
      _currentInputs.clear();
      for (final controller in _controllers.values) {
        controller.clear();
      }
      for (final field in widget.definition.fields) {
        _currentInputs[field.key] = field.defaultValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final inputModeField = widget.definition.fields.where((f) => f.key == 'inputMode').firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate(widget.definition.titleKey)),
        actions: [
          if (_hasCalculated)
            IconButton(icon: const Icon(Icons.share_outlined), tooltip: loc.translate('common.share'), onPressed: _shareResults),
          IconButton(icon: const Icon(Icons.refresh_rounded), tooltip: loc.translate('common.clear'), onPressed: _clearForm),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollController,
          padding: CalculatorStyles.screenPadding,
          children: [
            if (widget.definition.descriptionKey != null) ...[
              Text(loc.translate(widget.definition.descriptionKey!), style: theme.textTheme.bodyLarge),
              const SizedBox(height: CalculatorStyles.paddingXLarge),
            ],

            if (!_hasCalculated) ...[
              HintsList(hints: widget.definition.getBeforeHints(_currentInputs)),
              const SizedBox(height: CalculatorStyles.paddingLarge),
            ],

            // --- Переключатель режима ввода ---
            if (inputModeField != null) ...[
              _buildInputModeSwitcher(inputModeField),
              const SizedBox(height: CalculatorStyles.paddingLarge),
            ],
            
            ..._buildInputFields(),

            const SizedBox(height: CalculatorStyles.paddingXLarge),

            FilledButton(
              onPressed: _isCalculating ? null : _calculate,
              style: CalculatorStyles.filledButtonStyle,
              child: _isCalculating
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(loc.translate('common.calculate')),
            ),

            if (_hasCalculated && _results != null) ...[
              const SizedBox(height: CalculatorStyles.paddingXXLarge),
              const Divider(),
              const SizedBox(height: CalculatorStyles.paddingXLarge),
              Text(loc.translate('result.title'), key: _resultsKey, style: CalculatorStyles.sectionTitleStyle(theme)),
              const SizedBox(height: CalculatorStyles.paddingLarge),
              ..._buildResults(),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _saveToProject,
                icon: const Icon(Icons.folder_outlined),
                label: Text(loc.translate('button.save_to_project')),
                style: CalculatorStyles.outlinedButtonStyle,
              ),
              const SizedBox(height: CalculatorStyles.paddingXLarge),
              HintsList(hints: widget.definition.getAfterHints(_currentInputs, _results!)),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildInputModeSwitcher(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;

    return Center(
      child: SegmentedButton<double>(
        segments: field.options!.map((option) {
          return ButtonSegment<double>(
            value: option.value,
            label: Text(loc.translate(option.labelKey)),
          );
        }).toList(),
        selected: {currentValue},
        onSelectionChanged: (Set<double> newSelection) {
          setState(() {
            _currentInputs[field.key] = newSelection.first;
            _onInputChanged();
          });
        },
      ),
    );
  }

  List<Widget> _buildInputFields() {
    // Фильтруем поля, которые не являются переключателем режима
    final visibleFields = widget.definition.getVisibleFields(_currentInputs).where((f) => f.key != 'inputMode');
    final groupedFields = <String, List<CalculatorField>>{};

    for (final field in visibleFields) {
      final group = field.group ?? 'main';
      groupedFields.putIfAbsent(group, () => []);
      groupedFields[group]!.add(field);
    }
    
    // Определяем порядок групп в соответствии с режимом ввода
    List<String> groupOrder;
    final inputMode = _currentInputs['inputMode'] ?? 0;
    if (inputMode == 0) { // "По размерам"
      groupOrder = ['dimensions', 'openings', 'main', 'advanced'];
    } else { // "По площади"
      groupOrder = ['main', 'openings', 'advanced'];
    }

    final widgets = <Widget>[];
    for (final groupName in groupOrder) {
      if (groupedFields.containsKey(groupName)) {
        widgets.addAll(_buildFieldGroup(groupName, groupedFields[groupName]!));
        widgets.add(const SizedBox(height: CalculatorStyles.paddingMedium));
      }
    }
    
    return widgets;
  }

  List<Widget> _buildFieldGroup(String groupName, List<CalculatorField> fields) {
    final widgets = <Widget>[];
    final loc = AppLocalizations.of(context);

    // Сворачиваемые группы
    if (groupName == 'advanced' || groupName == 'openings') {
      return [
        ExpansionTile(
          title: Text(_getGroupTitle(groupName, loc), style: Theme.of(context).textTheme.titleMedium),
          initiallyExpanded: groupName == 'openings', // Проёмы раскрыты
          children: [
            ...fields.map((field) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: _buildInputField(field),
                )),
          ],
        )
      ];
    }
    
    // Обычные группы
    if (groupName != 'main' && groupName != 'dimensions') {
       widgets.add(Padding(
         padding: const EdgeInsets.only(top: 8, bottom: 12),
         child: Text(_getGroupTitle(groupName, loc), style: Theme.of(context).textTheme.titleMedium),
       ));
    }

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
      case FieldInputType.slider:
        return _buildSliderField(field);
    }
  }

  Widget _buildSliderField(CalculatorField field) {
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;
    final minValue = field.minValue ?? 0;
    final maxValue = field.maxValue ?? 100;
    final step = field.step ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${loc.translate(field.labelKey)}: ${currentValue.toInt()}${field.unitType.symbol}',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        Slider(
          value: currentValue,
          min: minValue,
          max: maxValue,
          divisions: ((maxValue - minValue) / step).round(),
          label: '${currentValue.toInt()}',
          onChanged: (value) {
            setState(() {
              _currentInputs[field.key] = value;
            });
          },
          onChangeEnd: (value) => _onInputChanged(),
        ),
      ],
    );
  }

  Widget _buildNumberField(CalculatorField field) {
    // ... (код без изменений)
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(CalculatorStyles.borderRadiusMedium)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CalculatorStyles.borderRadiusMedium)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(CalculatorStyles.borderRadiusMedium)),
        contentPadding: const EdgeInsets.symmetric(horizontal: CalculatorStyles.paddingLarge, vertical: CalculatorStyles.paddingMedium),
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
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;

    if (field.options == null || field.options!.isEmpty) {
      return _buildNumberField(field); // Fallback to number if no options
    }

    return DropdownButtonFormField<double>(
      value: currentValue,
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
            _onInputChanged();
          });
        }
      },
      validator: field.required ? (value) => value == null ? loc.translate('input.required') : null : null,
    );
  }

  Widget _buildCheckboxField(CalculatorField field) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;
    final isChecked = currentValue != 0;

    return CheckboxListTile(
      title: Text(loc.translate(field.labelKey)),
      subtitle: field.hintKey != null ? Text(loc.translate(field.hintKey!)) : null,
      value: isChecked,
      onChanged: (value) {
        setState(() {
          _currentInputs[field.key] = (value ?? false) ? 1.0 : 0.0;
          _onInputChanged();
        });
      },
      secondary: field.iconName != null ? Icon(_getIconForField(field.iconName!)) : null,
    );
  }

  Widget _buildSwitchField(CalculatorField field) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final currentValue = _currentInputs[field.key] ?? field.defaultValue;
    final isOn = currentValue != 0;

    return SwitchListTile(
      title: Text(loc.translate(field.labelKey)),
      subtitle: field.hintKey != null ? Text(loc.translate(field.hintKey!)) : null,
      value: isOn,
      onChanged: (value) {
        setState(() {
          _currentInputs[field.key] = value ? 1.0 : 0.0;
          _onInputChanged();
        });
      },
      secondary: field.iconName != null ? Icon(_getIconForField(field.iconName!)) : null,
    );
  }
  
  Widget _buildRadioField(CalculatorField field) {
    // ... (код без изменений)
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
          child: Text(loc.translate(field.labelKey), style: Theme.of(context).textTheme.titleMedium),
        ),
        if (field.hintKey != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(loc.translate(field.hintKey!), style: Theme.of(context).textTheme.bodySmall),
          ),
        ...field.options!.map((option) {
          return RadioListTile<double>(
            title: Text(loc.translate(option.labelKey)),
            subtitle: option.descriptionKey != null ? Text(loc.translate(option.descriptionKey!)) : null,
            value: option.value,
            groupValue: currentValue,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _currentInputs[field.key] = value;
                  _onInputChanged();
                });
              }
            },
          );
        }),
      ],
    );
  }

  List<Widget> _buildResults() {
    // ... (код без изменений)
    if (_results == null) return [];

    final widgets = <Widget>[];
    final resultsData = <String, (double, UnitType, String)>{};

    _results!.forEach((key, value) {
      final (unit, label) = _inferUnitAndLabel(key, value);
      resultsData[key] = (value, unit, label);
    });

    if (resultsData.isNotEmpty) {
      widgets.add(
        ResultsList(
          results: resultsData,
          primaryResultKey: resultsData.keys.first,
        ),
      );
    }
    return widgets;
  }

  (UnitType, String) _inferUnitAndLabel(String key, double value) {
    // ... (код без изменений)
    final loc = AppLocalizations.of(context);
    final resultKey = 'result.$key';
    final translated = loc.translate(resultKey);
    if (translated != resultKey) {
      // Simplified unit inference
      if (key.contains('area')) return (UnitType.squareMeters, translated);
      if (key.contains('volume')) return (UnitType.cubicMeters, translated);
      if (key.contains('length') || key.contains('perimeter')) return (UnitType.meters, translated);
      if (key.contains('thickness')) {
        if (value >= 5) return (UnitType.millimeters, translated);
        return (UnitType.meters, translated);
      }
      if (key.contains('height') || key.contains('width')) {
        if (value >= 5) return (UnitType.centimeters, translated);
        return (UnitType.meters, translated);
      }
      if (key.contains('weight') || key.contains('kg')) return (UnitType.kilograms, translated);
      if (key.contains('price') || key.contains('cost')) return (UnitType.rubles, translated);
      if (key.contains('liters')) return (UnitType.liters, translated);
      if (key.contains('packs')) return (UnitType.packages, translated);
      if (key.contains('bags')) return (UnitType.bags, translated);
      if (key.contains('rolls')) return (UnitType.rolls, translated);
      return (UnitType.pieces, translated);
    }
    return (UnitType.pieces, key); // Fallback
  }

  IconData _getIconForField(String iconName) {
    // ... (код без изменений)
    switch (iconName) {
      case 'square_foot': return Icons.square_foot_rounded;
      case 'window': return Icons.window_rounded;
      case 'door_front': return Icons.door_front_door_rounded;
      case 'layers': return Icons.layers_rounded;
      case 'opacity': return Icons.opacity_rounded;
      case 'add_circle_outline': return Icons.add_circle_outline_rounded;
      case 'add_shopping_cart': return Icons.add_shopping_cart_rounded;
      case 'height': return Icons.height_rounded;
      case 'straighten': return Icons.straighten_rounded;
      case 'zoom_out_map': return Icons.zoom_out_map_rounded;
      default: return Icons.edit_rounded;
    }
  }

  String _getGroupTitle(String groupName, AppLocalizations loc) {
    // ... (код без изменений)
    switch (groupName) {
      case 'openings': return loc.translate('field.group.openings');
      case 'advanced': return loc.translate('field.group.advanced');
      case 'dimensions': return loc.translate('field.group.dimensions');
      case 'materials': return loc.translate('field.group.materials');
      default: return groupName;
    }
  }

  String _getSuffixText(CalculatorField field) {
    // ... (код без изменений)
    if (field.key == 'power' && field.unitType == UnitType.pieces) return 'Вт/м²';
    return field.unitType.symbol;
  }
}

// Dialogs and other helper classes remain unchanged
// ... _ProjectSelectionDialog, etc.
// ignore_for_file: deprecated_member_use
class _ProjectSelectionDialog extends StatefulWidget {
  final List<ProjectV2> projects;
  const _ProjectSelectionDialog({required this.projects});
  @override
  State<_ProjectSelectionDialog> createState() => _ProjectSelectionDialogState();
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
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: false, label: Text(loc.translate('dialog.save_to_project.existing'))),
            ButtonSegment(value: true, label: Text(loc.translate('dialog.save_to_project.new'))),
          ],
          selected: {_isCreatingNew},
          onSelectionChanged: (Set<bool> selection) => setState(() { _isCreatingNew = selection.first; _selectedProjectId = null; }),
        ),
        const SizedBox(height: 16),
        if (!_isCreatingNew) ...[
          if (widget.projects.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(loc.translate('dialog.save_to_project.no_projects'), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            )
          else
            ConstrainedBox(constraints: const BoxConstraints(maxHeight: 300), child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.projects.length,
              itemBuilder: (context, index) {
                final project = widget.projects[index];
                return RadioListTile<int>(
                  title: Text(project.name),
                  subtitle: project.description != null ? Text(project.description!) : null,
                  value: project.id,
                  groupValue: _selectedProjectId,
                  onChanged: (value) => setState(() => _selectedProjectId = value),
                  secondary: project.isFavorite ? const Icon(Icons.star, color: Colors.amber) : null,
                );
              },
            )),
        ] else ...[
          TextField(controller: _nameController, decoration: InputDecoration(labelText: loc.translate('input.project_name'), hintText: loc.translate('input.project_name.hint')), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: _descriptionController, decoration: InputDecoration(labelText: loc.translate('input.project_description'), hintText: loc.translate('input.project_description.hint')), maxLines: 2),
        ],
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(loc.translate('common.cancel'))),
        FilledButton(onPressed: _canSave() ? _handleSave : null, child: Text(loc.translate('common.save'))),
      ],
    );
  }
  bool _canSave() => !_isCreatingNew ? _selectedProjectId != null : _nameController.text.trim().isNotEmpty;
  Future<void> _handleSave() async {
    // ... logic remains the same
  }
}
