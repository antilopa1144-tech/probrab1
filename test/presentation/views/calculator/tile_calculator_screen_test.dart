import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/tile_calculator_screen.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_widgets.dart';

import '../../../helpers/calculator_test_helpers.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  late CalculatorDefinitionV2 definition;

  setUpAll(() {
    setupMocks();
    definition = getCalculatorDefinition('floors_tile');
  });

  testWidgets(
    'restores label packaging and keeps canonical values on a phone',
    (tester) async {
      setupTestScreenSize(tester, size: const Size(390, 844));

      await tester.pumpWidget(
        createTestApp(
          child: TileCalculatorScreen(
            definition: definition,
            initialInputs: const {
              'inputMode': 1,
              'area': 20,
              'tileWidthCm': 60,
              'tileHeightCm': 30,
              'packagingMode': 1,
              'packArea': 12,
              'tilesPerPackage': 150,
              'layoutPattern': 4,
              'roomComplexity': 3,
            },
          ),
          overrides: CalculatorMockOverrides.tile,
        ),
      );
      await pumpCalculatorWidget(tester);

      final packagingFieldFinder = find.byWidgetPredicate(
        (widget) =>
            widget is CalculatorSliderField &&
            widget.label == 'Плиток в коробке',
      );
      expect(packagingFieldFinder, findsOneWidget);

      final packagingField = tester.widget<CalculatorSliderField>(
        packagingFieldFinder,
      );
      expect(packagingField.value, 150);
      expect(packagingField.max, 500);

      final scaffold = tester.widget<CalculatorScaffold>(
        find.byType(CalculatorScaffold),
      );
      final savedInputs = scaffold.mikhalychDataCollector!();

      expect(savedInputs['inputMode'], 1);
      expect(savedInputs['tileWidthCm'], 60);
      expect(savedInputs['tileHeightCm'], 30);
      expect(savedInputs['packagingMode'], 1);
      expect(savedInputs['tilesPerPackage'], 150);
      expect(savedInputs['layoutPattern'], 4);
      expect(savedInputs['roomComplexity'], 3);
      expect(tester.takeException(), isNull);
    },
  );
}
