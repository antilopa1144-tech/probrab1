import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип балкона
enum BalconyType {
  open('balcony_calc.type.open', 'balcony_calc.type.open_desc', Icons.balcony),
  glazed('balcony_calc.type.glazed', 'balcony_calc.type.glazed_desc', Icons.window),
  warm('balcony_calc.type.warm', 'balcony_calc.type.warm_desc', Icons.whatshot);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const BalconyType(this.nameKey, this.descKey, this.icon);
}

class _BalconyResult {
  final double floorArea;
  final double wallArea;
  final double ceilingArea;
  final double insulationArea;
  final double finishingArea;
  final double glazingLength;

  const _BalconyResult({
    required this.floorArea,
    required this.wallArea,
    required this.ceilingArea,
    required this.insulationArea,
    required this.finishingArea,
    required this.glazingLength,
  });
}

class BalconyCalculatorScreen extends StatefulWidget {
  const BalconyCalculatorScreen({super.key});

  @override
  State<BalconyCalculatorScreen> createState() => _BalconyCalculatorScreenState();
}

class _BalconyCalculatorScreenState extends State<BalconyCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('balcony_calc.title');
  double _length = 3.0;
  double _width = 1.2;
  double _height = 2.5;

  BalconyType _balconyType = BalconyType.glazed;
  bool _needInsulation = true;
  bool _needFloorFinishing = true;
  bool _needWallFinishing = true;

  late _BalconyResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _BalconyResult _calculate() {
    final floorArea = _length * _width;
    final ceilingArea = floorArea;

    // Стены: 3 стороны (без стены дома)
    final wallArea = 2 * _width * _height + _length * _height;

    // Утепление: пол + потолок + 3 стены
    double insulationArea = 0;
    if (_balconyType == BalconyType.warm && _needInsulation) {
      insulationArea = (floorArea + ceilingArea + wallArea) * 1.1;
    }

    // Отделка
    double finishingArea = 0;
    if (_needFloorFinishing) finishingArea += floorArea;
    if (_needWallFinishing) finishingArea += wallArea;
    if (_balconyType != BalconyType.open) finishingArea += ceilingArea;
    finishingArea *= 1.1; // +10% запас

    // Остекление
    double glazingLength = 0;
    if (_balconyType != BalconyType.open) {
      glazingLength = _length + 2 * _width; // П-образное
    }

    return _BalconyResult(
      floorArea: floorArea,
      wallArea: wallArea,
      ceilingArea: ceilingArea,
      insulationArea: insulationArea,
      finishingArea: finishingArea,
      glazingLength: glazingLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('balcony_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('balcony_calc.export.floor_area')
        .replaceFirst('{value}', _result.floorArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('balcony_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_balconyType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('balcony_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    if (_result.glazingLength > 0) {
      buffer.writeln(_loc.translate('balcony_calc.export.glazing')
          .replaceFirst('{value}', _result.glazingLength.toStringAsFixed(1)));
    }
    if (_result.insulationArea > 0) {
      buffer.writeln(_loc.translate('balcony_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('balcony_calc.export.finishing')
        .replaceFirst('{value}', _result.finishingArea.toStringAsFixed(1)));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('balcony_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('balcony_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('balcony_calc.result.floor_area').toUpperCase(),
            value: '${_result.floorArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('balcony_calc.result.wall_area').toUpperCase(),
            value: '${_result.wallArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
          ResultItem(
            label: _loc.translate('balcony_calc.result.finishing').toUpperCase(),
            value: '${_result.finishingArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.format_paint,
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
      options: BalconyType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _balconyType.index,
      onSelect: (index) {
        setState(() {
          _balconyType = BalconyType.values[index];
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
              Expanded(child: CalculatorTextField(label: _loc.translate('balcony_calc.label.length'), value: _length, onChanged: (v) { setState(() { _length = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 10)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('balcony_calc.label.width'), value: _width, onChanged: (v) { setState(() { _width = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.5, maxValue: 3)),
            ],
          ),
          const SizedBox(height: 12),
          CalculatorTextField(label: _loc.translate('balcony_calc.label.height'), value: _height, onChanged: (v) { setState(() { _height = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 2, maxValue: 3.5),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          if (_balconyType == BalconyType.warm)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_loc.translate('balcony_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
              subtitle: Text(_loc.translate('balcony_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
              value: _needInsulation,
              activeTrackColor: _accentColor,
              onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('balcony_calc.option.floor_finishing'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('balcony_calc.option.floor_finishing_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needFloorFinishing,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needFloorFinishing = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('balcony_calc.option.wall_finishing'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('balcony_calc.option.wall_finishing_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needWallFinishing,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needWallFinishing = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[];

    if (_result.glazingLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('balcony_calc.materials.glazing'),
        value: '${_result.glazingLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('balcony_calc.materials.glazing_desc'),
        icon: Icons.window,
      ));
    }

    if (_result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('balcony_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('balcony_calc.materials.insulation_desc'),
        icon: Icons.layers,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('balcony_calc.materials.finishing'),
      value: '${_result.finishingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      subtitle: _loc.translate('balcony_calc.materials.finishing_desc'),
      icon: Icons.format_paint,
    ));

    return MaterialsCardModern(
      title: _loc.translate('balcony_calc.section.materials'),
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
