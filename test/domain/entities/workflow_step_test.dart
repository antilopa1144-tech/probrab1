import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/workflow_step.dart';

void main() {
  group('WorkflowStep', () {
    test('creates WorkflowStep with all fields', () {
      const step = WorkflowStep(
        id: 'step-1',
        title: 'Foundation',
        description: 'Pour foundation',
        category: 'Фундамент',
        order: 1,
        prerequisites: ['prep'],
        estimatedDays: 7,
        requiredMaterials: ['Бетон', 'Арматура'],
        requiredTools: ['Бетономешалка'],
        checklist: ['Prepare site', 'Pour concrete'],
        isCritical: true,
      );

      expect(step.id, equals('step-1'));
      expect(step.title, equals('Foundation'));
      expect(step.order, equals(1));
      expect(step.isCritical, isTrue);
      expect(step.prerequisites.length, equals(1));
      expect(step.requiredMaterials.length, equals(2));
    });

    test('creates WorkflowStep with defaults', () {
      const step = WorkflowStep(
        id: 'step-2',
        title: 'Walls',
        description: 'Build walls',
        category: 'Стены',
        order: 2,
      );

      expect(step.prerequisites, isEmpty);
      expect(step.estimatedDays, equals(1));
      expect(step.requiredMaterials, isEmpty);
      expect(step.isCritical, isFalse);
    });
  });

  group('WorkflowPlan', () {
    test('creates WorkflowPlan with all fields', () {
      final steps = [
        const WorkflowStep(
          id: 'step-1',
          title: 'Step 1',
          description: 'First step',
          category: 'Test',
          order: 1,
          estimatedDays: 5,
        ),
        const WorkflowStep(
          id: 'step-2',
          title: 'Step 2',
          description: 'Second step',
          category: 'Test',
          order: 2,
          estimatedDays: 3,
        ),
      ];

      final plan = WorkflowPlan(
        id: 'plan-1',
        name: 'Test Plan',
        steps: steps,
        createdAt: DateTime(2024, 1, 1),
        startDate: DateTime(2024, 1, 5),
      );

      expect(plan.id, equals('plan-1'));
      expect(plan.steps.length, equals(2));
      expect(plan.startDate, equals(DateTime(2024, 1, 5)));
    });

    test('totalDays returns 0 for empty plan', () {
      final plan = WorkflowPlan(
        id: 'empty',
        name: 'Empty Plan',
        steps: [],
        createdAt: DateTime.now(),
      );

      expect(plan.totalDays, equals(0));
    });

    test('totalDays calculates critical path correctly', () {
      final steps = [
        const WorkflowStep(
          id: 'step-1',
          title: 'Step 1',
          description: 'First',
          category: 'Test',
          order: 1,
          estimatedDays: 5,
          isCritical: true,
        ),
        const WorkflowStep(
          id: 'step-2',
          title: 'Step 2',
          description: 'Second',
          category: 'Test',
          order: 2,
          estimatedDays: 3,
          isCritical: true,
        ),
        const WorkflowStep(
          id: 'step-3',
          title: 'Step 3',
          description: 'Third',
          category: 'Test',
          order: 3,
          estimatedDays: 2,
          isCritical: false,
        ),
      ];

      final plan = WorkflowPlan(
        id: 'plan-1',
        name: 'Test Plan',
        steps: steps,
        createdAt: DateTime.now(),
      );

      // Только критические шаги: 5 + 3 = 8
      expect(plan.totalDays, equals(8));
    });

    test('getAvailableSteps returns steps without prerequisites', () {
      final steps = [
        const WorkflowStep(
          id: 'step-1',
          title: 'Step 1',
          description: 'First',
          category: 'Test',
          order: 1,
        ),
        const WorkflowStep(
          id: 'step-2',
          title: 'Step 2',
          description: 'Second',
          category: 'Test',
          order: 2,
          prerequisites: ['step-1'],
        ),
        const WorkflowStep(
          id: 'step-3',
          title: 'Step 3',
          description: 'Third',
          category: 'Test',
          order: 3,
          prerequisites: ['step-2'],
        ),
      ];

      final plan = WorkflowPlan(
        id: 'plan-1',
        name: 'Test Plan',
        steps: steps,
        createdAt: DateTime.now(),
      );

      // Без выполненных шагов - доступен только step-1
      final available1 = plan.getAvailableSteps([]);
      expect(available1.length, equals(1));
      expect(available1.first.id, equals('step-1'));

      // После step-1 - доступен step-2
      final available2 = plan.getAvailableSteps(['step-1']);
      expect(available2.length, equals(1));
      expect(available2.first.id, equals('step-2'));

      // После step-1 и step-2 - доступен step-3
      final available3 = plan.getAvailableSteps(['step-1', 'step-2']);
      expect(available3.length, equals(1));
      expect(available3.first.id, equals('step-3'));
    });

    test('getAvailableSteps excludes completed steps', () {
      final steps = [
        const WorkflowStep(
          id: 'step-1',
          title: 'Step 1',
          description: 'First',
          category: 'Test',
          order: 1,
        ),
        const WorkflowStep(
          id: 'step-2',
          title: 'Step 2',
          description: 'Second',
          category: 'Test',
          order: 2,
        ),
      ];

      final plan = WorkflowPlan(
        id: 'plan-1',
        name: 'Test Plan',
        steps: steps,
        createdAt: DateTime.now(),
      );

      // Оба шага выполнены - ничего не доступно
      final available = plan.getAvailableSteps(['step-1', 'step-2']);
      expect(available, isEmpty);
    });

    test('getAvailableSteps returns parallel steps', () {
      final steps = [
        const WorkflowStep(
          id: 'foundation',
          title: 'Foundation',
          description: 'Foundation work',
          category: 'Base',
          order: 1,
        ),
        const WorkflowStep(
          id: 'plumbing',
          title: 'Plumbing',
          description: 'Plumbing work',
          category: 'Utilities',
          order: 2,
          prerequisites: ['foundation'],
        ),
        const WorkflowStep(
          id: 'electrical',
          title: 'Electrical',
          description: 'Electrical work',
          category: 'Utilities',
          order: 2,
          prerequisites: ['foundation'],
        ),
      ];

      final plan = WorkflowPlan(
        id: 'plan-1',
        name: 'Test Plan',
        steps: steps,
        createdAt: DateTime.now(),
      );

      // После foundation - доступны оба: plumbing и electrical
      final available = plan.getAvailableSteps(['foundation']);
      expect(available.length, equals(2));
      expect(available.map((s) => s.id), containsAll(['plumbing', 'electrical']));
    });

    test('copyWith creates modified copy', () {
      final original = WorkflowPlan(
        id: 'plan-1',
        name: 'Original',
        steps: const [],
        createdAt: DateTime(2024, 1, 1),
      );

      final modified = original.copyWith(
        name: 'Modified',
        completedSteps: ['step-1'],
      );

      expect(modified.id, equals('plan-1')); // unchanged
      expect(modified.name, equals('Modified'));
      expect(modified.completedSteps, equals(['step-1']));
    });
  });

  group('WorkflowStep JSON serialization', () {
    test('toJson serializes correctly', () {
      const step = WorkflowStep(
        id: 'test',
        title: 'Test Step',
        description: 'Test Description',
        category: 'Test Category',
        order: 1,
        prerequisites: ['prereq1'],
        estimatedDays: 5,
        requiredMaterials: ['Material1'],
        requiredTools: ['Tool1'],
        checklist: ['Check1'],
        isCritical: true,
      );

      final json = step.toJson();

      expect(json['id'], equals('test'));
      expect(json['title'], equals('Test Step'));
      expect(json['description'], equals('Test Description'));
      expect(json['category'], equals('Test Category'));
      expect(json['order'], equals(1));
      expect(json['prerequisites'], equals(['prereq1']));
      expect(json['estimatedDays'], equals(5));
      expect(json['requiredMaterials'], equals(['Material1']));
      expect(json['requiredTools'], equals(['Tool1']));
      expect(json['checklist'], equals(['Check1']));
      expect(json['isCritical'], equals(true));
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'from-json',
        'title': 'From JSON',
        'description': 'Desc',
        'category': 'Cat',
        'order': 2,
        'prerequisites': ['p1', 'p2'],
        'estimatedDays': 3,
        'requiredMaterials': ['m1'],
        'requiredTools': ['t1'],
        'checklist': ['c1', 'c2'],
        'isCritical': true,
      };

      final step = WorkflowStep.fromJson(json);

      expect(step.id, equals('from-json'));
      expect(step.prerequisites.length, equals(2));
      expect(step.estimatedDays, equals(3));
      expect(step.isCritical, isTrue);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'minimal',
        'title': 'Minimal',
        'description': 'Desc',
        'category': 'Cat',
        'order': 1,
      };

      final step = WorkflowStep.fromJson(json);

      expect(step.prerequisites, isEmpty);
      expect(step.estimatedDays, equals(1));
      expect(step.isCritical, isFalse);
    });

    test('toJson and fromJson are inverse operations', () {
      const original = WorkflowStep(
        id: 'round-trip',
        title: 'Round Trip',
        description: 'Round trip test',
        category: 'Testing',
        order: 5,
        prerequisites: ['a', 'b'],
        estimatedDays: 10,
        requiredMaterials: ['m1', 'm2', 'm3'],
        requiredTools: ['t1'],
        checklist: ['c1', 'c2'],
        isCritical: true,
      );

      final restored = WorkflowStep.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.prerequisites, equals(original.prerequisites));
      expect(restored.estimatedDays, equals(original.estimatedDays));
      expect(restored.isCritical, equals(original.isCritical));
    });
  });

  group('WorkflowPlan JSON serialization', () {
    test('toJson serializes correctly', () {
      final plan = WorkflowPlan(
        id: 'plan-json',
        name: 'JSON Plan',
        steps: const [
          WorkflowStep(
            id: 's1',
            title: 'Step 1',
            description: 'Desc',
            category: 'Cat',
            order: 1,
          ),
        ],
        createdAt: DateTime(2024, 6, 15, 10, 30),
        startDate: DateTime(2024, 7, 1),
        completedSteps: const ['s1'],
      );

      final json = plan.toJson();

      expect(json['id'], equals('plan-json'));
      expect(json['name'], equals('JSON Plan'));
      expect(json['steps'], isList);
      expect((json['steps'] as List).length, equals(1));
      expect(json['createdAt'], equals('2024-06-15T10:30:00.000'));
      expect(json['startDate'], equals('2024-07-01T00:00:00.000'));
      expect(json['completedSteps'], equals(['s1']));
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'from-json-plan',
        'name': 'Restored Plan',
        'steps': [
          {
            'id': 's1',
            'title': 'Step',
            'description': 'Desc',
            'category': 'Cat',
            'order': 1,
          }
        ],
        'createdAt': '2024-03-20T14:00:00.000',
        'startDate': '2024-04-01T09:00:00.000',
        'completedSteps': ['s1'],
      };

      final plan = WorkflowPlan.fromJson(json);

      expect(plan.id, equals('from-json-plan'));
      expect(plan.steps.length, equals(1));
      expect(plan.createdAt, equals(DateTime(2024, 3, 20, 14, 0)));
      expect(plan.startDate, equals(DateTime(2024, 4, 1, 9, 0)));
      expect(plan.completedSteps, equals(['s1']));
    });

    test('fromJson handles null startDate', () {
      final json = {
        'id': 'no-start',
        'name': 'No Start Date',
        'steps': <Map<String, dynamic>>[],
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final plan = WorkflowPlan.fromJson(json);

      expect(plan.startDate, isNull);
      expect(plan.completedSteps, isEmpty);
    });

    test('toJson and fromJson are inverse operations', () {
      final original = WorkflowPlan(
        id: 'round-trip-plan',
        name: 'Round Trip Plan',
        steps: const [
          WorkflowStep(
            id: 's1',
            title: 'Step 1',
            description: 'First step',
            category: 'Test',
            order: 1,
            estimatedDays: 5,
            isCritical: true,
          ),
          WorkflowStep(
            id: 's2',
            title: 'Step 2',
            description: 'Second step',
            category: 'Test',
            order: 2,
            prerequisites: ['s1'],
            estimatedDays: 3,
          ),
        ],
        createdAt: DateTime(2024, 5, 10, 12, 0),
        startDate: DateTime(2024, 6, 1),
        completedSteps: const ['s1'],
      );

      final restored = WorkflowPlan.fromJson(original.toJson());

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.steps.length, equals(original.steps.length));
      expect(restored.createdAt, equals(original.createdAt));
      expect(restored.startDate, equals(original.startDate));
      expect(restored.completedSteps, equals(original.completedSteps));
    });
  });
}
