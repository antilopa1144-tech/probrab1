import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_soft_roofing.dart';

/// Калькулятор мягкой кровли V2.
final softRoofingCalculatorV2 = CalculatorDefinitionV2(
  id: 'roofing_soft',
  titleKey: 'calculator.soft_roofing.title',
  descriptionKey: 'calculator.soft_roofing.description',
  category: CalculatorCategory.roofing,
  subCategory: 'soft',
  iconName: 'roof',
  accentColor: 0xFF2196F3, // Единый цвет для всех калькуляторов
  complexity: 2,
  popularity: 80,
  tags: ['кровля', 'мягкая', 'битум', 'рулонная', 'roofing', 'soft'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 10.0,
      maxValue: 1000.0,
      required: true,
      step: 1.0,
      iconName: 'square_foot',
      order: 1,
    ),
    CalculatorField(
      key: 'slope',
      labelKey: 'input.slope',
      hintKey: 'input.slope.hint',
      unitType: UnitType.percent,
      defaultValue: 30.0,
      minValue: 12.0,
      maxValue: 60.0,
      required: true,
      step: 1.0,
      iconName: 'height',
      order: 2,
    ),
    CalculatorField(
      key: 'layers',
      labelKey: 'input.layers',
      hintKey: 'input.layers.hint',
      unitType: UnitType.pieces,
      defaultValue: 2,
      minValue: 1,
      maxValue: 5,
      required: true,
      step: 1,
      iconName: 'layers',
      order: 3,
    ),
    CalculatorField(
      key: 'rollWidth',
      labelKey: 'input.rollWidth',
      hintKey: 'input.rollWidth.hint',
      unitType: UnitType.meters,
      defaultValue: 1.0,
      minValue: 0.5,
      maxValue: 2.0,
      required: false,
      step: 0.1,
      iconName: 'straighten',
      group: 'dimensions',
      order: 4,
    ),
    CalculatorField(
      key: 'rollLength',
      labelKey: 'input.rollLength',
      hintKey: 'input.rollLength.hint',
      unitType: UnitType.meters,
      defaultValue: 10.0,
      minValue: 5.0,
      maxValue: 20.0,
      required: false,
      step: 0.5,
      iconName: 'straighten',
      group: 'dimensions',
      order: 5,
    ),
    CalculatorField(
      key: 'overlap',
      labelKey: 'input.overlap',
      hintKey: 'input.overlap.hint',
      unitType: UnitType.centimeters,
      defaultValue: 10.0,
      minValue: 5.0,
      maxValue: 20.0,
      required: false,
      step: 1.0,
      iconName: 'layers',
      group: 'advanced',
      order: 6,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.roofing.soft.before.preparation',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.soft.before.layers',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.roofing.soft.before.slope',
      condition: HintCondition(
        type: HintConditionType.lessThan,
        fieldKey: 'slope',
        value: 5,
      ),
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.soft.after.installation',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.roofing.soft.after.overlap',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateSoftRoofing(),
);

