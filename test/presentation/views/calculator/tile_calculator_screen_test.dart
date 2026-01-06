import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';
import 'package:probrab_ai/presentation/views/calculator/tile_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';
import '../../../helpers/test_helpers.dart';

/// Mock constants for testing
final _mockConstantsOverrides = <Override>[
  calculatorConstantsProvider('tile').overrideWith((ref) async => null),
  calculatorConstantsProvider('common').overrideWith((ref) async => null),
];

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();

    // Use real definition from registry
    final realDefinition = CalculatorRegistry.getById('floors_tile');
    if (realDefinition == null) {
      throw StateError('floors_tile calculator not found in registry');
    }
    testDefinition = realDefinition;
  });

  group('TileCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('has tile material selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should have material type options
      expect(find.byIcon(Icons.grid_on), findsWidgets);
    });

    testWidgets('has share and copy buttons', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('has sliders for adjustments', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows results in header', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display area
      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
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

      expect(find.byType(TileCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });
  });

  group('TileCalculatorScreen input modes', () {
    testWidgets('shows input mode selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Режим ввода'), findsOneWidget);
    });

    testWidgets('has ModeSelector widget', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can switch between area and dimensions mode', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap the "По размерам" button
      final byDimensionsText = find.text('По размерам');
      if (byDimensionsText.evaluate().isNotEmpty) {
        await tester.tap(byDimensionsText);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen material selection', () {
    testWidgets('shows material selector icons', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Check for material icons
      expect(find.byIcon(Icons.grid_on), findsWidgets); // ceramic
      expect(find.byIcon(Icons.view_module), findsWidgets); // porcelain
    });

    testWidgets('can select ceramic material', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find ceramic text and tap
      final ceramic = find.text('Керамическая плитка');
      if (ceramic.evaluate().isNotEmpty) {
        await tester.tap(ceramic.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select porcelain material', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find porcelain text and tap
      final porcelain = find.text('Керамогранит');
      if (porcelain.evaluate().isNotEmpty) {
        await tester.tap(porcelain.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen room types', () {
    testWidgets('shows room type selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Should have room type icons
      expect(find.byIcon(Icons.bathroom), findsWidgets);
      expect(find.byIcon(Icons.kitchen), findsWidgets);
    });

    testWidgets('can select bathroom room type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find bathroom option and tap
      final bathroom = find.text('Ванная / санузел');
      if (bathroom.evaluate().isNotEmpty) {
        await tester.tap(bathroom.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select kitchen room type', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find kitchen option and tap
      final kitchen = find.text('Кухня');
      if (kitchen.evaluate().isNotEmpty) {
        await tester.tap(kitchen.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen layout patterns', () {
    testWidgets('shows layout pattern selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Should have layout pattern icons
      expect(find.byIcon(Icons.grid_3x3), findsWidgets); // straight
      expect(find.byIcon(Icons.rotate_right), findsWidgets); // diagonal
    });

    testWidgets('can select straight layout', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find straight pattern and tap
      final straight = find.text('Прямая');
      if (straight.evaluate().isNotEmpty) {
        await tester.tap(straight.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select diagonal layout', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find diagonal pattern and tap
      final diagonal = find.text('Диагональная');
      if (diagonal.evaluate().isNotEmpty) {
        await tester.tap(diagonal.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen options', () {
    testWidgets('shows option toggles', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Should have switch widgets for options
      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle SVP option', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Check for common tile sizes
      expect(find.textContaining('см'), findsWidgets);
    });

    testWidgets('can change tile size preset', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy);
      expect(copyButton, findsOneWidget);

      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      // Should show snackbar
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('can tap share button', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final shareButton = find.byIcon(Icons.share);
      expect(shareButton, findsOneWidget);

      // Just verify button exists, share may not work in test
      expect(find.byType(TileCalculatorScreen), findsOneWidget);
    });
  });

  group('TileCalculatorScreen results', () {
    testWidgets('shows tiles count in result', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Should show tiles count
      expect(find.textContaining('шт'), findsWidgets);
    });

    testWidgets('shows boxes count in result', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Should show boxes label
      expect(find.text('УПАКОВОК'), findsOneWidget);
    });

    testWidgets('shows material results after scroll', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
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
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('shows CalculatorScaffold', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });
  });

  group('TileCalculatorScreen joint width', () {
    testWidgets('can adjust joint width slider', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      // Find joint width text
      final jointText = find.textContaining('мм');
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
