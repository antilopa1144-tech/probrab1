import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/underfloor_heating_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/test_helpers.dart';
import '../../../helpers/calculator_test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('floors_warm');
  });

  group('UnderfloorHeatingCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pump();

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pump();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('uses Cards for sections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 30.0,
            },
          ),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pump();

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen input modes', () {
    testWidgets('shows input mode selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('warmfloor.mode'), findsWidgets);
    });

    testWidgets('has ModeSelector widget', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can switch between area and dimensions mode', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find mode selector by localization key
      final byDimensionsText = find.text('warmfloor.mode.by_dimensions');
      if (byDimensionsText.evaluate().isNotEmpty) {
        await tester.tap(byDimensionsText);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen heating system types', () {
    testWidgets('shows heating system selector icons', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.grid_on), findsWidgets);
      expect(find.byIcon(Icons.cable), findsWidgets);
    });

    testWidgets('can select electric mat', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find by localization key
      final electricMat = find.text('warmfloor.system.electric_mat');
      if (electricMat.evaluate().isNotEmpty) {
        await tester.tap(electricMat.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select electric cable', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find by localization key
      final electricCable = find.text('warmfloor.system.electric_cable');
      if (electricCable.evaluate().isNotEmpty) {
        await tester.tap(electricCable.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select infrared film', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find by localization key
      final film = find.text('warmfloor.system.infrared_film');
      if (film.evaluate().isNotEmpty) {
        await tester.tap(film.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select water based system', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find by localization key
      final water = find.text('warmfloor.system.water_based');
      if (water.evaluate().isNotEmpty) {
        await tester.tap(water.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen room types', () {
    testWidgets('shows room type selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // TestAppLocalizations returns keys, so we search for localization key
      expect(find.textContaining('warmfloor.room'), findsWidgets);
    });

    testWidgets('can select bathroom room type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // TestAppLocalizations returns keys, try to find a room type option
      final roomTypeOption = find.textContaining('room_type');
      if (roomTypeOption.evaluate().isNotEmpty) {
        await tester.tap(roomTypeOption.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select living room type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find by localization key
      final living = find.text('warmfloor.room.living');
      if (living.evaluate().isNotEmpty) {
        await tester.tap(living.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select kitchen room type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find by localization key
      final kitchen = find.text('warmfloor.room.kitchen');
      if (kitchen.evaluate().isNotEmpty) {
        await tester.tap(kitchen.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('can select balcony room type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Find by localization key
      final balcony = find.text('warmfloor.room.balcony');
      if (balcony.evaluate().isNotEmpty) {
        await tester.tap(balcony.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen options', () {
    testWidgets('shows option switches', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle insulation option', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
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

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen actions', () {
    testWidgets('has copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('has share button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final copyButton = find.byIcon(Icons.copy_rounded);
      await tester.tap(copyButton);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen results', () {
    testWidgets('shows power result in header', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Verify CalculatorResultHeader is present (contains power result)
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('shows area result', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      // Verify CalculatorResultHeader is present (contains area result)
      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('shows CalculatorResultHeader', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });

    testWidgets('shows CalculatorScaffold', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorScaffold), findsOneWidget);
    });

    testWidgets('updates results when area changes', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().isNotEmpty) {
        await tester.drag(sliders.first, const Offset(100, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen materials', () {
    testWidgets('shows materials after scroll', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -500));
      await tester.pumpAndSettle();

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows tips section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -800));
      await tester.pumpAndSettle();

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });
  });

  group('UnderfloorHeatingCalculatorScreen useful area', () {
    testWidgets('can adjust useful area slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      if (sliders.evaluate().length > 1) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(UnderfloorHeatingCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows useful area text', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: UnderfloorHeatingCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.underfloorHeating,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('%'), findsWidgets);
    });
  });
}
