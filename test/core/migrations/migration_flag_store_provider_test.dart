import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/migrations/migration_flag_store.dart';
import 'package:probrab_ai/core/migrations/migration_flag_store_provider.dart';

void main() {
  group('migrationFlagStoreProvider', () {
    test('is a Provider', () {
      expect(migrationFlagStoreProvider, isA<Provider<MigrationFlagStore>>());
    });

    test('provides SharedPreferencesMigrationFlagStore', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store = container.read(migrationFlagStoreProvider);
      expect(store, isA<SharedPreferencesMigrationFlagStore>());
    });

    test('returns same type on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final store1 = container.read(migrationFlagStoreProvider);
      final store2 = container.read(migrationFlagStoreProvider);

      expect(store1, isA<MigrationFlagStore>());
      expect(store2, isA<MigrationFlagStore>());
    });
  });
}
