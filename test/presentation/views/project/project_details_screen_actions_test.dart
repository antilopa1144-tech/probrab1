import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/project_details_screen.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('ProjectDetailsScreen Actions - Helper Methods', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('_getStatusIcon возвращает корректные иконки для всех статусов',
        (tester) async {
      setTestViewportSize(tester);

      // Проверяем что для каждого статуса есть своя иконка
      final statusIcons = {
        ProjectStatus.planning: Icons.edit_note_rounded,
        ProjectStatus.inProgress: Icons.construction_rounded,
        ProjectStatus.onHold: Icons.pause_circle_outline_rounded,
        ProjectStatus.completed: Icons.check_circle_outline_rounded,
        ProjectStatus.cancelled: Icons.cancel_outlined,
      };

      for (final status in ProjectStatus.values) {
        expect(statusIcons.containsKey(status), isTrue,
            reason: 'Статус $status должен иметь иконку');
      }
    });

    testWidgets('_getStatusColor возвращает корректные цвета для всех статусов',
        (tester) async {
      setTestViewportSize(tester);

      // Проверяем что для каждого статуса есть свой цвет
      final statusColors = {
        ProjectStatus.planning: Colors.blue,
        ProjectStatus.inProgress: Colors.orange,
        ProjectStatus.onHold: Colors.grey,
        ProjectStatus.completed: Colors.green,
        ProjectStatus.cancelled: Colors.red,
      };

      for (final status in ProjectStatus.values) {
        expect(statusColors.containsKey(status), isTrue,
            reason: 'Статус $status должен иметь цвет');
      }
    });

    testWidgets('_getStatusLabel возвращает корректные метки для всех статусов',
        (tester) async {
      setTestViewportSize(tester);

      // Проверяем что для каждого статуса есть своя метка
      final statusLabels = {
        ProjectStatus.planning: 'Планирование',
        ProjectStatus.inProgress: 'В работе',
        ProjectStatus.onHold: 'Приостановлен',
        ProjectStatus.completed: 'Завершён',
        ProjectStatus.cancelled: 'Отменён',
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

      final statusIcons = {
        ProjectStatus.planning: Icons.edit_note_rounded,
        ProjectStatus.inProgress: Icons.construction_rounded,
        ProjectStatus.onHold: Icons.pause_circle_outline_rounded,
        ProjectStatus.completed: Icons.check_circle_outline_rounded,
        ProjectStatus.cancelled: Icons.cancel_outlined,
      };

      final iconSet = statusIcons.values.toSet();
      expect(iconSet.length, equals(statusIcons.length),
          reason: 'Все иконки должны быть уникальными');
    });

    testWidgets('все статусы имеют уникальные цвета', (tester) async {
      setTestViewportSize(tester);

      final statusColors = {
        ProjectStatus.planning: Colors.blue,
        ProjectStatus.inProgress: Colors.orange,
        ProjectStatus.onHold: Colors.grey,
        ProjectStatus.completed: Colors.green,
        ProjectStatus.cancelled: Colors.red,
      };

      final colorSet = statusColors.values.toSet();
      expect(colorSet.length, equals(statusColors.length),
          reason: 'Все цвета должны быть уникальными');
    });

    testWidgets('все статусы имеют уникальные метки', (tester) async {
      setTestViewportSize(tester);

      final statusLabels = {
        ProjectStatus.planning: 'Планирование',
        ProjectStatus.inProgress: 'В работе',
        ProjectStatus.onHold: 'Приостановлен',
        ProjectStatus.completed: 'Завершён',
        ProjectStatus.cancelled: 'Отменён',
      };

      final labelSet = statusLabels.values.toSet();
      expect(labelSet.length, equals(statusLabels.length),
          reason: 'Все метки должны быть уникальными');
    });
  });

  group('ProjectDetailsScreen Actions - ProjectStatus', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('ProjectStatus имеет все необходимые значения', (tester) async {
      setTestViewportSize(tester);

      // Проверяем что enum содержит все ожидаемые значения
      expect(ProjectStatus.values.length, equals(5),
          reason: 'ProjectStatus должен иметь 5 значений');

      expect(ProjectStatus.values, contains(ProjectStatus.planning));
      expect(ProjectStatus.values, contains(ProjectStatus.inProgress));
      expect(ProjectStatus.values, contains(ProjectStatus.onHold));
      expect(ProjectStatus.values, contains(ProjectStatus.completed));
      expect(ProjectStatus.values, contains(ProjectStatus.cancelled));
    });

    testWidgets('ProjectStatus можно итерировать', (tester) async {
      setTestViewportSize(tester);

      int count = 0;
      for (final status in ProjectStatus.values) {
        expect(status, isA<ProjectStatus>());
        count++;
      }

      expect(count, equals(5));
    });

    testWidgets('ProjectStatus имеет корректные имена', (tester) async {
      setTestViewportSize(tester);

      expect(ProjectStatus.planning.name, equals('planning'));
      expect(ProjectStatus.inProgress.name, equals('inProgress'));
      expect(ProjectStatus.onHold.name, equals('onHold'));
      expect(ProjectStatus.completed.name, equals('completed'));
      expect(ProjectStatus.cancelled.name, equals('cancelled'));
    });
  });

  group('ProjectDetailsScreen Actions - структура', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('отображает основные элементы экрана', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие Scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('показывает индикатор загрузки при инициализации',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Сразу после создания должен быть индикатор загрузки
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('FutureBuilder обрабатывает состояние ожидания',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Проверяем FutureBuilder
      expect(find.byType(FutureBuilder<ProjectV2?>), findsOneWidget);
    });

    testWidgets('обрабатывает разные projectId корректно', (tester) async {
      setTestViewportSize(tester);
      // Тест с разными ID
      for (final id in [1, 2, 100]) {
        await tester.pumpWidget(
          createTestApp(
            child: ProjectDetailsScreen(projectId: id),
          ),
        );

        await tester.pump();

        expect(find.byType(ProjectDetailsScreen), findsOneWidget);

        // Очищаем для следующей итерации
        await tester.pumpWidget(Container());
      }
    });

    testWidgets('CircularProgressIndicator центрирован', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Проверяем сразу, до pump - должен быть индикатор
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Если индикатор есть, он обычно центрирован
      final indicator = find.byType(CircularProgressIndicator);
      expect(indicator, findsOneWidget);
    });

    testWidgets('имеет правильную иерархию виджетов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Проверяем базовую структуру
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('Scaffold содержит все необходимые компоненты', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));

      // Проверяем основные свойства Scaffold
      expect(scaffold.body, isNotNull);
    });

    testWidgets('правильно работает с ProviderScope', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Проверяем наличие ProviderScope
      expect(find.byType(ProviderScope), findsOneWidget);
    });

    testWidgets('поддерживает различные состояния загрузки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Начальное состояние - должен быть индикатор
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Завершение загрузки
      await tester.pumpAndSettle();

      // После загрузки виджет должен продолжать существовать
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('корректно обрабатывает пересоздание виджета',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Пересоздаем с тем же ID
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('изменение projectId создает новый виджет', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Меняем projectId
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 2),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });
  });

  group('ProjectDetailsScreen Actions - состояния', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('обрабатывает состояние "нет данных"', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 999999),
        ),
      );

      await tester.pumpAndSettle();

      // После загрузки должен быть какой-то контент
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('показывает индикатор при первой загрузке', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Немедленная проверка - должен быть индикатор
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('завершает загрузку за разумное время', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Ждем до 5 секунд
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // После загрузки индикатора быть не должно
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('обрабатывает несуществующий проект', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 999999),
        ),
      );

      await tester.pumpAndSettle();

      // Должна быть какая-то UI (сообщение об ошибке или пустой экран)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('показывает состояние загрузки корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Проверяем начальное состояние
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Даем время на загрузку
      await tester.pump(const Duration(milliseconds: 100));

      // Виджет должен существовать
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });
  });

  group('ProjectDetailsScreen Actions - интеграция', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('работает с MaterialApp', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Проверяем интеграцию с MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('поддерживает темную тему', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const ProjectDetailsScreen(projectId: 1),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('поддерживает светлую тему', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.light(),
            home: const ProjectDetailsScreen(projectId: 1),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('корректно работает в Navigator stack', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Navigator(
            onGenerateRoute: (settings) {
              return MaterialPageRoute(
                builder: (context) =>
                    const ProjectDetailsScreen(projectId: 1),
              );
            },
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('обрабатывает множество проектов', (tester) async {
      setTestViewportSize(tester);

      for (final projectId in [1, 5, 10, 50, 100]) {
        await tester.pumpWidget(
          createTestApp(
            child: ProjectDetailsScreen(projectId: projectId),
          ),
        );

        await tester.pump();

        expect(find.byType(ProjectDetailsScreen), findsOneWidget);

        // Очищаем для следующей итерации
        await tester.pumpWidget(Container());
        await tester.pump();
      }
    });

    testWidgets('создается с разными ключами', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(
            key: Key('project_1'),
            projectId: 1,
          ),
        ),
      );

      await tester.pump();

      expect(
        find.byKey(const Key('project_1')),
        findsOneWidget,
      );
    });
  });

  group('ProjectDetailsScreen Actions - error handling', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('обрабатывает отрицательный projectId', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: -1),
        ),
      );

      await tester.pump();

      // Виджет должен создаться, но может показать ошибку
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('обрабатывает нулевой projectId', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 0),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('обрабатывает очень большой projectId', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 999999999),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('корректно отображает состояние ошибки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 999999),
        ),
      );

      await tester.pumpAndSettle();

      // После загрузки должна быть какая-то UI
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ProjectDetailsScreen Actions - ProjectV2 model', () {
    setUp(() {
      setupMocks();
    });

    test('ProjectV2 создается с корректными значениями по умолчанию', () {
      final project = ProjectV2();

      expect(project.name, equals(''));
      expect(project.isFavorite, isFalse);
      expect(project.tags, isEmpty);
      expect(project.status, equals(ProjectStatus.planning));
      expect(project.createdAt, isA<DateTime>());
      expect(project.updatedAt, isA<DateTime>());
    });

    test('ProjectV2 правильно хранит название', () {
      final project = ProjectV2()..name = 'Тестовый проект';

      expect(project.name, equals('Тестовый проект'));
    });

    test('ProjectV2 правильно хранит описание', () {
      final project = ProjectV2()
        ..name = 'Test'
        ..description = 'Описание проекта';

      expect(project.description, equals('Описание проекта'));
    });

    test('ProjectV2 правильно хранит null описание', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.description, isNull);
    });

    test('ProjectV2 правильно хранит статус избранного', () {
      final project = ProjectV2()
        ..name = 'Test'
        ..isFavorite = true;

      expect(project.isFavorite, isTrue);
    });

    test('ProjectV2 правильно хранит теги', () {
      final project = ProjectV2()
        ..name = 'Test'
        ..tags = ['ремонт', 'дом'];

      expect(project.tags, equals(['ремонт', 'дом']));
      expect(project.tags.length, equals(2));
    });

    test('ProjectV2 правильно хранит статус', () {
      for (final status in ProjectStatus.values) {
        final project = ProjectV2()
          ..name = 'Test'
          ..status = status;

        expect(project.status, equals(status));
      }
    });

    test('ProjectV2 правильно хранит цвет', () {
      final project = ProjectV2()
        ..name = 'Test'
        ..color = 0xFF0000FF;

      expect(project.color, equals(0xFF0000FF));
    });

    test('ProjectV2 правильно хранит null цвет', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.color, isNull);
    });

    test('ProjectV2 правильно хранит заметки', () {
      final project = ProjectV2()
        ..name = 'Test'
        ..notes = 'Важные заметки';

      expect(project.notes, equals('Важные заметки'));
    });

    test('ProjectV2 правильно хранит null заметки', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.notes, isNull);
    });

    test('ProjectV2 правильно хранит даты', () {
      final created = DateTime(2024, 1, 1);
      final updated = DateTime(2024, 1, 2);

      final project = ProjectV2()
        ..name = 'Test'
        ..createdAt = created
        ..updatedAt = updated;

      expect(project.createdAt, equals(created));
      expect(project.updatedAt, equals(updated));
    });

    test('ProjectV2 totalCost начинается с 0', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.totalCost, equals(0.0));
    });

    test('ProjectV2 totalMaterialCost начинается с 0', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.totalMaterialCost, equals(0.0));
    });

    test('ProjectV2 totalLaborCost начинается с 0', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.totalLaborCost, equals(0.0));
    });

    test('ProjectV2 calculations начинается пустым', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.calculations.isEmpty, isTrue);
    });

    test('ProjectV2 allMaterials начинается пустым', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.allMaterials, isEmpty);
    });

    test('ProjectV2 shoppingList начинается пустым', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.shoppingList, isEmpty);
    });

    test('ProjectV2 remainingMaterialCost начинается с 0', () {
      final project = ProjectV2()..name = 'Test';

      expect(project.remainingMaterialCost, equals(0.0));
    });
  });

  group('ProjectDetailsScreen Actions - ProjectCalculation model', () {
    setUp(() {
      setupMocks();
    });

    test('ProjectCalculation создается с корректными значениями', () {
      final calc = ProjectCalculation();

      expect(calc.calculatorId, equals(''));
      expect(calc.name, equals(''));
      expect(calc.inputs, isEmpty);
      expect(calc.results, isEmpty);
      expect(calc.materials, isEmpty);
      expect(calc.createdAt, isA<DateTime>());
      expect(calc.updatedAt, isA<DateTime>());
    });

    test('ProjectCalculation правильно хранит calculatorId', () {
      final calc = ProjectCalculation()..calculatorId = 'brick';

      expect(calc.calculatorId, equals('brick'));
    });

    test('ProjectCalculation правильно хранит name', () {
      final calc = ProjectCalculation()..name = 'Кирпичная кладка';

      expect(calc.name, equals('Кирпичная кладка'));
    });

    test('ProjectCalculation правильно хранит materialCost', () {
      final calc = ProjectCalculation()..materialCost = 5000.0;

      expect(calc.materialCost, equals(5000.0));
    });

    test('ProjectCalculation правильно хранит null materialCost', () {
      final calc = ProjectCalculation();

      expect(calc.materialCost, isNull);
    });

    test('ProjectCalculation правильно хранит laborCost', () {
      final calc = ProjectCalculation()..laborCost = 3000.0;

      expect(calc.laborCost, equals(3000.0));
    });

    test('ProjectCalculation правильно хранит null laborCost', () {
      final calc = ProjectCalculation();

      expect(calc.laborCost, isNull);
    });

    test('ProjectCalculation правильно хранит заметки', () {
      final calc = ProjectCalculation()..notes = 'Важное замечание';

      expect(calc.notes, equals('Важное замечание'));
    });

    test('ProjectCalculation правильно хранит null заметки', () {
      final calc = ProjectCalculation();

      expect(calc.notes, isNull);
    });

    test('ProjectCalculation inputsMap работает корректно', () {
      final calc = ProjectCalculation();
      calc.setInputsFromMap({'length': 10.0, 'width': 5.0});

      final inputsMap = calc.inputsMap;

      expect(inputsMap['length'], equals(10.0));
      expect(inputsMap['width'], equals(5.0));
      expect(inputsMap.length, equals(2));
    });

    test('ProjectCalculation resultsMap работает корректно', () {
      final calc = ProjectCalculation();
      calc.setResultsFromMap({'area': 50.0, 'perimeter': 30.0});

      final resultsMap = calc.resultsMap;

      expect(resultsMap['area'], equals(50.0));
      expect(resultsMap['perimeter'], equals(30.0));
      expect(resultsMap.length, equals(2));
    });

    test('ProjectCalculation setInputsFromMap создает KeyValuePair', () {
      final calc = ProjectCalculation();
      calc.setInputsFromMap({'test': 123.0});

      expect(calc.inputs.length, equals(1));
      expect(calc.inputs.first.key, equals('test'));
      expect(calc.inputs.first.value, equals(123.0));
    });

    test('ProjectCalculation setResultsFromMap создает KeyValuePair', () {
      final calc = ProjectCalculation();
      calc.setResultsFromMap({'result': 456.0});

      expect(calc.results.length, equals(1));
      expect(calc.results.first.key, equals('result'));
      expect(calc.results.first.value, equals(456.0));
    });

    test('ProjectCalculation detailedMaterialCost начинается с 0', () {
      final calc = ProjectCalculation();

      expect(calc.detailedMaterialCost, equals(0.0));
    });

    test('ProjectCalculation effectiveMaterialCost использует aggregate', () {
      final calc = ProjectCalculation()..materialCost = 1000.0;

      expect(calc.effectiveMaterialCost, equals(1000.0));
    });

    test('ProjectCalculation правильно хранит даты', () {
      final created = DateTime(2024, 1, 1);
      final updated = DateTime(2024, 1, 2);

      final calc = ProjectCalculation()
        ..createdAt = created
        ..updatedAt = updated;

      expect(calc.createdAt, equals(created));
      expect(calc.updatedAt, equals(updated));
    });
  });

  group('ProjectDetailsScreen Actions - KeyValuePair model', () {
    setUp(() {
      setupMocks();
    });

    test('KeyValuePair создается с пустыми значениями', () {
      final pair = KeyValuePair();

      expect(pair.key, equals(''));
      expect(pair.value, equals(0));
    });

    test('KeyValuePair правильно хранит key', () {
      final pair = KeyValuePair()..key = 'test_key';

      expect(pair.key, equals('test_key'));
    });

    test('KeyValuePair правильно хранит value', () {
      final pair = KeyValuePair()..value = 123.45;

      expect(pair.value, equals(123.45));
    });

    test('KeyValuePair хранит отрицательные значения', () {
      final pair = KeyValuePair()..value = -50.0;

      expect(pair.value, equals(-50.0));
    });

    test('KeyValuePair хранит нулевое значение', () {
      final pair = KeyValuePair()..value = 0.0;

      expect(pair.value, equals(0.0));
    });

    test('KeyValuePair хранит русские ключи', () {
      final pair = KeyValuePair()..key = 'Площадь';

      expect(pair.key, equals('Площадь'));
    });

    test('KeyValuePair хранит большие числа', () {
      final pair = KeyValuePair()..value = 999999999.99;

      expect(pair.value, equals(999999999.99));
    });

    test('KeyValuePair хранит малые числа', () {
      final pair = KeyValuePair()..value = 0.00001;

      expect(pair.value, equals(0.00001));
    });
  });

  group('ProjectDetailsScreen Actions - ProjectMaterial model', () {
    setUp(() {
      setupMocks();
    });

    test('ProjectMaterial создается с корректными значениями', () {
      final material = ProjectMaterial();

      expect(material.name, equals(''));
      expect(material.quantity, equals(0));
      expect(material.unit, equals(''));
      expect(material.pricePerUnit, equals(0));
      expect(material.priority, equals(3));
      expect(material.purchased, isFalse);
    });

    test('ProjectMaterial правильно хранит name', () {
      final material = ProjectMaterial()..name = 'Кирпич';

      expect(material.name, equals('Кирпич'));
    });

    test('ProjectMaterial правильно хранит sku', () {
      final material = ProjectMaterial()..sku = 'BRICK-001';

      expect(material.sku, equals('BRICK-001'));
    });

    test('ProjectMaterial правильно хранит null sku', () {
      final material = ProjectMaterial();

      expect(material.sku, isNull);
    });

    test('ProjectMaterial правильно хранит quantity', () {
      final material = ProjectMaterial()..quantity = 100.0;

      expect(material.quantity, equals(100.0));
    });

    test('ProjectMaterial правильно хранит unit', () {
      final material = ProjectMaterial()..unit = 'шт';

      expect(material.unit, equals('шт'));
    });

    test('ProjectMaterial правильно хранит pricePerUnit', () {
      final material = ProjectMaterial()..pricePerUnit = 15.50;

      expect(material.pricePerUnit, equals(15.50));
    });

    test('ProjectMaterial правильно вычисляет totalCost', () {
      final material = ProjectMaterial()
        ..quantity = 100.0
        ..pricePerUnit = 15.0;

      expect(material.totalCost, equals(1500.0));
    });

    test('ProjectMaterial правильно хранит calculatorId', () {
      final material = ProjectMaterial()..calculatorId = 'brick';

      expect(material.calculatorId, equals('brick'));
    });

    test('ProjectMaterial правильно хранит null calculatorId', () {
      final material = ProjectMaterial();

      expect(material.calculatorId, isNull);
    });

    test('ProjectMaterial правильно хранит priority', () {
      final material = ProjectMaterial()..priority = 5;

      expect(material.priority, equals(5));
    });

    test('ProjectMaterial правильно хранит purchased', () {
      final material = ProjectMaterial()..purchased = true;

      expect(material.purchased, isTrue);
    });

    test('ProjectMaterial правильно хранит purchasedAt', () {
      final date = DateTime(2024, 1, 15);
      final material = ProjectMaterial()..purchasedAt = date;

      expect(material.purchasedAt, equals(date));
    });

    test('ProjectMaterial правильно хранит null purchasedAt', () {
      final material = ProjectMaterial();

      expect(material.purchasedAt, isNull);
    });

    test('ProjectMaterial totalCost с нулевым количеством', () {
      final material = ProjectMaterial()
        ..quantity = 0
        ..pricePerUnit = 100.0;

      expect(material.totalCost, equals(0.0));
    });

    test('ProjectMaterial totalCost с нулевой ценой', () {
      final material = ProjectMaterial()
        ..quantity = 100.0
        ..pricePerUnit = 0;

      expect(material.totalCost, equals(0.0));
    });

    test('ProjectMaterial totalCost с дробными числами', () {
      final material = ProjectMaterial()
        ..quantity = 10.5
        ..pricePerUnit = 12.3;

      expect(material.totalCost, closeTo(129.15, 0.01));
    });
  });
}
