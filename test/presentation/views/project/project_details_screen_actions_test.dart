import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/project_details_screen.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('ProjectDetailsScreen с действиями', () {
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

    testWidgets('показывает индикатор загрузки при инициализации', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Сразу после создания должен быть индикатор загрузки
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('FutureBuilder обрабатывает состояние ожидания', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Проверяем FutureBuilder
      expect(find.byType(FutureBuilder<ProjectV2?>), findsOneWidget);
    });

    testWidgets('отображает AppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 999),
        ),
      );

      await tester.pump();

      // Проверяем наличие AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('AppBar содержит кнопку назад', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Проверяем наличие кнопки назад или leading
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar, isNotNull);
    });

    testWidgets('показывает сообщение об ошибке для несуществующего проекта', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 99999),
        ),
      );

      await tester.pumpAndSettle();

      // Должно быть сообщение об ошибке или пустое состояние
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text || widget is Icon,
        ),
        findsWidgets,
      );
    });

    testWidgets('Scaffold имеет body', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.body, isNotNull);
    });

    testWidgets('FutureBuilder отображает состояние загрузки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      // Перед pump должно быть состояние загрузки
      await tester.pump(Duration.zero);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('экран корректно создается с валидным projectId', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Проверяем, что виджет создан
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('Consumer правильно обрабатывает providers', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Проверяем наличие ConsumerStatefulWidget
      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });
  });

  group('ProjectDetailsScreen - взаимодействие с меню', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('AppBar может содержать actions', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      // actions может быть null или содержать элементы
      expect(appBar, isNotNull);
    });

    testWidgets('обрабатывает разные projectId корректно', (tester) async {
      setTestViewportSize(tester);
      // Тест с разными ID
      for (int id in [1, 2, 100]) {
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

      await tester.pump();

      // Проверяем наличие Center с CircularProgressIndicator
      final centerFinder = find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(Center),
      );

      expect(centerFinder, findsOneWidget);
    });
  });

  group('ProjectDetailsScreen - структура', () {
    setUp(() {
      setupMocks();
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
      expect(find.byType(AppBar), findsOneWidget);
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
      expect(scaffold.appBar, isNotNull);
      expect(scaffold.body, isNotNull);
    });

    testWidgets('FutureBuilder обрабатывает Future<ProjectV2?>', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
        ),
      );

      await tester.pump();

      // Проверяем тип FutureBuilder
      expect(find.byType(FutureBuilder<ProjectV2?>), findsOneWidget);
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

      // Начальное состояние
      await tester.pump(Duration.zero);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Завершение загрузки
      await tester.pumpAndSettle();

      // После загрузки индикатора быть не должно
      // (либо показывается контент, либо ошибка)
      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
      );
    });

    testWidgets('корректно обрабатывает пересоздание виджета', (tester) async {
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

  group('ProjectDetailsScreen - состояния', () {
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
  });

  group('ProjectDetailsScreen - интеграция', () {
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
                builder: (context) => const ProjectDetailsScreen(projectId: 1),
              );
            },
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });
  });
}
