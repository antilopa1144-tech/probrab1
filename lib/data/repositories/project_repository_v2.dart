import 'package:isar_community/isar.dart';
import '../../domain/models/project_v2.dart';
import '../../core/exceptions/storage_exception.dart';
import '../../core/migrations/migration_flag_store.dart';
import '../../domain/calculators/calculator_id_migration.dart';

/// Репозиторий для работы с проектами (версия 2).
class ProjectRepositoryV2 {
  final Isar isar;

  ProjectRepositoryV2(
    this.isar, {
    MigrationFlagStore? flagStore,
  }) : _flagStore = flagStore ?? InMemoryMigrationFlagStore();

  final MigrationFlagStore _flagStore;

  static const int _calculatorIdMigrationVersion = 1;
  static const String _calculatorIdMigrationKey =
      'migration.projectCalculation.calculatorId.version';

  static const int _materialsMigrationVersion = 1;
  static const String _materialsMigrationKey =
      'migration.projectCalculation.materials.version';

  bool _calculatorIdMigrationDone = false;
  bool _materialsMigrationDone = false;

  Future<void> _ensureCalculatorIdsMigrated() async {
    if (_calculatorIdMigrationDone) return;

    final currentVersion = await _flagStore.getInt(_calculatorIdMigrationKey);
    if (currentVersion != null &&
        currentVersion >= _calculatorIdMigrationVersion) {
      _calculatorIdMigrationDone = true;
      return;
    }

    await migrateLegacyCalculatorIds();
    await _flagStore.setInt(
      _calculatorIdMigrationKey,
      _calculatorIdMigrationVersion,
    );
    _calculatorIdMigrationDone = true;
  }

  Future<void> _ensureMaterialsMigrated() async {
    if (_materialsMigrationDone) return;

    final currentVersion = await _flagStore.getInt(_materialsMigrationKey);
    if (currentVersion != null &&
        currentVersion >= _materialsMigrationVersion) {
      _materialsMigrationDone = true;
      return;
    }

    await initializeEmptyMaterialsLists();
    await _flagStore.setInt(
      _materialsMigrationKey,
      _materialsMigrationVersion,
    );
    _materialsMigrationDone = true;
  }

  /// One-time migration for stored legacy calculator IDs inside projects.
  Future<int> migrateLegacyCalculatorIds() async {
    return isar.writeTxn(() async {
      final all = await isar.projectCalculations.where().findAll();
      final changed = <ProjectCalculation>[];

      for (final calculation in all) {
        final canonical =
            CalculatorIdMigration.canonicalize(calculation.calculatorId);
        if (canonical != calculation.calculatorId) {
          calculation.calculatorId = canonical;
          changed.add(calculation);
        }
      }

      for (final calculation in changed) {
        await isar.projectCalculations.put(calculation);
      }

      return changed.length;
    });
  }

  /// One-time migration to initialize empty materials lists for existing calculations.
  Future<int> initializeEmptyMaterialsLists() async {
    return isar.writeTxn(() async {
      final all = await isar.projectCalculations.where().findAll();
      int updated = 0;

      for (final calculation in all) {
        // Only update if materials list doesn't exist or is not initialized
        // Isar always initializes empty lists, so this is mostly a safety check
        if (calculation.materials.isEmpty) {
          // Already empty/initialized, no action needed
          continue;
        }
        updated++;
      }

      return updated;
    });
  }

  /// Получить все проекты
  Future<List<ProjectV2>> getAllProjects() async {
    try {
      return await isar.projectV2s.where().sortByUpdatedAtDesc().findAll();
    } catch (e) {
      throw StorageException.readError('ProjectV2', e);
    }
  }

  /// Получить проект по ID
  Future<ProjectV2?> getProjectById(int id) async {
    try {
      return await isar.projectV2s.get(id);
    } catch (e) {
      throw StorageException.readError('ProjectV2', e);
    }
  }

  /// Создать новый проект
  Future<int> createProject(ProjectV2 project) async {
    try {
      return await isar.writeTxn(() async {
        return isar.projectV2s.put(project);
      });
    } catch (e) {
      throw StorageException.saveError('ProjectV2', e);
    }
  }

  /// Обновить проект
  Future<void> updateProject(ProjectV2 project) async {
    try {
      project.updatedAt = DateTime.now();
      await isar.writeTxn(() async {
        await isar.projectV2s.put(project);
      });
    } catch (e) {
      throw StorageException.saveError('ProjectV2', e);
    }
  }

  /// Удалить проект
  Future<void> deleteProject(int id) async {
    try {
      await isar.writeTxn(() async {
        // Получаем проект для доступа к расчётам
        final project = await isar.projectV2s.get(id);
        if (project == null) {
          throw StorageException.notFound('ProjectV2', id.toString());
        }

        // Загружаем связанные расчёты
        await project.calculations.load();

        // Удаляем все расчёты проекта (cascade delete)
        final calculationIds = project.calculations.map((c) => c.id).toList();
        if (calculationIds.isNotEmpty) {
          await isar.projectCalculations.deleteAll(calculationIds);
        }

        // Удаляем сам проект
        final success = await isar.projectV2s.delete(id);
        if (!success) {
          throw StorageException.notFound('ProjectV2', id.toString());
        }
      });
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException.deleteError('ProjectV2', e);
    }
  }

  /// Получить избранные проекты
  Future<List<ProjectV2>> getFavoriteProjects() async {
    try {
      return await isar.projectV2s
          .filter()
          .isFavoriteEqualTo(true)
          .sortByUpdatedAtDesc()
          .findAll();
    } catch (e) {
      throw StorageException.readError('ProjectV2', e);
    }
  }

  /// Получить проекты по статусу
  Future<List<ProjectV2>> getProjectsByStatus(ProjectStatus status) async {
    try {
      return await isar.projectV2s
          .filter()
          .statusEqualTo(status)
          .sortByUpdatedAtDesc()
          .findAll();
    } catch (e) {
      throw StorageException.readError('ProjectV2', e);
    }
  }

  /// Поиск проектов по названию
  Future<List<ProjectV2>> searchProjects(String query) async {
    try {
      final lowerQuery = query.toLowerCase();
      return await isar.projectV2s
          .filter()
          .nameContains(lowerQuery, caseSensitive: false)
          .or()
          .optional(
            query.isNotEmpty,
            (q) => q.descriptionContains(lowerQuery, caseSensitive: false),
          )
          .sortByUpdatedAtDesc()
          .findAll();
    } catch (e) {
      throw StorageException.readError('ProjectV2', e);
    }
  }

  /// Переключить избранное
  Future<void> toggleFavorite(int id) async {
    try {
      await isar.writeTxn(() async {
        final project = await isar.projectV2s.get(id);
        if (project != null) {
          project.isFavorite = !project.isFavorite;
          project.updatedAt = DateTime.now();
          await isar.projectV2s.put(project);
        }
      });
    } catch (e) {
      throw StorageException.saveError('ProjectV2', e);
    }
  }

  /// Добавить расчёт к проекту
  Future<void> addCalculationToProject(
    int projectId,
    ProjectCalculation calculation,
  ) async {
    try {
      // Канонизируем calculatorId без миграций (миграции выполняются при старте)
      calculation.calculatorId =
          CalculatorIdMigration.canonicalize(calculation.calculatorId);

      await isar.writeTxn(() async {
        final project = await isar.projectV2s.get(projectId);
        if (project == null) {
          throw StorageException.notFound('ProjectV2', projectId.toString());
        }

        // Сохраняем расчёт сначала
        await isar.projectCalculations.put(calculation);

        // Связываем через прямую связь (IsarLinks), а не через backlink
        // Backlink calculation.project управляется автоматически
        project.calculations.add(calculation);
        await project.calculations.save();

        // Обновляем время проекта
        project.updatedAt = DateTime.now();
        await isar.projectV2s.put(project);
      });
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException.saveError('ProjectCalculation', e);
    }
  }

  /// Удалить расчёт из проекта
  Future<void> removeCalculationFromProject(int calculationId) async {
    try {
      await _ensureCalculatorIdsMigrated();
      await isar.writeTxn(() async {
        final calculation = await isar.projectCalculations.get(calculationId);
        if (calculation != null) {
          // Обновляем время проекта
          final project = calculation.project.value;
          if (project != null) {
            project.updatedAt = DateTime.now();
            await isar.projectV2s.put(project);
          }

          // Удаляем расчёт
          await isar.projectCalculations.delete(calculationId);
        }
      });
    } catch (e) {
      throw StorageException.deleteError('ProjectCalculation', e);
    }
  }

  /// Переключить статус покупки материала
  Future<void> toggleMaterialPurchased(
    int calculationId,
    int materialIndex,
  ) async {
    try {
      await isar.writeTxn(() async {
        final calculation = await isar.projectCalculations.get(calculationId);
        if (calculation == null) {
          throw StorageException.notFound(
            'ProjectCalculation',
            calculationId.toString(),
          );
        }

        if (materialIndex < 0 || materialIndex >= calculation.materials.length) {
          throw StorageException.readError(
            'ProjectMaterial',
            Exception('Invalid material index: $materialIndex'),
          );
        }

        // Переключаем статус покупки
        final material = calculation.materials[materialIndex];
        material.purchased = !material.purchased;
        material.purchasedAt = material.purchased ? DateTime.now() : null;

        // Обновляем расчёт
        calculation.updatedAt = DateTime.now();
        await isar.projectCalculations.put(calculation);

        // Обновляем время проекта
        final project = calculation.project.value;
        if (project != null) {
          project.updatedAt = DateTime.now();
          await isar.projectV2s.put(project);
        }
      });
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException.saveError('ProjectMaterial', e);
    }
  }

  /// Получить все расчёты проекта
  Future<List<ProjectCalculation>> getProjectCalculations(int projectId) async {
    try {
      await _ensureCalculatorIdsMigrated();
      await _ensureMaterialsMigrated();
      final project = await isar.projectV2s.get(projectId);
      if (project == null) {
        throw StorageException.notFound('ProjectV2', projectId.toString());
      }

      await project.calculations.load();
      return project.calculations.toList();
    } catch (e) {
      if (e is StorageException) rethrow;
      throw StorageException.readError('ProjectCalculation', e);
    }
  }

  /// Получить статистику проектов
  Future<ProjectStatistics> getStatistics() async {
    try {
      final total = await isar.projectV2s.count();
      final favorites = await isar.projectV2s
          .filter()
          .isFavoriteEqualTo(true)
          .count();
      final planning = await isar.projectV2s
          .filter()
          .statusEqualTo(ProjectStatus.planning)
          .count();
      final inProgress = await isar.projectV2s
          .filter()
          .statusEqualTo(ProjectStatus.inProgress)
          .count();
      final completed = await isar.projectV2s
          .filter()
          .statusEqualTo(ProjectStatus.completed)
          .count();

      return ProjectStatistics(
        total: total,
        favorites: favorites,
        planning: planning,
        inProgress: inProgress,
        completed: completed,
      );
    } catch (e) {
      throw StorageException.readError('ProjectV2', e);
    }
  }

  /// Очистить все проекты (только для отладки!)
  Future<void> clearAllProjects() async {
    try {
      await isar.writeTxn(() async {
        await isar.projectV2s.clear();
        await isar.projectCalculations.clear();
      });
    } catch (e) {
      throw StorageException.deleteError('ProjectV2', e);
    }
  }
}

/// Статистика по проектам.
class ProjectStatistics {
  final int total;
  final int favorites;
  final int planning;
  final int inProgress;
  final int completed;

  const ProjectStatistics({
    required this.total,
    required this.favorites,
    required this.planning,
    required this.inProgress,
    required this.completed,
  });

  int get active => planning + inProgress;
}
