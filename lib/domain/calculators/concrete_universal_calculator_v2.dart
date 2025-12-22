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
      defaultValue: 0.0,
      required: true,
      minValue: 0.01,
      maxValue: 1000.0,
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
      messageKey:
          'Если заказываете готовый бетон, обычно имеет смысл добавить запас 3–7% на потери и неровности.',
    ),
  ],
);
