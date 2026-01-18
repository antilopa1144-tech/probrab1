import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор грунтовки.
///
/// Рассчитывает количество грунтовки для обработки поверхностей
/// с учётом типа поверхности, типа грунтовки и количества слоёв.
///
/// Нормативы:
/// - СП 71.13330.2017 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - surfaceType: тип поверхности (0=бетон, 1=штукатурка, 2=гипсокартон)
/// - primerType: тип грунтовки (0=глубокого проникновения, 1=бетонконтакт, 2=универсальная)
/// - layers: количество слоёв (1-3)
/// - canSize: объём канистры (л)
/// - roomWidth: ширина комнаты (м), опционально
/// - roomLength: длина комнаты (м), опционально
/// - roomHeight: высота комнаты (м), опционально
class CalculatePrimerV2 extends BaseCalculator {
  /// Базовый расход грунтовки по типу (л/м²)
  static const Map<int, double> baseConsumptionRate = {
    0: 0.1,   // Глубокого проникновения
    1: 0.3,   // Бетонконтакт
    2: 0.15,  // Универсальная
  };

  /// Коэффициент поверхности
  static const Map<int, double> surfaceMultiplier = {
    0: 1.3,  // Бетон (пористый)
    1: 1.0,  // Штукатурка
    2: 0.8,  // Гипсокартон
  };

  /// Запас на потери (%)
  static const double wastePercent = 10.0;

  /// Доступные размеры канистр (л)
  static const List<double> availableCanSizes = [5.0, 10.0, 20.0];

  /// Оптимальный подбор канистр с минимальным излишком
  static Map<double, int> selectOptimalCans(double litersNeeded, double preferredCanSize) {
    final result = <double, int>{};

    // Если нужно меньше минимальной канистры - берём одну минимальную
    if (litersNeeded <= availableCanSizes.first) {
      result[availableCanSizes.first] = 1;
      return result;
    }

    // Используем предпочтительный размер
    if (preferredCanSize > 0 && availableCanSizes.contains(preferredCanSize)) {
      final fullCans = (litersNeeded / preferredCanSize).floor();
      final remainder = litersNeeded - fullCans * preferredCanSize;

      if (fullCans > 0) {
        result[preferredCanSize] = fullCans;
      }

      // Для остатка ищем минимальную канистру, которая покроет его
      if (remainder > 0) {
        for (final size in availableCanSizes) {
          if (size >= remainder) {
            result[size] = (result[size] ?? 0) + 1;
            break;
          }
        }
        // Если ни одна не подошла, берём ещё одну предпочтительного размера
        if (remainder > availableCanSizes.last) {
          result[preferredCanSize] = (result[preferredCanSize] ?? 0) + 1;
        }
      }
    } else {
      // Просто делим на выбранный размер
      result[preferredCanSize] = (litersNeeded / preferredCanSize).ceil();
    }

    return result;
  }

  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    final roomWidth = inputs['roomWidth'];
    final roomLength = inputs['roomLength'];
    final roomHeight = inputs['roomHeight'];

    // Нужна либо площадь, либо размеры комнаты
    if (area <= 0 && (roomWidth == null || roomLength == null || roomHeight == null)) {
      return 'Необходимо указать площадь или размеры комнаты';
    }

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    // Входные параметры
    final surfaceType = getIntInput(inputs, 'surfaceType', defaultValue: 0, minValue: 0, maxValue: 2);
    final primerType = getIntInput(inputs, 'primerType', defaultValue: 0, minValue: 0, maxValue: 2);
    final layers = getIntInput(inputs, 'layers', defaultValue: 2, minValue: 1, maxValue: 3);
    final canSize = getInput(inputs, 'canSize', defaultValue: 10.0, minValue: 1.0, maxValue: 50.0);

    // Площадь: либо напрямую, либо из размеров комнаты (площадь стен)
    double area;
    final inputArea = getInput(inputs, 'area', defaultValue: 0);
    if (inputArea > 0) {
      area = inputArea;
    } else {
      final roomWidth = getInput(inputs, 'roomWidth', defaultValue: 4.0, minValue: 0.5, maxValue: 20);
      final roomLength = getInput(inputs, 'roomLength', defaultValue: 5.0, minValue: 0.5, maxValue: 20);
      final roomHeight = getInput(inputs, 'roomHeight', defaultValue: 2.7, minValue: 2.0, maxValue: 5);
      // Площадь стен = периметр × высота
      area = 2 * (roomWidth + roomLength) * roomHeight;
    }

    // Расход грунтовки
    final baseRate = baseConsumptionRate[primerType]!;
    final surfaceMult = surfaceMultiplier[surfaceType]!;
    final consumptionRate = baseRate * surfaceMult;

    // Количество грунтовки с запасом
    final litersNeeded = area * consumptionRate * layers * (1 + wastePercent / 100);

    // Оптимальный подбор канистр
    final optimalCans = selectOptimalCans(litersNeeded, canSize);

    // Общее количество канистр и литров
    int totalCans = 0;
    double totalLiters = 0;
    for (final entry in optimalCans.entries) {
      totalCans += entry.value;
      totalLiters += entry.key * entry.value;
    }

    // Излишек
    final excess = totalLiters - litersNeeded;

    // Расчёт стоимости
    final primerPrice = findPrice(priceList, ['primer', 'primer_deep', 'primer_contact', 'primer_universal', 'грунтовка']);

    final totalPrice = calculateCost(totalLiters, primerPrice?.price);

    // Формируем результат
    final values = <String, double>{
      'area': area,
      'surfaceType': surfaceType.toDouble(),
      'primerType': primerType.toDouble(),
      'layers': layers.toDouble(),
      'consumptionRate': consumptionRate,
      'litersNeeded': litersNeeded,
      'cansNeeded': totalCans.toDouble(),
      'canSize': canSize,
      'totalLiters': totalLiters,
      'excess': excess,
    };

    // Добавляем информацию о каждом размере канистр
    for (final entry in optimalCans.entries) {
      values['cans_${entry.key.toInt()}l'] = entry.value.toDouble();
    }

    return createResult(
      values: values,
      totalPrice: totalPrice,
    );
  }
}
