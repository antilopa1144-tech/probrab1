import '../../data/repositories/project_repository_v2.dart';

/// Use case для удаления проектов
class DeleteProjectUseCase {
  final ProjectRepositoryV2 _repository;

  DeleteProjectUseCase(this._repository);

  /// Удалить проект по ID
  ///
  /// Удаляет проект и все связанные данные (calculations с cascade)
  ///
  /// Throws [ArgumentError] если projectId недействителен
  /// Throws [StorageException] при ошибках удаления
  Future<void> execute({required int projectId}) async {
    if (projectId <= 0) {
      throw ArgumentError('Invalid projectId: $projectId');
    }

    await _repository.deleteProject(projectId);
  }

  /// Удалить несколько проектов
  ///
  /// Throws [ArgumentError] если какой-либо projectId недействителен
  /// Throws [StorageException] при ошибках удаления
  Future<void> deleteMultiple({required List<int> projectIds}) async {
    if (projectIds.isEmpty) {
      throw ArgumentError('projectIds cannot be empty');
    }

    for (final id in projectIds) {
      if (id <= 0) {
        throw ArgumentError('Invalid projectId in list: $id');
      }
    }

    // Удаляем последовательно
    for (final projectId in projectIds) {
      await _repository.deleteProject(projectId);
    }
  }
}
