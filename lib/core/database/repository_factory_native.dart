// Нативная реализация фабрики репозиториев (Android, iOS, Desktop)
// Использует Isar для хранения данных

import 'package:isar_community/isar.dart';
import '../../data/repositories/interfaces/project_repository_interface.dart';
import '../../data/repositories/interfaces/checklist_repository_interface.dart';
import '../../data/repositories/project_repository_v2.dart';
import '../../data/repositories/checklist_repository.dart';

/// Обёртка над ProjectRepositoryV2 для реализации интерфейса IProjectRepository
class NativeProjectRepositoryWrapper implements IProjectRepository {
  final ProjectRepositoryV2 _repo;

  NativeProjectRepositoryWrapper(this._repo);

  @override
  Future<List> getAllProjects() => _repo.getAllProjects();

  @override
  Future<dynamic> getProjectById(int id) => _repo.getProjectById(id);

  @override
  Future<int> createProject(dynamic project) => _repo.createProject(project);

  @override
  Future<void> updateProject(dynamic project) => _repo.updateProject(project);

  @override
  Future<void> deleteProject(int id) => _repo.deleteProject(id);

  @override
  Future<List> getFavoriteProjects() => _repo.getFavoriteProjects();

  @override
  Future<List> getProjectsByStatus(dynamic status) =>
      _repo.getProjectsByStatus(status);

  @override
  Future<List> searchProjects(String query) => _repo.searchProjects(query);

  @override
  Future<void> toggleFavorite(int id) => _repo.toggleFavorite(id);

  @override
  Future<void> addCalculationToProject(int projectId, dynamic calculation) =>
      _repo.addCalculationToProject(projectId, calculation);

  @override
  Future<void> removeCalculationFromProject(int calculationId) =>
      _repo.removeCalculationFromProject(calculationId);

  @override
  Future<void> toggleMaterialPurchased(int calculationId, int materialIndex) =>
      _repo.toggleMaterialPurchased(calculationId, materialIndex);

  @override
  Future<List> getProjectCalculations(int projectId) =>
      _repo.getProjectCalculations(projectId);

  @override
  Future getStatistics() => _repo.getStatistics();

  @override
  Future<void> clearAllProjects() => _repo.clearAllProjects();
}

/// Обёртка над ChecklistRepository для реализации интерфейса IChecklistRepository
class NativeChecklistRepositoryWrapper implements IChecklistRepository {
  final ChecklistRepository _repo;

  NativeChecklistRepositoryWrapper(this._repo);

  @override
  Future<List> getAllChecklists() => _repo.getAllChecklists();

  @override
  Future<dynamic> getChecklistById(int id) => _repo.getChecklistById(id);

  @override
  Future<List> getChecklistsByProjectId(int projectId) =>
      _repo.getChecklistsByProjectId(projectId);

  @override
  Future<List> getChecklistsByCategory(dynamic category) =>
      _repo.getChecklistsByCategory(category);

  @override
  Future createChecklist(dynamic checklist) => _repo.createChecklist(checklist);

  @override
  Future createChecklistFromTemplate(dynamic template, {int? projectId}) =>
      _repo.createChecklistFromTemplate(template, projectId: projectId);

  @override
  Future<void> updateChecklist(dynamic checklist) =>
      _repo.updateChecklist(checklist);

  @override
  Future<void> deleteChecklist(int id) => _repo.deleteChecklist(id);

  @override
  Future<List> getChecklistItems(int checklistId) =>
      _repo.getChecklistItems(checklistId);

  @override
  Future createChecklistItem({
    required int checklistId,
    required String title,
    String? description,
    dynamic priority,
  }) =>
      _repo.createChecklistItem(
        checklistId: checklistId,
        title: title,
        description: description,
        priority: priority,
      );

  @override
  Future<void> updateChecklistItem(dynamic item) =>
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
  Future getOverallStats() => _repo.getOverallStats();

  @override
  Future getProjectStats(int projectId) => _repo.getProjectStats(projectId);

  @override
  Stream<List> watchAllChecklists() => _repo.watchAllChecklists();

  @override
  Stream<dynamic> watchChecklist(int id) => _repo.watchChecklist(id);

  @override
  Stream<List> watchProjectChecklists(int projectId) =>
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
