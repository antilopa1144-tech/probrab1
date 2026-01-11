import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:probrab_ai/data/repositories/checklist_repository.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';

void main() {
  late Isar isar;
  late ChecklistRepository repository;

  setUp(() async {
    // Создаём in-memory Isar для тестов
    isar = await Isar.open(
      [RenovationChecklistSchema, ChecklistItemSchema],
      directory: '',
      name: 'test_checklist_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = ChecklistRepository(isar);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('ChecklistRepository - Создание чек-листов', () {
    test('createChecklist создаёт и сохраняет чек-лист', () async {
      final checklist = RenovationChecklist()
        ..name = 'Тестовый чек-лист'
        ..description = 'Описание'
        ..category = ChecklistCategory.room
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final result = await repository.createChecklist(checklist);

      expect(result.id, isNot(Isar.autoIncrement));
      expect(result.name, 'Тестовый чек-лист');

      // Проверяем, что сохранилось в БД
      final fromDb = await repository.getChecklistById(result.id);
      expect(fromDb, isNotNull);
      expect(fromDb!.name, 'Тестовый чек-лист');
    });

    test('createChecklistFromTemplate создаёт чек-лист с элементами', () async {
      final template = ChecklistTemplates.bathroomRenovation;

      final checklist = await repository.createChecklistFromTemplate(template);

      expect(checklist.id, isNot(Isar.autoIncrement));
      expect(checklist.name, template.name);
      expect(checklist.category, template.category);
      expect(checklist.isFromTemplate, true);
      expect(checklist.templateId, template.id);
      expect(checklist.items.length, template.items.length);

      // Проверяем, что элементы правильно связаны
      for (final item in checklist.items) {
        await item.checklist.load();
        expect(item.checklist.value, isNotNull);
        expect(item.checklist.value!.id, checklist.id);
      }
    });

    test('createChecklistFromTemplate с projectId привязывает к проекту', () async {
      final template = ChecklistTemplates.roomRenovation;
      const projectId = 42;

      final checklist = await repository.createChecklistFromTemplate(
        template,
        projectId: projectId,
      );

      expect(checklist.projectId, projectId);
    });
  });

  group('ChecklistRepository - Чтение чек-листов', () {
    test('getChecklistById возвращает чек-лист с элементами', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      final result = await repository.getChecklistById(checklist.id);

      expect(result, isNotNull);
      expect(result!.id, checklist.id);
      expect(result.items.isNotEmpty, true);
    });

    test('getChecklistById возвращает null для несуществующего ID', () async {
      final result = await repository.getChecklistById(99999);

      expect(result, isNull);
    });

    test('getAllChecklists возвращает все чек-листы', () async {
      await repository.createChecklistFromTemplate(ChecklistTemplates.roomRenovation);
      await repository.createChecklistFromTemplate(ChecklistTemplates.bathroomRenovation);
      await repository.createChecklistFromTemplate(ChecklistTemplates.kitchenRenovation);

      final result = await repository.getAllChecklists();

      expect(result.length, 3);
    });

    test('getChecklistsByProjectId возвращает только чек-листы проекта', () async {
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
        projectId: 1,
      );
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.bathroomRenovation,
        projectId: 1,
      );
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.kitchenRenovation,
        projectId: 2,
      );

      final project1 = await repository.getChecklistsByProjectId(1);
      final project2 = await repository.getChecklistsByProjectId(2);

      expect(project1.length, 2);
      expect(project2.length, 1);
    });

    test('getChecklistsByCategory возвращает чек-листы по категории', () async {
      await repository.createChecklistFromTemplate(ChecklistTemplates.roomRenovation);
      await repository.createChecklistFromTemplate(ChecklistTemplates.bathroomRenovation);
      await repository.createChecklistFromTemplate(ChecklistTemplates.roomRenovation);

      final rooms = await repository.getChecklistsByCategory(ChecklistCategory.room);
      final bathrooms = await repository.getChecklistsByCategory(ChecklistCategory.bathroom);

      expect(rooms.length, 2);
      expect(bathrooms.length, 1);
    });
  });

  group('ChecklistRepository - Обновление чек-листов', () {
    test('updateChecklist обновляет чек-лист', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      checklist.name = 'Новое название';
      await repository.updateChecklist(checklist);

      final updated = await repository.getChecklistById(checklist.id);
      expect(updated!.name, 'Новое название');
    });

    test('updateChecklist обновляет updatedAt', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final originalUpdatedAt = checklist.updatedAt;

      await Future.delayed(const Duration(milliseconds: 10));

      checklist.name = 'Новое название';
      await repository.updateChecklist(checklist);

      final updated = await repository.getChecklistById(checklist.id);
      expect(updated!.updatedAt.isAfter(originalUpdatedAt), true);
    });
  });

  group('ChecklistRepository - Удаление чек-листов', () {
    test('deleteChecklist удаляет чек-лист и его элементы', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final itemIds = checklist.items.map((e) => e.id).toList();

      await repository.deleteChecklist(checklist.id);

      // Проверяем, что чек-лист удалён
      final deletedChecklist = await repository.getChecklistById(checklist.id);
      expect(deletedChecklist, isNull);

      // Проверяем, что элементы тоже удалены
      for (final itemId in itemIds) {
        final item = await isar.checklistItems.get(itemId);
        expect(item, isNull);
      }
    });
  });

  group('ChecklistRepository - Работа с элементами', () {
    test('createChecklistItem создаёт элемент и добавляет в чек-лист', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final initialCount = checklist.items.length;

      final item = await repository.createChecklistItem(
        checklistId: checklist.id,
        title: 'Новая задача',
        description: 'Описание задачи',
        priority: ChecklistPriority.high,
      );

      expect(item.id, isNot(Isar.autoIncrement));
      expect(item.title, 'Новая задача');
      expect(item.priority, ChecklistPriority.high);

      // Проверяем, что элемент добавился в чек-лист
      final updated = await repository.getChecklistById(checklist.id);
      expect(updated!.items.length, initialCount + 1);
    });

    test('createChecklistItem устанавливает правильный order', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final maxOrder = checklist.items.map((e) => e.order).reduce((a, b) => a > b ? a : b);

      final item = await repository.createChecklistItem(
        checklistId: checklist.id,
        title: 'Новая задача',
      );

      expect(item.order, maxOrder + 1);
    });

    test('getChecklistItems возвращает элементы в правильном порядке', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      final items = await repository.getChecklistItems(checklist.id);

      // Проверяем, что элементы отсортированы по order
      for (var i = 0; i < items.length - 1; i++) {
        expect(items[i].order, lessThanOrEqualTo(items[i + 1].order));
      }
    });

    test('updateChecklistItem обновляет элемент', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final item = checklist.items.first;

      item.title = 'Обновлённое название';
      item.priority = ChecklistPriority.high;
      await repository.updateChecklistItem(item);

      final updated = await isar.checklistItems.get(item.id);
      expect(updated!.title, 'Обновлённое название');
      expect(updated.priority, ChecklistPriority.high);
    });

    test('toggleChecklistItem переключает статус выполнения', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final item = checklist.items.first;

      expect(item.isCompleted, false);
      expect(item.completedAt, isNull);

      // Отмечаем как выполненное
      await repository.toggleChecklistItem(item.id);

      final completed = await isar.checklistItems.get(item.id);
      expect(completed!.isCompleted, true);
      expect(completed.completedAt, isNotNull);

      // Снимаем отметку
      await repository.toggleChecklistItem(item.id);

      final uncompleted = await isar.checklistItems.get(item.id);
      expect(uncompleted!.isCompleted, false);
      expect(uncompleted.completedAt, isNull);
    });

    test('deleteChecklistItem удаляет элемент', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final item = checklist.items.first;
      final itemId = item.id;

      await repository.deleteChecklistItem(itemId);

      final deleted = await isar.checklistItems.get(itemId);
      expect(deleted, isNull);
    });

    test('reorderChecklistItems изменяет порядок элементов', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final items = checklist.items.toList();

      // Меняем порядок: [0,1,2,3] → [3,2,1,0]
      final reversedIds = items.reversed.map((e) => e.id).toList();

      await repository.reorderChecklistItems(checklist.id, reversedIds);

      // Проверяем новый порядок
      final reordered = await repository.getChecklistItems(checklist.id);
      expect(reordered.first.id, items.last.id);
      expect(reordered.last.id, items.first.id);
    });
  });

  group('ChecklistRepository - Статистика', () {
    test('getOverallStats возвращает статистику по всем чек-листам', () async {
      final checklist1 = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.bathroomRenovation,
      );

      // Отмечаем несколько задач как выполненные
      await repository.toggleChecklistItem(checklist1.items.first.id);
      await repository.toggleChecklistItem(checklist1.items.toList()[1].id);

      final stats = await repository.getOverallStats();

      expect(stats.totalChecklists, 2);
      expect(stats.totalItems, greaterThan(0));
      expect(stats.completedItems, 2);
    });

    test('getProjectStats возвращает статистику проекта', () async {
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
        projectId: 1,
      );
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.bathroomRenovation,
        projectId: 1,
      );
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.kitchenRenovation,
        projectId: 2,
      );

      final project1Stats = await repository.getProjectStats(1);
      final project2Stats = await repository.getProjectStats(2);

      expect(project1Stats.totalChecklists, 2);
      expect(project2Stats.totalChecklists, 1);
    });
  });

  group('ChecklistRepository - Реактивные запросы (watch)', () {
    test('watchAllChecklists отправляет обновления при изменении', () async {
      final stream = repository.watchAllChecklists();
      final updates = <List<RenovationChecklist>>[];

      final subscription = stream.listen(updates.add);

      // Ждём первый эмит
      await Future.delayed(const Duration(milliseconds: 100));

      // Создаём чек-лист
      await repository.createChecklistFromTemplate(ChecklistTemplates.roomRenovation);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(updates.length, greaterThanOrEqualTo(2));
      expect(updates.last.length, 1);

      await subscription.cancel();
    });

    test('watchChecklist отправляет обновления для конкретного чек-листа', () async {
      final checklist = await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      final stream = repository.watchChecklist(checklist.id);
      final updates = <RenovationChecklist?>[];

      final subscription = stream.listen(updates.add);

      // Ждём первый эмит
      await Future.delayed(const Duration(milliseconds: 100));

      // Обновляем чек-лист
      checklist.name = 'Новое название';
      await repository.updateChecklist(checklist);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(updates.isNotEmpty, true);
      expect(updates.last?.name, 'Новое название');

      await subscription.cancel();
    });

    test('watchProjectChecklists отправляет обновления для проекта', () async {
      const projectId = 1;

      final stream = repository.watchProjectChecklists(projectId);
      final updates = <List<RenovationChecklist>>[];

      final subscription = stream.listen(updates.add);

      // Ждём первый эмит
      await Future.delayed(const Duration(milliseconds: 100));

      // Создаём чек-лист для проекта
      await repository.createChecklistFromTemplate(
        ChecklistTemplates.roomRenovation,
        projectId: projectId,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      expect(updates.length, greaterThanOrEqualTo(2));
      expect(updates.last.length, 1);
      expect(updates.last.first.projectId, projectId);

      await subscription.cancel();
    });
  });

  group('ChecklistRepository - Граничные случаи', () {
    test('createChecklistItem выбрасывает исключение для несуществующего чек-листа', () async {
      expect(
        () => repository.createChecklistItem(
          checklistId: 99999,
          title: 'Тест',
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('getChecklistItems возвращает пустой список для пустого чек-листа', () async {
      final checklist = RenovationChecklist()
        ..name = 'Пустой'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      await repository.createChecklist(checklist);

      final items = await repository.getChecklistItems(checklist.id);

      expect(items, isEmpty);
    });

    test('toggleChecklistItem игнорирует несуществующий ID', () async {
      // Не должно выбросить исключение
      await repository.toggleChecklistItem(99999);
    });

    test('deleteChecklist игнорирует несуществующий ID', () async {
      // Не должно выбросить исключение
      await repository.deleteChecklist(99999);
    });
  });
}
