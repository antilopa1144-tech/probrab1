import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/history/widgets/history_filter_chip.dart';

void main() {
  group('HistoryFilterChip', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChip(
              label: 'All',
              selected: false,
              onSelected: () {},
            ),
          ),
        ),
      );

      expect(find.text('All'), findsOneWidget);
    });

    testWidgets('shows selected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChip(
              label: 'Selected',
              selected: true,
              onSelected: () {},
            ),
          ),
        ),
      );

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('shows unselected state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChip(
              label: 'Unselected',
              selected: false,
              onSelected: () {},
            ),
          ),
        ),
      );

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isFalse);
    });

    testWidgets('calls onSelected when tapped', (tester) async {
      bool callbackCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChip(
              label: 'Tap Me',
              selected: false,
              onSelected: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilterChip));
      expect(callbackCalled, isTrue);
    });

    testWidgets('renders multiple chips in a row', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                HistoryFilterChip(
                  label: 'Filter 1',
                  selected: true,
                  onSelected: () {},
                ),
                HistoryFilterChip(
                  label: 'Filter 2',
                  selected: false,
                  onSelected: () {},
                ),
                HistoryFilterChip(
                  label: 'Filter 3',
                  selected: false,
                  onSelected: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(HistoryFilterChip), findsNWidgets(3));
      expect(find.text('Filter 1'), findsOneWidget);
      expect(find.text('Filter 2'), findsOneWidget);
      expect(find.text('Filter 3'), findsOneWidget);
    });

    testWidgets('has right padding', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChip(
              label: 'Test',
              selected: false,
              onSelected: () {},
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding).first);
      expect(padding.padding, const EdgeInsets.only(right: 8));
    });

    testWidgets('toggle selection state', (tester) async {
      bool isSelected = false;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: HistoryFilterChip(
                  label: 'Toggle',
                  selected: isSelected,
                  onSelected: () {
                    setState(() {
                      isSelected = !isSelected;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      // Initially unselected
      var chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isFalse);

      // Tap to select
      await tester.tap(find.byType(FilterChip));
      await tester.pump();

      chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('handles long labels', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HistoryFilterChip(
              label: 'Very Long Category Name',
              selected: false,
              onSelected: () {},
            ),
          ),
        ),
      );

      expect(find.text('Very Long Category Name'), findsOneWidget);
    });
  });
}
