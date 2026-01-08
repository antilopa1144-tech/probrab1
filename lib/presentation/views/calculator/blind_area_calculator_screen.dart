import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип отмостки
enum BlindAreaType {
  concrete('blind_area_calc.type.concrete', 'blind_area_calc.type.concrete_desc', Icons.view_agenda),
  paving('blind_area_calc.type.paving', 'blind_area_calc.type.paving_desc', Icons.grid_on),
  soft('blind_area_calc.type.soft', 'blind_area_calc.type.soft_desc', Icons.grass);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const BlindAreaType(this.nameKey, this.descKey, this.icon);
}

class _BlindAreaResult {
  final double totalArea;
  final double perimeter;
  final double concreteVolume;
  final double sandVolume;
  final double gravelVolume;
  final double membranArea;

  const _BlindAreaResult({
    required this.totalArea,
    required this.perimeter,
    required this.concreteVolume,
    required this.sandVolume,
    required this.gravelVolume,
    required this.membranArea,
  });
}

class BlindAreaCalculatorScreen extends StatefulWidget {
  const BlindAreaCalculatorScreen({super.key});

  @override
  State<BlindAreaCalculatorScreen> createState() => _BlindAreaCalculatorScreenState();
}

class _BlindAreaCalculatorScreenState extends State<BlindAreaCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('blind_area_calc.title');
  double _houseLength = 10.0;
  double _houseWidth = 8.0;
  double _blindAreaWidth = 1.0;
  double _thickness = 0.1;

  BlindAreaType _blindAreaType = BlindAreaType.concrete;
  bool _needInsulation = false;
  bool _needDrainage = true;

  late _BlindAreaResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _BlindAreaResult _calculate() {
    // Периметр дома
    final perimeter = 2 * (_houseLength + _houseWidth);

    // Площадь отмостки
    final totalArea = perimeter * _blindAreaWidth;

    // Бетон (для бетонной отмостки)
    double concreteVolume = 0;
    if (_blindAreaType == BlindAreaType.concrete) {
      concreteVolume = totalArea * _thickness * 1.05;
    }

    // Песчаная подушка (10 см)
    final sandVolume = totalArea * 0.1 * 1.1;

    // Щебень (15 см)
    final gravelVolume = totalArea * 0.15 * 1.1;

    // Мембрана с запасом на нахлёсты
    final membranArea = totalArea * 1.15;

    return _BlindAreaResult(
      totalArea: totalArea,
      perimeter: perimeter,
      concreteVolume: concreteVolume,
      sandVolume: sandVolume,
      gravelVolume: gravelVolume,
      membranArea: membranArea,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('blind_area_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('blind_area_calc.export.perimeter')
        .replaceFirst('{value}', _result.perimeter.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('blind_area_calc.export.area')
        .replaceFirst('{value}', _result.totalArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('blind_area_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_blindAreaType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('blind_area_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    if (_blindAreaType == BlindAreaType.concrete) {
      buffer.writeln(_loc.translate('blind_area_calc.export.concrete')
          .replaceFirst('{value}', _result.concreteVolume.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('blind_area_calc.export.sand')
        .replaceFirst('{value}', _result.sandVolume.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('blind_area_calc.export.gravel')
        .replaceFirst('{value}', _result.gravelVolume.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('blind_area_calc.export.membrane')
        .replaceFirst('{value}', _result.membranArea.toStringAsFixed(1)));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('blind_area_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('blind_area_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('blind_area_calc.result.perimeter').toUpperCase(),
            value: '${_result.perimeter.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.crop_square,
          ),
          ResultItem(
            label: _loc.translate('blind_area_calc.result.area').toUpperCase(),
            value: '${_result.totalArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('blind_area_calc.result.concrete').toUpperCase(),
            value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.view_in_ar,
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
      options: BlindAreaType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _blindAreaType.index,
      onSelect: (index) {
        setState(() {
          _blindAreaType = BlindAreaType.values[index];
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
              Expanded(child: CalculatorTextField(label: _loc.translate('blind_area_calc.label.house_length'), value: _houseLength, onChanged: (v) { setState(() { _houseLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 30)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('blind_area_calc.label.house_width'), value: _houseWidth, onChanged: (v) { setState(() { _houseWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('blind_area_calc.label.blind_width'), value: _blindAreaWidth, onChanged: (v) { setState(() { _blindAreaWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.6, maxValue: 2.0)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('blind_area_calc.label.thickness'), value: _thickness * 100, onChanged: (v) { setState(() { _thickness = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 5, maxValue: 20)),
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
            title: Text(_loc.translate('blind_area_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('blind_area_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needInsulation,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('blind_area_calc.option.drainage'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('blind_area_calc.option.drainage_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needDrainage,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needDrainage = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[];

    if (_blindAreaType == BlindAreaType.concrete && _result.concreteVolume > 0) {
      items.add(MaterialItem(
        name: _loc.translate('blind_area_calc.materials.concrete'),
        value: '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('blind_area_calc.materials.concrete_desc'),
        icon: Icons.view_in_ar,
      ));
    }

    if (_blindAreaType == BlindAreaType.paving) {
      items.add(MaterialItem(
        name: _loc.translate('blind_area_calc.materials.paving'),
        value: '${_result.totalArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('blind_area_calc.materials.paving_desc'),
        icon: Icons.grid_on,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('blind_area_calc.materials.sand'),
      value: '${_result.sandVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
      subtitle: _loc.translate('blind_area_calc.materials.sand_desc'),
      icon: Icons.grain,
    ));

    items.add(MaterialItem(
      name: _loc.translate('blind_area_calc.materials.gravel'),
      value: '${_result.gravelVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
      subtitle: _loc.translate('blind_area_calc.materials.gravel_desc'),
      icon: Icons.circle,
    ));

    items.add(MaterialItem(
      name: _loc.translate('blind_area_calc.materials.membrane'),
      value: '${_result.membranArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      subtitle: _loc.translate('blind_area_calc.materials.membrane_desc'),
      icon: Icons.layers,
    ));

    if (_needInsulation) {
      items.add(MaterialItem(
        name: _loc.translate('blind_area_calc.materials.insulation'),
        value: '${_result.totalArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('blind_area_calc.materials.insulation_desc'),
        icon: Icons.view_module,
      ));
    }

    if (_needDrainage) {
      items.add(MaterialItem(
        name: _loc.translate('blind_area_calc.materials.drainage'),
        value: '${_result.perimeter.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('blind_area_calc.materials.drainage_desc'),
        icon: Icons.water,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('blind_area_calc.section.materials'),
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
