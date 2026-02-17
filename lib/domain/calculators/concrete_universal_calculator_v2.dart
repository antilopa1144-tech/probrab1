import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_concrete_universal.dart';
import 'calculator_constants.dart';

final concreteUniversalCalculatorV2 = CalculatorDefinitionV2(
  id: 'concrete_universal',
  titleKey: 'calculator.concrete_universal.title',
  descriptionKey: 'calculator.concrete_universal.description',
  category: CalculatorCategory.exterior,
  subCategoryKey: 'subcategory.concrete',
  tags: ['бетон', 'замес', 'цемент', 'песок', 'щебень', 'concrete'],
  accentColor: kCalculatorAccentColor,
  useCase: CalculateConcreteUniversal(),
  fields: const [
    CalculatorField(
      key: 'concreteVolume',
      labelKey: 'input.concreteVolume',
      hintKey: 'input.concreteVolume.hint',
      unitType: UnitType.cubicMeters,
      defaultValue: 1.0,
      required: true,
      minValue: 0.01,
      maxValue: 1000.0,
    ),
    CalculatorField(
      key: 'concreteGrade',
      labelKey: 'input.concreteGrade',
      hintKey: 'input.concreteGrade.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 3,
      required: true,
      options: [
        FieldOption(value: 1, labelKey: 'input.concreteGrade.m100'),
        FieldOption(value: 2, labelKey: 'input.concreteGrade.m150'),
        FieldOption(value: 3, labelKey: 'input.concreteGrade.m200'),
        FieldOption(value: 4, labelKey: 'input.concreteGrade.m250'),
        FieldOption(value: 5, labelKey: 'input.concreteGrade.m300'),
        FieldOption(value: 6, labelKey: 'input.concreteGrade.m350'),
        FieldOption(value: 7, labelKey: 'input.concreteGrade.m400'),
      ],
    ),
    CalculatorField(
      key: 'manualMix',
      labelKey: 'input.manualMix',
      hintKey: 'input.manualMix.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 0.0,
      required: false,
    ),
    CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      unitType: UnitType.percent,
      defaultValue: 5.0,
      required: false,
    ),
  ],
  beforeHints: const [
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.concrete.before.reserve',
    ),
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.concrete.before.grade',
    ),
  ],
  afterHints: const [
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.concrete.after.curing',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.concrete.after.temperature',
    ),
    // М100-М150: подготовка, подушка, стяжка по грунту
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.concrete.grade_low_use',
      condition: HintCondition(
        type: HintConditionType.inRange,
        fieldKey: 'concreteGrade',
        range: (1, 2),
      ),
    ),
    // М200: стяжка, отмостка, дорожки
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.concrete.grade_m200_use',
      condition: HintCondition(
        type: HintConditionType.equals,
        fieldKey: 'concreteGrade',
        value: 3,
      ),
    ),
    // М250-М300: фундаменты, несущие конструкции
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.concrete.grade_mid_use',
      condition: HintCondition(
        type: HintConditionType.inRange,
        fieldKey: 'concreteGrade',
        range: (4, 5),
      ),
    ),
    // М350-М400: ответственные конструкции, бассейны
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.concrete.grade_high_use',
      condition: HintCondition(
        type: HintConditionType.inRange,
        fieldKey: 'concreteGrade',
        range: (6, 7),
      ),
    ),
  ],
);
