import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';
import 'package:probrab_ai/presentation/views/calculator/tile_adhesive_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';
import 'package:probrab_ai/presentation/widgets/existing/hint_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_helpers.dart';

/// Mock constants for testing
final _mockConstantsOverrides = <Override>[
  calculatorConstantsProvider('tile_adhesive').overrideWith((ref) async => null),
  calculatorConstantsProvider('common').overrideWith((ref) async => null),
];

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    setupMocks();

    final realDefinition = CalculatorRegistry.getById('mixes_tile_glue');
    if (realDefinition == null) {
      throw StateError('mixes_tile_glue calculator not found in registry');
    }
    testDefinition = realDefinition;
  });

  group('TileAdhesiveCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows Cards for sections', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: _mockConstantsOverrides,
        ),
      );

      expect(find.byType(TileAdhesiveCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 30.0,
            },
          ),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pump();

      expect(find.byType(TileAdhesiveCalculatorScreen), findsOneWidget);
    });
  });

  group('TileAdhesiveCalculatorScreen Input Mode', () {
    testWidgets('shows ModeSelector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });
  });

  group('TileAdhesiveCalculatorScreen Tile Type', () {
    testWidgets('shows ModeSelectorVertical', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelectorVertical), findsWidgets);
    });

    testWidgets('can select tile type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle option switch', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MaterialsCardModern), findsWidgets);
    });
  });

  group('TileAdhesiveCalculatorScreen Tips', () {
    testWidgets('shows tips section', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('TileAdhesiveCalculatorScreen Result Header', () {
    testWidgets('shows CalculatorResultHeader', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileAdhesiveCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });
  });
}
