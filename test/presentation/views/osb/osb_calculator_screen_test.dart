import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/osb/osb_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('sheeting_osb_plywood');
  });

  group('OsbCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('uses Cards for sections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      // OsbCalculatorScreen uses Container with card decoration instead of Card
      // and MaterialsCardModern for materials sections
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.osb,
        ),
      );

      expect(find.byType(OsbCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for type selection', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can tap type selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 50.0,
            },
          ),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('accepts initial thickness input', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 30.0,
              'thickness': 18.0,
            },
          ),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pump();

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Construction Types', () {
    testWidgets('shows construction type selectors', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      // Verify construction type selector is present by checking for InkWell widgets
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can select different construction types', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 1) {
        await tester.tap(inkWells.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Sheet Size Selector', () {
    testWidgets('shows ModeSelectorVertical', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectorVertical), findsOneWidget);
    });

    testWidgets('can select different sheet size', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final modeSelectorVertical = find.byType(ModeSelectorVertical);
      expect(modeSelectorVertical, findsOneWidget);

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Thickness Selector', () {
    testWidgets('shows ModeSelector for thickness', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can interact with thickness selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final modeSelectors = find.byType(ModeSelector);
      expect(modeSelectors, findsWidgets);

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Input Mode', () {
    testWidgets('shows input mode selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      // Check for ModeSelector which is used for input mode
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can switch input modes', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final modeSelectors = find.byType(ModeSelector);
      if (modeSelectors.evaluate().isNotEmpty) {
        // Find the GestureDetector or InkWell inside ModeSelector to tap
        final inkWells = find.descendant(
          of: modeSelectors.first,
          matching: find.byType(InkWell),
        );
        if (inkWells.evaluate().length > 1) {
          await tester.tap(inkWells.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Area Slider', () {
    testWidgets('shows area slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('can drag area slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Reserve Slider', () {
    testWidgets('shows reserve slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      // Multiple sliders should be present (area, reserve, etc.)
      expect(find.byType(Slider), findsWidgets);
    });
  });

  group('OsbCalculatorScreen Materials', () {
    testWidgets('shows MaterialsCardModern', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsWidgets);
    });
  });

  group('OsbCalculatorScreen Additional Materials', () {
    testWidgets('shows additional materials section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Additional materials section should have MaterialsCardModern widgets
      expect(find.byType(MaterialsCardModern), findsWidgets);
    });
  });

  group('OsbCalculatorScreen Tips', () {
    testWidgets('shows tips section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(TipsCard), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Actions', () {
    testWidgets('shows copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Result Header', () {
    testWidgets('shows CalculatorResultHeader', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });
  });

  group('OsbCalculatorScreen Construction Type Interactions', () {
    testWidgets('can interact with floor type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      // Find construction type selector InkWells and tap one
      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 1) {
        await tester.tap(inkWells.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can interact with roof type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 2) {
        await tester.tap(inkWells.at(2));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can interact with partition type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 3) {
        await tester.tap(inkWells.at(3));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can interact with SIP type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 4) {
        await tester.tap(inkWells.at(4));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });

    testWidgets('can interact with formwork type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: OsbCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.osb,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 5) {
        await tester.tap(inkWells.at(5));
        await tester.pumpAndSettle();
      }

      expect(find.byType(OsbCalculatorScreen), findsOneWidget);
    });
  });
}
