import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';

void main() {
  group('ChecklistTemplates', () {
    test('all templates are available', () {
      final templates = ChecklistTemplates.all;

      // Должно быть 8 шаблонов (5 старых + 3 новых)
      expect(templates.length, equals(8));

      // Проверяем наличие всех шаблонов
      final ids = templates.map((t) => t.id).toList();
      expect(ids, contains('room_renovation'));
      expect(ids, contains('bathroom_renovation'));
      expect(ids, contains('kitchen_renovation'));
      expect(ids, contains('living_room_renovation'));
      expect(ids, contains('hallway_renovation'));
      expect(ids, contains('balcony_renovation'));
      expect(ids, contains('facade_renovation'));
      expect(ids, contains('general_renovation'));
    });

    test('hallway template has correct structure', () {
      final template = ChecklistTemplates.hallwayRenovation;

      expect(template.id, equals('hallway_renovation'));
      expect(template.name, equals('Ремонт прихожей'));
      expect(template.category, equals(ChecklistCategory.hallway));
      expect(template.items.length, equals(14));

      // Проверяем ключевые задачи
      final titles = template.items.map((i) => i.title).toList();
      expect(titles, contains('Замена входной двери'));
      expect(titles, contains('Установка вешалок и полок'));
      expect(titles, contains('Зеркало'));
    });

    test('balcony template has correct structure', () {
      final template = ChecklistTemplates.balconyRenovation;

      expect(template.id, equals('balcony_renovation'));
      expect(template.name, equals('Ремонт балкона/лоджии'));
      expect(template.category, equals(ChecklistCategory.balcony));
      expect(template.items.length, equals(15));

      // Проверяем ключевые задачи
      final titles = template.items.map((i) => i.title).toList();
      expect(titles, contains('Остекление балкона'));
      expect(titles, contains('Гидроизоляция'));
      expect(titles, contains('Утепление пола'));
      expect(titles, contains('Сушилка для белья'));
    });

    test('facade template has correct structure', () {
      final template = ChecklistTemplates.facadeRenovation;

      expect(template.id, equals('facade_renovation'));
      expect(template.name, equals('Ремонт фасада'));
      expect(template.category, equals(ChecklistCategory.facade));
      expect(template.items.length, equals(15));

      // Проверяем ключевые задачи
      final titles = template.items.map((i) => i.title).toList();
      expect(titles, contains('Обследование фасада'));
      expect(titles, contains('Установка лесов'));
      expect(titles, contains('Утепление фасада'));
      expect(titles, contains('Водосточная система'));
    });

    test('findById returns correct template', () {
      final hallway = ChecklistTemplates.findById('hallway_renovation');
      expect(hallway, isNotNull);
      expect(hallway!.name, equals('Ремонт прихожей'));

      final balcony = ChecklistTemplates.findById('balcony_renovation');
      expect(balcony, isNotNull);
      expect(balcony!.name, equals('Ремонт балкона/лоджии'));

      final facade = ChecklistTemplates.findById('facade_renovation');
      expect(facade, isNotNull);
      expect(facade!.name, equals('Ремонт фасада'));
    });

    test('findById returns null for non-existent template', () {
      final result = ChecklistTemplates.findById('non_existent');
      expect(result, isNull);
    });

    test('getByCategory returns correct templates', () {
      final hallwayTemplates =
          ChecklistTemplates.getByCategory(ChecklistCategory.hallway);
      expect(hallwayTemplates.length, equals(1));
      expect(hallwayTemplates.first.id, equals('hallway_renovation'));

      final balconyTemplates =
          ChecklistTemplates.getByCategory(ChecklistCategory.balcony);
      expect(balconyTemplates.length, equals(1));
      expect(balconyTemplates.first.id, equals('balcony_renovation'));

      final facadeTemplates =
          ChecklistTemplates.getByCategory(ChecklistCategory.facade);
      expect(facadeTemplates.length, equals(1));
      expect(facadeTemplates.first.id, equals('facade_renovation'));
    });

    test('templates have high priority items', () {
      // Прихожая: входная дверь, электрика
      final hallway = ChecklistTemplates.hallwayRenovation;
      final hallwayHighPriority =
          hallway.items.where((i) => i.priority == ChecklistPriority.high);
      expect(hallwayHighPriority.length, greaterThan(0));

      // Балкон: остекление, парапет, гидроизоляция
      final balcony = ChecklistTemplates.balconyRenovation;
      final balconyHighPriority =
          balcony.items.where((i) => i.priority == ChecklistPriority.high);
      expect(balconyHighPriority.length, equals(3));

      // Фасад: обследование, разрешения, леса, ремонт трещин, водостоки
      final facade = ChecklistTemplates.facadeRenovation;
      final facadeHighPriority =
          facade.items.where((i) => i.priority == ChecklistPriority.high);
      expect(facadeHighPriority.length, equals(5));
    });

    test('template creates checklist correctly', () {
      final template = ChecklistTemplates.hallwayRenovation;
      final checklist = template.toChecklist(projectId: 123);

      expect(checklist.name, equals(template.name));
      expect(checklist.description, equals(template.description));
      expect(checklist.category, equals(template.category));
      expect(checklist.projectId, equals(123));
      expect(checklist.isFromTemplate, isTrue);
      expect(checklist.templateId, equals(template.id));
    });

    test('template creates items correctly', () {
      final template = ChecklistTemplates.balconyRenovation;
      final items = template.createItems();

      expect(items.length, equals(template.items.length));

      // Проверяем первый элемент
      final firstItem = items.first;
      expect(firstItem.title, equals(template.items.first.title));
      expect(firstItem.description, equals(template.items.first.description));
      expect(firstItem.priority, equals(template.items.first.priority));
      expect(firstItem.isCompleted, isFalse);
      expect(firstItem.order, equals(0));

      // Проверяем порядок элементов
      for (int i = 0; i < items.length; i++) {
        expect(items[i].order, equals(i));
      }
    });

    test('all templates have descriptions', () {
      for (final template in ChecklistTemplates.all) {
        expect(template.description.isNotEmpty, isTrue,
            reason: '${template.name} должен иметь описание');
      }
    });

    test('all template items have titles', () {
      for (final template in ChecklistTemplates.all) {
        for (final item in template.items) {
          expect(item.title.isNotEmpty, isTrue,
              reason:
                  'Все элементы в ${template.name} должны иметь заголовки');
        }
      }
    });

    test('new templates have unique IDs', () {
      final ids = ChecklistTemplates.all.map((t) => t.id).toSet();
      expect(ids.length, equals(ChecklistTemplates.all.length),
          reason: 'Все шаблоны должны иметь уникальные ID');
    });

    test('categories have correct display names and icons', () {
      expect(ChecklistCategory.hallway.displayName, equals('Прихожая'));
      expect(ChecklistCategory.hallway.icon, equals('🚪'));

      expect(ChecklistCategory.balcony.displayName, equals('Балкон'));
      expect(ChecklistCategory.balcony.icon, equals('🪴'));

      expect(ChecklistCategory.facade.displayName, equals('Фасад'));
      expect(ChecklistCategory.facade.icon, equals('🏛️'));
    });
  });
}
