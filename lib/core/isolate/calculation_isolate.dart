import 'dart:isolate';
import '../../data/models/price_item.dart';
import '../../domain/usecases/calculator_usecase.dart';

/// Сервис для выполнения тяжёлых расчётов в отдельном Isolate.
///
/// Используется для калькуляторов, которые требуют значительных вычислительных ресурсов:
/// - Фундаменты (большие объёмы бетона, арматуры)
/// - Отопление (сложные тепловые расчёты)
/// - Многоэтажные конструкции
///
/// ## Пример использования:
///
/// ```dart
/// final result = await CalculationIsolate.compute(
///   useCase: CalculateStripFoundation(),
///   inputs: {'perimeter': 50.0, 'width': 0.4, 'height': 0.8},
///   priceList: priceList,
/// );
/// ```
class CalculationIsolate {
  /// Выполнить расчёт в отдельном Isolate.
  ///
  /// - [useCase]: Use case для выполнения расчёта
  /// - [inputs]: входные данные
  /// - [priceList]: список цен
  ///
  /// Возвращает результат расчёта или выбрасывает исключение.
  static Future<CalculatorResult> compute({
    required CalculatorUseCase useCase,
    required Map<String, double> inputs,
    required List<PriceItem> priceList,
  }) async {
    // Для небольших расчётов выполняем синхронно
    if (_isLightCalculation(inputs)) {
      return useCase.call(inputs, priceList);
    }

    // Для тяжёлых расчётов используем Isolate
    return Isolate.run(() {
      return useCase.call(inputs, priceList);
    });
  }

  /// Проверка, является ли расчёт лёгким (можно выполнить синхронно).
  ///
  /// Критерии для тяжёлого расчёта:
  /// - Периметр > 100 м (большой фундамент)
  /// - Площадь > 500 м² (большая площадь)
  /// - Объём > 100 м³ (большой объём)
  static bool _isLightCalculation(Map<String, double> inputs) {
    final perimeter = inputs['perimeter'] ?? 0.0;
    final area = inputs['area'] ?? 0.0;
    final volume = inputs['volume'] ?? 0.0;

    // Если есть большой периметр, площадь или объём - это тяжёлый расчёт
    if (perimeter > 100 || area > 500 || volume > 100) {
      return false;
    }

    return true;
  }
}
