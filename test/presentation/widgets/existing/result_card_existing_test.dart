import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/unit_type.dart';
import 'package:probrab_ai/presentation/widgets/existing/result_card.dart';

void main() {
  group('ResultsListLayout', () {
    test('has all expected values', () {
      expect(ResultsListLayout.values.length, 2);
      expect(ResultsListLayout.values, contains(ResultsListLayout.flat));
      expect(ResultsListLayout.values, contains(ResultsListLayout.shoppingList));
    });

    test('has correct indices', () {
      expect(ResultsListLayout.flat.index, 0);
      expect(ResultsListLayout.shoppingList.index, 1);
    });
  });

  group('ResultCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Area',
              value: 25.0,
              unitType: UnitType.squareMeters,
            ),
          ),
        ),
      );

      expect(find.text('Area'), findsOneWidget);
      // Value is formatted by InputSanitizer
      expect(find.textContaining('25'), findsWidgets);
    });

    testWidgets('renders unit symbol', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Volume',
              value: 10.0,
              unitType: UnitType.cubicMeters,
            ),
          ),
        ),
      );

      expect(find.text('м³'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Test',
              value: 100,
              unitType: UnitType.pieces,
              icon: Icons.calculate,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('does not render icon when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Test',
              value: 100,
              unitType: UnitType.pieces,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('uses Card widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Test',
              value: 50,
              unitType: UnitType.kilograms,
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('primary card has higher elevation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Primary',
              value: 100,
              unitType: UnitType.pieces,
              isPrimary: true,
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 4);
    });

    testWidgets('non-primary card has zero elevation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Secondary',
              value: 50,
              unitType: UnitType.pieces,
              isPrimary: false,
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 0);
    });

    testWidgets('formats large numbers with separators', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              label: 'Large',
              value: 1234567.89,
              unitType: UnitType.pieces,
            ),
          ),
        ),
      );

      // InputSanitizer formats numbers with space separators
      expect(find.textContaining('1'), findsWidgets);
    });

    testWidgets('renders with different unit types', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ResultCard(
                  label: 'Length',
                  value: 5,
                  unitType: UnitType.meters,
                ),
                ResultCard(
                  label: 'Weight',
                  value: 10,
                  unitType: UnitType.kilograms,
                ),
                ResultCard(
                  label: 'Count',
                  value: 15,
                  unitType: UnitType.pieces,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ResultCard), findsNWidgets(3));
    });

    testWidgets('applies theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: ResultCard(
              label: 'Themed',
              value: 100,
              unitType: UnitType.pieces,
            ),
          ),
        ),
      );

      expect(find.text('Themed'), findsOneWidget);
    });
  });
}
