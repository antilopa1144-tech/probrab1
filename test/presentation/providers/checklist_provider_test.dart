import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:probrab_ai/data/repositories/checklist_repository.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';
import 'package:probrab_ai/presentation/providers/checklist_provider.dart';
import 'package:probrab_ai/core/database/database_provider.dart';

void main() {
  late Isar isar;

  setUp(() async {
    isar = await Isar.open(
      [RenovationChecklistSchema, ChecklistItemSchema],
      directory: '',
      name: 'test_provider_${DateTime.now().millisecondsSinceEpoch}',
    );
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('checklistRepositoryProvider', () {
    test('создаёт ChecklistRepository при наличии Isar', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      // Ждём загрузки Isar
      await container.read(isarProvider.future);

      final repository = container.read(checklistRepositoryProvider);

      expect(repository, isA<ChecklistRepository>());
    });

    test('выбрасывает StateError если Isar не инициализирован', () {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async {
            // Никогда не завершается - эмулирует loading
            await Future.delayed(const Duration(days: 1));
            return isar;
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(
        () => container.read(checklistRepositoryProvider),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('checklistTemplatesProvider', () {
    test('возвращает список всех шаблонов', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final templates = container.read(checklistTemplatesProvider);

      expect(templates, isNotEmpty);
      expect(templates, equals(ChecklistTemplates.all));
    });
  });

  group('ChecklistNotifier', () {
    test('начальное состояние - data(null)', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      // Ждём инициализации Isar
      await container.read(isarProvider.future);

      final state = container.read(checklistNotifierProvider);

      expect(state, isA<AsyncData<void>>());
    });

    test('createChecklist устанавливает loading и возвращает data', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = RenovationChecklist()
        ..name = 'Test Checklist'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      final result = await notifier.createChecklist(checklist);

      expect(result.id, isNot(Isar.autoIncrement));
      expect(result.name, 'Test Checklist');

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('createFromTemplate создаёт чек-лист из шаблона', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);
      final template = ChecklistTemplates.roomRenovation;

      final result = await notifier.createFromTemplate(template);

      expect(result.id, isNot(Isar.autoIncrement));
      expect(result.name, template.name);
      expect(result.isFromTemplate, true);
    });

    test('createFromTemplate с projectId привязывает к проекту', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);
      final template = ChecklistTemplates.bathroomRenovation;

      final result = await notifier.createFromTemplate(
        template,
        projectId: 42,
      );

      expect(result.projectId, 42);
    });

    test('updateChecklist обновляет чек-лист', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);
      final repository = container.read(checklistRepositoryProvider);

      // Создаём чек-лист
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      // Обновляем
      checklist.name = 'Новое название';
      await notifier.updateChecklist(checklist);

      // Проверяем
      final updated = await repository.getChecklistById(checklist.id);
      expect(updated?.name, 'Новое название');
    });

    test('deleteChecklist удаляет чек-лист', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);
      final repository = container.read(checklistRepositoryProvider);

      // Создаём чек-лист
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final id = checklist.id;

      // Удаляем
      await notifier.deleteChecklist(id);

      // Проверяем
      final deleted = await repository.getChecklistById(id);
      expect(deleted, isNull);
    });

    test('addItem добавляет элемент в чек-лист', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);
      final repository = container.read(checklistRepositoryProvider);

      // Создаём чек-лист
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final initialCount = checklist.items.length;

      // Добавляем элемент
      final item = await notifier.addItem(
        checklistId: checklist.id,
        title: 'Новая задача',
        description: 'Описание задачи',
        priority: ChecklistPriority.high,
      );

      expect(item.id, isNot(Isar.autoIncrement));
      expect(item.title, 'Новая задача');
      expect(item.priority, ChecklistPriority.high);

      // Проверяем что элемент добавился
      final items = await repository.getChecklistItems(checklist.id);
      expect(items.length, initialCount + 1);
    });

    test('toggleItem переключает статус элемента', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);

      // Создаём чек-лист с элементами
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final itemId = checklist.items.first.id;

      // Переключаем
      await notifier.toggleItem(itemId);

      // Проверяем
      final item = await isar.checklistItems.get(itemId);
      expect(item?.isCompleted, true);

      // Переключаем обратно
      await notifier.toggleItem(itemId);

      final unchecked = await isar.checklistItems.get(itemId);
      expect(unchecked?.isCompleted, false);
    });

    test('deleteItem удаляет элемент', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);

      // Создаём чек-лист с элементами
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final itemId = checklist.items.first.id;

      // Удаляем
      await notifier.deleteItem(itemId);

      // Проверяем
      final item = await isar.checklistItems.get(itemId);
      expect(item, isNull);
    });

    test('reorderItems изменяет порядок элементов', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);
      final repository = container.read(checklistRepositoryProvider);

      // Создаём чек-лист с элементами
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final items = checklist.items.toList();

      // Меняем порядок
      final reversedIds = items.reversed.map((e) => e.id).toList();
      await notifier.reorderItems(checklist.id, reversedIds);

      // Проверяем новый порядок
      final reordered = await repository.getChecklistItems(checklist.id);
      expect(reordered.first.id, items.last.id);
    });

    test('createChecklist устанавливает error при исключении', () async {
      // Создаём отдельную базу для теста с ошибкой
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);

      // Закрываем isar чтобы вызвать ошибку
      await errorIsar.close();

      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = RenovationChecklist()
        ..name = 'Test'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await expectLater(
        () => notifier.createChecklist(checklist),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });
  });

  group('allChecklistsProvider', () {
    test('возвращает stream чек-листов после инициализации', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      // Ждём загрузки Isar
      await container.read(isarProvider.future);

      // Ожидаем пока stream выдаст данные
      AsyncValue<List<RenovationChecklist>> asyncValue;
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        asyncValue = container.read(allChecklistsProvider);
        if (asyncValue is AsyncData<List<RenovationChecklist>>) break;
      }

      asyncValue = container.read(allChecklistsProvider);
      expect(asyncValue, isA<AsyncData<List<RenovationChecklist>>>());
    });

    test('возвращает пустой список изначально', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      // Ожидаем пока stream выдаст данные
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final asyncValue = container.read(allChecklistsProvider);
        if (asyncValue.hasValue) break;
      }

      final asyncValue = container.read(allChecklistsProvider);
      expect(asyncValue.value ?? <RenovationChecklist>[], isEmpty);
    });
  });

  group('checklistProvider', () {
    test('возвращает null для несуществующего чек-листа', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      // Ожидаем пока stream выдаст данные
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final asyncValue = container.read(checklistProvider(999));
        if (asyncValue.hasValue) break;
      }

      final asyncValue = container.read(checklistProvider(999));
      // После загрузки должен быть null для несуществующего id
      expect(asyncValue.hasValue, isTrue);
      expect(asyncValue.value, isNull);
    });

    test('возвращает чек-лист по id', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      // Создаём чек-лист
      final notifier = container.read(checklistNotifierProvider.notifier);
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      // Ожидаем пока stream выдаст данные
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final asyncValue = container.read(checklistProvider(checklist.id));
        if (asyncValue.hasValue && asyncValue.value != null) break;
      }

      final asyncValue = container.read(checklistProvider(checklist.id));
      expect(asyncValue.value?.id, checklist.id);
    });
  });

  group('projectChecklistsProvider', () {
    test('возвращает пустой список для проекта без чек-листов', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      // Ожидаем пока stream выдаст данные
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final asyncValue = container.read(projectChecklistsProvider(999));
        if (asyncValue.hasValue) break;
      }

      final asyncValue = container.read(projectChecklistsProvider(999));
      expect(asyncValue.value ?? <RenovationChecklist>[], isEmpty);
    });

    test('возвращает чек-листы проекта', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      // Создаём чек-лист для проекта
      final notifier = container.read(checklistNotifierProvider.notifier);
      await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
        projectId: 42,
      );

      // Ожидаем пока stream выдаст данные
      for (var i = 0; i < 20; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        final asyncValue = container.read(projectChecklistsProvider(42));
        if (asyncValue.hasValue && (asyncValue.value?.isNotEmpty ?? false)) break;
      }

      final asyncValue = container.read(projectChecklistsProvider(42));
      expect(asyncValue.value?.length, 1);
    });
  });

  group('checklistStatsProvider', () {
    test('возвращает статистику для пустого списка', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final stats = await container.read(checklistStatsProvider.future);

      expect(stats.totalChecklists, 0);
      expect(stats.totalItems, 0);
      expect(stats.completedItems, 0);
    });

    test('возвращает корректную статистику', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      // Создаём чек-лист с элементами
      final notifier = container.read(checklistNotifierProvider.notifier);
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      // Завершаем один элемент
      await notifier.toggleItem(checklist.items.first.id);

      final stats = await container.read(checklistStatsProvider.future);

      expect(stats.totalChecklists, 1);
      expect(stats.totalItems, checklist.items.length);
      expect(stats.completedItems, 1);
    });
  });

  group('projectChecklistStatsProvider', () {
    test('возвращает статистику для проекта без чек-листов', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final stats = await container.read(projectChecklistStatsProvider(999).future);

      expect(stats.totalChecklists, 0);
      expect(stats.totalItems, 0);
    });

    test('возвращает статистику для проекта с чек-листами', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      // Создаём чек-лист для проекта
      final notifier = container.read(checklistNotifierProvider.notifier);
      await notifier.createFromTemplate(
        ChecklistTemplates.bathroomRenovation,
        projectId: 100,
      );

      final stats = await container.read(projectChecklistStatsProvider(100).future);

      expect(stats.totalChecklists, 1);
    });
  });

  group('ChecklistNotifier - дополнительное покрытие', () {
    test('updateItem обновляет элемент чек-листа', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);

      // Создаём чек-лист с элементами
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final item = checklist.items.first;

      // Обновляем элемент
      item.title = 'Обновлённый заголовок';
      item.description = 'Обновлённое описание';
      item.priority = ChecklistPriority.high;
      await notifier.updateItem(item);

      // Проверяем обновление
      final updated = await isar.checklistItems.get(item.id);
      expect(updated?.title, 'Обновлённый заголовок');
      expect(updated?.description, 'Обновлённое описание');
      expect(updated?.priority, ChecklistPriority.high);
    });

    test('addItem с низким приоритетом', () async {
      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => isar),
        ],
      );
      addTearDown(container.dispose);

      await container.read(isarProvider.future);

      final notifier = container.read(checklistNotifierProvider.notifier);
      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      final item = await notifier.addItem(
        checklistId: checklist.id,
        title: 'Низкий приоритет',
        priority: ChecklistPriority.low,
      );

      expect(item.priority, ChecklistPriority.low);
    });

    test('updateChecklist устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_update_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      // Закрываем базу
      await errorIsar.close();

      checklist.name = 'Новое имя';
      await expectLater(
        () => notifier.updateChecklist(checklist),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('deleteChecklist устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_delete_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await errorIsar.close();

      await expectLater(
        () => notifier.deleteChecklist(checklist.id),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('addItem устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_additem_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );

      await errorIsar.close();

      await expectLater(
        () => notifier.addItem(
          checklistId: checklist.id,
          title: 'Test',
        ),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('updateItem устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_updateitem_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final item = checklist.items.first;

      await errorIsar.close();

      item.title = 'Новое';
      await expectLater(
        () => notifier.updateItem(item),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('toggleItem устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_toggle_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final itemId = checklist.items.first.id;

      await errorIsar.close();

      await expectLater(
        () => notifier.toggleItem(itemId),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('deleteItem устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_deleteitem_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final itemId = checklist.items.first.id;

      await errorIsar.close();

      await expectLater(
        () => notifier.deleteItem(itemId),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('reorderItems устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_reorder_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      final notifier = container.read(checklistNotifierProvider.notifier);

      final checklist = await notifier.createFromTemplate(
        ChecklistTemplates.roomRenovation,
      );
      final itemIds = checklist.items.map((e) => e.id).toList();

      await errorIsar.close();

      await expectLater(
        () => notifier.reorderItems(checklist.id, itemIds),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });

    test('createFromTemplate устанавливает error при исключении', () async {
      final errorIsar = await Isar.open(
        [RenovationChecklistSchema, ChecklistItemSchema],
        directory: '',
        name: 'test_error_template_${DateTime.now().millisecondsSinceEpoch}',
      );

      final container = ProviderContainer(
        overrides: [
          isarProvider.overrideWith((ref) async => errorIsar),
        ],
      );
      addTearDown(() async {
        container.dispose();
        if (errorIsar.isOpen) {
          await errorIsar.close(deleteFromDisk: true);
        }
      });

      await container.read(isarProvider.future);
      await errorIsar.close();

      final notifier = container.read(checklistNotifierProvider.notifier);

      await expectLater(
        () => notifier.createFromTemplate(ChecklistTemplates.roomRenovation),
        throwsA(anything),
      );

      final state = container.read(checklistNotifierProvider);
      expect(state, isA<AsyncError<void>>());
    });
  });
}
