import '../../../domain/models/project_v2.dart';
import '../project_repository_v2.dart';

/// Абстрактный интерфейс для репозитория проектов.
/// Позволяет использовать разные реализации для разных платформ:
/// - Isar для мобильных устройств
/// - SharedPreferences/localStorage для веба
abstract class IProjectRepository {
  /// Получить все проекты
  Future<List<ProjectV2>> getAllProjects();

  /// Получить проект по ID
  Future<ProjectV2?> getProjectById(int id);

  /// Создать новый проект
  Future<int> createProject(ProjectV2 project);

  /// Обновить проект
  Future<void> updateProject(ProjectV2 project);

  /// Удалить проект
  Future<void> deleteProject(int id);

  /// Получить избранные проекты
  Future<List<ProjectV2>> getFavoriteProjects();

  /// Получить проекты по статусу
  Future<List<ProjectV2>> getProjectsByStatus(ProjectStatus status);

  /// Поиск проектов по названию
  Future<List<ProjectV2>> searchProjects(String query);

  /// Переключить избранное
  Future<void> toggleFavorite(int id);

  /// Добавить расчёт к проекту
  Future<void> addCalculationToProject(
    int projectId,
    ProjectCalculation calculation,
  );

  /// Удалить расчёт из проекта
  Future<void> removeCalculationFromProject(int calculationId);

  /// Переключить статус покупки материала
  Future<void> toggleMaterialPurchased(
    int calculationId,
    int materialIndex,
  );

  /// Получить все расчёты проекта
  Future<List<ProjectCalculation>> getProjectCalculations(int projectId);

  /// Получить статистику проектов
  Future<ProjectStatistics> getStatistics();

  /// Очистить все проекты (только для отладки!)
  Future<void> clearAllProjects();
}
