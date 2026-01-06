import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/project.dart';
import 'package:probrab_ai/domain/entities/project.dart';

void main() {
  group('ProjectModel', () {
    test('creates empty instance', () {
      final model = ProjectModel();
      expect(model.id, isNotNull);
    });

    test('can set all fields', () {
      final now = DateTime.now();
      final startDate = DateTime(2024, 1, 1);
      final completionDate = DateTime(2024, 12, 31);

      final model = ProjectModel()
        ..projectId = 'proj-123'
        ..name = 'House Renovation'
        ..description = 'Full renovation project'
        ..objectType = 'house'
        ..createdAt = now
        ..startDate = startDate
        ..completionDate = completionDate
        ..totalBudget = 1000000.0
        ..spentAmount = 250000.0
        ..calculationIdsJson = '["calc1", "calc2", "calc3"]'
        ..metadataJson = '{"floor_count": 2}';

      expect(model.projectId, 'proj-123');
      expect(model.name, 'House Renovation');
      expect(model.description, 'Full renovation project');
      expect(model.objectType, 'house');
      expect(model.createdAt, now);
      expect(model.startDate, startDate);
      expect(model.completionDate, completionDate);
      expect(model.totalBudget, 1000000.0);
      expect(model.spentAmount, 250000.0);
      expect(model.calculationIdsJson, contains('calc1'));
      expect(model.metadataJson, contains('floor_count'));
    });

    group('fromDomain', () {
      test('creates ProjectModel from Project', () {
        final project = Project(
          id: 'proj-abc',
          name: 'Test Project',
          description: 'Test description',
          objectType: 'apartment',
          calculationIds: ['calc-1', 'calc-2'],
          createdAt: DateTime(2024, 6, 15),
          startDate: DateTime(2024, 7, 1),
          completionDate: null,
          totalBudget: 500000.0,
          spentAmount: 100000.0,
          metadata: {'rooms': 3, 'area': 75.0},
        );

        final model = ProjectModel.fromDomain(project);

        expect(model.projectId, 'proj-abc');
        expect(model.name, 'Test Project');
        expect(model.description, 'Test description');
        expect(model.objectType, 'apartment');
        expect(model.createdAt, DateTime(2024, 6, 15));
        expect(model.startDate, DateTime(2024, 7, 1));
        expect(model.completionDate, isNull);
        expect(model.totalBudget, 500000.0);
        expect(model.spentAmount, 100000.0);
        expect(model.calculationIdsJson, contains('calc-1'));
        expect(model.calculationIdsJson, contains('calc-2'));
        expect(model.metadataJson, contains('rooms'));
        expect(model.metadataJson, contains('area'));
      });

      test('handles empty calculationIds', () {
        final project = Project(
          id: 'proj-empty',
          name: 'Empty Project',
          description: 'No calculations',
          objectType: 'garage',
          calculationIds: [],
          createdAt: DateTime.now(),
          metadata: {},
        );

        final model = ProjectModel.fromDomain(project);

        expect(model.calculationIdsJson, '[]');
        expect(model.metadataJson, '{}');
      });

      test('handles empty metadata', () {
        final project = Project(
          id: 'proj-minimal',
          name: 'Minimal',
          description: '',
          objectType: 'other',
          createdAt: DateTime.now(),
        );

        final model = ProjectModel.fromDomain(project);

        expect(model.metadataJson, '{}');
        expect(model.calculationIdsJson, '[]');
      });
    });

    group('toDomain', () {
      test('converts to Project domain model', () {
        final model = ProjectModel()
          ..projectId = 'proj-xyz'
          ..name = 'Domain Test'
          ..description = 'Test conversion'
          ..objectType = 'house'
          ..createdAt = DateTime(2024, 3, 20)
          ..startDate = DateTime(2024, 4, 1)
          ..completionDate = DateTime(2024, 9, 30)
          ..totalBudget = 2000000.0
          ..spentAmount = 500000.0
          ..calculationIdsJson = '["id1", "id2", "id3"]'
          ..metadataJson = '{"priority": "high"}';

        final project = model.toDomain();

        expect(project.id, 'proj-xyz');
        expect(project.name, 'Domain Test');
        expect(project.description, 'Test conversion');
        expect(project.objectType, 'house');
        expect(project.createdAt, DateTime(2024, 3, 20));
        expect(project.startDate, DateTime(2024, 4, 1));
        expect(project.completionDate, DateTime(2024, 9, 30));
        expect(project.totalBudget, 2000000.0);
        expect(project.spentAmount, 500000.0);
        expect(project.calculationIds, ['id1', 'id2', 'id3']);
        expect(project.metadata['priority'], 'high');
      });

      test('handles empty lists in JSON', () {
        final model = ProjectModel()
          ..projectId = 'empty-test'
          ..name = 'Empty'
          ..description = ''
          ..objectType = 'apartment'
          ..createdAt = DateTime.now()
          ..totalBudget = 0
          ..spentAmount = 0
          ..calculationIdsJson = '[]'
          ..metadataJson = '{}';

        final project = model.toDomain();

        expect(project.calculationIds, isEmpty);
        expect(project.metadata, isEmpty);
      });

      test('handles null dates', () {
        final model = ProjectModel()
          ..projectId = 'null-dates'
          ..name = 'Null Dates'
          ..description = 'Testing null handling'
          ..objectType = 'garage'
          ..createdAt = DateTime.now()
          ..startDate = null
          ..completionDate = null
          ..totalBudget = 100000.0
          ..spentAmount = 0.0
          ..calculationIdsJson = '[]'
          ..metadataJson = '{}';

        final project = model.toDomain();

        expect(project.startDate, isNull);
        expect(project.completionDate, isNull);
      });
    });

    group('round-trip conversion', () {
      test('Project -> ProjectModel -> Project preserves data', () {
        final original = Project(
          id: 'round-trip',
          name: 'Round Trip Test',
          description: 'Testing data preservation',
          objectType: 'house',
          calculationIds: ['a', 'b', 'c'],
          createdAt: DateTime(2024, 5, 10, 14, 30),
          startDate: DateTime(2024, 6, 1),
          completionDate: DateTime(2024, 12, 1),
          totalBudget: 1500000.0,
          spentAmount: 750000.0,
          metadata: {'status': 'active', 'phase': 2},
        );

        final model = ProjectModel.fromDomain(original);
        final result = model.toDomain();

        expect(result.id, original.id);
        expect(result.name, original.name);
        expect(result.description, original.description);
        expect(result.objectType, original.objectType);
        expect(result.calculationIds, original.calculationIds);
        expect(result.createdAt, original.createdAt);
        expect(result.startDate, original.startDate);
        expect(result.completionDate, original.completionDate);
        expect(result.totalBudget, original.totalBudget);
        expect(result.spentAmount, original.spentAmount);
        expect(result.metadata['status'], original.metadata['status']);
        expect(result.metadata['phase'], original.metadata['phase']);
      });
    });
  });
}
