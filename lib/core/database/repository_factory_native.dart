// Нативная реализация фабрики репозиториев (Android, iOS, Desktop)
// Использует Isar для хранения данных

import 'package:isar_community/isar.dart';
import '../../data/repositories/interfaces/project_repository_interface.dart';
import '../../data/repositories/interfaces/checklist_repository_interface.dart';
import '../../data/repositories/project_repository_v2.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/project_v2.dart';
import '../../domain/models/checklist.dart';
import '../../domain/models/checklist_template.dart';

/// Обёртка над ProjectRepositoryV2 для реализации интерфейса IProjectRepository
class NativeProjectRepositoryWrapper implements IProjectRepository {
  final ProjectRepositoryV2 _repo;

  NativeProjectRepositoryWrapper(this._repo);

  @override
  Future<List<ProjectV2>> getAllProjects() => _repo.getAllProjects();

  @override
  Future<ProjectV2?> getProjectById(int id) => _repo.getProjectById(id);

  @override
  Future<int> createProject(ProjectV2 project) => _repo.createProject(project);

  @override
  Future<void> updateProject(ProjectV2 project) => _repo.updateProject(project);

  @override
  Future<void> deleteProject(int id) => _repo.deleteProject(id);

  @override
  Future<List<ProjectV2>> getFavoriteProjects() => _repo.getFavoriteProjects();

  @override
  Future<List<ProjectV2>> getProjectsByStatus(ProjectStatus status) =>
      _repo.getProjectsByStatus(status);

  @override
  Future<List<ProjectV2>> searchProjects(String query) => _repo.searchProjects(query);

  @override
  Future<void> toggleFavorite(int id) => _repo.toggleFavorite(id);

  @override
  Future<void> addCalculationToProject(int projectId, ProjectCalculation calculation) =>
      _repo.addCalculationToProject(projectId, calculation);

  @override
  Future<void> removeCalculationFromProject(int calculationId) =>
      _repo.removeCalculationFromProject(calculationId);

  @override
  Future<void> toggleMaterialPurchased(int calculationId, int materialIndex) =>
      _repo.toggleMaterialPurchased(calculationId, materialIndex);

  @override
  Future<List<ProjectCalculation>> getProjectCalculations(int projectId) =>
      _repo.getProjectCalculations(projectId);

  @override
  Future<ProjectStatistics> getStatistics() => _repo.getStatistics();

  @override
  Future<void> clearAllProjects() => _repo.clearAllProjects();
}

/// Обёртка над ChecklistRepository для реализации интерфейса IChecklistRepository
class NativeChecklistRepositoryWrapper implements IChecklistRepository {
  final ChecklistRepository _repo;

  NativeChecklistRepositoryWrapper(this._repo);

  @override
  Future<List<RenovationChecklist>> getAllChecklists() => _repo.getAllChecklists();

  @override
  Future<RenovationChecklist?> getChecklistById(int id) => _repo.getChecklistById(id);

  @override
  Future<List<RenovationChecklist>> getChecklistsByProjectId(int projectId) =>
      _repo.getChecklistsByProjectId(projectId);

  @override
  Future<List<RenovationChecklist>> getChecklistsByCategory(ChecklistCategory category) =>
      _repo.getChecklistsByCategory(category);

  @override
  Future<RenovationChecklist> createChecklist(RenovationChecklist checklist) =>
      _repo.createChecklist(checklist);

  @override
  Future<RenovationChecklist> createChecklistFromTemplate(ChecklistTemplate template, {int? projectId}) =>
      _repo.createChecklistFromTemplate(template, projectId: projectId);

  @override
  Future<void> updateChecklist(RenovationChecklist checklist) =>
      _repo.updateChecklist(checklist);

  @override
  Future<void> deleteChecklist(int id) => _repo.deleteChecklist(id);

  @override
  Future<List<ChecklistItem>> getChecklistItems(int checklistId) =>
      _repo.getChecklistItems(checklistId);

  @override
  Future<ChecklistItem> createChecklistItem({
    required int checklistId,
    required String title,
    String? description,
    ChecklistPriority priority = ChecklistPriority.normal,
  }) =>
      _repo.createChecklistItem(
        checklistId: checklistId,
        title: title,
        description: description,
        priority: priority,
      );

  @override
  Future<void> updateChecklistItem(ChecklistItem item) =>
      _repo.updateChecklistItem(item);

  @override
  Future<void> toggleChecklistItem(int itemId) =>
      _repo.toggleChecklistItem(itemId);

  @override
  Future<void> deleteChecklistItem(int itemId) =>
      _repo.deleteChecklistItem(itemId);

  @override
  Future<void> reorderChecklistItems(int checklistId, List<int> itemIds) =>
      _repo.reorderChecklistItems(checklistId, itemIds);

  @override
  Future<ChecklistStats> getOverallStats() => _repo.getOverallStats();

  @override
  Future<ChecklistStats> getProjectStats(int projectId) => _repo.getProjectStats(projectId);

  @override
  Stream<List<RenovationChecklist>> watchAllChecklists() => _repo.watchAllChecklists();

  @override
  Stream<RenovationChecklist?> watchChecklist(int id) => _repo.watchChecklist(id);

  @override
  Stream<List<RenovationChecklist>> watchProjectChecklists(int projectId) =>
      _repo.watchProjectChecklists(projectId);
}

/// Создаёт нативный репозиторий проектов (с Isar)
IProjectRepository createNativeProjectRepository(dynamic isar) {
  return NativeProjectRepositoryWrapper(ProjectRepositoryV2(isar as Isar));
}

/// Создаёт нативный репозиторий чек-листов (с Isar)
IChecklistRepository createNativeChecklistRepository(dynamic isar) {
  return NativeChecklistRepositoryWrapper(ChecklistRepository(isar as Isar));
}
