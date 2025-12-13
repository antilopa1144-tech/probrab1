import '../../core/enums/calculator_category.dart';
import '../../core/enums/unit_type.dart';
import '../models/calculator_definition_v2.dart';
import '../models/calculator_field.dart';
import '../models/calculator_hint.dart';
import '../usecases/calculate_plinth.dart';
import 'calculator_constants.dart';

final plinthCalculatorV2 = CalculatorDefinitionV2(
  id: 'plinth',
  titleKey: 'calculator.plinth.title',
  descriptionKey: 'calculator.plinth.description',
  category: CalculatorCategory.interior,
  subCategory: 'Полы',
  tags: ['плинтус', 'пол', 'ремонт', 'plinth', 'baseboard'],
  accentColor: kCalculatorAccentColor,
  useCase: CalculatePlinth(),
  fields: const [
    CalculatorField(
      key: 'perimeter',
      labelKey: 'input.perimeter',
      hintKey: 'input.perimeter.hint',
      unitType: UnitType.meters,
      required: false,
      defaultValue: 0.0,
    ),
    CalculatorField(
      key: 'length',
      labelKey: 'input.length',
      unitType: UnitType.meters,
      required: true,
      dependency: FieldDependency(
        fieldKey: 'perimeter',
        condition: DependencyCondition.equals,
        value: 0,
      ),
    ),
    CalculatorField(
      key: 'width',
      labelKey: 'input.width',
      unitType: UnitType.meters,
      required: true,
      dependency: FieldDependency(
        fieldKey: 'perimeter',
        condition: DependencyCondition.equals,
        value: 0,
      ),
    ),
    CalculatorField(
      key: 'doors',
      labelKey: 'input.doors',
      unitType: UnitType.pieces,
      required: false,
    ),
    CalculatorField(
      key: 'doorWidth',
      labelKey: 'input.doorWidth',
      unitType: UnitType.meters,
      required: false,
      defaultValue: 0.8,
    ),
    CalculatorField(
      key: 'plinthPieceLength',
      labelKey: 'input.plinthPieceLength',
      hintKey: 'input.plinthPieceLength.hint',
      unitType: UnitType.meters,
      required: false,
      defaultValue: 2.5,
    ),
    CalculatorField(
      key: 'reserve',
      labelKey: 'input.reserve',
      unitType: UnitType.percent,
      required: false,
      defaultValue: 5.0,
    ),
  ],
  beforeHints: const [
    CalculatorHint(
      type: HintType.tip,
      messageKey:
          'Если периметр неизвестен — укажите длину и ширину комнаты, периметр будет рассчитан автоматически.',
    ),
  ],
);
