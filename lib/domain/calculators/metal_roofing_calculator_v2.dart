import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_roofing_metal.dart';

/// Калькулятор металлической кровли V2.
final metalRoofingCalculatorV2 = CalculatorDefinitionV2(
  id: 'roofing_metal',
  titleKey: 'calculator.metal_roofing.title',
  descriptionKey: 'calculator.metal_roofing.description',
  category: CalculatorCategory.roofing,
  subCategory: 'metal',
  iconName: 'roof',
  accentColor: 0xFF607D8B,
  complexity: 2,
  popularity: 85,
  tags: ['кровля', 'металл', 'профлист', 'roofing', 'metal'],

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
      key: 'sheetWidth',
      labelKey: 'input.sheetWidth',
      hintKey: 'input.sheetWidth.hint',
      unitType: UnitType.meters,
      defaultValue: 1.18,
      minValue: 0.5,
      maxValue: 1.5,
      required: true,
      step: 0.01,
      iconName: 'straighten',
      group: 'dimensions',
      order: 3,
    ),
    CalculatorField(
      key: 'sheetLength',
      labelKey: 'input.sheetLength',
      hintKey: 'input.sheetLength.hint',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      minValue: 1.0,
      maxValue: 8.0,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      group: 'dimensions',
      order: 4,
    ),
    CalculatorField(
      key: 'ridgeLength',
      labelKey: 'input.ridgeLength',
      hintKey: 'input.ridgeLength.hint',
      unitType: UnitType.meters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 0.5,
      iconName: 'straighten',
      group: 'advanced',
      order: 5,
    ),
    CalculatorField(
      key: 'valleyLength',
      labelKey: 'input.valleyLength',
      hintKey: 'input.valleyLength.hint',
      unitType: UnitType.meters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 0.5,
      iconName: 'straighten',
      group: 'advanced',
      order: 6,
    ),
    CalculatorField(
      key: 'perimeter',
      labelKey: 'input.perimeter',
      hintKey: 'input.perimeter.hint',
      unitType: UnitType.meters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 200.0,
      required: false,
      step: 0.5,
      iconName: 'straighten',
      group: 'advanced',
      order: 7,
    ),
    CalculatorField(
      key: 'endLength',
      labelKey: 'input.endLength',
      hintKey: 'input.endLength.hint',
      unitType: UnitType.meters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 0.5,
      iconName: 'straighten',
      group: 'advanced',
      order: 8,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.roofing.metal.before.slope',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.metal.before.overlap',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.roofing.metal.before.waterproofing',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.roofing.metal.after.screws',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.roofing.metal.after.installation',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateRoofingMetal(),
);

