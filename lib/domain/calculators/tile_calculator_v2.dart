// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_tile.dart';

/// Калькулятор плитки V2.
final tileCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_tile',
  titleKey: calculatorTitleKey('floors_tile'),
  descriptionKey: calculatorDescriptionKey('floors_tile'),
  category: CalculatorCategory.flooring,
  subCategory: 'Полы',
  iconName: 'grid_view',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 95,
  tags: ['плитка', 'полы', 'кафель', 'tile', 'flooring', 'ceramic'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.5,
      maxValue: 500.0,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 1,
    ),
    CalculatorField(
      key: 'tileWidth',
      labelKey: 'input.tileWidth',
      hintKey: 'input.tileWidth.hint',
      unitType: UnitType.centimeters,
      defaultValue: 30.0,
      minValue: 1.0,
      maxValue: 200.0,
      required: true,
      step: 5.0,
      iconName: 'width_normal',
      group: 'tile',
      order: 2,
    ),
    CalculatorField(
      key: 'tileHeight',
      labelKey: 'input.tileHeight',
      hintKey: 'input.tileHeight.hint',
      unitType: UnitType.centimeters,
      defaultValue: 30.0,
      minValue: 1.0,
      maxValue: 200.0,
      required: true,
      step: 5.0,
      iconName: 'height',
      group: 'tile',
      order: 3,
    ),
    CalculatorField(
      key: 'jointWidth',
      labelKey: 'input.jointWidth',
      hintKey: 'input.jointWidth.hint',
      unitType: UnitType.millimeters,
      defaultValue: 3.0,
      minValue: 1.0,
      maxValue: 10.0,
      required: false,
      step: 1.0,
      iconName: 'border_style',
      group: 'tile',
      order: 4,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(type: HintType.info, messageKey: 'hint.tile.before.measure'),
    CalculatorHint(type: HintType.tip, messageKey: 'hint.tile.before.level'),
    CalculatorHint(type: HintType.tip, messageKey: 'hint.tile.before.crosses'),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(type: HintType.tip, messageKey: 'hint.tile.after.grout'),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.tile.after.adhesive',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.tile.after.installation',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateTile(),
);
