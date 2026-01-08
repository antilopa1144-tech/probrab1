import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Способ укладки ламината
enum LaminatePattern {
  straight('laminate_calc.pattern.straight', 'laminate_calc.pattern.straight_desc', Icons.view_stream),
  diagonal('laminate_calc.pattern.diagonal', 'laminate_calc.pattern.diagonal_desc', Icons.rotate_right);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const LaminatePattern(this.nameKey, this.descKey, this.icon);
}

/// Класс ламината
enum LaminateClass {
  class31('laminate_calc.class.31', 'laminate_calc.class.31_desc'),
  class32('laminate_calc.class.32', 'laminate_calc.class.32_desc'),
  class33('laminate_calc.class.33', 'laminate_calc.class.33_desc');

  final String nameKey;
  final String descKey;
  const LaminateClass(this.nameKey, this.descKey);
}

enum LaminateInputMode { manual, room }

class _LaminateResult {
  final double area;
  final double areaWithWaste;
  final int packsNeeded;
  final double packArea;
  final double underlayArea;
  final int underlayRolls;
  final double plinthLength;
  final int plinthPieces;

  const _LaminateResult({
    required this.area,
    required this.areaWithWaste,
    required this.packsNeeded,
    required this.packArea,
    required this.underlayArea,
    required this.underlayRolls,
    required this.plinthLength,
    required this.plinthPieces,
  });
}

class LaminateCalculatorScreen extends StatefulWidget {
  const LaminateCalculatorScreen({super.key});

  @override
  State<LaminateCalculatorScreen> createState() => _LaminateCalculatorScreenState();
}

class _LaminateCalculatorScreenState extends State<LaminateCalculatorScreen>
    with ExportableMixin {
  // ExportableMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('laminate_calc.title');

  // Состояние
  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _packArea = 2.4; // м² в упаковке

  LaminatePattern _pattern = LaminatePattern.straight;
  LaminateClass _laminateClass = LaminateClass.class32;
  LaminateInputMode _inputMode = LaminateInputMode.manual;
  bool _needUnderlay = true;
  bool _needPlinth = true;

  late _LaminateResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Процент отходов в зависимости от способа укладки
  double _getWastePercent() {
    return switch (_pattern) {
      LaminatePattern.straight => 0.05, // 5%
      LaminatePattern.diagonal => 0.15,  // 15%
    };
  }

  _LaminateResult _calculate() {
    double area = _area;
    if (_inputMode == LaminateInputMode.room) {
      area = _roomWidth * _roomLength;
    }

    final wastePercent = _getWastePercent();
    final areaWithWaste = area * (1 + wastePercent);
    final packsNeeded = (areaWithWaste / _packArea).ceil();

    // Подложка: +10% запас
    final underlayArea = area * 1.1;
    final underlayRolls = (underlayArea / 10).ceil(); // рулон = 10 м²

    // Плинтус: периметр - дверной проём (~1м)
    double plinthLength = 0;
    int plinthPieces = 0;
    if (_needPlinth) {
      if (_inputMode == LaminateInputMode.room) {
        plinthLength = 2 * (_roomWidth + _roomLength) - 1.0;
      } else {
        // Приближённый периметр из площади (квадратная комната)
        final side = area > 0 ? math.sqrt(area) : 0.0;
        plinthLength = 4 * side - 1.0;
      }
      plinthPieces = (plinthLength / 2.5).ceil(); // плинтус = 2.5 м
    }

    return _LaminateResult(
      area: area,
      areaWithWaste: areaWithWaste,
      packsNeeded: packsNeeded,
      packArea: _packArea,
      underlayArea: underlayArea,
      underlayRolls: _needUnderlay ? underlayRolls : 0,
      plinthLength: plinthLength,
      plinthPieces: plinthPieces,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('laminate_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('laminate_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('laminate_calc.export.pattern')
        .replaceFirst('{value}', _loc.translate(_pattern.nameKey)));
    buffer.writeln(_loc.translate('laminate_calc.export.waste')
        .replaceFirst('{value}', (_getWastePercent() * 100).toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln(_loc.translate('laminate_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('laminate_calc.export.packs')
        .replaceFirst('{value}', _result.packsNeeded.toString())
        .replaceFirst('{area}', _result.packArea.toStringAsFixed(1)));
    if (_needUnderlay) {
      buffer.writeln(_loc.translate('laminate_calc.export.underlay')
          .replaceFirst('{value}', _result.underlayRolls.toString()));
    }
    if (_needPlinth) {
      buffer.writeln(_loc.translate('laminate_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('laminate_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('laminate_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('laminate_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('laminate_calc.result.packs').toUpperCase(),
            value: '${_result.packsNeeded}',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: _loc.translate('laminate_calc.result.total_area').toUpperCase(),
            value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
        ],
      ),
      children: [
        _buildPatternSelector(),
        const SizedBox(height: 16),
        _buildClassSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildPatternSelector() {
    return TypeSelectorGroup(
      options: LaminatePattern.values.map((p) => TypeSelectorOption(
        icon: p.icon,
        title: _loc.translate(p.nameKey),
        subtitle: _loc.translate(p.descKey),
      )).toList(),
      selectedIndex: _pattern.index,
      onSelect: (index) {
        setState(() {
          _pattern = LaminatePattern.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildClassSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('laminate_calc.section.class'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: LaminateClass.values.map((c) => _loc.translate(c.nameKey)).toList(),
            selectedIndex: _laminateClass.index,
            onSelect: (index) {
              setState(() {
                _laminateClass = LaminateClass.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_laminateClass.descKey),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('laminate_calc.mode.manual'),
              _loc.translate('laminate_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = LaminateInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == LaminateInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('laminate_calc.label.area'),
      value: _area,
      min: 5,
      max: 200,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) {
        setState(() {
          _area = v;
          _update();
        });
      },
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('laminate_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('laminate_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('laminate_calc.label.floor_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('laminate_calc.label.pack_area'),
            value: _packArea,
            min: 1.5,
            max: 4.0,
            divisions: 10,
            suffix: _loc.translate('common.sqm'),
            accentColor: _accentColor,
            decimalPlaces: 1,
            onChanged: (v) {
              setState(() {
                _packArea = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('laminate_calc.option.underlay'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('laminate_calc.option.underlay_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needUnderlay,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needUnderlay = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('laminate_calc.option.plinth'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('laminate_calc.option.plinth_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needPlinth,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needPlinth = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('laminate_calc.materials.laminate'),
        value: '${_result.packsNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ),
    ];

    if (_needUnderlay && _result.underlayRolls > 0) {
      items.add(MaterialItem(
        name: _loc.translate('laminate_calc.materials.underlay'),
        value: '${_result.underlayRolls} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.underlayArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.view_agenda,
      ));
    }

    if (_needPlinth && _result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('laminate_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('laminate_calc.section.materials'),
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
