import 'package:isar/isar.dart';
import '../../domain/models/project_v2.dart';
import '../../core/exceptions/storage_exception.dart';

/// Репозиторий для работы с проектами (версия 2).
class ProjectRepositoryV2 {
  final Isar isar;

  ProjectRepositoryV2(this.isar);

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
        return await isar.projectV2s.put(project);
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
      await isar.writeTxn(() async {
        final project = await isar.projectV2s.get(projectId);
        if (project == null) {
          throw StorageException.notFound('ProjectV2', projectId.toString());
        }

        // Сохраняем расчёт
        await isar.projectCalculations.put(calculation);

        // Связываем с проектом
        calculation.project.value = project;
        await calculation.project.save();

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

  /// Получить все расчёты проекта
  Future<List<ProjectCalculation>> getProjectCalculations(int projectId) async {
    try {
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
