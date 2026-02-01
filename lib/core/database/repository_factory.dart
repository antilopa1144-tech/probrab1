import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/repositories/interfaces/project_repository_interface.dart';
import '../../data/repositories/interfaces/checklist_repository_interface.dart';
import '../../data/repositories/web/web_project_repository.dart';
import '../../data/repositories/web/web_checklist_repository.dart';

// Условный импорт для Isar (только для не-веб платформ)
import 'repository_factory_native.dart'
    if (dart.library.html) 'repository_factory_web.dart' as platform;

/// Фабрика для создания репозиториев в зависимости от платформы.
///
/// На мобильных устройствах использует Isar.
/// На вебе использует SharedPreferences (localStorage).
class RepositoryFactory {
  /// Создаёт репозиторий проектов для текущей платформы.
  static Future<IProjectRepository> createProjectRepository(
    SharedPreferences prefs, {
    dynamic isar, // Isar или null для веба
  }) async {
    if (kIsWeb) {
      return WebProjectRepository(prefs);
    }
    return platform.createNativeProjectRepository(isar);
  }

  /// Создаёт репозиторий чек-листов для текущей платформы.
  static Future<IChecklistRepository> createChecklistRepository(
    SharedPreferences prefs, {
    dynamic isar, // Isar или null для веба
  }) async {
    if (kIsWeb) {
      return WebChecklistRepository(prefs);
    }
    return platform.createNativeChecklistRepository(isar);
  }

  /// Проверяет, работает ли приложение в веб-режиме.
  static bool get isWeb => kIsWeb;
}
