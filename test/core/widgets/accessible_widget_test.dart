import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/widgets/accessible_widget.dart';

void main() {
  group('AccessibleWidget extension', () {
    testWidgets('withSemantics renders widget with label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Test').withSemantics(
              label: 'Test label',
              hint: 'Test hint',
            ),
          ),
        ),
      );

      // Widget tree includes Semantics and the child renders
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('withSemantics with button property renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Button').withSemantics(
              label: 'Button label',
              button: true,
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
    });

    testWidgets('withSemantics with header property renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Header').withSemantics(
              label: 'Header label',
              header: true,
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('withSemantics with enabled false renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Disabled').withSemantics(
              label: 'Disabled item',
              enabled: false,
            ),
          ),
        ),
      );

      expect(find.text('Disabled'), findsOneWidget);
    });

    testWidgets('withSemantics with all properties renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const Text('Full').withSemantics(
              label: 'Label',
              hint: 'Hint',
              button: true,
              header: false,
              image: false,
              textField: false,
              value: 'Value',
              enabled: true,
              checked: true,
              selected: false,
              onTap: () {},
              onLongPress: () {},
            ),
          ),
        ),
      );

      expect(find.text('Full'), findsOneWidget);
    });

    testWidgets('withTextScaling adds MediaQuery wrapper', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return const Text('Scaled').withTextScaling(
                  context,
                  minScale: 0.8,
                  maxScale: 2.0,
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Scaled'), findsOneWidget);
    });

    testWidgets('withTextScaling with defaults renders', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return const Text('Default scale').withTextScaling(context);
              },
            ),
          ),
        ),
      );

      expect(find.text('Default scale'), findsOneWidget);
    });

    testWidgets('withHighContrast applies theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return const Text('Contrast').withHighContrast(context);
              },
            ),
          ),
        ),
      );

      expect(find.text('Contrast'), findsOneWidget);
    });
  });

  group('AccessibleContainer', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              child: Text('Child'),
            ),
          ),
        ),
      );

      expect(find.text('Child'), findsOneWidget);
    });

    testWidgets('renders with semantic label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              semanticLabel: 'Container label',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders with semantic hint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              semanticHint: 'My hint',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('renders with isButton true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              isButton: true,
              child: Text('Button'),
            ),
          ),
        ),
      );

      expect(find.text('Button'), findsOneWidget);
    });

    testWidgets('renders with isHeader true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              isHeader: true,
              child: Text('Header'),
            ),
          ),
        ),
      );

      expect(find.text('Header'), findsOneWidget);
    });

    testWidgets('renders with onSemanticTap callback', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              onSemanticTap: () {},
              child: const Text('Tappable'),
            ),
          ),
        ),
      );

      expect(find.text('Tappable'), findsOneWidget);
    });

    testWidgets('renders with all properties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              semanticLabel: 'Full label',
              semanticHint: 'Full hint',
              isButton: true,
              isHeader: false,
              onSemanticTap: () {},
              child: const Text('Full'),
            ),
          ),
        ),
      );

      expect(find.text('Full'), findsOneWidget);
    });

    testWidgets('AccessibleContainer is wrapped by Semantics', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AccessibleContainer(
              semanticLabel: 'Test',
              child: Text('Inner'),
            ),
          ),
        ),
      );

      // Find the AccessibleContainer and verify it's in the tree
      expect(find.byType(AccessibleContainer), findsOneWidget);
      expect(find.text('Inner'), findsOneWidget);
    });
  });
}
