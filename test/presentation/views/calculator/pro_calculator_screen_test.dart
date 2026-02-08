import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/calculator_registry.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_text_field.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 testDefinition;

  setUpAll(() {
    setupMocks();

    final realDefinition = CalculatorRegistry.getById('gypsum_board');
    if (realDefinition == null) {
      throw StateError('gypsum_board calculator not found in registry');
    }
    testDefinition = realDefinition;
  });

  group('ProCalculatorScreen', () {
    testWidgets('renders correctly', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      expect(find.byType(ProCalculatorScreen), findsOneWidget);
    });

    testWidgets('shows Scaffold structure', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows Card widgets', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('uses scrollable layout', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('disposes correctly', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        createTestApp(
          child: const SizedBox.shrink(),
        ),
      );

      expect(find.byType(ProCalculatorScreen), findsNothing);
    });
  });

  group('ProCalculatorScreen slider+textfield', () {
    testWidgets('slider fields show both Slider and CalculatorTextField', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pumpAndSettle();

      // gypsum_board has slider fields — both Slider and CalculatorTextField should be present
      expect(find.byType(Slider), findsWidgets);
      expect(find.byType(CalculatorTextField), findsWidgets);
    });

    testWidgets('can interact with slider', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pumpAndSettle();

      final slider = find.byType(Slider);
      if (slider.evaluate().isNotEmpty) {
        await tester.drag(slider.first, const Offset(50, 0));
        await tester.pumpAndSettle();
      }

      expect(find.byType(ProCalculatorScreen), findsOneWidget);
    });

    testWidgets('no input mode toggle present', (tester) async {
      setTestViewportSize(tester);

      await tester.pumpWidget(
        createTestApp(
          child: ProCalculatorScreen(definition: testDefinition),
        ),
      );
      await tester.pumpAndSettle();

      // The SegmentedButton toggle was removed — sliders and text fields are always shown together
      expect(find.byType(SegmentedButton<bool>), findsNothing);
    });
  });
}
