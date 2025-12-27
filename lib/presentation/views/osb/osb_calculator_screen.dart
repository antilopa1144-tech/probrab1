import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/services/calculator_memory_service.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_field.dart';
import '../../views/calculator/pro_calculator_screen.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/calculator/grouped_results_card.dart';
import '../../widgets/existing/hint_card.dart';

class OsbCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const OsbCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  ConsumerState<OsbCalculatorScreen> createState() => _OsbCalculatorScreenState();
}

class _OsbCalculatorScreenState extends ConsumerState<OsbCalculatorScreen> {
  late final CalculatorMemoryService _memory;
  Map<String, double> _latestInputs = {};
  late AppLocalizations _loc;

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
    ref.read(proCalculatorProvider(widget.definition).notifier).updateInput(key, value);
  }

  CalculatorField _field(String key) {
    return widget.definition.fields.firstWhere((f) => f.key == key);
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    final calcState = ref.watch(proCalculatorProvider(widget.definition));
    _latestInputs = Map<String, double>.from(calcState.inputs);
    final accentColor = CalculatorColors.getColorByCategory(widget.definition.category.name);
    final afterHints = calcState.results != null
        ? widget.definition.getAfterHints(calcState.inputs, calcState.results!)
        : const <CalculatorHint>[];
    final beforeHints = widget.definition.getBeforeHints(calcState.inputs);
    final bottomHints = [...afterHints, ...beforeHints];

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      resultHeader: calcState.results != null
          ? _buildResultHeader(calcState.results!, accentColor)
          : null,
      children: [
        _buildModeSelector(calcState.inputs, accentColor),
        const SizedBox(height: 16),
        _buildDimensionsGroup(calcState.inputs, accentColor),
        const SizedBox(height: 16),
        _buildSheetGroup(calcState.inputs, calcState.results, accentColor),
        const SizedBox(height: 16),
        _buildApplicationGroup(calcState.inputs, accentColor),
        const SizedBox(height: 16),
        _buildReserveGroup(calcState.inputs, accentColor),
        const SizedBox(height: 16),
        _buildOpeningsGroup(calcState.inputs, accentColor),
        const SizedBox(height: 16),
        if (calcState.results != null) GroupedResultsCard(
          results: calcState.results!,
          loc: _loc,
        ),
        if (bottomHints.isNotEmpty) const SizedBox(height: 16),
        if (bottomHints.isNotEmpty) HintsList(hints: bottomHints),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildModeSelector(Map<String, double> inputs, Color accentColor) {
    final field = _field('inputMode');
    final options = field.options ?? [];
    final current = inputs[field.key] ?? field.defaultValue;
    final selectedIndex = options.indexWhere((opt) => opt.value == current);

    return InputGroup(
      title: _loc.translate('group.dimensions'),
      icon: Icons.straighten,
      accentColor: accentColor,
      children: [
        ModeSelector(
          options: options.map((opt) => _loc.translate(opt.labelKey)).toList(),
          selectedIndex: selectedIndex < 0 ? 0 : selectedIndex,
          onSelect: (index) => _updateValue(field.key, options[index].value),
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildDimensionsGroup(Map<String, double> inputs, Color accentColor) {
    final lengthField = _field('length');
    final widthField = _field('width');
    final areaField = _field('area');
    final children = <Widget>[];

    if (lengthField.shouldDisplay(inputs) && widthField.shouldDisplay(inputs)) {
      children.add(
        Row(
          children: [
            Expanded(child: _buildNumberField(lengthField, inputs, accentColor)),
            const SizedBox(width: 12),
            Expanded(child: _buildNumberField(widthField, inputs, accentColor)),
          ],
        ),
      );
    }

    if (areaField.shouldDisplay(inputs)) {
      children.add(_buildNumberField(areaField, inputs, accentColor));
    }

    return InputGroup(
      title: _loc.translate('group.dimensions'),
      icon: Icons.straighten,
      accentColor: accentColor,
      children: children,
    );
  }

  Widget _buildSheetGroup(
    Map<String, double> inputs,
    Map<String, double>? results,
    Color accentColor,
  ) {
    final sheetSizeField = _field('sheetSize');
    final sheetLengthField = _field('sheetLength');
    final sheetWidthField = _field('sheetWidth');
    final thicknessField = _field('thickness');
    final osbClassField = _field('osbClass');

    final children = <Widget>[
      _buildSelectField(sheetSizeField, inputs, accentColor),
    ];

    if (sheetLengthField.shouldDisplay(inputs) || sheetWidthField.shouldDisplay(inputs)) {
      children.add(
        Row(
          children: [
            if (sheetLengthField.shouldDisplay(inputs))
              Expanded(child: _buildNumberField(sheetLengthField, inputs, accentColor)),
            if (sheetLengthField.shouldDisplay(inputs) && sheetWidthField.shouldDisplay(inputs))
              const SizedBox(width: 12),
            if (sheetWidthField.shouldDisplay(inputs))
              Expanded(child: _buildNumberField(sheetWidthField, inputs, accentColor)),
          ],
        ),
      );
    }

    children.add(_buildSelectField(thicknessField, inputs, accentColor));
    children.add(_buildSelectField(osbClassField, inputs, accentColor));

    final recommendedThickness = results?['recommendedThickness'];
    if (recommendedThickness != null && recommendedThickness > 0) {
      children.add(
        Row(
          children: [
            Icon(Icons.recommend, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${_loc.translate('result.recommendedThickness')}: '
                '${recommendedThickness.toStringAsFixed(0)} '
                '${_loc.translate('unit.mm')}',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return InputGroup(
      title: _loc.translate('group.sheet'),
      icon: Icons.grid_on,
      accentColor: accentColor,
      children: children,
    );
  }

  Widget _buildApplicationGroup(Map<String, double> inputs, Color accentColor) {
    final constructionField = _field('constructionType');
    final joistStepField = _field('joistStep');
    final rafterStepField = _field('rafterStep');
    final environmentField = _field('environment');
    final loadLevelField = _field('loadLevel');

    final children = <Widget>[
      _buildSelectField(constructionField, inputs, accentColor),
    ];

    if (joistStepField.shouldDisplay(inputs)) {
      children.add(_buildSelectField(joistStepField, inputs, accentColor));
    }
    if (rafterStepField.shouldDisplay(inputs)) {
      children.add(_buildSelectField(rafterStepField, inputs, accentColor));
    }
    children.add(_buildSelectField(environmentField, inputs, accentColor));
    children.add(_buildSelectField(loadLevelField, inputs, accentColor));

    return InputGroup(
      title: _loc.translate('group.application'),
      icon: Icons.home_repair_service,
      accentColor: accentColor,
      children: children,
    );
  }

  Widget _buildReserveGroup(Map<String, double> inputs, Color accentColor) {
    final reserveField = _field('reserve');
    return InputGroup(
      title: _loc.translate('group.parameters'),
      icon: Icons.tune,
      accentColor: accentColor,
      children: [
        _buildSliderField(reserveField, inputs, accentColor),
      ],
    );
  }

  Widget _buildOpeningsGroup(Map<String, double> inputs, Color accentColor) {
    final windowsField = _field('windowsArea');
    final doorsField = _field('doorsArea');

    return InputGroup(
      title: _loc.translate('group.openings'),
      icon: Icons.door_front_door,
      accentColor: accentColor,
      isCollapsible: true,
      initiallyExpanded: false,
      children: [
        _buildNumberField(windowsField, inputs, accentColor),
        _buildNumberField(doorsField, inputs, accentColor),
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

  Widget _buildSelectField(
    CalculatorField field,
    Map<String, double> inputs,
    Color accentColor,
  ) {
    final value = inputs[field.key] ?? field.defaultValue;
    final options = field.options ?? [];

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
                    color: CalculatorColors.textPrimary,
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
              color: CalculatorColors.textPrimary,
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

  Widget _buildSliderField(
    CalculatorField field,
    Map<String, double> inputs,
    Color accentColor,
  ) {
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
                  color: CalculatorColors.textSecondary,
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

  Widget _buildResultHeader(Map<String, double> results, Color accentColor) {
    final headerResults = <ResultItem>[];

    void addItem(String key, IconData icon) {
      final value = results[key];
      if (value == null) return;
      headerResults.add(
        ResultItem(
          label: _translateResultLabel(key).toUpperCase(),
          value: value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
          icon: icon,
        ),
      );
    }

    addItem('sheetsNeeded', Icons.layers);
    addItem('screwsNeeded', Icons.build);
    addItem('materialArea', Icons.straighten);

    if (headerResults.length < 2) {
      return const SizedBox.shrink();
    }

    return CalculatorResultHeader(
      accentColor: accentColor,
      results: headerResults.take(3).toList(),
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

  IconData _getIconForOption(String labelKey) {
    final key = labelKey.toLowerCase();
    if (key.contains('wall')) return Icons.square;
    if (key.contains('floor')) return Icons.layers;
    if (key.contains('roof')) return Icons.roofing;
    if (key.contains('partition')) return Icons.view_week;
    if (key.contains('sip')) return Icons.holiday_village;
    if (key.contains('formwork')) return Icons.factory;
    if (key.contains('wet')) return Icons.water_drop;
    if (key.contains('outdoor')) return Icons.cloud;
    if (key.contains('high')) return Icons.fitness_center;
    return Icons.check_circle;
  }
}
