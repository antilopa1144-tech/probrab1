// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_slab.dart';

/// Калькулятор монолитной плиты V2.
final slabFoundationCalculatorV2 = CalculatorDefinitionV2(
  id: 'foundation_slab',
  titleKey: calculatorTitleKey('foundation_slab'),
  descriptionKey: calculatorDescriptionKey('foundation_slab'),
  category: CalculatorCategory.exterior,
  subCategoryKey: 'subcategory.slab',
  iconName: 'foundation',
  accentColor: kCalculatorAccentColor,
  complexity: 3,
  popularity: 85,
  tags: ['фундамент', 'плита', 'монолит', 'бетон', 'foundation', 'slab'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 50.0,
      minValue: 10.0,
      maxValue: 1000.0,
      required: true,
      step: 1.0,
      iconName: 'square_foot',
      order: 1,
    ),
    CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      hintKey: 'input.thickness.hint',
      unitType: UnitType.meters,
      defaultValue: 0.2,
      minValue: 0.1,
      maxValue: 0.5,
      required: true,
      step: 0.05,
      iconName: 'height',
      order: 2,
    ),
    CalculatorField(
      key: 'insulation',
      labelKey: 'input.insulationThickness',
      hintKey: 'input.insulationThickness.hint',
      unitType: UnitType.meters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 0.3,
      required: false,
      step: 0.01,
      iconName: 'layers',
      group: 'materials',
      order: 4,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.foundation.slab.before.min_thickness',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.foundation.slab.before.preparation',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.foundation.slab.before.waterproofing',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.foundation.slab.after.reinforcement',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.foundation.slab.after.insulation',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'insulation',
        value: 0,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateSlab(),
);
