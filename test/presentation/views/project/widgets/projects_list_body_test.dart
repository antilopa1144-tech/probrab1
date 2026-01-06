import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/projects_list_body.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_card.dart';

void main() {
  group('ProjectsListBody', () {
    late List<ProjectV2> testProjects;

    String statusLabel(ProjectStatus status) {
      switch (status) {
        case ProjectStatus.planning:
          return 'Планирование';
        case ProjectStatus.inProgress:
          return 'В работе';
        case ProjectStatus.completed:
          return 'Завершён';
        case ProjectStatus.onHold:
          return 'Приостановлен';
        case ProjectStatus.cancelled:
          return 'Отменён';
      }
    }

    IconData statusIcon(ProjectStatus status) {
      switch (status) {
        case ProjectStatus.planning:
          return Icons.pending_outlined;
        case ProjectStatus.inProgress:
          return Icons.construction_rounded;
        case ProjectStatus.completed:
          return Icons.check_circle_outline;
        case ProjectStatus.onHold:
          return Icons.pause_circle_outline;
        case ProjectStatus.cancelled:
          return Icons.cancel_outlined;
      }
    }

    Color statusColor(ProjectStatus status) {
      switch (status) {
        case ProjectStatus.planning:
          return Colors.blue;
        case ProjectStatus.inProgress:
          return Colors.orange;
        case ProjectStatus.completed:
          return Colors.green;
        case ProjectStatus.onHold:
          return Colors.grey;
        case ProjectStatus.cancelled:
          return Colors.red;
      }
    }

    setUp(() {
      testProjects = [
        ProjectV2()
          ..id = 1
          ..name = 'Project 1'
          ..createdAt = DateTime(2024, 1, 15)
          ..updatedAt = DateTime(2024, 1, 20)
          ..isFavorite = false
          ..status = ProjectStatus.planning,
        ProjectV2()
          ..id = 2
          ..name = 'Project 2'
          ..createdAt = DateTime(2024, 1, 16)
          ..updatedAt = DateTime(2024, 1, 21)
          ..isFavorite = true
          ..status = ProjectStatus.inProgress,
      ];
    });

    testWidgets('renders list of projects', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: testProjects,
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: false,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ProjectCard), findsNWidgets(2));
      expect(find.text('Project 1'), findsOneWidget);
      expect(find.text('Project 2'), findsOneWidget);
    });

    testWidgets('shows favorites filter chip when showFavoritesOnly is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: [testProjects[1]],
              showFavoritesOnly: true,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: true,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Только избранные'), findsOneWidget);
    });

    testWidgets('shows status filter chip when filterStatus is set',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: [testProjects[0]],
              showFavoritesOnly: false,
              filterStatus: ProjectStatus.planning,
              searchQuery: '',
              hasActiveFilters: true,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Планирование'), findsWidgets);
    });

    testWidgets('shows search filter chip when searchQuery is not empty',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: [testProjects[0]],
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: 'test query',
              hasActiveFilters: true,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Поиск: "test query"'), findsOneWidget);
    });

    testWidgets('shows filtered count when hasActiveFilters is true',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: [testProjects[0]],
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: 'test',
              hasActiveFilters: true,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Найдено: 1 из 2'), findsOneWidget);
    });

    testWidgets('hides filter info when hasActiveFilters is false',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: testProjects,
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: false,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Только избранные'), findsNothing);
      expect(find.textContaining('Найдено:'), findsNothing);
    });

    testWidgets('calls onClearFavorites when favorites chip is deleted',
        (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: [testProjects[1]],
              showFavoritesOnly: true,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: true,
              onClearFavorites: () => cleared = true,
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      // Find the delete icon on the chip
      final chipFinder = find.widgetWithText(Chip, 'Только избранные');
      final chipWidget = tester.widget<Chip>(chipFinder);
      expect(chipWidget.onDeleted, isNotNull);

      // Tap the delete icon
      await tester.tap(find.descendant(
        of: chipFinder,
        matching: find.byIcon(Icons.cancel),
      ));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
    });

    testWidgets('calls onClearSearch when search chip is deleted',
        (tester) async {
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: [testProjects[0]],
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: 'test',
              hasActiveFilters: true,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () => cleared = true,
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      // Find the delete icon on the search chip
      final chipFinder = find.widgetWithText(Chip, 'Поиск: "test"');
      await tester.tap(find.descendant(
        of: chipFinder,
        matching: find.byIcon(Icons.cancel),
      ));
      await tester.pumpAndSettle();

      expect(cleared, isTrue);
    });

    testWidgets('calls onOpenProject when project card is tapped',
        (tester) async {
      ProjectV2? openedProject;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: testProjects,
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: false,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (p) => openedProject = p,
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('Project 1'));
      await tester.pumpAndSettle();

      expect(openedProject?.name, 'Project 1');
    });

    testWidgets('calls onDeleteProject when delete is pressed', (tester) async {
      ProjectV2? deletedProject;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: testProjects,
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: false,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (p) => deletedProject = p,
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
      await tester.pumpAndSettle();

      expect(deletedProject?.name, 'Project 1');
    });

    testWidgets('calls onToggleFavorite when star is pressed', (tester) async {
      ProjectV2? toggledProject;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: testProjects,
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: false,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (p) => toggledProject = p,
            ),
          ),
        ),
      );

      // Tap star_border for unfavorited project
      await tester.tap(find.byIcon(Icons.star_border).first);
      await tester.pumpAndSettle();

      expect(toggledProject?.name, 'Project 1');
    });

    testWidgets('renders empty list when filtered is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: const [],
              showFavoritesOnly: false,
              filterStatus: null,
              searchQuery: '',
              hasActiveFilters: false,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(ProjectCard), findsNothing);
    });

    testWidgets('shows multiple filter chips simultaneously', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProjectsListBody(
              projects: testProjects,
              filtered: [testProjects[1]],
              showFavoritesOnly: true,
              filterStatus: ProjectStatus.inProgress,
              searchQuery: 'query',
              hasActiveFilters: true,
              onClearFavorites: () {},
              onClearStatus: () {},
              onClearSearch: () {},
              statusLabel: statusLabel,
              statusIcon: statusIcon,
              statusColor: statusColor,
              onOpenProject: (_) {},
              onDeleteProject: (_) {},
              onToggleFavorite: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Только избранные'), findsOneWidget);
      expect(find.text('В работе'), findsWidgets); // Status chip + card
      expect(find.text('Поиск: "query"'), findsOneWidget);
    });
  });
}
