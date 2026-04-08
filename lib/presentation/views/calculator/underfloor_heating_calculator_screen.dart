
import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../data/models/price_item.dart';
import '../../../domain/usecases/calculate_underfloor_heating.dart';
import '../../mixins/exportable_mixin.dart';
import '../../mixins/accuracy_mode_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Вспомогательный класс для работы с константами калькулятора тёплого пола
class _WarmFloorConstants {
  final CalculatorConstants? _data;

  const _WarmFloorConstants([this._data]);

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

  // Room power (Вт/м²)
  int getRoomPower(String roomKey) {
    final defaults = {'bathroom': 180, 'living': 150, 'kitchen': 130, 'balcony': 200};
    return _getInt('room_power', roomKey, defaults[roomKey] ?? 150);
  }

  // Pipe step for water system (мм)
  int getPipeStep(String roomKey) {
    final defaults = {'bathroom': 100, 'living': 150, 'kitchen': 150, 'balcony': 100};
    return _getInt('pipe_step', roomKey, defaults[roomKey] ?? 150);
  }

  // Cable power (Вт/м)
  double get cablePowerPerMeter => _getDouble('cable_power', 'standard_cable', 18.0);

  // Useful area
  double get usefulAreaDefault => _getDouble('useful_area', 'default', 72.0);
  double get usefulAreaMin => _getDouble('useful_area', 'min', 50.0);
  double get usefulAreaMax => _getDouble('useful_area', 'max', 90.0);

  // Water system
  double get pipeMargin => _getDouble('water_system', 'pipe_margin', 1.15);
  double get maxLoopLength => _getDouble('water_system', 'max_loop_length', 100.0);
  double get screedThickness => _getDouble('water_system', 'screed_thickness', 0.08);
  double get damperTapePerM2 => _getDouble('water_system', 'damper_tape_per_m2', 0.4);
  double get bracketsPerM2 => _getDouble('water_system', 'brackets_per_m2', 10.0);

  // Electric cable
  double get montageTapeMultiplier => _getDouble('electric_cable', 'montage_tape_multiplier', 2.0);

  // Infrared film
  double get filmStripArea => _getDouble('infrared_film', 'film_strip_area', 2.5);
  int get contactsPerStrip => _getInt('infrared_film', 'contacts_per_strip', 2);

  // Common materials
  int get thermostatCount => _getInt('common_materials', 'thermostat_count', 1);
  int get sensorCount => _getInt('common_materials', 'sensor_count', 1);
  double get corrugatedTubeLength => _getDouble('common_materials', 'corrugated_tube_length', 2.5);
}

enum InputMode { byArea, byDimensions }

enum HeatingSystemType {
  electricMat(
    'warmfloor.system.electric_mat',
    'warmfloor.system.electric_mat_desc',
    'warmfloor.system.electric_mat_advantage',
    Icons.grid_on,
  ),
  electricCable(
    'warmfloor.system.electric_cable',
    'warmfloor.system.electric_cable_desc',
    'warmfloor.system.electric_cable_advantage',
    Icons.cable,
  ),
  infraredFilm(
    'warmfloor.system.infrared_film',
    'warmfloor.system.infrared_film_desc',
    'warmfloor.system.infrared_film_advantage',
    Icons.view_module,
  ),
  waterBased(
    'warmfloor.system.water_based',
    'warmfloor.system.water_based_desc',
    'warmfloor.system.water_based_advantage',
    Icons.waves,
  );

  final String nameKey;
  final String subtitleKey;
  final String advantageKey;
  final IconData icon;
  const HeatingSystemType(this.nameKey, this.subtitleKey, this.advantageKey, this.icon);
}

enum RoomType {
  bathroom('warmfloor.room.bathroom', 'warmfloor.room.bathroom_desc'),
  living('warmfloor.room.living', 'warmfloor.room.living_desc'),
  kitchen('warmfloor.room.kitchen', 'warmfloor.room.kitchen_desc'),
  balcony('warmfloor.room.balcony', 'warmfloor.room.balcony_desc');

  final String nameKey;
  final String descriptionKey;
  const RoomType(this.nameKey, this.descriptionKey);

  /// Ключ для получения значений из констант
  String get key => name;
}

class _HeatingResult {
  final double area;
  final double perimeter; // Периметр помещения (м)
  final HeatingSystemType systemType;
  final RoomType roomType;
  final double heatingArea; // Фактическая площадь обогрева (70-80% от общей)

  // Общие параметры
  final int totalPower; // Вт
  final bool needsThermostat;
  final bool needsInsulation;

  // Электрический мат/кабель
  final double? matArea; // м²
  final double? cableLength; // м

  // ИК плёнка
  final double? filmArea; // м²
  final double? filmLinearMeters; // погонные метры
  final int? filmWidthCm; // ширина плёнки в см
  final int? contactClips;

  // Водяной
  final double? pipeLength; // м
  final int? loopCount; // количество контуров
  final int? collectorOutputs;
  final double? insulationArea; // м²
  final double? screedVolume; // м³

  // Общие материалы
  final double thermostatCount;
  final double sensorCount;
  final double corrugatedTubeLength; // м для датчика

  const _HeatingResult({
    required this.area,
    required this.perimeter,
    required this.systemType,
    required this.roomType,
    required this.heatingArea,
    required this.totalPower,
    required this.needsThermostat,
    required this.needsInsulation,
    this.matArea,
    this.cableLength,
    this.filmArea,
    this.filmLinearMeters,
    this.filmWidthCm,
    this.contactClips,
    this.pipeLength,
    this.loopCount,
    this.collectorOutputs,
    this.insulationArea,
    this.screedVolume,
    required this.thermostatCount,
    required this.sensorCount,
    required this.corrugatedTubeLength,
  });
}

class UnderfloorHeatingCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const UnderfloorHeatingCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<UnderfloorHeatingCalculatorScreen> createState() =>
      _UnderfloorHeatingCalculatorScreenState();
}

class _UnderfloorHeatingCalculatorScreenState
    extends State<UnderfloorHeatingCalculatorScreen> with ExportableMixin, AccuracyModeMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('warmfloor.export.subject');
  bool _isDark = false;
  InputMode _inputMode = InputMode.byArea;
  double _area = 15.0;
  double _length = 4.0;
  double _width = 3.75;
  HeatingSystemType _systemType = HeatingSystemType.electricMat;
  RoomType _roomType = RoomType.living;
  bool _addInsulation = false;
  int _filmWidthIndex = 1; // 0=50см, 1=80см, 2=100см

  late double _usefulAreaPercent;
  late _HeatingResult _result;
  late AppLocalizations _loc;

  // Константы калькулятора (null = используются hardcoded defaults)
  late final _WarmFloorConstants _constants;

  @override
  void initState() {
    super.initState();
    _constants = const _WarmFloorConstants(null);
    _usefulAreaPercent = _constants.usefulAreaDefault;
    _applyInitialInputs();
    _result = _calculate();
  }

  final CalculateUnderfloorHeating _calculator = CalculateUnderfloorHeating();

  T _enumFromStoredIndex<T>(List<T> values, double? rawValue, T fallback, {bool oneBased = false}) {
    if (rawValue == null) return fallback;
    final rawIndex = rawValue.round() - (oneBased ? 1 : 0);
    if (rawIndex < 0 || rawIndex >= values.length) return fallback;
    return values[rawIndex];
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    _inputMode = _enumFromStoredIndex(InputMode.values, initial['inputMode'], _inputMode);
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['length'] != null) _length = initial['length']!.clamp(0.1, 100.0);
    if (initial['width'] != null) _width = initial['width']!.clamp(0.1, 100.0);
    _systemType = _enumFromStoredIndex(HeatingSystemType.values, initial['systemType'], _systemType, oneBased: true);
    _roomType = _enumFromStoredIndex(RoomType.values, initial['roomType'], _roomType, oneBased: true);
    if (initial['usefulAreaPercent'] != null) {
      _usefulAreaPercent = initial['usefulAreaPercent']!.clamp(_constants.usefulAreaMin, _constants.usefulAreaMax);
    }
    if (initial['addInsulation'] != null) _addInsulation = initial['addInsulation']! >= 1;
    if (initial['filmWidth'] != null) _filmWidthIndex = initial['filmWidth']!.round().clamp(0, 2);
  }

  Map<String, double> _buildCalculationInputs() {
    return {
      'inputMode': _inputMode.index.toDouble(),
      'area': _area,
      'length': _length,
      'width': _width,
      'systemType': (_systemType.index + 1).toDouble(),
      'roomType': (_roomType.index + 1).toDouble(),
      'usefulAreaPercent': _usefulAreaPercent,
      'addInsulation': _addInsulation ? 1.0 : 0.0,
      'filmWidth': _filmWidthIndex.toDouble(),
      ...accuracyModeInput,
    };
  }

  _HeatingResult _mapCalculationResult(Map<String, double> values) {
    final systemType = _enumFromStoredIndex(
      HeatingSystemType.values,
      values['systemType'],
      HeatingSystemType.electricMat,
      oneBased: true,
    );
    final roomType = _enumFromStoredIndex(
      RoomType.values,
      values['roomType'],
      RoomType.living,
      oneBased: true,
    );
    return _HeatingResult(
      area: values['area'] ?? 0,
      perimeter: values['perimeter'] ?? 0,
      systemType: systemType,
      roomType: roomType,
      heatingArea: values['heatingArea'] ?? 0,
      totalPower: (values['totalPower'] ?? 0).round(),
      needsThermostat: true,
      needsInsulation: values['insulationArea'] != null,
      matArea: values['matArea'],
      cableLength: values['cableLength'],
      filmArea: values['filmArea'],
      filmLinearMeters: values['filmLinearMeters'],
      filmWidthCm: values['filmWidthCm']?.round(),
      contactClips: values['contactClips']?.round(),
      pipeLength: values['pipeLength'],
      loopCount: values['loopCount']?.round(),
      collectorOutputs: values['collectorOutputs']?.round(),
      insulationArea: values['insulationArea'],
      screedVolume: values['screedVolume'],
      thermostatCount: values['thermostatCount'] ?? _constants.thermostatCount.toDouble(),
      sensorCount: values['sensorCount'] ?? _constants.sensorCount.toDouble(),
      corrugatedTubeLength: values['corrugatedTubeLength'] ?? _constants.corrugatedTubeLength,
    );
  }

  _HeatingResult _calculate() {
    final result = _calculator(_buildCalculationInputs(), <PriceItem>[]);
    return _mapCalculationResult(result.values);
  }

  void _recalculate() => _result = _calculate();

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 ${_loc.translate('warmfloor.export.title')}');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('${_loc.translate('warmfloor.export.room_area')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('warmfloor.export.heating_area')}: ${_result.heatingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln('${_loc.translate('warmfloor.export.system_type')}: ${_loc.translate(_result.systemType.nameKey)}');
    buffer.writeln('${_loc.translate('warmfloor.export.room_type')}: ${_loc.translate(_result.roomType.nameKey)}');
    buffer.writeln('${_loc.translate('warmfloor.export.power')}: ${_result.totalPower} ${_loc.translate('common.watt')}');
    buffer.writeln();

    buffer.writeln('📦 ${_loc.translate('warmfloor.export.materials_title')}:');
    buffer.writeln('─' * 40);

    switch (_result.systemType) {
      case HeatingSystemType.electricMat:
        buffer.writeln('• ${_loc.translate('warmfloor.export.heating_mat')}: ${(_result.matArea ?? 0).toStringAsFixed(1)} ${_loc.translate('common.sqm')} (${_result.totalPower} ${_loc.translate('common.watt')})');
        break;
      case HeatingSystemType.electricCable:
        buffer.writeln('• ${_loc.translate('warmfloor.export.heating_cable')}: ${(_result.cableLength ?? 0).toStringAsFixed(1)} ${_loc.translate('common.meters')} (${_result.totalPower} ${_loc.translate('common.watt')})');
        buffer.writeln('• ${_loc.translate('warmfloor.export.mounting_tape')}: ${(_result.heatingArea * _constants.montageTapeMultiplier).toStringAsFixed(0)} ${_loc.translate('common.meters')}');
        break;
      case HeatingSystemType.infraredFilm:
        buffer.writeln('• ${_loc.translate('warmfloor.export.ir_film')}: ${(_result.filmLinearMeters ?? 0).toStringAsFixed(1)} ${_loc.translate('common.meters')} (${_loc.translate('warmfloor.film_width.label')}: ${_result.filmWidthCm} ${_loc.translate('common.cm')})');
        buffer.writeln('• ${_loc.translate('warmfloor.export.contact_clips')}: ${_result.contactClips} ${_loc.translate('common.pcs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.contact_insulation')}: ${_result.contactClips} ${_loc.translate('common.pcs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.reflective_substrate')}: ${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
        break;
      case HeatingSystemType.waterBased:
        buffer.writeln('• ${_loc.translate('warmfloor.export.pipe_pert')}: ${(_result.pipeLength ?? 0).toStringAsFixed(0)} ${_loc.translate('common.meters')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.collector')}: ${_result.collectorOutputs} ${_loc.translate('warmfloor.materials.outputs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.loops')}: ${_result.loopCount}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.insulation_psb')}: ${(_result.insulationArea ?? 0).toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.damper_tape')}: ${(_result.perimeter * 1.1).toStringAsFixed(0)} ${_loc.translate('common.meters')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.brackets')}: ${(_result.heatingArea * _constants.bracketsPerM2).toStringAsFixed(0)} ${_loc.translate('common.pcs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.screed')}: ${(_result.screedVolume ?? 0).toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}');
        break;
    }

    buffer.writeln('• ${_loc.translate('warmfloor.export.thermostat')}: ${_result.thermostatCount.toStringAsFixed(0)} ${_loc.translate('common.pcs')}');
    buffer.writeln('• ${_loc.translate('warmfloor.export.corrugated_tube')}: ${_result.corrugatedTubeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}');

    if (_result.insulationArea != null && _result.systemType != HeatingSystemType.waterBased) {
      buffer.writeln('• ${_loc.translate('warmfloor.export.insulation')}: ${_result.insulationArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    }


    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('warmfloor.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.engineering;

    return CalculatorScaffold(
      title: _loc.translate('warmfloor.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('warmfloor.header.area'),
            value: '${_result.heatingArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('warmfloor.header.power'),
            value: '${(_result.totalPower / 1000).toStringAsFixed(1)} ${_loc.translate('common.kilowatt')}',
            icon: Icons.bolt,
          ),
          ResultItem(
            label: _result.systemType == HeatingSystemType.waterBased
                ? _loc.translate('warmfloor.header.pipe')
                : _loc.translate('warmfloor.header.system'),
            value: _result.systemType == HeatingSystemType.waterBased
                ? '${_result.pipeLength!.toStringAsFixed(0)} ${_loc.translate('common.meters')}'
                : _result.systemType == HeatingSystemType.electricMat
                    ? '${_result.matArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}'
                    : _result.systemType == HeatingSystemType.electricCable
                        ? '${_result.cableLength!.toStringAsFixed(0)} ${_loc.translate('common.meters')}'
                        : '${_result.filmLinearMeters!.toStringAsFixed(1)} ${_loc.translate('common.linear_meter_short')}',
            icon: Icons.thermostat,
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
        _buildSystemTypeSelector(),
        const SizedBox(height: 16),
        _buildRoomTypeSelector(),
        const SizedBox(height: 16),
        _buildUsefulAreaSlider(),
        const SizedBox(height: 16),
        if (_systemType == HeatingSystemType.infraredFilm) _buildFilmWidthSelector(),
        if (_systemType == HeatingSystemType.infraredFilm) const SizedBox(height: 16),
        if (_systemType != HeatingSystemType.waterBased) _buildInsulationToggle(),
        if (_systemType != HeatingSystemType.waterBased) const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildAdditionalInfoCard(),
        const SizedBox(height: 24),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('warmfloor.mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('warmfloor.mode.by_area'),
              _loc.translate('warmfloor.mode.by_dimensions'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = InputMode.values[index];
                _recalculate();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: CalculatorTextField(
        key: const ValueKey('warm_floor_area'),
        label: _loc.translate('warmfloor.dimensions.room_area'),
        value: _area,
        onChanged: (v) {
          setState(() {
            _area = v;
            _recalculate();
          });
        },
        suffix: _loc.translate('common.sqm'),
        accentColor: accentColor,
        minValue: 1,
        maxValue: 200,
      ),
    );
  }

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CalculatorTextField(
                  key: const ValueKey('warm_floor_length'),
                  label: _loc.translate('warmfloor.dimensions.length'),
                  value: _length,
                  onChanged: (v) {
                    setState(() {
                      _length = v;
                      _recalculate();
                    });
                  },
                  suffix: _loc.translate('common.meters'),
                  accentColor: accentColor,
                  minValue: 0.5,
                  maxValue: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CalculatorTextField(
                  key: const ValueKey('warm_floor_width'),
                  label: _loc.translate('warmfloor.dimensions.width'),
                  value: _width,
                  onChanged: (v) {
                    setState(() {
                      _width = v;
                      _recalculate();
                    });
                  },
                  suffix: _loc.translate('common.meters'),
                  accentColor: accentColor,
                  minValue: 0.5,
                  maxValue: 30,
                ),
              ),
            ],
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
                  _loc.translate('warmfloor.dimensions.room_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
                Text(
                  '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemTypeSelector() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('warmfloor.system.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ...HeatingSystemType.values.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _systemType == type;

            return Padding(
              padding: EdgeInsets.only(bottom: index < HeatingSystemType.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _systemType = type;
                    _recalculate();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type.icon,
                          color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc.translate(type.nameKey),
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected
                                    ? accentColor
                                    : CalculatorColors.getTextPrimary(_isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _loc.translate(type.subtitleKey),
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.getTextSecondary(_isDark),
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Text(
                                '✓ ${_loc.translate(type.advantageKey)}',
                                style: CalculatorDesignSystem.bodySmall.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('warmfloor.room.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('warmfloor.room.title_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ...RoomType.values.asMap().entries.map((entry) {
            final index = entry.key;
            final type = entry.value;
            final isSelected = _roomType == type;

            return Padding(
              padding: EdgeInsets.only(bottom: index < RoomType.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _roomType = type;
                    _recalculate();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.getTextSecondary(_isDark).withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc.translate(type.nameKey),
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected
                                    ? accentColor
                                    : CalculatorColors.getTextPrimary(_isDark),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_loc.translate(type.descriptionKey)} • ${_constants.getRoomPower(type.key)} ${_loc.translate('watt_per_sqm')}',
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.getTextSecondary(_isDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildUsefulAreaSlider() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('warmfloor.useful_area.title'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_usefulAreaPercent.round()}%',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('warmfloor.useful_area.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.2),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: _usefulAreaPercent,
              min: _constants.usefulAreaMin,
              max: _constants.usefulAreaMax,
              divisions: ((_constants.usefulAreaMax - _constants.usefulAreaMin) / 5).round(),
              onChanged: (value) {
                setState(() {
                  _usefulAreaPercent = value;
                  _recalculate();
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_constants.usefulAreaMin.toInt()}% (${_loc.translate('warmfloor.useful_area.min_label')})',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                  fontSize: 11,
                ),
              ),
              Text(
                '${_constants.usefulAreaMax.toInt()}% (${_loc.translate('warmfloor.useful_area.max_label')})',
                style: CalculatorDesignSystem.bodySmall.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: _loc.translate('warmfloor.useful_area.title'),
            value: _usefulAreaPercent,
            onChanged: (v) {
              setState(() {
                _usefulAreaPercent = v;
                _recalculate();
              });
            },
            suffix: _loc.translate('common.percent'),
            accentColor: accentColor,
            minValue: _constants.usefulAreaMin,
            maxValue: _constants.usefulAreaMax,
            decimalPlaces: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildFilmWidthSelector() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('warmfloor.film_width.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: ['50 ${_loc.translate('room.unit.cm')}', '80 ${_loc.translate('room.unit.cm')}', '100 ${_loc.translate('room.unit.cm')}'],
            selectedIndex: _filmWidthIndex,
            onSelect: (index) {
              setState(() {
                _filmWidthIndex = index;
                _result = _calculate();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildInsulationToggle() {
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loc.translate('warmfloor.insulation.title'),
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: CalculatorColors.getTextPrimary(_isDark),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _loc.translate('warmfloor.insulation.hint'),
                  style: CalculatorDesignSystem.bodySmall.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _addInsulation,
            onChanged: (value) {
              setState(() {
                _addInsulation = value;
                _recalculate();
              });
            },
            activeTrackColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.engineering;

    final materials = <MaterialItem>[];

    switch (_result.systemType) {
      case HeatingSystemType.electricMat:
        materials.add(MaterialItem(
          name: _loc.translate('warmfloor.materials.heating_mat'),
          value: '${_result.matArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
          subtitle: '${_result.totalPower} ${_loc.translate('common.watt')}',
          icon: Icons.grid_on,
        ));
        break;

      case HeatingSystemType.electricCable:
        materials.addAll([
          MaterialItem(
            name: _loc.translate('warmfloor.materials.heating_cable'),
            value: '${_result.cableLength!.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            subtitle: '${_result.totalPower} ${_loc.translate('common.watt')}',
            icon: Icons.cable,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.mounting_tape'),
            value: '${(_result.heatingArea * _constants.montageTapeMultiplier).toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.straighten,
          ),
        ]);
        break;

      case HeatingSystemType.infraredFilm:
        materials.addAll([
          MaterialItem(
            name: _loc.translate('warmfloor.materials.ir_film'),
            value: '${_result.filmLinearMeters!.toStringAsFixed(1)} ${_loc.translate('common.meters')} × ${_result.filmWidthCm} ${_loc.translate('common.cm')}',
            subtitle: '${_loc.translate('warmfloor.materials.coverage')}: ${_result.filmArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.view_module,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.contact_clips'),
            value: '${_result.contactClips} ${_loc.translate('common.pcs')}',
            icon: Icons.link,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.contact_insulation'),
            value: '${_result.contactClips} ${_loc.translate('common.pcs')}',
            icon: Icons.bolt,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.reflective_substrate'),
            value: '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.layers,
          ),
        ]);
        break;

      case HeatingSystemType.waterBased:
        materials.addAll([
          MaterialItem(
            name: _loc.translate('warmfloor.materials.pipe_pert'),
            value: '${_result.pipeLength!.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            subtitle: '${_loc.translate('warmfloor.materials.pipe_step')}: ${_constants.getPipeStep(_roomType.key)} ${_loc.translate('common.mm')}',
            icon: Icons.timeline,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.collector'),
            value: '${_result.collectorOutputs} ${_loc.translate('warmfloor.materials.outputs')}',
            icon: Icons.device_hub,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.loops'),
            value: '${_result.loopCount} ${_loc.translate('common.pcs')}',
            icon: Icons.loop,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.insulation_psb'),
            value: '${_result.insulationArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            subtitle: '50 ${_loc.translate('common.mm')}',
            icon: Icons.layers,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.damper_tape'),
            value: '${(_result.perimeter * 1.1).toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.straighten,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.brackets'),
            value: '${(_result.heatingArea * _constants.bracketsPerM2).toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.push_pin,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.screed'),
            value: '${_result.screedVolume!.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}',
            icon: Icons.foundation,
          ),
        ]);
        break;
    }

    // Общие материалы
    materials.addAll([
      MaterialItem(
        name: _loc.translate('warmfloor.materials.thermostat'),
        value: '${_result.thermostatCount.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
        icon: Icons.thermostat,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.materials.temp_sensor'),
        value: '${_result.sensorCount.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
        icon: Icons.sensors,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.materials.corrugated_tube'),
        value: '${_result.corrugatedTubeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('warmfloor.materials.for_sensor'),
        icon: Icons.sensor_door,
      ),
    ]);

    if (_result.insulationArea != null && _result.systemType != HeatingSystemType.waterBased) {
      materials.add(MaterialItem(
        name: _loc.translate('warmfloor.materials.insulation'),
        value: '${_result.insulationArea!.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('warmfloor.materials.title'),
      titleIcon: Icons.construction,
      items: materials,
      accentColor: accentColor,
    );
  }

  Widget _buildAdditionalInfoCard() {
    const accentColor = CalculatorColors.engineering;

    // Примерное энергопотребление (8 часов в день, 120 дней в сезон)
    final monthlyConsumption = (_result.totalPower / 1000) * 8 * 30; // кВт⋅ч
    final seasonConsumption = monthlyConsumption * 4; // 4 месяца

    final infoItems = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('warmfloor.info.system_power'),
        value: '${(_result.totalPower / 1000).toStringAsFixed(2)} ${_loc.translate('common.kilowatt')}',
        icon: Icons.bolt,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.info.heating_area'),
        value: '${_result.heatingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: '${_usefulAreaPercent.round()}${_loc.translate('common.percent')} ${_loc.translate('warmfloor.info.heating_area_hint')}',
        icon: Icons.heat_pump,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.info.monthly_consumption'),
        value: '~${monthlyConsumption.toStringAsFixed(0)} ${_loc.translate('common.kilowatt_hour')}',
        subtitle: _loc.translate('warmfloor.info.monthly_hint'),
        icon: Icons.calendar_month,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.info.season_consumption'),
        value: '~${seasonConsumption.toStringAsFixed(0)} ${_loc.translate('common.kilowatt_hour')}',
        subtitle: _loc.translate('warmfloor.info.season_hint'),
        icon: Icons.calendar_today,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('warmfloor.info.title'),
      titleIcon: Icons.info_outline,
      items: infoItems,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.engineering;
    final tips = <String>[];

    switch (_result.systemType) {
      case HeatingSystemType.electricMat:
        tips.addAll([
          _loc.translate('warmfloor.hints.mat_surface'),
          _loc.translate('warmfloor.hints.mat_thermostat'),
          _loc.translate('warmfloor.hints.mat_resistance'),
        ]);
        break;
      case HeatingSystemType.electricCable:
        tips.addAll([
          _loc.translate('warmfloor.hints.cable_step'),
          _loc.translate('warmfloor.hints.cable_tape'),
          _loc.translate('warmfloor.hints.cable_no_cut'),
        ]);
        break;
      case HeatingSystemType.infraredFilm:
        tips.addAll([
          _loc.translate('warmfloor.hints.film_substrate'),
          _loc.translate('warmfloor.hints.film_parallel'),
          _loc.translate('warmfloor.hints.film_insulate'),
        ]);
        break;
      case HeatingSystemType.waterBased:
        tips.addAll([
          _loc.translate('warmfloor.hints.water_pressure'),
          _loc.translate('warmfloor.hints.water_pipe'),
          _loc.translate('warmfloor.hints.water_drying'),
        ]);
        break;
    }

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}





