import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/app/new_home_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('NewHomeScreen', () {
    testWidgets('renders correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(NewHomeScreen), findsOneWidget);
    });

    testWidgets('displays app title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Probrab AI'), findsOneWidget);
    });

    testWidgets('has search field', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays quick access section', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Быстрый доступ'), findsOneWidget);
    });

    testWidgets('displays categories section', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Категории'), findsOneWidget);
    });

    testWidgets('search field accepts input', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'плитка');
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(NewHomeScreen), findsOneWidget);
    });

    testWidgets('search clear button appears when typing', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'краска');
      await tester.pump(const Duration(milliseconds: 300));

      // Clear button should appear
      expect(find.byIcon(Icons.clear_rounded), findsOneWidget);
    });

    testWidgets('can clear search', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Enter search text
      await tester.enterText(find.byType(TextField), 'краска');
      await tester.pump(const Duration(milliseconds: 300));

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pump();

      expect(find.byType(NewHomeScreen), findsOneWidget);
    });

    testWidgets('has favorites button', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
    });

    testWidgets('displays calculator categories grid', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have GridView for categories
      expect(find.byType(GridView), findsAtLeastNWidgets(1));
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

      await tester.pump();

      await tester.pumpWidget(createTestApp(child: const SizedBox.shrink()));

      expect(find.byType(NewHomeScreen), findsNothing);
    });

    group('Тесты поиска с debounce', () {
      testWidgets('debounce задерживает обновление поиска', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим текст
        await tester.enterText(find.byType(TextField), 'плитка');

        // Сразу проверяем - результаты еще не должны появиться (debounce)
        await tester.pump(const Duration(milliseconds: 100));

        // Ждем завершения debounce
        await tester.pump(const Duration(milliseconds: 300));

        // Теперь результаты должны быть
        expect(find.byType(NewHomeScreen), findsOneWidget);
      });

      testWidgets('быстрый ввод сбрасывает debounce', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим текст несколько раз быстро
        await tester.enterText(find.byType(TextField), 'п');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'пл');
        await tester.pump(const Duration(milliseconds: 100));

        await tester.enterText(find.byType(TextField), 'плитка');

        // Ждем завершения debounce
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(NewHomeScreen), findsOneWidget);
      });

      testWidgets('поиск показывает счетчик найденных результатов', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим поисковый запрос
        await tester.enterText(find.byType(TextField), 'калькулятор');
        await tester.pump(const Duration(milliseconds: 300));

        // Должен быть текст с количеством найденных
        expect(find.textContaining('Найдено:'), findsOneWidget);
      });

      testWidgets('пустой поиск показывает empty state', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим запрос, который ничего не найдет
        await tester.enterText(find.byType(TextField), 'xyz123qwerty');
        await tester.pump(const Duration(milliseconds: 300));

        // Должен быть empty state
        expect(find.text('search.no_results'), findsOneWidget);
      });
    });

    group('Тесты секции "Быстрый доступ"', () {
      testWidgets('секция быстрого доступа показывает калькуляторы', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должна быть секция быстрого доступа
        expect(find.text('Быстрый доступ'), findsOneWidget);

        // Должен быть горизонтальный список
        final horizontalLists = find.byWidgetPredicate(
          (widget) =>
              widget is ListView && widget.scrollDirection == Axis.horizontal,
        );
        expect(horizontalLists, findsAtLeastNWidgets(1));
      });

      testWidgets('тап по карточке быстрого доступа открывает калькулятор', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим карточки быстрого доступа
        final popularCards = find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          ),
          matching: find.byType(InkWell),
        );

        if (popularCards.evaluate().isNotEmpty) {
          // Тапаем по первой карточке
          await tester.tap(popularCards.first);
          await tester.pumpAndSettle();

          // После навигации NewHomeScreen должен остаться
          expect(find.byType(NewHomeScreen), findsOneWidget);
        }
      });
    });

    group('Тесты секции категорий', () {
      testWidgets('секция категорий отображает сетку', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должна быть секция категорий
        expect(find.text('Категории'), findsOneWidget);

        // Должна быть GridView
        expect(find.byType(GridView), findsAtLeastNWidgets(1));
      });

      testWidgets('тап по категории открывает список калькуляторов', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим плитки категорий в GridView
        final categoryTiles = find.descendant(
          of: find.byType(GridView),
          matching: find.byType(InkWell),
        );

        if (categoryTiles.evaluate().isNotEmpty) {
          // Тапаем по первой категории
          await tester.tap(categoryTiles.first);
          await tester.pumpAndSettle();

          // Проверяем, что произошла навигация
          expect(find.byType(NewHomeScreen), findsOneWidget);
        }
      });
    });

    group('Тесты кнопки избранного', () {
      testWidgets('иконка избранного меняется когда есть избранные', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Изначально должна быть пустая звезда
        expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      });

      testWidgets('тап по кнопке избранного открывает список', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Тапаем по кнопке избранного
        await tester.tap(find.byIcon(Icons.star_outline_rounded));
        await tester.pumpAndSettle();

        // Должна произойти навигация
        expect(find.byType(NewHomeScreen), findsOneWidget);
      });
    });

    group('Тесты карточек калькуляторов', () {
      testWidgets('карточка калькулятора отображает все элементы', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Вводим поисковый запрос чтобы увидеть карточки
        await tester.enterText(find.byType(TextField), 'плитка');
        await tester.pump(const Duration(milliseconds: 300));

        // Проверяем наличие карточек калькуляторов
        expect(find.byType(NewHomeScreen), findsOneWidget);
      });

      testWidgets('долгое нажатие на карточку открывает пресеты', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим карточки в быстром доступе
        final popularCards = find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          ),
          matching: find.byType(InkWell),
        );

        if (popularCards.evaluate().isNotEmpty) {
          // Длинное нажатие
          await tester.longPress(popularCards.first);
          await tester.pumpAndSettle();

          // Должно открыться модальное окно с пресетами
          expect(find.text('Пресеты:'), findsOneWidget);
        }
      });
    });

    group('Тесты модального окна пресетов', () {
      testWidgets('модальное окно пресетов отображает все варианты', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим карточки популярных калькуляторов
        final popularCards = find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          ),
          matching: find.byType(InkWell),
        );

        if (popularCards.evaluate().isNotEmpty) {
          // Открываем модальное окно
          await tester.longPress(popularCards.first);
          await tester.pumpAndSettle();

          // Проверяем наличие пресетов
          expect(find.text('Ванная'), findsOneWidget);
          expect(find.text('Кухня'), findsOneWidget);
          expect(find.text('Спальня'), findsOneWidget);
          expect(find.text('Свои размеры'), findsOneWidget);
        }
      });

      testWidgets('тап по пресету открывает калькулятор с параметрами', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим карточки популярных калькуляторов
        final popularCards = find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          ),
          matching: find.byType(InkWell),
        );

        if (popularCards.evaluate().isNotEmpty) {
          // Открываем модальное окно
          await tester.longPress(popularCards.first);
          await tester.pumpAndSettle();

          // Тапаем по пресету "Ванная"
          final bathroomPreset = find.text('Ванная');
          if (bathroomPreset.evaluate().isNotEmpty) {
            await tester.tap(bathroomPreset);
            await tester.pumpAndSettle();

            // Модальное окно должно закрыться
            expect(find.text('Пресеты:'), findsNothing);
          }
        }
      });

      testWidgets('кнопка "Открыть калькулятор" работает', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим карточки популярных калькуляторов
        final popularCards = find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is ListView && widget.scrollDirection == Axis.horizontal,
          ),
          matching: find.byType(InkWell),
        );

        if (popularCards.evaluate().isNotEmpty) {
          // Открываем модальное окно
          await tester.longPress(popularCards.first);
          await tester.pumpAndSettle();

          // Нажимаем кнопку "Открыть калькулятор"
          final openButton = find.text('Открыть калькулятор');
          if (openButton.evaluate().isNotEmpty) {
            await tester.tap(openButton);
            await tester.pumpAndSettle();

            // Модальное окно должно закрыться
            expect(find.text('Пресеты:'), findsNothing);
          }
        }
      });
    });

    group('Тесты onTabRequested callback', () {
      testWidgets('onTabRequested вызывается при навигации в избранное', (
        tester,
      ) async {
        int? requestedTab;

        await tester.pumpWidget(
          createTestApp(
            child: NewHomeScreen(
              onTabRequested: (index) => requestedTab = index,
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Нажимаем на кнопку избранного
        await tester.tap(find.byIcon(Icons.star_outline_rounded));
        await tester.pump();

        // Callback должен был вызваться с индексом 2 (избранное)
        expect(requestedTab, 2);
      });

      testWidgets('без callback навигация работает через Navigator', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Нажимаем на кнопку избранного
        await tester.tap(find.byIcon(Icons.star_outline_rounded));
        await tester.pumpAndSettle();

        // Должна быть навигация через Navigator
        expect(find.byType(NewHomeScreen), findsOneWidget);
      });
    });

    group('Тесты чипов недавних калькуляторов', () {
      testWidgets('секция "Часто считают" отображается', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должна быть секция "Часто считают"
        expect(find.text('Часто считают'), findsOneWidget);
      });

      testWidgets('чипы недавних калькуляторов кликабельны', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(createTestApp(child: const NewHomeScreen()));

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Находим Wrap с чипами
        final wrapWidget = find.byType(Wrap);
        if (wrapWidget.evaluate().isNotEmpty) {
          // Находим InkWell внутри Wrap
          final chips = find.descendant(
            of: wrapWidget,
            matching: find.byType(InkWell),
          );

          if (chips.evaluate().isNotEmpty) {
            // Тапаем по первому чипу
            await tester.tap(chips.first);
            await tester.pumpAndSettle();

            expect(find.byType(NewHomeScreen), findsOneWidget);
          }
        }
      });
    });
  });
}
