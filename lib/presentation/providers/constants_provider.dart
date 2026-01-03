import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import '../../data/datasources/local_constants_data_source.dart';
import '../../data/datasources/remote_constants_data_source.dart';
import '../../data/repositories/constants_repository.dart';
import '../../domain/models/calculator_constant.dart';
import '../../core/errors/error_handler.dart';

/// Provider для LocalConstantsDataSource
///
/// Создает единственный экземпляр источника локальных констант.
final localConstantsDataSourceProvider = Provider<LocalConstantsDataSource>((ref) {
  return LocalConstantsDataSource();
});

/// Provider для RemoteConstantsDataSource
///
/// Использует Firebase Remote Config instance.
/// Remote Config уже инициализирован в main.dart через Firebase.initializeApp.
final remoteConstantsDataSourceProvider = Provider<RemoteConstantsDataSource>((ref) {
  return RemoteConstantsDataSource(FirebaseRemoteConfig.instance);
});

/// Provider для ConstantsRepository
///
/// Основной репозиторий для работы с константами.
/// Использует fallback стратегию: Remote Config → Local JSON → null.
final constantsRepositoryProvider = Provider<ConstantsRepository>((ref) {
  final localDataSource = ref.watch(localConstantsDataSourceProvider);
  final remoteDataSource = ref.watch(remoteConstantsDataSourceProvider);

  return ConstantsRepository(localDataSource, remoteDataSource);
});

/// Provider для инициализации Remote Config
///
/// Вызывается один раз при старте приложения для настройки
/// Firebase Remote Config с таймаутами и дефолтными значениями.
///
/// Пример использования в InitializationScreen или main.dart:
/// ```dart
/// ref.read(remoteConfigInitProvider);
/// ```
///
/// Ошибки логируются, но не приводят к падению приложения.
/// При ошибке инициализации будет использоваться fallback на локальные файлы.
final remoteConfigInitProvider = FutureProvider<void>((ref) async {
  try {
    final remoteDataSource = ref.watch(remoteConstantsDataSourceProvider);
    await remoteDataSource.initialize();
  } catch (e, stackTrace) {
    // Логируем ошибку, но не прерываем работу приложения
    ErrorHandler.logError(
      e,
      stackTrace,
      'ConstantsProvider.remoteConfigInit: Failed to initialize Remote Config',
    );
    // Приложение продолжит работу с локальными константами
  }
});

/// Provider для загрузки констант конкретного калькулятора
///
/// Семейство providers для получения констант по ID калькулятора.
/// Использует кеширование на уровне репозитория (TTL 1 час).
///
/// Пример использования:
/// ```dart
/// final warmfloorConstants = ref.watch(calculatorConstantsProvider('warmfloor'));
/// warmfloorConstants.when(
///   data: (constants) => Text('Version: ${constants?.version ?? 'N/A'}'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error loading constants'),
/// );
/// ```
///
/// Fallback стратегия:
/// 1. Remote Config (если доступен)
/// 2. Local JSON файл
/// 3. null (калькулятор использует hardcoded defaults)
final calculatorConstantsProvider = FutureProvider.family<CalculatorConstants?, String>(
  (ref, calculatorId) async {
    try {
      final repo = ref.watch(constantsRepositoryProvider);
      final constants = await repo.getConstants(calculatorId);

      // null - это нормально, калькулятор будет использовать дефолтные значения
      return constants;
    } catch (e, stackTrace) {
      // Логируем ошибку
      ErrorHandler.logError(
        e,
        stackTrace,
        'ConstantsProvider.calculatorConstants: Failed to load constants for $calculatorId',
      );

      // Возвращаем null для graceful degradation
      // Калькулятор будет работать с hardcoded defaults
      return null;
    }
  },
);

/// Provider для загрузки общих констант
///
/// Общие константы используются всеми калькуляторами
/// (стандартные запасы, преобразования единиц и т.д.).
///
/// Это shortcut для `calculatorConstantsProvider('common')`.
///
/// Пример использования:
/// ```dart
/// final commonConstants = ref.watch(commonConstantsProvider);
/// ```
final commonConstantsProvider = FutureProvider<CalculatorConstants?>((ref) async {
  return ref.watch(calculatorConstantsProvider('common').future);
});

/// Provider для получения конкретного значения константы
///
/// Семейство providers для быстрого доступа к одному значению
/// без необходимости загружать и парсить все константы.
///
/// Пример использования:
/// ```dart
/// // Параметры: (calculatorId, constantKey, valueKey, defaultValue)
/// final bathroomPower = ref.watch(
///   constantValueProvider(ConstantValueParams(
///     calculatorId: 'warmfloor',
///     constantKey: 'room_power',
///     valueKey: 'bathroom',
///     defaultValue: 180.0,
///   )),
/// );
/// ```
final constantValueProvider = FutureProvider.family<dynamic, ConstantValueParams>(
  (ref, params) async {
    try {
      final repo = ref.watch(constantsRepositoryProvider);
      final value = await repo.getConstantValue(
        params.calculatorId,
        params.constantKey,
        params.valueKey,
        defaultValue: params.defaultValue,
      );
      return value;
    } catch (e, stackTrace) {
      ErrorHandler.logError(
        e,
        stackTrace,
        'ConstantsProvider.constantValue: Failed to get value for ${params.calculatorId}.${params.constantKey}.${params.valueKey}',
      );
      return params.defaultValue;
    }
  },
);

/// Параметры для constantValueProvider
///
/// Используется для передачи множественных параметров в family provider.
class ConstantValueParams {
  final String calculatorId;
  final String constantKey;
  final String valueKey;
  final dynamic defaultValue;

  const ConstantValueParams({
    required this.calculatorId,
    required this.constantKey,
    required this.valueKey,
    this.defaultValue,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConstantValueParams &&
          runtimeType == other.runtimeType &&
          calculatorId == other.calculatorId &&
          constantKey == other.constantKey &&
          valueKey == other.valueKey &&
          defaultValue == other.defaultValue;

  @override
  int get hashCode =>
      calculatorId.hashCode ^
      constantKey.hashCode ^
      valueKey.hashCode ^
      (defaultValue?.hashCode ?? 0);
}
