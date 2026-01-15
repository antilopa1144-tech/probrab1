import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_ceiling_insulation_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип утеплителя
enum CeilingInsulationType {
  mineralWool('ceiling_insulation_calc.type.mineral_wool', 'ceiling_insulation_calc.type.mineral_wool_desc', Icons.waves),
  styrofoam('ceiling_insulation_calc.type.styrofoam', 'ceiling_insulation_calc.type.styrofoam_desc', Icons.grid_view),
  extrudedPPS('ceiling_insulation_calc.type.extruded', 'ceiling_insulation_calc.type.extruded_desc', Icons.layers);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const CeilingInsulationType(this.nameKey, this.descKey, this.icon);
}

enum CeilingInsulationInputMode { manual, room }

class _CeilingInsulationResult {
  final double area;
  final double insulationArea;
  final int insulationPacks;
  final double vaporBarrierArea;
  final double membraneArea;

  const _CeilingInsulationResult({
    required this.area,
    required this.insulationArea,
    required this.insulationPacks,
    required this.vaporBarrierArea,
    required this.membraneArea,
  });

  factory _CeilingInsulationResult.fromCalculatorResult(Map<String, double> values) {
    return _CeilingInsulationResult(
      area: values['area'] ?? 0,
      insulationArea: values['insulationArea'] ?? 0,
      insulationPacks: (values['insulationPacks'] ?? 0).toInt(),
      vaporBarrierArea: values['vaporBarrierArea'] ?? 0,
      membraneArea: values['membraneArea'] ?? 0,
    );
  }
}

class CeilingInsulationCalculatorScreen extends ConsumerStatefulWidget {
  const CeilingInsulationCalculatorScreen({super.key});

  @override
  ConsumerState<CeilingInsulationCalculatorScreen> createState() => _CeilingInsulationCalculatorScreenState();
}

class _CeilingInsulationCalculatorScreenState extends ConsumerState<CeilingInsulationCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('ceiling_insulation_calc.title');

  // Domain layer calculator
  final _calculator = CalculateCeilingInsulationV2();

  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _thickness = 100.0; // мм

  CeilingInsulationType _insulationType = CeilingInsulationType.mineralWool;
  CeilingInsulationInputMode _inputMode = CeilingInsulationInputMode.manual;
  bool _needVaporBarrier = true;
  bool _needMembrane = true;

  late _CeilingInsulationResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _CeilingInsulationResult _calculate() {
    final inputs = <String, double>{
      'area': _area,
      'roomWidth': _roomWidth,
      'roomLength': _roomLength,
      'thickness': _thickness,
      'insulationType': _insulationType.index.toDouble(),
      'inputMode': _inputMode.index.toDouble(),
      'needVaporBarrier': _needVaporBarrier ? 1.0 : 0.0,
      'needMembrane': _needMembrane ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _CeilingInsulationResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('ceiling_insulation_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('ceiling_insulation_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('ceiling_insulation_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_insulationType.nameKey)));
    buffer.writeln(_loc.translate('ceiling_insulation_calc.export.thickness')
        .replaceFirst('{value}', _thickness.toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln(_loc.translate('ceiling_insulation_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('ceiling_insulation_calc.export.insulation')
        .replaceFirst('{value}', _result.insulationPacks.toString()));
    if (_needVaporBarrier) {
      buffer.writeln(_loc.translate('ceiling_insulation_calc.export.vapor_barrier')
          .replaceFirst('{value}', _result.vaporBarrierArea.toStringAsFixed(1)));
    }
    if (_needMembrane) {
      buffer.writeln(_loc.translate('ceiling_insulation_calc.export.membrane')
          .replaceFirst('{value}', _result.membraneArea.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('ceiling_insulation_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('ceiling_insulation_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('ceiling_insulation_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('ceiling_insulation_calc.result.packs').toUpperCase(),
            value: '${_result.insulationPacks}',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: _loc.translate('ceiling_insulation_calc.result.thickness').toUpperCase(),
            value: '${_thickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}',
            icon: Icons.height,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_insulationType) {
      case CeilingInsulationType.mineralWool:
        tips.addAll([
          _loc.translate('ceiling_insulation_calc.tip.mineral_wool_1'),
          _loc.translate('ceiling_insulation_calc.tip.mineral_wool_2'),
        ]);
        break;
      case CeilingInsulationType.styrofoam:
        tips.addAll([
          _loc.translate('ceiling_insulation_calc.tip.styrofoam_1'),
          _loc.translate('ceiling_insulation_calc.tip.styrofoam_2'),
        ]);
        break;
      case CeilingInsulationType.extrudedPPS:
        tips.addAll([
          _loc.translate('ceiling_insulation_calc.tip.extruded_1'),
          _loc.translate('ceiling_insulation_calc.tip.extruded_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('ceiling_insulation_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: CeilingInsulationType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _insulationType.index,
      onSelect: (index) {
        setState(() {
          _insulationType = CeilingInsulationType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('ceiling_insulation_calc.mode.manual'),
              _loc.translate('ceiling_insulation_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = CeilingInsulationInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == CeilingInsulationInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('ceiling_insulation_calc.label.area'),
      value: _area,
      min: 5,
      max: 200,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) { setState(() { _area = v; _update(); }); },
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('ceiling_insulation_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('ceiling_insulation_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('ceiling_insulation_calc.label.ceiling_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThicknessCard() {
    return _card(
      child: CalculatorSliderField(
        label: _loc.translate('ceiling_insulation_calc.label.thickness'),
        value: _thickness,
        min: 50,
        max: 200,
        divisions: 6,
        suffix: _loc.translate('common.mm'),
        accentColor: _accentColor,
        onChanged: (v) { setState(() { _thickness = v; _update(); }); },
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('ceiling_insulation_calc.option.vapor_barrier'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('ceiling_insulation_calc.option.vapor_barrier_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needVaporBarrier,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needVaporBarrier = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('ceiling_insulation_calc.option.membrane'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('ceiling_insulation_calc.option.membrane_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needMembrane,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needMembrane = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('ceiling_insulation_calc.materials.insulation'),
        value: '${_result.insulationPacks} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.waves,
      ),
    ];

    if (_needVaporBarrier && _result.vaporBarrierArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('ceiling_insulation_calc.materials.vapor_barrier'),
        value: '${_result.vaporBarrierArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ));
    }

    if (_needMembrane && _result.membraneArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('ceiling_insulation_calc.materials.membrane'),
        value: '${_result.membraneArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.filter_list,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('ceiling_insulation_calc.section.materials'),
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
