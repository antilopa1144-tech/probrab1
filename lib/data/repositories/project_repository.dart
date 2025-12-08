import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/project.dart';
import '../../domain/entities/project.dart';

/// Репозиторий проектов. Предоставляет методы для сохранения, получения и
/// удаления сохранённых проектов в базе данных Isar.
class ProjectRepository {
  static Isar? _isar;

  /// Открывает базу данных если она ещё не открыта.
  Future<Isar> _getDb() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [ProjectModelSchema],
      directory: dir.path,
    );
    return _isar!;
  }

  /// Сохранить проект
  Future<void> saveProject(Project project) async {
    final db = await _getDb();
    final model = ProjectModel.fromDomain(project);
    
    // Проверяем существующий проект
    final existing = await db.projectModels
        .filter()
        .projectIdEqualTo(project.id)
        .findFirst();
    
    if (existing != null) {
      model.id = existing.id;
    }
    
    await db.writeTxn(() async {
      await db.projectModels.put(model);
    });
  }

  /// Получить все проекты
  Future<List<Project>> getAllProjects() async {
    final db = await _getDb();
    final models = await db.projectModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return models.map((m) => m.toDomain()).toList();
  }

  /// Обновить проект
  Future<void> updateProject(Project project) async {
    await saveProject(project); // Isar автоматически обновит по projectId
  }

  /// Удалить проект по String ID
  Future<void> deleteProject(String projectId) async {
    final db = await _getDb();
    final model = await db.projectModels
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    
    if (model != null) {
      await db.writeTxn(() async {
        await db.projectModels.delete(model.id);
      });
    }
  }

  /// Получить проект по String ID
  Future<Project?> getProject(String projectId) async {
    final db = await _getDb();
    final model = await db.projectModels
        .filter()
        .projectIdEqualTo(projectId)
        .findFirst();
    return model?.toDomain();
  }

  /// Закрыть базу данных (для тестирования)
  Future<void> close() async {
    if (_isar != null) {
      await _isar!.close(deleteFromDisk: false);
      _isar = null;
    }
  }
}