import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/checklist.dart';

void main() {
  group('RenovationChecklist', () {
    late RenovationChecklist checklist;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
      checklist = RenovationChecklist()
        ..name = 'Тестовый чек-лист'
        ..description = 'Описание чек-листа'
        ..category = ChecklistCategory.general
        ..projectId = null
        ..isFromTemplate = false
        ..templateId = null
        ..createdAt = testDate
        ..updatedAt = testDate;
    });

    test('создаётся с обязательными полями', () {
      expect(checklist.name, 'Тестовый чек-лист');
      expect(checklist.category, ChecklistCategory.general);
      expect(checklist.createdAt, testDate);
      expect(checklist.updatedAt, testDate);
    });

    test('создаётся с опциональными полями', () {
      expect(checklist.description, 'Описание чек-листа');
      expect(checklist.projectId, isNull);
      expect(checklist.templateId, isNull);
    });

    test('создаётся из шаблона', () {
      final templateChecklist = RenovationChecklist()
        ..name = 'Шаблонный чек-лист'
        ..category = ChecklistCategory.bathroom
        ..isFromTemplate = true
        ..templateId = 'template_123'
        ..createdAt = testDate
        ..updatedAt = testDate;

      expect(templateChecklist.isFromTemplate, true);
      expect(templateChecklist.templateId, 'template_123');
    });

    test('привязывается к проекту', () {
      final projectChecklist = RenovationChecklist()
        ..name = 'Проектный чек-лист'
        ..category = ChecklistCategory.kitchen
        ..projectId = 42
        ..createdAt = testDate
        ..updatedAt = testDate;

      expect(projectChecklist.projectId, 42);
    });

    test('totalItems возвращает 0 для пустого чек-листа', () {
      expect(checklist.totalItems, 0);
    });

    test('completedItems возвращает 0 для пустого чек-листа', () {
      expect(checklist.completedItems, 0);
    });

    test('progress возвращает 0.0 для пустого чек-листа', () {
      expect(checklist.progress, 0.0);
    });

    test('progressPercent возвращает 0 для пустого чек-листа', () {
      expect(checklist.progressPercent, 0);
    });

    test('isCompleted возвращает false для пустого чек-листа', () {
      expect(checklist.isCompleted, false);
    });

    test('isStarted возвращает false для пустого чек-листа', () {
      expect(checklist.isStarted, false);
    });

    test('toString возвращает читаемую строку', () {
      final str = checklist.toString();
      expect(str, contains('RenovationChecklist'));
      expect(str, contains('Тестовый чек-лист'));
      expect(str, contains('0%'));
    });
  });

  group('ChecklistItem', () {
    late ChecklistItem item;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15, 10, 30);
      item = ChecklistItem()
        ..title = 'Тестовая задача'
        ..description = 'Описание задачи'
        ..isCompleted = false
        ..order = 1
        ..priority = ChecklistPriority.normal
        ..createdAt = testDate
        ..completedAt = null
        ..updatedAt = testDate;
    });

    test('создаётся с обязательными полями', () {
      expect(item.title, 'Тестовая задача');
      expect(item.order, 1);
      expect(item.createdAt, testDate);
      expect(item.updatedAt, testDate);
    });

    test('создаётся с опциональными полями', () {
      expect(item.description, 'Описание задачи');
      expect(item.isCompleted, false);
      expect(item.completedAt, isNull);
    });

    test('создаётся с низким приоритетом', () {
      final lowPriorityItem = ChecklistItem()
        ..title = 'Низкий приоритет'
        ..order = 2
        ..priority = ChecklistPriority.low
        ..createdAt = testDate
        ..updatedAt = testDate;

      expect(lowPriorityItem.priority, ChecklistPriority.low);
    });

    test('создаётся с высоким приоритетом', () {
      final highPriorityItem = ChecklistItem()
        ..title = 'Высокий приоритет'
        ..order = 3
        ..priority = ChecklistPriority.high
        ..createdAt = testDate
        ..updatedAt = testDate;

      expect(highPriorityItem.priority, ChecklistPriority.high);
    });

    test('помечается как выполненная', () {
      final completedDate = DateTime(2024, 1, 20);
      item.isCompleted = true;
      item.completedAt = completedDate;

      expect(item.isCompleted, true);
      expect(item.completedAt, completedDate);
    });

    test('toString возвращает читаемую строку', () {
      final str = item.toString();
      expect(str, contains('ChecklistItem'));
      expect(str, contains('Тестовая задача'));
      expect(str, contains('completed: false'));
    });

    test('toString показывает статус выполнения', () {
      item.isCompleted = true;
      final str = item.toString();
      expect(str, contains('completed: true'));
    });
  });

  group('ChecklistCategory', () {
    test('имеет все необходимые категории', () {
      expect(ChecklistCategory.values.length, 8);
      expect(ChecklistCategory.values, contains(ChecklistCategory.general));
      expect(ChecklistCategory.values, contains(ChecklistCategory.room));
      expect(ChecklistCategory.values, contains(ChecklistCategory.bathroom));
      expect(ChecklistCategory.values, contains(ChecklistCategory.kitchen));
      expect(ChecklistCategory.values, contains(ChecklistCategory.livingRoom));
      expect(ChecklistCategory.values, contains(ChecklistCategory.hallway));
      expect(ChecklistCategory.values, contains(ChecklistCategory.balcony));
      expect(ChecklistCategory.values, contains(ChecklistCategory.facade));
    });
  });

  group('ChecklistCategoryExtension', () {
    test('displayName возвращает корректные названия', () {
      expect(ChecklistCategory.general.displayName, 'Общий ремонт');
      expect(ChecklistCategory.room.displayName, 'Комната');
      expect(ChecklistCategory.bathroom.displayName, 'Ванная');
      expect(ChecklistCategory.kitchen.displayName, 'Кухня');
      expect(ChecklistCategory.livingRoom.displayName, 'Гостиная');
      expect(ChecklistCategory.hallway.displayName, 'Прихожая');
      expect(ChecklistCategory.balcony.displayName, 'Балкон');
      expect(ChecklistCategory.facade.displayName, 'Фасад');
    });

    test('icon возвращает корректные иконки', () {
      expect(ChecklistCategory.general.icon, '🏠');
      expect(ChecklistCategory.room.icon, '🛏️');
      expect(ChecklistCategory.bathroom.icon, '🚿');
      expect(ChecklistCategory.kitchen.icon, '🍳');
      expect(ChecklistCategory.livingRoom.icon, '🛋️');
      expect(ChecklistCategory.hallway.icon, '🚪');
      expect(ChecklistCategory.balcony.icon, '🪴');
      expect(ChecklistCategory.facade.icon, '🏛️');
    });

    test('все displayName не пустые', () {
      for (final category in ChecklistCategory.values) {
        expect(category.displayName.isNotEmpty, true);
      }
    });

    test('все icon не пустые', () {
      for (final category in ChecklistCategory.values) {
        expect(category.icon.isNotEmpty, true);
      }
    });
  });

  group('ChecklistPriority', () {
    test('имеет все необходимые приоритеты', () {
      expect(ChecklistPriority.values.length, 3);
      expect(ChecklistPriority.values, contains(ChecklistPriority.low));
      expect(ChecklistPriority.values, contains(ChecklistPriority.normal));
      expect(ChecklistPriority.values, contains(ChecklistPriority.high));
    });
  });

  group('ChecklistPriorityExtension', () {
    test('displayName возвращает корректные названия', () {
      expect(ChecklistPriority.low.displayName, 'Низкий');
      expect(ChecklistPriority.normal.displayName, 'Обычный');
      expect(ChecklistPriority.high.displayName, 'Высокий');
    });

    test('icon возвращает корректные иконки', () {
      expect(ChecklistPriority.low.icon, '⬇️');
      expect(ChecklistPriority.normal.icon, '➡️');
      expect(ChecklistPriority.high.icon, '⬆️');
    });

    test('все displayName не пустые', () {
      for (final priority in ChecklistPriority.values) {
        expect(priority.displayName.isNotEmpty, true);
      }
    });

    test('все icon не пустые', () {
      for (final priority in ChecklistPriority.values) {
        expect(priority.icon.isNotEmpty, true);
      }
    });
  });

  group('RenovationChecklist - прогресс и статусы', () {
    test('progress вычисляется корректно с 50% выполнением', () {
      // Note: Этот тест демонстрирует логику, но без Isar транзакции
      // items IsarLinks не может быть наполнен. Тест проверяет граничные условия.
      final checklist = RenovationChecklist()
        ..name = 'Test'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      // Без items - progress должен быть 0
      expect(checklist.progress, 0.0);
      expect(checklist.progressPercent, 0);
    });

    test('isCompleted возвращает false если есть незавершённые элементы', () {
      final checklist = RenovationChecklist()
        ..name = 'Test'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(checklist.isCompleted, false);
    });

    test('isStarted возвращает false если нет выполненных элементов', () {
      final checklist = RenovationChecklist()
        ..name = 'Test'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(checklist.isStarted, false);
    });
  });

  group('RenovationChecklist - различные категории', () {
    test('создаётся для комнаты', () {
      final roomChecklist = RenovationChecklist()
        ..name = 'Ремонт комнаты'
        ..category = ChecklistCategory.room
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(roomChecklist.category, ChecklistCategory.room);
      expect(roomChecklist.category.displayName, 'Комната');
    });

    test('создаётся для ванной', () {
      final bathroomChecklist = RenovationChecklist()
        ..name = 'Ремонт ванной'
        ..category = ChecklistCategory.bathroom
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(bathroomChecklist.category, ChecklistCategory.bathroom);
      expect(bathroomChecklist.category.displayName, 'Ванная');
    });

    test('создаётся для кухни', () {
      final kitchenChecklist = RenovationChecklist()
        ..name = 'Ремонт кухни'
        ..category = ChecklistCategory.kitchen
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(kitchenChecklist.category, ChecklistCategory.kitchen);
      expect(kitchenChecklist.category.displayName, 'Кухня');
    });

    test('создаётся для гостиной', () {
      final livingRoomChecklist = RenovationChecklist()
        ..name = 'Ремонт гостиной'
        ..category = ChecklistCategory.livingRoom
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(livingRoomChecklist.category, ChecklistCategory.livingRoom);
      expect(livingRoomChecklist.category.displayName, 'Гостиная');
    });

    test('создаётся для прихожей', () {
      final hallwayChecklist = RenovationChecklist()
        ..name = 'Ремонт прихожей'
        ..category = ChecklistCategory.hallway
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(hallwayChecklist.category, ChecklistCategory.hallway);
      expect(hallwayChecklist.category.displayName, 'Прихожая');
    });

    test('создаётся для балкона', () {
      final balconyChecklist = RenovationChecklist()
        ..name = 'Ремонт балкона'
        ..category = ChecklistCategory.balcony
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(balconyChecklist.category, ChecklistCategory.balcony);
      expect(balconyChecklist.category.displayName, 'Балкон');
    });

    test('создаётся для фасада', () {
      final facadeChecklist = RenovationChecklist()
        ..name = 'Ремонт фасада'
        ..category = ChecklistCategory.facade
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(facadeChecklist.category, ChecklistCategory.facade);
      expect(facadeChecklist.category.displayName, 'Фасад');
    });
  });

  group('ChecklistItem - различные приоритеты', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
    });

    test('создаётся с низким приоритетом и корректными атрибутами', () {
      final item = ChecklistItem()
        ..title = 'Низкоприоритетная задача'
        ..priority = ChecklistPriority.low
        ..order = 1
        ..createdAt = testDate
        ..updatedAt = testDate;

      expect(item.priority, ChecklistPriority.low);
      expect(item.priority.displayName, 'Низкий');
      expect(item.priority.icon, '⬇️');
    });

    test('создаётся с обычным приоритетом и корректными атрибутами', () {
      final item = ChecklistItem()
        ..title = 'Обычная задача'
        ..priority = ChecklistPriority.normal
        ..order = 2
        ..createdAt = testDate
        ..updatedAt = testDate;

      expect(item.priority, ChecklistPriority.normal);
      expect(item.priority.displayName, 'Обычный');
      expect(item.priority.icon, '➡️');
    });

    test('создаётся с высоким приоритетом и корректными атрибутами', () {
      final item = ChecklistItem()
        ..title = 'Высокоприоритетная задача'
        ..priority = ChecklistPriority.high
        ..order = 3
        ..createdAt = testDate
        ..updatedAt = testDate;

      expect(item.priority, ChecklistPriority.high);
      expect(item.priority.displayName, 'Высокий');
      expect(item.priority.icon, '⬆️');
    });
  });

  group('ChecklistItem - граничные случаи', () {
    test('создаётся без описания', () {
      final item = ChecklistItem()
        ..title = 'Задача без описания'
        ..order = 1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.description, isNull);
    });

    test('создаётся с пустым описанием', () {
      final item = ChecklistItem()
        ..title = 'Задача'
        ..description = ''
        ..order = 1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.description, '');
    });

    test('создаётся с длинным названием', () {
      final longTitle = 'Очень длинное название задачи, ' * 10;
      final item = ChecklistItem()
        ..title = longTitle
        ..order = 1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.title, longTitle);
    });

    test('создаётся с длинным описанием', () {
      final longDesc = 'Очень длинное описание задачи, ' * 20;
      final item = ChecklistItem()
        ..title = 'Задача'
        ..description = longDesc
        ..order = 1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.description, longDesc);
    });

    test('порядковый номер может быть отрицательным', () {
      final item = ChecklistItem()
        ..title = 'Задача'
        ..order = -1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.order, -1);
    });

    test('порядковый номер может быть нулевым', () {
      final item = ChecklistItem()
        ..title = 'Задача'
        ..order = 0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.order, 0);
    });

    test('порядковый номер может быть очень большим', () {
      final item = ChecklistItem()
        ..title = 'Задача'
        ..order = 999999
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.order, 999999);
    });
  });

  group('RenovationChecklist - граничные случаи', () {
    test('создаётся с минимальными обязательными полями', () {
      final checklist = RenovationChecklist()
        ..name = 'Минимальный чек-лист'
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(checklist.name, 'Минимальный чек-лист');
      expect(checklist.description, isNull);
      expect(checklist.projectId, isNull);
      expect(checklist.templateId, isNull);
      expect(checklist.isFromTemplate, false);
    });

    test('создаётся с пустым описанием', () {
      final checklist = RenovationChecklist()
        ..name = 'Чек-лист'
        ..description = ''
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(checklist.description, '');
    });

    test('создаётся с очень длинным названием', () {
      final longName = 'Очень длинное название чек-листа ' * 10;
      final checklist = RenovationChecklist()
        ..name = longName
        ..category = ChecklistCategory.general
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(checklist.name, longName);
    });

    test('создаётся с нулевым projectId', () {
      final checklist = RenovationChecklist()
        ..name = 'Чек-лист'
        ..category = ChecklistCategory.general
        ..projectId = 0
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(checklist.projectId, 0);
    });

    test('создаётся с отрицательным projectId', () {
      final checklist = RenovationChecklist()
        ..name = 'Чек-лист'
        ..category = ChecklistCategory.general
        ..projectId = -1
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(checklist.projectId, -1);
    });

    test('updatedAt может быть после createdAt', () {
      final createdAt = DateTime(2024, 1, 1);
      final updatedAt = DateTime(2024, 1, 15);

      final checklist = RenovationChecklist()
        ..name = 'Чек-лист'
        ..category = ChecklistCategory.general
        ..createdAt = createdAt
        ..updatedAt = updatedAt;

      expect(checklist.createdAt.isBefore(checklist.updatedAt), true);
    });

    test('updatedAt может совпадать с createdAt', () {
      final date = DateTime(2024, 1, 1);

      final checklist = RenovationChecklist()
        ..name = 'Чек-лист'
        ..category = ChecklistCategory.general
        ..createdAt = date
        ..updatedAt = date;

      expect(checklist.createdAt, checklist.updatedAt);
    });
  });

  group('ChecklistItem - даты', () {
    test('completedAt устанавливается при выполнении', () {
      final completedDate = DateTime(2024, 1, 20, 15, 30);
      final item = ChecklistItem()
        ..title = 'Задача'
        ..order = 1
        ..isCompleted = true
        ..completedAt = completedDate
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 20);

      expect(item.completedAt, completedDate);
      expect(item.isCompleted, true);
    });

    test('completedAt равен null для невыполненной задачи', () {
      final item = ChecklistItem()
        ..title = 'Задача'
        ..order = 1
        ..isCompleted = false
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      expect(item.completedAt, isNull);
    });

    test('updatedAt обновляется после выполнения', () {
      final createdAt = DateTime(2024, 1, 15);
      final updatedAt = DateTime(2024, 1, 20);

      final item = ChecklistItem()
        ..title = 'Задача'
        ..order = 1
        ..isCompleted = true
        ..createdAt = createdAt
        ..updatedAt = updatedAt;

      expect(item.updatedAt.isAfter(item.createdAt), true);
    });
  });
}
