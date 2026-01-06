import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/history/widgets/history_stat_card.dart';

void main() {
  group('HistoryStatCard', () {
    testWidgets('renders with all required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryStatCard(
              icon: Icons.calculate,
              label: 'Total Calculations',
              value: '42',
              color: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.calculate), findsOneWidget);
      expect(find.text('Total Calculations'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('displays icon with correct color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryStatCard(
              icon: Icons.history,
              label: 'Label',
              value: '10',
              color: Colors.green,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.history));
      expect(icon.color, Colors.green);
    });

    testWidgets('animates on build', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryStatCard(
              icon: Icons.star,
              label: 'Stars',
              value: '5',
              color: Colors.amber,
            ),
          ),
        ),
      );

      // Initial state before animation completes
      expect(find.byType(HistoryStatCard), findsOneWidget);

      // Let animation complete
      await tester.pumpAndSettle();

      expect(find.text('Stars'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders with different colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                HistoryStatCard(
                  icon: Icons.home,
                  label: 'Home',
                  value: '1',
                  color: Colors.red,
                ),
                HistoryStatCard(
                  icon: Icons.work,
                  label: 'Work',
                  value: '2',
                  color: Colors.purple,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('handles long text values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryStatCard(
              icon: Icons.numbers,
              label: 'Very Long Label Text Here',
              value: '999,999',
              color: Colors.teal,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Very Long Label Text Here'), findsOneWidget);
      expect(find.text('999,999'), findsOneWidget);
    });

    testWidgets('renders value with custom formatting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryStatCard(
              icon: Icons.attach_money,
              label: 'Total Cost',
              value: '₽ 15,000',
              color: Colors.green,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('₽ 15,000'), findsOneWidget);
    });

    testWidgets('has correct widget structure', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HistoryStatCard(
              icon: Icons.check,
              label: 'Done',
              value: '100%',
              color: Colors.green,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should have Container with decoration
      expect(find.byType(Container), findsWidgets);
      // Should have Column for layout
      expect(find.byType(Column), findsWidgets);
    });
  });
}
