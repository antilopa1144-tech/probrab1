// GENERATED FILE - do not edit by hand.
// CalculatorDefinitionV2 entries used by the app.

import '../../../core/enums/calculator_category.dart';
import '../../../core/enums/field_input_type.dart';
import '../../../core/enums/unit_type.dart';
import '../../models/calculator_definition_v2.dart';
import '../../models/calculator_field.dart';
import '../../models/calculator_hint.dart';
import '../calculator_constants.dart';
import '../../usecases/calculate_gutters.dart';

final List<CalculatorDefinitionV2> roofingCalculators = [
  CalculatorDefinitionV2(
      id: 'roofing_gutters',
      titleKey: 'calculator.roofing_gutters.title',
      descriptionKey: 'calculator.roofing_gutters.description',
      category: CalculatorCategory.exterior,
      subCategoryKey: 'subcategory.roofing',
      fields: [
        const CalculatorField(
          key: 'roofLength',
          labelKey: 'input.roofLength',
          unitType: UnitType.meters,
          inputType: FieldInputType.number,
          defaultValue: 10.0,
          minValue: 2.0,
          maxValue: 50.0,
          step: 0.5,
          iconName: 'straighten',
          group: 'dimensions',
          required: true,
          order: 1,
        ),
        const CalculatorField(
          key: 'roofArea',
          labelKey: 'input.roofArea',
          unitType: UnitType.squareMeters,
          inputType: FieldInputType.number,
          defaultValue: 50.0,
          minValue: 5.0,
          maxValue: 500.0,
          step: 1.0,
          iconName: 'square_foot',
          group: 'dimensions',
          required: true,
          order: 2,
        ),
        const CalculatorField(
          key: 'gutterLength',
          labelKey: 'input.gutterLength',
          unitType: UnitType.meters,
          inputType: FieldInputType.number,
          defaultValue: 3.0,
          minValue: 1.0,
          maxValue: 5.0,
          step: 0.5,
          iconName: 'straighten',
          group: 'material',
          required: true,
          order: 3,
        ),
      ],
      beforeHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.ustanavlivayte_zheloba_s_uklonom'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.kronshteyny_montiruyutsya_cherez_kazhdye'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.na_kazhdye_10_m'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.ispolzuyte_germetik_dlya_soedineniy'),
      ],
      afterHints: [
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.ustanavlivayte_zheloba_s_uklonom'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.kronshteyny_montiruyutsya_cherez_kazhdye'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.na_kazhdye_10_m'),
        const CalculatorHint(type: HintType.tip, messageKey: 'hint.roofing.ispolzuyte_germetik_dlya_soedineniy'),
      ],
      useCase: CalculateGutters(),
      accentColor: kCalculatorAccentColor,
      complexity: 3,
      popularity: 10,
      tags: [
        'roofing',
        'roofing_gutters',
        'tag.krovlya',
        'gutters',
        'tag.naruzhnaya_otdelka',
      ],
    ),
];