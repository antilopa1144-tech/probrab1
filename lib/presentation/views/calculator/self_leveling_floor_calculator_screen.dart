import 'dart:math';
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Вспомогательный класс для работы с константами калькулятора наливного пола
class _SelfLevelingConstants {
  final CalculatorConstants? _data;

  const _SelfLevelingConstants([this._data]);

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

  int _getInt(String constantKey, String valueKey, int defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return defaultValue;
  }

  // Materials
  double get primerPerM2 => _getDouble('materials_consumption', 'primer_per_m2', 0.1);

  // Tools
  double get spikeRollerArea => _getDouble('tools', 'spike_roller_area', 50.0);
  int get spikeShoesCount => _getInt('tools', 'spike_shoes_count', 1);
}

enum InputMode { byArea, byDimensions }
enum BagWeight { kg20, kg25 }

enum MixtureBrand {
  ceresit175(1.5, 'Ceresit CN 175', [25]),
  ceresit173(1.6, 'Ceresit CN 173', [25]),
  knauf(1.6, 'Knauf Боден', [20, 25]),
  unis(1.5, 'Unis Горизонт', [20, 25]),
  volma(1.7, 'Волма Нивелир', [20]),
  osnovit(1.5, 'Основит Скорлайн', [20]),
  bergauf(1.6, 'Bergauf Easy Boden', [25]),
  starateli(1.6, 'Старатели', [20]),
  average(1.6, 'Средний расход', [20, 25]);

  final double consumption;
  final String name;
  final List<int> availableBagSizes;
  const MixtureBrand(this.consumption, this.name, this.availableBagSizes);

  bool hasBagSize(int size) => availableBagSizes.contains(size);
  int get defaultBagSize => availableBagSizes.first;
  bool get hasMultipleSizes => availableBagSizes.length > 1;
}

class _SelfLevelingFloorResult {
  final double area;
  final double thickness;
  final double consumption;
  final double totalWeight;
  final int bagsNeeded;
  final int bagWeight;
  final double primerLiters;
  final double damperTape;
  final int spikeRollers;
  final int spikeShoesCount;

  const _SelfLevelingFloorResult({
    required this.area,
    required this.thickness,
    required this.consumption,
    required this.totalWeight,
    required this.bagsNeeded,
    required this.bagWeight,
    required this.primerLiters,
    required this.damperTape,
    required this.spikeRollers,
    required this.spikeShoesCount,
  });
}

class SelfLevelingFloorCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const SelfLevelingFloorCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<SelfLevelingFloorCalculatorScreen> createState() =>
      _SelfLevelingFloorCalculatorScreenState();
}

class _SelfLevelingFloorCalculatorScreenState
    extends State<SelfLevelingFloorCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('self_leveling.export.subject');

  InputMode _inputMode = InputMode.byDimensions;
  double _area = 20.0;
  double _length = 5.0;
  double _width = 4.0;
  double _thickness = 10.0;
  MixtureBrand _mixtureBrand = MixtureBrand.average;
  BagWeight _bagWeight = BagWeight.kg25;
  late _SelfLevelingFloorResult _result;
  late AppLocalizations _loc;

  // Константы калькулятора (null = используются hardcoded defaults)
  late final _SelfLevelingConstants _constants;

  @override
  void initState() {
    super.initState();
    _constants = const _SelfLevelingConstants(null);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['length'] != null) _length = initial['length']!.clamp(0.1, 100.0);
    if (initial['width'] != null) _width = initial['width']!.clamp(0.1, 100.0);
    if (initial['thickness'] != null) {
      _thickness = initial['thickness']!.clamp(3.0, 100.0);
    }
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    return _length * _width;
  }

  _SelfLevelingFloorResult _calculate() {
    final calculatedArea = _getCalculatedArea();

    // Расчёт общего веса смеси
    // Формула: Площадь × Толщина (мм) × Расход (кг/м²/мм)
    final totalWeight = calculatedArea * _thickness * _mixtureBrand.consumption;

    // Вес мешка
    final bagWeightKg = _bagWeight == BagWeight.kg20 ? 20 : 25;

    // Количество мешков
    final bagsNeeded = (totalWeight / bagWeightKg).ceil();

    // Грунтовка из констант
    final primerLiters = calculatedArea * _constants.primerPerM2;

    // Демпферная лента (периметр комнаты)
    double damperTape;
    if (_inputMode == InputMode.byDimensions) {
      damperTape = (_length + _width) * 2;
    } else {
      // Приблизительный расчёт для квадратной площади
      final side = sqrt(calculatedArea);
      damperTape = side * 4;
    }

    // Игольчатый валик из констант
    final spikeRollers = (calculatedArea / _constants.spikeRollerArea).ceil();

    // Краскоступы из констант
    final spikeShoesCount = _constants.spikeShoesCount;

    return _SelfLevelingFloorResult(
      area: calculatedArea,
      thickness: _thickness,
      consumption: _mixtureBrand.consumption,
      totalWeight: totalWeight,
      bagsNeeded: bagsNeeded,
      bagWeight: bagWeightKg,
      primerLiters: primerLiters,
      damperTape: damperTape,
      spikeRollers: spikeRollers,
      spikeShoesCount: spikeShoesCount,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('self_leveling.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln(_loc.translate('self_leveling.export.area').replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('self_leveling.export.thickness').replaceFirst('{value}', _result.thickness.toStringAsFixed(0)));
    buffer.writeln();

    buffer.writeln(_loc.translate('self_leveling.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('self_leveling.export.mixture_line').replaceFirst('{bags}', _result.bagsNeeded.toString()).replaceFirst('{weight}', _result.bagWeight.toString())}');
    buffer.writeln('• ${_loc.translate('self_leveling.export.total_weight_line').replaceFirst('{value}', _result.totalWeight.toStringAsFixed(1))}');
    buffer.writeln('• ${_loc.translate('self_leveling.export.primer_line').replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1))}');
    buffer.writeln('• ${_loc.translate('self_leveling.export.damper_tape_line').replaceFirst('{value}', _result.damperTape.toStringAsFixed(1))}');
    buffer.writeln();

    buffer.writeln(_loc.translate('self_leveling.export.tools_title'));
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('self_leveling.export.spike_roller_line').replaceFirst('{value}', _result.spikeRollers.toString())}');
    buffer.writeln('• ${_loc.translate('self_leveling.export.spike_shoes_line').replaceFirst('{value}', _result.spikeShoesCount.toString())}');
    buffer.writeln();

    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('self_leveling.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('self_leveling.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('self_leveling.label.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('self_leveling.summary.bags').toUpperCase(),
            value: '${_result.bagsNeeded}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: _loc.translate('self_leveling.summary.weight').toUpperCase(),
            value: '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('self_leveling.materials.kg')}',
            icon: Icons.scale,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea
            ? _buildAreaCard()
            : _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
        const SizedBox(height: 16),
        _buildMixtureBrandSelector(),
        if (_mixtureBrand.hasMultipleSizes) ...[
          const SizedBox(height: 16),
          _buildBagWeightSelector(),
        ],
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildToolsCard(),
        const SizedBox(height: 24),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('self_leveling.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('self_leveling.input_mode.by_dimensions'),
              _loc.translate('self_leveling.input_mode.by_area'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = InputMode.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('self_leveling.label.area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
              ),
              Text(
                '${_area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _area,
            min: 1,
            max: 500,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _area = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('self_leveling.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('self_leveling.dimensions.length'),
            value: _length,
            min: 0.5,
            max: 50.0,
            onChanged: (v) {
              setState(() {
                _length = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('self_leveling.dimensions.width'),
            value: _width,
            min: 0.5,
            max: 50.0,
            onChanged: (v) {
              setState(() {
                _width = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _loc.translate('self_leveling.dimensions.calculated_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                  style: CalculatorDesignSystem.headlineMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
              style: CalculatorDesignSystem.titleMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildThicknessCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loc.translate('self_leveling.thickness.title'),
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: CalculatorColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loc.translate('self_leveling.thickness.subtitle'),
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                  ),
                ],
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
          const SizedBox(height: 8),
          Slider(
            value: _thickness,
            min: 3,
            max: 100,
            divisions: 97,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _thickness = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMixtureBrandSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('self_leveling.brand.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: MixtureBrand.values.map((brand) => brand.name).toList(),
            selectedIndex: _mixtureBrand.index,
            onSelect: (index) {
              setState(() {
                _mixtureBrand = MixtureBrand.values[index];
                // Автоматически устанавливаем доступный вес мешка
                final currentBagWeight = _bagWeight == BagWeight.kg20 ? 20 : 25;
                if (!_mixtureBrand.hasBagSize(currentBagWeight)) {
                  // Если текущий вес недоступен для нового бренда, устанавливаем дефолтный
                  _bagWeight = _mixtureBrand.defaultBagSize == 20
                      ? BagWeight.kg20
                      : BagWeight.kg25;
                }
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBagWeightSelector() {
    // Если у бренда только одна доступная фасовка, не показываем выбор
    if (!_mixtureBrand.hasMultipleSizes) {
      return const SizedBox.shrink();
    }

    const accentColor = CalculatorColors.interior;
    final availableSizes = _mixtureBrand.availableBagSizes;

    // Создаем опции только для доступных фасовок
    final options = <String>[];
    final indexMapping = <int, BagWeight>{};
    int currentMappedIndex = 0;

    for (var i = 0; i < BagWeight.values.length; i++) {
      final weight = BagWeight.values[i];
      final weightKg = weight == BagWeight.kg20 ? 20 : 25;

      if (availableSizes.contains(weightKg)) {
        options.add(_loc.translate('self_leveling.bag_weight.kg$weightKg'));
        indexMapping[currentMappedIndex] = weight;
        currentMappedIndex++;
      }
    }

    // Определяем текущий выбранный индекс среди доступных опций
    final currentWeightKg = _bagWeight == BagWeight.kg20 ? 20 : 25;
    final selectedIndex = availableSizes.indexOf(currentWeightKg);

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('self_leveling.bag_weight.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: options,
            selectedIndex: selectedIndex.clamp(0, options.length - 1),
            onSelect: (index) {
              setState(() {
                _bagWeight = indexMapping[index]!;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('self_leveling.materials.mixture'),
        value: '${_result.bagsNeeded} ${_loc.translate('self_leveling.materials.bags_unit')}',
        subtitle: '× ${_result.bagWeight} ${_loc.translate('self_leveling.materials.kg')}',
        icon: Icons.shopping_bag,
      ),
      MaterialItem(
        name: _loc.translate('self_leveling.materials.total_weight'),
        value: '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('self_leveling.materials.kg')}',
        icon: Icons.scale,
      ),
      MaterialItem(
        name: _loc.translate('self_leveling.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('self_leveling.materials.liters')}',
        icon: Icons.water_drop,
      ),
      MaterialItem(
        name: _loc.translate('self_leveling.materials.damper_tape'),
        value: '${_result.damperTape.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('self_leveling.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildToolsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('self_leveling.tools.spike_roller'),
        value: '${_result.spikeRollers} ${_loc.translate('self_leveling.tools.pieces')}',
        icon: Icons.roller_shades,
      ),
      MaterialItem(
        name: _loc.translate('self_leveling.tools.spike_shoes'),
        value: '${_result.spikeShoesCount} ${_loc.translate('self_leveling.tools.pair')}',
        icon: Icons.skateboarding,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('self_leveling.tools.title'),
      titleIcon: Icons.build_circle,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.interior;
    final tips = <String>[
      _loc.translate('hint.self_leveling.surface_preparation'),
      _loc.translate('hint.self_leveling.primer_required'),
      _loc.translate('hint.self_leveling.spike_roller'),
      _loc.translate('hint.self_leveling.mixing_temperature'),
      _loc.translate('hint.self_leveling.drying_time'),
    ];

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
