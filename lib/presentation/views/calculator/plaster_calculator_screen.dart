import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';

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
  static const Map<PlasterMaterial, double> _consumptionRates = {
    PlasterMaterial.gypsum: 8.5,
    PlasterMaterial.cement: 17.0,
  };

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

  @override
  void initState() {
    super.initState();
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

    final rate = _consumptionRates[_materialType] ?? 8.5;
    final totalWeight = area * (_thickness / 10.0) * rate * 1.1;
    return _PlasterResult(
      area: area,
      totalWeight: totalWeight,
      bags: (totalWeight / _bagWeight).ceil(),
      beacons: _useBeacons ? (area / 2.5).ceil() : 0,
      meshArea: _useMesh ? (area * 1.1).ceil() : 0,
      primerLiters: double.parse((_usePrimer ? area * 0.1 * 1.1 : 0).toStringAsFixed(1)),
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
            value: '${_result.area.toStringAsFixed(0)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('plaster_pro.summary.bags').toUpperCase(),
            value: '${_result.bags}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('plaster_pro.summary.weight').toUpperCase(),
            value: '${(_result.totalWeight / 1000).toStringAsFixed(1)} т',
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
          subtitle: '30 кг',
        ),
        TypeSelectorOption(
          icon: Icons.construction,
          title: _loc.translate('plaster_pro.material.cement'),
          subtitle: '25 кг',
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
              '${_manualArea.toStringAsFixed(0)} м²',
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
                suffix: 'м',
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
                suffix: 'м',
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
          suffix: 'м',
          accentColor: accentColor,
          minValue: 1.5,
          maxValue: 10,
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: _loc.translate('plaster_pro.label.openings_hint'),
          value: _openingsArea,
          onChanged: (v) => setState(() { _openingsArea = v; _update(); }),
          suffix: 'м²',
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
                '${_thickness.toStringAsFixed(0)} мм',
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

    final results = <ResultRowItem>[
      ResultRowItem(
        label: _loc.translate('plaster_pro.summary.weight'),
        value: '${_result.totalWeight.toStringAsFixed(0)} кг',
        icon: Icons.scale,
      ),
    ];

    if (_useBeacons) {
      results.add(ResultRowItem(
        label: '${_loc.translate('plaster_pro.options.beacons')} ${_result.beaconSize}мм',
        value: '${_result.beacons} шт',
        icon: Icons.architecture,
      ));
    }

    if (_useMesh) {
      results.add(ResultRowItem(
        label: _loc.translate('plaster_pro.spec.mesh_title'),
        value: '${_result.meshArea} м²',
        icon: Icons.grid_on,
      ));
    }

    if (_usePrimer) {
      results.add(ResultRowItem(
        label: _loc.translate('plaster_pro.options.primer'),
        value: '${_result.primerLiters} л',
        icon: Icons.water_drop,
      ));
    }

    return ResultCardLight(
      title: _loc.translate('plaster_pro.spec.title'),
      titleIcon: Icons.receipt_long,
      results: results,
      accentColor: accentColor,
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
