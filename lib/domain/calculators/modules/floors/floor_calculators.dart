import '../../definitions.dart';
import '../../../usecases/calculate_laminate.dart';
import '../../../usecases/calculate_screed.dart';
import '../../../usecases/calculate_tile.dart';
import '../../../usecases/calculate_linoleum.dart';
import '../../../usecases/calculate_warm_floor.dart';
import '../../../usecases/calculate_parquet.dart';
import '../../../usecases/calculate_self_leveling_floor.dart';
import '../../../usecases/calculate_carpet.dart';
import '../../../usecases/calculate_floor_insulation.dart';

/// Калькуляторы для напольных покрытий
///
/// Содержит калькуляторы для расчёта материалов на укладку полов:
/// - Ламинат
/// - Стяжка пола
/// - Напольная плитка
/// - Линолеум
/// - Тёплый пол
/// - Паркет
/// - Самовыравнивающийся пол
/// - Ковролин
/// - Утепление пола
final List<CalculatorDefinition> floorCalculators = [
  CalculatorDefinition(
    id: 'floors_laminate',
    titleKey: 'calculator.laminate',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 500.0,
      ),
      InputFieldDefinition(
        key: 'packArea',
        labelKey: 'input.packArea',
        defaultValue: 2.0,
        minValue: 1.0,
        maxValue: 5.0,
      ),
      InputFieldDefinition(
        key: 'underlayThickness',
        labelKey: 'input.underlayThickness',
        defaultValue: 3.0,
        minValue: 2.0,
        maxValue: 10.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 200.0,
        required: false,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'packsNeeded': 'result.packs',
      'underlayArea': 'result.underlay',
      'plinthLength': 'result.plinth',
      'wedgesNeeded': 'result.wedges',
    },
    tips: const [
      'Возьмите клинья для компенсационного зазора 10 мм.',
      'Подложку выбирайте толщиной 2–3 мм.',
      'Крестики не нужны, но контрольные клинья пригодятся.',
      'Проверьте ровность основания — перепад более 3 мм нежелателен.',
    ],
    useCase: CalculateLaminate(),
  ),
  CalculatorDefinition(
    id: 'floors_screed',
    titleKey: 'calculator.screed',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 1000.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 50.0,
        minValue: 20.0,
        maxValue: 200.0,
      ),
      InputFieldDefinition(
        key: 'cementGrade',
        labelKey: 'input.cementGrade',
        defaultValue: 400.0,
        minValue: 300.0,
        maxValue: 600.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'volume': 'result.volume',
      'cementBags': 'result.cementBags',
      'sandVolume': 'result.sand',
    },
    tips: const [
      'Перед заливкой проверьте уровень основания.',
      'Используйте маяки для контроля толщины стяжки.',
      'Выдержите стяжку не менее 7 дней перед укладкой покрытия.',
      'При толщине более 50 мм используйте армирующую сетку.',
    ],
    useCase: CalculateScreed(),
  ),
  CalculatorDefinition(
    id: 'floors_tile',
    titleKey: 'calculator.tile',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 0.5,
        maxValue: 500.0,
      ),
      InputFieldDefinition(
        key: 'tileWidth',
        labelKey: 'input.tileWidth',
        defaultValue: 30.0,
        minValue: 10.0,
        maxValue: 120.0,
      ),
      InputFieldDefinition(
        key: 'tileHeight',
        labelKey: 'input.tileHeight',
        defaultValue: 30.0,
        minValue: 10.0,
        maxValue: 120.0,
      ),
      InputFieldDefinition(
        key: 'jointWidth',
        labelKey: 'input.jointWidth',
        defaultValue: 3.0,
        minValue: 1.0,
        maxValue: 10.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'tilesNeeded': 'result.tiles',
      'groutNeeded': 'result.grout',
      'glueNeeded': 'result.glue',
      'crossesNeeded': 'result.crosses',
    },
    tips: const [
      'Используйте крестики для равномерного шва.',
      'Проверьте ровность основания — перепад не более 3 мм.',
      'Затирку выбирайте по цвету плитки.',
      'Клей наносите зубчатым шпателем.',
    ],
    useCase: CalculateTile(),
  ),
  CalculatorDefinition(
    id: 'floors_linoleum',
    titleKey: 'calculator.linoleum',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'rollWidth',
        labelKey: 'input.rollWidth',
        defaultValue: 3.0,
      ),
      InputFieldDefinition(
        key: 'rollLength',
        labelKey: 'input.rollLength',
        defaultValue: 30.0,
      ),
      InputFieldDefinition(
        key: 'overlap',
        labelKey: 'input.overlap',
        defaultValue: 5.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'rollsNeeded': 'result.rolls',
      'plinthLength': 'result.plinth',
      'glueNeeded': 'result.glue',
    },
    tips: const [
      'Раскатайте линолеум и дайте ему отлежаться 24 часа.',
      'Обрежьте излишки после укладки.',
      'Используйте двухсторонний скотч для фиксации.',
    ],
    useCase: CalculateLinoleum(),
  ),
  CalculatorDefinition(
    id: 'floors_warm',
    titleKey: 'calculator.warmFloor',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 200.0,
      ),
      InputFieldDefinition(
        key: 'power',
        labelKey: 'input.power',
        defaultValue: 150.0,
        minValue: 80.0,
        maxValue: 250.0,
      ),
      InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 2.0,
        minValue: 1.0,
        maxValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'thermostats',
        labelKey: 'input.thermostats',
        defaultValue: 1.0,
        minValue: 1.0,
        maxValue: 10.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'usefulArea': 'result.usefulArea',
      'totalPower': 'result.power',
      'cableLength': 'result.cable',
      'matArea': 'result.mat',
      'thermostats': 'result.thermostats',
    },
    tips: const [
      'Не укладывайте под мебелью и стационарной техникой.',
      'Используйте теплоизоляцию для повышения эффективности.',
      'Подключение должен выполнять квалифицированный электрик.',
      'Перед укладкой покрытия проверьте работоспособность системы.',
    ],
    useCase: CalculateWarmFloor(),
  ),
  CalculatorDefinition(
    id: 'floors_parquet',
    titleKey: 'calculator.parquet',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'plankWidth',
        labelKey: 'input.plankWidth',
        defaultValue: 7.0,
      ),
      InputFieldDefinition(
        key: 'plankLength',
        labelKey: 'input.plankLength',
        defaultValue: 40.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'planksNeeded': 'result.planks',
      'varnishNeeded': 'result.varnish',
      'primerNeeded': 'result.primer',
      'plinthLength': 'result.plinth',
      'glueNeeded': 'result.glue',
    },
    tips: const [
      'Паркет требует акклиматизации 48 часов перед укладкой.',
      'Используйте подложку для звукоизоляции.',
      'Лак наносите в 3 слоя с промежуточной шлифовкой.',
    ],
    useCase: CalculateParquet(),
  ),
  CalculatorDefinition(
    id: 'floors_self_leveling',
    titleKey: 'calculator.selfLevelingFloor',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 5.0,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'mixNeeded': 'result.mix',
      'primerNeeded': 'result.primer',
      'thickness': 'result.thickness',
      'rollersNeeded': 'result.rollers',
    },
    tips: const [
      'Основание должно быть чистым и сухим.',
      'Используйте грунтовку для улучшения адгезии.',
      'Раскатывайте смесь игольчатым валиком сразу после заливки.',
      'Не ходите по полу 24 часа после заливки.',
    ],
    useCase: CalculateSelfLevelingFloor(),
  ),
  CalculatorDefinition(
    id: 'floors_carpet',
    titleKey: 'calculator.carpet',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'rollWidth',
        labelKey: 'input.rollWidth',
        defaultValue: 4.0,
      ),
    ],
    resultLabels: const {
      'rollsNeeded': 'result.rolls',
      'glueNeeded': 'result.glue',
      'tapeNeeded': 'result.tape',
    },
    tips: const [
      'Ковролин должен отлежаться в помещении 24 часа.',
      'Для больших площадей используйте клей.',
      'На маленьких площадях можно использовать скотч.',
      'Укладывайте в одном направлении ворса.',
    ],
    useCase: CalculateCarpet(),
  ),
  CalculatorDefinition(
    id: 'floors_insulation',
    titleKey: 'calculator.floorInsulation',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'insulationThickness',
        labelKey: 'input.insulationThickness',
        defaultValue: 100.0,
      ),
      InputFieldDefinition(
        key: 'insulationType',
        labelKey: 'input.insulationType',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        required: false,
      ),
    ],
    resultLabels: const {
      'area': 'result.area',
      'volume': 'result.volume',
      'sheetsNeeded': 'result.sheets',
      'weight': 'result.weight',
      'vaporBarrierArea': 'result.vaporBarrier',
      'waterproofingArea': 'result.waterproofing',
      'plinthLength': 'result.plinth',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Утепление пола особенно важно для первого этажа и над неотапливаемыми помещениями.',
      'Для минваты обязательна гидроизоляция снизу.',
      'Пароизоляция укладывается сверху утеплителя (со стороны тёплого помещения).',
      'Пенопласт и ЭППС не требуют гидроизоляции, но нужна пароизоляция.',
      'Оставляйте зазор 2-3 см между утеплителем и финишным покрытием для вентиляции.',
    ],
    useCase: CalculateFloorInsulation(),
  ),
];
