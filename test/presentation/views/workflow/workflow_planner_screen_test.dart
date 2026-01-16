import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/workflow/workflow_planner_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('WorkflowPlannerScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders with app bar when no plan', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen()),
      );
      await tester.pump();

      expect(find.text('Планировщик работ'), findsOneWidget);
    });

    testWidgets('shows empty state when no object type', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen()),
      );
      await tester.pump();

      expect(find.text('Выберите тип объекта для создания плана'), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });

    testWidgets('shows create plan button when empty', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen()),
      );
      await tester.pump();

      expect(find.text('Создать план'), findsOneWidget);
    });

    testWidgets('shows plan when object type provided', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'home')),
      );
      await tester.pump();

      // Should show the plan name (contains 'home' or localized)
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows statistics bar when plan exists', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'flat')),
      );
      await tester.pump();

      expect(find.text('Всего шагов'), findsOneWidget);
      expect(find.text('Выполнено'), findsOneWidget);
      expect(find.text('Дней'), findsOneWidget);
    });

    testWidgets('shows stat icons', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'home')),
      );
      await tester.pump();

      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsWidgets);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows save button in app bar', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'home')),
      );
      await tester.pump();

      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('shows step cards with expansion tiles', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'home')),
      );
      await tester.pump();

      expect(find.byType(ExpansionTile), findsWidgets);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('tapping create plan opens dialog', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen()),
      );
      await tester.pump();

      await tester.tap(find.text('Создать план'));
      await tester.pumpAndSettle();

      expect(find.text('Выберите тип объекта'), findsOneWidget);
      expect(find.text('Дом'), findsOneWidget);
      expect(find.text('Квартира'), findsOneWidget);
      expect(find.text('Гараж'), findsOneWidget);
    });

    testWidgets('selecting home in dialog creates plan', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen()),
      );
      await tester.pump();

      await tester.tap(find.text('Создать план'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Дом'));
      await tester.pumpAndSettle();

      // Should now show the plan
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows object icons in dialog', (tester) async {
      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen()),
      );
      await tester.pump();

      await tester.tap(find.text('Создать план'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.house), findsOneWidget);
      expect(find.byIcon(Icons.apartment), findsOneWidget);
      expect(find.byIcon(Icons.garage), findsOneWidget);
    });

    testWidgets('renders flat plan', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'flat')),
      );
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('renders garage plan', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'garage')),
      );
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('shows CircleAvatars for step numbers', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(child: const WorkflowPlannerScreen(objectType: 'home')),
      );
      await tester.pump();

      expect(find.byType(CircleAvatar), findsWidgets);
    });
  });
}
