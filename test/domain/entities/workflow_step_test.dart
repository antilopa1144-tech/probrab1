import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/workflow_step.dart';

void main() {
  group('WorkflowStep', () {
    test('creates WorkflowStep with all fields', () {
      final step = WorkflowStep(
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
      final step = WorkflowStep(
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
  });
}
