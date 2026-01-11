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

  group('ResultCard - дополнительные тесты', () {
    testWidgets('отображает пустой список результатов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Empty Results',
              accentColor: Colors.blue,
              results: [],
            ),
          ),
        ),
      );

      expect(find.text('Empty Results'), findsOneWidget);
      expect(find.byType(ResultCard), findsOneWidget);
    });

    testWidgets('отображает множество элементов результатов', (tester) async {
      setTestViewportSize(tester);
      final items = List.generate(
        10,
        (i) => ResultRowItem(label: 'Item $i', value: '${i * 10}'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Many Items',
              accentColor: Colors.green,
              results: items,
            ),
          ),
        ),
      );

      expect(find.text('Item 0'), findsOneWidget);
      expect(find.text('Item 9'), findsOneWidget);
    });

    testWidgets('отображает длинные значения с ellipsis', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Long Values',
              accentColor: Colors.red,
              results: [
                ResultRowItem(
                  label: 'Very long material name that should be truncated',
                  value: 'Very long value text that might overflow',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ResultCard), findsOneWidget);
    });

    testWidgets('отображает различные цвета акцента', (tester) async {
      setTestViewportSize(tester);
      final colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];

      for (final color in colors) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResultCard(
                title: 'Test',
                accentColor: color,
                results: const [],
              ),
            ),
          ),
        );

        expect(find.byType(ResultCard), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('отображает totalRow с иконкой', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'With Icon Total',
              accentColor: Colors.purple,
              results: [],
              totalRow: ResultRowItem(
                label: 'Total Cost',
                value: '10000 ₽',
                icon: Icons.payments,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Total Cost'), findsOneWidget);
      expect(find.text('10000 ₽'), findsOneWidget);
      expect(find.byIcon(Icons.payments), findsOneWidget);
    });

    testWidgets('отображает footer с кнопкой', (tester) async {
      setTestViewportSize(tester);
      var buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'With Button',
              accentColor: Colors.blue,
              results: const [],
              footer: ElevatedButton(
                onPressed: () => buttonPressed = true,
                child: const Text('Save'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Save'), findsOneWidget);
      await tester.tap(find.text('Save'));
      expect(buttonPressed, isTrue);
    });

    testWidgets('отображает результаты с разными иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Different Icons',
              accentColor: Colors.teal,
              results: [
                ResultRowItem(label: 'Item 1', value: '10', icon: Icons.build),
                ResultRowItem(label: 'Item 2', value: '20', icon: Icons.home),
                ResultRowItem(label: 'Item 3', value: '30', icon: Icons.work),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.build), findsOneWidget);
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.work), findsOneWidget);
    });

    testWidgets('отображает titleIcon корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'With Title Icon',
              titleIcon: Icons.shopping_cart,
              accentColor: Colors.amber,
              results: [],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.shopping_cart), findsOneWidget);
      expect(find.text('With Title Icon'), findsOneWidget);
    });

    testWidgets('отображает subtitle в результатах', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'With Subtitles',
              accentColor: Colors.indigo,
              results: [
                ResultRowItem(
                  label: 'Material A',
                  value: '100 шт',
                  subtitle: 'Package of 25',
                ),
                ResultRowItem(
                  label: 'Material B',
                  value: '50 л',
                  subtitle: 'Liquid form',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Package of 25'), findsOneWidget);
      expect(find.text('Liquid form'), findsOneWidget);
    });

    testWidgets('использует custom backgroundColor', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Custom BG',
              accentColor: Colors.blue,
              backgroundColor: Colors.grey,
              results: [],
            ),
          ),
        ),
      );

      expect(find.byType(ResultCard), findsOneWidget);
    });
  });

  group('ResultCardLight - дополнительные тесты', () {
    testWidgets('отображает пустой список', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Empty',
              accentColor: Colors.blue,
              results: [],
            ),
          ),
        ),
      );

      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('отображает множество элементов', (tester) async {
      setTestViewportSize(tester);
      final items = List.generate(
        15,
        (i) => ResultRowItem(label: 'Light $i', value: '$i'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Many Items Light',
              accentColor: Colors.purple,
              results: items,
            ),
          ),
        ),
      );

      expect(find.text('Light 0'), findsOneWidget);
      expect(find.text('Light 14'), findsOneWidget);
    });

    testWidgets('отображает результат с иконкой и subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Full Item',
              accentColor: Colors.orange,
              results: [
                ResultRowItem(
                  label: 'Complete Item',
                  value: '999',
                  subtitle: 'With all fields',
                  icon: Icons.check_circle,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Complete Item'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);
      expect(find.text('With all fields'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('отображает totalRow с subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'Total with Sub',
              accentColor: Colors.green,
              results: [],
              totalRow: ResultRowItem(
                label: 'Grand Total',
                value: '5000',
                subtitle: 'Including tax',
              ),
            ),
          ),
        ),
      );

      expect(find.text('Grand Total'), findsOneWidget);
      expect(find.text('5000'), findsOneWidget);
      expect(find.text('Including tax'), findsOneWidget);
    });

    testWidgets('отображает footer с текстом', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'With Footer Text',
              accentColor: Colors.blue,
              results: [],
              footer: Text('Footer information here'),
            ),
          ),
        ),
      );

      expect(find.text('Footer information here'), findsOneWidget);
    });

    testWidgets('отображает различные цвета акцента', (tester) async {
      setTestViewportSize(tester);
      final colors = [Colors.pink, Colors.cyan, Colors.lime, Colors.deepOrange];

      for (final color in colors) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ResultCardLight(
                title: 'Color Test',
                accentColor: color,
                results: const [],
              ),
            ),
          ),
        );

        expect(find.byType(ResultCardLight), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });
  });

  group('MaterialsCardModern - дополнительные тесты', () {
    testWidgets('отображает пустой список items', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Empty Materials',
              titleIcon: Icons.inventory,
              items: [],
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Empty Materials'), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('отображает один элемент без divider', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Single Item',
              titleIcon: Icons.view_list,
              items: [
                MaterialItem(name: 'Only One', value: '100', icon: Icons.star),
              ],
              accentColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.text('Only One'), findsOneWidget);
      expect(find.byType(Divider), findsNothing);
    });

    testWidgets('отображает множество элементов', (tester) async {
      setTestViewportSize(tester);
      final items = List.generate(
        5,
        (i) => MaterialItem(
          name: 'Material $i',
          value: '${i * 10}',
          icon: Icons.category,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Many Materials',
              titleIcon: Icons.list_alt,
              items: items,
              accentColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Material 0'), findsOneWidget);
      expect(find.text('Material 4'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(4)); // n-1 dividers
    });

    testWidgets('отображает элементы с длинными названиями', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Long Names',
              titleIcon: Icons.text_fields,
              items: [
                MaterialItem(
                  name: 'Very long material name that should wrap properly in the layout',
                  value: '999 units',
                  icon: Icons.text_format,
                ),
              ],
              accentColor: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('отображает элементы с различными иконками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Different Icons',
              titleIcon: Icons.apps,
              items: [
                MaterialItem(name: 'Brick', value: '100', icon: Icons.view_module),
                MaterialItem(name: 'Paint', value: '50', icon: Icons.format_paint),
                MaterialItem(name: 'Wire', value: '200', icon: Icons.cable),
                MaterialItem(name: 'Tool', value: '5', icon: Icons.handyman),
              ],
              accentColor: Colors.teal,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.view_module), findsOneWidget);
      expect(find.byIcon(Icons.format_paint), findsOneWidget);
      expect(find.byIcon(Icons.cable), findsOneWidget);
      expect(find.byIcon(Icons.handyman), findsOneWidget);
    });

    testWidgets('отображает subtitle для всех элементов', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'All with Subtitles',
              titleIcon: Icons.info,
              items: [
                MaterialItem(
                  name: 'Item A',
                  value: '10',
                  subtitle: 'Description A',
                  icon: Icons.looks_one,
                ),
                MaterialItem(
                  name: 'Item B',
                  value: '20',
                  subtitle: 'Description B',
                  icon: Icons.looks_two,
                ),
              ],
              accentColor: Colors.blue,
            ),
          ),
        ),
      );

      expect(find.text('Description A'), findsOneWidget);
      expect(find.text('Description B'), findsOneWidget);
    });

    testWidgets('отображает элементы с различными значениями', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Various Values',
              titleIcon: Icons.assessment,
              items: [
                MaterialItem(name: 'Small', value: '1 шт', icon: Icons.filter_1),
                MaterialItem(name: 'Medium', value: '100 м²', icon: Icons.filter_2),
                MaterialItem(name: 'Large', value: '1000 кг', icon: Icons.filter_3),
                MaterialItem(name: 'Huge', value: '10000 ₽', icon: Icons.filter_4),
              ],
              accentColor: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('1 шт'), findsOneWidget);
      expect(find.text('100 м²'), findsOneWidget);
      expect(find.text('1000 кг'), findsOneWidget);
      expect(find.text('10000 ₽'), findsOneWidget);
    });

    testWidgets('отображает различные цвета акцента', (tester) async {
      setTestViewportSize(tester);
      final colors = [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
      ];

      for (final color in colors) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MaterialsCardModern(
                title: 'Color',
                titleIcon: Icons.palette,
                items: const [
                  MaterialItem(name: 'Test', value: '1', icon: Icons.circle),
                ],
                accentColor: color,
              ),
            ),
          ),
        );

        expect(find.byType(MaterialsCardModern), findsOneWidget);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('отображает длинный title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Very Long Title That Should Be Displayed Properly Without Issues',
              titleIcon: Icons.title,
              items: [],
              accentColor: Colors.indigo,
            ),
          ),
        ),
      );

      expect(find.textContaining('Very Long Title'), findsOneWidget);
    });

    testWidgets('корректно работает с Container', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Test Container',
              titleIcon: Icons.inbox,
              items: [
                MaterialItem(name: 'A', value: '1', icon: Icons.abc),
              ],
              accentColor: Colors.brown,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });
  });

  group('edge cases and special scenarios', () {
    testWidgets('ResultCard с очень длинным title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'This is an extremely long title that might cause layout issues if not handled properly',
              accentColor: Colors.blue,
              results: [],
            ),
          ),
        ),
      );

      expect(find.byType(ResultCard), findsOneWidget);
    });

    testWidgets('ResultCard с числовыми значениями в value', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCard(
              title: 'Numbers',
              accentColor: Colors.green,
              results: [
                ResultRowItem(label: 'Count', value: '1234567890'),
                ResultRowItem(label: 'Decimal', value: '123.456'),
                ResultRowItem(label: 'Negative', value: '-999'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('1234567890'), findsOneWidget);
      expect(find.text('123.456'), findsOneWidget);
      expect(find.text('-999'), findsOneWidget);
    });

    testWidgets('MaterialsCardModern с особыми символами в subtitle', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MaterialsCardModern(
              title: 'Special Chars',
              titleIcon: Icons.text_format,
              items: [
                MaterialItem(
                  name: 'Item',
                  value: '100',
                  subtitle: 'Special: №1 (50%) - важно!',
                  icon: Icons.star,
                ),
              ],
              accentColor: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text('Special: №1 (50%) - важно!'), findsOneWidget);
    });

    testWidgets('ResultCardLight без titleIcon', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ResultCardLight(
              title: 'No Icon',
              accentColor: Colors.red,
              results: [
                ResultRowItem(label: 'Test', value: '1'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('No Icon'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
    });
  });
}
