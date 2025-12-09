// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_gkl_ceiling.dart';

/// Калькулятор потолка из ГКЛ V2.
final gklCeilingCalculatorV2 = CalculatorDefinitionV2(
  id: 'ceilings_gkl',
  titleKey: calculatorTitleKey('ceilings_gkl'),
  descriptionKey: calculatorDescriptionKey('ceilings_gkl'),
  category: CalculatorCategory.ceilings,
  subCategory: 'gkl',
  iconName: 'ceiling',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 85,
  tags: ['потолок', 'гкл', 'гипсокартон', 'ceiling', 'gkl'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 1.0,
      maxValue: 200.0,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 1,
    ),
    CalculatorField(
      key: 'layers',
      labelKey: 'input.layers',
      hintKey: 'input.layers.hint',
      unitType: UnitType.pieces,
      defaultValue: 1,
      minValue: 1,
      maxValue: 2,
      required: true,
      step: 1,
      iconName: 'layers',
      order: 2,
    ),
    CalculatorField(
      key: 'ceilingHeight',
      labelKey: 'input.ceilingHeight',
      hintKey: 'input.ceilingHeight.hint',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      minValue: 2.0,
      maxValue: 4.0,
      required: true,
      step: 0.1,
      iconName: 'height',
      group: 'dimensions',
      order: 3,
    ),
    CalculatorField(
      key: 'dropHeight',
      labelKey: 'input.dropHeight',
      hintKey: 'input.dropHeight.hint',
      unitType: UnitType.meters,
      defaultValue: 0.1,
      minValue: 0.05,
      maxValue: 0.5,
      required: true,
      step: 0.05,
      iconName: 'height',
      group: 'dimensions',
      order: 4,
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
      order: 5,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.gkl_ceiling.before.profiles',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.gkl_ceiling.before.layers',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.gkl_ceiling.after.installation',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.gkl_ceiling.after.joints',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateGklCeiling(),
);
