import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/project.dart';
import '../../data/repositories/project_repository.dart';
import '../../core/errors/error_handler.dart';

/// Провайдер репозитория проектов
final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository();
});

/// Провайдер для управления проектами через Isar репозиторий.
class ProjectNotifier extends StateNotifier<AsyncValue<List<Project>>> {
  ProjectNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadProjects();
  }

  final ProjectRepository _repository;

  Future<void> _loadProjects() async {
    try {
      state = const AsyncValue.loading();
      final projects = await _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace, 'ProjectNotifier._loadProjects');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addProject(Project project) async {
    try {
      await _repository.saveProject(project);
      await _loadProjects(); // Перезагружаем список
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace, 'ProjectNotifier.addProject');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProject(Project project) async {
    try {
      await _repository.updateProject(project);
      await _loadProjects();
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace, 'ProjectNotifier.updateProject');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _repository.deleteProject(id);
      await _loadProjects();
    } catch (error, stackTrace) {
      ErrorHandler.logError(error, stackTrace, 'ProjectNotifier.deleteProject');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Project?> getProject(String id) async {
    return await _repository.getProject(id);
  }

  /// Обновить список проектов
  Future<void> refresh() => _loadProjects();
}

final projectProvider = 
    StateNotifierProvider<ProjectNotifier, AsyncValue<List<Project>>>(
  (ref) => ProjectNotifier(ref.watch(projectRepositoryProvider)),
);

