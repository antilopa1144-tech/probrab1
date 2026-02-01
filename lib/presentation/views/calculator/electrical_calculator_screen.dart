import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_electrical_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../widgets/calculator/calculator_result_header.dart';
import '../../widgets/calculator/calculator_scaffold.dart';
import '../../widgets/calculator/mode_selector.dart';
import '../../widgets/calculator/result_card.dart';
import '../../widgets/calculator/tips_card.dart';

/// Режим ввода данных
enum InputMode {
  byArea, // По площади (автоматический расчёт точек)
  byPoints, // По точкам (ручной ввод)
}

/// Тип помещения для расчёта электрики
enum RoomType {
  apartment, // Квартира
  house, // Частный дом
  office, // Офис/коммерческое
}

/// Способ прокладки кабеля
enum WiringMethod {
  hidden, // Скрытая проводка (в штробах)
  open, // Открытая (в кабель-каналах/гофре)
}

/// Результат расчёта электрики
class _ElectricalResult {
  final double area;
  final int rooms;
  final int sockets;
  final int switches;
  final int lights;
  final double cableLight; // Кабель 3×1.5 для освещения
  final double cableSocket; // Кабель 3×2.5 для розеток
  final double cablePower; // Кабель 3×4.0 или 3×6.0 для мощных потребителей
  final double conduitLength;
  final int circuitBreakers;
  final int rcdDevices;
  final int difAutomats; // Дифавтоматы для мощных потребителей
  final int junctionBoxes;
  final int panelModules; // Количество модулей в щитке
  final int powerConsumers; // Мощные потребители
  final bool hasGrounding;

  const _ElectricalResult({
    required this.area,
    required this.rooms,
    required this.sockets,
    required this.switches,
    required this.lights,
    required this.cableLight,
    required this.cableSocket,
    required this.cablePower,
    required this.conduitLength,
    required this.circuitBreakers,
    required this.rcdDevices,
    required this.difAutomats,
    required this.junctionBoxes,
    required this.panelModules,
    required this.powerConsumers,
    required this.hasGrounding,
  });

  factory _ElectricalResult.fromCalculatorResult(Map<String, double> values) {
    return _ElectricalResult(
      area: values['area'] ?? 50.0,
      rooms: (values['rooms'] ?? 2).toInt(),
      sockets: (values['sockets'] ?? 0).toInt(),
      switches: (values['switches'] ?? 0).toInt(),
      lights: (values['lights'] ?? 0).toInt(),
      cableLight: values['cableLight'] ?? 0,
      cableSocket: values['cableSocket'] ?? 0,
      cablePower: values['cablePower'] ?? 0,
      conduitLength: values['conduitLength'] ?? 0,
      circuitBreakers: (values['circuitBreakers'] ?? 0).toInt(),
      rcdDevices: (values['rcdDevices'] ?? 0).toInt(),
      difAutomats: (values['difAutomats'] ?? 0).toInt(),
      junctionBoxes: (values['junctionBoxes'] ?? 0).toInt(),
      panelModules: (values['panelModules'] ?? 0).toInt(),
      powerConsumers: (values['powerConsumers'] ?? 0).toInt(),
      hasGrounding: (values['withGrounding'] ?? 1) == 1,
    );
  }
}

class ElectricalCalculatorScreen extends ConsumerStatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const ElectricalCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  ConsumerState<ElectricalCalculatorScreen> createState() =>
      _ElectricalCalculatorScreenState();
}

class _ElectricalCalculatorScreenState
    extends ConsumerState<ElectricalCalculatorScreen> with ExportableConsumerMixin {
  bool _isDark = false;

  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('electrical.export.subject');

  // Domain layer calculator
  final _calculator = CalculateElectricalV2();

  // Режим ввода
  InputMode _inputMode = InputMode.byArea;

  // Основные параметры (режим "По площади")
  double _area = 50.0;
  int _rooms = 2;

  // Параметры для режима "По точкам"
  int _manualSockets = 20;
  int _manualSwitches = 6;
  int _manualLights = 6;

  // Расширенные параметры
  RoomType _roomType = RoomType.apartment;
  WiringMethod _wiringMethod = WiringMethod.hidden;

  // Мощные потребители (каждый требует отдельной линии)
  bool _hasElectricStove = false; // Электроплита (6 кВт, кабель 3×6)
  bool _hasOven = false; // Духовой шкаф (3.5 кВт, кабель 3×4)
  bool _hasBoiler = false; // Бойлер (2-3 кВт, кабель 3×2.5)
  bool _hasWashingMachine = false; // Стиральная машина (2.5 кВт)
  bool _hasDishwasher = false; // Посудомойка (2 кВт)
  bool _hasConditioner = false; // Кондиционер (2-3 кВт)
  bool _hasWarmFloor = false; // Тёплый пол (отдельная линия)

  // Дополнительные опции
  bool _withConduit = true; // Гофра/кабель-канал
  bool _withGrounding = true; // Заземление

  late _ElectricalResult _result;
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

    if (initial['inputMode'] != null) {
      final mode = initial['inputMode']!.toInt();
      _inputMode = mode == 0 ? InputMode.byArea : InputMode.byPoints;
    }

    if (initial['area'] != null) {
      _area = initial['area']!.clamp(10.0, 500.0);
    }
    if (initial['rooms'] != null) {
      _rooms = initial['rooms']!.round().clamp(1, 20);
    }
    if (initial['manualSockets'] != null) {
      _manualSockets = initial['manualSockets']!.round().clamp(0, 200);
    }
    if (initial['manualSwitches'] != null) {
      _manualSwitches = initial['manualSwitches']!.round().clamp(0, 100);
    }
    if (initial['manualLights'] != null) {
      _manualLights = initial['manualLights']!.round().clamp(0, 100);
    }

    if (initial['roomType'] != null) {
      final type = initial['roomType']!.toInt();
      if (type >= 0 && type < RoomType.values.length) {
        _roomType = RoomType.values[type];
      }
    }

    if (initial['wiringMethod'] != null) {
      final method = initial['wiringMethod']!.toInt();
      if (method >= 0 && method < WiringMethod.values.length) {
        _wiringMethod = WiringMethod.values[method];
      }
    }

    if (initial['hasElectricStove'] != null) _hasElectricStove = initial['hasElectricStove']! > 0;
    if (initial['hasOven'] != null) _hasOven = initial['hasOven']! > 0;
    if (initial['hasBoiler'] != null) _hasBoiler = initial['hasBoiler']! > 0;
    if (initial['hasWashingMachine'] != null) _hasWashingMachine = initial['hasWashingMachine']! > 0;
    if (initial['hasDishwasher'] != null) _hasDishwasher = initial['hasDishwasher']! > 0;
    if (initial['hasConditioner'] != null) _hasConditioner = initial['hasConditioner']! > 0;
    if (initial['hasWarmFloor'] != null) _hasWarmFloor = initial['hasWarmFloor']! > 0;
    if (initial['withConduit'] != null) _withConduit = initial['withConduit']! > 0;
    if (initial['withGrounding'] != null) _withGrounding = initial['withGrounding']! > 0;
  }

  /// Использует domain layer для расчёта
  _ElectricalResult _calculate() {
    final inputs = <String, double>{
      'inputMode': _inputMode.index.toDouble(),
      'area': _area,
      'rooms': _rooms.toDouble(),
      'manualSockets': _manualSockets.toDouble(),
      'manualSwitches': _manualSwitches.toDouble(),
      'manualLights': _manualLights.toDouble(),
      'roomType': _roomType.index.toDouble(),
      'wiringMethod': _wiringMethod.index.toDouble(),
      'hasElectricStove': _hasElectricStove ? 1.0 : 0.0,
      'hasOven': _hasOven ? 1.0 : 0.0,
      'hasBoiler': _hasBoiler ? 1.0 : 0.0,
      'hasWashingMachine': _hasWashingMachine ? 1.0 : 0.0,
      'hasDishwasher': _hasDishwasher ? 1.0 : 0.0,
      'hasConditioner': _hasConditioner ? 1.0 : 0.0,
      'hasWarmFloor': _hasWarmFloor ? 1.0 : 0.0,
      'withConduit': _withConduit ? 1.0 : 0.0,
      'withGrounding': _withGrounding ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _ElectricalResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String? get calculatorId => 'electrical';

  @override
  Map<String, dynamic>? getCurrentInputs() {
    return {
      'inputMode': (_inputMode == InputMode.byArea ? 0 : 1).toDouble(),
      'area': _area,
      'rooms': _rooms.toDouble(),
      'manualSockets': _manualSockets.toDouble(),
      'manualSwitches': _manualSwitches.toDouble(),
      'manualLights': _manualLights.toDouble(),
      'roomType': _roomType.index.toDouble(),
      'wiringMethod': _wiringMethod.index.toDouble(),
      'hasElectricStove': _hasElectricStove ? 1.0 : 0.0,
      'hasOven': _hasOven ? 1.0 : 0.0,
      'hasBoiler': _hasBoiler ? 1.0 : 0.0,
      'hasWashingMachine': _hasWashingMachine ? 1.0 : 0.0,
      'hasDishwasher': _hasDishwasher ? 1.0 : 0.0,
      'hasConditioner': _hasConditioner ? 1.0 : 0.0,
      'hasWarmFloor': _hasWarmFloor ? 1.0 : 0.0,
      'withConduit': _withConduit ? 1.0 : 0.0,
      'withGrounding': _withGrounding ? 1.0 : 0.0,
    };
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln('⚡ ${_loc.translate('electrical.export.title')}');
    buffer.writeln('');
    buffer.writeln('${_loc.translate('electrical.export.params')}:');
    if (_inputMode == InputMode.byArea) {
      buffer.writeln('• ${_loc.translate('electrical.export.area')}: ${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}');
      buffer.writeln('• ${_loc.translate('electrical.export.rooms')}: ${_result.rooms}');
      buffer.writeln('• ${_loc.translate('electrical.export.type')}: ${_getRoomTypeName()}');
    } else {
      buffer.writeln('• ${_loc.translate('electrical.export.mode_manual')}');
    }
    buffer.writeln('• ${_loc.translate('electrical.export.wiring')}: ${_wiringMethod == WiringMethod.hidden ? _loc.translate('electrical.export.wiring_hidden') : _loc.translate('electrical.export.wiring_open')}');

    buffer.writeln('');
    buffer.writeln('${_loc.translate('electrical.export.points_title')}:');
    buffer.writeln('• ${_loc.translate('electrical.export.sockets')}: ${_result.sockets} ${_loc.translate('common.pcs')}');
    buffer.writeln('• ${_loc.translate('electrical.export.switches')}: ${_result.switches} ${_loc.translate('common.pcs')}');
    buffer.writeln('• ${_loc.translate('electrical.export.lights')}: ${_result.lights} ${_loc.translate('common.pcs')}');
    if (_result.powerConsumers > 0) {
      buffer.writeln('• ${_loc.translate('electrical.export.power_consumers')}: ${_result.powerConsumers} ${_loc.translate('common.pcs')}');
    }

    buffer.writeln('');
    buffer.writeln('${_loc.translate('electrical.export.cable_title')}:');
    buffer.writeln('• ${_loc.translate('electrical.export.cable_light')}: ${_result.cableLight.toStringAsFixed(0)} ${_loc.translate('common.meters')}');
    buffer.writeln('• ${_loc.translate('electrical.export.cable_socket')}: ${_result.cableSocket.toStringAsFixed(0)} ${_loc.translate('common.meters')}');
    if (_result.cablePower > 0) {
      buffer.writeln('• ${_loc.translate('electrical.export.cable_power')}: ${_result.cablePower.toStringAsFixed(0)} ${_loc.translate('common.meters')}');
    }
    if (_result.conduitLength > 0) {
      buffer.writeln('• ${_wiringMethod == WiringMethod.hidden ? _loc.translate('electrical.export.conduit_hidden') : _loc.translate('electrical.export.conduit_open')}: ${_result.conduitLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}');
    }

    buffer.writeln('');
    buffer.writeln('${_loc.translate('electrical.export.panel_title')} (${_result.panelModules} ${_loc.translate('electrical.export.panel_modules')}):');
    buffer.writeln('• ${_loc.translate('electrical.export.breakers')}: ${_result.circuitBreakers} ${_loc.translate('common.pcs')}');
    buffer.writeln('• ${_loc.translate('electrical.export.rcd')}: ${_result.rcdDevices} ${_loc.translate('common.pcs')}');
    if (_result.difAutomats > 0) {
      buffer.writeln('• ${_loc.translate('electrical.export.difautomats')}: ${_result.difAutomats} ${_loc.translate('common.pcs')}');
    }
    buffer.writeln('• ${_loc.translate('electrical.export.junction_boxes')}: ${_result.junctionBoxes} ${_loc.translate('common.pcs')}');

    return buffer.toString();
  }

  String _getRoomTypeName() {
    switch (_roomType) {
      case RoomType.apartment:
        return _loc.translate('electrical.room_type.apartment');
      case RoomType.house:
        return _loc.translate('electrical.room_type.house');
      case RoomType.office:
        return _loc.translate('electrical.room_type.office');
    }
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('calculator.engineering_electrics.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('electrical.header.sockets'),
            value: '${_result.sockets}',
            icon: Icons.power,
          ),
          ResultItem(
            label: _loc.translate('electrical.header.cable'),
            value: '${(_result.cableLight + _result.cableSocket + _result.cablePower).toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.cable,
          ),
          ResultItem(
            label: _loc.translate('electrical.header.panel'),
            value: '${_result.panelModules} ${_loc.translate('electrical.header.modules')}',
            icon: Icons.dashboard,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        if (_inputMode == InputMode.byArea) ...[
          _buildRoomTypeSelector(),
          const SizedBox(height: 16),
          _buildAreaCard(),
        ] else ...[
          _buildManualInputCard(),
        ],
        const SizedBox(height: 16),
        _buildWiringMethodSelector(),
        const SizedBox(height: 16),
        _buildPowerConsumersCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildPointsCard(),
        const SizedBox(height: 16),
        _buildCableCard(),
        const SizedBox(height: 16),
        _buildEquipmentCard(),
        const SizedBox(height: 16),
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
            _loc.translate('electrical.mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('electrical.mode.by_area'),
              _loc.translate('electrical.mode.by_points'),
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
          const SizedBox(height: 8),
          Text(
            _inputMode == InputMode.byArea
                ? _loc.translate('electrical.mode.by_area_hint')
                : _loc.translate('electrical.mode.by_points_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('electrical.room_type.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('electrical.room_type.apartment'),
              _loc.translate('electrical.room_type.house'),
              _loc.translate('electrical.room_type.office'),
            ],
            selectedIndex: _roomType.index,
            onSelect: (index) {
              setState(() {
                _roomType = RoomType.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _getRoomTypeDescription(),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoomTypeDescription() {
    switch (_roomType) {
      case RoomType.apartment:
        return _loc.translate('electrical.room_type.apartment_desc');
      case RoomType.house:
        return _loc.translate('electrical.room_type.house_desc');
      case RoomType.office:
        return _loc.translate('electrical.room_type.office_desc');
    }
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('electrical.area.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          // Площадь
          _buildSliderRow(
            label: _loc.translate('electrical.area.total_area'),
            value: _area,
            min: 10,
            max: 300,
            divisions: 29,
            suffix: _loc.translate('common.sqm'),
            onChanged: (v) {
              setState(() {
                _area = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 20),
          // Комнаты
          _buildSliderRow(
            label: _loc.translate('electrical.area.rooms_count'),
            value: _rooms.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            suffix: '',
            isInteger: true,
            onChanged: (v) {
              setState(() {
                _rooms = v.round();
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('electrical.area.rooms_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualInputCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('electrical.points.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: _loc.translate('electrical.points.sockets'),
            value: _manualSockets.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            suffix: _loc.translate('common.pcs'),
            isInteger: true,
            onChanged: (v) {
              setState(() {
                _manualSockets = v.round();
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: _loc.translate('electrical.points.switches'),
            value: _manualSwitches.toDouble(),
            min: 2,
            max: 30,
            divisions: 14,
            suffix: _loc.translate('common.pcs'),
            isInteger: true,
            onChanged: (v) {
              setState(() {
                _manualSwitches = v.round();
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: _loc.translate('electrical.points.lights'),
            value: _manualLights.toDouble(),
            min: 2,
            max: 50,
            divisions: 24,
            suffix: _loc.translate('common.pcs'),
            isInteger: true,
            onChanged: (v) {
              setState(() {
                _manualLights = v.round();
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
    required Color accentColor,
    bool isInteger = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
            ),
            Text(
              isInteger
                  ? '${value.round()}${suffix.isNotEmpty ? ' $suffix' : ''}'
                  : '${value.toStringAsFixed(0)} $suffix',
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
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildWiringMethodSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('electrical.wiring.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('electrical.wiring.hidden'),
              _loc.translate('electrical.wiring.open'),
            ],
            selectedIndex: _wiringMethod.index,
            onSelect: (index) {
              setState(() {
                _wiringMethod = WiringMethod.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _wiringMethod == WiringMethod.hidden
                ? _loc.translate('electrical.wiring.hidden_desc')
                : _loc.translate('electrical.wiring.open_desc'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerConsumersCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: accentColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _loc.translate('electrical.consumers.title'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _loc.translate('electrical.consumers.subtitle'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildConsumerChip(
            label: _loc.translate('electrical.consumers.electric_stove'),
            subtitle: _loc.translate('electrical.consumers.electric_stove_desc'),
            value: _hasElectricStove,
            onChanged: (v) {
              setState(() {
                _hasElectricStove = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          _buildConsumerChip(
            label: _loc.translate('electrical.consumers.oven'),
            subtitle: _loc.translate('electrical.consumers.oven_desc'),
            value: _hasOven,
            onChanged: (v) {
              setState(() {
                _hasOven = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          _buildConsumerChip(
            label: _loc.translate('electrical.consumers.boiler'),
            subtitle: _loc.translate('electrical.consumers.boiler_desc'),
            value: _hasBoiler,
            onChanged: (v) {
              setState(() {
                _hasBoiler = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          _buildConsumerChip(
            label: _loc.translate('electrical.consumers.washing_machine'),
            subtitle: _loc.translate('electrical.consumers.washing_machine_desc'),
            value: _hasWashingMachine,
            onChanged: (v) {
              setState(() {
                _hasWashingMachine = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          _buildConsumerChip(
            label: _loc.translate('electrical.consumers.dishwasher'),
            subtitle: _loc.translate('electrical.consumers.dishwasher_desc'),
            value: _hasDishwasher,
            onChanged: (v) {
              setState(() {
                _hasDishwasher = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          _buildConsumerChip(
            label: _loc.translate('electrical.consumers.conditioner'),
            subtitle: _loc.translate('electrical.consumers.conditioner_desc'),
            value: _hasConditioner,
            onChanged: (v) {
              setState(() {
                _hasConditioner = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          _buildConsumerChip(
            label: _loc.translate('electrical.consumers.warm_floor'),
            subtitle: _loc.translate('electrical.consumers.warm_floor_desc'),
            value: _hasWarmFloor,
            onChanged: (v) {
              setState(() {
                _hasWarmFloor = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerChip({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: value ? accentColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value ? accentColor : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.getTextPrimary(_isDark),
                        fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: CalculatorDesignSystem.bodySmall.copyWith(
                        color: CalculatorColors.getTextSecondary(_isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('electrical.options.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          _buildSwitch(
            title: _wiringMethod == WiringMethod.hidden
                ? _loc.translate('electrical.options.conduit_hidden')
                : _loc.translate('electrical.options.conduit_open'),
            subtitle: _wiringMethod == WiringMethod.hidden
                ? _loc.translate('electrical.options.conduit_hidden_desc')
                : _loc.translate('electrical.options.conduit_open_desc'),
            value: _withConduit,
            onChanged: (value) {
              setState(() {
                _withConduit = value;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          _buildSwitch(
            title: _loc.translate('electrical.options.grounding'),
            subtitle: _loc.translate('electrical.options.grounding_desc'),
            value: _withGrounding,
            onChanged: (value) {
              setState(() {
                _withGrounding = value;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color accentColor,
  }) {
    return SwitchListTile.adaptive(
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
        title,
        style: CalculatorDesignSystem.bodyMedium.copyWith(
          color: CalculatorColors.getTextPrimary(_isDark),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: CalculatorDesignSystem.bodySmall.copyWith(
          color: CalculatorColors.getTextSecondary(_isDark),
        ),
      ),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildPointsCard() {
    const accentColor = CalculatorColors.interior;
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('electrical.results.sockets'),
        value: '${_result.sockets} ${_loc.translate('common.pcs')}',
        subtitle: _inputMode == InputMode.byArea
            ? _loc.translate('electrical.results.sockets_hint_auto')
            : _loc.translate('electrical.results.sockets_hint_manual'),
        icon: Icons.power,
      ),
      MaterialItem(
        name: _loc.translate('electrical.results.switches'),
        value: '${_result.switches} ${_loc.translate('common.pcs')}',
        subtitle: _inputMode == InputMode.byArea
            ? _loc.translate('electrical.results.switches_hint_auto')
            : _loc.translate('electrical.results.switches_hint_manual'),
        icon: Icons.toggle_off,
      ),
      MaterialItem(
        name: _loc.translate('electrical.results.lights'),
        value: '${_result.lights} ${_loc.translate('common.pcs')}',
        subtitle: _inputMode == InputMode.byArea
            ? _loc.translate('electrical.results.lights_hint_auto')
            : _loc.translate('electrical.results.lights_hint_manual'),
        icon: Icons.lightbulb_outline,
      ),
      if (_result.powerConsumers > 0)
        MaterialItem(
          name: _loc.translate('electrical.results.power_consumers'),
          value: '${_result.powerConsumers} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('electrical.results.power_consumers_hint'),
          icon: Icons.bolt,
        ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('electrical.results.points_title'),
      titleIcon: Icons.electrical_services,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildCableCard() {
    const accentColor = CalculatorColors.interior;
    final totalCable = _result.cableLight + _result.cableSocket + _result.cablePower;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('electrical.cable.vvg_1_5'),
        value: '${_result.cableLight.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('electrical.cable.vvg_1_5_desc'),
        icon: Icons.cable,
      ),
      MaterialItem(
        name: _loc.translate('electrical.cable.vvg_2_5'),
        value: '${_result.cableSocket.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('electrical.cable.vvg_2_5_desc'),
        icon: Icons.cable,
      ),
      if (_result.cablePower > 0)
        MaterialItem(
          name: _loc.translate('electrical.cable.vvg_4_6'),
          value: '${_result.cablePower.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
          subtitle: _loc.translate('electrical.cable.vvg_4_6_desc'),
          icon: Icons.cable,
        ),
      if (_result.conduitLength > 0)
        MaterialItem(
          name: _wiringMethod == WiringMethod.hidden
              ? _loc.translate('electrical.cable.conduit_hidden')
              : _loc.translate('electrical.cable.conduit_open'),
          value: '${_result.conduitLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
          subtitle: _loc.translate('electrical.cable.conduit_desc'),
          icon: Icons.linear_scale,
        ),
      MaterialItem(
        name: _loc.translate('electrical.cable.junction_boxes'),
        value: '${_result.junctionBoxes} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('electrical.cable.junction_boxes_desc'),
        icon: Icons.check_box_outline_blank,
      ),
      MaterialItem(
        name: _loc.translate('electrical.cable.total'),
        value: '${totalCable.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('electrical.cable.total_desc'),
        icon: Icons.summarize,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('electrical.cable.title'),
      titleIcon: Icons.inventory_2,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildEquipmentCard() {
    const accentColor = CalculatorColors.interior;
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('electrical.equipment.panel'),
        value: _loc.translate('electrical.equipment.from_modules').replaceFirst('{0}', '${_result.panelModules}'),
        subtitle: _loc.translate('electrical.equipment.panel_hint'),
        icon: Icons.dashboard,
      ),
      MaterialItem(
        name: _loc.translate('electrical.equipment.breakers'),
        value: '${_result.circuitBreakers} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('electrical.equipment.breakers_desc'),
        icon: Icons.toggle_on,
      ),
      MaterialItem(
        name: _loc.translate('electrical.equipment.rcd'),
        value: '${_result.rcdDevices} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('electrical.equipment.rcd_desc'),
        icon: Icons.shield,
      ),
      if (_result.difAutomats > 0)
        MaterialItem(
          name: _loc.translate('electrical.equipment.difautomat'),
          value: '${_result.difAutomats} ${_loc.translate('common.pcs')}',
          subtitle: _loc.translate('electrical.equipment.difautomat_desc'),
          icon: Icons.security,
        ),
      if (_result.hasGrounding)
        MaterialItem(
          name: _loc.translate('electrical.equipment.grounding'),
          value: _loc.translate('electrical.equipment.grounding_value'),
          subtitle: _loc.translate('electrical.equipment.grounding_desc'),
          icon: Icons.electric_bolt,
        ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('electrical.equipment.title'),
      titleIcon: Icons.electrical_services,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.interior;
    final tips = <String>[
      _loc.translate('hint.engineering.raboty_dolzhen_vypolnyat_kvalifitsirovannyy'),
      _loc.translate('hint.engineering.ispolzuyte_kabel_secheniem_ne'),
      _loc.translate('hint.engineering.ustanovite_uzo_dlya_zaschity'),
      _loc.translate('hint.engineering.proverte_vse_soedineniya_pered'),
    ];

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
