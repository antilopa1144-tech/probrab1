import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/widgets/animated_empty_state.dart';

void main() {
  group('AnimatedEmptyState', () {
    testWidgets('renders with required parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.inbox,
              title: 'No items',
              subtitle: 'There are no items to display',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedEmptyState), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.text('No items'), findsOneWidget);
      expect(find.text('There are no items to display'), findsOneWidget);
    });

    testWidgets('displays title text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.search,
              title: 'Ничего не найдено',
              subtitle: 'Попробуйте другой запрос',
            ),
          ),
        ),
      );

      expect(find.text('Ничего не найдено'), findsOneWidget);
    });

    testWidgets('displays subtitle text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.folder_open,
              title: 'Пустая папка',
              subtitle: 'Добавьте файлы',
            ),
          ),
        ),
      );

      expect(find.text('Добавьте файлы'), findsOneWidget);
    });

    testWidgets('renders action widget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.add,
              title: 'Create new',
              subtitle: 'Add your first item',
              action: ElevatedButton(
                onPressed: () {},
                child: const Text('Add Item'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);
    });

    testWidgets('does not render action when not provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.inbox,
              title: 'Empty',
              subtitle: 'Nothing here',
            ),
          ),
        ),
      );

      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('animates on appear', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.star,
              title: 'Test',
              subtitle: 'Animation test',
            ),
          ),
        ),
      );

      // Initial frame
      expect(find.byType(AnimatedEmptyState), findsOneWidget);

      // Pump half the animation duration
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AnimatedEmptyState), findsOneWidget);

      // Complete animation
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AnimatedEmptyState), findsOneWidget);
    });

    testWidgets('disposes animation controller properly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.inbox,
              title: 'Test',
              subtitle: 'Test',
            ),
          ),
        ),
      );

      // Replace with empty container
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox.shrink(),
          ),
        ),
      );

      // Should dispose without errors
      expect(find.byType(AnimatedEmptyState), findsNothing);
    });

    testWidgets('works with different icons', (tester) async {
      final icons = [
        Icons.inbox,
        Icons.search,
        Icons.folder_open,
        Icons.error_outline,
        Icons.favorite_border,
      ];

      for (final icon in icons) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AnimatedEmptyState(
                icon: icon,
                title: 'Test',
                subtitle: 'Test subtitle',
              ),
            ),
          ),
        );

        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    testWidgets('works with light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.inbox,
              title: 'Test',
              subtitle: 'Test',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedEmptyState), findsOneWidget);
    });

    testWidgets('works with dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.inbox,
              title: 'Test',
              subtitle: 'Test',
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedEmptyState), findsOneWidget);
    });

    testWidgets('handles long text gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: AnimatedEmptyState(
                icon: Icons.description,
                title: 'This is a very long title that might need multiple lines to display properly',
                subtitle: 'This is an even longer subtitle text that provides detailed information about the empty state and what the user can do to resolve it',
              ),
            ),
          ),
        ),
      );

      // Should render without overflow
      expect(find.byType(AnimatedEmptyState), findsOneWidget);
    });

    testWidgets('action button can be tapped', (tester) async {
      bool buttonPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedEmptyState(
              icon: Icons.add,
              title: 'Add Item',
              subtitle: 'Click to add',
              action: ElevatedButton(
                onPressed: () {
                  buttonPressed = true;
                },
                child: const Text('Add'),
              ),
            ),
          ),
        ),
      );

      // Complete animations
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      expect(buttonPressed, true);
    });
  });
}
