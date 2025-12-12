// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_linoleum.dart';

/// Калькулятор линолеума V2 с гибридным режимом ввода.
///
/// Согласно спецификации:
/// - Поддержка двух режимов ввода (по размерам / по площади)
/// - Расчет количества резов на основе ширины комнаты и ширины рулона
/// - Расчет аксессуаров: холодная сварка, клей, плинтус
final linoleumCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_linoleum',
  titleKey: calculatorTitleKey('floors_linoleum'),
  descriptionKey: calculatorDescriptionKey('floors_linoleum'),
  category: CalculatorCategory.interior,
  subCategory: 'Полы',
  iconName: 'layers',
  accentColor: kCalculatorAccentColor,
  complexity: 1,
  popularity: 85,
  tags: ['линолеум', 'полы', 'напольное покрытие', 'linoleum', 'flooring'],

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
      hintKey: 'input.length.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 50,
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
      hintKey: 'input.width.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.1,
      maxValue: 50,
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

    // --- Группа "По площади" ---
    const CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0,
      minValue: 0.5,
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
    const CalculatorField(
      key: 'roomWidth',
      labelKey: 'input.room_width',
      hintKey: 'input.room_width.hint',
      unitType: UnitType.meters,
      defaultValue: 0,
      minValue: 0.5,
      maxValue: 20,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      order: 4,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Общие поля ---
    const CalculatorField(
      key: 'rollWidth',
      labelKey: 'input.roll_width',
      hintKey: 'input.roll_width.hint',
      unitType: UnitType.meters,
      defaultValue: 3.0,
      minValue: 1.5,
      maxValue: 5.0,
      required: true,
      step: 0.5,
      iconName: 'straighten',
      order: 10,
    ),
    const CalculatorField(
      key: 'withGlue',
      labelKey: 'input.with_glue',
      hintKey: 'input.with_glue.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 0,
      order: 11,
    ),
    const CalculatorField(
      key: 'withPlinth',
      labelKey: 'input.with_plinth',
      hintKey: 'input.with_plinth.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 1,
      order: 12,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    const CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.linoleum.before.measure',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.linoleum.before.acclimatization',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.linoleum.before.level',
    ),
  ],

  // Подсказки после расчёта
  afterHints: [
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.linoleum.after.installation',
    ),
    const CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.linoleum.after.seams',
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateLinoleum(),
);
