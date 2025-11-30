import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../../core/enums/field_input_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_warm_floor.dart';

/// Калькулятор тёплого пола V2.
final warmFloorCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_warm',
  titleKey: 'calculator.warm_floor.title',
  descriptionKey: 'calculator.warm_floor.description',
  category: CalculatorCategory.engineering,
  subCategory: 'heating',
  iconName: 'radiator',
  accentColor: 0xFFE91E63,
  complexity: 2,
  popularity: 90,
  tags: ['тёплый пол', 'отопление', 'электричество', 'heating', 'floor'],

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
      key: 'power',
      labelKey: 'input.power',
      hintKey: 'input.power.hint',
      unitType: UnitType.pieces,
      defaultValue: 150.0,
      minValue: 80.0,
      maxValue: 200.0,
      required: true,
      step: 10.0,
      iconName: 'bolt',
      group: 'advanced',
      order: 2,
    ),
    CalculatorField(
      key: 'type',
      labelKey: 'input.type',
      hintKey: 'input.type.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 2.0,
      required: true,
      iconName: 'category',
      group: 'advanced',
      order: 3,
      options: [
        FieldOption(value: 1.0, labelKey: 'input.type.cable'),
        FieldOption(value: 2.0, labelKey: 'input.type.mat'),
      ],
    ),
    CalculatorField(
      key: 'thermostats',
      labelKey: 'input.thermostats',
      hintKey: 'input.thermostats.hint',
      unitType: UnitType.pieces,
      defaultValue: 1,
      minValue: 1,
      maxValue: 10,
      required: true,
      step: 1,
      iconName: 'settings',
      group: 'advanced',
      order: 4,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.warm_floor.before.power',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.warm_floor.before.area',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.warm_floor.before.installation',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.warm_floor.after.thermostat',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.warm_floor.after.electricity',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateWarmFloor(),
);

