import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_widgets.dart';

enum FloorType { cable, mat, infrared, water }
enum HeatingPurpose { main, comfort }
enum FloorCovering { tile, laminate, parquet, linoleum }

class _WarmFloorResult {
  final double workArea;
  final double totalPower;
  final double cableLength;
  final int matSets;
  final double filmArea;
  final int filmStrips;
  final double tubeLength;
  final int circuits;
  final int thermostats;
  final int sensors;
  final double montageTape;
  final double gofroTube;
  final int bitumInsulation;
  final int terminals;
  final double reflectiveSubstrate;
  final double insulationArea;
  final int beacons;
  final double demperTape;
  final int fittings;
  final int collectorOutputs;
  final double montageWire;

  const _WarmFloorResult({
    required this.workArea,
    required this.totalPower,
    required this.cableLength,
    required this.matSets,
    required this.filmArea,
    required this.filmStrips,
    required this.tubeLength,
    required this.circuits,
    required this.thermostats,
    required this.sensors,
    required this.montageTape,
    required this.gofroTube,
    required this.bitumInsulation,
    required this.terminals,
    required this.reflectiveSubstrate,
    required this.insulationArea,
    required this.beacons,
    required this.demperTape,
    required this.fittings,
    required this.collectorOutputs,
    required this.montageWire,
  });
}

class WarmFloorCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const WarmFloorCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<WarmFloorCalculatorScreen> createState() => _WarmFloorCalculatorScreenState();
}

class _WarmFloorCalculatorScreenState extends State<WarmFloorCalculatorScreen> {
  // Входные параметры
  double _totalArea = 20.0;
  double _excludedArea = 4.0;
  FloorType _floorType = FloorType.mat;
  HeatingPurpose _heatingPurpose = HeatingPurpose.comfort;
  FloorCovering _covering = FloorCovering.tile;
  double _cableStep = 12.0;
  double _matPower = 150.0;
  double _filmPower = 150.0;
  double _filmWidth = 50.0;
  double _tubeStep = 15.0;
  int _tubeDiameter = 16;
  double _distanceToCollector = 5.0;
  bool _hasInsulation = false;
  bool _useDemperTape = true;

  late _WarmFloorResult _result;
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
    if (initial['area'] != null) _totalArea = initial['area']!.clamp(1.0, 200.0);
    if (initial['type'] != null) {
      final typeValue = initial['type']!.round();
      if (typeValue >= 0 && typeValue < FloorType.values.length) {
        _floorType = FloorType.values[typeValue];
      }
    }
  }

  _WarmFloorResult _calculate() {
    final workArea = math.max(0.5, _totalArea - _excludedArea);

    // Определяем требуемую мощность
    double powerPerM2;
    switch (_heatingPurpose) {
      case HeatingPurpose.main:
        powerPerM2 = 150.0; // 150-180 Вт/м² для основного отопления
        break;
      case HeatingPurpose.comfort:
        powerPerM2 = _floorType == FloorType.mat ? _matPower :
                     _floorType == FloorType.infrared ? _filmPower : 120.0;
        break;
    }

    final totalPower = workArea * powerPerM2;

    // Количество терморегуляторов (1 на 15 м²)
    final thermostats = (workArea / 15).ceil().clamp(1, 10);
    final sensors = thermostats; // По одному датчику на регулятор

    double cableLength = 0.0;
    int matSets = 0;
    double filmArea = 0.0;
    int filmStrips = 0;
    double tubeLength = 0.0;
    int circuits = 0;
    double montageTape = 0.0;
    double gofroTube = thermostats * 2.0;
    int bitumInsulation = 0;
    int terminals = 0;
    double reflectiveSubstrate = 0.0;
    double insulationArea = _hasInsulation ? _totalArea : 0.0;
    int beacons = 0;
    double demperTape = 0.0;
    int fittings = 0;
    int collectorOutputs = 0;
    double montageWire = 0.0;

    switch (_floorType) {
      case FloorType.cable:
        // Электрический кабельный
        cableLength = (workArea / (_cableStep / 100)) * 1.1; // +10% на повороты
        montageTape = workArea * 2.0; // 2 п.м. на 1 м²
        beacons = (workArea / 2.5).ceil();
        demperTape = _useDemperTape ? (4 * math.sqrt(_totalArea)) * 1.05 : 0;
        insulationArea = _totalArea;
        break;

      case FloorType.mat:
        // Нагревательные маты - подбираем оптимальную комбинацию
        matSets = _calculateMatSets(workArea);
        demperTape = _useDemperTape ? (4 * math.sqrt(_totalArea)) * 1.05 : 0;
        break;

      case FloorType.infrared:
        // ИК-плёнка
        filmArea = workArea;
        filmStrips = (workArea / (_filmWidth / 100 * 8)).ceil(); // макс 8м на полосу
        bitumInsulation = filmStrips * 2; // 2 изоляции на каждую полосу
        terminals = filmStrips * 2; // 2 клеммы на полосу
        reflectiveSubstrate = _totalArea;
        montageWire = filmStrips * (math.sqrt(_totalArea) + 2); // от каждой полосы до регулятора
        break;

      case FloorType.water:
        // Водяной пол
        final maxCircuitLength = _tubeDiameter == 16 ? 80.0 : (_tubeDiameter == 17 ? 90.0 : 100.0);
        final areaPerCircuit = (_tubeStep / 100) * maxCircuitLength * 0.9;
        circuits = (workArea / areaPerCircuit).ceil().clamp(1, 12);

        tubeLength = (workArea / (_tubeStep / 100)) * 1.1; // основная длина
        tubeLength += _distanceToCollector * 2 * circuits; // подводка к коллектору

        fittings = circuits * 2; // 2 фитинга на контур
        collectorOutputs = circuits;
        demperTape = (4 * math.sqrt(_totalArea)) * 1.05;
        beacons = _hasInsulation ? 0 : (workArea * 2.5).ceil(); // скобы для крепления
        insulationArea = _totalArea;
        break;
    }

    return _WarmFloorResult(
      workArea: workArea,
      totalPower: totalPower,
      cableLength: cableLength,
      matSets: matSets,
      filmArea: filmArea,
      filmStrips: filmStrips,
      tubeLength: tubeLength,
      circuits: circuits,
      thermostats: thermostats,
      sensors: sensors,
      montageTape: montageTape,
      gofroTube: gofroTube,
      bitumInsulation: bitumInsulation,
      terminals: terminals,
      reflectiveSubstrate: reflectiveSubstrate,
      insulationArea: insulationArea,
      beacons: beacons,
      demperTape: demperTape,
      fittings: fittings,
      collectorOutputs: collectorOutputs,
      montageWire: montageWire,
    );
  }

  int _calculateMatSets(double area) {
    // Подбор оптимальной комбинации матов
    // Доступные размеры: 0.5, 1, 1.5, 2, 3, 4, 5, 6, 8, 10 м²
    final availableSizes = [10.0, 8.0, 6.0, 5.0, 4.0, 3.0, 2.0, 1.5, 1.0, 0.5];
    double remaining = area;
    int sets = 0;

    for (final size in availableSizes) {
      while (remaining >= size) {
        remaining -= size;
        sets++;
      }
    }

    // Если остаток больше 0.3 м², добавляем ещё один мат 0.5 м²
    if (remaining > 0.3) sets++;

    return sets;
  }

  void _update() => setState(() => _result = _calculate());

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.flooring;

    return CalculatorScaffold(
      title: _loc.translate('warm_floor.brand'),
      accentColor: accentColor,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('warm_floor.label.work_area').toUpperCase(),
            value: '${_result.workArea.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          if (_floorType != FloorType.water)
            ResultItem(
              label: _loc.translate('warm_floor.label.power').toUpperCase(),
              value: '${(_result.totalPower / 1000).toStringAsFixed(1)} кВт',
              icon: Icons.bolt,
            ),
          if (_floorType == FloorType.cable)
            ResultItem(
              label: _loc.translate('warm_floor.label.cable').toUpperCase(),
              value: '${_result.cableLength.toStringAsFixed(0)} м',
              icon: Icons.cable,
            ),
          if (_floorType == FloorType.mat)
            ResultItem(
              label: _loc.translate('warm_floor.label.mats').toUpperCase(),
              value: '${_result.matSets} компл.',
              icon: Icons.grid_on,
            ),
          if (_floorType == FloorType.infrared)
            ResultItem(
              label: _loc.translate('warm_floor.label.film').toUpperCase(),
              value: '${_result.filmArea.toStringAsFixed(1)} м²',
              icon: Icons.layers,
            ),
          if (_floorType == FloorType.water)
            ResultItem(
              label: _loc.translate('warm_floor.label.tube').toUpperCase(),
              value: '${_result.tubeLength.toStringAsFixed(0)} м',
              icon: Icons.water,
            ),
        ],
      ),
      children: [
        _buildFloorTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildParametersCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildFloorTypeSelector() {
    const accentColor = CalculatorColors.flooring;
    return TypeSelectorGroup(
      options: [
        TypeSelectorOption(
          icon: Icons.cable,
          title: _loc.translate('warm_floor.type.cable'),
          subtitle: _loc.translate('warm_floor.type.cable_desc'),
        ),
        TypeSelectorOption(
          icon: Icons.grid_on,
          title: _loc.translate('warm_floor.type.mat'),
          subtitle: _loc.translate('warm_floor.type.mat_desc'),
        ),
        TypeSelectorOption(
          icon: Icons.layers,
          title: _loc.translate('warm_floor.type.infrared'),
          subtitle: _loc.translate('warm_floor.type.infrared_desc'),
        ),
        TypeSelectorOption(
          icon: Icons.water,
          title: _loc.translate('warm_floor.type.water'),
          subtitle: _loc.translate('warm_floor.type.water_desc'),
        ),
      ],
      selectedIndex: _floorType.index,
      onSelect: (index) {
        setState(() {
          _floorType = FloorType.values[index];
          _update();
        });
      },
      accentColor: accentColor,
      direction: Axis.vertical,
      spacing: 8,
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.flooring;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('warm_floor.label.total_area'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_totalArea.toStringAsFixed(1)} м²',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _totalArea,
            min: 1,
            max: 200,
            activeColor: accentColor,
            onChanged: (v) { setState(() { _totalArea = v; _update(); }); },
          ),
          const SizedBox(height: 16),
          Text(
            _loc.translate('warm_floor.label.excluded_area'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_excludedArea.toStringAsFixed(1)} м²',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _loc.translate('warm_floor.label.furniture_hint'),
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.textTertiary,
                ),
              ),
            ],
          ),
          Slider(
            value: _excludedArea,
            min: 0,
            max: _totalArea * 0.5,
            activeColor: accentColor,
            onChanged: (v) { setState(() { _excludedArea = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildParametersCard() {
    const accentColor = CalculatorColors.flooring;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('warm_floor.label.parameters'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Назначение отопления
          _buildHeatingPurposeSelector(),
          const SizedBox(height: 16),

          // Тип покрытия
          _buildCoveringSelector(),
          const SizedBox(height: 16),

          // Параметры в зависимости от типа
          ..._buildTypeSpecificParameters(),

          // Дополнительные опции
          const SizedBox(height: 8),
          _buildOptionsRow(),
        ],
      ),
    );
  }

  Widget _buildHeatingPurposeSelector() {
    const accentColor = CalculatorColors.flooring;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate('warm_floor.label.purpose'),
          style: CalculatorDesignSystem.bodyMedium.copyWith(
            color: CalculatorColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.ac_unit,
                title: _loc.translate('warm_floor.purpose.main'),
                subtitle: '150-180 Вт/м²',
                isSelected: _heatingPurpose == HeatingPurpose.main,
                accentColor: accentColor,
                onTap: () => setState(() { _heatingPurpose = HeatingPurpose.main; _update(); }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TypeSelectorCard(
                icon: Icons.wb_sunny,
                title: _loc.translate('warm_floor.purpose.comfort'),
                subtitle: '100-130 Вт/м²',
                isSelected: _heatingPurpose == HeatingPurpose.comfort,
                accentColor: accentColor,
                onTap: () => setState(() { _heatingPurpose = HeatingPurpose.comfort; _update(); }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCoveringSelector() {
    const accentColor = CalculatorColors.flooring;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _loc.translate('warm_floor.label.covering'),
          style: CalculatorDesignSystem.bodyMedium.copyWith(
            color: CalculatorColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: FloorCovering.values.take(2).map((covering) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: covering == FloorCovering.tile ? 12 : 0),
              child: TypeSelectorCard(
                icon: covering == FloorCovering.tile ? Icons.grid_4x4 : Icons.view_module,
                title: _getCoveringName(covering),
                isSelected: _covering == covering,
                accentColor: accentColor,
                onTap: () => setState(() { _covering = covering; _update(); }),
                iconSize: 20,
              ),
            ),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: FloorCovering.values.skip(2).map((covering) => Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: covering == FloorCovering.parquet ? 12 : 0),
              child: TypeSelectorCard(
                icon: covering == FloorCovering.parquet ? Icons.window : Icons.layers,
                title: _getCoveringName(covering),
                isSelected: _covering == covering,
                accentColor: accentColor,
                onTap: () => setState(() { _covering = covering; _update(); }),
                iconSize: 20,
              ),
            ),
          )).toList(),
        ),
      ],
    );
  }

  String _getCoveringName(FloorCovering covering) {
    switch (covering) {
      case FloorCovering.tile:
        return _loc.translate('warm_floor.covering.tile');
      case FloorCovering.laminate:
        return _loc.translate('warm_floor.covering.laminate');
      case FloorCovering.parquet:
        return _loc.translate('warm_floor.covering.parquet');
      case FloorCovering.linoleum:
        return _loc.translate('warm_floor.covering.linoleum');
    }
  }

  List<Widget> _buildTypeSpecificParameters() {
    const accentColor = CalculatorColors.flooring;

    switch (_floorType) {
      case FloorType.cable:
        return [
          CalculatorTextField(
            label: _loc.translate('warm_floor.label.cable_step'),
            value: _cableStep,
            onChanged: (v) => setState(() { _cableStep = v; _update(); }),
            suffix: 'см',
            accentColor: accentColor,
            minValue: 8,
            maxValue: 20,
          ),
        ];

      case FloorType.mat:
        return [
          Row(
            children: [
              Text(
                _loc.translate('warm_floor.label.mat_power'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${_matPower.toStringAsFixed(0)} Вт/м²',
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _matPower,
            min: 100,
            max: 200,
            divisions: 10,
            activeColor: accentColor,
            onChanged: (v) { setState(() { _matPower = v; _update(); }); },
          ),
        ];

      case FloorType.infrared:
        return [
          Row(
            children: [
              Text(
                _loc.translate('warm_floor.label.film_power'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '${_filmPower.toStringAsFixed(0)} Вт/м²',
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _filmPower,
            min: 130,
            max: 220,
            divisions: 9,
            activeColor: accentColor,
            onChanged: (v) { setState(() { _filmPower = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          CalculatorTextField(
            label: _loc.translate('warm_floor.label.film_width'),
            value: _filmWidth,
            onChanged: (v) => setState(() { _filmWidth = v; _update(); }),
            suffix: 'см',
            accentColor: accentColor,
            minValue: 50,
            maxValue: 100,
          ),
        ];

      case FloorType.water:
        return [
          CalculatorTextField(
            label: _loc.translate('warm_floor.label.tube_step'),
            value: _tubeStep,
            onChanged: (v) => setState(() { _tubeStep = v; _update(); }),
            suffix: 'см',
            accentColor: accentColor,
            minValue: 10,
            maxValue: 30,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                _loc.translate('warm_floor.label.tube_diameter'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$_tubeDiameter мм',
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [16, 17, 20].map((diameter) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: diameter != 20 ? 8 : 0),
                child: TypeSelectorCard(
                  icon: Icons.settings_ethernet,
                  title: '$diameter мм',
                  isSelected: _tubeDiameter == diameter,
                  accentColor: accentColor,
                  onTap: () => setState(() { _tubeDiameter = diameter; _update(); }),
                  iconSize: 16,
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('warm_floor.label.distance_to_collector'),
            value: _distanceToCollector,
            onChanged: (v) => setState(() { _distanceToCollector = v; _update(); }),
            suffix: 'м',
            accentColor: accentColor,
            minValue: 1,
            maxValue: 30,
          ),
        ];
    }
  }

  Widget _buildOptionsRow() {
    const accentColor = CalculatorColors.flooring;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _optIcon(
          Icons.ac_unit,
          _hasInsulation,
          () => setState(() { _hasInsulation = !_hasInsulation; _update(); }),
          _loc.translate('warm_floor.option.insulation'),
        ),
        if (_floorType != FloorType.infrared)
          _optIcon(
            Icons.margin,
            _useDemperTape,
            () => setState(() { _useDemperTape = !_useDemperTape; _update(); }),
            _loc.translate('warm_floor.option.demper_tape'),
          ),
      ],
    );
  }

  Widget _optIcon(IconData icon, bool active, VoidCallback tap, String label) {
    const accentColor = CalculatorColors.flooring;
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, color: active ? accentColor : Colors.grey[300]),
          onPressed: tap,
        ),
        Text(
          label,
          style: CalculatorDesignSystem.bodySmall.copyWith(
            color: active ? accentColor : CalculatorColors.textTertiary,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.flooring;
    final results = <ResultRowItem>[];

    switch (_floorType) {
      case FloorType.cable:
        results.addAll([
          ResultRowItem(
            label: _loc.translate('warm_floor.material.heating_cable'),
            value: '${_result.cableLength.toStringAsFixed(0)} м',
            icon: Icons.cable,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.thermostat'),
            value: '${_result.thermostats} шт',
            icon: Icons.thermostat,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.sensor'),
            value: '${_result.sensors} шт',
            icon: Icons.sensors,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.montage_tape'),
            value: '${_result.montageTape.toStringAsFixed(0)} м',
            icon: Icons.handyman,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.gofro_tube'),
            value: '${_result.gofroTube.toStringAsFixed(1)} м',
            icon: Icons.settings_input_component,
          ),
        ]);
        if (_hasInsulation) {
          results.add(ResultRowItem(
            label: _loc.translate('warm_floor.material.insulation'),
            value: '${_result.insulationArea.toStringAsFixed(1)} м²',
            icon: Icons.layers,
          ));
        }
        if (_useDemperTape) {
          results.add(ResultRowItem(
            label: _loc.translate('warm_floor.material.demper_tape'),
            value: '${_result.demperTape.toStringAsFixed(1)} м',
            icon: Icons.margin,
          ));
        }
        break;

      case FloorType.mat:
        results.addAll([
          ResultRowItem(
            label: _loc.translate('warm_floor.material.heating_mat'),
            value: '${_result.matSets} компл',
            icon: Icons.grid_on,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.thermostat'),
            value: '${_result.thermostats} шт',
            icon: Icons.thermostat,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.sensor'),
            value: '${_result.sensors} шт',
            icon: Icons.sensors,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.gofro_tube'),
            value: '${_result.gofroTube.toStringAsFixed(1)} м',
            icon: Icons.settings_input_component,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.tile_glue'),
            value: '${(_result.workArea * 4.5).toStringAsFixed(0)} кг',
            icon: Icons.construction,
          ),
        ]);
        if (_useDemperTape) {
          results.add(ResultRowItem(
            label: _loc.translate('warm_floor.material.demper_tape'),
            value: '${_result.demperTape.toStringAsFixed(1)} м',
            icon: Icons.margin,
          ));
        }
        break;

      case FloorType.infrared:
        results.addAll([
          ResultRowItem(
            label: _loc.translate('warm_floor.material.ir_film'),
            value: '${_result.filmArea.toStringAsFixed(1)} м²',
            icon: Icons.layers,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.thermostat'),
            value: '${_result.thermostats} шт',
            icon: Icons.thermostat,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.sensor'),
            value: '${_result.sensors} шт',
            icon: Icons.sensors,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.reflective_substrate'),
            value: '${_result.reflectiveSubstrate.toStringAsFixed(1)} м²',
            icon: Icons.brightness_7,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.bitum_insulation'),
            value: '${_result.bitumInsulation} шт',
            icon: Icons.security,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.terminals'),
            value: '${_result.terminals} шт',
            icon: Icons.electrical_services,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.montage_wire'),
            value: '${_result.montageWire.toStringAsFixed(0)} м',
            icon: Icons.cable,
          ),
        ]);
        break;

      case FloorType.water:
        results.addAll([
          ResultRowItem(
            label: _loc.translate('warm_floor.material.tube') + ' ($_tubeDiameter мм)',
            value: '${_result.tubeLength.toStringAsFixed(0)} м',
            icon: Icons.water,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.collector'),
            value: '${_result.collectorOutputs} выходов',
            icon: Icons.device_hub,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.fittings'),
            value: '${_result.fittings} шт',
            icon: Icons.handyman,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.insulation'),
            value: '${_result.insulationArea.toStringAsFixed(1)} м²',
            icon: Icons.layers,
          ),
          ResultRowItem(
            label: _loc.translate('warm_floor.material.demper_tape'),
            value: '${_result.demperTape.toStringAsFixed(1)} м',
            icon: Icons.margin,
          ),
        ]);
        if (_hasInsulation) {
          results.add(ResultRowItem(
            label: _loc.translate('warm_floor.material.fixing_clips'),
            value: '${(_result.tubeLength * 2.5).toStringAsFixed(0)} шт',
            icon: Icons.push_pin,
          ));
        }
        break;
    }

    return ResultCardLight(
      title: _loc.translate('warm_floor.materials_title'),
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
