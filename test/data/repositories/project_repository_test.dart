import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/repositories/project_repository.dart';
import 'package:probrab_ai/domain/entities/project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectRepository repository;

  setUp(() {
    repository = ProjectRepository();
  });

  tearDown(() async {
    // Закрываем базу данных после каждого теста
    await repository.close();
  });

  group('ProjectRepository', () {
    test('saves project correctly', () async {
      final project = Project(
        id: 'test-project-1',
        name: 'Test Project',
        description: 'Test Description',
        objectType: 'дом',
        createdAt: DateTime.now(),
        totalBudget: 100000,
        spentAmount: 50000,
      );

      await repository.saveProject(project);

      final saved = await repository.getProject('test-project-1');
      expect(saved, isNotNull);
      expect(saved!.name, equals('Test Project'));
      expect(saved.description, equals('Test Description'));
      expect(saved.totalBudget, equals(100000));
    });

    test('gets all projects', () async {
      final project1 = Project(
        id: 'project-1',
        name: 'Project 1',
        description: 'Description 1',
        objectType: 'квартира',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      final project2 = Project(
        id: 'project-2',
        name: 'Project 2',
        description: 'Description 2',
        objectType: 'дом',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await repository.saveProject(project1);
      await repository.saveProject(project2);

      final allProjects = await repository.getAllProjects();
      expect(allProjects.length, equals(2));
      // Должны быть отсортированы по дате создания (новые первыми)
      expect(allProjects.first.name, equals('Project 2'));
    });

    test('updates existing project', () async {
      final project = Project(
        id: 'update-test',
        name: 'Original Name',
        description: 'Original Description',
        objectType: 'дом',
        createdAt: DateTime.now(),
        totalBudget: 50000,
      );

      await repository.saveProject(project);

      final updated = Project(
        id: 'update-test',
        name: 'Updated Name',
        description: 'Updated Description',
        objectType: 'дом',
        createdAt: project.createdAt,
        totalBudget: 75000,
      );

      await repository.updateProject(updated);

      final saved = await repository.getProject('update-test');
      expect(saved, isNotNull);
      expect(saved!.name, equals('Updated Name'));
      expect(saved.description, equals('Updated Description'));
      expect(saved.totalBudget, equals(75000));
    });

    test('deletes project correctly', () async {
      final project = Project(
        id: 'delete-test',
        name: 'To Delete',
        description: 'Will be deleted',
        objectType: 'гараж',
        createdAt: DateTime.now(),
      );

      await repository.saveProject(project);
      expect(await repository.getProject('delete-test'), isNotNull);

      await repository.deleteProject('delete-test');

      expect(await repository.getProject('delete-test'), isNull);
    });

    test('handles non-existent project deletion gracefully', () async {
      // Не должно выбрасывать исключение
      await repository.deleteProject('non-existent-id');
    });

    test('returns null for non-existent project', () async {
      final project = await repository.getProject('non-existent');
      expect(project, isNull);
    });

    test('preserves calculationIds and metadata', () async {
      final project = Project(
        id: 'metadata-test',
        name: 'Metadata Test',
        description: 'Test',
        objectType: 'дом',
        createdAt: DateTime.now(),
        calculationIds: ['calc-1', 'calc-2', 'calc-3'],
        metadata: {'key1': 'value1', 'key2': 42},
      );

      await repository.saveProject(project);

      final saved = await repository.getProject('metadata-test');
      expect(saved, isNotNull);
      expect(saved!.calculationIds.length, equals(3));
      expect(saved.calculationIds, contains('calc-1'));
      expect(saved.metadata['key1'], equals('value1'));
      expect(saved.metadata['key2'], equals(42));
    });

    test('handles dates correctly', () async {
      final now = DateTime.now();
      final startDate = now.subtract(const Duration(days: 30));
      final completionDate = now.add(const Duration(days: 60));

      final project = Project(
        id: 'dates-test',
        name: 'Dates Test',
        description: 'Test',
        objectType: 'дом',
        createdAt: now,
        startDate: startDate,
        completionDate: completionDate,
      );

      await repository.saveProject(project);

      final saved = await repository.getProject('dates-test');
      expect(saved, isNotNull);
      expect(saved!.startDate, equals(startDate));
      expect(saved.completionDate, equals(completionDate));
    });
  });
}
