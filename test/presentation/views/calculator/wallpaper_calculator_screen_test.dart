import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/wallpaper_calculator_screen.dart';
import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('walls_wallpaper');
  });

  group('WallpaperCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WallpaperCalculatorScreen), findsOneWidget);
    });

    testWidgets('has input mode selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // By room and by area modes - using actual Russian localization text
      expect(find.text('По комнате'), findsOneWidget);
      expect(find.text('По площади'), findsOneWidget);
    });

    testWidgets('has roll size selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Using actual Russian localization text
      expect(find.text('Размер рулона'), findsOneWidget);
    });

    testWidgets('shows results header', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should display area, rolls count
      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('м²'), findsWidgets);
    });

    testWidgets('has share and copy buttons', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
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
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

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
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(WallpaperCalculatorScreen), findsOneWidget);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );

      expect(find.byType(WallpaperCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
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
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(WallpaperCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: WallpaperCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.wallpaper,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });
  });
}
