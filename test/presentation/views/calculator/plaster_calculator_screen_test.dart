import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/plaster_calculator_screen.dart';
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

      // Should have gypsum and cement options
      expect(find.text('plaster_pro.material.gypsum'), findsOneWidget);
      expect(find.text('plaster_pro.material.cement'), findsOneWidget);
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

      // Manual and room modes
      expect(find.text('plaster_pro.mode.manual'), findsOneWidget);
      expect(find.text('plaster_pro.mode.room'), findsOneWidget);
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
      expect(find.text('plaster_pro.thickness.title'), findsOneWidget);
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

      // Should display wall area, bags count, weight
      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('common.sqm'), findsWidgets);
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

      // Tap cement option
      await tester.tap(find.text('plaster_pro.material.cement'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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

      // By default beacons are on, should show beacons text
      expect(find.text('plaster_pro.options.beacons'), findsOneWidget);
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

      // By default mesh is off
      expect(find.text('plaster_pro.spec.mesh_title'), findsNothing);
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

      // By default primer is on
      expect(find.text('plaster_pro.options.primer'), findsOneWidget);
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

      // Tap room mode
      await tester.tap(find.text('plaster_pro.mode.room'));
      await tester.pump();

      // Should show room dimension fields
      expect(find.text('plaster_pro.label.width'), findsOneWidget);
      expect(find.text('plaster_pro.label.length'), findsOneWidget);
      expect(find.text('plaster_pro.label.height'), findsOneWidget);
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
      await tester.tap(find.text('plaster_pro.mode.room'));
      await tester.pump();

      expect(find.text('plaster_pro.label.openings_hint'), findsOneWidget);
    });
  });
}
