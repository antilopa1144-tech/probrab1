import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Вспомогательный класс для работы с константами калькулятора вагонки
class _WoodLiningConstants {
  final CalculatorConstants? _data;

  const _WoodLiningConstants([this._data]);

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

  // Lining dimensions
  double getLiningWidth(String typeKey) {
    final defaults = {'standard': 88.0, 'euro': 96.0, 'blockHouse': 140.0, 'imitationBar': 140.0};
    return _getDouble('lining_types', '${typeKey}_width', defaults[typeKey] ?? 88.0);
  }

  double getLiningLength(String typeKey) {
    final defaults = {'standard': 3.0, 'euro': 2.5, 'blockHouse': 2.0, 'imitationBar': 3.0};
    return _getDouble('lining_types', '${typeKey}_length', defaults[typeKey] ?? 3.0);
  }

  // Fastening
  int getFasteningPerM2(String typeKey) {
    final defaults = {'klyaymery': 20, 'nails': 25, 'screws': 20};
    return _getInt('fastening', typeKey, defaults[typeKey] ?? 20);
  }

  // Finish consumption
  double getFinishConsumption(String typeKey) {
    final defaults = {'varnish': 0.15, 'oil': 0.12, 'wax': 0.10, 'stain': 0.10};
    return _getDouble('finish_consumption', typeKey, defaults[typeKey] ?? 0.15);
  }

  // Batten
  double get battenStep => _getDouble('batten', 'step', 0.5);
  double get battenMarginVertical => _getDouble('batten', 'margin_vertical', 1.1);
  double get battenMarginHorizontal => _getDouble('batten', 'margin_horizontal', 1.1);
  double get battenMarginDiagonal => _getDouble('batten', 'margin_diagonal', 1.3);

  // Antiseptic
  double get antisepticConsumption => _getDouble('antiseptic', 'consumption', 0.2);
  double get antisepticMargin => _getDouble('antiseptic', 'margin', 1.1);

  // Finish margin
  double get finishMargin => _getDouble('finish_margin', 'standard', 1.1);

  // Insulation
  double get insulationMargin => _getDouble('insulation', 'margin', 1.1);

  // Vapor barrier
  double get vaporBarrierOverlapMargin => _getDouble('vapor_barrier', 'overlap_margin', 1.2);
  double get vaporBarrierWeightPerM2 => _getDouble('vapor_barrier', 'weight_per_m2', 0.15);
}

/// Типы вагонки
enum LiningType {
  standard('woodlining.lining_type.standard', 'woodlining.lining_type.standard_desc', Icons.view_agenda),
  euro('woodlining.lining_type.euro', 'woodlining.lining_type.euro_desc', Icons.view_stream),
  blockHouse('woodlining.lining_type.block_house', 'woodlining.lining_type.block_house_desc', Icons.circle_outlined),
  imitationBar('woodlining.lining_type.imitation_bar', 'woodlining.lining_type.imitation_bar_desc', Icons.crop_square);

  final String nameKey;
  final String descKey;
  final IconData icon;

  const LiningType(this.nameKey, this.descKey, this.icon);

  /// Ключ для получения значений из констант
  String get key => name;
}

/// Породы дерева
enum WoodSpecies {
  pine('woodlining.wood_species.pine', 'woodlining.wood_species.pine_desc'),
  spruce('woodlining.wood_species.spruce', 'woodlining.wood_species.spruce_desc'),
  larch('woodlining.wood_species.larch', 'woodlining.wood_species.larch_desc'),
  cedar('woodlining.wood_species.cedar', 'woodlining.wood_species.cedar_desc'),
  aspen('woodlining.wood_species.aspen', 'woodlining.wood_species.aspen_desc'),
  alder('woodlining.wood_species.alder', 'woodlining.wood_species.alder_desc'),
  oak('woodlining.wood_species.oak', 'woodlining.wood_species.oak_desc');

  final String nameKey;
  final String descKey;

  const WoodSpecies(this.nameKey, this.descKey);
}

/// Направление монтажа
enum MountingDirection {
  vertical('woodlining.mounting.vertical', 'woodlining.mounting.vertical_desc', Icons.vertical_distribute, '40×20'),
  horizontal('woodlining.mounting.horizontal', 'woodlining.mounting.horizontal_desc', Icons.horizontal_distribute, '40×20'),
  diagonal('woodlining.mounting.diagonal', 'woodlining.mounting.diagonal_desc', Icons.rotate_right, '40×20');

  final String nameKey;
  final String descKey;
  final IconData icon;
  final String battenSize;

  const MountingDirection(this.nameKey, this.descKey, this.icon, this.battenSize);
}

/// Тип крепления
enum FasteningType {
  klyaymery('woodlining.fastening.klyaymery', 'woodlining.fastening.klyaymery_desc'),
  nails('woodlining.fastening.nails', 'woodlining.fastening.nails_desc'),
  screws('woodlining.fastening.screws', 'woodlining.fastening.screws_desc');

  final String nameKey;
  final String descKey;

  const FasteningType(this.nameKey, this.descKey);

  /// Ключ для получения значений из констант
  String get key => name;
}

/// Тип финишного покрытия
enum FinishType {
  varnish('woodlining.finish.varnish'),
  oil('woodlining.finish.oil'),
  wax('woodlining.finish.wax'),
  stain('woodlining.finish.stain');

  final String nameKey;

  const FinishType(this.nameKey);

  /// Ключ для получения значений из констант
  String get key => name;
}

class _WoodLiningResult {
  final double area;
  final double liningArea;
  final int liningPieces;
  final double battenLength;
  final int fasteners;
  final double antiseptic;
  final double finish;
  final double insulation;
  final double vaporBarrier;
  final double vaporBarrierWeight;

  const _WoodLiningResult({
    required this.area,
    required this.liningArea,
    required this.liningPieces,
    required this.battenLength,
    required this.fasteners,
    required this.antiseptic,
    required this.finish,
    required this.insulation,
    required this.vaporBarrier,
    required this.vaporBarrierWeight,
  });
}

enum InputMode { byArea, byDimensions }

class WoodLiningCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const WoodLiningCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<WoodLiningCalculatorScreen> createState() =>
      _WoodLiningCalculatorScreenState();
}

class _WoodLiningCalculatorScreenState extends State<WoodLiningCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate(widget.definition.titleKey);
  bool _isDark = false;
  InputMode _inputMode = InputMode.byArea;
  double _area = 20.0;
  double _length = 5.0;
  double _width = 4.0;
  double _height = 2.5;

  LiningType _liningType = LiningType.standard;
  WoodSpecies _woodSpecies = WoodSpecies.pine;
  MountingDirection _mountingDirection = MountingDirection.vertical;
  FasteningType _fasteningType = FasteningType.klyaymery;
  double _reserve = 10.0;

  bool _useInsulation = false;
  double _insulationThickness = 50.0;
  bool _useVaporBarrier = false;
  bool _useAntiseptic = true;
  bool _useFinish = false;
  FinishType _finishType = FinishType.varnish;

  late _WoodLiningResult _result;
  late AppLocalizations _loc;

  // Константы калькулятора (null = используются hardcoded defaults)
  late final _WoodLiningConstants _constants;

  @override
  void initState() {
    super.initState();
    _constants = const _WoodLiningConstants(null);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final inputs = widget.initialInputs;
    if (inputs == null) return;

    _inputMode = (inputs['inputMode'] ?? 1) == 0 ? InputMode.byDimensions : InputMode.byArea;
    _area = inputs['area']?.clamp(1.0, 500.0) ?? 20.0;
    _length = inputs['length']?.clamp(0.1, 50.0) ?? 5.0;
    _width = inputs['width']?.clamp(0.1, 50.0) ?? 4.0;
    _height = inputs['height']?.clamp(2.0, 5.0) ?? 2.5;
    _reserve = inputs['reserve']?.clamp(5.0, 20.0) ?? 10.0;
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    return _length * _width;
  }

  _WoodLiningResult _calculate() {
    final calculatedArea = _getCalculatedArea();
    if (calculatedArea <= 0) {
      return const _WoodLiningResult(
        area: 0,
        liningArea: 0,
        liningPieces: 0,
        battenLength: 0,
        fasteners: 0,
        antiseptic: 0,
        finish: 0,
        insulation: 0,
        vaporBarrier: 0,
        vaporBarrierWeight: 0,
      );
    }

    // Вагонка с запасом (используем только пользовательский запас)
    final liningArea = calculatedArea * (1 + _reserve / 100);
    final liningLength = _constants.getLiningLength(_liningType.key);
    final liningWidth = _constants.getLiningWidth(_liningType.key);
    final boardAreaM2 = liningLength * (liningWidth / 1000);
    final liningPieces = (liningArea / boardAreaM2).ceil();

    // Обрешётка
    final battenStep = _constants.battenStep;
    double battenLength;
    if (_mountingDirection == MountingDirection.vertical) {
      final battenCount = (_height / battenStep).ceil();
      final perimeterLength = _inputMode == InputMode.byArea
          ? math.sqrt(calculatedArea) * 4
          : 2 * (_length + _width);
      battenLength = battenCount * perimeterLength * _constants.battenMarginVertical;
    } else if (_mountingDirection == MountingDirection.horizontal) {
      final battenCount = _inputMode == InputMode.byArea
          ? (math.sqrt(calculatedArea) * 4 / battenStep).ceil()
          : ((_length + _width) * 2 / battenStep).ceil();
      battenLength = battenCount * _height * _constants.battenMarginHorizontal;
    } else {
      final battenCount = _inputMode == InputMode.byArea
          ? (math.sqrt(calculatedArea) * 4 / battenStep).ceil()
          : ((_length + _width) * 2 / battenStep).ceil();
      battenLength = battenCount * _height * _constants.battenMarginDiagonal;
    }

    // Крепёж
    final fasteningPerM2 = _constants.getFasteningPerM2(_fasteningType.key);
    final fasteners = (liningArea * fasteningPerM2).ceil();

    // Антисептик
    final antiseptic = _useAntiseptic
        ? calculatedArea * _constants.antisepticConsumption * _constants.antisepticMargin
        : 0.0;

    // Финишное покрытие
    final finishConsumption = _constants.getFinishConsumption(_finishType.key);
    final finish = _useFinish
        ? calculatedArea * finishConsumption * _constants.finishMargin
        : 0.0;

    // Утеплитель
    final insulation = _useInsulation
        ? calculatedArea * _constants.insulationMargin
        : 0.0;

    // Пароизоляция (нахлёсты из констант)
    final vaporBarrier = _useVaporBarrier
        ? calculatedArea * _constants.vaporBarrierOverlapMargin
        : 0.0;
    final vaporBarrierWeight = vaporBarrier * _constants.vaporBarrierWeightPerM2;

    return _WoodLiningResult(
      area: calculatedArea,
      liningArea: liningArea,
      liningPieces: liningPieces,
      battenLength: battenLength,
      fasteners: fasteners,
      antiseptic: antiseptic,
      finish: finish,
      insulation: insulation,
      vaporBarrier: vaporBarrier,
      vaporBarrierWeight: vaporBarrierWeight,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('${_loc.translate('woodlining.export.title')}\n');
    buffer.writeln(_loc.translate('woodlining.export.area').replaceFirst('{value}', _result.area.toStringAsFixed(2)));
    buffer.writeln(_loc.translate('woodlining.export.type').replaceFirst('{value}', _loc.translate(_liningType.nameKey)));
    buffer.writeln(_loc.translate('woodlining.export.species').replaceFirst('{value}', _loc.translate(_woodSpecies.nameKey)));
    buffer.writeln('${_loc.translate('woodlining.export.direction').replaceFirst('{value}', _loc.translate(_mountingDirection.nameKey))}\n');
    buffer.writeln('─────────────────────');
    buffer.writeln(_loc.translate('woodlining.export.main_materials'));
    buffer.writeln('• ${_loc.translate('woodlining.export.lining_line').replaceFirst('{area}', _result.liningArea.toStringAsFixed(2)).replaceFirst('{pcs}', _result.liningPieces.toString())}');
    buffer.writeln('• ${_loc.translate('woodlining.export.batten_line').replaceFirst('{value}', _result.battenLength.toStringAsFixed(1))}');
    buffer.writeln('• ${_loc.translate('woodlining.export.fasteners_line').replaceFirst('{count}', _result.fasteners.toString()).replaceFirst('{type}', _loc.translate(_fasteningType.nameKey))}');
    if (_useAntiseptic) {
      buffer.writeln('\n${_loc.translate('woodlining.export.protection')}');
      buffer.writeln('• ${_loc.translate('woodlining.export.antiseptic_line').replaceFirst('{value}', _result.antiseptic.toStringAsFixed(2))}');
    }
    if (_useFinish) {
      buffer.writeln('• ${_loc.translate('woodlining.export.finish_line').replaceFirst('{type}', _loc.translate(_finishType.nameKey)).replaceFirst('{value}', _result.finish.toStringAsFixed(2))}');
    }
    if (_useInsulation || _useVaporBarrier) {
      buffer.writeln('\n${_loc.translate('woodlining.export.isolation')}');
      if (_useInsulation) {
        buffer.writeln('• ${_loc.translate('woodlining.export.insulation_line').replaceFirst('{value}', _result.insulation.toStringAsFixed(2))}');
      }
      if (_useVaporBarrier) {
        buffer.writeln('• ${_loc.translate('woodlining.export.vapor_barrier_line').replaceFirst('{value}', _result.vaporBarrier.toStringAsFixed(2))}');
      }
    }
    buffer.writeln('\n─────────────────────');
    buffer.writeln(_loc.translate('woodlining.export.reserve').replaceFirst('{value}', _reserve.toInt().toString()));
    buffer.writeln('\n${_loc.translate('woodlining.export.footer')}');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.walls;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('woodlining.header.area'),
            value: '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('woodlining.header.lining'),
            value: '${_result.liningPieces} ${_loc.translate('common.pcs')}',
            icon: Icons.carpenter,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildLiningTypeCard(),
        const SizedBox(height: 16),
        _buildWoodSpeciesCard(),
        const SizedBox(height: 16),
        _buildMountingDirectionCard(),
        const SizedBox(height: 16),
        _buildFasteningCard(),
        const SizedBox(height: 16),
        _buildFinishCard(),
        const SizedBox(height: 16),
        _buildReserveCard(),
        const SizedBox(height: 16),
        _buildOptionalMaterialsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: ModeSelector(
        options: [
          _loc.translate('woodlining.mode.by_area'),
          _loc.translate('woodlining.mode.by_dimensions'),
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
    );
  }

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_inputMode == InputMode.byArea) ...[
            _buildSliderField(
              label: _loc.translate('woodlining.field.wall_area'),
              value: _area,
              min: 1.0,
              max: 500.0,
              suffix: _loc.translate('common.sqm'),
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            ),
          ] else ...[
            _buildSliderField(
              label: _loc.translate('woodlining.field.length'),
              value: _length,
              min: 0.1,
              max: 50.0,
              suffix: _loc.translate('common.meters'),
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _length = v;
                  _update();
                });
              },
            ),
            const SizedBox(height: 16),
            _buildSliderField(
              label: _loc.translate('woodlining.field.width'),
              value: _width,
              min: 0.1,
              max: 50.0,
              suffix: _loc.translate('common.meters'),
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _width = v;
                  _update();
                });
              },
            ),
          ],
          const SizedBox(height: 16),
          _buildSliderField(
            label: _loc.translate('woodlining.field.height'),
            value: _height,
            min: 2.0,
            max: 5.0,
            suffix: _loc.translate('common.meters'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _height = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLiningTypeCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('woodlining.section.lining_type'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<LiningType>(
            options: LiningType.values,
            minItemWidth: 140,
            minItemHeight: 72,
            itemBuilder: (type) {
              final isSelected = _liningType == type;
              return TypeSelectorCardCompact(
                icon: type.icon,
                title: _loc.translate(type.nameKey),
                subtitle: _loc.translate(type.descKey),
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _liningType = type;
                    _update();
                  });
                },
              );
            },
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _loc.translate('woodlining.info.dimensions')
                        .replaceFirst('{width}', _constants.getLiningWidth(_liningType.key).toInt().toString())
                        .replaceFirst('{length}', _constants.getLiningLength(_liningType.key).toString()),
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodSpeciesCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('woodlining.section.wood_species'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<WoodSpecies>(
            options: WoodSpecies.values,
            minItemWidth: 130,
            minItemHeight: 72,
            itemBuilder: (species) {
              final isSelected = _woodSpecies == species;
              return TypeSelectorCardCompact(
                icon: Icons.nature,
                title: _loc.translate(species.nameKey),
                subtitle: _loc.translate(species.descKey),
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _woodSpecies = species;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMountingDirectionCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('woodlining.section.mounting_direction'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<MountingDirection>(
            options: MountingDirection.values,
            minItemWidth: 140,
            minItemHeight: 72,
            itemBuilder: (direction) {
              final isSelected = _mountingDirection == direction;
              return TypeSelectorCardCompact(
                icon: direction.icon,
                title: _loc.translate(direction.nameKey),
                subtitle: _loc.translate(direction.descKey),
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _mountingDirection = direction;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFasteningCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('woodlining.section.fastening_type'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildOptionGrid<FasteningType>(
            options: FasteningType.values,
            minItemWidth: 140,
            minItemHeight: 72,
            itemBuilder: (type) {
              final isSelected = _fasteningType == type;
              return TypeSelectorCardCompact(
                icon: Icons.construction,
                title: _loc.translate(type.nameKey),
                subtitle: _loc.translate(type.descKey),
                isSelected: isSelected,
                accentColor: accentColor,
                onTap: () {
                  setState(() {
                    _fasteningType = type;
                    _update();
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinishCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('woodlining.section.finish_coating'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.getTextSecondary(_isDark),
            ),
            title: Text(
              _loc.translate('woodlining.finish.use_finish'),
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _useFinish ? _loc.translate(_finishType.nameKey) : _loc.translate('woodlining.finish.not_used'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _useFinish,
            onChanged: (v) {
              setState(() {
                _useFinish = v;
                _update();
              });
            },
          ),
          if (_useFinish) ...[
            const SizedBox(height: 8),
            _buildOptionGrid<FinishType>(
              options: FinishType.values,
              minItemWidth: 120,
              minItemHeight: 64,
              itemBuilder: (finish) {
                final isSelected = _finishType == finish;
                return TypeSelectorCardCompact(
                  icon: Icons.format_paint,
                  title: _loc.translate(finish.nameKey),
                  isSelected: isSelected,
                  accentColor: accentColor,
                  onTap: () {
                    setState(() {
                      _finishType = finish;
                      _update();
                    });
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReserveCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: _buildSliderField(
        label: _loc.translate('woodlining.field.reserve'),
        value: _reserve,
        min: 5.0,
        max: 20.0,
        suffix: '%',
        accentColor: accentColor,
        onChanged: (v) {
          setState(() {
            _reserve = v;
            _update();
          });
        },
      ),
    );
  }

  Widget _buildOptionalMaterialsCard() {
    const accentColor = CalculatorColors.walls;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('woodlining.section.additional_materials'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.getTextSecondary(_isDark),
            ),
            title: Text(
              _loc.translate('woodlining.optional.insulation'),
              style: CalculatorDesignSystem.bodyMedium,
            ),
            subtitle: Text(
              _useInsulation
                  ? _loc.translate('woodlining.optional.insulation_desc').replaceFirst('{value}', _insulationThickness.toInt().toString())
                  : _loc.translate('woodlining.finish.not_used'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _useInsulation,
            onChanged: (v) {
              setState(() {
                _useInsulation = v;
                _update();
              });
            },
          ),
          if (_useInsulation) ...[
            const SizedBox(height: 8),
            _buildSliderField(
              label: _loc.translate('woodlining.optional.insulation_thickness'),
              value: _insulationThickness,
              min: 50.0,
              max: 200.0,
              suffix: _loc.translate('common.mm'),
              divisions: 3,
              accentColor: accentColor,
              onChanged: (v) {
                setState(() {
                  _insulationThickness = v;
                  _update();
                });
              },
            ),
          ],
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.getTextSecondary(_isDark),
            ),
            title: Text(_loc.translate('woodlining.optional.vapor_barrier'), style: CalculatorDesignSystem.bodyMedium),
            subtitle: Text(
              _useVaporBarrier
                  ? _loc.translate('woodlining.optional.vapor_barrier_desc').replaceFirst('{value}', _constants.vaporBarrierWeightPerM2.toString())
                  : _loc.translate('woodlining.finish.not_used'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _useVaporBarrier,
            onChanged: (v) {
              setState(() {
                _useVaporBarrier = v;
                _update();
              });
            },
          ),
          const Divider(),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.getTextSecondary(_isDark),
            ),
            title: Text(_loc.translate('woodlining.optional.antiseptic'), style: CalculatorDesignSystem.bodyMedium),
            subtitle: Text(
              _useAntiseptic
                  ? _loc.translate('woodlining.optional.antiseptic_desc').replaceFirst('{value}', _constants.antisepticConsumption.toString())
                  : _loc.translate('woodlining.finish.not_used'),
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            value: _useAntiseptic,
            onChanged: (v) {
              setState(() {
                _useAntiseptic = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.walls;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('woodlining.material.lining'),
        value: '${_result.liningArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: '${_result.liningPieces} ${_loc.translate('common.pcs')}',
        icon: Icons.view_agenda,
      ),
      MaterialItem(
        name: _loc.translate('woodlining.material.batten'),
        value: '${_result.battenLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('woodlining.material.batten_desc').replaceFirst('{size}', _mountingDirection.battenSize),
        icon: Icons.view_stream,
      ),
      MaterialItem(
        name: _loc.translate('woodlining.material.fasteners'),
        value: '${_result.fasteners} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate(_fasteningType.nameKey),
        icon: Icons.construction,
      ),
    ];

    if (_useAntiseptic) {
      items.add(MaterialItem(
        name: _loc.translate('woodlining.optional.antiseptic'),
        value: '${_result.antiseptic.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('woodlining.material.consumption').replaceFirst('{value}', _constants.antisepticConsumption.toString()),
        icon: Icons.shield_outlined,
      ));
    }

    if (_useFinish) {
      items.add(MaterialItem(
        name: _loc.translate(_finishType.nameKey),
        value: '${_result.finish.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('woodlining.material.consumption').replaceFirst('{value}', _constants.getFinishConsumption(_finishType.key).toString()),
        icon: Icons.format_paint,
      ));
    }

    if (_useInsulation) {
      items.add(MaterialItem(
        name: _loc.translate('woodlining.optional.insulation'),
        value: '${_result.insulation.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('woodlining.optional.insulation_desc').replaceFirst('{value}', _insulationThickness.toInt().toString()),
        icon: Icons.waves,
      ));
    }

    if (_useVaporBarrier) {
      items.add(MaterialItem(
        name: _loc.translate('woodlining.optional.vapor_barrier'),
        value: '${_result.vaporBarrier.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: '~${_result.vaporBarrierWeight.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        icon: Icons.shield,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('woodlining.section.required_materials'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildOptionGrid<T>({
    required List<T> options,
    required double minItemWidth,
    double minItemHeight = 88,
    required Widget Function(T option) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final maxWidth = constraints.maxWidth;
        final targetColumns = math.max(
          1,
          ((maxWidth + spacing) / (minItemWidth + spacing)).floor(),
        ).toInt();
        final columns = math.max(1, math.min(options.length, targetColumns)).toInt();
        final itemWidth = (maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options
              .map((option) => SizedBox(
                    width: itemWidth,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minItemHeight),
                      child: itemBuilder(option),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.walls;
    final tips = <String>[];

    switch (_liningType) {
      case LiningType.standard:
        tips.addAll([
          _loc.translate('woodlining_calc.tip.standard_1'),
          _loc.translate('woodlining_calc.tip.standard_2'),
        ]);
        break;
      case LiningType.euro:
        tips.addAll([
          _loc.translate('woodlining_calc.tip.euro_1'),
          _loc.translate('woodlining_calc.tip.euro_2'),
        ]);
        break;
      case LiningType.blockHouse:
        tips.addAll([
          _loc.translate('woodlining_calc.tip.blockhouse_1'),
          _loc.translate('woodlining_calc.tip.blockhouse_2'),
        ]);
        break;
      case LiningType.imitationBar:
        tips.addAll([
          _loc.translate('woodlining_calc.tip.imitation_1'),
          _loc.translate('woodlining_calc.tip.imitation_2'),
        ]);
        break;
    }

    tips.addAll([
      _loc.translate('hint.wood.surface_preparation'),
      _loc.translate('hint.wood.moisture_control'),
    ]);

    tips.add(_loc.translate('woodlining_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required String suffix,
    int? divisions,
    required Color accentColor,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(value < 10 ? 1 : 0)} $suffix',
              style: CalculatorDesignSystem.headlineMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: accentColor.withValues(alpha: 0.2),
            thumbColor: accentColor,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions ?? ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: label,
          value: value,
          suffix: suffix,
          minValue: min,
          maxValue: max,
          decimalPlaces: value < 10 ? 1 : 0,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: CalculatorDesignSystem.cardPadding,
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}
