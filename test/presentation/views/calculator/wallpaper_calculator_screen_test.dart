import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/providers/constants_provider.dart';
import 'package:probrab_ai/presentation/views/calculator/wallpaper_calculator_screen.dart';
import '../../../helpers/test_helpers.dart';

/// Mock constants for testing
final _mockConstantsOverrides = <Override>[
  calculatorConstantsProvider('wallpaper').overrideWith((ref) async => null),
  calculatorConstantsProvider('common').overrideWith((ref) async => null),
];

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();

    // Use real definition from registry
    final realDefinition = CalculatorRegistry.getById('walls_wallpaper');
    if (realDefinition == null) {
      throw StateError('walls_wallpaper calculator not found in registry');
    }
    testDefinition = realDefinition;
  });

  group('WallpaperCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WallpaperCalculatorScreen), findsOneWidget);
    });

    testWidgets('has input mode selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // By room and by area modes
      expect(find.text('wallpaper.input_mode.by_room'), findsOneWidget);
      expect(find.text('wallpaper.input_mode.by_area'), findsOneWidget);
    });

    testWidgets('has roll size selector', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('wallpaper.roll_size.title'), findsOneWidget);
    });

    testWidgets('shows results header', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display area, rolls count
      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('has share and copy buttons', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
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
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 40.0,
              'length': 5.0,
              'width': 4.0,
              'height': 2.8,
            },
          ),
          overrides: _mockConstantsOverrides,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WallpaperCalculatorScreen), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
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

      expect(find.byType(WallpaperCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(WallpaperCalculatorScreen), findsOneWidget);
    });

    testWidgets('can scroll content', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(WallpaperCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: _mockConstantsOverrides,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });
  });
}
