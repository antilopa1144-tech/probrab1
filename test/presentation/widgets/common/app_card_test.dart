import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/app_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders child widget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
    });

    testWidgets('wraps child in Card widget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('applies default padding', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Text('Padded'),
            ),
          ),
        ),
      );

      // Find the Padding widget that is an ancestor of the child text
      final paddingFinder = find.ancestor(
        of: find.text('Padded'),
        matching: find.byType(Padding),
      );
      final padding = tester.widget<Padding>(paddingFinder.first);
      expect(padding.padding, const EdgeInsets.all(16));
    });

    testWidgets('applies custom padding', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              padding: EdgeInsets.all(24),
              child: Text('Custom Padded'),
            ),
          ),
        ),
      );

      // Find the Padding widget that is an ancestor of the child text
      final paddingFinder = find.ancestor(
        of: find.text('Custom Padded'),
        matching: find.byType(Padding),
      );
      final padding = tester.widget<Padding>(paddingFinder.first);
      expect(padding.padding, const EdgeInsets.all(24));
    });

    testWidgets('applies margin', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              margin: EdgeInsets.all(8),
              child: Text('Margined'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.all(8));
    });

    testWidgets('applies custom color', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              color: Colors.red,
              child: Text('Colored'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, Colors.red);
    });

    testWidgets('applies custom elevation', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              elevation: 8,
              child: Text('Elevated'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 8);
    });

    testWidgets('renders complex child widget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Column(
                children: [
                  Text('Title'),
                  Text('Subtitle'),
                  Icon(Icons.star),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Title'), findsOneWidget);
      expect(find.text('Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders with all properties', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              padding: EdgeInsets.all(20),
              margin: EdgeInsets.all(10),
              color: Colors.blue,
              elevation: 4,
              child: Text('Full Props'),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, Colors.blue);
      expect(card.elevation, 4);
      expect(card.margin, const EdgeInsets.all(10));
    });
  });
}
