import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/mode_selector.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ModeSelector', () {
    testWidgets('renders with two options', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelector(
              options: const ['Option 1', 'Option 2'],
              selectedIndex: 0,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Option 1'), findsOneWidget);
      expect(find.text('Option 2'), findsOneWidget);
    });

    testWidgets('renders with three options', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelector(
              options: const ['A', 'B', 'C'],
              selectedIndex: 1,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('calls onSelect when tapped', (tester) async {
      setTestViewportSize(tester);
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelector(
              options: const ['First', 'Second'],
              selectedIndex: 0,
              onSelect: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Second'));
      expect(selectedIndex, 1);
    });

    testWidgets('accepts custom accent color', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelector(
              options: const ['Option 1', 'Option 2'],
              selectedIndex: 0,
              onSelect: (_) {},
              accentColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byType(ModeSelector), findsOneWidget);
    });

    testWidgets('accepts custom height', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelector(
              options: const ['Option 1', 'Option 2'],
              selectedIndex: 0,
              onSelect: (_) {},
              height: 60,
            ),
          ),
        ),
      );

      expect(find.byType(ModeSelector), findsOneWidget);
    });
  });

  group('ModeSelectorWithIcons', () {
    testWidgets('renders with icons', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectorWithIcons(
              options: const [
                ModeSelectorIconOption(label: 'Home', icon: Icons.home),
                ModeSelectorIconOption(label: 'Settings', icon: Icons.settings),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('renders without icons', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectorWithIcons(
              options: const [
                ModeSelectorIconOption(label: 'Label 1'),
                ModeSelectorIconOption(label: 'Label 2'),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Label 1'), findsOneWidget);
      expect(find.text('Label 2'), findsOneWidget);
    });

    testWidgets('calls onSelect when tapped', (tester) async {
      setTestViewportSize(tester);
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectorWithIcons(
              options: const [
                ModeSelectorIconOption(label: 'First', icon: Icons.one_k),
                ModeSelectorIconOption(label: 'Second', icon: Icons.two_k),
              ],
              selectedIndex: 0,
              onSelect: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Second'));
      expect(selectedIndex, 1);
    });
  });

  group('ModeSelectorVertical', () {
    testWidgets('renders vertically', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectorVertical(
              options: const ['Option A', 'Option B', 'Option C'],
              selectedIndex: 1,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
      expect(find.text('Option C'), findsOneWidget);
    });

    testWidgets('shows check icon for selected option', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectorVertical(
              options: const ['First', 'Second'],
              selectedIndex: 0,
              onSelect: (_) {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('calls onSelect when tapped', (tester) async {
      setTestViewportSize(tester);
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectorVertical(
              options: const ['A', 'B', 'C'],
              selectedIndex: 0,
              onSelect: (index) => selectedIndex = index,
            ),
          ),
        ),
      );

      await tester.tap(find.text('C'));
      expect(selectedIndex, 2);
    });

    testWidgets('accepts custom accent color', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModeSelectorVertical(
              options: const ['Option 1', 'Option 2'],
              selectedIndex: 0,
              onSelect: (_) {},
              accentColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(ModeSelectorVertical), findsOneWidget);
    });
  });

  group('ModeSelectorIconOption', () {
    test('creates with label only', () {
      const option = ModeSelectorIconOption(label: 'Test');
      expect(option.label, 'Test');
      expect(option.icon, null);
    });

    test('creates with label and icon', () {
      const option = ModeSelectorIconOption(label: 'Home', icon: Icons.home);
      expect(option.label, 'Home');
      expect(option.icon, Icons.home);
    });
  });
}
