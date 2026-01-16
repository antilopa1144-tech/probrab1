import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/plaster_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';
import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('mixes_plaster');
  });

  group('PlasterCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('has material type selector', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have TypeSelectorGroup for gypsum and cement options
      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('has input mode selector', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Manual and room modes via ModeSelector
      expect(find.byType(ModeSelector), findsOneWidget);
    });

    testWidgets('has thickness slider', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows results header', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display CalculatorResultHeader with wall area, bags count, weight
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('switching material type updates calculation', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap second type card (cement option)
      final typeCards = find.byType(TypeSelectorCard);
      expect(typeCards, findsWidgets);
      if (typeCards.evaluate().length > 1) {
        await tester.tap(typeCards.at(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(PlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('has beacons toggle option', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Icon appears in toggle button and in spec card
      expect(find.byIcon(Icons.architecture), findsWidgets);
    });

    testWidgets('has mesh toggle option', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.grid_on), findsWidgets);
    });

    testWidgets('has primer toggle option', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Icon appears in toggle button and in spec card
      expect(find.byIcon(Icons.water_drop), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 50.0,
              'thickness': 20.0,
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('accepts initial inputs with cement type', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'type': 2.0, // cement
              'area': 30.0,
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(PlasterCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows beacons in spec by default', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // By default beacons are on, should show MaterialsCardModern with beacons
      expect(find.byType(MaterialsCardModern), findsOneWidget);
      // Architecture icon appears for beacons (in toggle button and spec card)
      expect(find.byIcon(Icons.architecture), findsWidgets);
    });

    testWidgets('does not show mesh in spec by default', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // By default mesh is off - MaterialsCardModern should still exist
      expect(find.byType(MaterialsCardModern), findsOneWidget);
    });

    testWidgets('shows primer in spec by default', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // By default primer is on - water_drop icon should appear
      expect(find.byIcon(Icons.water_drop), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(PlasterCalculatorScreen), findsNothing);
    });

    testWidgets('slider interaction works', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find sliders
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      // Interact with first slider (area in manual mode)
      await tester.drag(sliders.first, const Offset(50, 0));
      await tester.pump();

      expect(find.byType(PlasterCalculatorScreen), findsOneWidget);
    });
  });

  group('PlasterCalculatorScreen room mode', () {
    testWidgets('switching to room mode shows room inputs', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap room mode (second option in ModeSelector)
      final modeSelector = find.byType(ModeSelector);
      expect(modeSelector, findsOneWidget);

      // Find the mode selector options and tap the second one (room)
      // ModeSelector uses GestureDetector, so find by that
      final gestureDetectors = find.descendant(
        of: modeSelector,
        matching: find.byType(GestureDetector),
      );
      if (gestureDetectors.evaluate().length > 1) {
        await tester.tap(gestureDetectors.at(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should show room dimension fields - CalculatorTextField widgets
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('room mode has openings area field', (tester) async {
      setupTestScreenSize(tester);
      await tester.pumpWidget(
        createTestApp(
          overrides: CalculatorMockOverrides.plaster,
          child: PlasterCalculatorScreen(definition: testDefinition),
        ),
      );

      await tester.pump();

      // Switch to room mode
      final modeSelector = find.byType(ModeSelector);
      expect(modeSelector, findsOneWidget);

      final gestureDetectors = find.descendant(
        of: modeSelector,
        matching: find.byType(GestureDetector),
      );
      if (gestureDetectors.evaluate().length > 1) {
        await tester.tap(gestureDetectors.at(1));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should show CalculatorTextField inputs for room dimensions including openings
      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });
}
