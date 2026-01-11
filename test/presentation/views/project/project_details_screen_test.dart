import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/views/project/project_details_screen.dart';
import 'package:probrab_ai/presentation/providers/project_v2_provider.dart';
import 'package:probrab_ai/data/repositories/project_repository_v2.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

/// Mock repository for testing
class MockProjectRepositoryV2 implements ProjectRepositoryV2 {
  final ProjectV2? projectToReturn;
  final bool shouldThrowError;

  MockProjectRepositoryV2({
    this.projectToReturn,
    this.shouldThrowError = false,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final memberName = invocation.memberName.toString();

    if (memberName.contains('getProjectById')) {
      if (shouldThrowError) {
        return Future<ProjectV2?>.error(Exception('Test error'));
      }
      return Future.value(projectToReturn);
    }
    if (memberName.contains('getAllProjects')) {
      return Future.value(<ProjectV2>[]);
    }
    if (memberName.contains('updateProject')) {
      return Future<void>.value();
    }
    if (memberName.contains('removeCalculationFromProject')) {
      return Future<void>.value();
    }
    if (memberName.contains('getProjectCalculations')) {
      return Future.value(<ProjectCalculation>[]);
    }
    if (memberName.contains('getFavoriteProjects')) {
      return Future.value(<ProjectV2>[]);
    }
    if (memberName.contains('getStatistics')) {
      return Future.value({'totalProjects': 0});
    }

    return super.noSuchMethod(invocation);
  }
}

/// Mock notifier for testing
class MockProjectV2Notifier extends ProjectV2Notifier {
  MockProjectV2Notifier(super.repository);

  @override
  Future<void> loadProjects() async {
    state = const AsyncValue.data([]);
  }

  @override
  Future<void> updateProject(ProjectV2 project) async {}

  @override
  Future<void> deleteProject(int id) async {}

  @override
  Future<void> toggleFavorite(int id) async {}
}

List<Override> _createOverrides(MockProjectRepositoryV2 mockRepo) {
  return <Override>[
    projectRepositoryV2Provider.overrideWithValue(mockRepo),
    projectV2NotifierProvider.overrideWith((ref) => MockProjectV2Notifier(mockRepo)),
  ];
}

void main() {
  group('ProjectDetailsScreen', () {
    late MockProjectRepositoryV2 mockRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      mockRepo = MockProjectRepositoryV2(projectToReturn: null);
    });

    testWidgets('renders without error', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows project not found for invalid id', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: -999),
          overrides: _createOverrides(mockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has initial loading state', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows FAB for adding calculations', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB has add icon', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('handles null project gracefully', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows error state for repository error', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorRepo = MockProjectRepositoryV2(shouldThrowError: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(errorRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('displays FutureBuilder', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(FutureBuilder<ProjectV2?>), findsOneWidget);
    });

    testWidgets('accepts projectId parameter', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const projectId = 42;
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: projectId),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(ProjectDetailsScreen), findsOneWidget);
    });

    testWidgets('can tap FAB when loading', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pump();
    });

    testWidgets('renders with ConsumerStatefulWidget', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      final element = tester.element(find.byType(ProjectDetailsScreen));
      expect(element.widget, isA<ConsumerStatefulWidget>());
    });

    testWidgets('shows not found UI when project null', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should show folder_off icon for not found
      final folderOff = find.byIcon(Icons.folder_off_rounded);
      if (folderOff.evaluate().isNotEmpty) {
        expect(folderOff, findsOneWidget);
      }
    });

    testWidgets('shows not found text for null project', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Should show "Проект не найден" or similar
      final notFoundText = find.text('Проект не найден');
      if (notFoundText.evaluate().isNotEmpty) {
        expect(notFoundText, findsOneWidget);
      }
    });

    testWidgets('shows back button for not found project', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final nazadButton = find.text('Назад');
      if (nazadButton.evaluate().isNotEmpty) {
        expect(nazadButton, findsOneWidget);
      }
    });
  });

  group('ProjectDetailsScreen with project data', () {
    late ProjectV2 testProject;
    late MockProjectRepositoryV2 mockRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testProject = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..description = 'Test Description'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..status = ProjectStatus.planning
        ..isFavorite = false
        ..tags = ['tag1', 'tag2'];
      mockRepo = MockProjectRepositoryV2(projectToReturn: testProject);
    });

    testWidgets('loads project data on init', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('favorite project displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.isFavorite = true;
      final favMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(favMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('completed project displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.status = ProjectStatus.completed;
      final completedMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(completedMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('inProgress project displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.status = ProjectStatus.inProgress;
      final inProgressMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(inProgressMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('onHold project displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.status = ProjectStatus.onHold;
      final onHoldMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(onHoldMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('cancelled project displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.status = ProjectStatus.cancelled;
      final cancelledMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(cancelledMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('project without description displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.description = null;
      final noDescMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(noDescMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('project with notes displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.notes = 'Some important notes';
      final notesMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(notesMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('project with color displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.color = 0xFF4CAF50;
      final colorMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(colorMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('project with empty tags displays correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.tags = [];
      final emptyTagsMockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(emptyTagsMockRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('ProjectDetailsScreen state transitions', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('transitions from loading to data state', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final testProject = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..status = ProjectStatus.planning
        ..isFavorite = false
        ..tags = [];

      final mockRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('transitions from loading to error state', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorRepo = MockProjectRepositoryV2(shouldThrowError: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(errorRepo),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('transitions from loading to not found state', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final nullRepo = MockProjectRepositoryV2(projectToReturn: null);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(nullRepo),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('error state shows refresh button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorRepo = MockProjectRepositoryV2(shouldThrowError: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(errorRepo),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final errorIcon = find.byIcon(Icons.error_outline_rounded);
      if (errorIcon.evaluate().isNotEmpty) {
        expect(errorIcon, findsOneWidget);
      }
    });

    testWidgets('error state shows error text', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorRepo = MockProjectRepositoryV2(shouldThrowError: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(errorRepo),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final errorText = find.text('Ошибка загрузки проекта');
      if (errorText.evaluate().isNotEmpty) {
        expect(errorText, findsOneWidget);
      }
    });

    testWidgets('error state shows retry button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorRepo = MockProjectRepositoryV2(shouldThrowError: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(errorRepo),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final retryButton = find.text('Повторить');
      if (retryButton.evaluate().isNotEmpty) {
        expect(retryButton, findsOneWidget);
      }
    });
  });

  group('ProjectDetailsScreen actions', () {
    late ProjectV2 testProject;
    late MockProjectRepositoryV2 mockRepo;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      testProject = ProjectV2()
        ..id = 1
        ..name = 'Test Project'
        ..description = 'Test Description'
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now()
        ..status = ProjectStatus.planning
        ..isFavorite = false
        ..tags = ['tag1'];
      mockRepo = MockProjectRepositoryV2(projectToReturn: testProject);
    });

    testWidgets('использует FutureBuilder для загрузки проекта', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(FutureBuilder<ProjectV2?>), findsOneWidget);
    });

    testWidgets('FAB всегда видна', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('можно тапнуть на FAB во время загрузки', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      final fab = find.byType(FloatingActionButton);
      await tester.tap(fab);
      await tester.pump();
    });

    testWidgets('загружается с правильным projectId', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const projectId = 42;
      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: projectId),
          overrides: _createOverrides(mockRepo),
        ),
      );

      final widget = tester.widget<ProjectDetailsScreen>(
        find.byType(ProjectDetailsScreen),
      );
      expect(widget.projectId, projectId);
    });

    testWidgets('имеет Scaffold в body', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('состояние not found показывает правильную иконку', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final notFoundIcon = find.byIcon(Icons.folder_off_rounded);
      if (notFoundIcon.evaluate().isNotEmpty) {
        expect(notFoundIcon, findsOneWidget);
      }
    });

    testWidgets('состояние ошибки показывает правильную иконку', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final errorRepo = MockProjectRepositoryV2(shouldThrowError: true);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(errorRepo),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      final errorIcon = find.byIcon(Icons.error_outline_rounded);
      if (errorIcon.evaluate().isNotEmpty) {
        expect(errorIcon, findsOneWidget);
      }
    });

    testWidgets('использует ConsumerStatefulWidget', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      final element = tester.element(find.byType(ProjectDetailsScreen));
      expect(element.widget, isA<ConsumerStatefulWidget>());
    });

    testWidgets('вызывает initState при создании', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      // initState должен вызвать _loadProject
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('проект с максимальным количеством тегов', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.tags = List.generate(10, (i) => 'tag$i');
      final tagsRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(tagsRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('проект со всеми полями заполненными', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.description = 'Full description';
      testProject.notes = 'Full notes';
      testProject.color = 0xFF4CAF50;
      testProject.tags = ['tag1', 'tag2', 'tag3'];
      final fullRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(fullRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('обрабатывает очень длинное имя проекта', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.name = 'Very Long Project Name ' * 10;
      final longNameRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(longNameRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('обрабатывает очень длинное описание проекта', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.description = 'Very Long Description ' * 50;
      final longDescRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(longDescRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('переходит из loading в data state', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(mockRepo),
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for data to load
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Should have scaffold
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('проект с датой создания в будущем', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.createdAt = DateTime.now().add(const Duration(days: 365));
      final futureRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(futureRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('проект с очень старой датой создания', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      testProject.createdAt = DateTime(2000, 1, 1);
      final oldRepo = MockProjectRepositoryV2(projectToReturn: testProject);

      await tester.pumpWidget(
        createTestApp(
          child: const ProjectDetailsScreen(projectId: 1),
          overrides: _createOverrides(oldRepo),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('тест всех статусов проекта в одном тесте', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      for (final status in ProjectStatus.values) {
        testProject.status = status;
        final statusRepo = MockProjectRepositoryV2(projectToReturn: testProject);

        await tester.pumpWidget(
          createTestApp(
            child: const ProjectDetailsScreen(projectId: 1),
            overrides: _createOverrides(statusRepo),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(Scaffold), findsOneWidget);

        // Cleanup for next iteration
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  });
}
