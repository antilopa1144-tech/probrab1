import '../core/enums/calculator_category.dart';
import '../usecases/calculate_bathroom_tile.dart';
import 'calculator_constants.dart';
import 'models/calculator_definition_v2.dart';
import 'models/calculator_field.dart';

/// V2 калькулятор: calculator.bathroomTile
///
/// Автоматически сгенерирован из V1 модуля: bathroom
final bathroom_tileV2 = CalculatorDefinitionV2(
  id: 'bathroom_tile',
  titleKey: 'calculator.bathroomTile',
  descriptionKey: 'calculator.bathroomTile.description',
  category: CalculatorCategory.interior,
  subCategory: 'bathroom',
  fields: [
    // TODO: Добавить поля из V1 калькулятора
  ],
  useCase: CalculateBathroomTile(),
  complexity: 2,
  popularity: 10,
  tags: ['Внутренняя отделка', 'Ванная / туалет', 'bathroom'],
);
