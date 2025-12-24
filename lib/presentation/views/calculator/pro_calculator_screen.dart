// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/validation/input_sanitizer.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../core/exceptions/calculation_exception.dart';
import '../../../core/services/calculator_memory_service.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_field.dart';
import '../../../data/models/price_item.dart';
import '../../providers/price_provider.dart';
import '../../providers/settings_provider.dart';
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
    state = state.copyWith(inputs: defaults);
    calculate();
  }

  void applyInputs(Map<String, double> inputs) {
    if (inputs.isEmpty) return;
    final merged = Map<String, double>.from(state.inputs);
    for (final entry in inputs.entries) {
      merged[entry.key] = entry.value;
    }
    state = state.copyWith(inputs: merged);
    calculate();
  }

  void updateInput(String key, double value) {
    final updated = Map<String, double>.from(state.inputs);
    updated[key] = value;
    state = state.copyWith(inputs: updated);
    calculate();
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
  // Контроллеры для текстовых полей (только для number полей)
  final Map<String, TextEditingController> _controllers = {};
  late final CalculatorMemoryService _memory;
  Map<String, double> _latestInputs = {};

  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    _memory = ref.read(calculatorMemoryProvider);
    _latestInputs =
        Map<String, double>.from(ref.read(proCalculatorProvider(widget.definition)).inputs);
    _initializeControllers();
    _loadLastInputs();
  }

  @override
  void dispose() {
    _memory.saveLastInputs(widget.definition.id, _latestInputs);
    for (final controller in _controllers.values) {
      controller.dispose();
    }
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
    for (final entry in inputs.entries) {
      _controllers[entry.key]?.text =
          entry.value.toStringAsFixed(entry.value % 1 == 0 ? 0 : 1);
    }
  }

  void _initializeControllers() {
    for (final field in widget.definition.fields) {
      final initialValue = widget.initialInputs?[field.key] ?? field.defaultValue;
      // Создаем контроллер только для number полей
      if (field.inputType == FieldInputType.number) {
        _controllers[field.key] = TextEditingController(
          text: initialValue != 0 ? initialValue.toStringAsFixed(0) : '',
        );
      }
    }
  }

  void _updateValue(String key, double value) {
    ref
        .read(proCalculatorProvider(widget.definition).notifier)
        .updateInput(key, value);
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    final calcState = ref.watch(proCalculatorProvider(widget.definition));
    _latestInputs = Map<String, double>.from(calcState.inputs);
    final settings = ref.watch(settingsProvider);
    final accentColor = CalculatorColors.getColorByCategory(widget.definition.category.name);

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      resultHeader: calcState.results != null ? _buildResultHeader(calcState.results, accentColor) : null,
      children: [
        // Режим: Новичок / PRO
        ModeSelector(
          options: [
            _loc.translate('mode.beginner'),
            _loc.translate('mode.pro'),
          ],
          selectedIndex: settings.isProMode ? 1 : 0,
          onSelect: (index) {
            ref.read(settingsProvider.notifier).setProMode(index == 1);
          },
          accentColor: accentColor,
        ),
        const SizedBox(height: 16),
        ..._buildInputFields(calcState.inputs, settings.isProMode),
        const SizedBox(height: 16),
        if (calcState.results != null) _buildDetailsCard(calcState.results),
        const SizedBox(height: 20),
      ],
    );
  }

  List<Widget> _buildInputFields(
    Map<String, double> inputs,
    bool isProMode,
  ) {
    final visibleFields =
        widget.definition.getVisibleFieldsForMode(inputs, isProMode);
    final groupedFields = <String, List<CalculatorField>>{};

    // Группируем поля
    for (final field in visibleFields) {
      final group = field.group ?? 'default';
      groupedFields.putIfAbsent(group, () => []);
      groupedFields[group]!.add(field);
    }

    final widgets = <Widget>[];

    for (final entry in groupedFields.entries) {
      widgets.add(_card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (entry.key != 'default') ...[
              Text(
                _loc.translate('group.${entry.key}').toUpperCase(),
                style: CalculatorDesignSystem.labelSmall.copyWith(
                  color: CalculatorColors.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
            ],
            ...entry.value.map((field) => _buildField(field, inputs)),
          ],
        ),
      ));
      widgets.add(const SizedBox(height: 16));
    }

    return widgets;
  }

  Widget _buildField(CalculatorField field, Map<String, double> inputs) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (field.inputType) {
        FieldInputType.slider => _buildSliderField(field, inputs),
        FieldInputType.select => _buildSelectField(field, inputs),
        FieldInputType.checkbox || FieldInputType.switch_ =>
          _buildToggleField(field, inputs),
        FieldInputType.radio => _buildRadioField(field, inputs),
        _ => _buildNumberField(field, inputs),
      },
    );
  }

  Widget _buildSliderField(CalculatorField field, Map<String, double> inputs) {
    final value = inputs[field.key] ?? field.defaultValue;
    final min = field.minValue ?? 0;
    final max = field.maxValue ?? 100;
    final unitLabel = _loc.translate('unit.${field.unitType.name}');

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
                        color: CalculatorColors.textPrimary,
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
                color: CalculatorColors.interior,
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
                  color: CalculatorColors.textSecondary,
                ),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: CalculatorColors.interior,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: CalculatorColors.interior,
                  overlayColor: CalculatorColors.interior.withValues(alpha: 0.2),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  divisions: ((max - min) / (field.step ?? 1)).round(),
                  onChanged: (v) => _updateValue(field.key, v),
                ),
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                '${max.toInt()} $unitLabel',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.textSecondary,
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
  ) {
    final value = inputs[field.key] ?? field.defaultValue;
    final step = field.step ?? 1.0;
    final min = field.minValue ?? 0;
    final max = field.maxValue ?? double.infinity;
    final controller = _controllers[field.key];

    void applyValue(double next) {
      final clamped = next.clamp(min, max);
      _updateValue(field.key, clamped);
      if (controller != null) {
        controller.text = clamped.toStringAsFixed(clamped % 1 == 0 ? 0 : 1);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _loc.translate(field.labelKey),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
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
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              color: CalculatorColors.textSecondary,
              onPressed: value > min ? () => applyValue(value - step) : null,
            ),
            Expanded(
              child: TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: CalculatorDesignSystem.bodyLarge.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText:
                      field.hintKey == null ? null : _loc.translate(field.hintKey!),
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                  suffixText: _loc.translate('unit.${field.unitType.name}'),
                  suffixStyle: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: CalculatorColors.interior, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (text) {
                  final parsed =
                      InputSanitizer.parseDouble(text) ?? field.defaultValue;
                  _updateValue(field.key, parsed);
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              color: CalculatorColors.textSecondary,
              onPressed: value < max ? () => applyValue(value + step) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectField(CalculatorField field, Map<String, double> inputs) {
    final value = inputs[field.key] ?? field.defaultValue;
    final options = field.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _loc.translate(field.labelKey),
              style: const TextStyle(color: Colors.white70, fontSize: 14),
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
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: DropdownButton<double>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: const Color(0xFF1E293B),
            style: const TextStyle(color: Colors.white),
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

  Widget _buildToggleField(CalculatorField field, Map<String, double> inputs) {
    final value = inputs[field.key] ?? field.defaultValue;
    final isOn = value == 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    _loc.translate(field.labelKey),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
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
          Switch(
            value: isOn,
            activeThumbColor: Colors.blueAccent,
            activeTrackColor: Colors.blueAccent.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.white24,
            inactiveTrackColor: Colors.white10,
            onChanged: (v) => _updateValue(field.key, v ? 1.0 : 0.0),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioField(CalculatorField field, Map<String, double> inputs) {
    final value = inputs[field.key] ?? field.defaultValue;
    final options = field.options ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              _loc.translate(field.labelKey),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
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
        ...options.map((opt) {
          final isSelected = value == opt.value;
          return InkWell(
            onTap: () => _updateValue(field.key, opt.value),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? Colors.blueAccent : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<double>(
                    value: opt.value,
                    groupValue: value,
                    fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.blueAccent;
                      }
                      return Colors.white24;
                    }),
                    onChanged: (v) {
                      if (v != null) _updateValue(field.key, v);
                    },
                  ),
                  Expanded(
                    child: Text(
                      _loc.translate(opt.labelKey),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
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
      headerResults.add(
        ResultItem(
          label: _loc.translate('result.$key').toUpperCase(),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(CalculatorDesignSystem.spacingL),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
