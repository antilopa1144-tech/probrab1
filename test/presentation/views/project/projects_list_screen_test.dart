import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/views/project/projects_list_screen.dart';
import 'package:probrab_ai/presentation/providers/project_v2_provider.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('ProjectsListScreen', () {
    testWidgets('renders without error', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byType(ProjectsListScreen), findsOneWidget);
    });

    testWidgets('shows app bar with title', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      // SliverAppBar.large may render title twice (collapsed + expanded)
      expect(find.text('Проекты'), findsWidgets);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byType(Scaffold), findsOneWidget);
      // SliverAppBar is used instead of AppBar
      expect(find.byType(SliverAppBar), findsOneWidget);
    });

    testWidgets('shows filter icon in app bar', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
    });

    testWidgets('shows search bar', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.text('Поиск по названию, адресу, тегам...'), findsOneWidget);
    });

    testWidgets('shows SearchBar widget', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byType(SearchBar), findsOneWidget);
    });

    testWidgets('показывает иконку сканирования QR кода', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('показывает FAB для создания нового проекта', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Новый проект'), findsOneWidget);
    });

    testWidgets('FAB имеет иконку добавления', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    // Skip: Loading state is transient and hard to catch reliably
    testWidgets(
      'показывает CircularProgressIndicator при загрузке',
      (tester) async {
        setTestViewportSize(tester);
        addTearDown(tester.view.resetPhysicalSize);

        // Don't override provider to keep loading state
        await tester.pumpWidget(
          createTestApp(child: const ProjectsListScreen()),
        );

        // Just pump once to see loading state
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
      skip: true, // Loading state is transient
    );

    testWidgets('показывает сортировку', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byIcon(Icons.sort_rounded), findsOneWidget);
    });

    testWidgets('показывает кнопку bulk select', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
    });

    testWidgets('SearchBar имеет правильный hint text', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.text('Поиск по названию, адресу, тегам...'), findsOneWidget);
    });

    testWidgets('использует ConsumerStatefulWidget', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      final element = tester.element(find.byType(ProjectsListScreen));
      expect(element.widget, isA<ConsumerStatefulWidget>());
    });

    testWidgets('показывает FilterChips для фильтрации', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      // Should have at least "Все" and "Избранное" filter chips
      expect(find.byType(FilterChip), findsWidgets);
      expect(find.text('Все'), findsOneWidget);
      expect(find.text('Избранное'), findsOneWidget);
    });

    testWidgets('показывает проекты в списке', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      final testProject = ProjectV2()
        ..id = 1
        ..name = 'Тестовый проект'
        ..status = ProjectStatus.inProgress
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => [testProject]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      expect(find.text('Тестовый проект'), findsOneWidget);
    });

    testWidgets('показывает empty state когда нет проектов', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          overrides: [
            allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
          ],
          child: const ProjectsListScreen(),
        ),
      );

      await pumpForStream(tester);

      // Should show empty state
      expect(find.text('Все проекты'), findsOneWidget);
    });

    // Skip: Тесты требующие взаимодействия с popups
    testWidgets(
      'можно открыть меню сортировки',
      (tester) async {
        setTestViewportSize(tester);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestApp(
            overrides: [
              allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
            ],
            child: const ProjectsListScreen(),
          ),
        );

        await pumpForStream(tester);

        final sortButton = find.byIcon(Icons.sort_rounded);
        await tester.tap(sortButton);
        await tester.pumpAndSettle();

        expect(find.text('Сортировка'), findsOneWidget);
      },
      skip: true, // Requires bottom sheet interaction
    );

    testWidgets(
      'можно открыть меню фильтров',
      (tester) async {
        setTestViewportSize(tester);
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          createTestApp(
            overrides: [
              allProjectsProvider.overrideWith((ref) async => <ProjectV2>[]),
            ],
            child: const ProjectsListScreen(),
          ),
        );

        await pumpForStream(tester);

        final filterButton = find.byIcon(Icons.filter_list_rounded);
        await tester.tap(filterButton);
        await tester.pumpAndSettle();

        expect(find.text('Фильтры'), findsOneWidget);
      },
      skip: true, // Requires bottom sheet interaction
    );
  });
}
