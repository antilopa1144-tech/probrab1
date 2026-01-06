import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/project/project_status_badge.dart';

void main() {
  group('ProjectStatusBadge', () {
    testWidgets('renders with label', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusBadge(
              label: 'Active',
              backgroundColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('uses provided background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusBadge(
              label: 'Status',
              backgroundColor: Colors.blue,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, Colors.blue);
    });

    testWidgets('uses custom text color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusBadge(
              label: 'Custom',
              backgroundColor: Colors.white,
              textColor: Colors.black,
            ),
          ),
        ),
      );

      expect(find.byType(ProjectStatusBadge), findsOneWidget);
    });

    testWidgets('has rounded corners', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusBadge(
              label: 'Rounded',
              backgroundColor: Colors.orange,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('has correct padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusBadge(
              label: 'Padded',
              backgroundColor: Colors.purple,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      expect(
        container.padding,
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      );
    });

    testWidgets('renders different status labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ProjectStatusBadge(
                  label: 'Planning',
                  backgroundColor: Colors.blue,
                ),
                ProjectStatusBadge(
                  label: 'In Progress',
                  backgroundColor: Colors.orange,
                ),
                ProjectStatusBadge(
                  label: 'Completed',
                  backgroundColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Planning'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('renders long labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusBadge(
              label: 'Very Long Status Label Here',
              backgroundColor: Colors.teal,
            ),
          ),
        ),
      );

      expect(find.text('Very Long Status Label Here'), findsOneWidget);
    });

    testWidgets('contains Text widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectStatusBadge(
              label: 'Test',
              backgroundColor: Colors.red,
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsOneWidget);
    });
  });
}
