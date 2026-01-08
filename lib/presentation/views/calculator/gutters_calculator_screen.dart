import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_gutters_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Материал водостока
enum GutterMaterial {
  plastic('gutters_calc.type.plastic', 'gutters_calc.type.plastic_desc', Icons.water_drop),
  metal('gutters_calc.type.metal', 'gutters_calc.type.metal_desc', Icons.iron),
  copper('gutters_calc.type.copper', 'gutters_calc.type.copper_desc', Icons.brightness_7);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const GutterMaterial(this.nameKey, this.descKey, this.icon);
}

class _GuttersResult {
  final double gutterLength;
  final double downpipeLength;
  final int cornersCount;
  final int funnelsCount;
  final int bracketsCount;
  final int downpipeBrackets;
  final int elbowsCount;
  final double heatingLength;

  const _GuttersResult({
    required this.gutterLength,
    required this.downpipeLength,
    required this.cornersCount,
    required this.funnelsCount,
    required this.bracketsCount,
    required this.downpipeBrackets,
    required this.elbowsCount,
    required this.heatingLength,
  });

  factory _GuttersResult.fromCalculatorResult(Map<String, double> values) {
    return _GuttersResult(
      gutterLength: values['gutterLength'] ?? 0,
      downpipeLength: values['downpipeLength'] ?? 0,
      cornersCount: (values['cornersCount'] ?? 0).toInt(),
      funnelsCount: (values['funnelsCount'] ?? 0).toInt(),
      bracketsCount: (values['bracketsCount'] ?? 0).toInt(),
      downpipeBrackets: (values['downpipeBrackets'] ?? 0).toInt(),
      elbowsCount: (values['elbowsCount'] ?? 0).toInt(),
      heatingLength: values['heatingLength'] ?? 0,
    );
  }
}

class GuttersCalculatorScreen extends ConsumerStatefulWidget {
  const GuttersCalculatorScreen({super.key});

  @override
  ConsumerState<GuttersCalculatorScreen> createState() => _GuttersCalculatorScreenState();
}

class _GuttersCalculatorScreenState extends ConsumerState<GuttersCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('gutters_calc.title');

  // Domain layer calculator
  final _calculator = CalculateGuttersV2();

  double _roofLength = 10.0;
  double _roofWidth = 8.0;
  double _wallHeight = 3.0;
  int _downpipesCount = 4;

  GutterMaterial _gutterMaterial = GutterMaterial.plastic;
  bool _needHeating = false;

  late _GuttersResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _GuttersResult _calculate() {
    final inputs = <String, double>{
      'roofLength': _roofLength,
      'roofWidth': _roofWidth,
      'wallHeight': _wallHeight,
      'downpipesCount': _downpipesCount.toDouble(),
      'needHeating': _needHeating ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _GuttersResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('gutters_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('gutters_calc.export.gutter_length')
        .replaceFirst('{value}', _result.gutterLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('gutters_calc.export.downpipe_length')
        .replaceFirst('{value}', _result.downpipeLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('gutters_calc.export.material')
        .replaceFirst('{value}', _loc.translate(_gutterMaterial.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('gutters_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('gutters_calc.export.corners')
        .replaceFirst('{value}', _result.cornersCount.toString()));
    buffer.writeln(_loc.translate('gutters_calc.export.funnels')
        .replaceFirst('{value}', _result.funnelsCount.toString()));
    buffer.writeln(_loc.translate('gutters_calc.export.brackets')
        .replaceFirst('{value}', _result.bracketsCount.toString()));
    buffer.writeln(_loc.translate('gutters_calc.export.elbows')
        .replaceFirst('{value}', _result.elbowsCount.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('gutters_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('gutters_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('gutters_calc.result.gutters').toUpperCase(),
            value: '${_result.gutterLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.horizontal_rule,
          ),
          ResultItem(
            label: _loc.translate('gutters_calc.result.downpipes').toUpperCase(),
            value: '${_result.downpipeLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.arrow_downward,
          ),
          ResultItem(
            label: _loc.translate('gutters_calc.result.brackets').toUpperCase(),
            value: '${_result.bracketsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.settings,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: GutterMaterial.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _gutterMaterial.index,
      onSelect: (index) {
        setState(() {
          _gutterMaterial = GutterMaterial.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildDimensionsCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('gutters_calc.label.roof_length'), value: _roofLength, onChanged: (v) { setState(() { _roofLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 30)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('gutters_calc.label.roof_width'), value: _roofWidth, onChanged: (v) { setState(() { _roofWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 20)),
            ],
          ),
          const SizedBox(height: 12),
          CalculatorTextField(label: _loc.translate('gutters_calc.label.wall_height'), value: _wallHeight, onChanged: (v) { setState(() { _wallHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 2, maxValue: 15),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('gutters_calc.label.downpipes_count'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('$_downpipesCount ${_loc.translate('common.pcs')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _downpipesCount.toDouble(),
            min: 2,
            max: 10,
            divisions: 8,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _downpipesCount = v.toInt(); _update(); }); },
          ),
          Text(
            _loc.translate('gutters_calc.downpipes_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_loc.translate('gutters_calc.option.heating'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
        subtitle: Text(_loc.translate('gutters_calc.option.heating_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
        value: _needHeating,
        activeTrackColor: _accentColor,
        onChanged: (v) { setState(() { _needHeating = v; _update(); }); },
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('gutters_calc.materials.gutters'),
        value: '${_result.gutterLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate(_gutterMaterial.nameKey),
        icon: Icons.horizontal_rule,
      ),
      MaterialItem(
        name: _loc.translate('gutters_calc.materials.downpipes'),
        value: '${_result.downpipeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('gutters_calc.materials.downpipes_desc'),
        icon: Icons.arrow_downward,
      ),
      MaterialItem(
        name: _loc.translate('gutters_calc.materials.corners'),
        value: '${_result.cornersCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gutters_calc.materials.corners_desc'),
        icon: Icons.turn_right,
      ),
      MaterialItem(
        name: _loc.translate('gutters_calc.materials.funnels'),
        value: '${_result.funnelsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gutters_calc.materials.funnels_desc'),
        icon: Icons.filter_alt,
      ),
      MaterialItem(
        name: _loc.translate('gutters_calc.materials.brackets'),
        value: '${_result.bracketsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gutters_calc.materials.brackets_desc'),
        icon: Icons.settings,
      ),
      MaterialItem(
        name: _loc.translate('gutters_calc.materials.downpipe_brackets'),
        value: '${_result.downpipeBrackets} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gutters_calc.materials.downpipe_brackets_desc'),
        icon: Icons.radio_button_unchecked,
      ),
      MaterialItem(
        name: _loc.translate('gutters_calc.materials.elbows'),
        value: '${_result.elbowsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('gutters_calc.materials.elbows_desc'),
        icon: Icons.turn_slight_right,
      ),
    ];

    if (_needHeating) {
      items.add(MaterialItem(
        name: _loc.translate('gutters_calc.materials.heating'),
        value: '${_result.heatingLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('gutters_calc.materials.heating_desc'),
        icon: Icons.electric_bolt,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('gutters_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
