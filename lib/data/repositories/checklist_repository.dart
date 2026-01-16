import 'package:isar_community/isar.dart';
import '../../domain/models/checklist.dart';
import '../../domain/models/checklist_template.dart';

/// Repository для работы с чек-листами
class ChecklistRepository {
  final Isar _isar;

  ChecklistRepository(this._isar);

  // ============================================================================
  // Чек-листы
  // ============================================================================

  /// Получить все чек-листы
  Future<List<RenovationChecklist>> getAllChecklists() async {
    return _isar.renovationChecklists.where().findAll();
  }

  /// Получить чек-лист по ID
  Future<RenovationChecklist?> getChecklistById(int id) async {
    final checklist = await _isar.renovationChecklists.get(id);
    if (checklist != null) {
      await checklist.items.load();
    }
    return checklist;
  }

  /// Получить чек-листы проекта
  Future<List<RenovationChecklist>> getChecklistsByProjectId(int projectId) async {
    final checklists = await _isar.renovationChecklists
        .filter()
        .projectIdEqualTo(projectId)
        .findAll();

    // Загружаем элементы для каждого чек-листа
    for (final checklist in checklists) {
      await checklist.items.load();
    }

    return checklists;
  }

  /// Получить чек-листы по категории
  Future<List<RenovationChecklist>> getChecklistsByCategory(
    ChecklistCategory category,
  ) async {
    return _isar.renovationChecklists
        .filter()
        .categoryEqualTo(category)
        .findAll();
  }

  /// Создать чек-лист
  Future<RenovationChecklist> createChecklist(RenovationChecklist checklist) async {
    await _isar.writeTxn(() async {
      await _isar.renovationChecklists.put(checklist);
    });
    return checklist;
  }

  /// Создать чек-лист из шаблона
  Future<RenovationChecklist> createChecklistFromTemplate(
    ChecklistTemplate template, {
    int? projectId,
  }) async {
    final checklist = template.toChecklist(projectId: projectId);
    final items = template.createItems();

    await _isar.writeTxn(() async {
      // 1. Сохраняем чек-лист
      await _isar.renovationChecklists.put(checklist);

      // 2. Сохраняем элементы
      for (final item in items) {
        await _isar.checklistItems.put(item);
      }

      // 3. Добавляем элементы в коллекцию чек-листа
      checklist.items.addAll(items);

      // 4. Сохраняем связи
      await checklist.items.save();
    });

    // Загружаем связанные элементы
    await checklist.items.load();

    return checklist;
  }

  /// Обновить чек-лист
  Future<void> updateChecklist(RenovationChecklist checklist) async {
    checklist.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.renovationChecklists.put(checklist);
    });
  }

  /// Удалить чек-лист
  Future<void> deleteChecklist(int id) async {
    await _isar.writeTxn(() async {
      // Получаем чек-лист с элементами
      final checklist = await _isar.renovationChecklists.get(id);
      if (checklist != null) {
        await checklist.items.load();

        // Удаляем все элементы
        for (final item in checklist.items) {
          await _isar.checklistItems.delete(item.id);
        }

        // Удаляем чек-лист
        await _isar.renovationChecklists.delete(id);
      }
    });
  }

  // ============================================================================
  // Элементы чек-листа
  // ============================================================================

  /// Получить элементы чек-листа
  Future<List<ChecklistItem>> getChecklistItems(int checklistId) async {
    final checklist = await _isar.renovationChecklists.get(checklistId);
    if (checklist == null) return [];

    await checklist.items.load();
    return checklist.items.toList()..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Создать элемент чек-листа
  Future<ChecklistItem> createChecklistItem({
    required int checklistId,
    required String title,
    String? description,
    ChecklistPriority priority = ChecklistPriority.normal,
  }) async {
    final checklist = await _isar.renovationChecklists.get(checklistId);
    if (checklist == null) {
      throw Exception('Checklist not found');
    }

    await checklist.items.load();
    final maxOrder = checklist.items.isEmpty
        ? 0
        : checklist.items.map((e) => e.order).reduce((a, b) => a > b ? a : b);

    final item = ChecklistItem()
      ..title = title
      ..description = description
      ..isCompleted = false
      ..order = maxOrder + 1
      ..priority = priority
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.checklistItems.put(item);
      checklist.items.add(item);
      await checklist.items.save();
      checklist.updatedAt = DateTime.now();
      await _isar.renovationChecklists.put(checklist);
    });

    return item;
  }

  /// Обновить элемент чек-листа
  Future<void> updateChecklistItem(ChecklistItem item) async {
    item.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.checklistItems.put(item);

      // Обновляем дату чек-листа
      await item.checklist.load();
      if (item.checklist.value != null) {
        item.checklist.value!.updatedAt = DateTime.now();
        await _isar.renovationChecklists.put(item.checklist.value!);
      }
    });
  }

  /// Переключить статус выполнения элемента
  Future<void> toggleChecklistItem(int itemId) async {
    final item = await _isar.checklistItems.get(itemId);
    if (item == null) return;

    await _isar.writeTxn(() async {
      item.isCompleted = !item.isCompleted;
      item.completedAt = item.isCompleted ? DateTime.now() : null;
      item.updatedAt = DateTime.now();
      await _isar.checklistItems.put(item);

      // Обновляем дату чек-листа
      await item.checklist.load();
      if (item.checklist.value != null) {
        item.checklist.value!.updatedAt = DateTime.now();
        await _isar.renovationChecklists.put(item.checklist.value!);
      }
    });
  }

  /// Удалить элемент чек-листа
  Future<void> deleteChecklistItem(int itemId) async {
    await _isar.writeTxn(() async {
      final item = await _isar.checklistItems.get(itemId);
      if (item != null) {
        await item.checklist.load();
        final checklist = item.checklist.value;

        await _isar.checklistItems.delete(itemId);

        // Обновляем дату чек-листа
        if (checklist != null) {
          checklist.updatedAt = DateTime.now();
          await _isar.renovationChecklists.put(checklist);
        }
      }
    });
  }

  /// Изменить порядок элементов
  Future<void> reorderChecklistItems(
    int checklistId,
    List<int> itemIds,
  ) async {
    await _isar.writeTxn(() async {
      for (var i = 0; i < itemIds.length; i++) {
        final item = await _isar.checklistItems.get(itemIds[i]);
        if (item != null) {
          item.order = i;
          item.updatedAt = DateTime.now();
          await _isar.checklistItems.put(item);
        }
      }

      // Обновляем дату чек-листа
      final checklist = await _isar.renovationChecklists.get(checklistId);
      if (checklist != null) {
        checklist.updatedAt = DateTime.now();
        await _isar.renovationChecklists.put(checklist);
      }
    });
  }

  // ============================================================================
  // Статистика
  // ============================================================================

  /// Получить общую статистику по всем чек-листам
  Future<ChecklistStats> getOverallStats() async {
    final checklists = await getAllChecklists();

    var totalItems = 0;
    var completedItems = 0;

    for (final checklist in checklists) {
      await checklist.items.load();
      totalItems += checklist.totalItems;
      completedItems += checklist.completedItems;
    }

    return ChecklistStats(
      totalChecklists: checklists.length,
      totalItems: totalItems,
      completedItems: completedItems,
    );
  }

  /// Получить статистику по проекту
  Future<ChecklistStats> getProjectStats(int projectId) async {
    final checklists = await getChecklistsByProjectId(projectId);

    var totalItems = 0;
    var completedItems = 0;

    for (final checklist in checklists) {
      await checklist.items.load();
      totalItems += checklist.totalItems;
      completedItems += checklist.completedItems;
    }

    return ChecklistStats(
      totalChecklists: checklists.length,
      totalItems: totalItems,
      completedItems: completedItems,
    );
  }

  // ============================================================================
  // Watch (для реактивности)
  // ============================================================================

  /// Наблюдать за всеми чек-листами
  Stream<List<RenovationChecklist>> watchAllChecklists() {
    return _isar.renovationChecklists
        .where()
        .watch(fireImmediately: true)
        .asyncMap((checklists) async {
      // Загружаем items для каждого чек-листа
      for (final checklist in checklists) {
        await checklist.items.load();
      }
      return checklists;
    });
  }

  /// Наблюдать за чек-листом
  Stream<RenovationChecklist?> watchChecklist(int id) {
    return _isar.renovationChecklists
        .where()
        .idEqualTo(id)
        .watch(fireImmediately: true)
        .asyncMap((list) async {
      if (list.isEmpty) return null;
      final checklist = list.first;
      await checklist.items.load();
      return checklist;
    });
  }

  /// Наблюдать за чек-листами проекта
  Stream<List<RenovationChecklist>> watchProjectChecklists(int projectId) {
    return _isar.renovationChecklists
        .filter()
        .projectIdEqualTo(projectId)
        .watch(fireImmediately: true)
        .asyncMap((checklists) async {
      // Загружаем items для каждого чек-листа
      for (final checklist in checklists) {
        await checklist.items.load();
      }
      return checklists;
    });
  }
}

/// Статистика чек-листов
class ChecklistStats {
  final int totalChecklists;
  final int totalItems;
  final int completedItems;

  const ChecklistStats({
    required this.totalChecklists,
    required this.totalItems,
    required this.completedItems,
  });

  double get progress {
    if (totalItems == 0) return 0.0;
    return completedItems / totalItems;
  }

  int get progressPercent => (progress * 100).round();
}
