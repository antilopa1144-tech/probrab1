import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
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
}

class SlabCalculatorScreen extends StatefulWidget {
  const SlabCalculatorScreen({super.key});

  @override
  State<SlabCalculatorScreen> createState() => _SlabCalculatorScreenState();
}

class _SlabCalculatorScreenState extends State<SlabCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('slab_calc.title');

  double _length = 10.0;
  double _width = 8.0;
  double _thickness = 0.3;

  SlabType _slabType = SlabType.monolithic;
  bool _needWaterproof = true;
  bool _needInsulation = true;

  late _SlabResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _SlabResult _calculate() {
    final slabArea = _length * _width;

    // Бетон
    double concreteVolume = slabArea * _thickness;
    if (_slabType == SlabType.ribbed) {
      // Добавляем рёбра жёсткости
      concreteVolume *= 1.15;
    }
    concreteVolume *= 1.02; // запас на потери

    // Арматура: ~80-100 кг на м³ бетона
    final reinforcementWeight = concreteVolume * 90;

    // Песчаная подушка (20 см)
    final sandVolume = slabArea * 0.2 * 1.1;

    // Щебень (15 см)
    final gravelVolume = slabArea * 0.15 * 1.1;

    // Гидроизоляция
    final waterproofArea = _needWaterproof ? slabArea * 1.15 : 0.0;

    // Утеплитель под плиту
    final insulationArea = _needInsulation ? slabArea * 1.05 : 0.0;

    return _SlabResult(
      slabArea: slabArea,
      concreteVolume: concreteVolume,
      reinforcementWeight: reinforcementWeight,
      sandVolume: sandVolume,
      gravelVolume: gravelVolume,
      waterproofArea: waterproofArea,
      insulationArea: insulationArea,
    );
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
              Text(_loc.translate('slab_calc.label.thickness'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
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
            title: Text(_loc.translate('slab_calc.option.waterproof'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('slab_calc.option.waterproof_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needWaterproof,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needWaterproof = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('slab_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('slab_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needInsulation,
            activeColor: _accentColor,
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
