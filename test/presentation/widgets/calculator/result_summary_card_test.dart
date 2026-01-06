import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/result_summary_card.dart';

void main() {
  group('ResultSummaryCard', () {
    testWidgets('renders label and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultSummaryCard(
              label: 'Total Area',
              value: '25.0',
            ),
          ),
        ),
      );

      expect(find.text('Total Area'), findsOneWidget);
      expect(find.text('25.0'), findsOneWidget);
    });

    testWidgets('renders value with unit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultSummaryCard(
              label: 'Volume',
              value: '12.5',
              unit: 'm³',
            ),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('12.5'), findsOneWidget);
      expect(find.text('m³'), findsOneWidget);
    });

    testWidgets('does not render unit when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultSummaryCard(
              label: 'Count',
              value: '100',
            ),
          ),
        ),
      );

      expect(find.text('Count'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      // Only 2 Text widgets
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultSummaryCard(
              label: 'With Icon',
              value: '50',
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
            body: ResultSummaryCard(
              label: 'No Icon',
              value: '75',
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders all elements together', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultSummaryCard(
              label: 'Full Card',
              value: '999',
              unit: 'items',
              icon: Icons.inventory,
            ),
          ),
        ),
      );

      expect(find.text('Full Card'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('items'), findsOneWidget);
      expect(find.byIcon(Icons.inventory), findsOneWidget);
    });

    testWidgets('uses Card as base widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultSummaryCard(
              label: 'Test',
              value: '0',
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('applies theme colors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          ),
          home: const Scaffold(
            body: ResultSummaryCard(
              label: 'Themed',
              value: '123',
            ),
          ),
        ),
      );

      expect(find.text('Themed'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('handles large values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultSummaryCard(
              label: 'Large Value',
              value: '1,234,567.89',
              unit: '₽',
            ),
          ),
        ),
      );

      expect(find.text('1,234,567.89'), findsOneWidget);
      expect(find.text('₽'), findsOneWidget);
    });
  });
}
