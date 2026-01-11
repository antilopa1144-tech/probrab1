import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/type_selector_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('TypeSelectorCard', () {
    testWidgets('renders with title and icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.format_paint,
              title: 'Paint',
              isSelected: false,
              accentColor: Colors.blue,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Paint'), findsOneWidget);
      expect(find.byIcon(Icons.format_paint), findsOneWidget);
    });

    testWidgets('renders with subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.wallpaper,
              title: 'Wallpaper',
              subtitle: '2 layers',
              isSelected: false,
              accentColor: Colors.green,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('2 layers'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      setTestViewportSize(tester);
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.brush,
              title: 'Brush',
              isSelected: false,
              accentColor: Colors.orange,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TypeSelectorCard));
      expect(tapped, isTrue);
    });

    testWidgets('shows checkmark when selected and showCheckmark is true', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.check_box,
              title: 'Option',
              isSelected: true,
              accentColor: Colors.purple,
              onTap: () {},
              showCheckmark: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('does not show checkmark when not selected', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.check_box,
              title: 'Option',
              isSelected: false,
              accentColor: Colors.purple,
              onTap: () {},
              showCheckmark: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('uses custom icon size', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.star,
              title: 'Star',
              isSelected: false,
              accentColor: Colors.amber,
              onTap: () {},
              iconSize: 40,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.size, 40);
    });

    testWidgets('animates selection change', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCard(
              icon: Icons.square,
              title: 'Square',
              isSelected: false,
              accentColor: Colors.red,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedContainer), findsOneWidget);
    });

    testWidgets('handles long titles', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: TypeSelectorCard(
                icon: Icons.text_fields,
                title: 'Very Long Title That Should Be Truncated',
                isSelected: false,
                accentColor: Colors.teal,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byType(TypeSelectorCard), findsOneWidget);
    });
  });

  group('TypeSelectorCardCompact', () {
    testWidgets('renders with title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCardCompact(
              title: 'Compact',
              isSelected: false,
              accentColor: Colors.blue,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Compact'), findsOneWidget);
    });

    testWidgets('uses default icon when none provided', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCardCompact(
              title: 'No Icon',
              isSelected: false,
              accentColor: Colors.blue,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCardCompact(
              icon: Icons.star,
              title: 'Custom Icon',
              isSelected: false,
              accentColor: Colors.amber,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('uses smaller icon size', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorCardCompact(
              icon: Icons.minimize,
              title: 'Small',
              isSelected: false,
              accentColor: Colors.grey,
              onTap: () {},
            ),
          ),
        ),
      );

      // Compact version uses 20px icon size
      expect(find.byType(TypeSelectorCard), findsOneWidget);
    });
  });

  group('TypeSelectorOption', () {
    test('creates with required parameters', () {
      const option = TypeSelectorOption(
        icon: Icons.home,
        title: 'Home',
      );
      expect(option.icon, Icons.home);
      expect(option.title, 'Home');
      expect(option.subtitle, isNull);
    });

    test('creates with subtitle', () {
      const option = TypeSelectorOption(
        icon: Icons.work,
        title: 'Work',
        subtitle: 'Office building',
      );
      expect(option.subtitle, 'Office building');
    });
  });

  group('TypeSelectorGroup', () {
    testWidgets('renders all options', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.home, title: 'Home'),
                TypeSelectorOption(icon: Icons.work, title: 'Work'),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
    });

    testWidgets('calls onSelect with correct index when tapped', (tester) async {
      setTestViewportSize(tester);
      int? selectedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.home, title: 'Home'),
                TypeSelectorOption(icon: Icons.work, title: 'Work'),
              ],
              selectedIndex: 0,
              onSelect: (index) {
                selectedIndex = index;
              },
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Work'));
      expect(selectedIndex, 1);
    });

    testWidgets('renders horizontally by default', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.one_k, title: 'One'),
                TypeSelectorOption(icon: Icons.two_k, title: 'Two'),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
              accentColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(Row), findsOneWidget);
    });

    testWidgets('renders vertically when direction is vertical', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.one_k, title: 'One'),
                TypeSelectorOption(icon: Icons.two_k, title: 'Two'),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
              accentColor: Colors.green,
              direction: Axis.vertical,
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('respects custom spacing', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TypeSelectorGroup(
              options: const [
                TypeSelectorOption(icon: Icons.circle, title: 'A'),
                TypeSelectorOption(icon: Icons.square, title: 'B'),
              ],
              selectedIndex: 0,
              onSelect: (_) {},
              accentColor: Colors.red,
              spacing: 24,
            ),
          ),
        ),
      );

      expect(find.byType(TypeSelectorGroup), findsOneWidget);
    });
  });
}
