import 'dart:math';

import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор электрики V2.
///
/// Входные параметры:
/// - inputMode: режим ввода (0=по площади, 1=по точкам), по умолчанию 0
/// - area: площадь помещения (м²), 10-500, по умолчанию 50
/// - rooms: количество комнат, 1-20, по умолчанию 2
/// - manualSockets: розетки (ручной ввод), 5-100, по умолчанию 20
/// - manualSwitches: выключатели (ручной ввод), 2-30, по умолчанию 6
/// - manualLights: светильники (ручной ввод), 2-50, по умолчанию 6
/// - roomType: тип помещения (0=квартира, 1=дом, 2=офис), по умолчанию 0
/// - wiringMethod: способ прокладки (0=скрытая, 1=открытая), по умолчанию 0
/// - hasElectricStove: электроплита (0/1), по умолчанию 0
/// - hasOven: духовой шкаф (0/1), по умолчанию 0
/// - hasBoiler: бойлер (0/1), по умолчанию 0
/// - hasWashingMachine: стиральная машина (0/1), по умолчанию 0
/// - hasDishwasher: посудомойка (0/1), по умолчанию 0
/// - hasConditioner: кондиционер (0/1), по умолчанию 0
/// - hasWarmFloor: тёплый пол (0/1), по умолчанию 0
/// - withConduit: гофра/кабель-канал (0/1), по умолчанию 1
/// - withGrounding: заземление (0/1), по умолчанию 1
///
/// Выходные значения:
/// - sockets, switches, lights: электроточки
/// - cableLight: кабель 3×1.5 для освещения (м)
/// - cableSocket: кабель 3×2.5 для розеток (м)
/// - cablePower: кабель 3×4/6 для мощных потребителей (м)
/// - conduitLength: гофра/кабель-канал (м)
/// - circuitBreakers: автоматы (шт)
/// - rcdDevices: УЗО (шт)
/// - difAutomats: дифавтоматы (шт)
/// - junctionBoxes: распределительные коробки (шт)
/// - panelModules: модулей в щитке
/// - powerConsumers: мощных потребителей
class CalculateElectricalV2 extends BaseCalculator {
  // Коэффициенты для типов помещений
  static const List<double> roomTypeMultipliers = [1.0, 1.2, 1.5]; // apt, house, office

  // Расчёт розеток
  static const int socketAreaDivisor = 4;
  static const int socketMinPerRoom = 3;
  static const int socketKitchenAdditional = 4;

  // Расчёт выключателей
  static const double switchPerRoom = 1.5;
  static const int switchPerAreaDivisor = 20;

  // Расчёт светильников
  static const int lightPerAreaDivisor = 6;
  static const int lightPerRoom = 1;

  // Кабель: ответвление от распредкоробки до точки (скрытая/открытая)
  // Реальное расстояние: коробка на стене → розетка/светильник = 1.5-2.5м
  static const List<double> branchPerLight = [2.5, 2.0];
  static const List<double> branchPerSocket = [2.0, 1.5];
  static const List<double> branchPerSwitch = [1.8, 1.5];

  // Кабель: магистраль от щитка до распредкоробки комнаты
  // Среднее расстояние по квартире от щитка до комнаты
  static const List<double> trunkPerRoom = [6.0, 5.0];

  // Группы освещения и розеток
  static const int maxLightsPerGroup = 8;
  static const int maxSocketsPerGroup = 6;

  // Запас кабеля: 10% (подъём/спуск, обход, запас в коробках ~20см на концы)
  static const double cableMarginPercent = 10.0;

  // Кабель для мощных потребителей (м)
  static const double electricStoveCable = 12.0;
  static const double ovenCable = 10.0;
  static const double boilerCable = 10.0;
  static const double washingMachineCable = 8.0;
  static const double dishwasherCable = 8.0;
  static const double conditionerCable = 12.0;
  static const double warmFloorCable = 10.0;

  // Коэффициенты гофры
  static const List<double> conduitFactors = [0.85, 1.0]; // hidden, open

  // УЗО
  static const int socketGroupsPerRcd = 2;
  static const int fireProtectionRcd = 1;

  // Распределительные коробки
  static const double boxesPerRoom = 1.5;
  static const int boxesPerAreaDivisor = 25;
  static const int boxesPerPointsDivisor = 8;

  // Модули в щитке
  static const int basePanelModules = 4;
  static const int breakerModules = 1;
  static const int rcdModules = 2;
  static const int difautomatModules = 2;
  static const double panelReserveFactor = 1.2;

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final inputMode = getIntInput(inputs, 'inputMode',
        defaultValue: 0, minValue: 0, maxValue: 1);
    final area = getInput(inputs, 'area',
        defaultValue: 50.0, minValue: 10.0, maxValue: 500.0);
    final rooms = getIntInput(inputs, 'rooms',
        defaultValue: 2, minValue: 1, maxValue: 20);
    final manualSockets = getIntInput(inputs, 'manualSockets',
        defaultValue: 20, minValue: 5, maxValue: 100);
    final manualSwitches = getIntInput(inputs, 'manualSwitches',
        defaultValue: 6, minValue: 2, maxValue: 30);
    final manualLights = getIntInput(inputs, 'manualLights',
        defaultValue: 6, minValue: 2, maxValue: 50);
    final roomType = getIntInput(inputs, 'roomType',
        defaultValue: 0, minValue: 0, maxValue: 2);
    final wiringMethod = getIntInput(inputs, 'wiringMethod',
        defaultValue: 0, minValue: 0, maxValue: 1);

    // Мощные потребители
    final hasElectricStove = getIntInput(inputs, 'hasElectricStove',
        defaultValue: 0, minValue: 0, maxValue: 1);
    final hasOven = getIntInput(inputs, 'hasOven',
        defaultValue: 0, minValue: 0, maxValue: 1);
    final hasBoiler = getIntInput(inputs, 'hasBoiler',
        defaultValue: 0, minValue: 0, maxValue: 1);
    final hasWashingMachine = getIntInput(inputs, 'hasWashingMachine',
        defaultValue: 0, minValue: 0, maxValue: 1);
    final hasDishwasher = getIntInput(inputs, 'hasDishwasher',
        defaultValue: 0, minValue: 0, maxValue: 1);
    final hasConditioner = getIntInput(inputs, 'hasConditioner',
        defaultValue: 0, minValue: 0, maxValue: 1);
    final hasWarmFloor = getIntInput(inputs, 'hasWarmFloor',
        defaultValue: 0, minValue: 0, maxValue: 1);

    // Опции
    final withConduit = getIntInput(inputs, 'withConduit',
        defaultValue: 1, minValue: 0, maxValue: 1);
    final withGrounding = getIntInput(inputs, 'withGrounding',
        defaultValue: 1, minValue: 0, maxValue: 1);

    // Расчёт электроточек
    int sockets;
    int switches;
    int lights;

    if (inputMode == 0) {
      // Автоматический расчёт по площади
      final socketMultiplier = roomTypeMultipliers[roomType];
      final socketsBase = (area / socketAreaDivisor * socketMultiplier).ceil();
      final socketsMin = rooms * socketMinPerRoom;
      sockets = max(socketsBase, socketsMin) + socketKitchenAdditional;

      switches = (rooms * switchPerRoom + area / switchPerAreaDivisor).ceil();
      lights = (area / lightPerAreaDivisor).ceil() + (rooms * lightPerRoom);
    } else {
      // Ручной ввод
      sockets = manualSockets;
      switches = manualSwitches;
      lights = manualLights;
    }

    // Мощные потребители
    final powerConsumers = hasElectricStove + hasOven + hasBoiler +
        hasWashingMachine + hasDishwasher + hasConditioner + hasWarmFloor;

    // Расчёт кабеля: модель «магистраль + ответвления»
    // Реальная проводка: щиток → магистраль до распредкоробки → ответвления до точек
    const cableMarginMultiplier = 1 + (cableMarginPercent / 100);
    final w = wiringMethod; // 0=скрытая, 1=открытая

    // Группы
    final lightGroups = (lights / maxLightsPerGroup).ceil();
    final socketGroups = (sockets / maxSocketsPerGroup).ceil();

    // Кабель 3×1.5 для освещения:
    // - магистраль от щитка: lightGroups × trunkPerRoom (каждая группа = своя линия)
    // - ответвления: lights × branchPerLight (от коробки до светильника)
    // - выключатели: switches × branchPerSwitch (от коробки до выключателя)
    final lightTrunk = lightGroups * trunkPerRoom[w];
    final lightBranches = lights * branchPerLight[w];
    final switchBranches = switches * branchPerSwitch[w];
    final cableLightTotal =
        (lightTrunk + lightBranches + switchBranches) * cableMarginMultiplier;

    // Кабель 3×2.5 для розеток:
    // - магистраль от щитка: socketGroups × trunkPerRoom
    // - ответвления: sockets × branchPerSocket (от коробки до розетки)
    final socketTrunk = socketGroups * trunkPerRoom[w];
    final socketBranches = sockets * branchPerSocket[w];
    final cableSocketTotal =
        (socketTrunk + socketBranches) * cableMarginMultiplier;

    // Кабель 3×4/6 для мощных потребителей (каждый на отдельной линии от щитка)
    double cablePowerCalc = 0;
    if (hasElectricStove == 1) cablePowerCalc += electricStoveCable;
    if (hasOven == 1) cablePowerCalc += ovenCable;
    if (hasBoiler == 1) cablePowerCalc += boilerCable;
    if (hasWashingMachine == 1) cablePowerCalc += washingMachineCable;
    if (hasDishwasher == 1) cablePowerCalc += dishwasherCable;
    if (hasConditioner == 1) cablePowerCalc += conditionerCable;
    if (hasWarmFloor == 1) cablePowerCalc += warmFloorCable;
    final cablePowerTotal = cablePowerCalc * cableMarginMultiplier;

    // Итого кабеля
    final totalCable = cableLightTotal + cableSocketTotal + cablePowerTotal;

    // Гофра
    double conduitLength = 0;
    if (withConduit == 1) {
      conduitLength = totalCable * conduitFactors[wiringMethod];
    }

    // Автоматика
    final circuitBreakers = lightGroups + socketGroups;
    final difAutomats = powerConsumers;
    final rcdDevices = (socketGroups / socketGroupsPerRcd).ceil() + fireProtectionRcd;

    // Распределительные коробки
    // В обоих режимах учитываем комнаты: минимум 1 коробка на комнату + по площади
    int junctionBoxes;
    if (inputMode == 0) {
      junctionBoxes = (rooms * boxesPerRoom + area / boxesPerAreaDivisor).ceil();
    } else {
      // Ручной режим: 1 коробка на каждые 4-5 точек, минимум rooms штук
      final byPoints = ((sockets + switches + lights) / boxesPerPointsDivisor).ceil();
      junctionBoxes = max(byPoints, rooms);
    }

    // Модули в щитке (вводной автомат 2 модуля + групповые + УЗО + диф + 20% резерв)
    final panelModules = ((2 + // вводной автомат (двухполюсный)
            circuitBreakers * breakerModules +
            rcdDevices * rcdModules +
            difAutomats * difautomatModules) *
        panelReserveFactor).ceil();

    // Расчёт стоимости
    double? totalPrice;

    final cable15Price = findPrice(priceList, ['cable_1_5', 'vvg_1_5']);
    final cable25Price = findPrice(priceList, ['cable_2_5', 'vvg_2_5']);
    final cable4Price = findPrice(priceList, ['cable_4', 'vvg_4']);
    final conduitPrice = findPrice(priceList, ['conduit', 'corrugated_pipe']);
    final socketPrice = findPrice(priceList, ['socket', 'outlet']);
    final switchPrice = findPrice(priceList, ['switch', 'light_switch']);
    final breakerPrice = findPrice(priceList, ['circuit_breaker', 'breaker']);
    final rcdPrice = findPrice(priceList, ['rcd', 'uzo']);
    final boxPrice = findPrice(priceList, ['junction_box', 'box']);

    if (cable15Price != null) {
      totalPrice = (totalPrice ?? 0) + cableLightTotal * cable15Price.price;
    }
    if (cable25Price != null) {
      totalPrice = (totalPrice ?? 0) + cableSocketTotal * cable25Price.price;
    }
    if (cable4Price != null && cablePowerTotal > 0) {
      totalPrice = (totalPrice ?? 0) + cablePowerTotal * cable4Price.price;
    }
    if (conduitPrice != null && conduitLength > 0) {
      totalPrice = (totalPrice ?? 0) + conduitLength * conduitPrice.price;
    }
    if (socketPrice != null) {
      totalPrice = (totalPrice ?? 0) + sockets * socketPrice.price;
    }
    if (switchPrice != null) {
      totalPrice = (totalPrice ?? 0) + switches * switchPrice.price;
    }
    if (breakerPrice != null) {
      totalPrice = (totalPrice ?? 0) + circuitBreakers * breakerPrice.price;
    }
    if (rcdPrice != null) {
      totalPrice = (totalPrice ?? 0) + rcdDevices * rcdPrice.price;
    }
    if (boxPrice != null) {
      totalPrice = (totalPrice ?? 0) + junctionBoxes * boxPrice.price;
    }

    return createResult(
      values: {
        'inputMode': inputMode.toDouble(),
        'area': area,
        'rooms': rooms.toDouble(),
        'roomType': roomType.toDouble(),
        'wiringMethod': wiringMethod.toDouble(),
        'sockets': sockets.toDouble(),
        'switches': switches.toDouble(),
        'lights': lights.toDouble(),
        'cableLight': cableLightTotal,
        'cableSocket': cableSocketTotal,
        'cablePower': cablePowerTotal,
        'totalCable': totalCable,
        'conduitLength': conduitLength,
        'circuitBreakers': circuitBreakers.toDouble(),
        'rcdDevices': rcdDevices.toDouble(),
        'difAutomats': difAutomats.toDouble(),
        'junctionBoxes': junctionBoxes.toDouble(),
        'panelModules': panelModules.toDouble(),
        'powerConsumers': powerConsumers.toDouble(),
        'withGrounding': withGrounding.toDouble(),
        'lightGroups': lightGroups.toDouble(),
        'socketGroups': socketGroups.toDouble(),
      },
      totalPrice: totalPrice,
    );
  }
}
