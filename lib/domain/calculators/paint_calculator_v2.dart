import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_wall_paint.dart';

/// Пример определения калькулятора краски с использованием новой модели.
final paintCalculatorV2 = CalculatorDefinitionV2(
  id: 'wall_paint',
  titleKey: 'calculator.wall_paint.title',
  descriptionKey: 'calculator.wall_paint.description',
  category: CalculatorCategory.wallFinishing,
  subCategory: 'paint',
  iconName: 'paint',
  accentColor: 0xFF4CAF50,
  complexity: 1,
  popularity: 100,
  tags: ['краска', 'стены', 'отделка', 'paint', 'walls'],

  // Поля ввода
  fields: [
    CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 1000,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 1,
    ),
    CalculatorField(
      key: 'windows_area',
      labelKey: 'input.windows_area',
      hintKey: 'input.windows_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0,
      maxValue: 100,
      required: false,
      step: 0.1,
      iconName: 'window',
      group: 'openings',
      order: 2,
    ),
    CalculatorField(
      key: 'doors_area',
      labelKey: 'input.doors_area',
      hintKey: 'input.doors_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0,
      maxValue: 50,
      required: false,
      step: 0.1,
      iconName: 'door_front',
      group: 'openings',
      order: 3,
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
      order: 4,
    ),
    CalculatorField(
      key: 'consumption',
      labelKey: 'input.consumption',
      hintKey: 'input.consumption.hint',
      unitType: UnitType.liters,
      defaultValue: 0.15,
      minValue: 0.08,
      maxValue: 0.5,
      required: false,
      step: 0.01,
      iconName: 'opacity',
      group: 'advanced',
      order: 5,
    ),
    CalculatorField(
      key: 'margin',
      labelKey: 'input.margin',
      hintKey: 'input.margin.hint',
      unitType: UnitType.percent,
      defaultValue: 10,
      minValue: 0,
      maxValue: 50,
      required: false,
      step: 5,
      iconName: 'add_circle_outline',
      group: 'advanced',
      order: 6,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.paint.before.measure',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.paint.before.primer',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.paint.large_area',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'area',
        value: 100,
      ),
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.paint.after.apply',
    ),
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.paint.after.ventilation',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.paint.high_consumption',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        resultKey: 'paint_liters',
        value: 50,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateWallPaint(),
);
