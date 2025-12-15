import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'migration_flag_store.dart';

final migrationFlagStoreProvider = Provider<MigrationFlagStore>((ref) {
  return SharedPreferencesMigrationFlagStore();
});

