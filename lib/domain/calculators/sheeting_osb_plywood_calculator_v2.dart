import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../../core/enums/field_input_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_sheeting_osb_plywood.dart';
import 'calculator_constants.dart';

/// Калькулятор ОСБ плит V2.
final sheetingOsbPlywoodCalculatorV2 = CalculatorDefinitionV2(
  id: 'sheeting_osb_plywood',
  titleKey: 'calculator.sheeting_osb_plywood.title',
  descriptionKey: 'calculator.sheeting_osb_plywood.description',
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.osb_plywood',
  iconName: 'layers',
  accentColor: kCalculatorAccentColor,
  complexity: 1,
  popularity: 85,
  tags: ['осб', 'осп', 'лист', 'обшивка', 'пол', 'крыша'],

  // Поля ввода
  fields: [
    // --- Переключатель режима ввода ---
    const CalculatorField(
      key: 'inputMode',
      labelKey: 'input.mode',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 1,
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
      defaultValue: 4,
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
      defaultValue: 2.5,
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

    // --- Группа "По площади" ---
    const CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 10,
      minValue: 0.1,
      maxValue: 10000.0,
      required: true,
      step: 1,
      iconName: 'square_foot',
      order: 3,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Группа "Характеристики плиты" ---
    const CalculatorField(
      key: 'sheetSize',
      labelKey: 'input.sheetSize',
      hintKey: 'input.sheetSize.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 1,
      required: true,
      iconName: 'crop_landscape',
      group: 'sheet',
      order: 10,
      options: [
        FieldOption(value: 1, labelKey: 'input.sheetSize.2500x1250'), // 3.125 м² - стандарт
        FieldOption(value: 2, labelKey: 'input.sheetSize.2500x625'), // 1.56 м² - шпунт для полов
        FieldOption(value: 3, labelKey: 'input.sheetSize.2800x1250'), // 3.5 м² - высокие стены
        FieldOption(value: 4, labelKey: 'input.sheetSize.3000x1250'), // 3.75 м² - высокие стены
        FieldOption(value: 5, labelKey: 'input.sheetSize.2440x1220'), // 2.98 м² - редкий
        FieldOption(value: 0, labelKey: 'input.sheetSize.custom'),
      ],
    ),
    const CalculatorField(
      key: 'sheetLength',
      labelKey: 'input.sheetLength',
      hintKey: 'input.sheetLength.hint',
      unitType: UnitType.meters,
      defaultValue: 2.5,
      minValue: 1.0,
      maxValue: 3.6,
      required: true,
      step: 0.01,
      iconName: 'straighten',
      group: 'sheet',
      order: 11,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'sheetSize',
        value: 0,
      ),
    ),
    const CalculatorField(
      key: 'sheetWidth',
      labelKey: 'input.sheetWidth',
      hintKey: 'input.sheetWidth.hint',
      unitType: UnitType.meters,
      defaultValue: 1.25,
      minValue: 0.5,
      maxValue: 1.5,
      required: true,
      step: 0.01,
      iconName: 'straighten',
      group: 'sheet',
      order: 12,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'sheetSize',
        value: 0,
      ),
    ),

    const CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      hintKey: 'input.thickness.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 9,
      required: true,
      iconName: 'height',
      group: 'sheet',
      order: 13,
      options: [
        FieldOption(value: 6, labelKey: 'input.thickness.6mm'),
        FieldOption(value: 9, labelKey: 'input.thickness.9mm'),
        FieldOption(value: 10, labelKey: 'input.thickness.10mm'),
        FieldOption(value: 12, labelKey: 'input.thickness.12mm'),
        FieldOption(value: 15, labelKey: 'input.thickness.15mm'),
        FieldOption(value: 18, labelKey: 'input.thickness.18mm'),
        FieldOption(value: 22, labelKey: 'input.thickness.22mm'),
      ],
    ),

    // --- Группа "Применение" ---
    const CalculatorField(
      key: 'constructionType',
      labelKey: 'input.constructionType',
      hintKey: 'input.constructionType.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.select,
      defaultValue: 1,
      required: true,
      iconName: 'home_repair_service',
      group: 'application',
      order: 20,
      options: [
        FieldOption(value: 1, labelKey: 'input.constructionType.wall_sheathing'),
        FieldOption(value: 2, labelKey: 'input.constructionType.floor'),
        FieldOption(value: 3, labelKey: 'input.constructionType.roof'),
        FieldOption(value: 4, labelKey: 'input.constructionType.partitions'),
        FieldOption(value: 5, labelKey: 'input.constructionType.sip_panels'),
        FieldOption(value: 6, labelKey: 'input.constructionType.formwork'),
      ],
    ),
    const CalculatorField(
      key: 'joistStep',
      labelKey: 'input.joistStep',
      hintKey: 'input.joistStep.hint',
      unitType: UnitType.millimeters,
      inputType: FieldInputType.select,
      defaultValue: 600,
      required: true,
      iconName: 'straighten',
      group: 'application',
      order: 21,
      options: [
        FieldOption(value: 300, labelKey: 'input.joistStep.300mm'),
        FieldOption(value: 400, labelKey: 'input.joistStep.400mm'),
        FieldOption(value: 500, labelKey: 'input.joistStep.500mm'),
        FieldOption(value: 600, labelKey: 'input.joistStep.600mm'),
        FieldOption(value: 800, labelKey: 'input.joistStep.800mm'),
      ],
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'constructionType',
        value: 2,
      ),
    ),

    // --- Группа "Дополнительно" ---
    const CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      hintKey: 'input.reserve.hint',
      unitType: UnitType.percent,
      inputType: FieldInputType.slider,
      defaultValue: 10.0,
      minValue: 5.0,
      maxValue: 20.0,
      step: 1,
      iconName: 'inventory',
      group: 'advanced',
      order: 30,
    ),

    // --- Группа "Проёмы" ---
    const CalculatorField(
      key: 'windowsArea',
      labelKey: 'input.windows_area',
      hintKey: 'input.windows_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 100.0,
      required: false,
      step: 0.1,
      iconName: 'window',
      group: 'openings',
      order: 40,
    ),
    const CalculatorField(
      key: 'doorsArea',
      labelKey: 'input.doors_area',
      hintKey: 'input.doors_area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 0.0,
      minValue: 0.0,
      maxValue: 50.0,
      required: false,
      step: 0.1,
      iconName: 'door_front',
      group: 'openings',
      order: 41,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: const [
    CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.osb.before.thickness',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.osb.before.application',
    ),
  ],

  // Подсказки после расчёта
  afterHints: const [
    CalculatorHint(
      type: HintType.important,
      messageKey: 'hint.osb.after.fasteners',
    ),
    CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.osb.after.installation',
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.osb.warning.thickness_floor',
      condition: HintCondition(
        type: HintConditionType.equals,
        resultKey: 'warningLowThicknessFloor',
        value: 1,
      ),
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.osb.warning.thickness_roof',
      condition: HintCondition(
        type: HintConditionType.equals,
        resultKey: 'warningLowThicknessRoof',
        value: 1,
      ),
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.osb.warning.thickness_formwork',
      condition: HintCondition(
        type: HintConditionType.equals,
        resultKey: 'warningLowThicknessFormwork',
        value: 1,
      ),
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.osb.warning.class_outdoor',
      condition: HintCondition(
        type: HintConditionType.equals,
        resultKey: 'warningClassOutdoor',
        value: 1,
      ),
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.osb.warning.class_wet',
      condition: HintCondition(
        type: HintConditionType.equals,
        resultKey: 'warningClassWet',
        value: 1,
      ),
    ),
    CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.osb.warning.class_load',
      condition: HintCondition(
        type: HintConditionType.equals,
        resultKey: 'warningClassLoad',
        value: 1,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateSheetingOsbPlywood(),
);
