import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/object_type.dart';
import 'package:probrab_ai/presentation/app/work_items_screen.dart';
import 'package:probrab_ai/presentation/data/work_catalog.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('WorkItemsScreen', () {
    late WorkAreaDefinition testArea;
    late WorkSectionDefinition testSection;

    setUp(() {
      // Get real test data from WorkCatalog
      final areas = WorkCatalog.areasFor(ObjectType.house);
      testArea = areas.firstWhere(
        (area) => area.id == 'interior',
        orElse: () => areas.first,
      );
      testSection = testArea.sections.first;
    });

    testWidgets('renders correctly', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WorkItemsScreen), findsOneWidget);
    });

    testWidgets('displays AppBar with section title', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
      // Section title is translated from 'work.section.interior.walls.title' to 'Стены'
      expect(find.text('Стены'), findsOneWidget);
    });

    testWidgets('displays area title in subtitle', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Area title is translated from 'work.area.interior.title' to 'Внутренняя отделка'
      expect(find.text('Внутренняя отделка'), findsOneWidget);
    });

    testWidgets('has ListView for work items', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('displays work item cards', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display work items
      if (testSection.items.isNotEmpty) {
        expect(find.byType(Card), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('displays work item titles', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      if (testSection.items.isNotEmpty) {
        // First item 'work.item.walls_top.title' translates to 'Стены (ТОП-использование)'
        expect(find.text('Стены (ТОП-использование)'), findsOneWidget);
      }
    });

    testWidgets('displays calculator button for items with calculator', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have calculator button text (either translated to 'Открыть калькулятор' or 'В разработке')
      final hasCalculatorText = find.text('Открыть калькулятор').evaluate().isNotEmpty ||
          find.text('В разработке').evaluate().isNotEmpty;
      expect(hasCalculatorText, isTrue);
    });

    testWidgets('shows tips section when available', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check if any item has tips
      final hasItemsWithTips = testSection.items.any((item) => item.tips.isNotEmpty);

      if (hasItemsWithTips) {
        expect(find.byIcon(Icons.lightbulb_outline), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('displays in development message for items without calculator', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Check if any item is without calculator
      final hasItemsWithoutCalculator = testSection.items.any(
        (item) => item.calculatorId == null,
      );

      if (hasItemsWithoutCalculator) {
        // 'work.screen.in_development' translates to 'В разработке'
        expect(find.text('В разработке'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AppBar is displayed', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('can tap calculator button', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final buttons = find.byType(FilledButton);
      if (buttons.evaluate().isNotEmpty) {
        // Try to tap the first button
        await tester.tap(buttons.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(WorkItemsScreen), findsOneWidget);
      }
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: WorkItemsScreen(
            objectType: ObjectType.house,
            area: testArea,
            section: testSection,
          ),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(WorkItemsScreen), findsNothing);
    });
  });
}
