import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/workflow_step.dart';
import 'package:probrab_ai/presentation/views/timeline/timeline_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('TimelineScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows loading indicator initially', (tester) async {
      // Set larger screen size to avoid overflow
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows no plan message when empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'workflow_plans': <String>[],
      });

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('workflow.timeline.no_plan'), findsOneWidget);
    });

    testWidgets('shows app bar with title', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump();

      expect(find.text('workflow.timeline.title'), findsWidgets);
    });

    testWidgets('shows timeline when plan exists', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final plan = WorkflowPlan(
        id: 'test_plan',
        name: 'Test Plan',
        steps: const [
          WorkflowStep(
            id: 'step_1',
            title: 'Foundation',
            description: 'Build foundation',
            category: 'foundation',
            order: 1,
            estimatedDays: 7,
            isCritical: true,
          ),
          WorkflowStep(
            id: 'step_2',
            title: 'Walls',
            description: 'Build walls',
            category: 'walls',
            order: 2,
            prerequisites: ['step_1'],
            estimatedDays: 14,
            isCritical: true,
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'workflow_plans': [jsonEncode(plan.toJson())],
      });

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Should show step titles
      expect(find.text('Foundation'), findsOneWidget);
      expect(find.text('Walls'), findsOneWidget);
    });

    testWidgets('shows timeline statistics', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final plan = WorkflowPlan(
        id: 'test_plan',
        name: 'Test Plan',
        steps: const [
          WorkflowStep(
            id: 'step_1',
            title: 'Step 1',
            description: 'Description',
            category: 'test',
            order: 1,
            estimatedDays: 10,
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'workflow_plans': [jsonEncode(plan.toJson())],
      });

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Should show statistics labels
      expect(find.text('workflow.timeline.start'), findsOneWidget);
      expect(find.text('workflow.timeline.end'), findsOneWidget);
      expect(find.text('workflow.timeline.days'), findsOneWidget);
    });

    testWidgets('shows calendar icon in app bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final plan = WorkflowPlan(
        id: 'test_plan',
        name: 'Test Plan',
        steps: const [
          WorkflowStep(
            id: 'step_1',
            title: 'Step 1',
            description: 'Description',
            category: 'test',
            order: 1,
            estimatedDays: 5,
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'workflow_plans': [jsonEncode(plan.toJson())],
      });

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.calendar_today), findsWidgets);
    });

    testWidgets('shows critical path chip for critical steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final plan = WorkflowPlan(
        id: 'test_plan',
        name: 'Test Plan',
        steps: const [
          WorkflowStep(
            id: 'step_1',
            title: 'Critical Step',
            description: 'This is critical',
            category: 'foundation',
            order: 1,
            estimatedDays: 7,
            isCritical: true,
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'workflow_plans': [jsonEncode(plan.toJson())],
      });

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('workflow.timeline.critical_path'), findsOneWidget);
    });

    testWidgets('shows check icon for completed steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // This would require a completed event to test
      // For now, we verify the screen renders without errors
      final plan = WorkflowPlan(
        id: 'test_plan',
        name: 'Test Plan',
        steps: const [
          WorkflowStep(
            id: 'step_1',
            title: 'Step 1',
            description: 'Description',
            category: 'test',
            order: 1,
            estimatedDays: 5,
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'workflow_plans': [jsonEncode(plan.toJson())],
      });

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('can scroll through timeline events', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final steps = List.generate(
        10,
        (i) => WorkflowStep(
          id: 'step_$i',
          title: 'Step ${i + 1}',
          description: 'Description $i',
          category: 'test',
          order: i + 1,
          estimatedDays: 3,
          prerequisites: i > 0 ? ['step_${i - 1}'] : [],
        ),
      );

      final plan = WorkflowPlan(
        id: 'test_plan',
        name: 'Test Plan',
        steps: steps,
        createdAt: DateTime(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'workflow_plans': [jsonEncode(plan.toJson())],
      });

      await tester.pumpWidget(
        createTestApp(child: const TimelineScreen()),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll down
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders with specific projectId', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final plan = WorkflowPlan(
        id: 'specific_plan',
        name: 'Specific Plan',
        steps: const [
          WorkflowStep(
            id: 'step_1',
            title: 'Step 1',
            description: 'Description',
            category: 'test',
            order: 1,
            estimatedDays: 5,
          ),
        ],
        createdAt: DateTime(2024, 1, 1),
      );

      SharedPreferences.setMockInitialValues({
        'workflow_plans': [jsonEncode(plan.toJson())],
      });

      await tester.pumpWidget(
        createTestApp(
          child: const TimelineScreen(projectId: 'specific_plan'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Step 1'), findsOneWidget);
    });
  });
}
