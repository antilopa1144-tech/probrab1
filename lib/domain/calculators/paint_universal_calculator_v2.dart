// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_paint_universal.dart';

/// Универсальный калькулятор покраски (стены, потолок, или всё вместе).
/// Простой и понятный интерфейс без лишних полей.
final paintUniversalCalculatorV2 = CalculatorDefinitionV2(
  id: 'paint_universal',
  titleKey: calculatorTitleKey('paint'),
  descriptionKey: calculatorDescriptionKey('paint'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.paint',
  iconName: 'format_paint',
  accentColor: kCalculatorAccentColor,
  complexity: 1,
  popularity: 100,
  tags: ['краска', 'стены', 'потолок', 'отделка', 'paint', 'walls', 'ceiling'],

  fields: [
    // Что красим: стены / потолок / всё
    const CalculatorField(
      key: 'paintType',
      labelKey: 'input.paint.type',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.paint.type.walls'),
        FieldOption(value: 1, labelKey: 'input.paint.type.ceiling'),
        FieldOption(value: 2, labelKey: 'input.paint.type.both'),
      ],
      order: 0,
    ),

    // Режим ввода: площадь или размеры комнаты
    const CalculatorField(
      key: 'inputMode',
      labelKey: 'input.mode',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.mode.by_area'),
        FieldOption(value: 1, labelKey: 'input.mode.by_dimensions'),
      ],
      order: 1,
    ),

    // --- Режим "По площади" - Площадь стен ---
    // Показываем только если: режим = по площади И (красим стены ИЛИ красим всё)
    const CalculatorField(
      key: 'wallArea',
      labelKey: 'input.paint.wall_area',
      hintKey: 'input.paint.wall_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 40,
      minValue: 1,
      maxValue: 500,
      step: 1,
      order: 10,
      dependencies: [
        FieldDependency(
          condition: DependencyCondition.equals,
          fieldKey: 'inputMode',
          value: 0,
        ),
        FieldDependency(
          condition: DependencyCondition.notEquals,
          fieldKey: 'paintType',
          value: 1, // не показываем, если выбран только потолок
        ),
      ],
    ),

    // --- Режим "По площади" - Площадь потолка ---
    // Показываем только если: режим = по площади И (красим потолок ИЛИ красим всё)
    const CalculatorField(
      key: 'ceilingArea',
      labelKey: 'input.paint.ceiling_area',
      hintKey: 'input.paint.ceiling_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 20,
      minValue: 1,
      maxValue: 500,
      step: 1,
      order: 11,
      dependencies: [
        FieldDependency(
          condition: DependencyCondition.equals,
          fieldKey: 'inputMode',
          value: 0,
        ),
        FieldDependency(
          condition: DependencyCondition.notEquals,
          fieldKey: 'paintType',
          value: 0, // не показываем, если выбраны только стены
        ),
      ],
    ),

    // --- Режим "По размерам комнаты" ---
    const CalculatorField(
      key: 'length',
      labelKey: 'input.room_length',
      unitType: UnitType.meters,
      defaultValue: 5,
      minValue: 1,
      maxValue: 50,
      step: 0.1,
      group: 'dimensions',
      order: 20,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),
    const CalculatorField(
      key: 'width',
      labelKey: 'input.room_width',
      unitType: UnitType.meters,
      defaultValue: 4,
      minValue: 1,
      maxValue: 50,
      step: 0.1,
      group: 'dimensions',
      order: 21,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),
    const CalculatorField(
      key: 'height',
      labelKey: 'input.room_height',
      unitType: UnitType.meters,
      defaultValue: 2.7,
      minValue: 2,
      maxValue: 5,
      step: 0.1,
      group: 'dimensions',
      order: 22,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // Проёмы (только для стен, не показываем если выбран только потолок)
    const CalculatorField(
      key: 'doorsWindows',
      labelKey: 'input.paint.doors_windows',
      hintKey: 'input.paint.doors_windows.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 5,
      minValue: 0,
      maxValue: 50,
      step: 0.5,
      group: 'openings',
      order: 30,
      dependency: FieldDependency(
        condition: DependencyCondition.notEquals,
        fieldKey: 'paintType',
        value: 1, // не показываем, если выбран только потолок
      ),
    ),

    // Подготовка поверхности
    const CalculatorField(
      key: 'surfacePrep',
      labelKey: 'input.paint.surfacePrep',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 1,
      options: [
        FieldOption(value: 1, labelKey: 'input.paint.surfacePrep.primed'),
        FieldOption(value: 2, labelKey: 'input.paint.surfacePrep.raw'),
        FieldOption(value: 3, labelKey: 'input.paint.surfacePrep.repainted'),
      ],
      group: 'conditions',
      order: 35,
    ),

    // Интенсивность цвета
    const CalculatorField(
      key: 'colorIntensity',
      labelKey: 'input.paint.colorIntensity',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 1,
      options: [
        FieldOption(value: 1, labelKey: 'input.paint.colorIntensity.light'),
        FieldOption(value: 2, labelKey: 'input.paint.colorIntensity.bright'),
        FieldOption(value: 3, labelKey: 'input.paint.colorIntensity.dark'),
      ],
      group: 'conditions',
      order: 36,
    ),

    // Количество слоёв
    const CalculatorField(
      key: 'layers',
      labelKey: 'input.paint.layers',
      hintKey: 'input.paint.layers.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.slider,
      defaultValue: 2,
      minValue: 1,
      maxValue: 4,
      step: 1,
      order: 40,
    ),

    // Расход (л/м2) - Moved out of advanced group for visibility
    const CalculatorField(
      key: 'consumption',
      labelKey: 'input.consumption',
      hintKey: 'input.consumption.hint',
      unitType: UnitType.litersPerSqm,
      defaultValue: 0.12,
      minValue: 0.05,
      maxValue: 0.5,
      step: 0.01,
      order: 41,
    ),

    // Запас
    const CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      unitType: UnitType.percent,
      inputType: FieldInputType.slider,
      defaultValue: 10,
      minValue: 0,
      maxValue: 25,
      step: 5,
      group: 'advanced',
      order: 50,
    ),
  ],

  beforeHints: [
    const CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.paint.before.prepare',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.paint.before.primer',
    ),
  ],

  afterHints: [
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.paint.after.apply',
    ),
    const CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.paint.after.drying',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.paint.dark_color_extra_coats',
      condition: HintCondition(
        type: HintConditionType.equals,
        fieldKey: 'colorIntensity',
        value: 3,
      ),
    ),
  ],

  useCase: CalculatePaintUniversal(),
  showToolsSection: true,
);
