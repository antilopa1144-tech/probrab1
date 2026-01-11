import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/materials_list.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('MaterialItem', () {
    test('creates with required parameters', () {
      const item = MaterialItem(
        label: 'Cement',
        value: '10',
      );

      expect(item.label, 'Cement');
      expect(item.value, '10');
      expect(item.unit, isNull);
    });

    test('creates with all parameters', () {
      const item = MaterialItem(
        label: 'Sand',
        value: '2.5',
        unit: 'm³',
      );

      expect(item.label, 'Sand');
      expect(item.value, '2.5');
      expect(item.unit, 'm³');
    });
  });

  group('MaterialsList', () {
    testWidgets('renders empty when items is empty', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsList(items: []),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Column), findsNothing);
    });

    testWidgets('renders single item', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsList(
              items: [
                MaterialItem(label: 'Cement', value: '10', unit: 'bags'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Cement'), findsOneWidget);
      expect(find.text('10 bags'), findsOneWidget);
    });

    testWidgets('renders multiple items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsList(
              items: [
                MaterialItem(label: 'Cement', value: '10', unit: 'bags'),
                MaterialItem(label: 'Sand', value: '2.5', unit: 'm³'),
                MaterialItem(label: 'Gravel', value: '3.0', unit: 'm³'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Cement'), findsOneWidget);
      expect(find.text('Sand'), findsOneWidget);
      expect(find.text('Gravel'), findsOneWidget);
      expect(find.text('10 bags'), findsOneWidget);
      expect(find.text('2.5 m³'), findsOneWidget);
      expect(find.text('3.0 m³'), findsOneWidget);
    });

    testWidgets('renders value without unit when unit is null', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsList(
              items: [
                MaterialItem(label: 'Count', value: '100'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Count'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('uses Column as layout', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsList(
              items: [
                MaterialItem(label: 'Test', value: '1'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsOneWidget);
    });

    testWidgets('applies theme styles', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: MaterialsList(
              items: [
                MaterialItem(label: 'Dark Item', value: '50'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Dark Item'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
    });
  });
}
