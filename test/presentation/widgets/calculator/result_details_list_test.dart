import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/result_details_list.dart';
import 'package:probrab_ai/presentation/widgets/calculator/result_row.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ResultDetailsList', () {
    testWidgets('renders empty when items is empty', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(items: []),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(ResultRow), findsNothing);
    });

    testWidgets('renders single item', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(
              items: [
                ResultRowData(label: 'Area', value: '25.0', unit: 'm²'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ResultRow), findsOneWidget);
      expect(find.text('Area'), findsOneWidget);
      expect(find.text('25.0 m²'), findsOneWidget);
    });

    testWidgets('renders multiple items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(
              items: [
                ResultRowData(label: 'Area', value: '25.0', unit: 'm²'),
                ResultRowData(label: 'Volume', value: '12.5', unit: 'm³'),
                ResultRowData(label: 'Weight', value: '500', unit: 'kg'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ResultRow), findsNWidgets(3));
      expect(find.text('Area'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(
              items: [
                ResultRowData(label: 'Test', value: '1'),
              ],
              padding: EdgeInsets.all(20),
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, const EdgeInsets.all(20));
    });

    testWidgets('uses default padding when not specified', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(
              items: [
                ResultRowData(label: 'Test', value: '1'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('uses Column as layout', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(
              items: [
                ResultRowData(label: 'Test', value: '1'),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('adds spacing between items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(
              items: [
                ResultRowData(label: 'First', value: '1'),
                ResultRowData(label: 'Second', value: '2'),
              ],
            ),
          ),
        ),
      );

      // Should have SizedBox spacers between items
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('renders items with subtitles', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultDetailsList(
              items: [
                ResultRowData(
                  label: 'Total',
                  value: '100',
                  subtitle: 'Including reserve',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Including reserve'), findsOneWidget);
    });
  });
}
