import '../../domain/models/calculator_constant.dart';

/// Базовый класс для работы с константами калькуляторов.
///
/// Предоставляет общие методы доступа к константам из [CalculatorConstants].
/// Калькуляторы могут наследовать этот класс и добавлять специализированные геттеры.
///
/// Использование:
/// ```dart
/// class PlasterConstants extends BaseCalculatorConstants {
///   const PlasterConstants([super.data]);
///
///   double getConsumptionRate(String material) {
///     final defaults = {'gypsum': 8.5, 'cement': 17.0};
///     return getDouble('consumption_rates', material, defaults[material] ?? 8.5);
///   }
/// }
/// ```
abstract class BaseCalculatorConstants {
  /// Данные констант (может быть null если Remote Config недоступен).
  final CalculatorConstants? data;

  const BaseCalculatorConstants([this.data]);

  /// Получить числовое значение константы.
  ///
  /// [constantKey] — ключ константы (например, 'consumption_rates')
  /// [valueKey] — ключ значения внутри константы (например, 'gypsum')
  /// [defaultValue] — значение по умолчанию, если константа не найдена
  double getDouble(String constantKey, String valueKey, double defaultValue) {
    if (data == null) return defaultValue;
    final constant = data!.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  /// Получить целочисленное значение константы.
  int getInt(String constantKey, String valueKey, int defaultValue) {
    if (data == null) return defaultValue;
    final constant = data!.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return defaultValue;
  }

  /// Получить строковое значение константы.
  String getString(String constantKey, String valueKey, String defaultValue) {
    if (data == null) return defaultValue;
    final constant = data!.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    return value?.toString() ?? defaultValue;
  }

  /// Получить типизированное значение константы.
  T get<T>(String constantKey, String valueKey, T defaultValue) {
    if (data == null) return defaultValue;
    final constant = data!.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value == null) return defaultValue;
    if (value is T) return value;

    // Конвертация между числовыми типами
    if (T == double && value is int) return value.toDouble() as T;
    if (T == int && value is double) return value.toInt() as T;

    return defaultValue;
  }

  /// Получить Map значений из константы.
  Map<String, dynamic> getMap(String constantKey) {
    if (data == null) return {};
    final constant = data!.constants[constantKey];
    return constant?.values ?? {};
  }

  /// Проверить наличие константы.
  bool has(String constantKey) {
    if (data == null) return false;
    return data!.constants.containsKey(constantKey);
  }

  /// Проверить, загружены ли константы.
  bool get isLoaded => data != null;
}

/// Простая реализация BaseCalculatorConstants для калькуляторов
/// без специализированных геттеров.
class SimpleCalculatorConstants extends BaseCalculatorConstants {
  const SimpleCalculatorConstants([super.data]);
}
