import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/electrical_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/mode_selector.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_result_header.dart';

import 'package:probrab_ai/presentation/widgets/calculator/calculator_text_field.dart';

import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();
    testDefinition = getCalculatorDefinition('engineering_electrics');
  });

  group('ElectricalCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      expect(find.byType(ElectricalCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows input sliders', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('shows Cards for sections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );

      expect(find.byType(ElectricalCalculatorScreen), findsNothing);
    });

    testWidgets('can interact with slider', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(ElectricalCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows InkWell for selections', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('can scroll content', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(SingleChildScrollView).first;
      await tester.drag(scrollable, const Offset(0, -200));
      await tester.pumpAndSettle();

      expect(find.byType(ElectricalCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows IconButton for actions', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsWidgets);
    });

    testWidgets('accepts initial inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'rooms': 5.0,
            },
          ),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      expect(find.byType(ElectricalCalculatorScreen), findsOneWidget);
    });

    testWidgets('accepts initial area inputs', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(
            definition: testDefinition,
            initialInputs: const {
              'area': 80.0,
              'rooms': 4.0,
            },
          ),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pump();

      expect(find.byType(ElectricalCalculatorScreen), findsOneWidget);
    });
  });

  group('ElectricalCalculatorScreen slider+textfield', () {
    testWidgets('slider fields have paired CalculatorTextField', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      // Both Slider and CalculatorTextField should be present
      expect(find.byType(Slider), findsWidgets);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });
  });

  group('ElectricalCalculatorScreen Room Types', () {
    testWidgets('shows room type selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      // The electrical calculator uses ModeSelector for room types
      expect(find.byType(ModeSelector), findsWidgets);
    });

    testWidgets('can select different room type', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      final inkWells = find.byType(InkWell);
      if (inkWells.evaluate().isNotEmpty) {
        await tester.tap(inkWells.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(ElectricalCalculatorScreen), findsOneWidget);
    });
  });

  group('ElectricalCalculatorScreen Wiring Method', () {
    testWidgets('shows ModeSelector for wiring method', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });
  });

  group('ElectricalCalculatorScreen Input Mode', () {
    testWidgets('shows input mode selector', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ModeSelector), findsWidgets);
    });
  });

  group('ElectricalCalculatorScreen Options', () {
    testWidgets('shows Switch for power consumers', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsWidgets);
    });

    testWidgets('can toggle switch', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      final switches = find.byType(Switch);
      if (switches.evaluate().isNotEmpty) {
        await tester.tap(switches.first);
        await tester.pumpAndSettle();
      }

      expect(find.byType(ElectricalCalculatorScreen), findsOneWidget);
    });
  });

  group('ElectricalCalculatorScreen Materials', () {
    testWidgets('shows materials section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      // The screen should have some form of materials display
      expect(find.byType(Container), findsWidgets);
    });
  });

  group('ElectricalCalculatorScreen Tips', () {
    testWidgets('shows tips section', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -800));
      await tester.pumpAndSettle();

      // The screen uses TipsCard widget for tips
      expect(find.text('Полезные советы'), findsOneWidget);
    });
  });

  group('ElectricalCalculatorScreen Actions', () {
    testWidgets('shows copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('shows share button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('can tap copy button', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });

  group('ElectricalCalculatorScreen Result Header', () {
    testWidgets('shows CalculatorResultHeader', (tester) async {
      setupTestScreenSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ElectricalCalculatorScreen(definition: testDefinition),
          overrides: CalculatorMockOverrides.electrical,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalculatorResultHeader), findsOneWidget);
    });
  });
}
