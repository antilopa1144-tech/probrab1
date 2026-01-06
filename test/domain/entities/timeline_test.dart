import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/timeline.dart';
import 'package:probrab_ai/domain/entities/workflow_step.dart';

void main() {
  group('TimelineEvent', () {
    test('creates with required parameters', () {
      final event = TimelineEvent(
        stepId: 'step1',
        title: 'Test Step',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 5),
        isCritical: true,
      );

      expect(event.stepId, 'step1');
      expect(event.title, 'Test Step');
      expect(event.startDate, DateTime(2024, 1, 1));
      expect(event.endDate, DateTime(2024, 1, 5));
      expect(event.isCritical, isTrue);
      expect(event.isCompleted, isFalse);
      expect(event.notes, isNull);
    });

    test('creates with all parameters', () {
      final event = TimelineEvent(
        stepId: 'step1',
        title: 'Test Step',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 10),
        isCritical: false,
        isCompleted: true,
        notes: 'Some notes',
      );

      expect(event.isCompleted, isTrue);
      expect(event.notes, 'Some notes');
    });

    test('durationDays returns correct number of days', () {
      final event = TimelineEvent(
        stepId: 'step1',
        title: 'Test Step',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 8),
        isCritical: false,
      );

      expect(event.durationDays, 7);
    });

    test('durationDays returns 0 for same day', () {
      final event = TimelineEvent(
        stepId: 'step1',
        title: 'Test Step',
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 1),
        isCritical: false,
      );

      expect(event.durationDays, 0);
    });
  });

  group('Timeline', () {
    test('creates with required parameters', () {
      final timeline = Timeline(
        projectId: 'project1',
        events: [],
        startDate: DateTime(2024, 1, 1),
      );

      expect(timeline.projectId, 'project1');
      expect(timeline.events, isEmpty);
      expect(timeline.startDate, DateTime(2024, 1, 1));
      expect(timeline.endDate, isNull);
    });

    test('creates with endDate', () {
      final timeline = Timeline(
        projectId: 'project1',
        events: [],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 2, 1),
      );

      expect(timeline.endDate, DateTime(2024, 2, 1));
    });

    test('getCriticalPath returns only critical events', () {
      final events = [
        TimelineEvent(
          stepId: 'step1',
          title: 'Critical Step',
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 5),
          isCritical: true,
        ),
        TimelineEvent(
          stepId: 'step2',
          title: 'Non-critical Step',
          startDate: DateTime(2024, 1, 5),
          endDate: DateTime(2024, 1, 8),
          isCritical: false,
        ),
        TimelineEvent(
          stepId: 'step3',
          title: 'Another Critical',
          startDate: DateTime(2024, 1, 8),
          endDate: DateTime(2024, 1, 12),
          isCritical: true,
        ),
      ];

      final timeline = Timeline(
        projectId: 'project1',
        events: events,
        startDate: DateTime(2024, 1, 1),
      );

      final criticalPath = timeline.getCriticalPath();

      expect(criticalPath.length, 2);
      expect(criticalPath[0].title, 'Critical Step');
      expect(criticalPath[1].title, 'Another Critical');
    });

    test('getTotalDays returns 0 when endDate is null', () {
      final timeline = Timeline(
        projectId: 'project1',
        events: [],
        startDate: DateTime(2024, 1, 1),
      );

      expect(timeline.getTotalDays(), 0);
    });

    test('getTotalDays returns correct days', () {
      final timeline = Timeline(
        projectId: 'project1',
        events: [],
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 15),
      );

      expect(timeline.getTotalDays(), 14);
    });

    test('fromWorkflowPlan creates timeline from plan', () {
      final steps = [
        const WorkflowStep(
          id: 'step1',
          title: 'First Step',
          description: 'Description 1',
          category: 'preparation',
          order: 1,
          estimatedDays: 3,
          isCritical: true,
          prerequisites: [],
        ),
        const WorkflowStep(
          id: 'step2',
          title: 'Second Step',
          description: 'Description 2',
          category: 'work',
          order: 2,
          estimatedDays: 5,
          isCritical: false,
          prerequisites: ['step1'],
        ),
      ];

      final plan = WorkflowPlan(
        id: 'plan1',
        name: 'Test Plan',
        steps: steps,
        createdAt: DateTime(2024, 1, 1),
      );

      final startDate = DateTime(2024, 1, 1);
      final timeline = Timeline.fromWorkflowPlan(plan, startDate);

      expect(timeline.projectId, 'plan1');
      expect(timeline.startDate, startDate);
      expect(timeline.events.length, 2);

      // First event starts on start date
      expect(timeline.events[0].startDate, startDate);
      expect(timeline.events[0].endDate, DateTime(2024, 1, 4));
      expect(timeline.events[0].title, 'First Step');

      // Second event starts after first ends
      expect(timeline.events[1].startDate, DateTime(2024, 1, 4));
      expect(timeline.events[1].endDate, DateTime(2024, 1, 9));
      expect(timeline.events[1].title, 'Second Step');

      expect(timeline.endDate, DateTime(2024, 1, 9));
    });

    test('fromWorkflowPlan handles empty plan', () {
      final plan = WorkflowPlan(
        id: 'plan1',
        name: 'Empty Plan',
        steps: const [],
        createdAt: DateTime(2024, 1, 1),
      );

      final startDate = DateTime(2024, 1, 1);
      final timeline = Timeline.fromWorkflowPlan(plan, startDate);

      expect(timeline.events, isEmpty);
      expect(timeline.endDate, isNull);
    });

    test('fromWorkflowPlan respects step order', () {
      final steps = [
        const WorkflowStep(
          id: 'step2',
          title: 'Second Step',
          description: 'Description 2',
          category: 'work',
          order: 2,
          estimatedDays: 2,
          isCritical: false,
          prerequisites: ['step1'],
        ),
        const WorkflowStep(
          id: 'step1',
          title: 'First Step',
          description: 'Description 1',
          category: 'preparation',
          order: 1,
          estimatedDays: 3,
          isCritical: true,
          prerequisites: [],
        ),
      ];

      final plan = WorkflowPlan(
        id: 'plan1',
        name: 'Unordered Plan',
        steps: steps,
        createdAt: DateTime(2024, 1, 1),
      );

      final startDate = DateTime(2024, 1, 1);
      final timeline = Timeline.fromWorkflowPlan(plan, startDate);

      expect(timeline.events.length, 2);
      expect(timeline.events[0].title, 'First Step');
      expect(timeline.events[1].title, 'Second Step');
    });
  });
}
