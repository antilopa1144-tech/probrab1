import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Вспомогательный класс для работы с константами калькулятора штукатурки
class _PlasterConstants {
  final CalculatorConstants? _data;

  const _PlasterConstants([this._data]);

  double _getDouble(String constantKey, String valueKey, double defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  // Consumption rates
  double getConsumptionRate(String materialKey) {
    final defaults = {'gypsum': 8.5, 'cement': 17.0};
    return _getDouble('consumption_rates', materialKey, defaults[materialKey] ?? 8.5);
  }

  // Margins
  double get materialMargin => _getDouble('margins', 'material_margin', 1.1);
  double get meshMargin => _getDouble('margins', 'mesh_margin', 1.1);
  double get primerMargin => _getDouble('margins', 'primer_margin', 1.1);

  // Beacons
  double get areaPerBeacon => _getDouble('beacons', 'area_per_beacon', 2.5);

  // Primer
  double get primerConsumption => _getDouble('primer', 'consumption', 0.1);
}

enum PlasterMaterial { gypsum, cement }
enum PlasterInputMode { manual, room }

class _PlasterResult {
  final double area;
  final double totalWeight;
  final int bags;
  final int beacons;
  final int meshArea;
  final double primerLiters;
  final int beaconSize;

  const _PlasterResult({
    required this.area,
    required this.totalWeight,
    required this.bags,
    required this.beacons,
    required this.meshArea,
    required this.primerLiters,
    required this.beaconSize,
  });
}

class PlasterCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const PlasterCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<PlasterCalculatorScreen> createState() => _PlasterCalculatorScreenState();
}

class _PlasterCalculatorScreenState extends State<PlasterCalculatorScreen> {
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  double _openingsArea = 4.0;

  double _manualArea = 30;
  double _thickness = 15;
  int _bagWeight = 30;
  bool _useBeacons = true;
  bool _useMesh = false;
  bool _usePrimer = true;
  PlasterMaterial _materialType = PlasterMaterial.gypsum;
  PlasterInputMode _inputMode = PlasterInputMode.manual;
  late _PlasterResult _result;
  late AppLocalizations _loc;

  // Константы калькулятора (null = используются hardcoded defaults)
  late final _PlasterConstants _constants;

  @override
  void initState() {
    super.initState();
    _constants = const _PlasterConstants(null);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    if (initial['thickness'] != null) _thickness = initial['thickness']!.clamp(5.0, 100.0);
    if (initial['type']?.round() == 2) {
      _materialType = PlasterMaterial.cement;
      _bagWeight = 25;
    }
    if (initial['area'] != null && initial['area']! > 0) {
      _manualArea = initial['area']!.clamp(1.0, 1000.0);
      _inputMode = PlasterInputMode.manual;
    }
  }

  _PlasterResult _calculate() {
    double area = _manualArea;
    if (_inputMode == PlasterInputMode.room) {
      area = math.max(0, (2 * (_roomWidth + _roomLength) * _roomHeight) - _openingsArea);
    }

    final rate = _constants.getConsumptionRate(_materialType.name);
    final totalWeight = area * (_thickness / 10.0) * rate * _constants.materialMargin;
    return _PlasterResult(
      area: area,
      totalWeight: totalWeight,
      bags: (totalWeight / _bagWeight).ceil(),
      beacons: _useBeacons ? (area / _constants.areaPerBeacon).ceil() : 0,
      meshArea: _useMesh ? (area * _constants.meshMargin).ceil() : 0,
      primerLiters: double.parse((_usePrimer ? area * _constants.primerConsumption * _constants.primerMargin : 0).toStringAsFixed(1)),
      beaconSize: _thickness < 10 ? 6 : 10,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.walls;

    return CalculatorScaffold(
      title: _loc.translate('plaster_pro.brand'),
      accentColor: accentColor,

      // Header с ключевыми результатами вверху
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('plaster_pro.label.wall_area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('plaster_pro.summary.bags').toUpperCase(),
            value: '${_result.bags}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('plaster_pro.summary.weight').toUpperCase(),
            value: '${(_result.totalWeight / 1000).toStringAsFixed(1)} ${_loc.translate('common.tons')}',
            icon: Icons.scale,
          ),
        ],
      ),

      children: [
        _buildMaterialSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
        const SizedBox(height: 16),
        // Убираем большую карточку с результатами - теперь они в header
        // _buildSummaryCard(),
        // const SizedBox(height: 16),
        _buildSpecCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMaterialSelector() {
    const accentColor = CalculatorColors.walls;
    return TypeSelectorGroup(
      options: [
        TypeSelectorOption(
          icon: Icons.home_repair_service,
          title: _loc.translate('plaster_pro.material.gypsum'),
          subtitle: '30 ${_loc.translate('common.kg')}',
        ),
        TypeSelectorOption(
          icon: Icons.construction,
          title: _loc.translate('plaster_pro.material.cement'),
          subtitle: '25 ${_loc.translate('common.kg')}',
        ),
      ],
      selectedIndex: _materialType == PlasterMaterial.gypsum ? 0 : 1,
      onSelect: (index) {
        setState(() {
          _materialType = index == 0 ? PlasterMaterial.gypsum : PlasterMaterial.cement;
          _bagWeight = index == 0 ? 30 : 25;
          _result = _calculate();
        });
      },
      accentColor: accentColor,
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('plaster_pro.mode.manual'),
              _loc.translate('plaster_pro.mode.room'),
            ],
            selectedIndex: _inputMode == PlasterInputMode.manual ? 0 : 1,
            onSelect: (index) {
              setState(() {
                _inputMode = index == 0 ? PlasterInputMode.manual : PlasterInputMode.room;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == PlasterInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    const accentColor = CalculatorColors.walls;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _loc.translate('plaster_pro.label.wall_area'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            Text(
              '${_manualArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
              style: CalculatorDesignSystem.headlineMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Slider(
          value: _manualArea,
          min: 1,
          max: 500,
          activeColor: accentColor,
          onChanged: (v) { setState(() { _manualArea = v; _update(); }); },
        ),
      ],
    );
  }

  Widget _buildRoomInputs() {
    const accentColor = CalculatorColors.walls;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('plaster_pro.label.width'),
                value: _roomWidth,
                onChanged: (v) => setState(() { _roomWidth = v; _update(); }),
                suffix: _loc.translate('common.meters'),
                accentColor: accentColor,
                minValue: 0.1,
                maxValue: 100,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CalculatorTextField(
                label: _loc.translate('plaster_pro.label.length'),
                value: _roomLength,
                onChanged: (v) => setState(() { _roomLength = v; _update(); }),
                suffix: _loc.translate('common.meters'),
                accentColor: accentColor,
                minValue: 0.1,
                maxValue: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: _loc.translate('plaster_pro.label.height'),
          value: _roomHeight,
          onChanged: (v) => setState(() { _roomHeight = v; _update(); }),
          suffix: _loc.translate('common.meters'),
          accentColor: accentColor,
          minValue: 1.5,
          maxValue: 10,
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: _loc.translate('plaster_pro.label.openings_hint'),
          value: _openingsArea,
          onChanged: (v) => setState(() { _openingsArea = v; _update(); }),
          suffix: _loc.translate('common.sqm'),
          accentColor: accentColor,
          minValue: 0,
          maxValue: 100,
        ),
      ],
    );
  }

  Widget _buildThicknessCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('plaster_pro.thickness.title'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              Text(
                '${_thickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _thickness,
            min: 5,
            max: 100,
            activeColor: accentColor,
            onChanged: (v) { setState(() { _thickness = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _optIcon(Icons.architecture, _useBeacons, () => setState(() { _useBeacons = !_useBeacons; _update(); })),
              _optIcon(Icons.grid_on, _useMesh, () => setState(() { _useMesh = !_useMesh; _update(); })),
              _optIcon(Icons.water_drop, _usePrimer, () => setState(() { _usePrimer = !_usePrimer; _update(); })),
            ],
          )
        ],
      ),
    );
  }

  Widget _optIcon(IconData icon, bool active, VoidCallback tap) {
    const accentColor = CalculatorColors.walls;
    return IconButton(
      icon: Icon(icon, color: active ? accentColor : Colors.grey[300]),
      onPressed: tap,
    );
  }


  Widget _buildSpecCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('plaster_pro.summary.weight'),
        value: '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.scale,
      ),
    ];

    if (_useBeacons) {
      items.add(MaterialItem(
        name: _loc.translate('plaster_pro.options.beacons'),
        value: '${_result.beacons} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.beaconSize} ${_loc.translate('common.mm')}',
        icon: Icons.architecture,
      ));
    }

    if (_useMesh) {
      items.add(MaterialItem(
        name: _loc.translate('plaster_pro.spec.mesh_title'),
        value: '${_result.meshArea} ${_loc.translate('common.sqm')}',
        icon: Icons.grid_on,
      ));
    }

    if (_usePrimer) {
      items.add(MaterialItem(
        name: _loc.translate('plaster_pro.options.primer'),
        value: '${_result.primerLiters} ${_loc.translate('common.liters')}',
        icon: Icons.water_drop,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('plaster_pro.spec.title'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.walls;
    final tips = <String>[];

    switch (_materialType) {
      case PlasterMaterial.gypsum:
        tips.addAll([
          _loc.translate('plaster_calc.tip.gypsum_1'),
          _loc.translate('plaster_calc.tip.gypsum_2'),
        ]);
        break;
      case PlasterMaterial.cement:
        tips.addAll([
          _loc.translate('plaster_calc.tip.cement_1'),
          _loc.translate('plaster_calc.tip.cement_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('plaster_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
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
