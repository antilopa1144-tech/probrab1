import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:probrab_ai/presentation/providers/workflow_provider.dart';
import 'package:probrab_ai/domain/entities/workflow_step.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('WorkflowNotifier', () {
    test('starts with loading state', () {
      final notifier = WorkflowNotifier();
      expect(notifier.state.isLoading, true);
    });

    test('loads empty list initially', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.hasValue, true);
      final plans = notifier.state.value ?? [];
      expect(plans, isEmpty);
    });

    test('addPlan adds plan to state', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      final plan = WorkflowPlan(
        id: '1',
        name: 'Test Plan',
        steps: [
          const WorkflowStep(
            id: 'step1',
            title: 'Step 1',
            description: 'First step',
            category: 'foundation',
            order: 1,
            estimatedDays: 5,
          ),
        ],
        createdAt: DateTime(2025, 1, 1),
      );

      await notifier.addPlan(plan);

      expect(notifier.state.hasValue, true);
      final plans = notifier.state.value!;
      expect(plans.length, 1);
      expect(plans.first.id, '1');
      expect(plans.first.name, 'Test Plan');
    });

    test('addPlan persists to SharedPreferences', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      final plan = WorkflowPlan(
        id: '1',
        name: 'Persisted Plan',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      );

      await notifier.addPlan(plan);
      await Future.delayed(const Duration(milliseconds: 100));

      // Create new notifier to load from SharedPreferences
      final notifier2 = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier2.state.hasValue, true);
      final plans = notifier2.state.value!;
      expect(plans.length, 1);
      expect(plans.first.name, 'Persisted Plan');
    });

    test('updatePlan updates existing plan', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      final plan = WorkflowPlan(
        id: '1',
        name: 'Original',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      );

      await notifier.addPlan(plan);

      final updated = WorkflowPlan(
        id: '1',
        name: 'Updated',
        steps: [
          const WorkflowStep(
            id: 'step1',
            title: 'New Step',
            description: 'Description',
            category: 'walls',
            order: 1,
            estimatedDays: 3,
          ),
        ],
        createdAt: DateTime(2025, 1, 1),
      );

      await notifier.updatePlan('1', updated);

      expect(notifier.state.hasValue, true);
      final plans = notifier.state.value!;
      expect(plans.length, 1);
      expect(plans.first.name, 'Updated');
      expect(plans.first.steps.length, 1);
    });

    test('updatePlan does not affect other plans', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addPlan(WorkflowPlan(
        id: '1',
        name: 'Plan 1',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      ));

      await notifier.addPlan(WorkflowPlan(
        id: '2',
        name: 'Plan 2',
        steps: [],
        createdAt: DateTime(2025, 1, 2),
      ));

      final updated = WorkflowPlan(
        id: '1',
        name: 'Updated Plan 1',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      );

      await notifier.updatePlan('1', updated);

      expect(notifier.state.hasValue, true);
      final plans = notifier.state.value!;
      expect(plans.length, 2);
      expect(plans[0].name, 'Updated Plan 1');
      expect(plans[1].name, 'Plan 2');
    });

    test('deletePlan removes plan from state', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addPlan(WorkflowPlan(
        id: '1',
        name: 'Plan 1',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      ));

      await notifier.addPlan(WorkflowPlan(
        id: '2',
        name: 'Plan 2',
        steps: [],
        createdAt: DateTime(2025, 1, 2),
      ));

      await notifier.deletePlan('1');

      expect(notifier.state.hasValue, true);
      final plans = notifier.state.value!;
      expect(plans.length, 1);
      expect(plans.first.id, '2');
    });

    test('getPlan returns plan by id', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addPlan(WorkflowPlan(
        id: '1',
        name: 'Plan 1',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      ));

      await notifier.addPlan(WorkflowPlan(
        id: '2',
        name: 'Plan 2',
        steps: [],
        createdAt: DateTime(2025, 1, 2),
      ));

      final plan = notifier.getPlan('2');

      expect(plan, isNotNull);
      expect(plan!.id, '2');
      expect(plan.name, 'Plan 2');
    });

    test('getPlan returns null for non-existent id', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addPlan(WorkflowPlan(
        id: '1',
        name: 'Plan 1',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      ));

      final plan = notifier.getPlan('non-existent');

      expect(plan, isNull);
    });

    test('updateProgress updates completed steps', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      final plan = WorkflowPlan(
        id: '1',
        name: 'Test Plan',
        steps: [
          const WorkflowStep(
            id: 'step1',
            title: 'Step 1',
            description: 'Description',
            category: 'foundation',
            order: 1,
            estimatedDays: 5,
          ),
          const WorkflowStep(
            id: 'step2',
            title: 'Step 2',
            description: 'Description',
            category: 'walls',
            order: 2,
            estimatedDays: 7,
          ),
        ],
        createdAt: DateTime(2025, 1, 1),
      );

      await notifier.addPlan(plan);
      await notifier.updateProgress('1', {'step1'});

      expect(notifier.state.hasValue, true);
      final plans = notifier.state.value!;
      expect(plans.first.completedSteps, ['step1']);
    });

    test('refresh reloads plans from SharedPreferences', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      await notifier.addPlan(WorkflowPlan(
        id: '1',
        name: 'Plan 1',
        steps: [],
        createdAt: DateTime(2025, 1, 1),
      ));

      await notifier.refresh();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier.state.hasValue, true);
      final plans = notifier.state.value!;
      expect(plans.length, 1);
      expect(plans.first.name, 'Plan 1');
    });

    test('handles complex workflow plan with multiple steps', () async {
      final notifier = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      final plan = WorkflowPlan(
        id: 'complex-plan',
        name: 'Complex Plan',
        steps: [
          const WorkflowStep(
            id: 'foundation',
            title: 'Foundation',
            description: 'Build foundation',
            category: 'foundation',
            order: 1,
            estimatedDays: 7,
            requiredMaterials: ['concrete', 'rebar'],
            requiredTools: ['mixer', 'vibrator'],
            checklist: ['prepare site', 'pour concrete'],
            isCritical: true,
          ),
          const WorkflowStep(
            id: 'walls',
            title: 'Walls',
            description: 'Build walls',
            category: 'walls',
            order: 2,
            prerequisites: ['foundation'],
            estimatedDays: 14,
            requiredMaterials: ['blocks', 'mortar'],
            requiredTools: ['trowel', 'level'],
            checklist: ['lay first row', 'build to height'],
            isCritical: true,
          ),
        ],
        createdAt: DateTime(2025, 1, 1),
        completedSteps: const ['foundation'],
      );

      await notifier.addPlan(plan);
      await Future.delayed(const Duration(milliseconds: 100));

      // Reload to verify persistence
      final notifier2 = WorkflowNotifier();
      await Future.delayed(const Duration(milliseconds: 100));

      expect(notifier2.state.hasValue, true);
      final plans = notifier2.state.value!;
      expect(plans.length, 1);
      final loaded = plans.first;
      expect(loaded.steps.length, 2);
      expect(loaded.steps[0].requiredMaterials, ['concrete', 'rebar']);
      expect(loaded.steps[1].prerequisites, ['foundation']);
      expect(loaded.completedSteps, ['foundation']);
    });
  });
}
