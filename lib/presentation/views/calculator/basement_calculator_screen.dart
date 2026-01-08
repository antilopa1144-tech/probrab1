import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип подвала
enum BasementType {
  technical('basement_calc.type.technical', 'basement_calc.type.technical_desc', Icons.engineering),
  living('basement_calc.type.living', 'basement_calc.type.living_desc', Icons.home),
  garage('basement_calc.type.garage', 'basement_calc.type.garage_desc', Icons.garage);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const BasementType(this.nameKey, this.descKey, this.icon);
}

class _BasementResult {
  final double floorArea;
  final double wallArea;
  final double concreteVolume;
  final double waterproofArea;
  final double insulationArea;
  final double drainageLength;

  const _BasementResult({
    required this.floorArea,
    required this.wallArea,
    required this.concreteVolume,
    required this.waterproofArea,
    required this.insulationArea,
    required this.drainageLength,
  });
}

class BasementCalculatorScreen extends StatefulWidget {
  const BasementCalculatorScreen({super.key});

  @override
  State<BasementCalculatorScreen> createState() => _BasementCalculatorScreenState();
}

class _BasementCalculatorScreenState extends State<BasementCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('basement_calc.title');
  double _length = 10.0;
  double _width = 8.0;
  double _depth = 2.5;
  double _wallThickness = 0.3;

  BasementType _basementType = BasementType.technical;
  bool _needWaterproof = true;
  bool _needInsulation = false;
  bool _needDrainage = true;

  late _BasementResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _BasementResult _calculate() {
    final floorArea = _length * _width;
    final perimeter = 2 * (_length + _width);
    final wallArea = perimeter * _depth;

    // Бетон: пол + стены
    final floorVolume = floorArea * 0.15; // 15 см толщина
    final wallVolume = wallArea * _wallThickness;
    final concreteVolume = (floorVolume + wallVolume) * 1.05;

    // Гидроизоляция: пол + стены снаружи
    final waterproofArea = _needWaterproof ? (floorArea + wallArea) * 1.15 : 0.0;

    // Утеплитель для жилого подвала
    final insulationArea = _needInsulation ? (floorArea + wallArea) * 1.1 : 0.0;

    // Дренаж по периметру
    final drainageLength = _needDrainage ? perimeter * 1.1 : 0.0;

    return _BasementResult(
      floorArea: floorArea,
      wallArea: wallArea,
      concreteVolume: concreteVolume,
      waterproofArea: waterproofArea,
      insulationArea: insulationArea,
      drainageLength: drainageLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('basement_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('basement_calc.export.floor_area')
        .replaceFirst('{value}', _result.floorArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('basement_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_basementType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('basement_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('basement_calc.export.concrete')
        .replaceFirst('{value}', _result.concreteVolume.toStringAsFixed(1)));
    if (_needWaterproof) {
      buffer.writeln(_loc.translate('basement_calc.export.waterproof')
          .replaceFirst('{value}', _result.waterproofArea.toStringAsFixed(1)));
    }
    if (_needInsulation) {
      buffer.writeln(_loc.translate('basement_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    if (_needDrainage) {
      buffer.writeln(_loc.translate('basement_calc.export.drainage')
          .replaceFirst('{value}', _result.drainageLength.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('basement_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('basement_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('basement_calc.result.floor_area').toUpperCase(),
            value: '${_result.floorArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('basement_calc.result.concrete').toUpperCase(),
            value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.view_in_ar,
          ),
          ResultItem(
            label: _loc.translate('basement_calc.result.wall_area').toUpperCase(),
            value: '${_result.wallArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
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
      options: BasementType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _basementType.index,
      onSelect: (index) {
        setState(() {
          _basementType = BasementType.values[index];
          if (_basementType == BasementType.living) {
            _needInsulation = true;
          }
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
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.length'), value: _length, onChanged: (v) { setState(() { _length = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 30)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.width'), value: _width, onChanged: (v) { setState(() { _width = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.depth'), value: _depth, onChanged: (v) { setState(() { _depth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1.5, maxValue: 4)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('basement_calc.label.wall_thickness'), value: _wallThickness * 100, onChanged: (v) { setState(() { _wallThickness = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 20, maxValue: 50)),
            ],
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
            title: Text(_loc.translate('basement_calc.option.waterproof'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('basement_calc.option.waterproof_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needWaterproof,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needWaterproof = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('basement_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('basement_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needInsulation,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('basement_calc.option.drainage'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('basement_calc.option.drainage_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needDrainage,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needDrainage = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('basement_calc.materials.concrete'),
        value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('basement_calc.materials.concrete_desc'),
        icon: Icons.view_in_ar,
      ),
    ];

    if (_needWaterproof && _result.waterproofArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('basement_calc.materials.waterproof'),
        value: '${_result.waterproofArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('basement_calc.materials.waterproof_desc'),
        icon: Icons.water_drop,
      ));
    }

    if (_needInsulation && _result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('basement_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('basement_calc.materials.insulation_desc'),
        icon: Icons.layers,
      ));
    }

    if (_needDrainage && _result.drainageLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('basement_calc.materials.drainage'),
        value: '${_result.drainageLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('basement_calc.materials.drainage_desc'),
        icon: Icons.water,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('basement_calc.section.materials'),
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
