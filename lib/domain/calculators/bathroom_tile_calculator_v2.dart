import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_bathroom_tile.dart';

/// Калькулятор плитки для ванной V2.
final bathroomTileCalculatorV2 = CalculatorDefinitionV2(
  id: 'bathroom_tile',
  titleKey: 'calculator.bathroom_tile.title',
  descriptionKey: 'calculator.bathroom_tile.description',
  category: CalculatorCategory.wallFinishing,
  subCategory: 'tile',
  iconName: 'bathtub',
  accentColor: 0xFF00BCD4,
  complexity: 2,
  popularity: 95,
  tags: ['плитка', 'ванная', 'кафель', 'tile', 'bathroom'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'wallArea',
      labelKey: 'input.wallArea',
      hintKey: 'input.wallArea.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 0.5,
      iconName: 'wall',
      order: 1,
    ),
    CalculatorField(
      key: 'floorArea',
      labelKey: 'input.floorArea',
      hintKey: 'input.floorArea.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.0,
      maxValue: 50.0,
      required: false,
      step: 0.5,
      iconName: 'square_foot',
      order: 2,
    ),
    CalculatorField(
      key: 'tileWidth',
      labelKey: 'input.tileWidth',
      hintKey: 'input.tileWidth.hint',
      unitType: UnitType.centimeters,
      defaultValue: 30.0,
      minValue: 10.0,
      maxValue: 120.0,
      required: true,
      step: 1.0,
      iconName: 'straighten',
      group: 'dimensions',
      order: 3,
    ),
    CalculatorField(
      key: 'tileHeight',
      labelKey: 'input.tileHeight',
      hintKey: 'input.tileHeight.hint',
      unitType: UnitType.centimeters,
      defaultValue: 30.0,
      minValue: 10.0,
      maxValue: 120.0,
      required: true,
      step: 1.0,
      iconName: 'straighten',
      group: 'dimensions',
      order: 4,
    ),
    CalculatorField(
      key: 'jointWidth',
      labelKey: 'input.jointWidth',
      hintKey: 'input.jointWidth.hint',
      unitType: UnitType.millimeters,
      defaultValue: 3.0,
      minValue: 1.0,
      maxValue: 10.0,
      required: true,
      step: 0.5,
      iconName: 'straighten',
      group: 'advanced',
      order: 5,
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
      order: 6,
    ),
    CalculatorField(
      key: 'corners',
      labelKey: 'input.corners',
      hintKey: 'input.corners.hint',
      unitType: UnitType.meters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 50.0,
      required: false,
      step: 0.5,
      iconName: 'corner',
      group: 'advanced',
      order: 7,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.bathroom_tile.before.preparation',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.bathroom_tile.before.layout',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.bathroom_tile.before.waterproofing',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.bathroom_tile.after.grout',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.bathroom_tile.after.care',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateBathroomTile(),
);

