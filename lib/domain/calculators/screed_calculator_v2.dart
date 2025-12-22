// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_screed.dart';

/// Калькулятор стяжки V2.
final screedCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_screed',
  titleKey: calculatorTitleKey('floors_screed'),
  descriptionKey: calculatorDescriptionKey('floors_screed'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.floors',
  iconName: 'construction',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 85,
  tags: ['стяжка', 'полы', 'бетон', 'цемент', 'screed', 'flooring'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 1.0,
      maxValue: 1000.0,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 1,
    ),
    CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      hintKey: 'input.thickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 50.0,
      minValue: 30.0,
      maxValue: 150.0,
      required: true,
      step: 5.0,
      iconName: 'height',
      group: 'parameters',
      order: 2,
    ),
    CalculatorField(
      key: 'cementGrade',
      labelKey: 'input.cementGrade',
      hintKey: 'input.cementGrade.hint',
      unitType: UnitType.pieces,
      defaultValue: 400.0,
      minValue: 300.0,
      maxValue: 600.0,
      required: false,
      complexityLevel: 2,
      step: 50.0,
      iconName: 'grade',
      group: 'parameters',
      order: 3,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(type: HintType.info, messageKey: 'hint.screed.before.level'),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.screed.before.beacons',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.screed.before.thickness',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'thickness',
        value: 50,
      ),
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.screed.after.curing',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.screed.after.reinforcement',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'thickness',
        value: 50,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateScreed(),
);
