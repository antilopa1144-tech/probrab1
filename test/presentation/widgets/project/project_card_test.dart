import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/project/project_card.dart';
import 'package:probrab_ai/presentation/widgets/project/project_status_badge.dart';

void main() {
  group('ProjectCard', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(title: 'Test Project'),
          ),
        ),
      );

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              title: 'Project',
              subtitle: 'Project description',
            ),
          ),
        ),
      );

      expect(find.text('Project'), findsOneWidget);
      expect(find.text('Project description'), findsOneWidget);
    });

    testWidgets('does not render subtitle when null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(title: 'Project'),
          ),
        ),
      );

      expect(find.text('Project'), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
    });

    testWidgets('renders status badge when status provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              title: 'Project',
              statusLabel: 'Active',
              statusColor: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(ProjectStatusBadge), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('does not render status badge when status null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(title: 'Project'),
          ),
        ),
      );

      expect(find.byType(ProjectStatusBadge), findsNothing);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              title: 'Project',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long pressed', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              title: 'Project',
              onLongPress: () => longPressed = true,
            ),
          ),
        ),
      );

      await tester.longPress(find.byType(ListTile));
      expect(longPressed, isTrue);
    });

    testWidgets('renders leading widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              title: 'Project',
              leading: Icon(Icons.folder),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.folder), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              title: 'Project',
              trailing: Icon(Icons.arrow_forward),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);
    });

    testWidgets('trailing widget overrides status badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              title: 'Project',
              statusLabel: 'Active',
              statusColor: Colors.green,
              trailing: Icon(Icons.more_vert),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.byType(ProjectStatusBadge), findsNothing);
    });

    testWidgets('uses Card widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(title: 'Project'),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('uses ListTile for content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectCard(title: 'Project'),
          ),
        ),
      );

      expect(find.byType(ListTile), findsOneWidget);
    });
  });
}
