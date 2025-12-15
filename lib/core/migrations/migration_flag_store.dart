import 'package:shared_preferences/shared_preferences.dart';

abstract class MigrationFlagStore {
  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);
}

/// In-memory implementation for tests.
class InMemoryMigrationFlagStore implements MigrationFlagStore {
  final Map<String, int> _values = {};

  @override
  Future<int?> getInt(String key) async => _values[key];

  @override
  Future<void> setInt(String key, int value) async {
    _values[key] = value;
  }
}

/// Persistent implementation backed by SharedPreferences.
class SharedPreferencesMigrationFlagStore implements MigrationFlagStore {
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    final existing = _prefs;
    if (existing != null) return existing;
    final created = await SharedPreferences.getInstance();
    _prefs = created;
    return created;
  }

  @override
  Future<int?> getInt(String key) async {
    return (await _getPrefs()).getInt(key);
  }

  @override
  Future<void> setInt(String key, int value) async {
    await (await _getPrefs()).setInt(key, value);
  }
}

