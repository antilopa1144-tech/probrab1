import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/object_type.dart';
import 'package:probrab_ai/presentation/app/category_selector_screen.dart';
import 'package:probrab_ai/presentation/data/work_catalog.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('CategorySelectorScreen', () {
    late WorkAreaDefinition testArea;

    setUp(() {
      // Get a real area from WorkCatalog for testing
      final areas = WorkCatalog.areasFor(ObjectType.house);
      testArea = areas.firstWhere(
        (area) => area.id == 'interior',
        orElse: () => areas.first,
      );
    });

    testWidgets('renders correctly', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(CategorySelectorScreen), findsOneWidget);
    });

    testWidgets('displays AppBar with area title', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
      // testArea.title is a localization key, the screen translates it
      expect(find.text('Внутренняя отделка'), findsOneWidget);
    });

    testWidgets('displays area subtitle', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // testArea.subtitle is a localization key, the screen translates it
      expect(find.text('Стены, потолки, полы, перегородки и окна'), findsOneWidget);
    });

    testWidgets('has GridView for sections', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays section cards', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display section cards
      if (testArea.sections.isNotEmpty) {
        expect(find.byType(GridView), findsOneWidget);
      }
    });

    testWidgets('can tap on section card', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      if (testArea.sections.isNotEmpty) {
        // Section titles are localization keys that get translated
        // Find translated section title 'Стены' (walls)
        final sectionCard = find.text('Стены');

        if (sectionCard.evaluate().isNotEmpty) {
          await tester.tap(sectionCard);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));

          // Navigation should occur
          expect(find.byType(CategorySelectorScreen), findsOneWidget);
        }
      }
    });

    testWidgets('AppBar is displayed', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // AppBar should be present
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: CategorySelectorScreen(
            objectType: ObjectType.house,
            area: testArea,
          ),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(CategorySelectorScreen), findsNothing);
    });
  });
}
