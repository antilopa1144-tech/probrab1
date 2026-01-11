import '../../data/repositories/project_repository_v2.dart';
import '../models/project_v2.dart';

/// Use case для сохранения расчётов в проект
class SaveCalculationUseCase {
  final ProjectRepositoryV2 _repository;

  SaveCalculationUseCase(this._repository);

  /// Сохранить новый расчёт в проект
  ///
  /// Throws [ArgumentError] если projectId недействителен
  /// Throws [StorageException] при ошибках сохранения
  Future<ProjectCalculation> execute({
    required int projectId,
    required ProjectCalculation calculation,
  }) async {
    if (projectId <= 0) {
      throw ArgumentError('Invalid projectId: $projectId');
    }

    // Добавляем расчёт к проекту
    await _repository.addCalculationToProject(projectId, calculation);

    return calculation;
  }

  /// Обновить существующий расчёт
  ///
  /// Примечание: Репозиторий автоматически обновляет расчёт при добавлении
  /// к проекту с тем же ID. Этот метод использует addCalculationToProject
  /// для обновления существующего расчёта.
  ///
  /// Throws [ArgumentError] если calculation.id недействителен
  /// Throws [StorageException] при ошибках обновления
  Future<ProjectCalculation> update({
    required ProjectCalculation calculation,
  }) async {
    if (calculation.id == 0) {
      throw ArgumentError('Cannot update calculation without valid id');
    }

    // Загружаем проект для получения projectId
    await calculation.project.load();
    final project = calculation.project.value;

    if (project == null) {
      throw ArgumentError('Calculation is not associated with a project');
    }

    // Обновляем через addCalculationToProject
    await _repository.addCalculationToProject(project.id, calculation);

    return calculation;
  }

  /// Удалить расчёт из проекта
  ///
  /// Throws [ArgumentError] если calculationId недействителен
  /// Throws [StorageException] при ошибках удаления
  Future<void> delete({
    required int calculationId,
  }) async {
    if (calculationId <= 0) {
      throw ArgumentError('Invalid calculationId: $calculationId');
    }

    await _repository.removeCalculationFromProject(calculationId);
  }
}
