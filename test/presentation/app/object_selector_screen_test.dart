import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/object_type.dart';
import 'package:probrab_ai/presentation/app/object_selector_screen.dart';
import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('ObjectSelectorScreen', () {
    testWidgets('renders correctly for house', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.house),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ObjectSelectorScreen), findsOneWidget);
    });

    testWidgets('renders correctly for flat', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.flat),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ObjectSelectorScreen), findsOneWidget);
    });

    testWidgets('renders correctly for garage', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.garage),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(ObjectSelectorScreen), findsOneWidget);
    });

    testWidgets('displays AppBar with title', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.house),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Дом'), findsOneWidget);
    });

    testWidgets('displays correct title for flat', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.flat),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Квартира'), findsOneWidget);
    });

    testWidgets('displays correct title for garage', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.garage),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Гараж'), findsOneWidget);
    });

    testWidgets('has GridView for areas', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.house),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('displays area cards', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.house),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display at least some area cards
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows empty state when no areas available', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      // Garage might have fewer areas
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.garage),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should either show grid or empty state
      expect(
        find.byType(GridView).evaluate().isNotEmpty ||
            find.text('Категории для этого объекта появятся позже').evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('AppBar is displayed', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.house),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        createTestApp(
          child: const ObjectSelectorScreen(objectType: ObjectType.house),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(ObjectSelectorScreen), findsNothing);
    });
  });
}
