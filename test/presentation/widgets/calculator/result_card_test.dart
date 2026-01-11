import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/result_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ResultRowItem', () {
    test('creates with required parameters', () {
      const item = ResultRowItem(label: 'Test', value: '100');
      expect(item.label, 'Test');
      expect(item.value, '100');
      expect(item.subtitle, null);
      expect(item.icon, null);
    });

    test('creates with all parameters', () {
      const item = ResultRowItem(
        label: 'Material',
        value: '50 шт',
        subtitle: 'Additional info',
        icon: Icons.build,
      );
      expect(item.label, 'Material');
      expect(item.value, '50 шт');
      expect(item.subtitle, 'Additional info');
      expect(item.icon, Icons.build);
    });
  });

  group('ResultCard', () {
    testWidgets('renders with title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Shopping List',
              accentColor: Colors.blue,
              results: [],
            ),
          ),
        ),
      );

      expect(find.text('Shopping List'), findsOneWidget);
    });

    testWidgets('renders with title icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Materials',
              titleIcon: Icons.construction,
              accentColor: Colors.green,
              results: [],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('renders result items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Results',
              accentColor: Colors.orange,
              results: [
                ResultRowItem(label: 'Item 1', value: '10'),
                ResultRowItem(label: 'Item 2', value: '20'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('renders result item with subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Results',
              accentColor: Colors.purple,
              results: [
                ResultRowItem(
                  label: 'Paint',
                  value: '5 л',
                  subtitle: 'White color',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Paint'), findsOneWidget);
      expect(find.text('5 л'), findsOneWidget);
      expect(find.text('White color'), findsOneWidget);
    });

    testWidgets('renders result item with icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Results',
              accentColor: Colors.red,
              results: [
                ResultRowItem(
                  label: 'Screws',
                  value: '100 шт',
                  icon: Icons.settings,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders total row', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Shopping List',
              accentColor: Colors.blue,
              results: [
                ResultRowItem(label: 'Item', value: '100'),
              ],
              totalRow: ResultRowItem(
                label: 'Total',
                value: '5000 ₽',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total'), findsOneWidget);
      expect(find.text('5000 ₽'), findsOneWidget);
    });

    testWidgets('renders footer widget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Results',
              accentColor: Colors.teal,
              results: [],
              footer: Text('Footer content'),
            ),
          ),
        ),
      );

      expect(find.text('Footer content'), findsOneWidget);
    });

    testWidgets('accepts custom background color', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Results',
              accentColor: Colors.blue,
              backgroundColor: Colors.black87,
              results: [],
            ),
          ),
        ),
      );

      expect(find.byType(ResultCard), findsOneWidget);
    });
  });

  group('ResultCardLight', () {
    testWidgets('renders with title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Light Card',
              accentColor: Colors.blue,
              results: [],
            ),
          ),
        ),
      );

      expect(find.text('Light Card'), findsOneWidget);
    });

    testWidgets('renders with title icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Materials',
              titleIcon: Icons.list,
              accentColor: Colors.green,
              results: [],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.list), findsOneWidget);
    });

    testWidgets('renders result items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Results',
              accentColor: Colors.orange,
              results: [
                ResultRowItem(label: 'A', value: '1'),
                ResultRowItem(label: 'B', value: '2'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('renders total row', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'List',
              accentColor: Colors.purple,
              results: [],
              totalRow: ResultRowItem(label: 'Sum', value: '999'),
            ),
          ),
        ),
      );

      expect(find.text('Sum'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
    });

    testWidgets('renders footer', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Card',
              accentColor: Colors.red,
              results: const [],
              footer: ElevatedButton(
                onPressed: () {},
                child: const Text('Action'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Action'), findsOneWidget);
    });
  });

  group('MaterialItem', () {
    test('creates with required parameters', () {
      const item = MaterialItem(
        name: 'Tiles',
        value: '100 шт',
        icon: Icons.grid_on,
      );
      expect(item.name, 'Tiles');
      expect(item.value, '100 шт');
      expect(item.icon, Icons.grid_on);
      expect(item.subtitle, null);
    });

    test('creates with subtitle', () {
      const item = MaterialItem(
        name: 'Glue',
        value: '3 bags',
        subtitle: '25 kg each',
        icon: Icons.shopping_bag,
      );
      expect(item.subtitle, '25 kg each');
    });
  });

  group('MaterialsCardModern', () {
    testWidgets('renders with title and icon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Materials',
              titleIcon: Icons.construction,
              items: [],
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Materials'), findsOneWidget);
      expect(find.byIcon(Icons.construction), findsOneWidget);
    });

    testWidgets('renders material items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'List',
              titleIcon: Icons.list,
              items: [
                MaterialItem(name: 'Tile', value: '50 шт', icon: Icons.grid_on),
                MaterialItem(name: 'Glue', value: '2 bags', icon: Icons.shopping_bag),
              ],
              accentColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Tile'), findsOneWidget);
      expect(find.text('50 шт'), findsOneWidget);
      expect(find.text('Glue'), findsOneWidget);
      expect(find.text('2 bags'), findsOneWidget);
    });

    testWidgets('renders item with subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Materials',
              titleIcon: Icons.build,
              items: [
                MaterialItem(
                  name: 'Paint',
                  value: '10 л',
                  subtitle: 'White matte',
                  icon: Icons.format_paint,
                ),
              ],
              accentColor: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('White matte'), findsOneWidget);
    });

    testWidgets('shows dividers between items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Materials',
              titleIcon: Icons.list,
              items: [
                MaterialItem(name: 'A', value: '1', icon: Icons.abc),
                MaterialItem(name: 'B', value: '2', icon: Icons.abc),
                MaterialItem(name: 'C', value: '3', icon: Icons.abc),
              ],
              accentColor: Colors.purple,
            ),
          ),
        ),
      );

      // Should have dividers between items (2 dividers for 3 items)
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });
}
