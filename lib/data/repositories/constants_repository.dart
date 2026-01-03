import '../datasources/local_constants_data_source.dart';
import '../datasources/remote_constants_data_source.dart';
import '../../domain/models/calculator_constant.dart';

/// Репозиторий констант с fallback стратегией и кешированием
///
/// Стратегия загрузки (Fallback chain):
/// 1. **Remote Config** (если доступен и включен)
/// 2. **Local JSON** (fallback при недоступности Remote)
/// 3. **Default values** (hardcoded в калькуляторе как последний fallback)
///
/// Кеширование:
/// - Время жизни кеша: 1 час (как в PriceRepository)
/// - In-memory кеш для быстрого доступа
/// - Автоматическая инвалидация по TTL
///
/// Пример использования:
/// ```dart
/// final repo = ConstantsRepository(localDataSource, remoteDataSource);
/// final constants = await repo.getConstants('warmfloor');
///
/// // Получение конкретного значения
/// final power = await repo.getConstantValue<double>(
///   'warmfloor',
///   'room_power',
///   'bathroom',
///   defaultValue: 180.0,
/// );
/// ```
class ConstantsRepository {
  final LocalConstantsDataSource _localDataSource;
  final RemoteConstantsDataSource _remoteDataSource;

  // Кеш констант (ключ: calculator_id)
  final Map<String, CalculatorConstants> _cache = {};

  // Время последней загрузки для каждого калькулятора
  final Map<String, DateTime> _cacheTimestamps = {};

  // Время жизни кеша: 1 час (соответствует PriceRepository)
  static const Duration _cacheLifetime = Duration(hours: 1);

  ConstantsRepository(this._localDataSource, this._remoteDataSource);

  /// Получить константы для калькулятора с кешированием
  ///
  /// [calculatorId] - ID калькулятора
  /// [forceRefresh] - игнорировать кеш и загрузить заново
  ///
  /// Возвращает:
  /// - [CalculatorConstants] если успешно загружено
  /// - [null] если не найдено ни в одном источнике
  ///
  /// Fallback порядок: Remote → Local → null
  Future<CalculatorConstants?> getConstants(
    String calculatorId, {
    bool forceRefresh = false,
  }) async {
    // Проверяем кеш
    if (!forceRefresh && _cache.containsKey(calculatorId)) {
      final timestamp = _cacheTimestamps[calculatorId];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheLifetime) {
        return _cache[calculatorId];
      }
    }

    CalculatorConstants? constants;

    // 1. Попытка загрузить из Remote Config
    try {
      constants = await _remoteDataSource.getConstants(calculatorId);
      if (constants != null) {
        _logSource('remote', calculatorId, constants.version);
      }
    } catch (_) {
      // Игнорируем ошибки Remote Config, переходим к Local
    }

    // 2. Fallback на локальные файлы
    if (constants == null) {
      constants = await _localDataSource.getConstants(calculatorId);
      if (constants != null) {
        _logSource('local', calculatorId, constants.version);
      }
    }

    // Сохраняем в кеш если успешно загрузили
    if (constants != null) {
      _cache[calculatorId] = constants;
      _cacheTimestamps[calculatorId] = DateTime.now();
    }

    return constants;
  }

  /// Получить общие константы
  ///
  /// Общие константы используются всеми калькуляторами
  /// (стандартные запасы, преобразования единиц и т.д.)
  Future<CalculatorConstants?> getCommonConstants({
    bool forceRefresh = false,
  }) async {
    return getConstants('common', forceRefresh: forceRefresh);
  }

  /// Получить конкретное значение константы
  ///
  /// Удобный метод для получения одного значения без загрузки всех констант.
  ///
  /// [calculatorId] - ID калькулятора
  /// [constantKey] - ключ константы (например, 'room_power')
  /// [valueKey] - ключ значения (например, 'bathroom')
  /// [defaultValue] - значение по умолчанию
  ///
  /// Пример:
  /// ```dart
  /// final margin = await repo.getConstantValue<double>(
  ///   'tile',
  ///   'cable_margins',
  ///   'standard_margin',
  ///   defaultValue: 15.0,
  /// );
  /// ```
  ///
  /// Возвращает значение или defaultValue если не найдено.
  Future<T?> getConstantValue<T>(
    String calculatorId,
    String constantKey,
    String valueKey, {
    T? defaultValue,
  }) async {
    final constants = await getConstants(calculatorId);
    if (constants == null) return defaultValue;

    final constant = constants.constants[constantKey];
    if (constant == null) return defaultValue;

    final value = constant.values[valueKey];
    if (value == null) return defaultValue;

    // Проверка типа и конверсия
    if (value is T) {
      return value;
    }

    // Автоматическая конверсия int ↔ double
    if (T == double && value is int) {
      return value.toDouble() as T;
    }
    if (T == int && value is double) {
      return value.toInt() as T;
    }

    return defaultValue;
  }

  /// Очистить кеш констант
  ///
  /// [calculatorId] - опциональный ID калькулятора.
  /// Если указан - очистит только его, иначе - весь кеш.
  void clearCache([String? calculatorId]) {
    if (calculatorId != null) {
      _cache.remove(calculatorId);
      _cacheTimestamps.remove(calculatorId);
    } else {
      _cache.clear();
      _cacheTimestamps.clear();
    }
  }

  /// Принудительно обновить Remote Config и очистить кеш
  ///
  /// Используется для кнопки "Обновить константы" в настройках
  /// или при обнаружении проблем с расчетами.
  ///
  /// Возвращает `true` если Remote Config успешно обновлен.
  Future<bool> refreshRemoteConfig() async {
    final success = await _remoteDataSource.forceRefresh();
    if (success) {
      clearCache(); // Очищаем кеш после обновления
    }
    return success;
  }

  /// Получить статистику кеша
  ///
  /// Возвращает Map с информацией о закешированных калькуляторах:
  /// - количество закешированных
  /// - список ID
  /// - время последней загрузки для каждого
  Map<String, dynamic> getCacheStats() {
    return {
      'cached_count': _cache.length,
      'calculator_ids': _cache.keys.toList(),
      'timestamps': Map.fromEntries(
        _cacheTimestamps.entries.map(
          (e) => MapEntry(
            e.key,
            e.value.toIso8601String(),
          ),
        ),
      ),
    };
  }

  /// Проверить, закеширован ли калькулятор и актуален ли кеш
  bool isCached(String calculatorId) {
    if (!_cache.containsKey(calculatorId)) return false;

    final timestamp = _cacheTimestamps[calculatorId];
    if (timestamp == null) return false;

    return DateTime.now().difference(timestamp) < _cacheLifetime;
  }

  /// Логирование источника констант для мониторинга
  void _logSource(String source, String calculatorId, String version) {
    // В production это будет отправляться в Firebase Analytics
    // Пока просто для отладки
    // print('[Constants] Loaded $calculatorId v$version from $source');
  }
}
