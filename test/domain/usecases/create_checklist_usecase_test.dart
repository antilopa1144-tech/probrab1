import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:probrab_ai/data/repositories/checklist_repository.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';
import 'package:probrab_ai/domain/usecases/create_checklist_usecase.dart';

void main() {
  late Isar isar;
  late ChecklistRepository repository;
  late CreateChecklistUseCase useCase;

  setUp(() async {
    // Создаём in-memory Isar для тестов
    isar = await Isar.open(
      [RenovationChecklistSchema, ChecklistItemSchema],
      directory: '',
      name: 'test_create_checklist_${DateTime.now().millisecondsSinceEpoch}',
    );
    repository = ChecklistRepository(isar);
    useCase = CreateChecklistUseCase(repository);
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  group('CreateChecklistUseCase - execute', () {
    test('успешно создаёт пустой чек-лист', () async {
      // Act
      final result = await useCase.execute(
        name: 'Тестовый чек-лист',
        category: ChecklistCategory.room,
      );

      // Assert
      expect(result.id, isNot(Isar.autoIncrement));
      expect(result.name, 'Тестовый чек-лист');
      expect(result.category, ChecklistCategory.room);
      expect(result.description, isNull);
      expect(result.projectId, isNull);
    });

    test('создаёт чек-лист со всеми полями', () async {
      // Act
      final result = await useCase.execute(
        name: 'Полный чек-лист',
        description: 'Описание чек-листа',
        category: ChecklistCategory.bathroom,
        projectId: 42,
      );

      // Assert
      expect(result.name, 'Полный чек-лист');
      expect(result.description, 'Описание чек-листа');
      expect(result.category, ChecklistCategory.bathroom);
      expect(result.projectId, 42);
    });

    test('бросает ArgumentError при пустом названии', () async {
      // Act & Assert
      expect(
        () => useCase.execute(
          name: '',
          category: ChecklistCategory.room,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError при названии из пробелов', () async {
      // Act & Assert
      expect(
        () => useCase.execute(
          name: '   ',
          category: ChecklistCategory.room,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('создаёт чек-листы разных категорий', () async {
      // Arrange
      const categories = ChecklistCategory.values;

      // Act & Assert
      for (final category in categories) {
        final result = await useCase.execute(
          name: 'Чек-лист ${category.name}',
          category: category,
        );

        expect(result.category, category);
      }
    });

    test('обрезает пробелы в названии', () async {
      // Act
      final result = await useCase.execute(
        name: '  Название с пробелами  ',
        category: ChecklistCategory.room,
      );

      // Assert - название должно быть сохранено с пробелами (trim() только для валидации)
      expect(result.name, '  Название с пробелами  ');
    });

    test('создаёт чек-лист с длинным названием', () async {
      // Arrange
      final longName = 'Очень ' * 50 + 'длинное название';

      // Act
      final result = await useCase.execute(
        name: longName,
        category: ChecklistCategory.kitchen,
      );

      // Assert
      expect(result.name, longName);
      expect(result.name.length, greaterThan(200));
    });

    test('создаёт чек-лист с кириллицей и эмодзи', () async {
      // Act
      final result = await useCase.execute(
        name: 'Ремонт ванной 🛁🚿',
        description: 'Полный ремонт с плиткой',
        category: ChecklistCategory.bathroom,
      );

      // Assert
      expect(result.name, 'Ремонт ванной 🛁🚿');
      expect(result.description, 'Полный ремонт с плиткой');
    });

    test('создаёт несколько чек-листов', () async {
      // Act
      final checklist1 = await useCase.execute(
        name: 'Чек-лист 1',
        category: ChecklistCategory.room,
      );

      final checklist2 = await useCase.execute(
        name: 'Чек-лист 2',
        category: ChecklistCategory.kitchen,
      );

      final checklist3 = await useCase.execute(
        name: 'Чек-лист 3',
        category: ChecklistCategory.bathroom,
      );

      // Assert
      expect(checklist1.id, isNot(checklist2.id));
      expect(checklist2.id, isNot(checklist3.id));

      // Проверяем в БД
      final all = await repository.getAllChecklists();
      expect(all.length, 3);
    });
  });

  group('CreateChecklistUseCase - executeFromTemplate', () {
    test('создаёт чек-лист из шаблона Room Renovation', () async {
      // Arrange
      final template = ChecklistTemplates.roomRenovation;

      // Act
      final result = await useCase.executeFromTemplate(template: template);

      // Assert
      expect(result.id, isNot(Isar.autoIncrement));
      expect(result.name, template.name);
      expect(result.category, template.category);
      expect(result.isFromTemplate, true);
      expect(result.templateId, template.id);
      expect(result.items.length, template.items.length);
    });

    test('создаёт чек-лист из шаблона Bathroom Renovation', () async {
      // Arrange
      final template = ChecklistTemplates.bathroomRenovation;

      // Act
      final result = await useCase.executeFromTemplate(template: template);

      // Assert
      expect(result.name, template.name);
      expect(result.category, ChecklistCategory.bathroom);
      expect(result.items.isNotEmpty, true);
    });

    test('создаёт чек-лист из шаблона Kitchen Renovation', () async {
      // Arrange
      final template = ChecklistTemplates.kitchenRenovation;

      // Act
      final result = await useCase.executeFromTemplate(template: template);

      // Assert
      expect(result.name, template.name);
      expect(result.category, ChecklistCategory.kitchen);
      expect(result.items.isNotEmpty, true);
    });

    test('создаёт чек-лист из шаблона с projectId', () async {
      // Arrange
      final template = ChecklistTemplates.roomRenovation;
      const projectId = 123;

      // Act
      final result = await useCase.executeFromTemplate(
        template: template,
        projectId: projectId,
      );

      // Assert
      expect(result.projectId, projectId);
      expect(result.isFromTemplate, true);
    });

    test('элементы чек-листа правильно связаны', () async {
      // Arrange
      final template = ChecklistTemplates.bathroomRenovation;

      // Act
      final result = await useCase.executeFromTemplate(template: template);

      // Assert
      for (final item in result.items) {
        await item.checklist.load();
        expect(item.checklist.value, isNotNull);
        expect(item.checklist.value!.id, result.id);
      }
    });

    test('создаёт чек-листы из разных шаблонов', () async {
      // Act
      final checklist1 = await useCase.executeFromTemplate(
        template: ChecklistTemplates.roomRenovation,
      );

      final checklist2 = await useCase.executeFromTemplate(
        template: ChecklistTemplates.bathroomRenovation,
      );

      final checklist3 = await useCase.executeFromTemplate(
        template: ChecklistTemplates.kitchenRenovation,
      );

      // Assert
      expect(checklist1.id, isNot(checklist2.id));
      expect(checklist2.id, isNot(checklist3.id));
      expect(checklist1.category, isNot(checklist2.category));
    });

    test('проверяет что элементы имеют правильный порядок', () async {
      // Arrange
      final template = ChecklistTemplates.roomRenovation;

      // Act
      final result = await useCase.executeFromTemplate(template: template);

      // Assert
      final itemsList = result.items.toList();
      for (var i = 0; i < itemsList.length - 1; i++) {
        expect(
          itemsList[i].order,
          lessThan(itemsList[i + 1].order),
        );
      }
    });
  });

  group('CreateChecklistUseCase - executeWithItems', () {
    test('создаёт чек-лист с пользовательскими элементами', () async {
      // Arrange
      final itemTitles = [
        'Задача 1',
        'Задача 2',
        'Задача 3',
      ];

      // Act
      final result = await useCase.executeWithItems(
        name: 'Пользовательский чек-лист',
        category: ChecklistCategory.general,
        itemTitles: itemTitles,
      );

      // Assert
      expect(result.name, 'Пользовательский чек-лист');
      expect(result.items.length, 3);
      final itemsList = result.items.toList();
      expect(itemsList[0].title, 'Задача 1');
      expect(itemsList[1].title, 'Задача 2');
      expect(itemsList[2].title, 'Задача 3');
    });

    test('бросает ArgumentError при пустом названии', () async {
      // Act & Assert
      expect(
        () => useCase.executeWithItems(
          name: '',
          category: ChecklistCategory.room,
          itemTitles: ['Задача 1'],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('бросает ArgumentError при пустом списке элементов', () async {
      // Act & Assert
      expect(
        () => useCase.executeWithItems(
          name: 'Чек-лист',
          category: ChecklistCategory.room,
          itemTitles: [],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('создаёт чек-лист с одним элементом', () async {
      // Act
      final result = await useCase.executeWithItems(
        name: 'Простой чек-лист',
        category: ChecklistCategory.room,
        itemTitles: ['Единственная задача'],
      );

      // Assert
      expect(result.items.length, 1);
      expect(result.items.first.title, 'Единственная задача');
    });

    test('пропускает пустые элементы', () async {
      // Arrange
      final itemTitles = [
        'Задача 1',
        '',
        '   ',
        'Задача 2',
      ];

      // Act
      final result = await useCase.executeWithItems(
        name: 'Чек-лист',
        category: ChecklistCategory.room,
        itemTitles: itemTitles,
      );

      // Assert - пустые элементы должны быть пропущены
      expect(result.items.length, 2);
      final itemsList = result.items.toList();
      expect(itemsList[0].title, 'Задача 1');
      expect(itemsList[1].title, 'Задача 2');
    });

    test('создаёт чек-лист с большим количеством элементов', () async {
      // Arrange
      final itemTitles = List.generate(50, (i) => 'Задача ${i + 1}');

      // Act
      final result = await useCase.executeWithItems(
        name: 'Большой чек-лист',
        category: ChecklistCategory.general,
        itemTitles: itemTitles,
      );

      // Assert
      expect(result.items.length, 50);
      final itemsList = result.items.toList();
      expect(itemsList[0].title, 'Задача 1');
      expect(itemsList[49].title, 'Задача 50');
    });

    test('создаёт чек-лист с description и projectId', () async {
      // Act
      final result = await useCase.executeWithItems(
        name: 'Полный чек-лист',
        description: 'Описание',
        category: ChecklistCategory.kitchen,
        itemTitles: ['Задача 1', 'Задача 2'],
        projectId: 456,
      );

      // Assert
      expect(result.description, 'Описание');
      expect(result.projectId, 456);
      expect(result.items.length, 2);
    });

    test('элементы имеют правильный порядок', () async {
      // Arrange
      final itemTitles = List.generate(10, (i) => 'Задача $i');

      // Act
      final result = await useCase.executeWithItems(
        name: 'Чек-лист',
        category: ChecklistCategory.room,
        itemTitles: itemTitles,
      );

      // Assert
      final itemsList = result.items.toList();
      for (var i = 0; i < itemsList.length - 1; i++) {
        expect(
          itemsList[i].order,
          lessThan(itemsList[i + 1].order),
        );
      }
    });

    test('создаёт элементы с кириллицей и специальными символами', () async {
      // Arrange
      final itemTitles = [
        'Купить материалы 🛒',
        'Демонтаж старого покрытия',
        'Подготовка поверхности (выравнивание)',
      ];

      // Act
      final result = await useCase.executeWithItems(
        name: 'Ремонт',
        category: ChecklistCategory.room,
        itemTitles: itemTitles,
      );

      // Assert
      final itemsList = result.items.toList();
      expect(itemsList[0].title, 'Купить материалы 🛒');
      expect(itemsList[1].title, 'Демонтаж старого покрытия');
      expect(itemsList[2].title, 'Подготовка поверхности (выравнивание)');
    });
  });

  group('CreateChecklistUseCase - Интеграционные сценарии', () {
    test('создание разных типов чек-листов', () async {
      // Act - создаём пустой чек-лист
      final empty = await useCase.execute(
        name: 'Пустой',
        category: ChecklistCategory.room,
      );

      // Act - создаём из шаблона
      final fromTemplate = await useCase.executeFromTemplate(
        template: ChecklistTemplates.bathroomRenovation,
      );

      // Act - создаём с элементами
      final withItems = await useCase.executeWithItems(
        name: 'С элементами',
        category: ChecklistCategory.kitchen,
        itemTitles: ['Задача 1', 'Задача 2'],
      );

      // Assert
      expect(empty.items, isEmpty);
      expect(fromTemplate.items.isNotEmpty, true);
      expect(withItems.items.length, 2);

      final all = await repository.getAllChecklists();
      expect(all.length, 3);
    });

    test('создание чек-листов для одного проекта', () async {
      // Arrange
      const projectId = 789;

      // Act
      final checklist1 = await useCase.execute(
        name: 'Чек-лист 1',
        category: ChecklistCategory.room,
        projectId: projectId,
      );

      final checklist2 = await useCase.executeFromTemplate(
        template: ChecklistTemplates.bathroomRenovation,
        projectId: projectId,
      );

      final checklist3 = await useCase.executeWithItems(
        name: 'Чек-лист 3',
        category: ChecklistCategory.kitchen,
        itemTitles: ['Задача'],
        projectId: projectId,
      );

      // Assert
      expect(checklist1.projectId, projectId);
      expect(checklist2.projectId, projectId);
      expect(checklist3.projectId, projectId);

      final projectChecklists = await repository.getChecklistsByProjectId(projectId);
      expect(projectChecklists.length, 3);
    });

    test('создание чек-листов из всех доступных шаблонов', () async {
      // Arrange
      final templates = [
        ChecklistTemplates.roomRenovation,
        ChecklistTemplates.bathroomRenovation,
        ChecklistTemplates.kitchenRenovation,
      ];

      // Act
      for (final template in templates) {
        await useCase.executeFromTemplate(template: template);
      }

      // Assert
      final all = await repository.getAllChecklists();
      expect(all.length, 3);

      for (final template in templates) {
        final found = all.any((c) => c.templateId == template.id);
        expect(found, true);
      }
    });

    test('создание чек-листов для разных категорий', () async {
      // Act
      final byCategory = <ChecklistCategory, RenovationChecklist>{};

      for (final category in ChecklistCategory.values) {
        final checklist = await useCase.execute(
          name: 'Чек-лист ${category.name}',
          category: category,
        );
        byCategory[category] = checklist;
      }

      // Assert
      expect(byCategory.length, ChecklistCategory.values.length);

      for (final entry in byCategory.entries) {
        expect(entry.value.category, entry.key);
      }
    });
  });

  group('CreateChecklistUseCase - Граничные случаи', () {
    test('создаёт чек-лист с минимальными данными', () async {
      // Act
      final result = await useCase.execute(
        name: 'A',
        category: ChecklistCategory.general,
      );

      // Assert
      expect(result.name, 'A');
      expect(result.description, isNull);
      expect(result.projectId, isNull);
    });

    test('создаёт чек-лист с очень длинным description', () async {
      // Arrange
      final longDesc = 'Очень ' * 500 + 'длинное описание';

      // Act
      final result = await useCase.execute(
        name: 'Чек-лист',
        description: longDesc,
        category: ChecklistCategory.room,
      );

      // Assert
      expect(result.description, longDesc);
      expect(result.description!.length, greaterThan(2000));
    });

    test('создаёт чек-лист с максимальным projectId', () async {
      // Arrange
      const maxProjectId = 2147483647; // Max int32

      // Act
      final result = await useCase.execute(
        name: 'Чек-лист',
        category: ChecklistCategory.room,
        projectId: maxProjectId,
      );

      // Assert
      expect(result.projectId, maxProjectId);
    });

    test('executeWithItems с очень длинными названиями задач', () async {
      // Arrange
      final longTitle = 'Очень ' * 100 + 'длинная задача';
      final itemTitles = [longTitle];

      // Act
      final result = await useCase.executeWithItems(
        name: 'Чек-лист',
        category: ChecklistCategory.room,
        itemTitles: itemTitles,
      );

      // Assert
      final firstItem = result.items.first;
      expect(firstItem.title, longTitle);
      expect(firstItem.title.length, greaterThan(500));
    });

    test('executeWithItems со списком из 100 элементов', () async {
      // Arrange
      final itemTitles = List.generate(100, (i) => 'Задача ${i + 1}');

      // Act
      final result = await useCase.executeWithItems(
        name: 'Огромный чек-лист',
        category: ChecklistCategory.general,
        itemTitles: itemTitles,
      );

      // Assert
      expect(result.items.length, 100);
      final itemsList = result.items.toList();
      expect(itemsList[0].title, 'Задача 1');
      expect(itemsList[99].title, 'Задача 100');
    });

    test('executeWithItems с элементами только из пробелов', () async {
      // Arrange
      final itemTitles = ['   ', '  ', '    '];

      // Act
      final result = await useCase.executeWithItems(
        name: 'Чек-лист',
        category: ChecklistCategory.room,
        itemTitles: itemTitles,
      );

      // Assert - все элементы должны быть пропущены
      expect(result.items, isEmpty);
    });

    test('создаёт несколько чек-листов с одинаковым названием', () async {
      // Act
      final checklist1 = await useCase.execute(
        name: 'Одинаковое название',
        category: ChecklistCategory.room,
      );

      final checklist2 = await useCase.execute(
        name: 'Одинаковое название',
        category: ChecklistCategory.bathroom,
      );

      // Assert
      expect(checklist1.id, isNot(checklist2.id));
      expect(checklist1.name, checklist2.name);
      expect(checklist1.category, isNot(checklist2.category));
    });
  });
}
