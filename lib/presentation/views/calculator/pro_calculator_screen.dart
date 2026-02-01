// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../core/exceptions/calculation_exception.dart';
import '../../../core/services/calculator_memory_service.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_field.dart';
import '../../../data/models/price_item.dart';
import '../../providers/price_provider.dart';
import '../../widgets/calculator/grouped_results_card.dart';
import '../../widgets/calculator/calculator_widgets.dart';

class ProCalculatorState {
  final Map<String, double> inputs;
  final Map<String, double>? results;
  final bool hasError;

  const ProCalculatorState({
    required this.inputs,
    this.results,
    this.hasError = false,
  });

  ProCalculatorState copyWith({
    Map<String, double>? inputs,
    Map<String, double>? results,
    bool? hasError,
    bool clearResults = false,
  }) {
    return ProCalculatorState(
      inputs: inputs ?? this.inputs,
      results: clearResults ? null : (results ?? this.results),
      hasError: hasError ?? this.hasError,
    );
  }
}

class ProCalculatorNotifier extends StateNotifier<ProCalculatorState> {
  ProCalculatorNotifier(this._ref, this.definition)
      : super(const ProCalculatorState(inputs: {})) {
    _initDefaults();
  }

  final Ref _ref;
  final CalculatorDefinitionV2 definition;

  void _initDefaults() {
    final defaults = <String, double>{};
    for (final field in definition.fields) {
      defaults[field.key] = field.defaultValue;
    }
    final adjusted = _applyAutoAdjustments(defaults);
    state = state.copyWith(inputs: adjusted);
    calculate();
  }

  void applyInputs(Map<String, double> inputs) {
    if (inputs.isEmpty) return;
    final merged = Map<String, double>.from(state.inputs);
    for (final entry in inputs.entries) {
      merged[entry.key] = entry.value;
    }
    final adjusted = _applyAutoAdjustments(merged);
    state = state.copyWith(inputs: adjusted);
    calculate();
  }

  void updateInput(String key, double value) {
    final updated = Map<String, double>.from(state.inputs);
    updated[key] = value;
    final adjusted = _applyAutoAdjustments(updated);
    state = state.copyWith(inputs: adjusted);
    calculate();
  }

  Map<String, double> _applyAutoAdjustments(Map<String, double> inputs) {
    if (definition.id != 'sheeting_osb_plywood') {
      return inputs;
    }

    final adjusted = Map<String, double>.from(inputs);
    final constructionType = (adjusted['constructionType'] ?? 1).round();
    final thickness = (adjusted['thickness'] ?? 9).round();
    final joistStep = (adjusted['joistStep'] ?? 600).round();
    final rafterStep = (adjusted['rafterStep'] ?? 600).round();

    int? recommendedThickness;
    if (constructionType == 2) {
      if (joistStep <= 300) {
        recommendedThickness = 15;
      } else if (joistStep <= 400) {
        recommendedThickness = 18;
      } else if (joistStep <= 500) {
        recommendedThickness = 18;
      } else if (joistStep <= 600) {
        recommendedThickness = 22;
      } else {
        recommendedThickness = 22;
      }
    } else if (constructionType == 3) {
      if (rafterStep <= 600) {
        recommendedThickness = 9;
      } else if (rafterStep <= 900) {
        recommendedThickness = 12;
      } else {
        recommendedThickness = 15;
      }
    }

    if (recommendedThickness != null && thickness < recommendedThickness) {
      adjusted['thickness'] = recommendedThickness.toDouble();
    }

    final osbClass = (adjusted['osbClass'] ?? 3).round();
    final environment = (adjusted['environment'] ?? 1).round();
    final loadLevel = (adjusted['loadLevel'] ?? 1).round();
    final requiresOsb3 = environment >= 2 ||
        loadLevel == 2 ||
        constructionType == 3 ||
        constructionType == 6;

    if (requiresOsb3 && osbClass < 3) {
      adjusted['osbClass'] = 3.0;
    }

    return adjusted;
  }

  void calculate() {
    final priceListAsync = _ref.read(priceListProvider);
    final priceList = priceListAsync.maybeWhen(
      data: (list) => list,
      orElse: () => <PriceItem>[],
    );
    try {
      final result = definition.calculate(state.inputs, priceList);
      state = state.copyWith(results: result.values, hasError: false);
    } on CalculationException {
      state = state.copyWith(clearResults: true, hasError: true);
    }
  }
}

final proCalculatorProvider = StateNotifierProvider.autoDispose
    .family<ProCalculatorNotifier, ProCalculatorState, CalculatorDefinitionV2>(
  (ref, definition) => ProCalculatorNotifier(ref, definition),
);

/// Универсальный PRO калькулятор с темным дизайном.
///
/// Автоматически генерирует UI на основе CalculatorDefinitionV2.
/// Использует современный темный дизайн как в PlasterCalculatorScreen.
class ProCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const ProCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  ConsumerState<ProCalculatorScreen> createState() => _ProCalculatorScreenState();
}

class _ProCalculatorScreenState extends ConsumerState<ProCalculatorScreen> {
  late final CalculatorMemoryService _memory;
  Map<String, double> _latestInputs = {};

  late AppLocalizations _loc;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _memory = ref.read(calculatorMemoryProvider);
    _latestInputs =
        Map<String, double>.from(ref.read(proCalculatorProvider(widget.definition)).inputs);
    _loadLastInputs();
  }

  @override
  void dispose() {
    _memory.saveLastInputs(widget.definition.id, _latestInputs);
    super.dispose();
  }

  Future<void> _loadLastInputs() async {
    final lastInputs = _memory.loadLastInputs(widget.definition.id);
    if (lastInputs != null) {
      _applyInputs(lastInputs);
    }
    if (widget.initialInputs != null) {
      _applyInputs(widget.initialInputs!);
    }
  }

  void _applyInputs(Map<String, double> inputs) {
    ref.read(proCalculatorProvider(widget.definition).notifier).applyInputs(inputs);
  }

  void _updateValue(String key, double value) {
    ref
        .read(proCalculatorProvider(widget.definition).notifier)
        .updateInput(key, value);
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    final calcState = ref.watch(proCalculatorProvider(widget.definition));
    _latestInputs = Map<String, double>.from(calcState.inputs);
    final accentColor = CalculatorColors.getColorByCategory(widget.definition.category.name);
    final beforeHints = widget.definition.getBeforeHints(calcState.inputs);
    final afterHints = calcState.results != null
        ? widget.definition.getAfterHints(calcState.inputs, calcState.results!)
        : const [];

    // Convert hints to tips strings
    final beforeTips = beforeHints.map((dynamic h) => (h.message ?? _loc.translate(h.messageKey ?? '')) as String).toList();
    final afterTips = afterHints.map((dynamic h) => (h.message ?? _loc.translate(h.messageKey ?? '')) as String).toList();

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      resultHeader: calcState.results != null ? _buildResultHeader(calcState.results, accentColor) : null,
      children: [
        if (beforeTips.isNotEmpty) TipsCard(
          tips: beforeTips,
          accentColor: accentColor,
          title: _loc.translate('common.tips'),
        ),
        if (beforeTips.isNotEmpty) const SizedBox(height: 16),
        ..._buildInputFields(calcState.inputs),
        const SizedBox(height: 16),
        if (calcState.results != null) _buildDetailsCard(calcState.results),
        if (afterTips.isNotEmpty) const SizedBox(height: 16),
        if (afterTips.isNotEmpty) TipsCard(
          tips: afterTips,
          accentColor: accentColor,
          title: _loc.translate('common.tips'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildInputFields(
    Map<String, double> inputs,
  ) {
    final visibleFields = widget.definition.getVisibleFields(inputs);
    final groupedFields = <String, List<CalculatorField>>{};

    // Группируем поля
    for (final field in visibleFields) {
      final group = field.group ?? 'default';
      groupedFields.putIfAbsent(group, () => []);
      groupedFields[group]!.add(field);
    }

    final widgets = <Widget>[];
    final accentColor = CalculatorColors.getColorByCategory(widget.definition.category.name);

    for (final entry in groupedFields.entries) {
      // Используем InputGroup для групп с названием
      if (entry.key != 'default') {
        widgets.add(
          InputGroup(
            title: _loc.translate('group.${entry.key}'),
            icon: _getIconForGroup(entry.key),
            accentColor: accentColor,
            children: entry.value.map((field) => _buildField(field, inputs, accentColor)).toList(),
          ),
        );
      } else {
        // Для default группы используем простую белую карточку
        widgets.add(_card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entry.value.map((field) => _buildField(field, inputs, accentColor)).toList(),
          ),
        ));
      }
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  IconData _getIconForGroup(String groupKey) {
    // Подбираем иконку по типу группы
    if (groupKey.contains('geometry') || groupKey.contains('геометрия')) return Icons.straighten;
    if (groupKey.contains('material') || groupKey.contains('материал')) return Icons.category;
    if (groupKey.contains('opening') || groupKey.contains('проем')) return Icons.door_front_door;
    if (groupKey.contains('parameter') || groupKey.contains('параметр')) return Icons.tune;
    if (groupKey.contains('option') || groupKey.contains('опци')) return Icons.settings;
    return Icons.folder;
  }

  Widget _buildField(CalculatorField field, Map<String, double> inputs, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (field.inputType) {
        FieldInputType.slider => _buildSliderField(field, inputs, accentColor),
        FieldInputType.select => _buildSelectField(field, inputs, accentColor),
        FieldInputType.checkbox || FieldInputType.switch_ =>
          _buildToggleField(field, inputs),
        FieldInputType.radio => _buildRadioField(field, inputs, accentColor),
        _ => _buildNumberField(field, inputs, accentColor),
      },
    );
  }

  Widget _buildSliderField(CalculatorField field, Map<String, double> inputs, Color accentColor) {
    final value = inputs[field.key] ?? field.defaultValue;
    final min = field.minValue ?? 0;
    final max = field.maxValue ?? 100;
    final step = field.step ?? 1;
    final unitLabel = _loc.translate('unit.${field.unitType.name}');
    final range = max - min;
    int? divisions;
    if (step > 0 && range > 0) {
      final raw = range / step;
      if (raw.isFinite && raw >= 1) {
        divisions = raw.round();
      }
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      _loc.translate(field.labelKey),
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.getTextPrimary(_isDark),
                      ),
                    ),
                  ),
                  if (field.required) ...[
                    const SizedBox(width: 4),
                    const Text(
                      '*',
                      style: TextStyle(color: Colors.redAccent, fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)} $unitLabel',
              style: CalculatorDesignSystem.headlineMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SizedBox(
              width: 50,
              child: Text(
                '${min.toInt()} $unitLabel',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: accentColor,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: accentColor,
                  overlayColor: accentColor.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: (v) => _updateValue(field.key, v),
                ),
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${max.toInt()} $unitLabel',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField(
    CalculatorField field,
    Map<String, double> inputs,
    Color accentColor,
  ) {
    final value = inputs[field.key] ?? field.defaultValue;

    return CalculatorTextField(
      label: _loc.translate(field.labelKey),
      value: value,
      onChanged: (v) => _updateValue(field.key, v),
      suffix: _loc.translate('unit.${field.unitType.name}'),
      hint: field.hintKey != null ? _loc.translate(field.hintKey!) : null,
      accentColor: accentColor,
      minValue: field.minValue ?? 0,
      maxValue: field.maxValue ?? double.infinity,
      isInteger: (field.step ?? 1.0) >= 1.0,
      decimalPlaces: 1,
    );
  }

  Widget _buildSelectField(CalculatorField field, Map<String, double> inputs, Color accentColor) {
    final value = inputs[field.key] ?? field.defaultValue;
    final options = field.options ?? [];

    // Если опций <= 4, используем TypeSelectorGroup для лучшего UX
    if (options.length <= 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.labelKey.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  _loc.translate(field.labelKey),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextPrimary(_isDark),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (field.required) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '*',
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
          ],
          TypeSelectorGroup(
            options: options.map((opt) => TypeSelectorOption(
              icon: _getIconForOption(opt.labelKey),
              title: _loc.translate(opt.labelKey),
              subtitle: '',
            )).toList(),
            selectedIndex: options.indexWhere((opt) => opt.value == value),
            onSelect: (index) => _updateValue(field.key, options[index].value),
            accentColor: accentColor,
          ),
        ],
      );
    }

    // Для большого количества опций используем Dropdown
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _loc.translate(field.labelKey),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            if (field.required) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: CalculatorColors.inputBackground,
            borderRadius: CalculatorDesignSystem.inputBorderRadius,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButton<double>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: CalculatorColors.inputBackground,
            style: CalculatorDesignSystem.bodyMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
            items: options.map((opt) {
              return DropdownMenuItem(
                value: opt.value,
                child: Text(_loc.translate(opt.labelKey)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) _updateValue(field.key, v);
            },
          ),
        ),
      ],
    );
  }

  IconData _getIconForOption(String labelKey) {
    // Подбираем иконку на основе ключа перевода
    final key = labelKey.toLowerCase();
    if (key.contains('gypsum') || key.contains('гипс')) return Icons.home_repair_service;
    if (key.contains('cement') || key.contains('цемент')) return Icons.construction;
    if (key.contains('paint') || key.contains('краск')) return Icons.format_paint;
    if (key.contains('wood') || key.contains('дерев')) return Icons.carpenter;
    if (key.contains('wall') || key.contains('стен')) return Icons.square;
    if (key.contains('floor') || key.contains('пол')) return Icons.layers;
    if (key.contains('ceiling') || key.contains('потолок')) return Icons.horizontal_rule;
    return Icons.check_circle;
  }

  Widget _buildToggleField(CalculatorField field, Map<String, double> inputs) {
    final value = inputs[field.key] ?? field.defaultValue;
    final isOn = value == 1.0;
    final accentColor = CalculatorColors.getColorByCategory(widget.definition.category.name);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _loc.translate(field.labelKey),
                        style: CalculatorDesignSystem.bodyMedium.copyWith(
                          color: CalculatorColors.getTextPrimary(_isDark),
                        ),
                      ),
                    ),
                    if (field.required) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(color: Colors.redAccent, fontSize: 14),
                      ),
                    ],
                  ],
                ),
                if (field.hintKey != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _loc.translate(field.hintKey!),
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: isOn,
            activeColor: accentColor,
            onChanged: (v) => _updateValue(field.key, v ? 1.0 : 0.0),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioField(CalculatorField field, Map<String, double> inputs, Color accentColor) {
    final value = inputs[field.key] ?? field.defaultValue;
    final options = field.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (field.labelKey.isNotEmpty) ...[
          Row(
            children: [
              Text(
                _loc.translate(field.labelKey),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (field.required) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
        ],
        TypeSelectorGroup(
          options: options.map((opt) => TypeSelectorOption(
            icon: _getIconForOption(opt.labelKey),
            title: _loc.translate(opt.labelKey),
            subtitle: '',
          )).toList(),
          selectedIndex: options.indexWhere((opt) => opt.value == value),
          onSelect: (index) => _updateValue(field.key, options[index].value),
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildResultHeader(Map<String, double>? results, Color accentColor) {
    if (results == null || results.isEmpty) return const SizedBox.shrink();

    // Берём до 3 первых результатов для header
    final resultKeys = results.keys.take(3).toList();
    final headerResults = <ResultItem>[];

    for (final key in resultKeys) {
      final value = results[key]!;
      final label = _translateResultLabel(key);
      headerResults.add(
        ResultItem(
          label: label.toUpperCase(),
          value: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          icon: _getIconForResult(key),
        ),
      );
    }

    return CalculatorResultHeader(
      accentColor: accentColor,
      results: headerResults,
    );
  }

  String _translateResultLabel(String key) {
    final resultKey = 'result.$key';
    final translated = _loc.translate(resultKey);
    if (translated == resultKey) {
      final fallback = _loc.translate(key);
      if (fallback != key) return fallback;
    }
    return translated;
  }

  IconData _getIconForResult(String key) {
    // Подбираем иконку по типу результата
    if (key.contains('area') || key.contains('площадь')) return Icons.straighten;
    if (key.contains('bag') || key.contains('мешк')) return Icons.shopping_bag;
    if (key.contains('weight') || key.contains('вес')) return Icons.scale;
    if (key.contains('volume') || key.contains('объем')) return Icons.water_drop;
    if (key.contains('count') || key.contains('количество')) return Icons.inventory_2;
    if (key.contains('price') || key.contains('стоимость')) return Icons.attach_money;
    return Icons.check_circle;
  }

  Widget _buildDetailsCard(Map<String, double>? results) {
    if (results == null || results.length <= 1) return const SizedBox();
    return GroupedResultsCard(
      results: results,
      loc: _loc,
      primaryKey: results.keys.first,
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CalculatorDesignSystem.spacingL),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}
