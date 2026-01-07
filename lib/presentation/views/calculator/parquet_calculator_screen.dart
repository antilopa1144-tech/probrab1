import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип паркета
enum ParquetType {
  board('parquet_calc.type.board', 'parquet_calc.type.board_desc', Icons.view_stream),
  engineered('parquet_calc.type.engineered', 'parquet_calc.type.engineered_desc', Icons.layers),
  massive('parquet_calc.type.massive', 'parquet_calc.type.massive_desc', Icons.park);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const ParquetType(this.nameKey, this.descKey, this.icon);
}

/// Способ укладки
enum ParquetPattern {
  straight('parquet_calc.pattern.straight', 5),
  diagonal('parquet_calc.pattern.diagonal', 15),
  herringbone('parquet_calc.pattern.herringbone', 20);

  final String nameKey;
  final int wastePercent;
  const ParquetPattern(this.nameKey, this.wastePercent);
}

enum ParquetInputMode { manual, room }

class _ParquetResult {
  final double area;
  final double areaWithWaste;
  final int packsNeeded;
  final double packArea;
  final double underlayArea;
  final double plinthLength;
  final int plinthPieces;
  final double glueLiters;

  const _ParquetResult({
    required this.area,
    required this.areaWithWaste,
    required this.packsNeeded,
    required this.packArea,
    required this.underlayArea,
    required this.plinthLength,
    required this.plinthPieces,
    required this.glueLiters,
  });
}

class ParquetCalculatorScreen extends StatefulWidget {
  const ParquetCalculatorScreen({super.key});

  @override
  State<ParquetCalculatorScreen> createState() => _ParquetCalculatorScreenState();
}

class _ParquetCalculatorScreenState extends State<ParquetCalculatorScreen>
    with ExportableMixin {
  // ExportableMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('parquet_calc.title');

  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _packArea = 2.0;

  ParquetType _parquetType = ParquetType.engineered;
  ParquetPattern _pattern = ParquetPattern.straight;
  ParquetInputMode _inputMode = ParquetInputMode.manual;
  bool _needUnderlay = true;
  bool _needPlinth = true;
  bool _needGlue = false;

  late _ParquetResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _ParquetResult _calculate() {
    double area = _area;
    double roomWidth = _roomWidth;
    double roomLength = _roomLength;

    if (_inputMode == ParquetInputMode.room) {
      area = roomWidth * roomLength;
    } else {
      final side = math.sqrt(area);
      roomWidth = side;
      roomLength = side;
    }

    final wasteMultiplier = 1 + (_pattern.wastePercent / 100);
    final areaWithWaste = area * wasteMultiplier;
    final packsNeeded = (areaWithWaste / _packArea).ceil();

    // Подложка +10%
    final underlayArea = _needUnderlay ? area * 1.1 : 0.0;

    // Плинтус
    double plinthLength = 0;
    int plinthPieces = 0;
    if (_needPlinth) {
      plinthLength = 2 * (roomWidth + roomLength) - 0.9;
      plinthPieces = (plinthLength / 2.5).ceil();
    }

    // Клей (0.3-0.5 кг/м² → ~0.25 л/м²)
    final glueLiters = _needGlue ? area * 0.25 : 0.0;

    return _ParquetResult(
      area: area,
      areaWithWaste: areaWithWaste,
      packsNeeded: packsNeeded,
      packArea: _packArea,
      underlayArea: underlayArea,
      plinthLength: plinthLength,
      plinthPieces: plinthPieces,
      glueLiters: glueLiters,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('parquet_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('parquet_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('parquet_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_parquetType.nameKey)));
    buffer.writeln(_loc.translate('parquet_calc.export.pattern')
        .replaceFirst('{value}', _loc.translate(_pattern.nameKey)));
    buffer.writeln(_loc.translate('parquet_calc.export.waste')
        .replaceFirst('{value}', _pattern.wastePercent.toString()));
    buffer.writeln();
    buffer.writeln(_loc.translate('parquet_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('parquet_calc.export.packs')
        .replaceFirst('{value}', _result.packsNeeded.toString())
        .replaceFirst('{area}', _result.packArea.toStringAsFixed(1)));
    if (_needUnderlay) {
      buffer.writeln(_loc.translate('parquet_calc.export.underlay')
          .replaceFirst('{value}', _result.underlayArea.toStringAsFixed(1)));
    }
    if (_needPlinth) {
      buffer.writeln(_loc.translate('parquet_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    if (_needGlue) {
      buffer.writeln(_loc.translate('parquet_calc.export.glue')
          .replaceFirst('{value}', _result.glueLiters.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('parquet_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('parquet_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('parquet_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('parquet_calc.result.packs').toUpperCase(),
            value: '${_result.packsNeeded}',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: _loc.translate('parquet_calc.result.total_area').toUpperCase(),
            value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildPatternSelector(),
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
      options: ParquetType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _parquetType.index,
      onSelect: (index) {
        setState(() {
          _parquetType = ParquetType.values[index];
          _needGlue = _parquetType == ParquetType.massive;
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildPatternSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('parquet_calc.section.pattern'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: ParquetPattern.values.map((p) => _loc.translate(p.nameKey)).toList(),
            selectedIndex: _pattern.index,
            onSelect: (index) {
              setState(() {
                _pattern = ParquetPattern.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('parquet_calc.pattern.waste_info').replaceFirst('{value}', _pattern.wastePercent.toString()),
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
              _loc.translate('parquet_calc.mode.manual'),
              _loc.translate('parquet_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = ParquetInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == ParquetInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('parquet_calc.label.area'),
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
            Expanded(child: CalculatorTextField(label: _loc.translate('parquet_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('parquet_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('parquet_calc.label.floor_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
            label: _loc.translate('parquet_calc.label.pack_area'),
            value: _packArea,
            min: 1.0,
            max: 4.0,
            divisions: 12,
            suffix: _loc.translate('common.sqm'),
            accentColor: _accentColor,
            decimalPlaces: 1,
            onChanged: (v) { setState(() { _packArea = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('parquet_calc.option.underlay'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('parquet_calc.option.underlay_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needUnderlay,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needUnderlay = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('parquet_calc.option.plinth'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('parquet_calc.option.plinth_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needPlinth,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needPlinth = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('parquet_calc.option.glue'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('parquet_calc.option.glue_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needGlue,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needGlue = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('parquet_calc.materials.parquet'),
        value: '${_result.packsNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ),
    ];

    if (_needUnderlay && _result.underlayArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('parquet_calc.materials.underlay'),
        value: '${_result.underlayArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.view_agenda,
      ));
    }

    if (_needPlinth && _result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('parquet_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ));
    }

    if (_needGlue && _result.glueLiters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('parquet_calc.materials.glue'),
        value: '${_result.glueLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        icon: Icons.water_drop,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('parquet_calc.section.materials'),
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
