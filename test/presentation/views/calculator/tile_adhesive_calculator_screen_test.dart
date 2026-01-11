import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/tile_adhesive_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';
import 'package:probrab_ai/presentation/widgets/existing/hint_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    setupMocks();

    testDefinition = getCalculatorDefinition('mixes_tile_glue');
  });

  group('TileAdhesiveCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pump();

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows Cards for sections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );

      expect(find.byType(TileAdhesiveCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 30.0,
            },
          ),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pump();

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });
  });

  group('TileAdhesiveCalculatorScreen Input Mode', () {
    testWidgets('shows ModeSelector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });
  });

  group('TileAdhesiveCalculatorScreen Tile Type', () {
    testWidgets('shows ModeSelectorVertical', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectorVertical), findsWidgets);
    });

    testWidgets('can select tile type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().length > 1) {
        await tester.tap(inkWells.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });
  });

  group('TileAdhesiveCalculatorScreen Options', () {
    testWidgets('shows Switch for options', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle option switch', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });
  });

  group('TileAdhesiveCalculatorScreen Materials', () {
    testWidgets('shows MaterialsCardModern', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsWidgets);
    });
  });

  group('TileAdhesiveCalculatorScreen Tips', () {
    testWidgets('shows tips section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(HintsList), findsOneWidget);
    });
  });

  group('TileAdhesiveCalculatorScreen Actions', () {
    testWidgets('shows copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('TileAdhesiveCalculatorScreen Result Header', () {
    testWidgets('shows CalculatorResultHeader', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tileAdhesive,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });
  });
}
