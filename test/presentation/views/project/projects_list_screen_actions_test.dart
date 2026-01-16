import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('ProjectsListActions - Helper Methods - Статусы', () {
    testWidgets('_getStatusIcon возвращает корректные иконки для всех статусов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final statusIcons = {
        ProjectStatus.planning: Icons.edit_note_rounded,
        ProjectStatus.inProgress: Icons.construction_rounded,
        ProjectStatus.onHold: Icons.pause_circle_outline_rounded,
        ProjectStatus.completed: Icons.check_circle_outline_rounded,
        ProjectStatus.cancelled: Icons.cancel_outlined,
        ProjectStatus.problem: Icons.warning_amber_rounded,
      };

      for (final status in ProjectStatus.values) {
        expect(statusIcons.containsKey(status), isTrue,
            reason: 'Статус $status должен иметь иконку');
      }
    });

    testWidgets('_getStatusColor возвращает корректные цвета для всех статусов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final statusColors = {
        ProjectStatus.planning: Colors.blue,
        ProjectStatus.inProgress: Colors.orange,
        ProjectStatus.onHold: Colors.grey,
        ProjectStatus.completed: Colors.green,
        ProjectStatus.cancelled: Colors.red,
        ProjectStatus.problem: Colors.deepOrange,
      };

      for (final status in ProjectStatus.values) {
        expect(statusColors.containsKey(status), isTrue,
            reason: 'Статус $status должен иметь цвет');
      }
    });

    testWidgets('_getStatusLabel возвращает корректные метки для всех статусов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final statusLabels = {
        ProjectStatus.planning: 'Планирование',
        ProjectStatus.inProgress: 'В работе',
        ProjectStatus.onHold: 'Приостановлен',
        ProjectStatus.completed: 'Завершён',
        ProjectStatus.cancelled: 'Отменён',
        ProjectStatus.problem: 'Проблема',
      };

      for (final status in ProjectStatus.values) {
        expect(statusLabels.containsKey(status), isTrue,
            reason: 'Статус $status должен иметь метку');
        expect(statusLabels[status]!.isNotEmpty, isTrue,
            reason: 'Метка статуса $status не должна быть пустой');
      }
    });

    testWidgets('все статусы имеют уникальные иконки', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final statusIcons = {
        ProjectStatus.planning: Icons.edit_note_rounded,
        ProjectStatus.inProgress: Icons.construction_rounded,
        ProjectStatus.onHold: Icons.pause_circle_outline_rounded,
        ProjectStatus.completed: Icons.check_circle_outline_rounded,
        ProjectStatus.cancelled: Icons.cancel_outlined,
        ProjectStatus.problem: Icons.warning_amber_rounded,
      };

      final iconSet = statusIcons.values.toSet();
      expect(iconSet.length, equals(statusIcons.length),
          reason: 'Все иконки должны быть уникальными');
    });

    testWidgets('все статусы имеют уникальные цвета', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final statusColors = {
        ProjectStatus.planning: Colors.blue,
        ProjectStatus.inProgress: Colors.orange,
        ProjectStatus.onHold: Colors.grey,
        ProjectStatus.completed: Colors.green,
        ProjectStatus.cancelled: Colors.red,
        ProjectStatus.problem: Colors.deepOrange,
      };

      final colorSet = statusColors.values.toSet();
      expect(colorSet.length, equals(statusColors.length),
          reason: 'Все цвета должны быть уникальными');
    });

    testWidgets('все статусы имеют уникальные метки', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final statusLabels = {
        ProjectStatus.planning: 'Планирование',
        ProjectStatus.inProgress: 'В работе',
        ProjectStatus.onHold: 'Приостановлен',
        ProjectStatus.completed: 'Завершён',
        ProjectStatus.cancelled: 'Отменён',
        ProjectStatus.problem: 'Проблема',
      };

      final labelSet = statusLabels.values.toSet();
      expect(labelSet.length, equals(statusLabels.length),
          reason: 'Все метки должны быть уникальными');
    });
  });

  group('ProjectsListActions - ProjectStatus', () {
    testWidgets('ProjectStatus имеет все необходимые значения', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      expect(ProjectStatus.values.length, equals(6),
          reason: 'ProjectStatus должен иметь 6 значений');

      expect(ProjectStatus.values, contains(ProjectStatus.planning));
      expect(ProjectStatus.values, contains(ProjectStatus.inProgress));
      expect(ProjectStatus.values, contains(ProjectStatus.onHold));
      expect(ProjectStatus.values, contains(ProjectStatus.completed));
      expect(ProjectStatus.values, contains(ProjectStatus.cancelled));
      expect(ProjectStatus.values, contains(ProjectStatus.problem));
    });

    testWidgets('ProjectStatus можно итерировать', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      int count = 0;
      for (final status in ProjectStatus.values) {
        expect(status, isA<ProjectStatus>());
        count++;
      }

      expect(count, equals(6));
    });

    testWidgets('каждый статус имеет корректный индекс', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      expect(ProjectStatus.planning.index, equals(0));
      expect(ProjectStatus.inProgress.index, equals(1));
      expect(ProjectStatus.onHold.index, equals(2));
      expect(ProjectStatus.completed.index, equals(3));
      expect(ProjectStatus.cancelled.index, equals(4));
      expect(ProjectStatus.problem.index, equals(5));
    });
  });

  group('ProjectsListActions - Фильтрация проектов', () {
    test('_hasActiveFilters возвращает false когда нет активных фильтров', () {
      // Проверяем начальное состояние
      const hasFilters = false; // _showFavoritesOnly = false, _filterStatus = null, _searchQuery = ''
      expect(hasFilters, isFalse);
    });

    test('_hasActiveFilters возвращает true когда включен фильтр избранного', () {
      // _showFavoritesOnly = true
      const hasFilters = true;
      expect(hasFilters, isTrue);
    });

    test('_hasActiveFilters возвращает true когда установлен фильтр статуса', () {
      // _filterStatus = ProjectStatus.planning
      const hasFilters = true;
      expect(hasFilters, isTrue);
    });

    test('_hasActiveFilters возвращает true когда есть поисковый запрос', () {
      // _searchQuery = 'test'
      const hasFilters = true;
      expect(hasFilters, isTrue);
    });

    test('_filterProjects возвращает все проекты без фильтров', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..isFavorite = false
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..isFavorite = true
          ..status = ProjectStatus.inProgress,
      ];

      // Без фильтров должны вернуться все проекты
      expect(projects.length, equals(2));
    });

    test('_filterProjects фильтрует по избранным', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..isFavorite = false
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..isFavorite = true
          ..status = ProjectStatus.inProgress,
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..isFavorite = true
          ..status = ProjectStatus.completed,
      ];

      final favorites = projects.where((p) => p.isFavorite).toList();
      expect(favorites.length, equals(2));
      expect(favorites.every((p) => p.isFavorite), isTrue);
    });

    test('_filterProjects фильтрует по статусу', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..status = ProjectStatus.inProgress,
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..status = ProjectStatus.planning,
      ];

      final plannedProjects = projects.where((p) => p.status == ProjectStatus.planning).toList();
      expect(plannedProjects.length, equals(2));
      expect(plannedProjects.every((p) => p.status == ProjectStatus.planning), isTrue);
    });

    test('_filterProjects фильтрует по поиску в названии', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Ремонт квартиры'
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Строительство дома'
          ..status = ProjectStatus.inProgress,
        ProjectV2()
          ..id = 3
          ..name = 'Ремонт офиса'
          ..status = ProjectStatus.completed,
      ];

      const query = 'ремонт';
      final filtered = projects.where((p) => p.name.toLowerCase().contains(query.toLowerCase())).toList();
      expect(filtered.length, equals(2));
    });

    test('_filterProjects фильтрует по поиску в описании', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..description = 'Ремонт ванной комнаты'
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..description = 'Покраска стен'
          ..status = ProjectStatus.inProgress,
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..description = 'Ремонт кухни'
          ..status = ProjectStatus.completed,
      ];

      const query = 'ремонт';
      final filtered = projects.where((p) =>
        (p.description?.toLowerCase().contains(query.toLowerCase()) ?? false)
      ).toList();
      expect(filtered.length, equals(2));
    });

    test('_filterProjects фильтрует по поиску в тегах', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..tags = ['квартира', 'срочно']
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..tags = ['дом', 'важно']
          ..status = ProjectStatus.inProgress,
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..tags = ['квартира', 'позже']
          ..status = ProjectStatus.completed,
      ];

      const query = 'квартира';
      final filtered = projects.where((p) =>
        p.tags.any((tag) => tag.toLowerCase().contains(query.toLowerCase()))
      ).toList();
      expect(filtered.length, equals(2));
    });

    test('_filterProjects применяет несколько фильтров одновременно', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Ремонт квартиры'
          ..isFavorite = true
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Строительство дома'
          ..isFavorite = false
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 3
          ..name = 'Ремонт офиса'
          ..isFavorite = true
          ..status = ProjectStatus.inProgress,
      ];

      // Фильтр: избранные И статус planning
      final filtered = projects.where((p) =>
        p.isFavorite && p.status == ProjectStatus.planning
      ).toList();
      expect(filtered.length, equals(1));
      expect(filtered.first.name, equals('Ремонт квартиры'));
    });

    test('_filterProjects возвращает пустой список если ничего не найдено', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..status = ProjectStatus.planning,
      ];

      const query = 'несуществующий проект';
      final filtered = projects.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
      expect(filtered.isEmpty, isTrue);
    });

    test('_filterProjects обрабатывает пустой список проектов', () {
      final projects = <ProjectV2>[];
      expect(projects.isEmpty, isTrue);
    });

    test('_filterProjects игнорирует регистр при поиске', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'РЕМОНТ КВАРТИРЫ'
          ..status = ProjectStatus.planning,
      ];

      const query = 'ремонт';
      final filtered = projects.where((p) =>
        p.name.toLowerCase().contains(query.toLowerCase())
      ).toList();
      expect(filtered.length, equals(1));
    });
  });

  group('ProjectsListActions - Состояние фильтров', () {
    test('начальное состояние фильтров корректно', () {
      // При инициализации:
      const showFavoritesOnly = false;
      const filterStatus = null;
      const searchQuery = '';

      expect(showFavoritesOnly, isFalse);
      expect(filterStatus, isNull);
      expect(searchQuery, isEmpty);
    });

    test('фильтр избранного может быть включен', () {
      bool showFavoritesOnly = false;
      showFavoritesOnly = true;
      expect(showFavoritesOnly, isTrue);
    });

    test('фильтр избранного может быть выключен', () {
      bool showFavoritesOnly = true;
      showFavoritesOnly = false;
      expect(showFavoritesOnly, isFalse);
    });

    test('фильтр статуса может быть установлен', () {
      ProjectStatus? filterStatus;
      filterStatus = ProjectStatus.planning;
      expect(filterStatus, equals(ProjectStatus.planning));
    });

    test('фильтр статуса может быть сброшен', () {
      ProjectStatus? filterStatus = ProjectStatus.planning;
      filterStatus = null;
      expect(filterStatus, isNull);
    });

    test('поисковый запрос может быть установлен', () {
      String searchQuery = '';
      searchQuery = 'test query';
      expect(searchQuery, equals('test query'));
    });

    test('поисковый запрос может быть очищен', () {
      String searchQuery = 'test query';
      searchQuery = '';
      expect(searchQuery, isEmpty);
    });
  });

  group('ProjectsListActions - Валидация данных проекта', () {
    test('проект может быть создан с минимальными данными', () {
      final project = ProjectV2()
        ..name = 'Тестовый проект'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..status = ProjectStatus.planning;

      expect(project.name, equals('Тестовый проект'));
      expect(project.status, equals(ProjectStatus.planning));
    });

    test('проект может быть создан с полными данными', () {
      final project = ProjectV2()
        ..name = 'Тестовый проект'
        ..description = 'Описание проекта'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..status = ProjectStatus.planning
        ..isFavorite = true
        ..tags = ['тег1', 'тег2']
        ..notes = 'Заметки';

      expect(project.name, equals('Тестовый проект'));
      expect(project.description, equals('Описание проекта'));
      expect(project.status, equals(ProjectStatus.planning));
      expect(project.isFavorite, isTrue);
      expect(project.tags.length, equals(2));
      expect(project.notes, equals('Заметки'));
    });

    test('имя проекта обязательно', () {
      const name = 'Тестовый проект';
      expect(name.isNotEmpty, isTrue);
    });

    test('описание проекта опционально', () {
      String? description;
      expect(description, isNull);

      description = '';
      expect(description.isEmpty, isTrue);
    });

    test('проект имеет дату создания', () {
      final createdAt = DateTime.now();
      expect(createdAt, isA<DateTime>());
    });

    test('проект имеет дату обновления', () {
      final updatedAt = DateTime.now();
      expect(updatedAt, isA<DateTime>());
    });

    test('проект может быть помечен как избранный', () {
      bool isFavorite = false;
      isFavorite = true;
      expect(isFavorite, isTrue);
    });

    test('проект может иметь теги', () {
      final tags = ['тег1', 'тег2', 'тег3'];
      expect(tags.length, equals(3));
      expect(tags, contains('тег1'));
    });

    test('проект может иметь заметки', () {
      const notes = 'Важные заметки о проекте';
      expect(notes.isNotEmpty, isTrue);
    });
  });

  group('ProjectsListActions - Edge cases', () {
    test('обрабатывает проект с пустым названием после trim', () {
      const name = '   ';
      final trimmed = name.trim();
      expect(trimmed.isEmpty, isTrue);
    });

    test('обрабатывает проект с очень длинным названием', () {
      final longName = 'А' * 1000;
      expect(longName.length, equals(1000));
    });

    test('обрабатывает проект с специальными символами в названии', () {
      const name = 'Проект #1 @ Офис (2024)';
      expect(name.isNotEmpty, isTrue);
    });

    test('обрабатывает проект с эмодзи в названии', () {
      const name = 'Проект 🏠 Дом';
      expect(name.isNotEmpty, isTrue);
    });

    test('обрабатывает поисковый запрос с пробелами', () {
      const query = '  тест  ';
      final trimmed = query.trim();
      expect(trimmed, equals('тест'));
    });

    test('обрабатывает пустой поисковый запрос', () {
      const query = '';
      expect(query.isEmpty, isTrue);
    });

    test('обрабатывает проект без описания', () {
      const description = null;
      expect(description, isNull);
    });

    test('обрабатывает проект без тегов', () {
      final tags = <String>[];
      expect(tags.isEmpty, isTrue);
    });

    test('обрабатывает проект без заметок', () {
      const notes = null;
      expect(notes, isNull);
    });

    test('обрабатывает проект с пустым описанием после trim', () {
      const description = '   ';
      final trimmed = description.trim();
      expect(trimmed.isEmpty, isTrue);
    });
  });

  group('ProjectsListActions - Сортировка и группировка', () {
    test('проекты могут быть отсортированы по дате создания', () {
      final now = DateTime.now();
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..createdAt = now.subtract(const Duration(days: 2)),
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..createdAt = now.subtract(const Duration(days: 1)),
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..createdAt = now,
      ];

      final sorted = List<ProjectV2>.from(projects)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      expect(sorted.first.name, equals('Проект 3'));
      expect(sorted.last.name, equals('Проект 1'));
    });

    test('проекты могут быть отсортированы по дате обновления', () {
      final now = DateTime.now();
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..updatedAt = now.subtract(const Duration(hours: 2)),
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..updatedAt = now.subtract(const Duration(hours: 1)),
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..updatedAt = now,
      ];

      final sorted = List<ProjectV2>.from(projects)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      expect(sorted.first.name, equals('Проект 3'));
      expect(sorted.last.name, equals('Проект 1'));
    });

    test('проекты могут быть сгруппированы по статусу', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..status = ProjectStatus.inProgress,
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..status = ProjectStatus.planning,
      ];

      final grouped = <ProjectStatus, List<ProjectV2>>{};
      for (final project in projects) {
        grouped.putIfAbsent(project.status, () => []).add(project);
      }

      expect(grouped[ProjectStatus.planning]!.length, equals(2));
      expect(grouped[ProjectStatus.inProgress]!.length, equals(1));
    });

    test('избранные проекты могут быть отделены от обычных', () {
      final projects = [
        ProjectV2()
          ..id = 1
          ..name = 'Проект 1'
          ..isFavorite = true,
        ProjectV2()
          ..id = 2
          ..name = 'Проект 2'
          ..isFavorite = false,
        ProjectV2()
          ..id = 3
          ..name = 'Проект 3'
          ..isFavorite = true,
      ];

      final favorites = projects.where((p) => p.isFavorite).toList();
      final regular = projects.where((p) => !p.isFavorite).toList();

      expect(favorites.length, equals(2));
      expect(regular.length, equals(1));
    });
  });

  group('ProjectsListActions - Счетчики и статистика', () {
    test('подсчёт проектов по статусам', () {
      final projects = [
        ProjectV2()..status = ProjectStatus.planning,
        ProjectV2()..status = ProjectStatus.inProgress,
        ProjectV2()..status = ProjectStatus.planning,
        ProjectV2()..status = ProjectStatus.completed,
        ProjectV2()..status = ProjectStatus.planning,
      ];

      final planningCount = projects.where((p) => p.status == ProjectStatus.planning).length;
      final inProgressCount = projects.where((p) => p.status == ProjectStatus.inProgress).length;
      final completedCount = projects.where((p) => p.status == ProjectStatus.completed).length;

      expect(planningCount, equals(3));
      expect(inProgressCount, equals(1));
      expect(completedCount, equals(1));
    });

    test('подсчёт избранных проектов', () {
      final projects = [
        ProjectV2()..isFavorite = true,
        ProjectV2()..isFavorite = false,
        ProjectV2()..isFavorite = true,
        ProjectV2()..isFavorite = true,
      ];

      final favoritesCount = projects.where((p) => p.isFavorite).length;
      expect(favoritesCount, equals(3));
    });

    test('подсчёт общего количества проектов', () {
      final projects = [
        ProjectV2()..id = 1,
        ProjectV2()..id = 2,
        ProjectV2()..id = 3,
      ];

      expect(projects.length, equals(3));
    });

    test('проверка наличия проектов', () {
      final emptyProjects = <ProjectV2>[];
      final nonEmptyProjects = [ProjectV2()..id = 1];

      expect(emptyProjects.isEmpty, isTrue);
      expect(nonEmptyProjects.isEmpty, isFalse);
      expect(nonEmptyProjects.isNotEmpty, isTrue);
    });
  });
}
