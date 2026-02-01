import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/interfaces/project_repository_interface.dart';
import '../../data/repositories/interfaces/checklist_repository_interface.dart';
import '../../data/repositories/web/web_project_repository.dart';
import '../../data/repositories/web/web_checklist_repository.dart';

// Условный импорт для Isar (только для не-веб платформ)
import 'database_provider_native.dart'
    if (dart.library.html) 'database_provider_web.dart' as platform;

/// Провайдер для SharedPreferences (используется на всех платформах)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});

/// Единая точка инициализации базы данных.
/// На мобильных платформах использует Isar.
/// На вебе возвращает null (данные хранятся в SharedPreferences).
final isarProvider = FutureProvider<dynamic>((ref) async {
  if (kIsWeb) {
    // На вебе Isar не используется
    return null;
  }
  return platform.openIsarDatabase();
});

/// Провайдер репозитория проектов.
/// Автоматически выбирает реализацию в зависимости от платформы.
final projectRepositoryProvider = FutureProvider<IProjectRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);

  if (kIsWeb) {
    return WebProjectRepository(prefs);
  }

  final isar = await ref.watch(isarProvider.future);
  return platform.createProjectRepository(isar);
});

/// Провайдер репозитория чек-листов.
/// Автоматически выбирает реализацию в зависимости от платформы.
final checklistRepositoryProvider = FutureProvider<IChecklistRepository>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);

  if (kIsWeb) {
    return WebChecklistRepository(prefs);
  }

  final isar = await ref.watch(isarProvider.future);
  return platform.createChecklistRepository(isar);
});
