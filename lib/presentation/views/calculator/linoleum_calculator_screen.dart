import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип линолеума
enum LinoleumType {
  household('linoleum_calc.type.household', 'linoleum_calc.type.household_desc', Icons.home),
  semiCommercial('linoleum_calc.type.semi_commercial', 'linoleum_calc.type.semi_commercial_desc', Icons.business),
  commercial('linoleum_calc.type.commercial', 'linoleum_calc.type.commercial_desc', Icons.factory);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const LinoleumType(this.nameKey, this.descKey, this.icon);
}

enum LinoleumInputMode { manual, room }

class _LinoleumResult {
  final double area;
  final double areaWithWaste;
  final double rollsNeeded;
  final double rollWidth;
  final double tapeLength;
  final double plinthLength;
  final int plinthPieces;

  const _LinoleumResult({
    required this.area,
    required this.areaWithWaste,
    required this.rollsNeeded,
    required this.rollWidth,
    required this.tapeLength,
    required this.plinthLength,
    required this.plinthPieces,
  });
}

class LinoleumCalculatorScreen extends StatefulWidget {
  const LinoleumCalculatorScreen({super.key});

  @override
  State<LinoleumCalculatorScreen> createState() => _LinoleumCalculatorScreenState();
}

class _LinoleumCalculatorScreenState extends State<LinoleumCalculatorScreen>
    with ExportableMixin {
  // ExportableMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('linoleum_calc.title');

  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _rollWidth = 3.0; // м

  LinoleumType _linoleumType = LinoleumType.semiCommercial;
  LinoleumInputMode _inputMode = LinoleumInputMode.manual;
  bool _needPlinth = true;
  bool _needTape = true;

  late _LinoleumResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _LinoleumResult _calculate() {
    double area = _area;
    double roomWidth = _roomWidth;
    double roomLength = _roomLength;

    if (_inputMode == LinoleumInputMode.room) {
      area = roomWidth * roomLength;
    } else {
      final side = math.sqrt(area);
      roomWidth = side;
      roomLength = side;
    }

    final areaWithWaste = area * 1.1; // +10% запас
    final rollsNeeded = areaWithWaste / (_rollWidth * 25); // рулон 25 м.п.

    // Скотч двусторонний: периметр + швы
    double tapeLength = 0;
    if (_needTape) {
      tapeLength = 2 * (roomWidth + roomLength) + roomLength; // периметр + 1 шов
    }

    // Плинтус
    double plinthLength = 0;
    int plinthPieces = 0;
    if (_needPlinth) {
      plinthLength = 2 * (roomWidth + roomLength) - 0.9; // минус дверь
      plinthPieces = (plinthLength / 2.5).ceil();
    }

    return _LinoleumResult(
      area: area,
      areaWithWaste: areaWithWaste,
      rollsNeeded: rollsNeeded,
      rollWidth: _rollWidth,
      tapeLength: tapeLength,
      plinthLength: plinthLength,
      plinthPieces: plinthPieces,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('linoleum_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('linoleum_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('linoleum_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_linoleumType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('linoleum_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('linoleum_calc.export.linoleum')
        .replaceFirst('{value}', _result.areaWithWaste.toStringAsFixed(1)));
    if (_needTape) {
      buffer.writeln(_loc.translate('linoleum_calc.export.tape')
          .replaceFirst('{value}', _result.tapeLength.toStringAsFixed(1)));
    }
    if (_needPlinth) {
      buffer.writeln(_loc.translate('linoleum_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('linoleum_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('linoleum_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('linoleum_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('linoleum_calc.result.linoleum').toUpperCase(),
            value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.layers,
          ),
          ResultItem(
            label: _loc.translate('linoleum_calc.result.plinth').toUpperCase(),
            value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
            icon: Icons.straighten,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
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

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: LinoleumType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _linoleumType.index,
      onSelect: (index) {
        setState(() {
          _linoleumType = LinoleumType.values[index];
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
              _loc.translate('linoleum_calc.mode.manual'),
              _loc.translate('linoleum_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = LinoleumInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == LinoleumInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('linoleum_calc.label.area'),
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
            Expanded(child: CalculatorTextField(label: _loc.translate('linoleum_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('linoleum_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('linoleum_calc.label.floor_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
            label: _loc.translate('linoleum_calc.label.roll_width'),
            value: _rollWidth,
            min: 2.0,
            max: 5.0,
            divisions: 6,
            suffix: _loc.translate('common.meters'),
            accentColor: _accentColor,
            decimalPlaces: 1,
            onChanged: (v) { setState(() { _rollWidth = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('linoleum_calc.option.tape'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('linoleum_calc.option.tape_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needTape,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needTape = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('linoleum_calc.option.plinth'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('linoleum_calc.option.plinth_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
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
        name: _loc.translate('linoleum_calc.materials.linoleum'),
        value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate(_linoleumType.nameKey),
        icon: Icons.layers,
      ),
    ];

    if (_needTape && _result.tapeLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('linoleum_calc.materials.tape'),
        value: '${_result.tapeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('linoleum_calc.materials.tape_desc'),
        icon: Icons.content_cut,
      ));
    }

    if (_needPlinth && _result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('linoleum_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('linoleum_calc.section.materials'),
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
