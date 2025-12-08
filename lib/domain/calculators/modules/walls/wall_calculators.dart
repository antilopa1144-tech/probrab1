import '../../definitions.dart';
import '../../../usecases/calculate_wall_paint.dart';
import '../../../usecases/calculate_wallpaper.dart';
import '../../../usecases/calculate_decorative_plaster.dart';
import '../../../usecases/calculate_decorative_stone.dart';
import '../../../usecases/calculate_pvc_panels.dart';
import '../../../usecases/calculate_mdf_panels.dart';
import '../../../usecases/calculate_3d_panels.dart';
import '../../../usecases/calculate_wood_wall.dart';
import '../../../usecases/calculate_gvl_wall.dart';
import '../../../usecases/calculate_wall_tile.dart';

/// Калькуляторы для отделки стен
///
/// Содержит калькуляторы для расчёта материалов на отделку стен:
/// - Покраска стен
/// - Обои
/// - Декоративная штукатурка
/// - Декоративный камень
/// - ПВХ панели
/// - МДФ панели
/// - 3D панели
/// - Деревянная вагонка
/// - ГВЛ листы
/// - Настенная плитка
final List<CalculatorDefinition> wallCalculators = [
  CalculatorDefinition(
    id: 'walls_paint',
    titleKey: 'calculator.wallPaint',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 1000.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 2.0,
        minValue: 1.0,
        maxValue: 5.0,
      ),
      InputFieldDefinition(
        key: 'consumption',
        labelKey: 'input.consumption',
        defaultValue: 0.15,
        minValue: 0.05,
        maxValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'doorsArea',
        labelKey: 'input.doorsArea',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 50.0,
        required: false,
      ),
    ],
    resultLabels: const {
      'usefulArea': 'result.area',
      'paintNeeded': 'result.paintNeeded',
      'primerNeeded': 'result.primerNeeded',
      'tapeNeeded': 'result.tapeNeeded',
      'rollersNeeded': 'result.rollersNeeded',
      'brushesNeeded': 'result.brushesNeeded',
      'layers': 'result.layers',
    },
    tips: const [
      'Рекомендуется купить грунтовку для улучшения сцепления.',
      'Используйте малярный скотч для защиты углов и плинтуса.',
      'Возьмите валик средней ворсистости и кювету.',
      'Для углов пригодятся кисти шириной 50 мм.',
      'Не забудьте плёнку для защиты пола и мебели.',
    ],
    useCase: CalculateWallPaint(),
  ),
  CalculatorDefinition(
    id: 'walls_wallpaper',
    titleKey: 'calculator.wallpaper',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 500.0,
      ),
      InputFieldDefinition(
        key: 'rollWidth',
        labelKey: 'input.rollWidth',
        defaultValue: 0.53,
        minValue: 0.3,
        maxValue: 1.5,
      ),
      InputFieldDefinition(
        key: 'rollLength',
        labelKey: 'input.rollLength',
        defaultValue: 10.05,
        minValue: 5.0,
        maxValue: 25.0,
      ),
      InputFieldDefinition(
        key: 'rapport',
        labelKey: 'input.rapport',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 1.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'wallHeight',
        labelKey: 'input.wallHeight',
        defaultValue: 2.5,
        minValue: 2.0,
        maxValue: 5.0,
      ),
      InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'doorsArea',
        labelKey: 'input.doorsArea',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 50.0,
        required: false,
      ),
    ],
    resultLabels: const {
      'usefulArea': 'result.area',
      'rollsNeeded': 'result.rolls',
      'glueNeeded': 'result.glue',
      'effectiveRollArea': 'result.area',
    },
    tips: const [
      'Проверьте совпадение рисунка (раппорта) перед поклейкой.',
      'Рекомендуется добавить 10 % к площади для подрезки.',
      'Используйте лазерный уровень для контроля вертикали.',
      'Клей подбирайте по типу обоев (флизелиновые/виниловые).',
    ],
    useCase: CalculateWallpaper(),
  ),
  CalculatorDefinition(
    id: 'walls_decor_plaster',
    titleKey: 'calculator.decorativePlaster',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'doorsArea',
        labelKey: 'input.doorsArea',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: const {
      'usefulArea': 'result.area',
      'plasterNeeded': 'result.plaster',
      'primerNeeded': 'result.primer',
    },
    tips: const [
      'Используйте грунтовку глубокого проникновения.',
      'Возьмите шпатели и кельмы разных размеров.',
      'Для венецианской штукатурки нужна кельма из нержавейки.',
    ],
    useCase: CalculateDecorativePlaster(),
  ),
  CalculatorDefinition(
    id: 'walls_decor_stone',
    titleKey: 'calculator.decorativeStone',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 15.0,
      ),
    ],
    resultLabels: const {
      'stoneNeeded': 'result.stones',
      'glueNeeded': 'result.glue',
      'groutNeeded': 'result.grout',
    },
    tips: const [
      'Добавьте 10% запас на подрезку и бой.',
      'Используйте специальный клей для декоративного камня.',
      'Обработайте камень гидрофобизатором.',
    ],
    useCase: CalculateDecorativeStone(),
  ),
  CalculatorDefinition(
    id: 'walls_pvc_panels',
    titleKey: 'calculator.pvcPanels',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 0.25,
      ),
    ],
    resultLabels: const {
      'panelsNeeded': 'result.panels',
      'profilesNeeded': 'result.profiles',
      'clipsNeeded': 'result.clips',
    },
    tips: const [
      'Панели укладывайте от угла.',
      'Оставляйте температурный зазор 5 мм.',
      'Используйте стартовый и финишный профили.',
    ],
    useCase: CalculatePvcPanels(),
  ),
  CalculatorDefinition(
    id: 'walls_mdf_panels',
    titleKey: 'calculator.mdfPanels',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 0.20,
      ),
    ],
    resultLabels: const {
      'panelsNeeded': 'result.panels',
      'battensNeeded': 'result.battens',
      'clipsNeeded': 'result.clips',
    },
    tips: const [
      'МДФ не для влажных помещений.',
      'Обрешетка с шагом 40-50 см.',
      'Крепите на кляймеры или клипсы.',
    ],
    useCase: CalculateMdfPanels(),
  ),
  CalculatorDefinition(
    id: 'walls_3d_panels',
    titleKey: 'calculator.3dPanels',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'panelSize',
        labelKey: 'input.packArea',
        defaultValue: 0.5,
      ),
    ],
    resultLabels: const {
      'panelsNeeded': 'result.panels',
      'glueNeeded': 'result.glue',
    },
    tips: const [
      'Проверьте ровность стен перед установкой.',
      'Используйте специальный клей для 3D панелей.',
      'Начинайте монтаж от центра стены.',
    ],
    useCase: Calculate3dPanels(),
  ),
  CalculatorDefinition(
    id: 'walls_wood',
    titleKey: 'calculator.woodWall',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'boardWidth',
        labelKey: 'input.boardWidth',
        defaultValue: 0.10,
      ),
    ],
    resultLabels: const {
      'boardsNeeded': 'result.boards',
      'battensNeeded': 'result.battens',
      'nailsNeeded': 'result.fasteners',
    },
    tips: const [
      'Дайте вагонке акклиматизироваться 48 часов.',
      'Обработайте антисептиком перед монтажом.',
      'Крепите на кляймеры для скрытого монтажа.',
    ],
    useCase: CalculateWoodWall(),
  ),
  CalculatorDefinition(
    id: 'walls_gvl',
    titleKey: 'calculator.gvlWall',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: const {
      'sheetsNeeded': 'result.sheets',
      'profilesNeeded': 'result.profiles',
      'screwsNeeded': 'result.screws',
    },
    tips: const [
      'ГВЛ тяжелее ГКЛ, усильте каркас.',
      'Используйте саморезы для ГВЛ.',
      'Зазор между листами 5-7 мм.',
    ],
    useCase: CalculateGvlWall(),
  ),
  CalculatorDefinition(
    id: 'walls_tile',
    titleKey: 'calculator.wallTile',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: const [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'tileWidth',
        labelKey: 'input.tileWidth',
        defaultValue: 30.0,
      ),
      InputFieldDefinition(
        key: 'tileHeight',
        labelKey: 'input.tileHeight',
        defaultValue: 60.0,
      ),
    ],
    resultLabels: const {
      'tilesNeeded': 'result.tiles',
      'glueNeeded': 'result.glue',
      'groutNeeded': 'result.grout',
    },
    tips: const [
      'Добавьте 10% запас на подрезку.',
      'Используйте крестики для ровных швов.',
      'Начинайте со второго ряда снизу.',
    ],
    useCase: CalculateWallTile(),
  ),
];
