import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/projects_empty_state.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('ProjectsEmptyState', () {
    testWidgets('shows default empty message', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: '',
              showFavoritesOnly: false,
              filterStatus: null,
            ),
          ),
        ),
      );

      expect(find.text('Нет проектов'), findsOneWidget);
      expect(find.text('Создайте первый проект'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open_rounded), findsOneWidget);
    });

    testWidgets('shows search not found message when searching', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: 'kitchen',
              showFavoritesOnly: false,
              filterStatus: null,
            ),
          ),
        ),
      );

      expect(find.text('Проекты не найдены'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('shows favorites empty message', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: '',
              showFavoritesOnly: true,
              filterStatus: null,
            ),
          ),
        ),
      );

      expect(find.text('Нет избранных проектов'), findsOneWidget);
      expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);
    });

    testWidgets('shows filter empty message when status filter is active', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: '',
              showFavoritesOnly: false,
              filterStatus: ProjectStatus.completed,
            ),
          ),
        ),
      );

      expect(find.text('Нет проектов с этим статусом'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_off_rounded), findsOneWidget);
    });

    testWidgets('does not show create hint when searching', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: 'test',
              showFavoritesOnly: false,
              filterStatus: null,
            ),
          ),
        ),
      );

      expect(find.text('Создайте первый проект'), findsNothing);
    });

    testWidgets('does not show create hint when filtering by favorites', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: '',
              showFavoritesOnly: true,
              filterStatus: null,
            ),
          ),
        ),
      );

      expect(find.text('Создайте первый проект'), findsNothing);
    });

    testWidgets('does not show create hint when filtering by status', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: '',
              showFavoritesOnly: false,
              filterStatus: ProjectStatus.inProgress,
            ),
          ),
        ),
      );

      expect(find.text('Создайте первый проект'), findsNothing);
    });

    testWidgets('centers content', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: '',
              showFavoritesOnly: false,
              filterStatus: null,
            ),
          ),
        ),
      );

      // ProjectsEmptyState wraps content in Center
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(ProjectsEmptyState), findsOneWidget);
    });

    testWidgets('search has priority over favorites filter', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ProjectsEmptyState(
              searchQuery: 'query',
              showFavoritesOnly: true,
              filterStatus: null,
            ),
          ),
        ),
      );

      // Search message should be shown, not favorites message
      expect(find.text('Проекты не найдены'), findsOneWidget);
      expect(find.text('Нет избранных проектов'), findsNothing);
    });

    testWidgets('renders with all project statuses', (tester) async {
      setTestViewportSize(tester);
      for (final status in ProjectStatus.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ProjectsEmptyState(
                searchQuery: '',
                showFavoritesOnly: false,
                filterStatus: status,
              ),
            ),
          ),
        );

        expect(find.text('Нет проектов с этим статусом'), findsOneWidget);
      }
    });
  });
}
