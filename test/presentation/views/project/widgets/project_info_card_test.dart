import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_info_card.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('ProjectInfoCard', () {
    late ProjectV2 testProject;

    setUp(() {
      testProject = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..description = 'A test project description'
        ..createdAt = DateTime(2024, 1, 15, 10, 30)
        ..updatedAt = DateTime(2024, 1, 20, 14, 45)
        ..isFavorite = false
        ..tags = ['renovation', 'kitchen']
        ..status = ProjectStatus.inProgress
        ..notes = 'Some project notes';
    });

    testWidgets('renders description', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('A test project description'), findsOneWidget);
    });

    testWidgets('renders creation date', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('Создан:'), findsOneWidget);
      expect(find.text('15.01.2024 10:30'), findsOneWidget);
    });

    testWidgets('renders update date', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('Обновлён:'), findsOneWidget);
      expect(find.text('20.01.2024 14:45'), findsOneWidget);
    });

    testWidgets('renders material cost section', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('Материалы'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('renders labor cost section', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('Работы'), findsOneWidget);
      expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
    });

    testWidgets('renders tags', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('renovation'), findsOneWidget);
      expect(find.text('kitchen'), findsOneWidget);
    });

    testWidgets('renders notes section', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('Заметки'), findsOneWidget);
      expect(find.text('Some project notes'), findsOneWidget);
    });

    testWidgets('hides notes section when notes is null', (tester) async {
      setTestViewportSize(tester);
      testProject.notes = null;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.text('Заметки'), findsNothing);
    });

    testWidgets('hides description when empty', (tester) async {
      setTestViewportSize(tester);
      testProject.description = null;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      // Should still render dates
      expect(find.text('Создан:'), findsOneWidget);
    });

    testWidgets('hides tags section when tags is empty', (tester) async {
      setTestViewportSize(tester);
      testProject.tags = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('is wrapped in a Card', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectInfoCard(project: testProject),
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}
