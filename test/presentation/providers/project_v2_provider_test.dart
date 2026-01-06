import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/providers/project_v2_provider.dart';
import 'package:probrab_ai/data/repositories/project_repository_v2.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';

/// Mock repository для тестирования без Isar
class MockProjectRepositoryV2 implements ProjectRepositoryV2 {
  final List<ProjectV2> _projects = [];
  final Map<int, List<ProjectCalculation>> _calculations = {};
  bool shouldThrow = false;
  int _nextId = 1;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ProjectV2>> getAllProjects() async {
    if (shouldThrow) throw Exception('Test error');
    return List.from(_projects);
  }

  @override
  Future<List<ProjectV2>> getFavoriteProjects() async {
    if (shouldThrow) throw Exception('Test error');
    return _projects.where((p) => p.isFavorite).toList();
  }

  @override
  Future<ProjectV2?> getProjectById(int id) async {
    if (shouldThrow) throw Exception('Test error');
    try {
      return _projects.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProjectCalculation>> getProjectCalculations(int projectId) async {
    if (shouldThrow) throw Exception('Test error');
    return _calculations[projectId] ?? [];
  }

  @override
  Future<ProjectStatistics> getStatistics() async {
    if (shouldThrow) throw Exception('Test error');
    return ProjectStatistics(
      total: _projects.length,
      favorites: _projects.where((p) => p.isFavorite).length,
      planning:
          _projects.where((p) => p.status == ProjectStatus.planning).length,
      inProgress:
          _projects.where((p) => p.status == ProjectStatus.inProgress).length,
      completed:
          _projects.where((p) => p.status == ProjectStatus.completed).length,
    );
  }

  @override
  Future<int> createProject(ProjectV2 project) async {
    if (shouldThrow) throw Exception('Test error');
    project.id = _nextId++;
    _projects.add(project);
    return project.id;
  }

  @override
  Future<void> updateProject(ProjectV2 project) async {
    if (shouldThrow) throw Exception('Test error');
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
      _projects[index] = project;
    }
  }

  @override
  Future<void> deleteProject(int id) async {
    if (shouldThrow) throw Exception('Test error');
    _projects.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> toggleFavorite(int id) async {
    if (shouldThrow) throw Exception('Test error');
    final index = _projects.indexWhere((p) => p.id == id);
    if (index >= 0) {
      _projects[index].isFavorite = !_projects[index].isFavorite;
    }
  }

  void addProject(ProjectV2 project) {
    if (project.id == 0) {
      project.id = _nextId++;
    }
    _projects.add(project);
  }

  void addCalculation(int projectId, ProjectCalculation calculation) {
    _calculations.putIfAbsent(projectId, () => []);
    _calculations[projectId]!.add(calculation);
  }

  void clear() {
    _projects.clear();
    _calculations.clear();
    _nextId = 1;
  }
}

ProjectV2 createTestProject({
  int id = 0,
  String name = 'Test Project',
  String? description,
  ProjectStatus status = ProjectStatus.planning,
  bool isFavorite = false,
}) {
  final project = ProjectV2()
    ..id = id
    ..name = name
    ..description = description
    ..status = status
    ..isFavorite = isFavorite;
  return project;
}

ProjectCalculation createTestCalculation({
  int id = 0,
  String calculatorId = 'foundation',
  String name = 'Test Calculation',
  double? materialCost,
  double? laborCost,
}) {
  final calculation = ProjectCalculation()
    ..id = id
    ..calculatorId = calculatorId
    ..name = name
    ..materialCost = materialCost
    ..laborCost = laborCost;
  return calculation;
}

void main() {
  group('ProjectV2Provider', () {
    late MockProjectRepositoryV2 mockRepository;

    setUp(() {
      mockRepository = MockProjectRepositoryV2();
    });

    group('ProjectV2Notifier', () {
      test('loads projects on initialization', () async {
        mockRepository.addProject(createTestProject(name: 'Project 1'));
        mockRepository.addProject(createTestProject(name: 'Project 2'));

        final notifier = ProjectV2Notifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.hasValue, true);
        expect(notifier.state.value!.length, 2);
      });

      test('createProject adds project and reloads', () async {
        final notifier = ProjectV2Notifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.length, 0);

        final newProject = createTestProject(name: 'New Project');
        final id = await notifier.createProject(newProject);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(id, isNotNull);
        expect(notifier.state.value!.length, 1);
        expect(notifier.state.value!.first.name, 'New Project');
      });

      test('updateProject updates existing project', () async {
        mockRepository.addProject(createTestProject(id: 1, name: 'Original'));

        final notifier = ProjectV2Notifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        final updated = createTestProject(id: 1, name: 'Updated');
        await notifier.updateProject(updated);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.first.name, 'Updated');
      });

      test('deleteProject removes project', () async {
        mockRepository.addProject(createTestProject(id: 1, name: 'Project 1'));
        mockRepository.addProject(createTestProject(id: 2, name: 'Project 2'));

        final notifier = ProjectV2Notifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.length, 2);

        await notifier.deleteProject(1);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.length, 1);
        expect(notifier.state.value!.first.id, 2);
      });

      test('toggleFavorite toggles favorite status', () async {
        mockRepository.addProject(createTestProject(
          id: 1,
          name: 'Project',
          isFavorite: false,
        ));

        final notifier = ProjectV2Notifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.first.isFavorite, false);

        await notifier.toggleFavorite(1);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.value!.first.isFavorite, true);
      });

      test('handles error gracefully', () async {
        mockRepository.shouldThrow = true;

        final notifier = ProjectV2Notifier(mockRepository);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifier.state.hasError, true);
      });
    });

    group('allProjectsProvider', () {
      test('returns all projects', () async {
        mockRepository.addProject(createTestProject(id: 1));
        mockRepository.addProject(createTestProject(id: 2));

        final container = ProviderContainer(
          overrides: [
            projectRepositoryV2Provider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final projects = await container.read(allProjectsProvider.future);

        expect(projects.length, 2);
      });
    });

    group('favoriteProjectsProvider', () {
      test('returns only favorite projects', () async {
        mockRepository.addProject(createTestProject(id: 1, isFavorite: true));
        mockRepository.addProject(createTestProject(id: 2, isFavorite: false));
        mockRepository.addProject(createTestProject(id: 3, isFavorite: true));

        final container = ProviderContainer(
          overrides: [
            projectRepositoryV2Provider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final favorites =
            await container.read(favoriteProjectsProvider.future);

        expect(favorites.length, 2);
        expect(favorites.every((p) => p.isFavorite), true);
      });
    });

    group('projectByIdProvider', () {
      test('returns project by id', () async {
        mockRepository.addProject(createTestProject(id: 1, name: 'Project 1'));
        mockRepository.addProject(createTestProject(id: 2, name: 'Project 2'));

        final container = ProviderContainer(
          overrides: [
            projectRepositoryV2Provider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final project = await container.read(projectByIdProvider(2).future);

        expect(project, isNotNull);
        expect(project!.name, 'Project 2');
      });

      test('returns null for non-existent id', () async {
        mockRepository.addProject(createTestProject(id: 1));

        final container = ProviderContainer(
          overrides: [
            projectRepositoryV2Provider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final project = await container.read(projectByIdProvider(999).future);

        expect(project, isNull);
      });
    });

    group('projectCalculationsProvider', () {
      test('returns calculations for project', () async {
        mockRepository.addProject(createTestProject(id: 1));
        mockRepository.addCalculation(
          1,
          createTestCalculation(
            id: 1,
            calculatorId: 'foundation',
            name: 'Фундамент',
            materialCost: 100000,
          ),
        );

        final container = ProviderContainer(
          overrides: [
            projectRepositoryV2Provider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final calculations = await container.read(
          projectCalculationsProvider(1).future,
        );

        expect(calculations.length, 1);
        expect(calculations.first.calculatorId, 'foundation');
      });

      test('returns empty list for project without calculations', () async {
        mockRepository.addProject(createTestProject(id: 1));

        final container = ProviderContainer(
          overrides: [
            projectRepositoryV2Provider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final calculations = await container.read(
          projectCalculationsProvider(1).future,
        );

        expect(calculations, isEmpty);
      });
    });

    group('projectStatisticsProvider', () {
      test('returns correct statistics', () async {
        mockRepository.addProject(createTestProject(
          id: 1,
          status: ProjectStatus.planning,
          isFavorite: true,
        ));
        mockRepository.addProject(createTestProject(
          id: 2,
          status: ProjectStatus.inProgress,
          isFavorite: false,
        ));
        mockRepository.addProject(createTestProject(
          id: 3,
          status: ProjectStatus.completed,
          isFavorite: true,
        ));

        final container = ProviderContainer(
          overrides: [
            projectRepositoryV2Provider.overrideWithValue(mockRepository),
          ],
        );
        addTearDown(container.dispose);

        final stats = await container.read(projectStatisticsProvider.future);

        expect(stats.total, 3);
        expect(stats.favorites, 2);
        expect(stats.planning, 1);
        expect(stats.inProgress, 1);
        expect(stats.completed, 1);
      });
    });
  });
}
