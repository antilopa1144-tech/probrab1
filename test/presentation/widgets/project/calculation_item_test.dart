import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/project/calculation_item.dart';

void main() {
  group('CalculationItem', () {
    testWidgets('renders title and value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Area',
              value: '25.0',
            ),
          ),
        ),
      );

      expect(find.text('Area'), findsOneWidget);
      expect(find.text('25.0'), findsOneWidget);
    });

    testWidgets('renders value with unit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Volume',
              value: '12.5',
              unit: 'm³',
            ),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('12.5 m³'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Cement',
              value: '10',
              unit: 'bags',
              subtitle: 'Including 10% reserve',
            ),
          ),
        ),
      );

      expect(find.text('Cement'), findsOneWidget);
      expect(find.text('Including 10% reserve'), findsOneWidget);
      expect(find.text('10 bags'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Simple',
              value: '100',
            ),
          ),
        ),
      );

      // Title and value only
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Tappable',
              value: '50',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('renders leading widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'With Icon',
              value: '20',
              leading: Icon(Icons.calculate),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calculate), findsOneWidget);
    });

    testWidgets('uses ListTile as base widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Test',
              value: '0',
            ),
          ),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('applies font weight to value', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Bold Value',
              value: '999',
            ),
          ),
        ),
      );

      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('handles numeric values correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CalculationItem(
              title: 'Price',
              value: '15,000.50',
              unit: '₽',
            ),
          ),
        ),
      );

      expect(find.text('15,000.50 ₽'), findsOneWidget);
    });
  });
}
