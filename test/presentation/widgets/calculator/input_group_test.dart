import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/input_group.dart';

void main() {
  group('InputGroup', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Geometry',
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.text('Geometry'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Settings',
              icon: Icons.settings,
              children: [Text('Settings content')],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('renders multiple children', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Fields',
              children: [
                Text('Field 1'),
                Text('Field 2'),
                Text('Field 3'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
      expect(find.text('Field 3'), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Group',
              trailing: IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {},
              ),
              children: const [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('accepts custom accent color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Colored',
              icon: Icons.color_lens,
              accentColor: Colors.purple,
              children: [Text('Content')],
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.color_lens));
      expect(icon.color, Colors.purple);
    });

    testWidgets('accepts custom background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Background',
              backgroundColor: Colors.grey,
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byType(InputGroup), findsOneWidget);
    });

    testWidgets('renders without shadow when showShadow is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Flat',
              showShadow: false,
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byType(InputGroup), findsOneWidget);
    });

    testWidgets('collapsible group starts expanded by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Collapsible',
              isCollapsible: true,
              children: [Text('Expandable content')],
            ),
          ),
        ),
      );

      expect(find.text('Expandable content'), findsOneWidget);
    });

    testWidgets('collapsible group can start collapsed', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Collapsible',
              isCollapsible: true,
              initiallyExpanded: false,
              children: [Text('Hidden content')],
            ),
          ),
        ),
      );

      // Content should not be visible when collapsed
      expect(find.text('Hidden content'), findsNothing);
    });

    testWidgets('collapsible group can be toggled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Toggle Me',
              isCollapsible: true,
              initiallyExpanded: true,
              children: [Text('Toggleable')],
            ),
          ),
        ),
      );

      // Initially expanded
      expect(find.text('Toggleable'), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.text('Toggle Me'));
      await tester.pumpAndSettle();

      // Should be collapsed now
      expect(find.text('Toggleable'), findsNothing);
    });

    testWidgets('accepts custom padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroup(
              title: 'Padded',
              padding: EdgeInsets.all(32),
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byType(InputGroup), findsOneWidget);
    });
  });

  group('InputGroupSimple', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupSimple(
              title: 'Simple Group',
              children: [Text('Simple content')],
            ),
          ),
        ),
      );

      expect(find.text('Simple Group'), findsOneWidget);
      expect(find.text('Simple content'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupSimple(
              title: 'With Icon',
              icon: Icons.info,
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputGroupSimple(
              title: 'Group',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Action'),
              ),
              children: const [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.text('Action'), findsOneWidget);
    });

    testWidgets('accepts custom accent color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupSimple(
              title: 'Colored',
              icon: Icons.palette,
              accentColor: Colors.red,
              children: [Text('Content')],
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.palette));
      expect(icon.color, Colors.red);
    });
  });

  group('InputGroupColored', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupColored(
              title: 'Colored Group',
              accentColor: Colors.blue,
              children: [Text('Colored content')],
            ),
          ),
        ),
      );

      expect(find.text('Colored Group'), findsOneWidget);
      expect(find.text('Colored content'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupColored(
              title: 'With Icon',
              icon: Icons.star,
              accentColor: Colors.amber,
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupColored(
              title: 'Group',
              accentColor: Colors.green,
              trailing: Icon(Icons.chevron_right),
              children: [Text('Content')],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('uses accent color for icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupColored(
              title: 'Test',
              icon: Icons.brush,
              accentColor: Colors.orange,
              children: [Text('Content')],
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.brush));
      expect(icon.color, Colors.orange);
    });
  });
}
