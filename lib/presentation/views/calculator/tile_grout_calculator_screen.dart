import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_tile_grout.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип затирки
enum GroutType {
  cement('grout_calc.type.cement', 'grout_calc.type.cement_desc', Icons.construction),
  epoxy('grout_calc.type.epoxy', 'grout_calc.type.epoxy_desc', Icons.science),
  polyurethane('grout_calc.type.polyurethane', 'grout_calc.type.polyurethane_desc', Icons.water_drop);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const GroutType(this.nameKey, this.descKey, this.icon);
}

/// Предустановки размера плитки
enum TilePreset {
  t20x20(20, 20, '20×20 см'),
  t30x30(30, 30, '30×30 см'),
  t40x40(40, 40, '40×40 см'),
  t60x60(60, 60, '60×60 см'),
  t80x80(80, 80, '80×80 см'),
  t120x60(120, 60, '120×60 см'),
  custom(0, 0, 'Свой размер');

  final double width;
  final double height;
  final String label;
  const TilePreset(this.width, this.height, this.label);
}

class _GroutResult {
  final double area;
  final double consumptionPerM2;
  final double groutNeeded;
  final int bagsNeeded;
  final double bagWeight;
  final int spatulaCount;
  final int spongePackCount;

  const _GroutResult({
    required this.area,
    required this.consumptionPerM2,
    required this.groutNeeded,
    required this.bagsNeeded,
    required this.bagWeight,
    required this.spatulaCount,
    required this.spongePackCount,
  });

  factory _GroutResult.fromCalculatorResult(Map<String, double> values) {
    return _GroutResult(
      area: values['area'] ?? 0,
      consumptionPerM2: values['consumptionPerM2'] ?? 0,
      groutNeeded: values['groutNeeded'] ?? 0,
      bagsNeeded: (values['bagsNeeded'] ?? 0).toInt(),
      bagWeight: values['bagWeight'] ?? 2.0,
      spatulaCount: (values['spatulaCount'] ?? 1).toInt(),
      spongePackCount: (values['spongePackCount'] ?? 1).toInt(),
    );
  }
}

class TileGroutCalculatorScreen extends ConsumerStatefulWidget {
  const TileGroutCalculatorScreen({super.key});

  @override
  ConsumerState<TileGroutCalculatorScreen> createState() => _TileGroutCalculatorScreenState();
}

class _TileGroutCalculatorScreenState extends ConsumerState<TileGroutCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('calculator.floors_tile_grout.title');

  final _calculator = CalculateTileGrout();

  // --- Inputs ---
  double _area = 20.0;
  GroutType _groutType = GroutType.cement;
  TilePreset _tilePreset = TilePreset.t60x60;
  double _tileWidth = 60.0;
  double _tileHeight = 60.0;
  double _jointWidth = 3.0; // мм
  double _jointDepth = 2.0; // мм

  late _GroutResult _result;
  late AppLocalizations _loc;
  bool _isDark = false;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _GroutResult _calculate() {
    final tileW = _tilePreset == TilePreset.custom ? _tileWidth : _tilePreset.width;
    final tileH = _tilePreset == TilePreset.custom ? _tileHeight : _tilePreset.height;

    final inputs = <String, double>{
      'inputMode': 1,
      'area': _area,
      'tileSize': _tilePreset == TilePreset.custom
          ? 0
          : (_tilePreset == TilePreset.t120x60 ? 120 : _tilePreset.width),
      'tileWidth': tileW,
      'tileHeight': tileH,
      'jointWidth': _jointWidth,
      'jointDepth': _jointDepth,
      'groutType': _groutType.index.toDouble(),
    };

    final result = _calculator(inputs, []);
    return _GroutResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('calculator.floors_tile_grout.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln('${_loc.translate('grout_calc.export.area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('grout_calc.export.grout_type')}: ${_loc.translate(_groutType.nameKey)}');
    final tileW = _tilePreset == TilePreset.custom ? _tileWidth : _tilePreset.width;
    final tileH = _tilePreset == TilePreset.custom ? _tileHeight : _tilePreset.height;
    buffer.writeln('${_loc.translate('grout_calc.export.tile_size')}: ${tileW.toStringAsFixed(0)}×${tileH.toStringAsFixed(0)} ${_loc.translate('common.cm')}');
    buffer.writeln('${_loc.translate('grout_calc.export.joint')}: ${_jointWidth.toStringAsFixed(1)}×${_jointDepth.toStringAsFixed(1)} ${_loc.translate('common.mm')}');
    buffer.writeln();
    buffer.writeln(_loc.translate('grout_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('${_loc.translate('grout_calc.export.consumption')}: ${_result.consumptionPerM2.toStringAsFixed(2)} ${_loc.translate('common.kg_per_sqm')}');
    buffer.writeln('${_loc.translate('grout_calc.export.total')}: ${_result.groutNeeded.toStringAsFixed(1)} ${_loc.translate('common.kg')}');
    buffer.writeln('${_loc.translate('grout_calc.export.bags')}: ${_result.bagsNeeded} ${_loc.translate('common.pcs')} (${_result.bagWeight.toStringAsFixed(1)} ${_loc.translate('common.kg')})');
    buffer.writeln('${_loc.translate('grout_calc.export.spatula')}: ${_result.spatulaCount} ${_loc.translate('common.pcs')}');
    buffer.writeln('${_loc.translate('grout_calc.export.sponge')}: ${_result.spongePackCount} ${_loc.translate('common.pcs')}');
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('grout_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('calculator.floors_tile_grout.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('grout_calc.result.bags').toUpperCase(),
            value: '${_result.bagsNeeded} ${_loc.translate('common.pcs')}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('grout_calc.result.consumption').toUpperCase(),
            value: '${_result.consumptionPerM2.toStringAsFixed(2)} ${_loc.translate('common.kg_per_sqm')}',
            icon: Icons.speed,
          ),
          ResultItem(
            label: _loc.translate('grout_calc.result.total').toUpperCase(),
            value: '${_result.groutNeeded.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
            icon: Icons.scale,
          ),
        ],
      ),
      children: [
        _buildGroutTypeSelector(),
        const SizedBox(height: 16),
        _buildTileSizeCard(),
        const SizedBox(height: 16),
        _buildJointCard(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGroutTypeSelector() {
    return TypeSelectorGroup(
      options: GroutType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _groutType.index,
      onSelect: (index) {
        setState(() {
          _groutType = GroutType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildTileSizeCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('grout_calc.section.tile_size'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TilePreset.values.map((preset) {
              final isSelected = _tilePreset == preset;
              return ChoiceChip(
                label: Text(
                  preset == TilePreset.custom
                      ? _loc.translate('grout_calc.tile.custom')
                      : preset.label,
                ),
                selected: isSelected,
                selectedColor: _accentColor.withValues(alpha: 0.2),
                checkmarkColor: _accentColor,
                labelStyle: TextStyle(
                  color: isSelected ? _accentColor : CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
                onSelected: (_) {
                  setState(() {
                    _tilePreset = preset;
                    if (preset != TilePreset.custom) {
                      _tileWidth = preset.width;
                      _tileHeight = preset.height;
                    }
                    _update();
                  });
                },
              );
            }).toList(),
          ),
          if (_tilePreset == TilePreset.custom) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CalculatorTextField(
                    label: _loc.translate('grout_calc.label.tile_width'),
                    value: _tileWidth,
                    onChanged: (v) { setState(() { _tileWidth = v; _update(); }); },
                    suffix: _loc.translate('common.cm'),
                    accentColor: _accentColor,
                    minValue: 1,
                    maxValue: 200,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CalculatorTextField(
                    label: _loc.translate('grout_calc.label.tile_height'),
                    value: _tileHeight,
                    onChanged: (v) { setState(() { _tileHeight = v; _update(); }); },
                    suffix: _loc.translate('common.cm'),
                    accentColor: _accentColor,
                    minValue: 1,
                    maxValue: 200,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJointCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('grout_calc.section.joint'),
            style: CalculatorDesignSystem.titleSmall.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('grout_calc.label.joint_width'),
                  value: _jointWidth,
                  onChanged: (v) { setState(() { _jointWidth = v; _update(); }); },
                  suffix: _loc.translate('common.mm'),
                  accentColor: _accentColor,
                  minValue: 1,
                  maxValue: 12,
                  decimalPlaces: 1,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalculatorTextField(
                  label: _loc.translate('grout_calc.label.joint_depth'),
                  value: _jointDepth,
                  onChanged: (v) { setState(() { _jointDepth = v; _update(); }); },
                  suffix: _loc.translate('common.mm'),
                  accentColor: _accentColor,
                  minValue: 1,
                  maxValue: 5,
                  decimalPlaces: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          CalculatorTextField(
            label: _loc.translate('grout_calc.label.area'),
            value: _area,
            onChanged: (v) { setState(() { _area = v; _update(); }); },
            suffix: _loc.translate('common.sqm'),
            accentColor: _accentColor,
            minValue: 0.1,
            maxValue: 500,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final groutTypeName = _loc.translate(_groutType.nameKey);
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('grout_calc.materials.grout'),
        value: '${_result.bagsNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '$groutTypeName (${_result.bagWeight.toStringAsFixed(1)} ${_loc.translate('common.kg')} × ${_result.bagsNeeded} = ${_result.groutNeeded.toStringAsFixed(1)} ${_loc.translate('common.kg')})',
        icon: Icons.shopping_bag,
      ),
      MaterialItem(
        name: _loc.translate('grout_calc.materials.spatula'),
        value: '${_result.spatulaCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('grout_calc.materials.spatula_desc'),
        icon: Icons.handyman,
      ),
      MaterialItem(
        name: _loc.translate('grout_calc.materials.sponge'),
        value: '${_result.spongePackCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('grout_calc.materials.sponge_desc'),
        icon: Icons.cleaning_services,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('grout_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];
    switch (_groutType) {
      case GroutType.cement:
        tips.add(_loc.translate('hint.floors_tile_grout.cement_universal'));
        tips.add(_loc.translate('hint.floors_tile_grout.clean_excess'));
      case GroutType.epoxy:
        tips.add(_loc.translate('hint.floors_tile_grout.epoxy_wet'));
        tips.add(_loc.translate('hint.floors_tile_grout.temperature'));
      case GroutType.polyurethane:
        tips.add(_loc.translate('hint.floors_tile_grout.polyurethane_easy'));
        tips.add(_loc.translate('hint.floors_tile_grout.clean_excess'));
    }
    tips.add(_loc.translate('hint.floors_tile_grout.rubber_spatula'));
    if (_tilePreset == TilePreset.t80x80 || _tilePreset == TilePreset.t120x60) {
      tips.add(_loc.translate('hint.floors_tile_grout.large_tile_wide_joint'));
    }
    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(_isDark),
      ),
      child: child,
    );
  }
}
