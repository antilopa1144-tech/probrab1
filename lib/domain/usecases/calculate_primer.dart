// ignore_for_file: prefer_const_declarations
import '../../data/models/price_item.dart';
import './calculator_usecase.dart';
import './base_calculator.dart';

/// Калькулятор грунтовки.
///
/// Нормативы:
/// - СНиП 3.04.01-87 "Изоляционные и отделочные покрытия"
///
/// Поля:
/// - area: площадь поверхности (м²)
/// - layers: количество слоёв, по умолчанию 1
/// - type: тип (1=обычная, 2=глубокого проникновения, 3=адгезионная), по умолчанию 2
/// - canSize: размер канистры (л), по умолчанию 10
class CalculatePrimer extends BaseCalculator {
  /// Доступные размеры канистр (л)
  static const List<double> availableCanSizes = [5.0, 10.0, 15.0, 20.0];

  /// Оптимальный подбор канистр с минимальным излишком
  static Map<double, int> selectOptimalCans(double litersNeeded, double preferredCanSize) {
    final result = <double, int>{};

    // Если нужно меньше минимальной канистры - берём одну минимальную
    if (litersNeeded <= availableCanSizes.first) {
      result[availableCanSizes.first] = 1;
      return result;
    }

    // Сначала пробуем использовать предпочтительный размер
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
        // Если ни одна не подошла, берём максимальную
        if (remainder > availableCanSizes.last) {
          result[availableCanSizes.last] = (result[availableCanSizes.last] ?? 0) + 1;
        }
      }
    } else {
      // Жадный алгоритм: от большего к меньшему
      var remaining = litersNeeded;
      final sizes = List<double>.from(availableCanSizes)..sort((a, b) => b.compareTo(a));

      for (final size in sizes) {
        final count = (remaining / size).floor();
        if (count > 0) {
          result[size] = count;
          remaining -= count * size;
        }
      }

      // Добавляем минимальную канистру для остатка
      if (remaining > 0) {
        final smallestSize = sizes.last;
        result[smallestSize] = (result[smallestSize] ?? 0) + 1;
      }
    }

    return result;
  }
  @override
  String? validateInputs(Map<String, double> inputs) {
    final baseError = super.validateInputs(inputs);
    if (baseError != null) return baseError;

    final area = inputs['area'] ?? 0;
    if (area <= 0) return 'Площадь должна быть больше нуля';

    return null;
  }

  @override
  CalculatorResult calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final area = getInput(inputs, 'area', minValue: 0.1);
    final layers = getIntInput(inputs, 'layers', defaultValue: 1, minValue: 1, maxValue: 3);
    final type = getIntInput(inputs, 'type', defaultValue: 2, minValue: 1, maxValue: 3);
    final canSize = getInput(inputs, 'canSize', defaultValue: 10.0, minValue: 1.0, maxValue: 50.0);

    // Расход грунтовки зависит от типа и впитываемости поверхности:
    // - Обычная: 0.08-0.12 л/м²
    // - Глубокого проникновения: 0.12-0.18 л/м²
    // - Адгезионная (бетоноконтакт): 0.25-0.35 л/м²
    final consumptionPerLayer = type == 1 ? 0.1 : (type == 2 ? 0.15 : 0.3);

    // Общий расход с учётом слоёв и запаса 10%
    final primerNeeded = area * consumptionPerLayer * layers * 1.1;

    // Оптимальный подбор канистр
    final optimalCans = selectOptimalCans(primerNeeded, canSize);

    // Общее количество литров в выбранных канистрах
    double totalLiters = 0;
    int totalCans = 0;
    for (final entry in optimalCans.entries) {
      totalLiters += entry.key * entry.value;
      totalCans += entry.value;
    }

    // Излишек
    final excess = totalLiters - primerNeeded;

    // Валики: 1-2 шт в зависимости от площади
    final rollersNeeded = ceilToInt(area / 30); // 1 валик на ~30-50 м²

    // Кисти для углов: 1-2 шт
    const brushesNeeded = 2;

    // Кювета для валика: 1 шт
    const traysNeeded = 1;

    // Время высыхания (информативно, часов)
    final dryingTime = type == 1 ? 2.0 : (type == 2 ? 4.0 : 3.0);

    // Расчёт стоимости
    final primerPrice = type == 1
        ? findPrice(priceList, ['primer', 'primer_standard', 'primer_universal'])
        : (type == 2
            ? findPrice(priceList, ['primer_deep', 'primer_penetrating', 'primer'])
            : findPrice(priceList, ['primer_adhesion', 'concrete_contact', 'betokontakt']));

    final costs = [
      calculateCost(totalLiters, primerPrice?.price),
    ];

    // Формируем результаты с информацией о канистрах
    final values = <String, double>{
      'area': area,
      'primerNeeded': primerNeeded,
      'totalLiters': totalLiters,
      'totalCans': totalCans.toDouble(),
      'excess': excess,
      'layers': layers.toDouble(),
      'rollersNeeded': rollersNeeded.toDouble(),
      'brushesNeeded': brushesNeeded.toDouble(),
      'traysNeeded': traysNeeded.toDouble(),
      'dryingTime': dryingTime,
    };

    // Добавляем информацию о каждом размере канистр
    for (final entry in optimalCans.entries) {
      values['cans_${entry.key.toInt()}l'] = entry.value.toDouble();
    }

    return createResult(
      values: values,
      totalPrice: sumCosts(costs),
    );
  }
}
