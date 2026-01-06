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
      expect(find.text(testSection.title), findsOneWidget);
    });

    testWidgets('displays area title in subtitle', (tester) async {
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

      expect(find.text(testArea.title), findsOneWidget);
    });

    testWidgets('has ListView for work items', (tester) async {
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
        final itemTitle = testSection.items.first.title;
        expect(find.text(itemTitle), findsOneWidget);
      }
    });

    testWidgets('displays calculator button for items with calculator', (tester) async {
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

      // Should have at least one button (either enabled or disabled)
      expect(find.byType(FilledButton), findsAtLeastNWidgets(1));
    });

    testWidgets('shows tips section when available', (tester) async {
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
        expect(find.text('work.screen.in_development'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('AppBar is displayed', (tester) async {
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
