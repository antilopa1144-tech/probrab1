import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:probrab_ai/data/datasources/remote_constants_data_source.dart';

/// Fake implementation of FirebaseRemoteConfig for testing
class FakeFirebaseRemoteConfig implements FirebaseRemoteConfig {
  bool _constantsEnabled = false;
  String _constantsVersion = '1.0.0';
  final Map<String, String> _values = {};
  RemoteConfigFetchStatus _lastFetchStatus = RemoteConfigFetchStatus.noFetchYet;
  DateTime _lastFetchTime = DateTime(1970);

  void setConstantsEnabled(bool enabled) {
    _constantsEnabled = enabled;
  }

  void setConstantsVersion(String version) {
    _constantsVersion = version;
  }

  void setValue(String key, String value) {
    _values[key] = value;
  }

  void setFetchStatus(RemoteConfigFetchStatus status) {
    _lastFetchStatus = status;
  }

  @override
  bool getBool(String key) {
    if (key == 'constants_enabled') return _constantsEnabled;
    return false;
  }

  @override
  String getString(String key) {
    if (key == 'constants_version') return _constantsVersion;
    return _values[key] ?? '';
  }

  @override
  RemoteConfigFetchStatus get lastFetchStatus => _lastFetchStatus;

  @override
  DateTime get lastFetchTime => _lastFetchTime;

  @override
  Map<String, RemoteConfigValue> getAll() {
    return _values.map((key, value) => MapEntry(
      key,
      _FakeRemoteConfigValue(value),
    ));
  }

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

  // Not used in tests but required by interface
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeRemoteConfigValue implements RemoteConfigValue {
  final String _value;
  _FakeRemoteConfigValue(this._value);

  @override
  String asString() => _value;

  @override
  int asInt() => int.tryParse(_value) ?? 0;

  @override
  double asDouble() => double.tryParse(_value) ?? 0.0;

  @override
  bool asBool() => _value == 'true';

  @override
  ValueSource get source => ValueSource.valueRemote;
}

void main() {
  group('RemoteConstantsDataSource', () {
    late FakeFirebaseRemoteConfig fakeRemoteConfig;
    late RemoteConstantsDataSource dataSource;

    setUp(() {
      fakeRemoteConfig = FakeFirebaseRemoteConfig();
      dataSource = RemoteConstantsDataSource(fakeRemoteConfig);
    });

    group('initialize', () {
      test('completes without error', () async {
        await expectLater(dataSource.initialize(), completes);
      });

      test('sets up defaults', () async {
        await dataSource.initialize();
        // Should not throw
        expect(dataSource.isEnabled, false);
      });
    });

    group('isEnabled', () {
      test('returns false by default', () {
        expect(dataSource.isEnabled, false);
      });

      test('returns true when enabled', () {
        fakeRemoteConfig.setConstantsEnabled(true);
        expect(dataSource.isEnabled, true);
      });
    });

    group('version', () {
      test('returns default version', () {
        expect(dataSource.version, '1.0.0');
      });

      test('returns configured version', () {
        fakeRemoteConfig.setConstantsVersion('2.0.0');
        expect(dataSource.version, '2.0.0');
      });
    });

    group('getConstants', () {
      test('returns null when disabled', () async {
        fakeRemoteConfig.setConstantsEnabled(false);
        final constants = await dataSource.getConstants('warmfloor');
        expect(constants, isNull);
      });

      test('returns null for empty value when enabled', () async {
        fakeRemoteConfig.setConstantsEnabled(true);
        final constants = await dataSource.getConstants('warmfloor');
        expect(constants, isNull);
      });

      test('returns CalculatorConstants for valid JSON', () async {
        fakeRemoteConfig.setConstantsEnabled(true);
        fakeRemoteConfig.setValue('calculator_constants_warmfloor', '''
{
  "calculator_id": "warmfloor",
  "version": "1.0.0",
  "last_updated": "2026-01-01T00:00:00Z",
  "constants": {
    "room_power": {
      "category": "power",
      "description": "Power by room type",
      "values": {"bathroom": 150, "kitchen": 120}
    }
  }
}
''');

        final constants = await dataSource.getConstants('warmfloor');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'warmfloor');
        expect(constants.version, '1.0.0');
        expect(constants.has('room_power'), true);
      });

      test('returns null for invalid JSON', () async {
        fakeRemoteConfig.setConstantsEnabled(true);
        fakeRemoteConfig.setValue('calculator_constants_warmfloor', 'invalid json');

        final constants = await dataSource.getConstants('warmfloor');
        expect(constants, isNull);
      });

      test('handles case insensitivity in calculator id', () async {
        fakeRemoteConfig.setConstantsEnabled(true);
        fakeRemoteConfig.setValue('calculator_constants_test', '''
{
  "calculator_id": "test",
  "version": "1.0.0",
  "last_updated": "2026-01-01T00:00:00Z",
  "constants": {}
}
''');

        final constants = await dataSource.getConstants('TEST');

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'test');
      });
    });

    group('getCommonConstants', () {
      test('is shortcut for getConstants common', () async {
        fakeRemoteConfig.setConstantsEnabled(true);
        fakeRemoteConfig.setValue('calculator_constants_common', '''
{
  "calculator_id": "common",
  "version": "1.0.0",
  "last_updated": "2026-01-01T00:00:00Z",
  "constants": {}
}
''');

        final constants = await dataSource.getCommonConstants();

        expect(constants, isNotNull);
        expect(constants!.calculatorId, 'common');
      });
    });

    group('forceRefresh', () {
      test('returns true on success', () async {
        final result = await dataSource.forceRefresh();
        expect(result, true);
      });
    });

    group('getAllKeys', () {
      test('returns set of keys', () {
        fakeRemoteConfig.setValue('key1', 'value1');
        fakeRemoteConfig.setValue('key2', 'value2');

        final keys = dataSource.getAllKeys();

        expect(keys, contains('key1'));
        expect(keys, contains('key2'));
      });
    });

    group('lastFetchStatus', () {
      test('returns noFetchYet initially', () {
        expect(dataSource.lastFetchStatus, RemoteConfigFetchStatus.noFetchYet);
      });

      test('returns success after fetch', () async {
        await dataSource.forceRefresh();
        expect(dataSource.lastFetchStatus, RemoteConfigFetchStatus.success);
      });
    });

    group('lastFetchTime', () {
      test('returns epoch initially', () {
        expect(dataSource.lastFetchTime, DateTime(1970));
      });

      test('returns recent time after fetch', () async {
        final before = DateTime.now();
        await dataSource.forceRefresh();
        final after = DateTime.now();

        expect(dataSource.lastFetchTime.isAfter(before.subtract(const Duration(seconds: 1))), true);
        expect(dataSource.lastFetchTime.isBefore(after.add(const Duration(seconds: 1))), true);
      });
    });
  });
}
