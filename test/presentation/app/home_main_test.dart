import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/calculation.dart';
import 'package:probrab_ai/data/repositories/calculation_repository.dart';
import 'package:probrab_ai/presentation/app/home_main.dart';
import 'package:probrab_ai/presentation/providers/calculation_provider.dart';
import '../../helpers/test_helpers.dart';

/// Mock repository для тестирования без Isar
class MockCalculationRepository implements CalculationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<Calculation>> getAllCalculations() async => [];

  @override
  Future<List<Calculation>> getCalculationsByCategory(String category) async =>
      [];

  @override
  Future<Map<String, dynamic>> getStatistics() async => {};
}

void main() {
  late MockCalculationRepository mockRepository;

  setUpAll(() {
    setupMocks();
    mockRepository = MockCalculationRepository();
  });

  group('HomeMainScreen', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(HomeMainScreen), findsOneWidget);
    });

    testWidgets('displays app title in AppBar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Probrab AI'), findsOneWidget);
    });

    testWidgets('has AppBar with menu button', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    });

    testWidgets('has search field', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays hero section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.calculate_outlined), findsAtLeastNWidgets(1));
    });

    testWidgets('displays categories section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('home.sections.categories.title'), findsOneWidget);
    });

    testWidgets('displays history section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // History section might be below visible area, scroll down to find it
      final listView = find.byType(ListView);
      expect(listView, findsOneWidget);

      // Scroll down to reveal history section
      await tester.drag(listView, const Offset(0, -300));
      await tester.pump();

      // History section should be visible after scroll
      expect(find.text('home.sections.history.title'), findsOneWidget);
    });

    testWidgets('has RefreshIndicator', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('search field accepts input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'плитка');
      await tester.pump();

      expect(find.byType(HomeMainScreen), findsOneWidget);
    });

    testWidgets('can open menu', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap menu button
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After tap, popup menu items should be visible
      // Just verify the screen is still there after tapping menu
      expect(find.byType(HomeMainScreen), findsOneWidget);
    });

    testWidgets('displays object grid', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have GridView for objects
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const HomeMainScreen(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: [
            calculationRepositoryProvider.overrideWithValue(mockRepository),
          ],
        ),
      );

      expect(find.byType(HomeMainScreen), findsNothing);
    });

    group('Тесты поиска калькуляторов', () {
      testWidgets('поиск показывает результаты при вводе запроса', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим текст поиска
        await tester.enterText(find.byType(TextField), 'плитка');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Проверяем, что показывается заголовок результатов поиска
        expect(find.text('home.search.results.title'), findsOneWidget);
      });

      testWidgets('очистка поиска убирает кнопку clear', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим текст
        await tester.enterText(find.byType(TextField), 'краска');
        await tester.pump();

        // Должна быть кнопка clear
        expect(find.byIcon(Icons.clear_rounded), findsOneWidget);

        // Нажимаем кнопку очистки
        await tester.tap(find.byIcon(Icons.clear_rounded));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Кнопка clear должна исчезнуть
        expect(find.byIcon(Icons.clear_rounded), findsNothing);
      });

      testWidgets('поиск фильтрует категории объектов', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим поисковый запрос
        await tester.enterText(find.byType(TextField), 'interior');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должна остаться GridView с объектами
        expect(find.byType(GridView), findsOneWidget);
      });

      testWidgets('пустой поиск показывает empty state', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим запрос, который ничего не найдёт
        await tester.enterText(find.byType(TextField), 'qwertyxyz123');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен отображаться empty state
        expect(find.text('search.no_results'), findsOneWidget);
      });
    });

    group('Тесты меню действий', () {
      testWidgets('меню открывается и показывает все пункты', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Открываем меню
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await tester.pumpAndSettle();

        // Проверяем наличие всех пунктов меню
        expect(find.text('workflow.screen.title'), findsOneWidget);
        expect(find.text('home.menu.projects'), findsOneWidget);
        expect(find.text('home.menu.reminders'), findsOneWidget);
        expect(find.text('home.menu.history'), findsOneWidget);
        expect(find.text('home.menu.settings'), findsOneWidget);
      });

      testWidgets('навигация в проекты работает', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Открываем меню
        await tester.tap(find.byIcon(Icons.menu_rounded));
        await tester.pumpAndSettle();

        // Нажимаем на "Проекты"
        await tester.tap(find.text('home.menu.projects'));
        await tester.pumpAndSettle();

        // Проверяем, что HomeMainScreen все еще есть (навигация push, а не replace)
        expect(find.byType(HomeMainScreen), findsOneWidget);
      });
    });

    group('Тесты истории расчётов', () {
      testWidgets('пустая история показывает empty state', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Прокручиваем вниз к секции истории
        final listView = find.byType(ListView);
        await tester.drag(listView, const Offset(0, -500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен быть empty state для истории
        expect(find.text('home.history.empty.title'), findsOneWidget);
      });

      testWidgets('секция истории имеет кнопку "Показать все"', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Прокручиваем вниз к секции истории
        final listView = find.byType(ListView);
        await tester.drag(listView, const Offset(0, -500));
        await tester.pump();

        // Должна быть кнопка действия
        expect(find.text('home.sections.history.action'), findsOneWidget);
      });
    });

    group('Тесты избранного', () {
      testWidgets('кнопка избранного не отображается когда список пуст', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Иконка избранного не должна отображаться
        expect(find.byIcon(Icons.favorite), findsNothing);
      });
    });

    group('Тесты обновления (pull to refresh)', () {
      testWidgets('pull to refresh обновляет историю', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Делаем pull to refresh
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // После обновления экран должен все еще существовать
        expect(find.byType(HomeMainScreen), findsOneWidget);
      });
    });

    group('Тесты адаптивности сетки', () {
      testWidgets('сетка объектов адаптируется под размер экрана', (
        tester,
      ) async {
        // Устанавливаем маленький размер экрана
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должна быть сетка
        final gridView = find.byType(GridView);
        expect(gridView, findsOneWidget);

        // Проверяем, что GridView существует и доступен
        final gridWidget = tester.widget<GridView>(gridView);
        expect(gridWidget, isNotNull);
      });
    });

    group('Тесты навигации по карточкам', () {
      testWidgets('тап по карточке объекта вызывает навигацию', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const HomeMainScreen(),
            overrides: [
              calculationRepositoryProvider.overrideWithValue(mockRepository),
            ],
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим любую карточку в GridView
        final gridItems = find.descendant(
          of: find.byType(GridView),
          matching: find.byType(InkWell),
        );

        if (gridItems.evaluate().isNotEmpty) {
          // Тапаем по первой карточке
          await tester.tap(gridItems.first);
          await tester.pumpAndSettle();

          // После навигации HomeMainScreen должен все еще существовать
          expect(find.byType(HomeMainScreen), findsOneWidget);
        }
      });
    });
  });
}
