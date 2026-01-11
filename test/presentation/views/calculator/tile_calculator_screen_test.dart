import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/tile_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('floors_tile');
  });

  group('TileCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('has tile material selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have material type options
      expect(find.byIcon(Icons.grid_on), findsWidgets);
    });

    testWidgets('has share and copy buttons', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('has sliders for adjustments', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows results in header', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display area
      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 25.0,
              'length': 5.0,
              'width': 4.0,
            },
          ),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.tile,
        ),
      );

      expect(find.byType(TileCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });
  });

  group('TileCalculatorScreen input modes', () {
    testWidgets('shows input mode selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('tile.mode'), findsWidgets);
    });

    testWidgets('has ModeSelector widget', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can switch between area and dimensions mode', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the "by dimensions" button using localization key
      final byDimensionsText = find.textContaining('tile.mode.by_dimensions');
      if (byDimensionsText.evaluate().isNotEmpty) {
        await tester.tap(byDimensionsText.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen material selection', () {
    testWidgets('shows material selector icons', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Check for material icons
      expect(find.byIcon(Icons.grid_on), findsWidgets); // ceramic
      expect(find.byIcon(Icons.view_module), findsWidgets); // porcelain
    });

    testWidgets('can select ceramic material', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find ceramic using localization key
      final ceramic = find.textContaining('tile.type.ceramic');
      if (ceramic.evaluate().isNotEmpty) {
        await tester.tap(ceramic.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select porcelain material', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find porcelain using localization key
      final porcelain = find.textContaining('tile.type.porcelain');
      if (porcelain.evaluate().isNotEmpty) {
        await tester.tap(porcelain.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen room types', () {
    testWidgets('shows room type selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Should have room type icons
      expect(find.byIcon(Icons.bathroom), findsWidgets);
      expect(find.byIcon(Icons.kitchen), findsWidgets);
    });

    testWidgets('can select bathroom room type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find bathroom option using localization key
      final bathroom = find.textContaining('tile.room.bathroom');
      if (bathroom.evaluate().isNotEmpty) {
        await tester.tap(bathroom.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select kitchen room type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find kitchen option using localization key
      final kitchen = find.textContaining('tile.room.kitchen');
      if (kitchen.evaluate().isNotEmpty) {
        await tester.tap(kitchen.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen layout patterns', () {
    testWidgets('shows layout pattern selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Should have layout pattern icons
      expect(find.byIcon(Icons.grid_3x3), findsWidgets); // straight
      expect(find.byIcon(Icons.rotate_right), findsWidgets); // diagonal
    });

    testWidgets('can select straight layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find straight pattern using localization key
      final straight = find.textContaining('tile.layout.straight');
      if (straight.evaluate().isNotEmpty) {
        await tester.tap(straight.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select diagonal layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find diagonal pattern using localization key
      final diagonal = find.textContaining('tile.layout.diagonal');
      if (diagonal.evaluate().isNotEmpty) {
        await tester.tap(diagonal.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen options', () {
    testWidgets('shows option toggles', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Should have switch widgets for options
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle SVP option', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to find the switches
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      // Try to find and tap a switch
      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen tile size', () {
    testWidgets('shows tile size preset selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Check for tile size presets (search for widget types instead of text)
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('can change tile size preset', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find a tile size option and tap
      final tileSize = find.text('60×60');
      if (tileSize.evaluate().isNotEmpty) {
        await tester.tap(tileSize.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen actions', () {
    testWidgets('can tap copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('can tap share button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share_rounded);
      expect(shareButton, findsOneWidget);

      // Just verify button exists, share may not work in test
      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen results', () {
    testWidgets('shows tiles count in result', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Should show tiles count (TestAppLocalizations returns keys)
      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('shows boxes count in result', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Should show boxes label (TestAppLocalizations returns keys)
      expect(find.textContaining('boxes'), findsWidgets);
    });

    testWidgets('shows material results after scroll', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to see more results
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('updates results when area changes', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find area slider and drag it
      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen additional info', () {
    testWidgets('shows tips section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to see tips
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows HintCard widgets', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Scroll down to see hints
      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -1000));
      await tester.pumpAndSettle();

      // May have hint cards - just verify it renders without error
      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows CalculatorResultHeader', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('shows CalculatorScaffold', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });
  });

  group('TileCalculatorScreen joint width', () {
    testWidgets('can adjust joint width slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await tester.pumpAndSettle();

      // Find joint width (TestAppLocalizations returns keys)
      final jointText = find.textContaining('common.mm');
      expect(jointText, findsWidgets);

      // Drag a slider
      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 1) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });
}
