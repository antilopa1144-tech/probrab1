import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
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
    final defaults = {'bathroom': 180, 'living': 120, 'kitchen': 130, 'balcony': 200};
    return _getInt('room_power', roomKey, defaults[roomKey] ?? 150);
  }

  // Pipe step for water system (мм)
  int getPipeStep(String roomKey) {
    final defaults = {'bathroom': 150, 'living': 150, 'kitchen': 150, 'balcony': 100};
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
    extends State<UnderfloorHeatingCalculatorScreen> with ExportableMixin {
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

  // Ширины ИК плёнки в метрах
  static const _filmWidths = {0: 0.5, 1: 0.8, 2: 1.0};
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

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['length'] != null) {
      _length = initial['length']!.clamp(0.1, 100.0);
    }
    if (initial['width'] != null) _width = initial['width']!.clamp(0.1, 100.0);
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    return _length * _width;
  }

  _HeatingResult _calculate() {
    final calculatedArea = _getCalculatedArea();

    // Площадь обогрева = настраиваемый % от общей (минус мебель, сантехника)
    final heatingArea = calculatedArea * (_usefulAreaPercent / 100);

    // Мощность из констант по типу помещения
    final roomPower = _constants.getRoomPower(_roomType.key);
    final totalPower = (heatingArea * roomPower).round();

    // Общие материалы из констант
    final thermostatCount = _constants.thermostatCount.toDouble();
    final sensorCount = _constants.sensorCount.toDouble();
    final corrugatedTubeLength = _constants.corrugatedTubeLength;

    double? matArea;
    double? cableLength;
    double? filmArea;
    double? filmLinearMeters;
    int? filmWidthCm;
    int? contactClips;
    double? pipeLength;
    int? loopCount;
    int? collectorOutputs;
    double? insulationArea;
    double? screedVolume;

    switch (_systemType) {
      case HeatingSystemType.electricMat:
        // Нагревательный мат продаётся готовыми комплектами по площади
        matArea = heatingArea;
        break;

      case HeatingSystemType.electricCable:
        // Кабель: длина зависит от мощности кабеля (обычно 17-20 Вт/м)
        final cablePowerPerMeter = _constants.cablePowerPerMeter;
        cableLength = totalPower / cablePowerPerMeter;
        break;

      case HeatingSystemType.infraredFilm:
        // ИК плёнка: ширина из выбора пользователя (50/80/100 см)
        final filmWidthM = _filmWidths[_filmWidthIndex] ?? 0.8;
        final filmWidthCmVal = (filmWidthM * 100).toInt();
        filmArea = heatingArea;
        // Погонные метры = площадь / ширина плёнки
        final linearMeters = filmArea / filmWidthM;
        // Количество полос (примерно 5 м.п. на полосу)
        final filmStrips = (linearMeters / 5.0).ceil();
        // На каждую полосу: контактные зажимы
        contactClips = filmStrips * _constants.contactsPerStrip;
        filmLinearMeters = linearMeters;
        filmWidthCm = filmWidthCmVal;
        break;

      case HeatingSystemType.waterBased:
        // Водяной: расчёт трубы по шагу укладки из констант
        final pipeStep = _constants.getPipeStep(_roomType.key);
        final stepM = pipeStep / 1000; // мм в метры
        final pipePerM2 = 1 / stepM; // метров трубы на м²
        pipeLength = heatingArea * pipePerM2 * _constants.pipeMargin;

        // Количество контуров
        loopCount = (pipeLength / _constants.maxLoopLength).ceil();
        collectorOutputs = loopCount;

        // Теплоизоляция обязательна для водяного
        insulationArea = calculatedArea;

        // Стяжка: толщина из констант
        screedVolume = calculatedArea * _constants.screedThickness;
        break;
    }

    // Теплоизоляция (опционально для электрических, обязательна для водяного)
    if (_addInsulation && _systemType != HeatingSystemType.waterBased) {
      insulationArea = calculatedArea;
    }

    return _HeatingResult(
      area: calculatedArea,
      systemType: _systemType,
      roomType: _roomType,
      heatingArea: heatingArea,
      totalPower: totalPower,
      needsThermostat: true,
      needsInsulation: _addInsulation || _systemType == HeatingSystemType.waterBased,
      matArea: matArea,
      cableLength: cableLength,
      filmArea: filmArea,
      filmLinearMeters: filmLinearMeters,
      filmWidthCm: filmWidthCm,
      contactClips: contactClips,
      pipeLength: pipeLength,
      loopCount: loopCount,
      collectorOutputs: collectorOutputs,
      insulationArea: insulationArea,
      screedVolume: screedVolume,
      thermostatCount: thermostatCount,
      sensorCount: sensorCount,
      corrugatedTubeLength: corrugatedTubeLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('📋 ${_loc.translate('warmfloor.export.title')}');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('${_loc.translate('warmfloor.export.room_area')}: ${_result.area.toStringAsFixed(1)} м²');
    buffer.writeln('${_loc.translate('warmfloor.export.heating_area')}: ${_result.heatingArea.toStringAsFixed(1)} м²');
    buffer.writeln('${_loc.translate('warmfloor.export.system_type')}: ${_loc.translate(_result.systemType.nameKey)}');
    buffer.writeln('${_loc.translate('warmfloor.export.room_type')}: ${_loc.translate(_result.roomType.nameKey)}');
    buffer.writeln('${_loc.translate('warmfloor.export.power')}: ${_result.totalPower} ${_loc.translate('common.watt')}');
    buffer.writeln();

    buffer.writeln('📦 ${_loc.translate('warmfloor.export.materials_title')}:');
    buffer.writeln('─' * 40);

    switch (_result.systemType) {
      case HeatingSystemType.electricMat:
        buffer.writeln('• ${_loc.translate('warmfloor.export.heating_mat')}: ${_result.matArea!.toStringAsFixed(1)} м² (${_result.totalPower} ${_loc.translate('common.watt')})');
        break;
      case HeatingSystemType.electricCable:
        buffer.writeln('• ${_loc.translate('warmfloor.export.heating_cable')}: ${_result.cableLength!.toStringAsFixed(1)} ${_loc.translate('common.meters')} (${_result.totalPower} ${_loc.translate('common.watt')})');
        buffer.writeln('• ${_loc.translate('warmfloor.export.mounting_tape')}: ${(_result.heatingArea * _constants.montageTapeMultiplier).toStringAsFixed(0)} ${_loc.translate('common.meters')}');
        break;
      case HeatingSystemType.infraredFilm:
        buffer.writeln('• ${_loc.translate('warmfloor.export.ir_film')}: ${_result.filmLinearMeters!.toStringAsFixed(1)} м.п. (${_loc.translate('warmfloor.film_width.label')}: ${_result.filmWidthCm} см)');
        buffer.writeln('• ${_loc.translate('warmfloor.export.contact_clips')}: ${_result.contactClips} ${_loc.translate('common.pcs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.contact_insulation')}: ${_result.contactClips} ${_loc.translate('common.pcs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.reflective_substrate')}: ${_result.area.toStringAsFixed(1)} м²');
        break;
      case HeatingSystemType.waterBased:
        buffer.writeln('• ${_loc.translate('warmfloor.export.pipe_pert')}: ${_result.pipeLength!.toStringAsFixed(0)} ${_loc.translate('common.meters')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.collector')}: ${_result.collectorOutputs} ${_loc.translate('warmfloor.materials.outputs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.loops')}: ${_result.loopCount}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.insulation_psb')}: ${_result.insulationArea!.toStringAsFixed(1)} м²');
        buffer.writeln('• ${_loc.translate('warmfloor.export.damper_tape')}: ${(_result.area * _constants.damperTapePerM2).toStringAsFixed(0)} ${_loc.translate('common.meters')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.brackets')}: ${(_result.heatingArea * _constants.bracketsPerM2).toStringAsFixed(0)} ${_loc.translate('common.pcs')}');
        buffer.writeln('• ${_loc.translate('warmfloor.export.screed')}: ${_result.screedVolume!.toStringAsFixed(2)} м³');
        break;
    }

    buffer.writeln('• ${_loc.translate('warmfloor.export.thermostat')}: ${_result.thermostatCount.toStringAsFixed(0)} ${_loc.translate('common.pcs')}');
    buffer.writeln('• ${_loc.translate('warmfloor.export.temp_sensor')}: ${_result.sensorCount.toStringAsFixed(0)} ${_loc.translate('common.pcs')}');
    buffer.writeln('• ${_loc.translate('warmfloor.export.corrugated_tube')}: ${_result.corrugatedTubeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}');

    if (_result.insulationArea != null && _result.systemType != HeatingSystemType.waterBased) {
      buffer.writeln('• ${_loc.translate('warmfloor.export.insulation')}: ${_result.insulationArea!.toStringAsFixed(1)} м²');
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
            value: '${_result.heatingArea.toStringAsFixed(0)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('warmfloor.header.power'),
            value: '${(_result.totalPower / 1000).toStringAsFixed(1)} кВт',
            icon: Icons.bolt,
          ),
          ResultItem(
            label: _result.systemType == HeatingSystemType.waterBased
                ? _loc.translate('warmfloor.header.pipe')
                : _loc.translate('warmfloor.header.system'),
            value: _result.systemType == HeatingSystemType.waterBased
                ? '${_result.pipeLength!.toStringAsFixed(0)} м'
                : _result.systemType == HeatingSystemType.electricMat
                    ? '${_result.matArea!.toStringAsFixed(1)} м²'
                    : _result.systemType == HeatingSystemType.electricCable
                        ? '${_result.cableLength!.toStringAsFixed(0)} м'
                        : '${_result.filmLinearMeters!.toStringAsFixed(1)} м.п.',
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
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('warmfloor.dimensions.room_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_area.toStringAsFixed(1)} м²',
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
            max: 100,
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
    const accentColor = CalculatorColors.engineering;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('warmfloor.dimensions.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('warmfloor.dimensions.length'),
            value: _length,
            min: 0.5,
            max: 20.0,
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
            label: _loc.translate('warmfloor.dimensions.width'),
            value: _width,
            min: 0.5,
            max: 20.0,
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
              children: [
                Expanded(
                  child: Text(
                    _loc.translate('warmfloor.dimensions.room_area'),
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} м²',
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
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(1)} м',
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
                    _update();
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
                    _update();
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
                              '${_loc.translate(type.descriptionKey)} • ${_constants.getRoomPower(type.key)} Вт/м²',
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
                  _update();
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
            options: const ['50 см', '80 см', '100 см'],
            selectedIndex: _filmWidthIndex,
            onSelect: (index) {
              setState(() {
                _filmWidthIndex = index;
                _update();
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
                _update();
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
          value: '${_result.matArea!.toStringAsFixed(1)} м²',
          subtitle: '${_result.totalPower} Вт',
          icon: Icons.grid_on,
        ));
        break;

      case HeatingSystemType.electricCable:
        materials.addAll([
          MaterialItem(
            name: _loc.translate('warmfloor.materials.heating_cable'),
            value: '${_result.cableLength!.toStringAsFixed(0)} м',
            subtitle: '${_result.totalPower} Вт',
            icon: Icons.cable,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.mounting_tape'),
            value: '${(_result.heatingArea * _constants.montageTapeMultiplier).toStringAsFixed(0)} м',
            icon: Icons.straighten,
          ),
        ]);
        break;

      case HeatingSystemType.infraredFilm:
        materials.addAll([
          MaterialItem(
            name: _loc.translate('warmfloor.materials.ir_film'),
            value: '${_result.filmLinearMeters!.toStringAsFixed(1)} м.п.',
            subtitle: '${_loc.translate('warmfloor.film_width.label')}: ${_result.filmWidthCm} см',
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
            value: '${_result.area.toStringAsFixed(1)} м²',
            icon: Icons.layers,
          ),
        ]);
        break;

      case HeatingSystemType.waterBased:
        materials.addAll([
          MaterialItem(
            name: _loc.translate('warmfloor.materials.pipe_pert'),
            value: '${_result.pipeLength!.toStringAsFixed(0)} м',
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
            value: '${_result.insulationArea!.toStringAsFixed(1)} м²',
            subtitle: '50 мм',
            icon: Icons.layers,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.damper_tape'),
            value: '${(_result.area * _constants.damperTapePerM2).toStringAsFixed(0)} м',
            icon: Icons.straighten,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.brackets'),
            value: '${(_result.heatingArea * _constants.bracketsPerM2).toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.push_pin,
          ),
          MaterialItem(
            name: _loc.translate('warmfloor.materials.screed'),
            value: '${_result.screedVolume!.toStringAsFixed(2)} м³',
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
        value: '${_result.corrugatedTubeLength.toStringAsFixed(1)} м',
        subtitle: _loc.translate('warmfloor.materials.for_sensor'),
        icon: Icons.sensor_door,
      ),
    ]);

    if (_result.insulationArea != null && _result.systemType != HeatingSystemType.waterBased) {
      materials.add(MaterialItem(
        name: _loc.translate('warmfloor.materials.insulation'),
        value: '${_result.insulationArea!.toStringAsFixed(1)} м²',
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
        value: '${(_result.totalPower / 1000).toStringAsFixed(2)} кВт',
        icon: Icons.bolt,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.info.heating_area'),
        value: '${_result.heatingArea.toStringAsFixed(1)} м²',
        subtitle: '${_usefulAreaPercent.round()}% ${_loc.translate('warmfloor.info.heating_area_hint')}',
        icon: Icons.heat_pump,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.info.monthly_consumption'),
        value: '~${monthlyConsumption.toStringAsFixed(0)} кВт⋅ч',
        subtitle: _loc.translate('warmfloor.info.monthly_hint'),
        icon: Icons.calendar_month,
      ),
      MaterialItem(
        name: _loc.translate('warmfloor.info.season_consumption'),
        value: '~${seasonConsumption.toStringAsFixed(0)} кВт⋅ч',
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
