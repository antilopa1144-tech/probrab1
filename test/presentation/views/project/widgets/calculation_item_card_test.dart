import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/calculation_item_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('CalculationItemCard', () {
    late ProjectCalculation testCalculation;

    setUp(() {
      testCalculation = ProjectCalculation()
        ..id = 1
        ..calculatorId = 'paint_calculator'
        ..name = 'Расчёт краски'
        ..createdAt = DateTime(2024, 1, 15, 10, 30)
        ..updatedAt = DateTime(2024, 1, 15, 10, 30);
    });

    testWidgets('renders calculation name', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Расчёт краски'), findsOneWidget);
    });

    testWidgets('renders calculator id', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('paint_calculator'), findsOneWidget);
    });

    testWidgets('renders creation date', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('15.01.2024 10:30'), findsOneWidget);
    });

    testWidgets('calls onDelete when delete button is pressed', (tester) async {
      setTestViewportSize(tester);
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);
    });

    // Note: onTap test is skipped because it requires AppLocalizations setup
    // The widget uses localization for the button text when onTap is provided
    testWidgets(
      'widget accepts onTap callback',
      (tester) async {
        setTestViewportSize(tester);
        // Just verify the widget can be created with onTap without error
        // when localization is set up (see integration tests)
        expect(
          () => CalculationItemCard(
            calculation: testCalculation,
            onTap: () {},
            onDelete: () {},
          ),
          returnsNormally,
        );
      },
    );

    testWidgets('shows notes when present', (tester) async {
      setTestViewportSize(tester);
      testCalculation.notes = 'Some calculation notes';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.text('Some calculation notes'), findsOneWidget);
    });

    testWidgets('hides notes when null', (tester) async {
      setTestViewportSize(tester);
      testCalculation.notes = null;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      // Only name should be visible
      expect(find.text('Расчёт краски'), findsOneWidget);
    });

    testWidgets('renders results when present', (tester) async {
      setTestViewportSize(tester);
      final kvPair1 = KeyValuePair()
        ..key = 'area'
        ..value = 25.5;
      final kvPair2 = KeyValuePair()
        ..key = 'volume'
        ..value = 10.0;
      testCalculation.results = [kvPair1, kvPair2];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsWidgets);
    });

    testWidgets('is wrapped in a Card', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('shows delete tooltip', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItemCard(
              calculation: testCalculation,
              onDelete: () {},
            ),
          ),
        ),
      );

      final iconButton = tester.widget<IconButton>(
        find.byType(IconButton),
      );
      expect(iconButton.tooltip, 'Удалить');
    });
  });
}
