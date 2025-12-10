import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/database_provider.dart';
import '../../data/repositories/project_repository_v2.dart';
import '../../domain/models/project_v2.dart';

/// Provider для ProjectRepositoryV2
final projectRepositoryV2Provider = Provider<ProjectRepositoryV2>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw Exception('Isar not initialized');
  }
  return ProjectRepositoryV2(isar);
});

/// Provider для списка всех проектов
final allProjectsProvider = FutureProvider<List<ProjectV2>>((ref) async {
  final repository = ref.watch(projectRepositoryV2Provider);
  return repository.getAllProjects();
});

/// Provider для избранных проектов
final favoriteProjectsProvider = FutureProvider<List<ProjectV2>>((ref) async {
  final repository = ref.watch(projectRepositoryV2Provider);
  return repository.getFavoriteProjects();
});

/// Provider для статистики проектов
final projectStatisticsProvider = FutureProvider((ref) async {
  final repository = ref.watch(projectRepositoryV2Provider);
  return repository.getStatistics();
});

/// Provider для конкретного проекта по ID
final projectByIdProvider = FutureProvider.family<ProjectV2?, int>((ref, id) async {
  final repository = ref.watch(projectRepositoryV2Provider);
  return repository.getProjectById(id);
});

/// Provider для расчётов проекта
final projectCalculationsProvider = FutureProvider.family<List<ProjectCalculation>, int>((ref, projectId) async {
  final repository = ref.watch(projectRepositoryV2Provider);
  return repository.getProjectCalculations(projectId);
});

/// StateNotifier для управления проектами
class ProjectV2Notifier extends StateNotifier<AsyncValue<List<ProjectV2>>> {
  final ProjectRepositoryV2 _repository;

  ProjectV2Notifier(this._repository) : super(const AsyncValue.loading()) {
    loadProjects();
  }

  /// Загрузить все проекты
  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    try {
      final projects = await _repository.getAllProjects();
      state = AsyncValue.data(projects);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Создать проект
  Future<int?> createProject(ProjectV2 project) async {
    try {
      final id = await _repository.createProject(project);
      await loadProjects();
      return id;
    } catch (e) {
      return null;
    }
  }

  /// Обновить проект
  Future<void> updateProject(ProjectV2 project) async {
    try {
      await _repository.updateProject(project);
      await loadProjects();
    } catch (e) {
      // Handle error
    }
  }

  /// Удалить проект
  Future<void> deleteProject(int id) async {
    try {
      await _repository.deleteProject(id);
      await loadProjects();
    } catch (e) {
      // Handle error
    }
  }

  /// Переключить избранное
  Future<void> toggleFavorite(int id) async {
    try {
      await _repository.toggleFavorite(id);
      await loadProjects();
    } catch (e) {
      // Handle error
    }
  }
}

/// Provider для ProjectV2Notifier
final projectV2NotifierProvider = StateNotifierProvider<ProjectV2Notifier, AsyncValue<List<ProjectV2>>>((ref) {
  final repository = ref.watch(projectRepositoryV2Provider);
  return ProjectV2Notifier(repository);
});
