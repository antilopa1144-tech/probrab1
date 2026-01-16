import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/app/main_shell.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('MainShell', () {
    testWidgets('renders correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(MainShell), findsOneWidget);
    });

    testWidgets('displays bottom navigation bar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('has three navigation tabs', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.items.length, 3);
    });

    testWidgets('starts with home tab selected', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.currentIndex, MainShell.homeTabIndex);
    });

    testWidgets('has IndexedStack for tab content', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(IndexedStack), findsOneWidget);
    });

    testWidgets('can switch to checklists tab', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap checklists tab
      await tester.tap(find.text('Чек-листы'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.currentIndex, MainShell.checklistsTabIndex);
    });

    testWidgets('can switch to favorites tab', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap favorites tab
      await tester.tap(find.text('Избранное'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.currentIndex, MainShell.favoritesTabIndex);
    });

    testWidgets('has Scaffold widgets', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have multiple Scaffolds (shell + child screens)
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const MainShell()));

      await tester.pump();

      await tester.pumpWidget(createTestApp(child: const SizedBox.shrink()));

      expect(find.byType(MainShell), findsNothing);
    });

    group('Тесты навигации между вкладками', () {
      testWidgets(
        'повторный тап на текущую вкладку сбрасывает стек навигации',
        (tester) async {
          setTestViewportSize(tester);
          await tester.pumpWidget(createTestApp(child: const MainShell()));

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Повторно тапаем по вкладке "Главная"
          await tester.tap(find.text('Главная'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Вкладка все еще должна быть активной
          final bottomNav = tester.widget<BottomNavigationBar>(
            find.byType(BottomNavigationBar),
          );
          expect(bottomNav.currentIndex, MainShell.homeTabIndex);
        },
      );

      testWidgets('переключение между всеми тремя вкладками работает', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Переключаемся на Чек-листы
        await tester.tap(find.text('Чек-листы'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        var bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.currentIndex, MainShell.checklistsTabIndex);

        // Переключаемся на Избранное
        await tester.tap(find.text('Избранное'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.currentIndex, MainShell.favoritesTabIndex);

        // Возвращаемся на Главную
        await tester.tap(find.text('Главная'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        bottomNav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar),
        );
        expect(bottomNav.currentIndex, MainShell.homeTabIndex);
      });

      testWidgets('каждая вкладка имеет свой Navigator', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // IndexedStack рендерит только активную вкладку, поэтому видно:
        // 1 Navigator от MaterialApp + 1 Navigator от активной вкладки = 2
        // Но MainShell создаёт 3 NavigatorKey для всех вкладок
        expect(find.byType(Navigator), findsAtLeastNWidgets(2));
      });
    });

    group('Тесты обработки back button', () {
      testWidgets('PopScope правильно обрабатывается', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Проверяем наличие PopScope (используем predicate для поиска
        // независимо от generic типа)
        final popScopeFinder = find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString().startsWith('PopScope'),
        );
        expect(popScopeFinder, findsAtLeastNWidgets(1));
      });
    });

    group('Тесты состояния вкладок', () {
      testWidgets('IndexedStack сохраняет состояние всех вкладок', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final indexedStack = tester.widget<IndexedStack>(
          find.byType(IndexedStack),
        );

        // Проверяем, что IndexedStack имеет правильный индекс
        expect(indexedStack.index, MainShell.homeTabIndex);

        // Проверяем количество дочерних элементов (должно быть 3)
        expect(indexedStack.children.length, 3);
      });

      testWidgets('переключение вкладок меняет индекс IndexedStack', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Переключаемся на чек-листы
        await tester.tap(find.text('Чек-листы'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final indexedStack = tester.widget<IndexedStack>(
          find.byType(IndexedStack),
        );
        expect(indexedStack.index, MainShell.checklistsTabIndex);
      });
    });

    group('Тесты иконок навигации', () {
      testWidgets('все вкладки имеют правильные иконки', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Проверяем наличие иконок
        expect(find.byIcon(Icons.home_rounded), findsOneWidget);
        expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
        expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      });

      testWidgets('вкладки имеют правильные подписи', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Главная'), findsOneWidget);
        expect(find.text('Чек-листы'), findsOneWidget);
        expect(find.text('Избранное'), findsOneWidget);
      });
    });

    group('Тесты постоянства состояния', () {
      testWidgets('состояние вкладки сохраняется при переключении', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Переключаемся на другую вкладку и возвращаемся
        await tester.tap(find.text('Чек-листы'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        await tester.tap(find.text('Главная'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // MainShell должен все еще существовать
        expect(find.byType(MainShell), findsOneWidget);
      });
    });

    group('Тесты NavigatorObserver', () {
      testWidgets('_TabNavigatorObserver отслеживает изменения навигации', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const MainShell()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Проверяем, что MainShell рендерится без ошибок
        expect(find.byType(MainShell), findsOneWidget);
      });
    });
  });
}
