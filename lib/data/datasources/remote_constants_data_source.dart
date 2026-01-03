import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../domain/models/calculator_constant.dart';
import '../../core/errors/error_handler.dart';

/// Источник констант из Firebase Remote Config
///
/// Позволяет обновлять константы калькуляторов без пересборки приложения.
/// Использует Firebase Remote Config для хранения JSON-конфигураций.
///
/// Пример использования:
/// ```dart
/// final remoteConfig = FirebaseRemoteConfig.instance;
/// final dataSource = RemoteConstantsDataSource(remoteConfig);
/// await dataSource.initialize();
/// final constants = await dataSource.getConstants('warmfloor');
/// ```
class RemoteConstantsDataSource {
  final FirebaseRemoteConfig _remoteConfig;

  RemoteConstantsDataSource(this._remoteConfig);

  /// Инициализация Remote Config с настройками
  ///
  /// Вызывается один раз при старте приложения.
  /// Настраивает таймауты и устанавливает дефолтные значения.
  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      // Устанавливаем defaults для graceful degradation
      await _remoteConfig.setDefaults(const {
        'constants_enabled': false,
        'constants_version': '1.0.0',
      });

      // Загружаем и активируем конфигурацию
      await _remoteConfig.fetchAndActivate();
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace,
        'RemoteConstantsDataSource.initialize',
      );
    }
  }

  /// Проверка, включены ли удаленные константы
  ///
  /// Используется для A/B тестирования и постепенного rollout.
  /// Если false, все калькуляторы будут использовать локальные файлы.
  bool get isEnabled => _remoteConfig.getBool('constants_enabled');

  /// Получить версию констант из Remote Config
  String get version => _remoteConfig.getString('constants_version');

  /// Загрузить константы для калькулятора из Remote Config
  ///
  /// [calculatorId] - ID калькулятора (например, 'warmfloor', 'electrical')
  ///
  /// Ключ в Remote Config: `calculator_constants_&lt;id&gt;`
  ///
  /// Возвращает:
  /// - [CalculatorConstants] если успешно загружено
  /// - [null] если константы отключены, не найдены или ошибка парсинга
  ///
  /// При ошибках логирует их и возвращает null для fallback
  /// на локальные файлы или дефолтные значения.
  Future<CalculatorConstants?> getConstants(String calculatorId) async {
    // Проверяем, включены ли удаленные константы
    if (!isEnabled) {
      return null;
    }

    try {
      final key = 'calculator_constants_${calculatorId.toLowerCase()}';
      final jsonString = _remoteConfig.getString(key);

      // Если значение пустое, значит не настроено
      if (jsonString.isEmpty) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return CalculatorConstants.fromJson(json);
    } on FormatException catch (e, stackTrace) {
      // Ошибка парсинга JSON
      ErrorHandler.logError(
        e,
        stackTrace,
        'RemoteConstantsDataSource.getConstants: JSON parse error for $calculatorId',
      );
      return null;
    } catch (e, stackTrace) {
      // Другие ошибки
      ErrorHandler.logError(
        e,
        stackTrace,
        'RemoteConstantsDataSource.getConstants: error for $calculatorId',
      );
      return null;
    }
  }

  /// Загрузить общие константы из Remote Config
  ///
  /// Это shortcut для `getConstants('common')`.
  Future<CalculatorConstants?> getCommonConstants() async {
    return getConstants('common');
  }

  /// Принудительно обновить конфигурацию из Firebase
  ///
  /// Игнорирует minimumFetchInterval и загружает свежие данные.
  /// Используется для кнопки "Обновить" в настройках или при
  /// обнаружении проблем с константами.
  ///
  /// Возвращает:
  /// - `true` если обновление успешно
  /// - `false` если произошла ошибка
  Future<bool> forceRefresh() async {
    try {
      final activated = await _remoteConfig.fetchAndActivate();
      return activated;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace,
        'RemoteConstantsDataSource.forceRefresh',
      );
      return false;
    }
  }

  /// Получить все ключи Remote Config (для дебага)
  Set<String> getAllKeys() {
    return _remoteConfig.getAll().keys.toSet();
  }

  /// Получить информацию о последнем fetch (для мониторинга)
  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;

  /// Получить время последнего успешного fetch
  DateTime get lastFetchTime => _remoteConfig.lastFetchTime;
}
