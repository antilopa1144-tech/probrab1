// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_strip_foundation.dart';

/// Калькулятор ленточного фундамента V2.
final stripFoundationCalculatorV2 = CalculatorDefinitionV2(
  id: 'foundation_strip',
  titleKey: calculatorTitleKey('foundation_strip'),
  descriptionKey: calculatorDescriptionKey('foundation_strip'),
  category: CalculatorCategory.exterior,
  subCategory: 'strip',
  iconName: 'foundation',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 90,
  tags: ['фундамент', 'ленточный', 'бетон', 'арматура', 'foundation', 'strip'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 10000,
      required: true,
      step: 1.0,
      iconName: 'square_foot',
      order: 0,
    ),
    CalculatorField(
      key: 'perimeter',
      labelKey: 'input.perimeter',
      hintKey: 'input.perimeter.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 10000,
      required: false,
      step: 0.5,
      iconName: 'straighten',
      order: 1,
    ),
    CalculatorField(
      key: 'width',
      labelKey: 'input.width',
      hintKey: 'input.width.hint',
      unitType: UnitType.meters,
      defaultValue: 0.4,
      minValue: 0.2,
      maxValue: 3.0,
      required: true,
      step: 0.05,
      iconName: 'straighten',
      order: 2,
    ),
    CalculatorField(
      key: 'height',
      labelKey: 'input.height',
      hintKey: 'input.height.hint',
      unitType: UnitType.meters,
      defaultValue: 0.6,
      minValue: 0.3,
      maxValue: 3.0,
      required: true,
      step: 0.1,
      iconName: 'height',
      order: 3,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.foundation.strip.before.preparation',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.foundation.strip.before.cushion',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.foundation.strip.before.formwork',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'perimeter',
        value: 50,
      ),
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.foundation.strip.after.reinforcement',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.foundation.strip.after.curing',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.foundation.strip.after.large_volume',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        resultKey: 'concreteVolume',
        value: 20,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateStripFoundation(),
);
