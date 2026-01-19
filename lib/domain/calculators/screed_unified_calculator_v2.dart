// ignore_for_file: prefer_const_constructors
import '../../core/enums/calculator_category.dart';
import '../../core/enums/field_input_type.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import 'calculator_constants.dart';
import '../usecases/calculate_screed_unified.dart';

/// Объединённый калькулятор стяжки V2.
///
/// Заменяет два калькулятора:
/// - `floors_screed` (Стяжка пола)
/// - `dsp` (ЦПС / Стяжка)
///
/// Объединяет функциональность:
/// - Выбор типа стяжки (ЦПС, полусухая, бетонная)
/// - Выбор способа (готовая смесь ЦПС или самозамес)
/// - Расчёт всех необходимых материалов
final screedUnifiedCalculatorV2 = CalculatorDefinitionV2(
  id: 'floors_screed_unified',
  titleKey: 'calculator.floors_screed_unified.title',
  descriptionKey: 'calculator.floors_screed_unified.description',
  category: CalculatorCategory.interior,
  subCategoryKey: 'subcategory.floors',
  iconName: 'foundation',
  accentColor: kCalculatorAccentColor,
  complexity: 2,
  popularity: 90, // Высокая популярность — объединённый калькулятор
  tags: [
    'стяжка',
    'цпс',
    'пол',
    'бетон',
    'цемент',
    'песок',
    'пескобетон',
    'screed',
    'floor',
    'dsp',
    'cement',
  ],

  // Поля ввода
  fields: [
    // --- Режим ввода площади ---
    const CalculatorField(
      key: 'inputMode',
      labelKey: 'input.mode',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.mode.by_area'),
        FieldOption(value: 1, labelKey: 'input.mode.by_room'),
      ],
      order: 0,
    ),

    // --- Площадь (для режима 0) ---
    const CalculatorField(
      key: 'area',
      labelKey: 'input.area',
      hintKey: 'input.area.hint',
      unitType: UnitType.squareMeters,
      defaultValue: 20,
      minValue: 1.0,
      maxValue: 500.0,
      required: true,
      step: 1,
      iconName: 'square_foot',
      order: 1,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 0,
      ),
    ),

    // --- Размеры комнаты (для режима 1) ---
    const CalculatorField(
      key: 'roomWidth',
      labelKey: 'input.room_width',
      unitType: UnitType.meters,
      defaultValue: 4.0,
      minValue: 0.5,
      maxValue: 30,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      group: 'room',
      order: 2,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),
    const CalculatorField(
      key: 'roomLength',
      labelKey: 'input.room_length',
      unitType: UnitType.meters,
      defaultValue: 5.0,
      minValue: 0.5,
      maxValue: 30,
      required: true,
      step: 0.1,
      iconName: 'straighten',
      group: 'room',
      order: 3,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'inputMode',
        value: 1,
      ),
    ),

    // --- Тип стяжки ---
    const CalculatorField(
      key: 'screedType',
      labelKey: 'input.screed_type',
      hintKey: 'input.screed_type.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.screed_type.cement_sand'),
        FieldOption(value: 1, labelKey: 'input.screed_type.semidry'),
        FieldOption(value: 2, labelKey: 'input.screed_type.concrete'),
      ],
      order: 10,
    ),

    // --- Способ приготовления ---
    const CalculatorField(
      key: 'materialType',
      labelKey: 'input.material_type',
      hintKey: 'input.material_type.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.material_type.ready_mix'),
        FieldOption(value: 1, labelKey: 'input.material_type.self_mix'),
      ],
      order: 11,
    ),

    // --- Марка смеси (для готовой смеси) ---
    const CalculatorField(
      key: 'mixGrade',
      labelKey: 'input.mix_grade',
      hintKey: 'input.mix_grade.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.radio,
      defaultValue: 0,
      options: [
        FieldOption(value: 0, labelKey: 'input.mix_grade.m300'),
        FieldOption(value: 1, labelKey: 'input.mix_grade.m150'),
      ],
      order: 12,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'materialType',
        value: 0,
      ),
    ),

    // --- Вес мешка (для готовой смеси) ---
    const CalculatorField(
      key: 'bagWeight',
      labelKey: 'input.bag_weight',
      hintKey: 'input.bag_weight.hint',
      unitType: UnitType.kilograms,
      defaultValue: 40,
      minValue: 25,
      maxValue: 50,
      required: true,
      step: 5,
      iconName: 'shopping_bag',
      group: 'mix',
      order: 13,
      dependency: FieldDependency(
        condition: DependencyCondition.equals,
        fieldKey: 'materialType',
        value: 0,
      ),
    ),

    // --- Толщина слоя ---
    const CalculatorField(
      key: 'thickness',
      labelKey: 'input.thickness',
      hintKey: 'input.thickness.hint',
      unitType: UnitType.millimeters,
      defaultValue: 50,
      minValue: 10,
      maxValue: 200,
      required: true,
      step: 5,
      iconName: 'height',
      order: 20,
    ),

    // --- Опции: армирующая сетка ---
    const CalculatorField(
      key: 'needMesh',
      labelKey: 'input.need_mesh',
      hintKey: 'input.need_mesh.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 1,
      group: 'options',
      order: 30,
    ),

    // --- Опции: плёнка ПЭ ---
    const CalculatorField(
      key: 'needFilm',
      labelKey: 'input.need_film',
      hintKey: 'input.need_film.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 1,
      group: 'options',
      order: 31,
    ),

    // --- Опции: демпферная лента ---
    const CalculatorField(
      key: 'needTape',
      labelKey: 'input.need_tape',
      hintKey: 'input.need_tape.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 1,
      group: 'options',
      order: 32,
    ),

    // --- Опции: маяки ---
    const CalculatorField(
      key: 'needBeacons',
      labelKey: 'input.need_beacons',
      hintKey: 'input.need_beacons.hint',
      unitType: UnitType.pieces,
      inputType: FieldInputType.switch_,
      defaultValue: 1,
      group: 'options',
      order: 33,
    ),
  ],

  // Подсказки перед расчётом
  beforeHints: [
    const CalculatorHint(
      type: HintType.info,
      messageKey: 'hint.screed.before.level',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.screed.before.material_choice',
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.screed.before.thin_layer',
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
      type: HintType.important,
      messageKey: 'hint.screed.after.curing',
    ),
    const CalculatorHint(
      type: HintType.tip,
      messageKey: 'hint.screed.after.reinforcement',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        fieldKey: 'thickness',
        value: 50,
      ),
    ),
    const CalculatorHint(
      type: HintType.warning,
      messageKey: 'hint.screed.after.crack_warning',
      condition: HintCondition(
        type: HintConditionType.greaterThan,
        resultKey: 'thicknessWarning',
        value: 0,
      ),
    ),
  ],

  // UseCase для расчёта
  useCase: CalculateScreedUnified(),

  showToolsSection: true,
);
