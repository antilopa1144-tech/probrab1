import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_result_header.dart';
import '../../widgets/calculator/calculator_scaffold.dart';
import '../../widgets/calculator/mode_selector.dart';
import '../../widgets/calculator/result_card.dart';
import '../../widgets/existing/hint_card.dart';

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

/// Вспомогательный класс для работы с константами калькулятора электрики
class _ElectricalConstants {
  final CalculatorConstants? _data;

  const _ElectricalConstants([this._data]);

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

  // Room type multipliers
  double getRoomMultiplier(RoomType type) {
    final defaults = {'apartment': 1.0, 'house': 1.2, 'office': 1.5};
    return _getDouble('room_type_multipliers', type.name, defaults[type.name]!);
  }

  // Socket calculation
  int get socketAreaDivisor => _getInt('socket_calculation', 'area_divisor', 4);
  int get socketMinPerRoom => _getInt('socket_calculation', 'min_per_room', 3);
  int get socketKitchenAdditional => _getInt('socket_calculation', 'kitchen_additional', 4);

  // Switch calculation
  double get switchPerRoom => _getDouble('switch_calculation', 'per_room', 1.5);
  int get switchPerAreaDivisor => _getInt('switch_calculation', 'per_area_divisor', 20);

  // Light calculation
  int get lightPerAreaDivisor => _getInt('light_calculation', 'per_area_divisor', 6);
  int get lightPerRoom => _getInt('light_calculation', 'per_room', 1);

  // Cable lengths
  double getCablePerLight(WiringMethod method) =>
      method == WiringMethod.hidden
          ? _getDouble('cable_lengths_hidden', 'light', 5.0)
          : _getDouble('cable_lengths_open', 'light', 4.0);

  double getCablePerSocket(WiringMethod method) =>
      method == WiringMethod.hidden
          ? _getDouble('cable_lengths_hidden', 'socket', 4.5)
          : _getDouble('cable_lengths_open', 'socket', 3.5);

  double getCablePerSwitch(WiringMethod method) =>
      method == WiringMethod.hidden
          ? _getDouble('cable_lengths_hidden', 'switch', 4.0)
          : _getDouble('cable_lengths_open', 'switch', 3.0);

  // Light and socket groups
  int get maxLightsPerGroup => _getInt('light_groups', 'max_lights_per_group', 8);
  double get cablePerLightGroup => _getDouble('light_groups', 'cable_per_group', 10.0);
  int get maxSocketsPerGroup => _getInt('socket_groups', 'max_sockets_per_group', 6);
  double get cablePerSocketGroup => _getDouble('socket_groups', 'cable_per_group', 10.0);

  // Cable margins
  double get cableMargin => _getDouble('cable_margins', 'standard_margin', 15.0);
  double get switchCableFactor => _getDouble('cable_margins', 'switch_cable_factor', 0.5);

  // Power consumers cable
  double get electricStoveCable => _getDouble('power_consumers_cable', 'electric_stove', 12.0);
  double get ovenCable => _getDouble('power_consumers_cable', 'oven', 10.0);
  double get boilerCable => _getDouble('power_consumers_cable', 'boiler', 10.0);
  double get washingMachineCable => _getDouble('power_consumers_cable', 'washing_machine', 8.0);
  double get dishwasherCable => _getDouble('power_consumers_cable', 'dishwasher', 8.0);
  double get conditionerCable => _getDouble('power_consumers_cable', 'conditioner', 12.0);
  double get warmFloorCable => _getDouble('power_consumers_cable', 'warm_floor', 10.0);

  // Conduit factors
  double getConduitFactor(WiringMethod method) =>
      method == WiringMethod.hidden
          ? _getDouble('conduit_factors', 'hidden_wiring', 0.85)
          : _getDouble('conduit_factors', 'open_wiring', 1.0);

  // RCD calculation
  int get socketGroupsPerRcd => _getInt('rcd_calculation', 'socket_groups_per_rcd', 2);
  int get fireProtectionRcd => _getInt('rcd_calculation', 'fire_protection_rcd', 1);

  // Junction boxes
  double get boxesPerRoom => _getDouble('junction_boxes', 'per_room', 1.5);
  int get boxesPerAreaDivisor => _getInt('junction_boxes', 'per_area_divisor', 25);
  int get boxesPerPointsDivisor => _getInt('junction_boxes', 'per_points_divisor', 8);

  // Panel modules
  int get basePanelModules => _getInt('panel_modules', 'base_modules', 4);
  int get breakerModules => _getInt('panel_modules', 'breaker_modules', 1);
  int get rcdModules => _getInt('panel_modules', 'rcd_modules', 2);
  int get difautomatModules => _getInt('panel_modules', 'difautomat_modules', 2);
  double get panelReserveFactor => _getDouble('panel_modules', 'reserve_factor', 1.2);
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
}

class ElectricalCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const ElectricalCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<ElectricalCalculatorScreen> createState() =>
      _ElectricalCalculatorScreenState();
}

class _ElectricalCalculatorScreenState
    extends State<ElectricalCalculatorScreen> {
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

  // Константы калькулятора (null = используются hardcoded defaults)
  late final _ElectricalConstants _constants;

  late _ElectricalResult _result;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    // TODO: Загрузить константы из provider когда понадобится Remote Config
    // final constants = await ref.read(calculatorConstantsProvider('electrical').future);
    _constants = const _ElectricalConstants(null); // Используем defaults пока
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    if (initial['area'] != null) {
      _area = initial['area']!.clamp(10.0, 500.0);
    }
    if (initial['rooms'] != null) {
      _rooms = initial['rooms']!.round().clamp(1, 20);
    }
  }

  _ElectricalResult _calculate() {
    int sockets;
    int switches;
    int lights;

    if (_inputMode == InputMode.byArea) {
      // === АВТОМАТИЧЕСКИЙ РАСЧЁТ ПО ПЛОЩАДИ ===

      // Коэффициент для типа помещения
      final socketMultiplier = _constants.getRoomMultiplier(_roomType);

      // Розетки по СП 256.1325800.2016:
      // - Жилые комнаты: 1 розетка на 4 м², но не менее 3 на комнату
      // - Кухня: минимум 4 розетки
      // - Коридор: 1 розетка на 10 м²
      // Упрощённая формула: площадь / divisor + дополнительные на кухню/ванную
      final socketsBase = (_area / _constants.socketAreaDivisor * socketMultiplier).ceil();
      final socketsMin = _rooms * _constants.socketMinPerRoom; // Минимум на комнату
      final socketsKitchen = _constants.socketKitchenAdditional; // Дополнительные для кухни
      sockets = max(socketsBase, socketsMin) + socketsKitchen;

      // Выключатели:
      // - Одноклавишные: 1 на комнату (основной свет)
      // - Двухклавишные: для комнат > 12 м²
      // - Проходные: для коридоров и больших комнат
      // Упрощённо: per_room на комнату + 1 на каждые per_area_divisor м²
      switches = (_rooms * _constants.switchPerRoom + _area / _constants.switchPerAreaDivisor).ceil();

      // Светильники:
      // - Норма освещённости жилых помещений: 150-300 лк
      // - 1 точка на 5-7 м² для общего освещения
      // - + дополнительные точки для зонального света
      lights = (_area / _constants.lightPerAreaDivisor).ceil() + (_rooms * _constants.lightPerRoom);
    } else {
      // === РУЧНОЙ ВВОД ===
      sockets = _manualSockets;
      switches = _manualSwitches;
      lights = _manualLights;
    }

    // === РАСЧЁТ МОЩНЫХ ПОТРЕБИТЕЛЕЙ ===
    int powerConsumers = 0;
    if (_hasElectricStove) powerConsumers++;
    if (_hasOven) powerConsumers++;
    if (_hasBoiler) powerConsumers++;
    if (_hasWashingMachine) powerConsumers++;
    if (_hasDishwasher) powerConsumers++;
    if (_hasConditioner) powerConsumers++;
    if (_hasWarmFloor) powerConsumers++;

    // === РАСЧЁТ КАБЕЛЯ ===
    // Учитываем высоту потолка (2.7м) + спуски/подъёмы + горизонтальные участки

    final cablePerLight = _constants.getCablePerLight(_wiringMethod);
    final cablePerSocket = _constants.getCablePerSocket(_wiringMethod);
    final cablePerSwitch = _constants.getCablePerSwitch(_wiringMethod);

    // Кабель ВВГнг-LS 3×1.5 для освещения
    // Группы освещения: 1 группа на 2-3 комнаты (до 10 точек, макс 2.3 кВт)
    final lightGroups = (lights / _constants.maxLightsPerGroup).ceil();
    final cableMarginMultiplier = 1 + (_constants.cableMargin / 100); // Преобразуем % в множитель
    final cableLight = (lights * cablePerLight + lightGroups * _constants.cablePerLightGroup) * cableMarginMultiplier;

    // Кабель ВВГнг-LS 3×2.5 для розеток
    // Группы розеток: макс N розеток на группу (до 3.5 кВт)
    final socketGroups = (sockets / _constants.maxSocketsPerGroup).ceil();
    final cableSocket = (sockets * cablePerSocket + socketGroups * _constants.cablePerSocketGroup) * cableMarginMultiplier;

    // Кабель для выключателей (учтён в освещении, но добавляем на спуски)
    final cableSwitches = switches * cablePerSwitch * _constants.switchCableFactor; // Часть уже в освещении

    // Кабель 3×4.0 и 3×6.0 для мощных потребителей
    // Каждый потребитель: ~8-12 м от щитка
    double cablePower = 0;
    if (_hasElectricStove) cablePower += _constants.electricStoveCable; // 3×6.0
    if (_hasOven) cablePower += _constants.ovenCable; // 3×4.0
    if (_hasBoiler) cablePower += _constants.boilerCable;
    if (_hasWashingMachine) cablePower += _constants.washingMachineCable;
    if (_hasDishwasher) cablePower += _constants.dishwasherCable;
    if (_hasConditioner) cablePower += _constants.conditionerCable; // Может быть далеко
    if (_hasWarmFloor) cablePower += _constants.warmFloorCable; // Кабель до терморегулятора
    cablePower *= cableMarginMultiplier; // +margin% запас

    // Общая длина кабеля для гофры
    final totalCable = cableLight + cableSocket + cableSwitches + cablePower;

    // Гофра: зависит от типа прокладки
    double conduitLength = 0;
    if (_withConduit) {
      conduitLength = totalCable * _constants.getConduitFactor(_wiringMethod);
    }

    // === РАСЧЁТ АВТОМАТИКИ ===

    // Группы автоматов:
    // - Освещение: C10A (1 на 2-3 комнаты)
    // - Розетки: C16A (1 группа на 6-8 розеток)
    // - Мощные потребители: C25A или C32A (отдельная линия каждому)
    final circuitBreakers = lightGroups + socketGroups;

    // Дифавтоматы для мощных потребителей (защита + УЗО в одном)
    final difAutomats = powerConsumers;

    // УЗО 30мА для групп розеток (N УЗО на группы)
    // + противопожарное УЗО 100-300мА на вводе
    final rcdDevices = (socketGroups / _constants.socketGroupsPerRcd).ceil() + _constants.fireProtectionRcd;

    // Распределительные коробки:
    // - per_room на комнату для разводки
    // - Дополнительные для сложных схем
    final junctionBoxes = _inputMode == InputMode.byArea
        ? (_rooms * _constants.boxesPerRoom + _area / _constants.boxesPerAreaDivisor).ceil()
        : ((sockets + switches) / _constants.boxesPerPointsDivisor).ceil();

    // Модули в щитке:
    // - Вводной автомат + противопожарное УЗО + реле напряжения: base_modules
    // - Автоматы: breaker_modules модуль каждый
    // - УЗО: rcd_modules модуля каждый
    // - Дифавтоматы: difautomat_modules модуля каждый
    // + reserve_factor% резерв
    final panelModules = ((_constants.basePanelModules +
            circuitBreakers * _constants.breakerModules +
            rcdDevices * _constants.rcdModules +
            difAutomats * _constants.difautomatModules) *
        _constants.panelReserveFactor).ceil();

    return _ElectricalResult(
      area: _area,
      rooms: _rooms,
      sockets: sockets,
      switches: switches,
      lights: lights,
      cableLight: cableLight + cableSwitches,
      cableSocket: cableSocket,
      cablePower: cablePower,
      conduitLength: conduitLength,
      circuitBreakers: circuitBreakers,
      rcdDevices: rcdDevices,
      difAutomats: difAutomats,
      junctionBoxes: junctionBoxes,
      panelModules: panelModules,
      powerConsumers: powerConsumers,
      hasGrounding: _withGrounding,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _exportText() {
    final buffer = StringBuffer();
    buffer.writeln('⚡ Электрика — расчёт');
    buffer.writeln('');
    buffer.writeln('Параметры:');
    if (_inputMode == InputMode.byArea) {
      buffer.writeln('• Площадь: ${_result.area.toStringAsFixed(0)} м²');
      buffer.writeln('• Комнат: ${_result.rooms}');
      buffer.writeln('• Тип: ${_getRoomTypeName()}');
    } else {
      buffer.writeln('• Режим: ручной ввод точек');
    }
    buffer.writeln('• Проводка: ${_wiringMethod == WiringMethod.hidden ? 'Скрытая' : 'Открытая'}');

    buffer.writeln('');
    buffer.writeln('Точки подключения:');
    buffer.writeln('• Розетки: ${_result.sockets} шт');
    buffer.writeln('• Выключатели: ${_result.switches} шт');
    buffer.writeln('• Светильники: ${_result.lights} шт');
    if (_result.powerConsumers > 0) {
      buffer.writeln('• Мощные потребители: ${_result.powerConsumers} шт');
    }

    buffer.writeln('');
    buffer.writeln('Кабель:');
    buffer.writeln('• ВВГнг-LS 3×1.5 (свет): ${_result.cableLight.toStringAsFixed(0)} м');
    buffer.writeln('• ВВГнг-LS 3×2.5 (розетки): ${_result.cableSocket.toStringAsFixed(0)} м');
    if (_result.cablePower > 0) {
      buffer.writeln('• ВВГнг-LS 3×4/6 (мощные): ${_result.cablePower.toStringAsFixed(0)} м');
    }
    if (_result.conduitLength > 0) {
      buffer.writeln('• ${_wiringMethod == WiringMethod.hidden ? 'Гофра ПВХ' : 'Кабель-канал'}: ${_result.conduitLength.toStringAsFixed(0)} м');
    }

    buffer.writeln('');
    buffer.writeln('Щиток (${_result.panelModules} модулей):');
    buffer.writeln('• Автоматы: ${_result.circuitBreakers} шт');
    buffer.writeln('• УЗО: ${_result.rcdDevices} шт');
    if (_result.difAutomats > 0) {
      buffer.writeln('• Дифавтоматы: ${_result.difAutomats} шт');
    }
    buffer.writeln('• Распред. коробки: ${_result.junctionBoxes} шт');

    return buffer.toString();
  }

  String _getRoomTypeName() {
    switch (_roomType) {
      case RoomType.apartment:
        return 'Квартира';
      case RoomType.house:
        return 'Дом';
      case RoomType.office:
        return 'Офис';
    }
  }

  void _share() {
    SharePlus.instance.share(
        ShareParams(text: _exportText(), subject: 'Расчёт электрики'));
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _exportText()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('calculator.engineering_electrics.title'),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: _loc.translate('common.copy'),
          onPressed: _copy,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: _loc.translate('common.share'),
          onPressed: _share,
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: 'РОЗЕТОК',
            value: '${_result.sockets}',
            icon: Icons.power,
          ),
          ResultItem(
            label: 'КАБЕЛЬ',
            value: '${(_result.cableLight + _result.cableSocket + _result.cablePower).toStringAsFixed(0)} м',
            icon: Icons.cable,
          ),
          ResultItem(
            label: 'ЩИТОК',
            value: '${_result.panelModules} мод',
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
        _buildTipsSection(),
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
            'Режим расчёта',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: const ['По площади', 'По точкам'],
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
                ? 'Автоматический расчёт количества точек по нормативам'
                : 'Укажите количество розеток, выключателей и светильников вручную',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
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
            'Тип помещения',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: const ['Квартира', 'Дом', 'Офис'],
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
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _getRoomTypeDescription() {
    switch (_roomType) {
      case RoomType.apartment:
        return 'Стандартный расчёт по СП 256.1325800.2016';
      case RoomType.house:
        return 'Увеличенный расчёт (+20% точек)';
      case RoomType.office:
        return 'Максимум розеток для рабочих мест (+50%)';
    }
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Параметры помещения',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Площадь
          _buildSliderRow(
            label: 'Общая площадь',
            value: _area,
            min: 10,
            max: 300,
            divisions: 29,
            suffix: 'м²',
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
            label: 'Количество комнат',
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
            'Включая кухню, санузлы и коридоры',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
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
            'Количество точек',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSliderRow(
            label: 'Розетки',
            value: _manualSockets.toDouble(),
            min: 5,
            max: 100,
            divisions: 19,
            suffix: 'шт',
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
            label: 'Выключатели',
            value: _manualSwitches.toDouble(),
            min: 2,
            max: 30,
            divisions: 14,
            suffix: 'шт',
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
            label: 'Светильники',
            value: _manualLights.toDouble(),
            min: 2,
            max: 50,
            divisions: 24,
            suffix: 'шт',
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
                  color: CalculatorColors.textSecondary,
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
            'Способ прокладки',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: const ['Скрытая', 'Открытая'],
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
                ? 'В штробах под штукатуркой — стандарт для квартир и домов'
                : 'В кабель-каналах по стенам — быстрый монтаж, легко обслуживать',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
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
                'Мощные потребители',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Каждый требует отдельной линии с защитой',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildConsumerChip(
            label: 'Электроплита',
            subtitle: '6 кВт · кабель 3×6',
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
            label: 'Духовой шкаф',
            subtitle: '3.5 кВт · кабель 3×4',
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
            label: 'Бойлер',
            subtitle: '2-3 кВт · кабель 3×2.5',
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
            label: 'Стиральная машина',
            subtitle: '2.5 кВт · отдельная линия',
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
            label: 'Посудомоечная машина',
            subtitle: '2 кВт · отдельная линия',
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
            label: 'Кондиционер',
            subtitle: '2-3 кВт · кабель 3×2.5',
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
            label: 'Тёплый пол',
            subtitle: 'Отдельная группа',
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
                        color: CalculatorColors.textPrimary,
                        fontWeight: value ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: CalculatorDesignSystem.bodySmall.copyWith(
                        color: CalculatorColors.textSecondary,
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
            'Дополнительно',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildSwitch(
            title: _wiringMethod == WiringMethod.hidden
                ? 'Гофра ПВХ d16-20'
                : 'Кабель-канал',
            subtitle: _wiringMethod == WiringMethod.hidden
                ? 'Защита кабеля в штробах (рекомендуется ПУЭ)'
                : 'Пластиковый короб для открытой проводки',
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
            title: 'Заземление',
            subtitle: 'Шина PE + контур (обязательно по ПУЭ)',
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
            : CalculatorColors.textSecondary.withValues(alpha: 0.2),
      ),
      thumbColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? accentColor
            : CalculatorColors.textSecondary,
      ),
      title: Text(
        title,
        style: CalculatorDesignSystem.bodyMedium.copyWith(
          color: CalculatorColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: CalculatorDesignSystem.bodySmall.copyWith(
          color: CalculatorColors.textSecondary,
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
        name: 'Розетки',
        value: '${_result.sockets} шт',
        subtitle: _inputMode == InputMode.byArea
            ? '1 на 4 м² + кухня'
            : 'Указано вручную',
        icon: Icons.power,
      ),
      MaterialItem(
        name: 'Выключатели',
        value: '${_result.switches} шт',
        subtitle: _inputMode == InputMode.byArea
            ? '1.5 на комнату'
            : 'Указано вручную',
        icon: Icons.toggle_off,
      ),
      MaterialItem(
        name: 'Светильники',
        value: '${_result.lights} шт',
        subtitle: _inputMode == InputMode.byArea
            ? '1 на 6 м²'
            : 'Указано вручную',
        icon: Icons.lightbulb_outline,
      ),
      if (_result.powerConsumers > 0)
        MaterialItem(
          name: 'Мощные потребители',
          value: '${_result.powerConsumers} шт',
          subtitle: 'Отдельные линии',
          icon: Icons.bolt,
        ),
    ];

    return MaterialsCardModern(
      title: 'Точки подключения',
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
        name: 'ВВГнг-LS 3×1.5',
        value: '${_result.cableLight.toStringAsFixed(0)} м',
        subtitle: 'Освещение (до 2.3 кВт)',
        icon: Icons.cable,
      ),
      MaterialItem(
        name: 'ВВГнг-LS 3×2.5',
        value: '${_result.cableSocket.toStringAsFixed(0)} м',
        subtitle: 'Розетки (до 3.5 кВт)',
        icon: Icons.cable,
      ),
      if (_result.cablePower > 0)
        MaterialItem(
          name: 'ВВГнг-LS 3×4 / 3×6',
          value: '${_result.cablePower.toStringAsFixed(0)} м',
          subtitle: 'Мощные потребители',
          icon: Icons.cable,
        ),
      if (_result.conduitLength > 0)
        MaterialItem(
          name: _wiringMethod == WiringMethod.hidden
              ? 'Гофра ПВХ d16-20'
              : 'Кабель-канал',
          value: '${_result.conduitLength.toStringAsFixed(0)} м',
          subtitle: 'Защита кабеля',
          icon: Icons.linear_scale,
        ),
      MaterialItem(
        name: 'Распред. коробки',
        value: '${_result.junctionBoxes} шт',
        subtitle: 'd80 мм',
        icon: Icons.check_box_outline_blank,
      ),
      MaterialItem(
        name: 'Всего кабеля',
        value: '${totalCable.toStringAsFixed(0)} м',
        subtitle: 'Общая длина',
        icon: Icons.summarize,
      ),
    ];

    return MaterialsCardModern(
      title: 'Кабель и материалы',
      titleIcon: Icons.inventory_2,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildEquipmentCard() {
    const accentColor = CalculatorColors.interior;
    final items = <MaterialItem>[
      MaterialItem(
        name: 'Электрощит',
        value: 'от ${_result.panelModules} мод',
        subtitle: 'С запасом +4 модуля',
        icon: Icons.dashboard,
      ),
      MaterialItem(
        name: 'Автоматы C10-C16',
        value: '${_result.circuitBreakers} шт',
        subtitle: 'Свет + розетки',
        icon: Icons.toggle_on,
      ),
      MaterialItem(
        name: 'УЗО 30мА',
        value: '${_result.rcdDevices} шт',
        subtitle: 'Включая вводное 100мА',
        icon: Icons.shield,
      ),
      if (_result.difAutomats > 0)
        MaterialItem(
          name: 'Дифавтоматы',
          value: '${_result.difAutomats} шт',
          subtitle: 'Для мощных потребителей',
          icon: Icons.security,
        ),
      if (_result.hasGrounding)
        const MaterialItem(
          name: 'Заземление',
          value: '1 компл.',
          subtitle: 'Шина PE + контур',
          icon: Icons.electric_bolt,
        ),
    ];

    return MaterialsCardModern(
      title: 'Оборудование щитка',
      titleIcon: Icons.electrical_services,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    final hints = <CalculatorHint>[
      const CalculatorHint(
        type: HintType.warning,
        messageKey: 'hint.engineering.raboty_dolzhen_vypolnyat_kvalifitsirovannyy',
      ),
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ispolzuyte_kabel_secheniem_ne',
      ),
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.ustanovite_uzo_dlya_zaschity',
      ),
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.engineering.proverte_vse_soedineniya_pered',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _loc.translate('common.tips'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
        ),
        HintsList(hints: hints),
      ],
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
