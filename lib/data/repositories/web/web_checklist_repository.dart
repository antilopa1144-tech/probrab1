import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/models/checklist.dart';
import '../../../domain/models/checklist_template.dart';
import '../interfaces/checklist_repository_interface.dart';
import '../checklist_repository.dart';

/// Веб-реализация репозитория чек-листов.
/// Использует SharedPreferences (localStorage в браузере) для хранения данных.
class WebChecklistRepository implements IChecklistRepository {
  final SharedPreferences _prefs;

  static const String _checklistsKey = 'web_checklists';
  static const String _itemsKey = 'web_checklist_items';
  static const String _idCounterKey = 'web_checklist_id_counter';

  // Кэш для быстрого доступа
  List<RenovationChecklist>? _checklistsCache;
  List<ChecklistItem>? _itemsCache;

  // StreamControllers для реактивности
  final _checklistsController = StreamController<List<RenovationChecklist>>.broadcast();

  WebChecklistRepository(this._prefs);

  int _getNextId() {
    final current = _prefs.getInt(_idCounterKey) ?? 1000; // Начинаем с 1000 для веба
    _prefs.setInt(_idCounterKey, current + 1);
    return current + 1;
  }

  // ============================================================================
  // Сериализация/Десериализация
  // ============================================================================

  Map<String, dynamic> _checklistToJson(RenovationChecklist checklist) {
    return {
      'id': checklist.id,
      'name': checklist.name,
      'description': checklist.description,
      'category': checklist.category.index,
      'projectId': checklist.projectId,
      'createdAt': checklist.createdAt.toIso8601String(),
      'updatedAt': checklist.updatedAt.toIso8601String(),
      'itemIds': checklist.items.map((i) => i.id).toList(),
    };
  }

  RenovationChecklist _checklistFromJson(Map<String, dynamic> json) {
    final checklist = RenovationChecklist()
      ..id = json['id'] as int
      ..name = json['name'] as String
      ..description = json['description'] as String?
      ..category = ChecklistCategory.values[json['category'] as int]
      ..projectId = json['projectId'] as int?
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
    return checklist;
  }

  Map<String, dynamic> _itemToJson(ChecklistItem item) {
    return {
      'id': item.id,
      'checklistId': item.checklist.value?.id,
      'title': item.title,
      'description': item.description,
      'isCompleted': item.isCompleted,
      'priority': item.priority.index,
      'order': item.order,
      'createdAt': item.createdAt.toIso8601String(),
      'updatedAt': item.updatedAt.toIso8601String(),
      'completedAt': item.completedAt?.toIso8601String(),
    };
  }

  ChecklistItem _itemFromJson(Map<String, dynamic> json) {
    final item = ChecklistItem()
      ..id = json['id'] as int
      ..title = json['title'] as String
      ..description = json['description'] as String?
      ..isCompleted = json['isCompleted'] as bool? ?? false
      ..priority = ChecklistPriority.values[json['priority'] as int? ?? 1]
      ..order = json['order'] as int? ?? 0
      ..createdAt = DateTime.parse(json['createdAt'] as String)
      ..updatedAt = DateTime.parse(json['updatedAt'] as String);
    if (json['completedAt'] != null) {
      item.completedAt = DateTime.parse(json['completedAt'] as String);
    }
    return item;
  }

  // ============================================================================
  // Загрузка/Сохранение
  // ============================================================================

  Future<List<RenovationChecklist>> _loadChecklists() async {
    if (_checklistsCache != null) return _checklistsCache!;

    final jsonStr = _prefs.getString(_checklistsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      _checklistsCache = [];
      return _checklistsCache!;
    }

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    _checklistsCache = jsonList.map((j) => _checklistFromJson(j as Map<String, dynamic>)).toList();

    // Загружаем элементы и связываем
    final items = await _loadItems();
    for (final checklist in _checklistsCache!) {
      final checklistItems = items.where((i) =>
        i.checklist.value?.id == checklist.id
      ).toList()..sort((a, b) => a.order.compareTo(b.order));
      checklist.items.addAll(checklistItems);
    }

    return _checklistsCache!;
  }

  Future<void> _saveChecklists() async {
    final jsonList = _checklistsCache!.map(_checklistToJson).toList();
    await _prefs.setString(_checklistsKey, jsonEncode(jsonList));
    _notifyListeners();
  }

  Future<List<ChecklistItem>> _loadItems() async {
    if (_itemsCache != null) return _itemsCache!;

    final jsonStr = _prefs.getString(_itemsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      _itemsCache = [];
      return _itemsCache!;
    }

    final List<dynamic> jsonList = jsonDecode(jsonStr);
    _itemsCache = jsonList.map((j) => _itemFromJson(j as Map<String, dynamic>)).toList();
    return _itemsCache!;
  }

  Future<void> _saveItems() async {
    final jsonList = _itemsCache!.map(_itemToJson).toList();
    await _prefs.setString(_itemsKey, jsonEncode(jsonList));
  }

  void _notifyListeners() {
    if (_checklistsCache != null) {
      _checklistsController.add(_checklistsCache!.toList());
    }
  }

  // ============================================================================
  // Реализация интерфейса - Чек-листы
  // ============================================================================

  @override
  Future<List<RenovationChecklist>> getAllChecklists() async {
    return _loadChecklists();
  }

  @override
  Future<RenovationChecklist?> getChecklistById(int id) async {
    final checklists = await _loadChecklists();
    try {
      return checklists.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<RenovationChecklist>> getChecklistsByProjectId(int projectId) async {
    final checklists = await _loadChecklists();
    return checklists.where((c) => c.projectId == projectId).toList();
  }

  @override
  Future<List<RenovationChecklist>> getChecklistsByCategory(
    ChecklistCategory category,
  ) async {
    final checklists = await _loadChecklists();
    return checklists.where((c) => c.category == category).toList();
  }

  @override
  Future<RenovationChecklist> createChecklist(RenovationChecklist checklist) async {
    await _loadChecklists();
    checklist.id = _getNextId();
    checklist.createdAt = DateTime.now();
    checklist.updatedAt = DateTime.now();
    _checklistsCache!.add(checklist);
    await _saveChecklists();
    return checklist;
  }

  @override
  Future<RenovationChecklist> createChecklistFromTemplate(
    ChecklistTemplate template, {
    int? projectId,
  }) async {
    await _loadChecklists();
    await _loadItems();

    final checklist = template.toChecklist(projectId: projectId);
    checklist.id = _getNextId();
    checklist.createdAt = DateTime.now();
    checklist.updatedAt = DateTime.now();

    final items = template.createItems();
    for (final item in items) {
      item.id = _getNextId();
      item.createdAt = DateTime.now();
      item.updatedAt = DateTime.now();
      item.checklist.value = checklist;
      _itemsCache!.add(item);
      checklist.items.add(item);
    }

    _checklistsCache!.add(checklist);

    await _saveItems();
    await _saveChecklists();

    return checklist;
  }

  @override
  Future<void> updateChecklist(RenovationChecklist checklist) async {
    await _loadChecklists();
    final index = _checklistsCache!.indexWhere((c) => c.id == checklist.id);
    if (index != -1) {
      checklist.updatedAt = DateTime.now();
      _checklistsCache![index] = checklist;
      await _saveChecklists();
    }
  }

  @override
  Future<void> deleteChecklist(int id) async {
    await _loadChecklists();
    await _loadItems();

    // Удаляем связанные элементы
    _itemsCache!.removeWhere((i) => i.checklist.value?.id == id);
    await _saveItems();

    // Удаляем чек-лист
    _checklistsCache!.removeWhere((c) => c.id == id);
    await _saveChecklists();
  }

  // ============================================================================
  // Реализация интерфейса - Элементы
  // ============================================================================

  @override
  Future<List<ChecklistItem>> getChecklistItems(int checklistId) async {
    await _loadItems();
    return _itemsCache!.where((i) => i.checklist.value?.id == checklistId).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  @override
  Future<ChecklistItem> createChecklistItem({
    required int checklistId,
    required String title,
    String? description,
    ChecklistPriority priority = ChecklistPriority.normal,
  }) async {
    await _loadChecklists();
    await _loadItems();

    final checklist = _checklistsCache!.firstWhere((c) => c.id == checklistId);

    final maxOrder = checklist.items.isEmpty
        ? 0
        : checklist.items.map((e) => e.order).reduce((a, b) => a > b ? a : b);

    final item = ChecklistItem()
      ..id = _getNextId()
      ..title = title
      ..description = description
      ..isCompleted = false
      ..order = maxOrder + 1
      ..priority = priority
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    item.checklist.value = checklist;
    _itemsCache!.add(item);
    checklist.items.add(item);
    checklist.updatedAt = DateTime.now();

    await _saveItems();
    await _saveChecklists();

    return item;
  }

  @override
  Future<void> updateChecklistItem(ChecklistItem item) async {
    await _loadItems();
    final index = _itemsCache!.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      item.updatedAt = DateTime.now();
      _itemsCache![index] = item;
      await _saveItems();
    }
  }

  @override
  Future<void> toggleChecklistItem(int itemId) async {
    await _loadItems();
    await _loadChecklists();

    final item = _itemsCache!.firstWhere((i) => i.id == itemId);
    item.isCompleted = !item.isCompleted;
    item.completedAt = item.isCompleted ? DateTime.now() : null;
    item.updatedAt = DateTime.now();

    final checklist = item.checklist.value;
    if (checklist != null) {
      checklist.updatedAt = DateTime.now();
      await _saveChecklists();
    }

    await _saveItems();
  }

  @override
  Future<void> deleteChecklistItem(int itemId) async {
    await _loadItems();
    await _loadChecklists();

    final item = _itemsCache!.firstWhere((i) => i.id == itemId);
    final checklist = item.checklist.value;

    _itemsCache!.removeWhere((i) => i.id == itemId);

    if (checklist != null) {
      checklist.items.removeWhere((i) => i.id == itemId);
      checklist.updatedAt = DateTime.now();
      await _saveChecklists();
    }

    await _saveItems();
  }

  @override
  Future<void> reorderChecklistItems(int checklistId, List<int> itemIds) async {
    await _loadItems();
    await _loadChecklists();

    for (var i = 0; i < itemIds.length; i++) {
      final item = _itemsCache!.firstWhere((it) => it.id == itemIds[i]);
      item.order = i;
      item.updatedAt = DateTime.now();
    }

    final checklist = _checklistsCache!.firstWhere((c) => c.id == checklistId);
    checklist.updatedAt = DateTime.now();

    await _saveItems();
    await _saveChecklists();
  }

  // ============================================================================
  // Статистика
  // ============================================================================

  @override
  Future<ChecklistStats> getOverallStats() async {
    final checklists = await _loadChecklists();

    var totalItems = 0;
    var completedItems = 0;

    for (final checklist in checklists) {
      totalItems += checklist.totalItems;
      completedItems += checklist.completedItems;
    }

    return ChecklistStats(
      totalChecklists: checklists.length,
      totalItems: totalItems,
      completedItems: completedItems,
    );
  }

  @override
  Future<ChecklistStats> getProjectStats(int projectId) async {
    final checklists = await getChecklistsByProjectId(projectId);

    var totalItems = 0;
    var completedItems = 0;

    for (final checklist in checklists) {
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

  @override
  Stream<List<RenovationChecklist>> watchAllChecklists() async* {
    // Сначала отдаём текущие данные
    yield await _loadChecklists();
    // Затем слушаем изменения
    yield* _checklistsController.stream;
  }

  @override
  Stream<RenovationChecklist?> watchChecklist(int id) async* {
    yield await getChecklistById(id);
    yield* _checklistsController.stream.asyncMap((list) async {
      try {
        return list.firstWhere((c) => c.id == id);
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Stream<List<RenovationChecklist>> watchProjectChecklists(int projectId) async* {
    yield await getChecklistsByProjectId(projectId);
    yield* _checklistsController.stream.asyncMap((list) async {
      return list.where((c) => c.projectId == projectId).toList();
    });
  }
}
