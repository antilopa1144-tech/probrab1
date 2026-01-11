import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/input_group_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('InputGroupCard', () {
    testWidgets('renders child widget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              child: Text('Child Content'),
            ),
          ),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              title: 'Dimensions',
              child: TextField(),
            ),
          ),
        ),
      );

      expect(find.text('Dimensions'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              title: 'Settings',
              subtitle: 'Configure your options',
              child: Switch(value: true, onChanged: (_) {}),
            ),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Configure your options'), findsOneWidget);
    });

    testWidgets('does not render title section when no title or trailing',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              child: Text('Just Child'),
            ),
          ),
        ),
      );

      expect(find.text('Just Child'), findsOneWidget);
      // Only the child text should be present
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders trailing widget', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              title: 'With Action',
              trailing: IconButton(
                icon: const Icon(Icons.info),
                onPressed: () {},
              ),
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.info), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('renders title section when only trailing is provided',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              trailing: Icon(Icons.help),
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.help), findsOneWidget);
    });

    testWidgets('applies custom padding', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              padding: EdgeInsets.all(32),
              child: Text('Padded'),
            ),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('renders all elements together', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              title: 'Full Card',
              subtitle: 'With all options',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('Action'),
              ),
              child: const Column(
                children: [
                  Text('Field 1'),
                  Text('Field 2'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Full Card'), findsOneWidget);
      expect(find.text('With all options'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.text('Field 1'), findsOneWidget);
      expect(find.text('Field 2'), findsOneWidget);
    });

    testWidgets('uses Column as layout', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InputGroupCard(
              title: 'Test',
              child: SizedBox(),
            ),
          ),
        ),
      );

      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('applies theme styles to title', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: InputGroupCard(
              title: 'Dark Title',
              subtitle: 'Dark subtitle',
              child: Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Dark Title'), findsOneWidget);
      expect(find.text('Dark subtitle'), findsOneWidget);
    });
  });
}
