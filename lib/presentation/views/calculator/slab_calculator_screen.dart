import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_slab_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип фундаментной плиты
enum SlabType {
  monolithic('slab_calc.type.monolithic', 'slab_calc.type.monolithic_desc', Icons.view_module),
  ribbed('slab_calc.type.ribbed', 'slab_calc.type.ribbed_desc', Icons.view_agenda),
  floating('slab_calc.type.floating', 'slab_calc.type.floating_desc', Icons.waves);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const SlabType(this.nameKey, this.descKey, this.icon);
}

class _SlabResult {
  final double slabArea;
  final double concreteVolume;
  final double reinforcementWeight;
  final double sandVolume;
  final double gravelVolume;
  final double waterproofArea;
  final double insulationArea;

  const _SlabResult({
    required this.slabArea,
    required this.concreteVolume,
    required this.reinforcementWeight,
    required this.sandVolume,
    required this.gravelVolume,
    required this.waterproofArea,
    required this.insulationArea,
  });

  factory _SlabResult.fromCalculatorResult(Map<String, double> values) {
    return _SlabResult(
      slabArea: values['slabArea'] ?? 0,
      concreteVolume: values['concreteVolume'] ?? 0,
      reinforcementWeight: values['reinforcementWeight'] ?? 0,
      sandVolume: values['sandVolume'] ?? 0,
      gravelVolume: values['gravelVolume'] ?? 0,
      waterproofArea: values['waterproofArea'] ?? 0,
      insulationArea: values['insulationArea'] ?? 0,
    );
  }
}

class SlabCalculatorScreen extends ConsumerStatefulWidget {
  const SlabCalculatorScreen({super.key});

  @override
  ConsumerState<SlabCalculatorScreen> createState() => _SlabCalculatorScreenState();
}

class _SlabCalculatorScreenState extends ConsumerState<SlabCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('slab_calc.title');

  // Domain layer calculator
  final _calculator = CalculateSlabV2();

  double _length = 10.0;
  double _width = 8.0;
  double _thickness = 0.3;

  SlabType _slabType = SlabType.monolithic;
  bool _needWaterproof = true;
  bool _needInsulation = true;

  late _SlabResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.foundation;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _SlabResult _calculate() {
    final inputs = <String, double>{
      'length': _length,
      'width': _width,
      'thickness': _thickness,
      'slabType': _slabType.index.toDouble(),
      'needWaterproof': _needWaterproof ? 1.0 : 0.0,
      'needInsulation': _needInsulation ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _SlabResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('slab_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('slab_calc.export.area')
        .replaceFirst('{value}', _result.slabArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('slab_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_slabType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('slab_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('slab_calc.export.concrete')
        .replaceFirst('{value}', _result.concreteVolume.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('slab_calc.export.reinforcement')
        .replaceFirst('{value}', _result.reinforcementWeight.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('slab_calc.export.sand')
        .replaceFirst('{value}', _result.sandVolume.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('slab_calc.export.gravel')
        .replaceFirst('{value}', _result.gravelVolume.toStringAsFixed(1)));
    if (_needWaterproof) {
      buffer.writeln(_loc.translate('slab_calc.export.waterproof')
          .replaceFirst('{value}', _result.waterproofArea.toStringAsFixed(1)));
    }
    if (_needInsulation) {
      buffer.writeln(_loc.translate('slab_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('slab_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('slab_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('slab_calc.result.area').toUpperCase(),
            value: '${_result.slabArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('slab_calc.result.concrete').toUpperCase(),
            value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.view_in_ar,
          ),
          ResultItem(
            label: _loc.translate('slab_calc.result.reinforcement').toUpperCase(),
            value: '${_result.reinforcementWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
            icon: Icons.grid_4x4,
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
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: SlabType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _slabType.index,
      onSelect: (index) {
        setState(() {
          _slabType = SlabType.values[index];
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
              Expanded(child: CalculatorTextField(label: _loc.translate('slab_calc.label.length'), value: _length, onChanged: (v) { setState(() { _length = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 30)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('slab_calc.label.width'), value: _width, onChanged: (v) { setState(() { _width = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 20)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('slab_calc.label.thickness'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w600)),
              Text('${(_thickness * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _thickness * 100,
            min: 20,
            max: 50,
            divisions: 6,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _thickness = v / 100; _update(); }); },
          ),
          Text(
            _loc.translate('slab_calc.thickness_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('slab_calc.option.waterproof'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('slab_calc.option.waterproof_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needWaterproof,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needWaterproof = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('slab_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('slab_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needInsulation,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('slab_calc.materials.concrete'),
        value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('slab_calc.materials.concrete_desc'),
        icon: Icons.view_in_ar,
      ),
      MaterialItem(
        name: _loc.translate('slab_calc.materials.reinforcement'),
        value: '${_result.reinforcementWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('slab_calc.materials.reinforcement_desc'),
        icon: Icons.grid_4x4,
      ),
      MaterialItem(
        name: _loc.translate('slab_calc.materials.sand'),
        value: '${_result.sandVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('slab_calc.materials.sand_desc'),
        icon: Icons.grain,
      ),
      MaterialItem(
        name: _loc.translate('slab_calc.materials.gravel'),
        value: '${_result.gravelVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('slab_calc.materials.gravel_desc'),
        icon: Icons.circle,
      ),
    ];

    if (_needWaterproof && _result.waterproofArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('slab_calc.materials.waterproof'),
        value: '${_result.waterproofArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('slab_calc.materials.waterproof_desc'),
        icon: Icons.water_drop,
      ));
    }

    if (_needInsulation && _result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('slab_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('slab_calc.materials.insulation_desc'),
        icon: Icons.layers,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('slab_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_slabType) {
      case SlabType.monolithic:
        tips.addAll([
          _loc.translate('slab_calc.tip.monolithic_1'),
          _loc.translate('slab_calc.tip.monolithic_2'),
        ]);
        break;
      case SlabType.ribbed:
        tips.addAll([
          _loc.translate('slab_calc.tip.ribbed_1'),
          _loc.translate('slab_calc.tip.ribbed_2'),
        ]);
        break;
      case SlabType.floating:
        tips.addAll([
          _loc.translate('slab_calc.tip.floating_1'),
          _loc.translate('slab_calc.tip.floating_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('slab_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}
