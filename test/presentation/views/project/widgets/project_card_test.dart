import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_card.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('ProjectCard', () {
    late ProjectV2 testProject;

    setUp(() {
      testProject = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..description = 'Test description'
        ..createdAt = DateTime(2024, 1, 15)
        ..updatedAt = DateTime(2024, 1, 20)
        ..isFavorite = false
        ..tags = ['tag1', 'tag2']
        ..status = ProjectStatus.planning;
    });

    testWidgets('renders project name', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('renders project description', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test description'), findsOneWidget);
    });

    testWidgets('shows first tag', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('tag1'), findsOneWidget);
    });

    testWidgets('calls onTap when card is tapped', (tester) async {
      setTestViewportSize(tester);
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () => tapped = true,
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell).first);
      expect(tapped, isTrue);
    });

    testWidgets('calls onDelete when delete button is pressed', (tester) async {
      setTestViewportSize(tester);
      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () => deleted = true,
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      expect(deleted, isTrue);
    });

    testWidgets('calls onToggleFavorite when star is pressed', (tester) async {
      setTestViewportSize(tester);
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () => toggled = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star_border));
      expect(toggled, isTrue);
    });

    testWidgets('shows filled star when project is favorite', (tester) async {
      setTestViewportSize(tester);
      testProject.isFavorite = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.star_border), findsNothing);
    });

    testWidgets('shows status chip for planning', (tester) async {
      setTestViewportSize(tester);
      testProject.status = ProjectStatus.planning;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Планирование'), findsOneWidget);
    });

    testWidgets('shows status chip for inProgress', (tester) async {
      setTestViewportSize(tester);
      testProject.status = ProjectStatus.inProgress;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('В работе'), findsOneWidget);
    });

    testWidgets('shows status chip for completed', (tester) async {
      setTestViewportSize(tester);
      testProject.status = ProjectStatus.completed;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Завершён'), findsOneWidget);
    });

    testWidgets('shows status chip for onHold', (tester) async {
      setTestViewportSize(tester);
      testProject.status = ProjectStatus.onHold;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Приостановлен'), findsOneWidget);
    });

    testWidgets('shows status chip for cancelled', (tester) async {
      setTestViewportSize(tester);
      testProject.status = ProjectStatus.cancelled;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('Отменён'), findsOneWidget);
    });

    testWidgets('hides description when empty', (tester) async {
      setTestViewportSize(tester);
      testProject.description = null;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      // Only name should be visible
      expect(find.text('Test Project'), findsOneWidget);
    });

    testWidgets('formats date correctly', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectCard(
              project: testProject,
              onTap: () {},
              onDelete: () {},
              onToggleFavorite: () {},
            ),
          ),
        ),
      );

      expect(find.text('15.01.2024'), findsOneWidget);
    });
  });
}
