import '../../definitions.dart';
import '../../../usecases/calculate_gkl_partition.dart';
import '../../../usecases/calculate_gasblock_partition.dart';
import '../../../usecases/calculate_brick_partition.dart';

/// Калькуляторы для перегородок
///
/// Содержит калькуляторы для расчёта материалов на внутренние перегородки:
/// - ГКЛ перегородки (гипсокартон на металлическом каркасе)
/// - Перегородки из газобетонных блоков
/// - Кирпичные перегородки
final List<CalculatorDefinition> partitionCalculators = [
  CalculatorDefinition(
    id: 'partitions_gkl',
    titleKey: 'calculator.gklPartition',
    category: 'Внутренняя отделка',
    subCategory: 'Перегородки',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 500.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 2.0,
        minValue: 1.0,
        maxValue: 3.0,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.5,
        minValue: 2.0,
        maxValue: 4.5,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'sheetsNeeded': 'result.sheets',
      'studsLength': 'result.studs',
      'guideLength': 'result.guide',
      'screwsNeeded': 'result.screws',
      'puttyNeeded': 'result.putty',
    },
    tips: const [
      'Шаг стоек — 60 см для прочности.',
      'Используйте звукоизоляцию между листами.',
      'Проверьте вертикальность стоек уровнем.',
      'Шпаклёвку наносите в два слоя.',
    ],
    useCase: CalculateGklPartition(),
  ),
  CalculatorDefinition(
    id: 'partitions_blocks',
    titleKey: 'calculator.gasBlockPartition',
    category: 'Внутренняя отделка',
    subCategory: 'Перегородки',
    fields: const [
      InputFieldDefinition(
        key: 'length',
        labelKey: 'input.length',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.7,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 100.0,
      ),
    ],
    resultLabels: const {
      'blocksNeeded': 'result.sheets',
      'glueNeeded': 'result.glue',
      'reinforcementLength': 'result.reinforcement',
    },
    tips: const [
      'Используйте специальный клей для газобетона.',
      'Армируйте каждый 3-4 ряд.',
      'Первый ряд укладывайте на раствор.',
      'Проверяйте геометрию уровнем.',
    ],
    useCase: CalculateGasblockPartition(),
  ),
  CalculatorDefinition(
    id: 'partitions_brick',
    titleKey: 'calculator.brickPartition',
    category: 'Внутренняя отделка',
    subCategory: 'Перегородки',
    fields: const [
      InputFieldDefinition(
        key: 'length',
        labelKey: 'input.length',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.7,
      ),
      InputFieldDefinition(
        key: 'brickType',
        labelKey: 'input.type',
        defaultValue: 0.5,
      ),
    ],
    resultLabels: const {
      'bricksNeeded': 'result.bricks',
      'mortarNeeded': 'result.mortar',
      'reinforcementLength': 'result.reinforcement',
    },
    tips: const [
      'Кладку в полкирпича армируйте каждые 5 рядов.',
      'Используйте цементно-песчаный раствор М100.',
      'Проверяйте вертикальность отвесом.',
      'Связывайте с несущими стенами анкерами.',
    ],
    useCase: CalculateBrickPartition(),
  ),
];
