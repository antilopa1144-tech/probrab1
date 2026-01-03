import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/models/calculator_constant.dart';
import '../../core/errors/error_handler.dart';

/// Источник констант из локальных JSON файлов
///
/// Загружает константы из `assets/json/constants/calculator_constants_&lt;id&gt;.json`
/// Аналогичен LocalPriceDataSource, но для констант калькуляторов.
///
/// Пример:
/// ```dart
/// final dataSource = LocalConstantsDataSource();
/// final constants = await dataSource.getConstants('warmfloor');
/// ```
class LocalConstantsDataSource {
  /// Кеш загруженных констант в памяти
  ///
  /// Ключ: calculator_id, значение: CalculatorConstants
  /// Кеш сохраняется на время жизни объекта
  final Map<String, CalculatorConstants> _cache = {};

  /// Загрузить константы для калькулятора
  ///
  /// [calculatorId] - ID калькулятора (например, 'warmfloor', 'electrical')
  ///
  /// Файлы хранятся в `assets/json/constants/calculator_constants_&lt;id&gt;.json`.
  ///
  /// Возвращает:
  /// - [CalculatorConstants] если файл успешно загружен
  /// - [null] если файл не найден или произошла ошибка парсинга
  ///
  /// При ошибках логирует их через ErrorHandler и возвращает null,
  /// позволяя калькулятору работать с дефолтными значениями.
  Future<CalculatorConstants?> getConstants(String calculatorId) async {
    // Проверяем кеш
    if (_cache.containsKey(calculatorId)) {
      return _cache[calculatorId];
    }

    try {
      final assetPath = 'assets/json/constants/calculator_constants_${calculatorId.toLowerCase()}.json';
      final data = await rootBundle.loadString(assetPath);
      final json = jsonDecode(data) as Map<String, dynamic>;
      final constants = CalculatorConstants.fromJson(json);

      // Сохраняем в кеш
      _cache[calculatorId] = constants;

      return constants;
    } on FormatException catch (e, stackTrace) {
      // Ошибка парсинга JSON - некорректный формат
      ErrorHandler.logError(
        e,
        stackTrace,
        'LocalConstantsDataSource.getConstants: JSON parse error for $calculatorId',
      );
      return null;
    } catch (e, stackTrace) {
      // Файл не найден или другие ошибки
      ErrorHandler.logError(
        e,
        stackTrace,
        'LocalConstantsDataSource.getConstants: error loading constants for $calculatorId',
      );
      return null;
    }
  }

  /// Загрузить общие константы
  ///
  /// Общие константы используются всеми калькуляторами
  /// (например, стандартные запасы, преобразования единиц).
  ///
  /// Это shortcut для `getConstants('common')`.
  Future<CalculatorConstants?> getCommonConstants() async {
    return getConstants('common');
  }

  /// Очистить кеш констант
  ///
  /// [calculatorId] - опциональный ID калькулятора.
  /// Если указан - очистит только его, иначе - весь кеш.
  ///
  /// Использование:
  /// ```dart
  /// // Очистить конкретный калькулятор
  /// dataSource.clearCache('warmfloor');
  ///
  /// // Очистить весь кеш
  /// dataSource.clearCache();
  /// ```
  void clearCache([String? calculatorId]) {
    if (calculatorId != null) {
      _cache.remove(calculatorId);
    } else {
      _cache.clear();
    }
  }

  /// Проверить, закеширован ли калькулятор
  bool isCached(String calculatorId) {
    return _cache.containsKey(calculatorId);
  }

  /// Получить количество закешированных калькуляторов
  int get cacheSize => _cache.length;
}
