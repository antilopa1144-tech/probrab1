// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_parquet.dart';

/// Калькулятор паркета V2.
final parquetCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_parquet',
  titleKey: calculatorTitleKey('floors_parquet'),
  descriptionKey: calculatorDescriptionKey('floors_parquet'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.wood',
  iconName: 'park',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 75,
  tags: ['паркет', 'массив', 'дерево', 'parquet', 'wood'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 1.0,
      maxValue: 500.0,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 1,
    ),
    CalculatorField(
      key: 'plankWidth',
      labelKey: 'input.plankWidth',
      hintKey: 'input.plankWidth.hint',
      unitType: UnitType.centimeters,
      defaultValue: 7.0,
      minValue: 5.0,
      maxValue: 20.0,
      required: true,
      step: 0.5,
      iconName: 'straighten',
      group: 'dimensions',
      order: 2,
    ),
    CalculatorField(
      key: 'plankLength',
      labelKey: 'input.plankLength',
      hintKey: 'input.plankLength.hint',
      unitType: UnitType.centimeters,
      defaultValue: 40.0,
      minValue: 20.0,
      maxValue: 100.0,
      required: true,
      step: 1.0,
      iconName: 'straighten',
      group: 'dimensions',
      order: 3,
    ),
    CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      hintKey: 'input.thickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 15.0,
      minValue: 10.0,
      maxValue: 22.0,
      required: true,
      step: 1.0,
      iconName: 'height',
      group: 'dimensions',
      order: 4,
    )],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.parquet.before.acclimatization',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.parquet.before.installation',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.parquet.after.varnish',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.parquet.after.care',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateParquet(),
);
