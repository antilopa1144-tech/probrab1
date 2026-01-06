import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/existing/swipeable_card.dart';

void main() {
  group('SwipeableCard', () {
    testWidgets('renders child widget', (tester) async {
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

    testWidgets('wraps child in Card widget', (tester) async {
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

    testWidgets('uses GestureDetector for swipe', (tester) async {
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

    testWidgets('applies custom background color', (tester) async {
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

    testWidgets('uses AnimatedPositioned for animation', (tester) async {
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

    testWidgets('uses Stack for layered layout', (tester) async {
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

    testWidgets('renders without optional callbacks', (tester) async {
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

    testWidgets('accepts onDelete callback', (tester) async {
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

    testWidgets('accepts onShare callback', (tester) async {
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

    testWidgets('accepts onDuplicate callback', (tester) async {
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

    testWidgets('accepts all callbacks together', (tester) async {
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
  });
}
