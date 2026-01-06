import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:probrab_ai/data/repositories/constants_repository.dart';
import 'package:probrab_ai/data/datasources/local_constants_data_source.dart';
import 'package:probrab_ai/data/datasources/remote_constants_data_source.dart';

/// Fake implementation of FirebaseRemoteConfig for testing
class FakeFirebaseRemoteConfig implements FirebaseRemoteConfig {
  bool _constantsEnabled = false;
  final Map<String, String> _values = {};
  RemoteConfigFetchStatus _lastFetchStatus = RemoteConfigFetchStatus.noFetchYet;
  DateTime _lastFetchTime = DateTime(1970);

  void setConstantsEnabled(bool enabled) {
    _constantsEnabled = enabled;
  }

  void setValue(String key, String value) {
    _values[key] = value;
  }

  @override
  bool getBool(String key) {
    if (key == 'constants_enabled') return _constantsEnabled;
    return false;
  }

  @override
  String getString(String key) {
    if (key == 'constants_version') return '1.0.0';
    return _values[key] ?? '';
  }

  @override
  RemoteConfigFetchStatus get lastFetchStatus => _lastFetchStatus;

  @override
  DateTime get lastFetchTime => _lastFetchTime;

  @override
  Map<String, RemoteConfigValue> getAll() => {};

  @override
  Future<void> setConfigSettings(RemoteConfigSettings settings) async {}

  @override
  Future<void> setDefaults(Map<String, dynamic> defaults) async {}

  @override
  Future<bool> fetchAndActivate() async {
    _lastFetchStatus = RemoteConfigFetchStatus.success;
    _lastFetchTime = DateTime.now();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConstantsRepository', () {
    late LocalConstantsDataSource localDataSource;
    late FakeFirebaseRemoteConfig fakeRemoteConfig;
    late RemoteConstantsDataSource remoteDataSource;
    late ConstantsRepository repository;

    setUp(() {
      localDataSource = LocalConstantsDataSource();
      fakeRemoteConfig = FakeFirebaseRemoteConfig();
      remoteDataSource = RemoteConstantsDataSource(fakeRemoteConfig);
      repository = ConstantsRepository(localDataSource, remoteDataSource);
    });

    group('getConstants', () {
      test('returns constants from local source when remote is disabled', () async {
        fakeRemoteConfig.setConstantsEnabled(false);

        final constants = await repository.getConstants('warmfloor');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'warmfloor');
      });

      test('returns constants from remote when enabled and available', () async {
        fakeRemoteConfig.setConstantsEnabled(true);
        fakeRemoteConfig.setValue('calculator_constants_warmfloor', '''
{
  "calculator_id": "warmfloor",
  "version": "2.0.0",
  "last_updated": "2026-01-01T00:00:00Z",
  "constants": {
    "room_power": {
      "category": "power",
      "description": "Power by room type",
      "values": {"bathroom": 200}
    }
  }
}
''');

        final constants = await repository.getConstants('warmfloor');

        expect(constants, isNotNull);
        expect(constants!.version, '2.0.0');
      });

      test('falls back to local when remote returns empty', () async {
        fakeRemoteConfig.setConstantsEnabled(true);
        // No value set for warmfloor

        final constants = await repository.getConstants('warmfloor');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'warmfloor');
      });

      test('returns null for non-existent calculator', () async {
        final constants = await repository.getConstants('nonexistent_calc');

        expect(constants, isNull);
      });

      test('loads various calculators successfully', () async {
        final calculators = ['warmfloor', 'electrical', 'gasblock', 'tile', 'gypsum', 'putty'];

        for (final id in calculators) {
          final constants = await repository.getConstants(id);
          expect(constants, isNotNull, reason: 'Failed to load $id');
          expect(constants!.calculatorId, id);
        }
      });
    });

    group('caching', () {
      test('caches loaded constants', () async {
        expect(repository.isCached('warmfloor'), false);

        await repository.getConstants('warmfloor');

        expect(repository.isCached('warmfloor'), true);
      });

      test('uses cached value on subsequent calls', () async {
        final constants1 = await repository.getConstants('warmfloor');
        final constants2 = await repository.getConstants('warmfloor');

        expect(identical(constants1, constants2), true);
      });

      test('forceRefresh bypasses cache', () async {
        await repository.getConstants('warmfloor');
        expect(repository.isCached('warmfloor'), true);

        // Force refresh should reload
        final constants = await repository.getConstants('warmfloor', forceRefresh: true);

        expect(constants, isNotNull);
      });

      test('clearCache removes specific calculator', () async {
        await repository.getConstants('warmfloor');
        await repository.getConstants('electrical');

        repository.clearCache('warmfloor');

        expect(repository.isCached('warmfloor'), false);
        expect(repository.isCached('electrical'), true);
      });

      test('clearCache removes all when no id specified', () async {
        await repository.getConstants('warmfloor');
        await repository.getConstants('electrical');

        repository.clearCache();

        expect(repository.isCached('warmfloor'), false);
        expect(repository.isCached('electrical'), false);
      });
    });

    group('getCommonConstants', () {
      test('is shortcut for getConstants common', () async {
        final common1 = await repository.getCommonConstants();
        final common2 = await repository.getConstants('common');

        // Both should be null or equal
        expect(common1 == null, common2 == null);
      });
    });

    group('getConstantValue', () {
      test('returns double value', () async {
        final value = await repository.getConstantValue<double>(
          'warmfloor',
          'room_power',
          'bathroom',
          defaultValue: 0.0,
        );

        expect(value, isNotNull);
        expect(value, greaterThan(0));
      });

      test('returns default for missing constant', () async {
        final value = await repository.getConstantValue<double>(
          'warmfloor',
          'nonexistent',
          'key',
          defaultValue: 42.0,
        );

        expect(value, 42.0);
      });

      test('returns default for missing value', () async {
        final value = await repository.getConstantValue<double>(
          'warmfloor',
          'room_power',
          'nonexistent_room',
          defaultValue: 99.0,
        );

        expect(value, 99.0);
      });

      test('returns default for non-existent calculator', () async {
        final value = await repository.getConstantValue<double>(
          'nonexistent',
          'constant',
          'key',
          defaultValue: 123.0,
        );

        expect(value, 123.0);
      });

      test('converts int to double', () async {
        // room_power values are typically stored as ints
        final value = await repository.getConstantValue<double>(
          'warmfloor',
          'room_power',
          'bathroom',
          defaultValue: 0.0,
        );

        expect(value, isA<double>());
      });
    });

    group('refreshRemoteConfig', () {
      test('returns true on success', () async {
        final result = await repository.refreshRemoteConfig();

        expect(result, true);
      });

      test('clears cache after refresh', () async {
        await repository.getConstants('warmfloor');
        expect(repository.isCached('warmfloor'), true);

        await repository.refreshRemoteConfig();

        expect(repository.isCached('warmfloor'), false);
      });
    });

    group('getCacheStats', () {
      test('returns empty stats initially', () {
        final stats = repository.getCacheStats();

        expect(stats['cached_count'], 0);
        expect((stats['calculator_ids'] as List), isEmpty);
      });

      test('returns correct stats after loading', () async {
        await repository.getConstants('warmfloor');
        await repository.getConstants('electrical');

        final stats = repository.getCacheStats();

        expect(stats['cached_count'], 2);
        expect((stats['calculator_ids'] as List), contains('warmfloor'));
        expect((stats['calculator_ids'] as List), contains('electrical'));
        expect((stats['timestamps'] as Map).containsKey('warmfloor'), true);
        expect((stats['timestamps'] as Map).containsKey('electrical'), true);
      });
    });
  });
}
