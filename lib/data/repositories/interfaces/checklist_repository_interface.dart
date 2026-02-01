import '../../../domain/models/checklist.dart';
import '../../../domain/models/checklist_template.dart';
import '../checklist_repository.dart';

/// Абстрактный интерфейс для репозитория чек-листов.
/// Позволяет использовать разные реализации для разных платформ.
abstract class IChecklistRepository {
  // ============================================================================
  // Чек-листы
  // ============================================================================

  /// Получить все чек-листы
  Future<List<RenovationChecklist>> getAllChecklists();

  /// Получить чек-лист по ID
  Future<RenovationChecklist?> getChecklistById(int id);

  /// Получить чек-листы проекта
  Future<List<RenovationChecklist>> getChecklistsByProjectId(int projectId);

  /// Получить чек-листы по категории
  Future<List<RenovationChecklist>> getChecklistsByCategory(
    ChecklistCategory category,
  );

  /// Создать чек-лист
  Future<RenovationChecklist> createChecklist(RenovationChecklist checklist);

  /// Создать чек-лист из шаблона
  Future<RenovationChecklist> createChecklistFromTemplate(
    ChecklistTemplate template, {
    int? projectId,
  });

  /// Обновить чек-лист
  Future<void> updateChecklist(RenovationChecklist checklist);

  /// Удалить чек-лист
  Future<void> deleteChecklist(int id);

  // ============================================================================
  // Элементы чек-листа
  // ============================================================================

  /// Получить элементы чек-листа
  Future<List<ChecklistItem>> getChecklistItems(int checklistId);

  /// Создать элемент чек-листа
  Future<ChecklistItem> createChecklistItem({
    required int checklistId,
    required String title,
    String? description,
    ChecklistPriority priority = ChecklistPriority.normal,
  });

  /// Обновить элемент чек-листа
  Future<void> updateChecklistItem(ChecklistItem item);

  /// Переключить статус выполнения элемента
  Future<void> toggleChecklistItem(int itemId);

  /// Удалить элемент чек-листа
  Future<void> deleteChecklistItem(int itemId);

  /// Изменить порядок элементов
  Future<void> reorderChecklistItems(int checklistId, List<int> itemIds);

  // ============================================================================
  // Статистика
  // ============================================================================

  /// Получить общую статистику по всем чек-листам
  Future<ChecklistStats> getOverallStats();

  /// Получить статистику по проекту
  Future<ChecklistStats> getProjectStats(int projectId);

  // ============================================================================
  // Watch (для реактивности)
  // ============================================================================

  /// Наблюдать за всеми чек-листами
  Stream<List<RenovationChecklist>> watchAllChecklists();

  /// Наблюдать за чек-листом
  Stream<RenovationChecklist?> watchChecklist(int id);

  /// Наблюдать за чек-листами проекта
  Stream<List<RenovationChecklist>> watchProjectChecklists(int projectId);
}
