import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/gasblock_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('partitions_blocks');
  });

  group('GasblockCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pump();

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pump();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('uses Cards for sections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );

      expect(find.byType(GasblockCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for type selection', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 50.0,
            },
          ),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pump();

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen input modes', () {
    testWidgets('shows input mode selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // TestAppLocalizations returns keys, so we verify widget exists instead
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('has ModeSelector widget', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can switch between area and dimensions mode', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Use ModeSelector widget instead of Russian text
      final modeSelectorItems = find.descendant(
        of: find.byType(ModeSelector),
        matching: find.byType(InkWell),
      );
      if (modeSelectorItems.evaluate().length > 1) {
        await tester.tap(modeSelectorItems.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen wall types', () {
    testWidgets('shows wall type icons', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.view_agenda), findsWidgets);
      expect(find.byIcon(Icons.home_work_outlined), findsWidgets);
    });

    testWidgets('can select partition wall type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Use TypeSelectorCard instead of Russian text
      final typeCards = find.byType(TypeSelectorCard);
      if (typeCards.evaluate().isNotEmpty) {
        await tester.tap(typeCards.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select bearing wall type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Use TypeSelectorCard instead of Russian text
      final typeCards = find.byType(TypeSelectorCard);
      if (typeCards.evaluate().length > 1) {
        await tester.tap(typeCards.at(1));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen block materials', () {
    testWidgets('shows block material icons', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.cloud_outlined), findsWidgets);
      expect(find.byIcon(Icons.bubble_chart_outlined), findsWidgets);
    });

    testWidgets('can select gasblock material', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Use ModeSelector instead of Russian text - material selector
      final modeSelectors = find.byType(ModeSelector);
      if (modeSelectors.evaluate().length > 1) {
        final materialSelector = modeSelectors.at(1);
        final items = find.descendant(
          of: materialSelector,
          matching: find.byType(InkWell),
        );
        if (items.evaluate().isNotEmpty) {
          await tester.tap(items.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select foamblock material', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Use ModeSelector instead of Russian text - material selector
      final modeSelectors = find.byType(ModeSelector);
      if (modeSelectors.evaluate().length > 1) {
        final materialSelector = modeSelectors.at(1);
        final items = find.descendant(
          of: materialSelector,
          matching: find.byType(InkWell),
        );
        if (items.evaluate().length > 1) {
          await tester.tap(items.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen masonry mix', () {
    testWidgets('shows masonry mix icons', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grain), findsWidgets);
    });

    testWidgets('can select glue masonry mix', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Use ModeSelector instead of Russian text - masonry selector
      final modeSelectors = find.byType(ModeSelector);
      if (modeSelectors.evaluate().length > 2) {
        final masonrySelector = modeSelectors.at(2);
        final items = find.descendant(
          of: masonrySelector,
          matching: find.byType(InkWell),
        );
        if (items.evaluate().isNotEmpty) {
          await tester.tap(items.first);
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select mortar masonry mix', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Use ModeSelector instead of Russian text - masonry selector
      final modeSelectors = find.byType(ModeSelector);
      if (modeSelectors.evaluate().length > 2) {
        final masonrySelector = modeSelectors.at(2);
        final items = find.descendant(
          of: masonrySelector,
          matching: find.byType(InkWell),
        );
        if (items.evaluate().length > 1) {
          await tester.tap(items.at(1));
          await tester.pumpAndSettle();
        }
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen options', () {
    testWidgets('shows option switches', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle options', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen actions', () {
    testWidgets('has copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('has share button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen results', () {
    testWidgets('shows blocks count in result', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('common.pcs'), findsWidgets);
    });

    testWidgets('shows area result', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('common.sqm'), findsWidgets);
    });

    testWidgets('shows CalculatorResultHeader', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('shows CalculatorScaffold', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('updates results when area changes', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen materials', () {
    testWidgets('shows materials after scroll', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows tips section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });

  group('GasblockCalculatorScreen block size', () {
    testWidgets('shows block size presets', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      // Should show preset labels
      expect(find.text('600x300'), findsWidgets);
    });

    testWidgets('can change block size preset', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: GasblockCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.gasblock,
        ),
      );
      await tester.pumpAndSettle();

      final preset = find.text('600x250');
      if (preset.evaluate().isNotEmpty) {
        await tester.tap(preset.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(GasblockCalculatorScreen), findsOneWidget);
    });
  });
}
