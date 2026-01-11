import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/checklist_repository.dart';
import '../../domain/models/checklist.dart';
import '../../domain/models/checklist_template.dart';
import '../../core/database/database_provider.dart';

/// Provider для ChecklistRepository
final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final isar = ref.watch(isarProvider).value;
  if (isar == null) {
    throw StateError('Isar не инициализирован');
  }
  return ChecklistRepository(isar);
});

/// Provider для всех чек-листов
final allChecklistsProvider = StreamProvider<List<RenovationChecklist>>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return repository.watchAllChecklists();
});

/// Provider для чек-листа по ID
final checklistProvider = StreamProvider.family<RenovationChecklist?, int>((ref, id) {
  final repository = ref.watch(checklistRepositoryProvider);
  return repository.watchChecklist(id);
});

/// Provider для чек-листов проекта
final projectChecklistsProvider = StreamProvider.family<List<RenovationChecklist>, int>((ref, projectId) {
  final repository = ref.watch(checklistRepositoryProvider);
  return repository.watchProjectChecklists(projectId);
});

/// Provider для общей статистики
final checklistStatsProvider = FutureProvider<ChecklistStats>((ref) async {
  final repository = ref.watch(checklistRepositoryProvider);
  return repository.getOverallStats();
});

/// Provider для статистики проекта
final projectChecklistStatsProvider = FutureProvider.family<ChecklistStats, int>((ref, projectId) async {
  final repository = ref.watch(checklistRepositoryProvider);
  return repository.getProjectStats(projectId);
});

/// Provider для доступных шаблонов
final checklistTemplatesProvider = Provider<List<ChecklistTemplate>>((ref) {
  return ChecklistTemplates.all;
});

/// StateNotifier для управления чек-листами
class ChecklistNotifier extends StateNotifier<AsyncValue<void>> {
  final ChecklistRepository _repository;

  ChecklistNotifier(this._repository) : super(const AsyncValue.data(null));

  /// Создать чек-лист
  Future<RenovationChecklist> createChecklist(RenovationChecklist checklist) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createChecklist(checklist);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Создать чек-лист из шаблона
  Future<RenovationChecklist> createFromTemplate(
    ChecklistTemplate template, {
    int? projectId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createChecklistFromTemplate(
        template,
        projectId: projectId,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Обновить чек-лист
  Future<void> updateChecklist(RenovationChecklist checklist) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateChecklist(checklist);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Удалить чек-лист
  Future<void> deleteChecklist(int id) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteChecklist(id);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Добавить элемент в чек-лист
  Future<ChecklistItem> addItem({
    required int checklistId,
    required String title,
    String? description,
    ChecklistPriority priority = ChecklistPriority.normal,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.createChecklistItem(
        checklistId: checklistId,
        title: title,
        description: description,
        priority: priority,
      );
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Обновить элемент
  Future<void> updateItem(ChecklistItem item) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateChecklistItem(item);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Переключить статус элемента
  Future<void> toggleItem(int itemId) async {
    try {
      await _repository.toggleChecklistItem(itemId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Удалить элемент
  Future<void> deleteItem(int itemId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.deleteChecklistItem(itemId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Изменить порядок элементов
  Future<void> reorderItems(int checklistId, List<int> itemIds) async {
    try {
      await _repository.reorderChecklistItems(checklistId, itemIds);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

/// Provider для ChecklistNotifier
final checklistNotifierProvider = StateNotifierProvider<ChecklistNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(checklistRepositoryProvider);
  return ChecklistNotifier(repository);
});
