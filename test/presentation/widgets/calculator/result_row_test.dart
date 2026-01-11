import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/result_row.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ResultRowData', () {
    test('creates with required parameters', () {
      const data = ResultRowData(
        label: 'Area',
        value: '25.0',
      );

      expect(data.label, 'Area');
      expect(data.value, '25.0');
      expect(data.unit, isNull);
      expect(data.subtitle, isNull);
    });

    test('creates with all parameters', () {
      const data = ResultRowData(
        label: 'Area',
        value: '25.0',
        unit: 'm²',
        subtitle: 'Total floor area',
      );

      expect(data.label, 'Area');
      expect(data.value, '25.0');
      expect(data.unit, 'm²');
      expect(data.subtitle, 'Total floor area');
    });
  });

  group('ResultRow', () {
    testWidgets('renders label and value', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Tiles needed',
        value: '250',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultRow(data: data),
          ),
        ),
      );

      expect(find.text('Tiles needed'), findsOneWidget);
      expect(find.text('250'), findsOneWidget);
    });

    testWidgets('renders value with unit', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Area',
        value: '25.0',
        unit: 'm²',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultRow(data: data),
          ),
        ),
      );

      expect(find.text('Area'), findsOneWidget);
      expect(find.text('25.0 m²'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Volume',
        value: '12.5',
        unit: 'm³',
        subtitle: 'Including 10% reserve',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultRow(data: data),
          ),
        ),
      );

      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Including 10% reserve'), findsOneWidget);
      expect(find.text('12.5 m³'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Count',
        value: '100',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultRow(data: data),
          ),
        ),
      );

      // Should only find 2 Text widgets (label and value)
      expect(find.byType(Text), findsNWidgets(2));
    });

    testWidgets('uses Row as root widget', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Test',
        value: '123',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultRow(data: data),
          ),
        ),
      );

      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('applies theme styles', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Styled',
        value: '999',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: ResultRow(data: data),
          ),
        ),
      );

      // Just verify it renders without error with custom theme
      expect(find.text('Styled'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('handles long label text', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Very long label text that might overflow in narrow containers',
        value: '42',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: ResultRow(data: data),
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Very long label text that might overflow in narrow containers',
        ),
        findsOneWidget,
      );
    });

    testWidgets('handles numeric values', (tester) async {
      setTestViewportSize(tester);
      const data = ResultRowData(
        label: 'Price',
        value: '15,000.50',
        unit: '₽',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultRow(data: data),
          ),
        ),
      );

      expect(find.text('Price'), findsOneWidget);
      expect(find.text('15,000.50 ₽'), findsOneWidget);
    });
  });
}
