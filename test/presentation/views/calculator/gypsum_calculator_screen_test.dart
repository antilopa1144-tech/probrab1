import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/gypsum_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('gypsum_board');
  });

  group('GypsumCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input fields', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows Cards for sections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {'area': 50.0},
          ),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('accepts initial layers input', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {'area': 30.0, 'layers': 2.0},
          ),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('accepts initial construction_type input', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {'area': 25.0, 'construction_type': 2.0},
          ),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('accepts initial gkl_type input', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {'area': 40.0, 'gkl_type': 2.0},
          ),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );

      expect(find.byType(GypsumCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for type selection', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });
  });

  group('GypsumCalculatorScreen Construction Types', () {
    testWidgets('shows TypeSelectorGroup', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TypeSelectorGroup), findsWidgets);
    });

    testWidgets('can select partition type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      final typeCards = find.byType(TypeSelectorCard);
      if (typeCards.evaluate().length > 1) {
        await tester.tap(typeCards.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select ceiling type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      final typeCards = find.byType(TypeSelectorCard);
      if (typeCards.evaluate().length > 2) {
        await tester.tap(typeCards.at(2));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });
  });

  group('GypsumCalculatorScreen GKL Types', () {
    testWidgets('shows GKL type selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });
  });

  group('GypsumCalculatorScreen Sheet Size', () {
    testWidgets('shows sheet size selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectorVertical), findsOneWidget);
    });
  });

  group('GypsumCalculatorScreen Input Mode', () {
    testWidgets('shows input mode selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });
  });

  group('GypsumCalculatorScreen Options', () {
    testWidgets('shows layers slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows insulation switch', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsOneWidget);
    });

    testWidgets('can toggle insulation switch', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(find.byType(GypsumCalculatorScreen), findsOneWidget);
    });
  });

  group('GypsumCalculatorScreen Materials', () {
    testWidgets('shows MaterialsCardModern', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsWidgets);
    });
  });

  group('GypsumCalculatorScreen Tips', () {
    testWidgets('shows tips section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      // The screen uses TipsCard widget for tips
      expect(find.text('Полезные советы'), findsOneWidget);
    });
  });

  group('GypsumCalculatorScreen Actions', () {
    testWidgets('shows copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('GypsumCalculatorScreen Result Header', () {
    testWidgets('shows CalculatorResultHeader', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GypsumCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gypsum,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });
  });
}
