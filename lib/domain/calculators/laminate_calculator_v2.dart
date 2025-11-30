import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_laminate.dart';

/// Калькулятор ламината V2.
final laminateCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_laminate',
  titleKey: 'calculator.laminate',
  descriptionKey: 'calculator.laminate.description',
  category: CalculatorCategory.flooring,
  subCategory: 'Полы',
  iconName: 'flooring',
  accentColor: 0xFF2196F3, // Единый цвет для всех калькуляторов
  complexity: 1,
  popularity: 90,
  tags: ['ламинат', 'полы', 'напольное покрытие', 'laminate', 'flooring'],

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
      key: 'packArea',
      labelKey: 'input.packArea',
      hintKey: 'input.packArea.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 2.0,
      minValue: 0.1,
      maxValue: 10.0,
      required: true,
      step: 0.1,
      iconName: 'inventory',
      group: 'material',
      order: 2,
    ),
    CalculatorField(
      key: 'underlayThickness',
      labelKey: 'input.underlayThickness',
      hintKey: 'input.underlayThickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 3.0,
      minValue: 2.0,
      maxValue: 5.0,
      required: false,
      step: 1.0,
      iconName: 'layers',
      group: 'material',
      order: 3,
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
      group: 'additional',
      order: 4,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.laminate.before.measure',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.laminate.before.underlay',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.laminate.before.level',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.laminate.after.wedges',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.laminate.after.acclimatization',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.laminate.after.installation',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateLaminate(),
);

