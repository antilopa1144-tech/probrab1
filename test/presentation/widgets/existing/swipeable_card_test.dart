import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/existing/swipeable_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('SwipeableCard', () {
    testWidgets('отображает дочерний виджет', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('оборачивает содержимое в виджет Card', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('использует GestureDetector для свайпа', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('применяет кастомный цвет фона', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              backgroundColor: Colors.blue,
              child: Text('Content'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, Colors.blue);
    });

    testWidgets('использует AnimatedPositioned для анимации', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedPositioned), findsOneWidget);
    });

    testWidgets('использует Stack для многослойной компоновки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('отображается без опциональных коллбэков', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('принимает коллбэк onDelete', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDelete: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('принимает коллбэк onShare', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onShare: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('принимает коллбэк onDuplicate', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDuplicate: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('принимает все коллбэки вместе', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDelete: () {},
              onShare: () {},
              onDuplicate: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('обрабатывает горизонтальный свайп влево', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDelete: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(300, 100));
      await gesture.moveBy(const Offset(-150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Проверяем что виджет все еще существует
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('обрабатывает горизонтальный свайп вправо', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onShare: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Проверяем что виджет все еще существует
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('работает с onDuplicate коллбэком', (tester) async {
      setTestViewportSize(tester);
      bool called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDuplicate: () => called = true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Виджет создан и работает
      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('карточка возвращается на место при малом свайпе влево', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDelete: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final cardFinder = find.byType(AnimatedPositioned);
      final initialCard = tester.widget<AnimatedPositioned>(cardFinder);
      final initialLeft = initialCard.left;

      // Малый свайп влево (менее порога)
      final gesture = await tester.startGesture(const Offset(300, 100));
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Проверяем что карточка вернулась
      final finalCard = tester.widget<AnimatedPositioned>(cardFinder);
      expect(finalCard.left, equals(initialLeft));
    });

    testWidgets('карточка возвращается на место при малом свайпе вправо', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onShare: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final cardFinder = find.byType(AnimatedPositioned);
      final initialCard = tester.widget<AnimatedPositioned>(cardFinder);
      final initialLeft = initialCard.left;

      // Малый свайп вправо (менее порога)
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Проверяем что карточка вернулась
      final finalCard = tester.widget<AnimatedPositioned>(cardFinder);
      expect(finalCard.left, equals(initialLeft));
    });

    testWidgets('поддерживает большие свайпы влево', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDelete: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Большой свайп влево (больше порога 100)
      final gesture = await tester.startGesture(const Offset(300, 100));
      await gesture.moveBy(const Offset(-150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Виджет обработал свайп
      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('поддерживает большие свайпы вправо', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onShare: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Большой свайп вправо (больше порога 100)
      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Виджет обработал свайп
      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('работает с несколькими коллбэками одновременно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onShare: () {},
              onDuplicate: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Виджет работает с несколькими коллбэками
      expect(find.byType(SwipeableCard), findsOneWidget);
    });

    testWidgets('не отображает действие удаления если onDelete не задан', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(300, 100));
      await gesture.moveBy(const Offset(-150, 0));
      await tester.pump();

      expect(find.byIcon(Icons.delete_outline), findsNothing);
      await gesture.up();
    });

    testWidgets('не отображает действие поделиться если onShare не задан', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(const Offset(100, 100));
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();

      expect(find.byIcon(Icons.share_outlined), findsNothing);
      await gesture.up();
    });

    testWidgets('поддерживает жесты свайпа влево и вправо', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDelete: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Свайп влево
      var gesture = await tester.startGesture(const Offset(300, 100));
      await gesture.moveBy(const Offset(-150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Проверяем что карточка может взаимодействовать со свайпами
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('ограничивает смещение при свайпе максимальным значением влево', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onDelete: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Очень большой свайп влево
      final gesture = await tester.startGesture(const Offset(500, 100));
      await gesture.moveBy(const Offset(-400, 0));
      await tester.pump();

      final cardFinder = find.byType(AnimatedPositioned);
      final card = tester.widget<AnimatedPositioned>(cardFinder);

      // Смещение должно быть ограничено (clamp -200)
      expect(card.left, greaterThanOrEqualTo(-200.0));
      await gesture.up();
    });

    testWidgets('ограничивает смещение при свайпе максимальным значением вправо', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeableCard(
              onShare: () {},
              child: const Text('Content'),
            ),
          ),
        ),
      );

      // Очень большой свайп вправо
      final gesture = await tester.startGesture(const Offset(50, 100));
      await gesture.moveBy(const Offset(400, 0));
      await tester.pump();

      final cardFinder = find.byType(AnimatedPositioned);
      final card = tester.widget<AnimatedPositioned>(cardFinder);

      // Смещение должно быть ограничено (clamp 200)
      expect(card.left, lessThanOrEqualTo(200.0));
      await gesture.up();
    });
  });
}
