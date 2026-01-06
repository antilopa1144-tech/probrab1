import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/core/migrations/migration_flag_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InMemoryMigrationFlagStore', () {
    late InMemoryMigrationFlagStore store;

    setUp(() {
      store = InMemoryMigrationFlagStore();
    });

    test('returns null for non-existent key', () async {
      final value = await store.getInt('non_existent');
      expect(value, isNull);
    });

    test('stores and retrieves int value', () async {
      await store.setInt('test_key', 42);
      final value = await store.getInt('test_key');
      expect(value, 42);
    });

    test('overwrites existing value', () async {
      await store.setInt('key', 1);
      expect(await store.getInt('key'), 1);

      await store.setInt('key', 2);
      expect(await store.getInt('key'), 2);
    });

    test('stores multiple keys independently', () async {
      await store.setInt('key1', 10);
      await store.setInt('key2', 20);
      await store.setInt('key3', 30);

      expect(await store.getInt('key1'), 10);
      expect(await store.getInt('key2'), 20);
      expect(await store.getInt('key3'), 30);
    });

    test('handles zero value', () async {
      await store.setInt('zero', 0);
      expect(await store.getInt('zero'), 0);
    });

    test('handles negative value', () async {
      await store.setInt('negative', -5);
      expect(await store.getInt('negative'), -5);
    });

    test('handles large value', () async {
      await store.setInt('large', 2147483647);
      expect(await store.getInt('large'), 2147483647);
    });

    test('handles empty key', () async {
      await store.setInt('', 100);
      expect(await store.getInt(''), 100);
    });

    test('handles special characters in key', () async {
      await store.setInt('migration.calc.v1', 1);
      expect(await store.getInt('migration.calc.v1'), 1);
    });

    test('is isolated between instances', () async {
      final store1 = InMemoryMigrationFlagStore();
      final store2 = InMemoryMigrationFlagStore();

      await store1.setInt('key', 1);

      expect(await store1.getInt('key'), 1);
      expect(await store2.getInt('key'), isNull);
    });
  });

  group('SharedPreferencesMigrationFlagStore', () {
    late SharedPreferencesMigrationFlagStore store;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      store = SharedPreferencesMigrationFlagStore();
    });

    test('returns null for non-existent key', () async {
      final value = await store.getInt('non_existent');
      expect(value, isNull);
    });

    test('stores and retrieves int value', () async {
      await store.setInt('test_key', 42);
      final value = await store.getInt('test_key');
      expect(value, 42);
    });

    test('overwrites existing value', () async {
      await store.setInt('key', 1);
      expect(await store.getInt('key'), 1);

      await store.setInt('key', 2);
      expect(await store.getInt('key'), 2);
    });

    test('stores multiple keys independently', () async {
      await store.setInt('key1', 10);
      await store.setInt('key2', 20);
      await store.setInt('key3', 30);

      expect(await store.getInt('key1'), 10);
      expect(await store.getInt('key2'), 20);
      expect(await store.getInt('key3'), 30);
    });

    test('handles zero value', () async {
      await store.setInt('zero', 0);
      expect(await store.getInt('zero'), 0);
    });

    test('handles negative value', () async {
      await store.setInt('negative', -5);
      expect(await store.getInt('negative'), -5);
    });

    test('persists data to SharedPreferences', () async {
      await store.setInt('persist_key', 123);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('persist_key'), 123);
    });

    test('reads existing SharedPreferences data', () async {
      SharedPreferences.setMockInitialValues({'existing_key': 999});

      final newStore = SharedPreferencesMigrationFlagStore();
      expect(await newStore.getInt('existing_key'), 999);
    });

    test('caches SharedPreferences instance', () async {
      // First call initializes
      await store.getInt('key1');
      // Second call should use cached instance
      await store.getInt('key2');
      // Third call
      await store.setInt('key3', 3);

      // All operations should work without error
      expect(await store.getInt('key3'), 3);
    });
  });

  group('MigrationFlagStore interface', () {
    test('InMemoryMigrationFlagStore implements MigrationFlagStore', () {
      final store = InMemoryMigrationFlagStore();
      expect(store, isA<MigrationFlagStore>());
    });

    test('SharedPreferencesMigrationFlagStore implements MigrationFlagStore',
        () {
      final store = SharedPreferencesMigrationFlagStore();
      expect(store, isA<MigrationFlagStore>());
    });

    test('both implementations are interchangeable', () async {
      Future<void> testStore(MigrationFlagStore store) async {
        await store.setInt('test', 42);
        expect(await store.getInt('test'), 42);
      }

      SharedPreferences.setMockInitialValues({});

      await testStore(InMemoryMigrationFlagStore());
      await testStore(SharedPreferencesMigrationFlagStore());
    });
  });
}
