import '../../definitions.dart';
import '../../../usecases/calculate_insulation_mineral_wool.dart';
import '../../../usecases/calculate_insulation_foam.dart';

/// Калькуляторы для утепления
///
/// Содержит калькуляторы для расчёта материалов на утепление:
/// - Минеральная вата (каменная вата, стекловата)
/// - Пенопласт (пенополистирол, ЭППС)
final List<CalculatorDefinition> insulationCalculators = [
  CalculatorDefinition(
    id: 'insulation_mineral',
    titleKey: 'calculator.mineralWool',
    category: 'Внутренняя отделка',
    subCategory: 'Утепление',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 100.0,
      ),
      const InputFieldDefinition(
        key: 'density',
        labelKey: 'input.density',
        defaultValue: 50.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'sheetsNeeded': 'result.sheets',
      'weight': 'result.weight',
      'vaporBarrierArea': 'result.vaporBarrier',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Используйте пароизоляцию с внутренней стороны.',
      'Не сжимайте вату при укладке — это снижает эффективность.',
      'Защитите руки и дыхательные пути при работе.',
    ],
    useCase: CalculateInsulationMineralWool(),
  ),
  CalculatorDefinition(
    id: 'insulation_foam',
    titleKey: 'calculator.foamInsulation',
    category: 'Внутренняя отделка',
    subCategory: 'Утепление',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'density',
        labelKey: 'input.density',
        defaultValue: 25.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'sheetsNeeded': 'result.sheets',
      'weight': 'result.weight',
      'glueNeeded': 'result.glue',
      'fastenersNeeded': 'result.fasteners',
      'meshArea': 'result.mesh',
    },
    tips: const [
      'Используйте специальный клей для пенопласта.',
      'Крепите дюбелями после высыхания клея.',
      'Для фасада обязательна армирующая сетка.',
    ],
    useCase: CalculateInsulationFoam(),
  ),
];
