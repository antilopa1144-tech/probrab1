import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:probrab_ai/data/datasources/local_constants_data_source.dart';
import 'package:probrab_ai/data/datasources/remote_constants_data_source.dart';
import 'package:probrab_ai/data/repositories/constants_repository.dart';
import 'package:probrab_ai/domain/models/calculator_constant.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';

/// Mock LocalConstantsDataSource для тестирования
class MockLocalConstantsDataSource extends LocalConstantsDataSource {
  final Map<String, CalculatorConstants> _mockData = {};
  bool _shouldFail = false;

  void setConstants(String calculatorId, CalculatorConstants constants) {
    _mockData[calculatorId] = constants;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  @override
  Future<CalculatorConstants?> getConstants(String calculatorId) async {
    if (_shouldFail) {
      throw Exception('Failed to load local constants');
    }
    return _mockData[calculatorId];
  }
}

/// Mock RemoteConstantsDataSource для тестирования
class MockRemoteConstantsDataSource {
  final Map<String, CalculatorConstants> _mockData = {};
  bool _isEnabled = false;
  bool _shouldFail = false;
  bool _initializeCalled = false;
  bool _forceRefreshSuccess = true;

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  void setConstants(String calculatorId, CalculatorConstants constants) {
    _mockData[calculatorId] = constants;
  }

  void setShouldFail(bool shouldFail) {
    _shouldFail = shouldFail;
  }

  void setForceRefreshSuccess(bool success) {
    _forceRefreshSuccess = success;
  }

  bool get isInitializeCalled => _initializeCalled;

  bool get isEnabled => _isEnabled;

  String get version => '1.0.0';

  Future<void> initialize() async {
    _initializeCalled = true;
    if (_shouldFail) {
      throw Exception('Failed to initialize Remote Config');
    }
  }

  Future<CalculatorConstants?> getConstants(String calculatorId) async {
    if (_shouldFail) {
      throw Exception('Failed to load remote constants');
    }
    if (!_isEnabled) {
      return null;
    }
    return _mockData[calculatorId];
  }

  Future<bool> forceRefresh() async {
    if (_shouldFail) {
      throw Exception('Failed to force refresh');
    }
    return _forceRefreshSuccess;
  }

  Set<String> getAllKeys() {
    return _mockData.keys.toSet();
  }

  RemoteConfigFetchStatus get lastFetchStatus =>
      RemoteConfigFetchStatus.success;

  DateTime get lastFetchTime => DateTime.now();
}

/// Mock ConstantsRepository для тестирования
class MockConstantsRepository {
  final MockLocalConstantsDataSource _mockLocal;
  final MockRemoteConstantsDataSource _mockRemote;

  MockConstantsRepository(this._mockLocal, this._mockRemote);

  Future<CalculatorConstants?> getConstants(
    String calculatorId, {
    bool forceRefresh = false,
  }) async {
    // Проверяем remote сначала
    if (_mockRemote.isEnabled) {
      try {
        final remote = await _mockRemote.getConstants(calculatorId);
        if (remote != null) return remote;
      } catch (_) {}
    }

    // Fallback на local
    return _mockLocal.getConstants(calculatorId);
  }

  Future<CalculatorConstants?> getCommonConstants({
    bool forceRefresh = false,
  }) async {
    return getConstants('common', forceRefresh: forceRefresh);
  }

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

  void clearCache([String? calculatorId]) {
    // Mock implementation - not needed for tests
  }

  Future<bool> refreshRemoteConfig() async {
    return _mockRemote.forceRefresh();
  }

  Map<String, dynamic> getCacheStats() {
    return {
      'cached_count': 0,
      'calculator_ids': <String>[],
      'timestamps': <String, String>{},
    };
  }

  bool isCached(String calculatorId) {
    return false;
  }
}

void main() {
  late MockLocalConstantsDataSource mockLocalDataSource;
  late MockRemoteConstantsDataSource mockRemoteDataSource;

  setUp(() {
    mockLocalDataSource = MockLocalConstantsDataSource();
    mockRemoteDataSource = MockRemoteConstantsDataSource();
  });

  group('ConstantValueParams', () {
    test('creates instance with required fields', () {
      const params = ConstantValueParams(
        calculatorId: 'warmfloor',
        constantKey: 'room_power',
        valueKey: 'bathroom',
      );

      expect(params.calculatorId, 'warmfloor');
      expect(params.constantKey, 'room_power');
      expect(params.valueKey, 'bathroom');
      expect(params.defaultValue, isNull);
    });

    test('creates instance with default value', () {
      const params = ConstantValueParams(
        calculatorId: 'plaster',
        constantKey: 'consumption',
        valueKey: 'gypsum',
        defaultValue: 8.5,
      );

      expect(params.defaultValue, 8.5);
    });

    test('supports various default value types', () {
      const intParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
        defaultValue: 42,
      );
      expect(intParams.defaultValue, 42);

      const stringParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
        defaultValue: 'default',
      );
      expect(stringParams.defaultValue, 'default');

      const boolParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
        defaultValue: true,
      );
      expect(boolParams.defaultValue, true);
    });

    group('equality', () {
      test('equal params are equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 10.0,
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 10.0,
        );

        expect(params1, equals(params2));
        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('different calculatorId makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc1',
          constantKey: 'const',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc2',
          constantKey: 'const',
          valueKey: 'val',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('different constantKey makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const1',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const2',
          valueKey: 'val',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('different valueKey makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val1',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val2',
        );

        expect(params1, isNot(equals(params2)));
      });

      test('different defaultValue makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 1.0,
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 2.0,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('null vs non-null defaultValue makes params not equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
          defaultValue: 0.0,
        );

        expect(params1, isNot(equals(params2)));
      });

      test('both null defaultValues are equal', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc',
          constantKey: 'const',
          valueKey: 'val',
        );

        expect(params1, equals(params2));
      });
    });

    group('hashCode', () {
      test('same params have same hashCode', () {
        const params1 = ConstantValueParams(
          calculatorId: 'warmfloor',
          constantKey: 'room_power',
          valueKey: 'bathroom',
          defaultValue: 180.0,
        );

        const params2 = ConstantValueParams(
          calculatorId: 'warmfloor',
          constantKey: 'room_power',
          valueKey: 'bathroom',
          defaultValue: 180.0,
        );

        expect(params1.hashCode, equals(params2.hashCode));
      });

      test('different params likely have different hashCodes', () {
        const params1 = ConstantValueParams(
          calculatorId: 'calc1',
          constantKey: 'key1',
          valueKey: 'val1',
        );

        const params2 = ConstantValueParams(
          calculatorId: 'calc2',
          constantKey: 'key2',
          valueKey: 'val2',
        );

        // hashCodes COULD collide but very unlikely for different data
        expect(params1.hashCode, isNot(equals(params2.hashCode)));
      });
    });

    test('can be used as map key', () {
      const params = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
      );

      final map = <ConstantValueParams, String>{};
      map[params] = 'test value';

      const sameParams = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'key',
        valueKey: 'value',
      );

      expect(map[sameParams], 'test value');
    });
  });

  group('localConstantsDataSourceProvider', () {
    test('создаёт экземпляр LocalConstantsDataSource', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dataSource = container.read(localConstantsDataSourceProvider);

      expect(dataSource, isA<LocalConstantsDataSource>());
    });

    test('возвращает один и тот же экземпляр', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dataSource1 = container.read(localConstantsDataSourceProvider);
      final dataSource2 = container.read(localConstantsDataSourceProvider);

      expect(identical(dataSource1, dataSource2), true);
    });
  });

  group('remoteConstantsDataSourceProvider', () {
    test('создаёт экземпляр RemoteConstantsDataSource', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final dataSource = container.read(remoteConstantsDataSourceProvider);

      expect(dataSource, isA<RemoteConstantsDataSource>());
    });
  });

  group('constantsRepositoryProvider', () {
    test('создаёт экземпляр ConstantsRepository', () {
      final container = ProviderContainer(
        overrides: [
          localConstantsDataSourceProvider.overrideWithValue(mockLocalDataSource),
          remoteConstantsDataSourceProvider.overrideWith((ref) => mockRemoteDataSource as RemoteConstantsDataSource),
        ],
      );
      addTearDown(container.dispose);

      final repository = container.read(constantsRepositoryProvider);

      expect(repository, isA<ConstantsRepository>());
    });
  });

  group('remoteConfigInitProvider', () {
    test('успешно инициализирует Remote Config', () async {
      final container = ProviderContainer(
        overrides: [
          remoteConstantsDataSourceProvider.overrideWith((ref) {
            return mockRemoteDataSource as RemoteConstantsDataSource;
          }),
        ],
      );
      addTearDown(container.dispose);

      await container.read(remoteConfigInitProvider.future);

      expect(mockRemoteDataSource.isInitializeCalled, true);
    });

    test('обрабатывает ошибку инициализации gracefully', () async {
      mockRemoteDataSource.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          remoteConstantsDataSourceProvider.overrideWith((ref) {
            return mockRemoteDataSource as RemoteConstantsDataSource;
          }),
        ],
      );
      addTearDown(container.dispose);

      // Не должно выбросить исключение, а залогировать ошибку
      await container.read(remoteConfigInitProvider.future);

      // Проверяем что provider не выбросил исключение
      final state = container.read(remoteConfigInitProvider);
      expect(state.hasValue, true);
    });

    test('состояние loading перед завершением', () {
      final container = ProviderContainer(
        overrides: [
          remoteConstantsDataSourceProvider.overrideWith((ref) {
            return mockRemoteDataSource as RemoteConstantsDataSource;
          }),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(remoteConfigInitProvider);

      expect(state.isLoading, true);
    });
  });

  group('calculatorConstantsProvider', () {
    test('загружает константы из remote когда доступны', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'warmfloor',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'room_power': CalculatorConstant(
            key: 'room_power',
            category: ConstantCategory.power,
            description: 'Мощность по типу помещения',
            unit: 'W/m²',
            values: {'bathroom': 180.0, 'kitchen': 130.0},
          ),
        },
      );

      mockRemoteDataSource.setEnabled(true);
      mockRemoteDataSource.setConstants('warmfloor', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        calculatorConstantsProvider('warmfloor').future,
      );

      expect(result, isNotNull);
      expect(result?.calculatorId, 'warmfloor');
      expect(result?.version, '1.0.0');
      expect(result?.constants.containsKey('room_power'), true);
    });

    test('загружает константы из local когда remote недоступен', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'tile',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'margin': CalculatorConstant(
            key: 'margin',
            category: ConstantCategory.margins,
            description: 'Запас материала',
            unit: 'percent',
            values: {'standard': 10.0},
          ),
        },
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('tile', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        calculatorConstantsProvider('tile').future,
      );

      expect(result, isNotNull);
      expect(result?.calculatorId, 'tile');
    });

    test('возвращает null когда константы не найдены', () async {
      mockRemoteDataSource.setEnabled(false);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        calculatorConstantsProvider('unknown').future,
      );

      expect(result, isNull);
    });

    test('обрабатывает ошибку загрузки и возвращает null', () async {
      mockRemoteDataSource.setEnabled(true);
      mockRemoteDataSource.setShouldFail(true);
      mockLocalDataSource.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      // Не должно выбросить исключение
      final result = await container.read(
        calculatorConstantsProvider('warmfloor').future,
      );

      expect(result, isNull);
    });

    test('кеширует загруженные константы', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'brick',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {},
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('brick', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      // Первая загрузка
      final result1 = await container.read(
        calculatorConstantsProvider('brick').future,
      );

      // Вторая загрузка (должна использовать кеш)
      final result2 = await container.read(
        calculatorConstantsProvider('brick').future,
      );

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(identical(result1, result2), true);
    });

    test('разные калькуляторы загружаются независимо', () async {
      final constants1 = CalculatorConstants(
        calculatorId: 'calc1',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {},
      );

      final constants2 = CalculatorConstants(
        calculatorId: 'calc2',
        version: '2.0.0',
        lastUpdated: DateTime.now(),
        constants: {},
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('calc1', constants1);
      mockLocalDataSource.setConstants('calc2', constants2);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      final result1 = await container.read(
        calculatorConstantsProvider('calc1').future,
      );

      final result2 = await container.read(
        calculatorConstantsProvider('calc2').future,
      );

      expect(result1?.calculatorId, 'calc1');
      expect(result2?.calculatorId, 'calc2');
      expect(result1?.version, '1.0.0');
      expect(result2?.version, '2.0.0');
    });
  });

  group('commonConstantsProvider', () {
    test('загружает общие константы', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'common',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'standard_margin': CalculatorConstant(
            key: 'standard_margin',
            category: ConstantCategory.margins,
            description: 'Стандартный запас',
            unit: 'percent',
            values: {'default': 10.0},
          ),
        },
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('common', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(commonConstantsProvider.future);

      expect(result, isNotNull);
      expect(result?.calculatorId, 'common');
      expect(result?.constants.containsKey('standard_margin'), true);
    });

    test('возвращает null когда общие константы не найдены', () async {
      mockRemoteDataSource.setEnabled(false);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(commonConstantsProvider.future);

      expect(result, isNull);
    });

    test('использует calculatorConstantsProvider с common ID', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'common',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {},
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('common', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      final commonResult = await container.read(commonConstantsProvider.future);
      final directResult = await container.read(
        calculatorConstantsProvider('common').future,
      );

      expect(identical(commonResult, directResult), true);
    });
  });

  group('constantValueProvider', () {
    test('получает конкретное значение константы', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'warmfloor',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'room_power': CalculatorConstant(
            key: 'room_power',
            category: ConstantCategory.power,
            description: 'Мощность',
            values: {'bathroom': 180.0, 'kitchen': 130.0},
          ),
        },
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('warmfloor', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      const params = ConstantValueParams(
        calculatorId: 'warmfloor',
        constantKey: 'room_power',
        valueKey: 'bathroom',
        defaultValue: 150.0,
      );

      final result = await container.read(
        constantValueProvider(params).future,
      );

      expect(result, 180.0);
    });

    test('возвращает defaultValue когда константа не найдена', () async {
      mockRemoteDataSource.setEnabled(false);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      const params = ConstantValueParams(
        calculatorId: 'unknown',
        constantKey: 'unknown_key',
        valueKey: 'unknown_value',
        defaultValue: 100.0,
      );

      final result = await container.read(
        constantValueProvider(params).future,
      );

      expect(result, 100.0);
    });

    test('возвращает defaultValue при ошибке загрузки', () async {
      mockRemoteDataSource.setEnabled(true);
      mockRemoteDataSource.setShouldFail(true);
      mockLocalDataSource.setShouldFail(true);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      const params = ConstantValueParams(
        calculatorId: 'warmfloor',
        constantKey: 'room_power',
        valueKey: 'bathroom',
        defaultValue: 180.0,
      );

      final result = await container.read(
        constantValueProvider(params).future,
      );

      expect(result, 180.0);
    });

    test('получает значения разных типов', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'test',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'values': CalculatorConstant(
            key: 'values',
            category: ConstantCategory.coefficients,
            description: 'Тестовые значения',
            values: {
              'double_value': 3.14,
              'int_value': 42,
              'string_value': 'test',
            },
          ),
        },
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('test', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      const params1 = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'values',
        valueKey: 'double_value',
        defaultValue: 0.0,
      );

      const params2 = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'values',
        valueKey: 'int_value',
        defaultValue: 0,
      );

      final doubleResult = await container.read(
        constantValueProvider(params1).future,
      );
      final intResult = await container.read(
        constantValueProvider(params2).future,
      );

      expect(doubleResult, 3.14);
      expect(intResult, 42);
    });

    test('обрабатывает отсутствующий valueKey', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'test',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'values': CalculatorConstant(
            key: 'values',
            category: ConstantCategory.coefficients,
            description: 'Тестовые значения',
            values: {'existing': 100.0},
          ),
        },
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('test', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      const params = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'values',
        valueKey: 'missing',
        defaultValue: 50.0,
      );

      final result = await container.read(
        constantValueProvider(params).future,
      );

      expect(result, 50.0);
    });

    test('обрабатывает отсутствующий constantKey', () async {
      final testConstants = CalculatorConstants(
        calculatorId: 'test',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {},
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('test', testConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      const params = ConstantValueParams(
        calculatorId: 'test',
        constantKey: 'missing_constant',
        valueKey: 'any',
        defaultValue: 75.0,
      );

      final result = await container.read(
        constantValueProvider(params).future,
      );

      expect(result, 75.0);
    });
  });

  group('Provider интеграция', () {
    test('все providers взаимодействуют корректно', () async {
      final commonConstants = CalculatorConstants(
        calculatorId: 'common',
        version: '1.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'margin': CalculatorConstant(
            key: 'margin',
            category: ConstantCategory.margins,
            description: 'Запас',
            values: {'default': 10.0},
          ),
        },
      );

      final warmfloorConstants = CalculatorConstants(
        calculatorId: 'warmfloor',
        version: '2.0.0',
        lastUpdated: DateTime.now(),
        constants: {
          'power': CalculatorConstant(
            key: 'power',
            category: ConstantCategory.power,
            description: 'Мощность',
            values: {'bathroom': 180.0},
          ),
        },
      );

      mockRemoteDataSource.setEnabled(false);
      mockLocalDataSource.setConstants('common', commonConstants);
      mockLocalDataSource.setConstants('warmfloor', warmfloorConstants);

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      // Загружаем общие константы
      final common = await container.read(commonConstantsProvider.future);
      expect(common?.calculatorId, 'common');

      // Загружаем константы калькулятора
      final warmfloor = await container.read(
        calculatorConstantsProvider('warmfloor').future,
      );
      expect(warmfloor?.calculatorId, 'warmfloor');

      // Получаем конкретное значение
      const params = ConstantValueParams(
        calculatorId: 'warmfloor',
        constantKey: 'power',
        valueKey: 'bathroom',
        defaultValue: 150.0,
      );

      final value = await container.read(
        constantValueProvider(params).future,
      );
      expect(value, 180.0);
    });

    test('несколько providers работают параллельно', () async {
      final constants = {
        'calc1': CalculatorConstants(
          calculatorId: 'calc1',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        ),
        'calc2': CalculatorConstants(
          calculatorId: 'calc2',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        ),
        'calc3': CalculatorConstants(
          calculatorId: 'calc3',
          version: '1.0.0',
          lastUpdated: DateTime.now(),
          constants: {},
        ),
      };

      mockRemoteDataSource.setEnabled(false);
      constants.forEach((id, const_) {
        mockLocalDataSource.setConstants(id, const_);
      });

      final container = ProviderContainer(
        overrides: [
          constantsRepositoryProvider.overrideWith((ref) =>
            MockConstantsRepository(mockLocalDataSource, mockRemoteDataSource) as ConstantsRepository
          ),
        ],
      );
      addTearDown(container.dispose);

      // Загружаем все константы параллельно
      final futures = constants.keys.map(
        (id) => container.read(calculatorConstantsProvider(id).future),
      );

      final results = await Future.wait(futures);

      expect(results.length, 3);
      expect(results.every((r) => r != null), true);
    });
  });
}
