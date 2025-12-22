// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_gkl_wall.dart';

/// Калькулятор обшивки стен ГКЛ (гипсокартон) V2 с гибридным режимом ввода.
///
/// Согласно спецификации:
/// - Направляющий профиль (PN/UD): Периметр × 2 (пол + потолок)
/// - Стоечный профиль (PS/CD): WallLength / 0.6м → Метры + Штуки (3м)
/// - Листы: Площадь / 3.0 м²
/// - Крепеж: раздельно "Металл-Металл" (блошки) и "ГКЛ-Металл" (25мм)
final gklWallCalculatorV2 = CalculatorDefinitionV2(
  id: 'walls_gkl',
  titleKey: calculatorTitleKey('walls_gkl'),
  descriptionKey: calculatorDescriptionKey('walls_gkl'),
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.walls',
  iconName: 'dashboard_customize',
  accentColor: kCalculatorAccentColor,
  complexity: 3,
  popularity: 80,
  tags: ['гипсокартон', 'гкл', 'стены', 'обшивка', 'drywall', 'gypsum'],

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
      key: 'wallLength',
      labelKey: 'input.wall_length',
      hintKey: 'input.wall_length.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.5,
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
      key: 'wallHeight',
      labelKey: 'input.wall_height',
      hintKey: 'input.wall_height.hint',
      unitType: UnitType.meters,
      defaultValue: 2.7,
      minValue: 2.0,
      maxValue: 6.0,
      required: true,
      step: 0.1,
      iconName: 'height',
      group: 'dimensions',
      order: 2,
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
      minValue: 1.0,
      maxValue: 500,
      required: true,
      step: 0.5,
      iconName: 'square_foot',
      order: 3,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Общие поля ---
    const CalculatorField(
      key: 'profileStep',
      labelKey: 'input.profile_step',
      hintKey: 'input.profile_step.hint',
      unitType: UnitType.centimeters,
      inputType: FieldInputType.select,
      defaultValue: 60,
      options: [
        FieldOption(value: 40, labelKey: 'input.profile_step.40cm'),
        FieldOption(value: 60, labelKey: 'input.profile_step.60cm'),
      ],
      order: 10,
    ),
    const CalculatorField(
      key: 'layers',
      labelKey: 'input.gkl_layers',
      hintKey: 'input.gkl_layers.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.slider,
      defaultValue: 1,
      minValue: 1,
      maxValue: 2,
      step: 1,
      order: 11,
    ),
    const CalculatorField(
      key: 'doubleSided',
      labelKey: 'input.double_sided',
      hintKey: 'input.double_sided.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 0,
      order: 12,
    ),

    // --- Группа "Проёмы" ---
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
      order: 20,
    ),
    const CalculatorField(
      key: 'doorsArea',
      labelKey: 'input.doors_area',
      hintKey: 'input.doors_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0,
      maxValue: 20,
      required: false,
      step: 0.1,
      iconName: 'door_front',
      group: 'openings',
      order: 21,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    const CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.gkl_wall.before.measure',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.gkl_wall.before.profile_step',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.gkl_wall.before.level',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    const CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.gkl_wall.after.installation',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.gkl_wall.after.joints',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.gkl_wall.after.screws',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateGklWall(),
);
