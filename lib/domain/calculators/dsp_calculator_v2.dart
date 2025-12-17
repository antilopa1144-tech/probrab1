// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_dsp.dart';

/// Определение калькулятора цементно-песчаной смеси (ЦПС) / стяжки пола.
final dspCalculatorV2 = CalculatorDefinitionV2(
  id: 'dsp',
  titleKey: calculatorTitleKey('dsp'),
  descriptionKey: calculatorDescriptionKey('dsp'),
  category: CalculatorCategory.interior,
  subCategory: 'flooring',
  iconName: 'layers',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 85,
  tags: ['цпс', 'стяжка', 'пол', 'штукатурка', 'смесь', 'пескобетон', 'dsp', 'screed', 'floor', 'plaster'],

  // Поля ввода
  fields: [
    // --- Переключатель режима ввода ---
    const CalculatorField(
      key: 'inputMode',
      labelKey: 'input.mode',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.mode.by_dimensions'),
        FieldOption(value: 1, labelKey: 'input.mode.by_area'),
      ],
      order: 0,
    ),

    // --- Группа "По размерам" ---
    const CalculatorField(
      key: 'length',
      labelKey: 'input.length',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 100,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      group: 'dimensions',
      order: 1,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 0,
      ),
    ),
    const CalculatorField(
      key: 'width',
      labelKey: 'input.width',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 100,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      group: 'dimensions',
      order: 2,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 0,
      ),
    ),
    const CalculatorField(
      key: 'height',
      labelKey: 'input.height',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      minValue: 0.1,
      maxValue: 10,
      required: true,
      step: 0.05,
      iconName: 'height',
      group: 'dimensions',
      order: 3,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 0,
      ),
    ),

    // --- Группа "По площади" ---
    const CalculatorField(
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
      order: 4,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),
    const CalculatorField(
      key: 'perimeter',
      labelKey: 'input.perimeter',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 500,
      required: true,
      step: 0.1,
      iconName: 'zoom_out_map',
      order: 5,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Тип работ ---
    const CalculatorField(
      key: 'applicationType',
      labelKey: 'input.application_type',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.application_type.floor'),
        FieldOption(value: 1, labelKey: 'input.application_type.walls'),
      ],
      order: 10,
    ),

    // --- Марка смеси ---
    const CalculatorField(
      key: 'mixType',
      labelKey: 'input.mix_type',
      hintKey: 'input.mix_type.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.mix_type.m300'),
        FieldOption(value: 1, labelKey: 'input.mix_type.m150'),
      ],
      order: 11,
    ),

    // --- Толщина слоя ---
    const CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      hintKey: 'input.thickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 40,
      minValue: 1,
      maxValue: 200,
      required: true,
      step: 1,
      iconName: 'height',
      order: 12,
    ),

    // --- Вес мешка ---
    const CalculatorField(
      key: 'bagWeight',
      labelKey: 'input.bag_weight',
      hintKey: 'input.bag_weight.hint',
      unitType: UnitType.kilograms,
      defaultValue: 40,
      minValue: 1,
      maxValue: 100,
      required: true,
      step: 1,
      iconName: 'shopping_bag',
      group: 'advanced',
      order: 20,
    ),

    // --- Группа "Проёмы" (только для стен) ---
    const CalculatorField(
      key: 'windowsArea',
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
      order: 30,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'applicationType',
        value: 1,
      ),
    ),
    const CalculatorField(
      key: 'doorsArea',
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
      order: 31,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'applicationType',
        value: 1,
      ),
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    const CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.dsp.before.measure',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.dsp.before.mix_choice',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.dsp.before.thin_screed',
      condition: HintCondition(
        type: HintConditionType.lessThan,
        fieldKey: 'thickness',
        value: 30,
      ),
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.dsp.after.curing',
    ),
    const CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.dsp.after.temperature',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.dsp.after.crack_warning',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        resultKey: 'thicknessWarning',
        value: 0,
      ),
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.dsp.after.reinforcement',
      condition: HintCondition(
        type: HintConditionType.equals,
        resultKey: 'applicationType',
        value: 0, // только для пола
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateDsp(),

  showToolsSection: true,
);
