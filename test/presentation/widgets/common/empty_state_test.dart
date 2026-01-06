import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/empty_state.dart';

void main() {
  group('EmptyState', () {
    testWidgets('renders with title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(title: 'No Items'),
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
    });

    testWidgets('renders with description', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(description: 'Add your first item to get started'),
          ),
        ),
      );

      expect(find.text('Add your first item to get started'), findsOneWidget);
    });

    testWidgets('renders with icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.inbox),
          ),
        ),
      );

      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders action button when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              actionLabel: 'Add Item',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('calls onAction when button is tapped', (tester) async {
      bool actionCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              actionLabel: 'Create',
              onAction: () {
                actionCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton));
      expect(actionCalled, isTrue);
    });

    testWidgets('hides button when actionLabel is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('hides button when onAction is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              actionLabel: 'Create',
            ),
          ),
        ),
      );

      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('renders custom child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              child: Text('Custom Widget'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Widget'), findsOneWidget);
    });

    testWidgets('renders with all properties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.folder_open,
              title: 'No Projects',
              description: 'Create a project to organize your calculations',
              actionLabel: 'New Project',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder_open), findsOneWidget);
      expect(find.text('No Projects'), findsOneWidget);
      expect(find.text('Create a project to organize your calculations'), findsOneWidget);
      expect(find.text('New Project'), findsOneWidget);
    });

    testWidgets('centers content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(title: 'Centered'),
          ),
        ),
      );

      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('has padding around content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(title: 'Padded'),
          ),
        ),
      );

      expect(find.byType(Padding), findsWidgets);
    });

    testWidgets('centers title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(title: 'Centered Title'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Centered Title'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('centers description text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(description: 'Centered description'),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Centered description'));
      expect(text.textAlign, TextAlign.center);
    });

    testWidgets('icon has correct size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(icon: Icons.star),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.star));
      expect(icon.size, 48);
    });
  });
}
