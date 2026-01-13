import '../../data/repositories/checklist_repository.dart';
import '../models/checklist.dart';
import '../models/checklist_template.dart';

/// Use case для создания чек-листов
class CreateChecklistUseCase {
  final ChecklistRepository _repository;

  CreateChecklistUseCase(this._repository);

  /// Создать пустой чек-лист
  ///
  /// Throws [ArgumentError] если обязательные поля пусты
  /// Throws [Exception] при ошибках создания
  Future<RenovationChecklist> execute({
    required String name,
    String? description,
    required ChecklistCategory category,
    int? projectId,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Checklist name cannot be empty');
    }

    final checklist = RenovationChecklist()
      ..name = name
      ..description = description
      ..category = category
      ..projectId = projectId
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    return _repository.createChecklist(checklist);
  }

  /// Создать чек-лист из шаблона
  ///
  /// Throws [ArgumentError] если template null
  /// Throws [Exception] при ошибках создания
  Future<RenovationChecklist> executeFromTemplate({
    required ChecklistTemplate template,
    int? projectId,
  }) async {
    return _repository.createChecklistFromTemplate(
      template,
      projectId: projectId,
    );
  }

  /// Создать чек-лист с пользовательскими элементами
  ///
  /// Throws [ArgumentError] если обязательные поля пусты или items пуст
  /// Throws [Exception] при ошибках создания
  Future<RenovationChecklist> executeWithItems({
    required String name,
    String? description,
    required ChecklistCategory category,
    required List<String> itemTitles,
    int? projectId,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('Checklist name cannot be empty');
    }

    if (itemTitles.isEmpty) {
      throw ArgumentError('At least one item is required');
    }

    final checklist = RenovationChecklist()
      ..name = name
      ..description = description
      ..category = category
      ..projectId = projectId
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    final created = await _repository.createChecklist(checklist);

    // Добавляем элементы
    for (var i = 0; i < itemTitles.length; i++) {
      final title = itemTitles[i].trim();
      if (title.isNotEmpty) {
        await _repository.createChecklistItem(
          checklistId: created.id,
          title: title,
        );
      }
    }

    // Возвращаем обновлённый чек-лист с элементами
    return (await _repository.getChecklistById(created.id))!;
  }
}
