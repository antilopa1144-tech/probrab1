
// Репозиторий расчётов (цены и прочее)

import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/core/cache/calculation_cache.dart';
import 'package:probrab_ai/domain/usecases/calculate_strip_foundation.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_paint.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/domain/usecases/calculate_decorative_plaster.dart';
import 'package:probrab_ai/domain/usecases/calculate_laminate.dart';
import 'package:probrab_ai/domain/usecases/calculate_screed.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';
import 'package:probrab_ai/domain/usecases/calculate_linoleum.dart';
import 'package:probrab_ai/domain/usecases/calculate_stretch_ceiling.dart';
import 'package:probrab_ai/domain/usecases/calculate_warm_floor.dart';
import 'package:probrab_ai/domain/usecases/calculate_gkl_partition.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_paint.dart';
import 'package:probrab_ai/domain/usecases/calculate_gkl_ceiling.dart';
import 'package:probrab_ai/domain/usecases/calculate_parquet.dart';
import 'package:probrab_ai/domain/usecases/calculate_self_leveling_floor.dart';
import 'package:probrab_ai/domain/usecases/calculate_insulation_mineral_wool.dart';
import 'package:probrab_ai/domain/usecases/calculate_insulation_foam.dart';
import 'package:probrab_ai/domain/usecases/calculate_siding.dart';
import 'package:probrab_ai/domain/usecases/calculate_rail_ceiling.dart';
import 'package:probrab_ai/domain/usecases/calculate_bathroom_tile.dart';
import 'package:probrab_ai/domain/usecases/calculate_waterproofing.dart';
import 'package:probrab_ai/domain/usecases/calculate_gasblock_partition.dart';
import 'package:probrab_ai/domain/usecases/calculate_brick_partition.dart';
import 'package:probrab_ai/domain/usecases/calculate_roofing_metal.dart';
import 'package:probrab_ai/domain/usecases/calculate_wet_facade.dart';
import 'package:probrab_ai/domain/usecases/calculate_carpet.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_tiles.dart';
import 'package:probrab_ai/domain/usecases/calculate_ceiling_insulation.dart';
import 'package:probrab_ai/domain/usecases/calculate_brick_facing.dart';
import 'package:probrab_ai/domain/usecases/calculate_gutters.dart';
import 'package:probrab_ai/domain/usecases/calculate_electrics.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_tile.dart';
import 'package:probrab_ai/domain/usecases/calculate_mdf_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_pvc_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_decorative_stone.dart';
import 'package:probrab_ai/domain/usecases/calculate_wood_wall.dart';
import 'package:probrab_ai/domain/usecases/calculate_gvl_wall.dart';
import 'package:probrab_ai/domain/usecases/calculate_plumbing.dart';
import 'package:probrab_ai/domain/usecases/calculate_heating.dart';
import 'package:probrab_ai/domain/usecases/calculate_putty.dart';
import 'package:probrab_ai/domain/usecases/calculate_primer.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile_glue.dart';
import 'package:probrab_ai/domain/usecases/calculate_plaster.dart';
import 'package:probrab_ai/domain/usecases/calculate_3d_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_facade_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_wood_facade.dart';
import 'package:probrab_ai/domain/usecases/calculate_window_installation.dart';
import 'package:probrab_ai/domain/usecases/calculate_door_installation.dart';
import 'package:probrab_ai/domain/usecases/calculate_slopes.dart';
import 'package:probrab_ai/domain/usecases/calculate_sound_insulation.dart';
import 'package:probrab_ai/domain/usecases/calculate_ventilation.dart';
import 'package:probrab_ai/domain/usecases/calculate_cassette_ceiling.dart';
cursor/optimize-all-calculators-for-ideal-performance-claude-4.5-sonnet-thinking-b889
import 'package:probrab_ai/domain/usecases/calculate_soft_roofing.dart';
import 'package:probrab_ai/domain/usecases/calculate_slab.dart';
import 'package:probrab_ai/domain/usecases/calculate_floor_insulation.dart';
import 'package:probrab_ai/domain/usecases/calculate_stairs.dart';
import 'package:probrab_ai/domain/usecases/calculate_fence.dart';
import 'package:probrab_ai/domain/usecases/calculate_blind_area.dart';
import 'package:probrab_ai/domain/usecases/calculate_basement.dart';
import 'package:probrab_ai/domain/usecases/calculate_balcony.dart';
import 'package:probrab_ai/domain/usecases/calculate_attic.dart';
import 'package:probrab_ai/domain/usecases/calculate_terrace.dart';
main


/// Описание поля ввода (одно поле формы: периметр, ширина и т.п.)
class InputFieldDefinition {
  /// ID поля (используется во входной карте inputs['perimeter'])
  final String key;

  /// Ключ для перевода (например 'input.perimeter')
  final String labelKey;

  /// Тип клавиатуры/ввода (number, text и т.п.)
  final String type;

  /// Значение по умолчанию
  final double defaultValue;

  /// Минимальное значение (null = нет ограничения)
  final double? minValue;

  /// Максимальное значение (null = нет ограничения)
  final double? maxValue;

  /// Обязательное поле
  final bool required;

  const InputFieldDefinition({
    required this.key,
    required this.labelKey,
    this.type = 'number',
    this.defaultValue = 0.0,
    this.minValue,
    this.maxValue,
    this.required = true,
  });
}

/// Описание самого калькулятора (одного инструмента)
class CalculatorDefinition {
  /// Уникальный ID (например 'calculator.stripTitle')
  final String id;

  /// Ключ заголовка для локализации
  final String titleKey;

  /// Поля ввода, которые нужно отрисовать на экране
  final List<InputFieldDefinition> fields;

  /// Ключи для подписей результатов (volume, rebar и т.п.)
  final Map<String, String> resultLabels;

  /// ГЛАВНОЕ: ссылка на класс-юзкейс, в котором живёт математика
  final CalculatorUseCase useCase;

  /// Категория (Дом → Внутренняя отделка → Стены)
  final String category;

  /// Подкатегория внутри категории (например, 'Ленточный фундамент')
  final String subCategory;

  /// Советы мастера, которые будет отображать универсальный экран.
  final List<String> tips;

  const CalculatorDefinition({
    required this.id,
    required this.titleKey,
    required this.fields,
    required this.resultLabels,
    required this.useCase,
    this.category = '',
    this.subCategory = '',
    this.tips = const [],
  });

  /// Кэш для результатов расчётов
  static final _cache = CalculationCache();

  /// Возвращает полный CalculatorResult (значения + цена).
  /// Использует кэширование для повторных расчётов с теми же параметрами.
  CalculatorResult run(
    Map<String, double> inputs,
    List<PriceItem> priceList, {
    bool useCache = true,
  }) {
    // Попытка получить из кэша
    if (useCache) {
      final cachedValues = _cache.get(id, inputs);
      if (cachedValues != null) {
        // Возвращаем кэшированный результат (без цены, т.к. цены могут измениться)
        return CalculatorResult(
          values: cachedValues,
          totalPrice: null,
        );
      }
    }

    // Выполняем расчёт
    final result = useCase.call(inputs, priceList);

    // Сохраняем в кэш
    if (useCache) {
      _cache.set(id, inputs, result.values);
    }

    return result;
  }

  /// Адаптер под старый код, который ожидает просто `Map<String, double>`.
  Map<String, double> compute(
    Map<String, double> inputs,
    List<PriceItem> priceList, {
    bool useCache = true,
  }) {
    final result = run(inputs, priceList, useCache: useCache);
    return result.values;
  }

  /// Alias для совместимости (некоторые экраны ожидают calculate()).
  Map<String, double> calculate(
    Map<String, double> inputs,
    List<PriceItem> priceList, {
    bool useCache = true,
  }) {
    return compute(inputs, priceList, useCache: useCache);
  }

  /// Очистить кэш для этого калькулятора
  void clearCache() {
    _cache.clearForCalculator(id);
  }

  /// Получить статистику кэша
  static CacheStats getCacheStats() {
    return _cache.getStats();
  }

  /// Очистить весь кэш
  static void clearAllCache() {
    _cache.clear();
  }
}

/// ===== КАЛЬКУЛЯТОРЫ ФУНДАМЕНТА =====

final List<CalculatorDefinition> foundationCalculators = [
  CalculatorDefinition(
    id: 'calculator.stripTitle',
    titleKey: 'calculator.stripTitle',
    category: 'Фундамент',
    subCategory: 'Ленточный фундамент',
    fields: [
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        minValue: 4.0,
        maxValue: 500.0,
      ),
      InputFieldDefinition(
        key: 'width',
        labelKey: 'input.width',
        minValue: 0.2,
        maxValue: 2.0,
        defaultValue: 0.4,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        minValue: 0.3,
        maxValue: 3.0,
        defaultValue: 0.8,
      ),
    ],
    resultLabels: {
      'concreteVolume': 'result.volume',
      'rebarWeight': 'result.rebar',
    },
    tips: const [
      'Снимите плодородный слой и утрамбуйте основание перед заливкой.',
      'Используйте песчано-щебёночную подушку не менее 200 мм.',
      'Контролируйте диагонали опалубки — от этого зависит геометрия стен.',
      'Заранее подготовьте закладные гильзы для инженерных коммуникаций.',
    ],
    useCase: CalculateStripFoundation(),
  ),
  CalculatorDefinition(
    id: 'foundation_slab',
    titleKey: 'calculator.slab',
    category: 'Фундамент',
    subCategory: 'Монолитная плита',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 0.2,
      ),
      InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulationThickness',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'thickness': 'result.thickness',
      'concreteVolume': 'result.volume',
      'rebarWeight': 'result.rebar',
      'sandVolume': 'result.sand',
      'gravelVolume': 'result.gravel',
      'waterproofingArea': 'result.waterproofing',
      'insulationVolume': 'result.insulation',
      'formworkArea': 'result.formwork',
      'wireNeeded': 'result.wire',
      'plasticizerNeeded': 'result.plasticizer',
    },
    tips: const [
      'Плита толщиной минимум 200 мм для жилого дома.',
      'Обязательна песчано-гравийная подготовка.',
      'Гидроизоляция снизу и по периметру.',
      'Армирование двумя сетками в верхней и нижней зонах.',
      'Утеплитель (ЭППС) под плитой для теплого пола.',
    ],
    useCase: CalculateSlab(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ СТЕН =====

final List<CalculatorDefinition> wallCalculators = [
  CalculatorDefinition(
    id: 'walls_paint',
    titleKey: 'calculator.wallPaint',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: [
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
    resultLabels: {
      'usefulArea': 'result.area',
      'paintNeeded': 'result.paint',
      'primerNeeded': 'result.primer',
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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

/// ===== КАЛЬКУЛЯТОРЫ ПОЛОВ =====

final List<CalculatorDefinition> floorCalculators = [
  CalculatorDefinition(
    id: 'floors_laminate',
    titleKey: 'calculator.laminate',
    category: 'Внутренняя отделка',
    subCategory: 'Полы',
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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

/// ===== КАЛЬКУЛЯТОРЫ ПОТОЛКОВ =====

final List<CalculatorDefinition> ceilingCalculators = [
  CalculatorDefinition(
    id: 'ceilings_paint',
    titleKey: 'calculator.ceilingPaint',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'consumption',
        labelKey: 'input.consumption',
        defaultValue: 0.12,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'paintNeeded': 'result.paint',
      'primerNeeded': 'result.primer',
      'layers': 'result.layers',
    },
    tips: const [
      'Используйте валик с длинным ворсом для потолка.',
      'Красьте перпендикулярно окну для равномерного покрытия.',
      'Не забудьте защитить стены и пол плёнкой.',
    ],
    useCase: CalculateCeilingPaint(),
  ),
  CalculatorDefinition(
    id: 'ceilings_stretch',
    titleKey: 'calculator.stretchCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'corners',
        labelKey: 'input.corners',
        defaultValue: 4.0,
      ),
      InputFieldDefinition(
        key: 'fixtures',
        labelKey: 'input.fixtures',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'canvasArea': 'result.canvas',
      'baguetteLength': 'result.baguette',
      'cornersNeeded': 'result.corners',
      'fixtures': 'result.fixtures',
    },
    tips: const [
      'Монтаж выполняют специалисты с опытом.',
      'Заранее определите места для светильников.',
      'Учитывайте высоту потолка — натяжной потолок опускает его на 3–5 см.',
    ],
    useCase: CalculateStretchCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_gkl',
    titleKey: 'calculator.gklCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        defaultValue: 2.5,
      ),
      InputFieldDefinition(
        key: 'dropHeight',
        labelKey: 'input.dropHeight',
        defaultValue: 0.1,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'sheetsNeeded': 'result.sheets',
      'guideLength': 'result.guide',
      'ceilingProfileLength': 'result.ceilingProfile',
      'hangersNeeded': 'result.hangers',
      'screwsNeeded': 'result.screws',
      'puttyNeeded': 'result.putty',
    },
    tips: const [
      'Шаг подвесов — 60 см для надёжности.',
      'Проверьте уровень всех профилей.',
      'Используйте армирующую ленту на стыках листов.',
    ],
    useCase: CalculateGklCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_rail',
    titleKey: 'calculator.railCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'railWidth',
        labelKey: 'input.railWidth',
        defaultValue: 10.0,
      ),
      InputFieldDefinition(
        key: 'railLength',
        labelKey: 'input.railLength',
        defaultValue: 300.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'railsNeeded': 'result.rails',
      'guideLength': 'result.guide',
      'hangersNeeded': 'result.hangers',
      'cornerLength': 'result.corner',
    },
    tips: const [
      'Монтируйте рейки перпендикулярно направляющим.',
      'Оставляйте зазор для вентиляции.',
      'Используйте уровень для контроля плоскости.',
    ],
    useCase: CalculateRailCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_cassette',
    titleKey: 'calculator.cassetteCeiling',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'cassetteSize',
        labelKey: 'input.tileSize',
        defaultValue: 60.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'cassettesNeeded': 'result.panels',
      'guideLength': 'result.guide',
      'hangersNeeded': 'result.hangers',
    },
    tips: const [
      'Кассеты легко заменяются при повреждении.',
      'Обеспечьте доступ к коммуникациям над потолком.',
      'Используйте уровень для монтажа направляющих.',
    ],
    useCase: CalculateCassetteCeiling(),
  ),
  CalculatorDefinition(
    id: 'ceilings_tiles',
    titleKey: 'calculator.ceilingTiles',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'tileSize',
        labelKey: 'input.tileSize',
        defaultValue: 50.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'tilesNeeded': 'result.tiles',
      'glueNeeded': 'result.glue',
      'primerNeeded': 'result.primer',
    },
    tips: const [
      'Проверьте ровность потолка перед укладкой.',
      'Используйте специальный клей для потолочной плитки.',
      'Начинайте укладку от центра комнаты.',
    ],
    useCase: CalculateCeilingTiles(),
  ),
  CalculatorDefinition(
    id: 'ceilings_insulation',
    titleKey: 'calculator.ceilingInsulation',
    category: 'Внутренняя отделка',
    subCategory: 'Потолки',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
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
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'sheetsNeeded': 'result.sheets',
      'vaporBarrierArea': 'result.vaporBarrier',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Используйте пароизоляцию с внутренней стороны.',
      'Не сжимайте утеплитель при укладке.',
      'Обеспечьте вентиляцию подкровельного пространства.',
    ],
    useCase: CalculateCeilingInsulation(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ ПЕРЕГОРОДОК =====

final List<CalculatorDefinition> partitionCalculators = [
  CalculatorDefinition(
    id: 'partitions_gkl',
    titleKey: 'calculator.gklPartition',
    category: 'Внутренняя отделка',
    subCategory: 'Перегородки',
    fields: [
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
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
    ],
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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
    fields: [
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
    resultLabels: {
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

/// ===== КАЛЬКУЛЯТОРЫ УТЕПЛЕНИЯ =====

final List<CalculatorDefinition> insulationCalculators = [
  CalculatorDefinition(
    id: 'insulation_mineral',
    titleKey: 'calculator.mineralWool',
    category: 'Внутренняя отделка',
    subCategory: 'Утепление',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 100.0,
      ),
      InputFieldDefinition(
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
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 50.0,
      ),
      InputFieldDefinition(
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

/// ===== КАЛЬКУЛЯТОРЫ НАРУЖНОЙ ОТДЕЛКИ =====

final List<CalculatorDefinition> exteriorCalculators = [
  CalculatorDefinition(
    id: 'exterior_siding',
    titleKey: 'calculator.siding',
    category: 'Наружная отделка',
    subCategory: 'Сайдинг',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 10.0,
        maxValue: 1000.0,
      ),
      InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 20.0,
        minValue: 10.0,
        maxValue: 50.0,
      ),
      InputFieldDefinition(
        key: 'panelLength',
        labelKey: 'input.panelLength',
        defaultValue: 300.0,
        minValue: 200.0,
        maxValue: 600.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 200.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'corners',
        labelKey: 'input.corners',
        defaultValue: 4.0,
        minValue: 4.0,
        maxValue: 20.0,
      ),
      InputFieldDefinition(
        key: 'soffitLength',
        labelKey: 'input.soffitLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'panelsNeeded': 'result.panels',
      'jProfileLength': 'result.jProfile',
      'cornerLength': 'result.corners',
      'startStripLength': 'result.startStrip',
      'finishStripLength': 'result.finishStrip',
      'soffitLength': 'result.soffit',
      'screwsNeeded': 'result.screws',
    },
    tips: const [
      'Не забудьте J-профиль, углы, стартовую и финишную планку.',
      'Оставляйте температурные зазоры (5-10 мм) для расширения материала.',
      'Монтируйте сайдинг снизу вверх, начиная со стартовой планки.',
      'Используйте саморезы с пресс-шайбой, не затягивайте их до упора.',
    ],
    useCase: CalculateSiding(),
  ),
  CalculatorDefinition(
    id: 'exterior_facade_panels',
    titleKey: 'calculator.facadePanels',
    category: 'Наружная отделка',
    subCategory: 'Фасадные панели',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 50.0,
      ),
      InputFieldDefinition(
        key: 'panelHeight',
        labelKey: 'input.panelHeight',
        defaultValue: 100.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'panelsNeeded': 'result.panels',
      'fastenersNeeded': 'result.fasteners',
      'cornersLength': 'result.corners',
      'startStripLength': 'result.startStrip',
    },
    tips: const [
      'Фасадные панели долговечны и не требуют ухода.',
      'Используйте качественные крепления.',
      'Оставляйте зазор для температурного расширения.',
    ],
    useCase: CalculateFacadePanels(),
  ),
  CalculatorDefinition(
    id: 'exterior_wood',
    titleKey: 'calculator.woodFacade',
    category: 'Наружная отделка',
    subCategory: 'Дерево',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'boardWidth',
        labelKey: 'input.boardWidth',
        defaultValue: 14.0,
      ),
      InputFieldDefinition(
        key: 'boardLength',
        labelKey: 'input.boardLength',
        defaultValue: 3.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'boardsNeeded': 'result.boards',
      'cornersLength': 'result.corners',
      'finishNeeded': 'result.finish',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Используйте защитные составы для дерева.',
      'Обрабатывайте торцы досок.',
      'Оставляйте зазор для вентиляции.',
    ],
    useCase: CalculateWoodFacade(),
  ),
  CalculatorDefinition(
    id: 'exterior_brick',
    titleKey: 'calculator.brickFacing',
    category: 'Наружная отделка',
    subCategory: 'Облицовочный кирпич',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 0.5,
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
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'wallHeight',
        labelKey: 'input.wallHeight',
        defaultValue: 2.5,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'usefulArea': 'result.usefulArea',
      'bricksNeeded': 'result.bricks',
      'mortarVolume': 'result.mortar',
      'cementNeeded': 'result.cement',
      'sandNeeded': 'result.sand',
      'reinforcementLength': 'result.reinforcement',
    },
    tips: const [
      'Используйте облицовочный кирпич с правильной геометрией.',
      'Армируйте через каждые 5 рядов.',
      'Проверяйте вертикальность каждого ряда.',
      'Защитите кладку от дождя во время работ.',
    ],
    useCase: CalculateBrickFacing(),
  ),
  CalculatorDefinition(
    id: 'exterior_wet_facade',
    titleKey: 'calculator.wetFacade',
    category: 'Наружная отделка',
    subCategory: 'Мокрый фасад',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
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
        defaultValue: 2.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'insulationVolume': 'result.insulationVolume',
      'sheetsNeeded': 'result.sheets',
      'glueNeeded': 'result.glue',
      'fastenersNeeded': 'result.fasteners',
      'meshArea': 'result.mesh',
      'plasterNeeded': 'result.plaster',
      'primerNeeded': 'result.primer',
      'finishNeeded': 'result.finish',
    },
    tips: const [
      'Работы выполняйте при температуре выше +5°C.',
      'Используйте армирующую сетку для прочности.',
      'Наносите штукатурку в два слоя.',
      'Защитите фасад от дождя во время работ.',
    ],
    useCase: CalculateWetFacade(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ КРОВЛИ =====

final List<CalculatorDefinition> roofingCalculators = [
  CalculatorDefinition(
    id: 'roofing_metal',
    titleKey: 'calculator.metalRoofing',
    category: 'Наружная отделка',
    subCategory: 'Кровля',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 10.0,
        maxValue: 1000.0,
      ),
      InputFieldDefinition(
        key: 'slope',
        labelKey: 'input.slope',
        defaultValue: 30.0,
        minValue: 5.0,
        maxValue: 60.0,
      ),
      InputFieldDefinition(
        key: 'sheetWidth',
        labelKey: 'input.sheetWidth',
        defaultValue: 1.18,
        minValue: 0.5,
        maxValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'sheetLength',
        labelKey: 'input.sheetLength',
        defaultValue: 2.5,
        minValue: 1.0,
        maxValue: 8.0,
      ),
      InputFieldDefinition(
        key: 'ridgeLength',
        labelKey: 'input.ridgeLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'valleyLength',
        labelKey: 'input.valleyLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 200.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'endLength',
        labelKey: 'input.endLength',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'realArea': 'result.realArea',
      'sheetsNeeded': 'result.sheets',
      'ridgeLength': 'result.ridge',
      'valleyLength': 'result.valley',
      'eaveLength': 'result.eave',
      'endLength': 'result.end',
      'screwsNeeded': 'result.screws',
      'waterproofingArea': 'result.waterproofing',
    },
    tips: const [
      'Учитывайте уклон крыши при расчёте площади.',
      'Используйте специальные саморезы с уплотнителями.',
      'Укладывайте листы с нахлёстом 15-20 см.',
      'Не забудьте про гидроизоляцию под кровлей.',
    ],
    useCase: CalculateRoofingMetal(),
  ),
  CalculatorDefinition(
    id: 'roofing_soft',
    titleKey: 'calculator.softRoofing',
    category: 'Наружная отделка',
    subCategory: 'Кровля',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'slope',
        labelKey: 'input.slope',
        defaultValue: 30.0,
      ),
      InputFieldDefinition(
        key: 'ridgeLength',
        labelKey: 'input.ridgeLength',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'valleyLength',
        labelKey: 'input.valleyLength',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'realArea': 'result.realArea',
      'packsNeeded': 'result.packs',
      'underlaymentArea': 'result.underlayment',
      'ridgeStripLength': 'result.ridge',
      'valleyCarpetLength': 'result.valley',
      'nailsNeeded': 'result.nails',
      'masticNeeded': 'result.mastic',
      'deckingArea': 'result.decking',
      'dripEdgeLength': 'result.dripEdge',
      'ventilationsNeeded': 'result.ventilation',
    },
    tips: const [
      'Битумная черепица подходит для крыш с уклоном от 12°.',
      'Обязательно используйте подкладочный ковёр.',
      'Монтаж при температуре выше +5°C.',
      'Укладывайте снизу вверх с перекрытием.',
    ],
    useCase: CalculateSoftRoofing(),
  ),
  CalculatorDefinition(
    id: 'roofing_gutters',
    titleKey: 'calculator.gutters',
    category: 'Наружная отделка',
    subCategory: 'Кровля',
    fields: [
      InputFieldDefinition(
        key: 'roofLength',
        labelKey: 'input.roofLength',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'roofArea',
        labelKey: 'input.roofArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'gutterLength',
        labelKey: 'input.gutterLength',
        defaultValue: 3.0,
      ),
    ],
    resultLabels: {
      'gutterLength': 'result.guide',
      'downpipeLength': 'result.pipeLength',
      'gutterBrackets': 'result.fasteners',
      'pipeBrackets': 'result.fasteners',
      'corners': 'result.corners',
      'endCaps': 'result.corners',
      'funnels': 'result.boxes',
      'elbows': 'result.fittings',
    },
    tips: const [
      'Устанавливайте желоба с уклоном 3-5 мм на 1 м.',
      'Кронштейны монтируются через каждые 50-60 см.',
      'На каждые 10 м² крыши — 1 водосточная труба.',
      'Используйте герметик для соединений.',
    ],
    useCase: CalculateGutters(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ ИНЖЕНЕРНЫХ РАБОТ =====

final List<CalculatorDefinition> engineeringCalculators = [
  CalculatorDefinition(
    id: 'engineering_electrics',
    titleKey: 'calculator.electrics',
    category: 'Инженерные работы',
    subCategory: 'Электрика',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 5.0,
        maxValue: 1000.0,
      ),
      InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
        minValue: 1.0,
        maxValue: 50.0,
      ),
      InputFieldDefinition(
        key: 'sockets',
        labelKey: 'input.sockets',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 200.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'switches',
        labelKey: 'input.switches',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'rooms': 'result.rooms',
      'sockets': 'result.sockets',
      'switches': 'result.switches',
      'wireLength': 'result.wire',
      'cableChannelLength': 'result.cableChannel',
      'circuitBreakers': 'result.breakers',
      'junctionBoxes': 'result.boxes',
    },
    tips: const [
      'Работы должен выполнять квалифицированный электрик.',
      'Используйте кабель сечением не менее 2.5 мм² для розеток.',
      'Установите УЗО для защиты от утечек тока.',
      'Проверьте все соединения перед включением.',
    ],
    useCase: CalculateElectrics(),
  ),
  CalculatorDefinition(
    id: 'engineering_plumbing',
    titleKey: 'calculator.plumbing',
    category: 'Инженерные работы',
    subCategory: 'Сантехника',
    fields: [
      InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'points',
        labelKey: 'input.points',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'pipeLength',
        labelKey: 'input.pipeLength',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'rooms': 'result.rooms',
      'points': 'result.points',
      'pipeLength': 'result.pipeLength',
      'fittingsNeeded': 'result.fittings',
      'tapsNeeded': 'result.taps',
      'mixersNeeded': 'result.mixers',
      'toiletsNeeded': 'result.toilets',
      'sinksNeeded': 'result.sinks',
      'showersNeeded': 'result.showers',
    },
    tips: const [
      'Используйте качественные фитинги для надёжности.',
      'Проверьте все соединения на герметичность.',
      'Установите запорные краны на каждую точку.',
      'Работы должен выполнять квалифицированный сантехник.',
    ],
    useCase: CalculatePlumbing(),
  ),
  CalculatorDefinition(
    id: 'engineering_heating',
    titleKey: 'calculator.heating',
    category: 'Инженерные работы',
    subCategory: 'Отопление',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 10.0,
        maxValue: 1000.0,
      ),
      InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
        minValue: 1.0,
        maxValue: 50.0,
      ),
      InputFieldDefinition(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        defaultValue: 2.5,
        minValue: 2.2,
        maxValue: 5.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'totalPower': 'result.power',
      'totalSections': 'result.sections',
      'pipeLength': 'result.pipeLength',
      'fittingsNeeded': 'result.fittings',
      'valvesNeeded': 'result.valves',
      'thermostatsNeeded': 'result.thermostats',
    },
    tips: const [
      'Расчёт мощности: 100 Вт на м² для средней полосы.',
      'Установите терморегуляторы для экономии.',
      'Используйте балансировочные краны.',
      'Работы должен выполнять квалифицированный специалист.',
    ],
    useCase: CalculateHeating(),
  ),
  CalculatorDefinition(
    id: 'engineering_ventilation',
    titleKey: 'calculator.ventilation',
    category: 'Инженерные работы',
    subCategory: 'Вентиляция',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'rooms',
        labelKey: 'input.rooms',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'ceilingHeight',
        labelKey: 'input.ceilingHeight',
        defaultValue: 2.5,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'airExchange': 'result.power',
      'ductsNeeded': 'result.boxes',
      'grillesNeeded': 'result.boxes',
      'fansNeeded': 'result.boxes',
      'ductLength': 'result.pipeLength',
    },
    tips: const [
      'Воздухообмен: минимум 3 м³/ч на м².',
      'Устанавливайте решётки вверху для вытяжки, внизу для притока.',
      'Проверьте тягу перед монтажом вентиляторов.',
    ],
    useCase: CalculateVentilation(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ ВАННОЙ =====

final List<CalculatorDefinition> bathroomCalculators = [
  CalculatorDefinition(
    id: 'bathroom_tile',
    titleKey: 'calculator.bathroomTile',
    category: 'Внутренняя отделка',
    subCategory: 'Ванная / туалет',
    fields: [
      InputFieldDefinition(
        key: 'wallArea',
        labelKey: 'input.wallArea',
        minValue: 0.0,
        maxValue: 100.0,
      ),
      InputFieldDefinition(
        key: 'floorArea',
        labelKey: 'input.floorArea',
        minValue: 0.0,
        maxValue: 50.0,
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
    resultLabels: {
      'wallArea': 'result.wallArea',
      'floorArea': 'result.floorArea',
      'totalTiles': 'result.tiles',
      'groutNeeded': 'result.grout',
      'glueNeeded': 'result.glue',
      'crossesNeeded': 'result.crosses',
      'waterproofingArea': 'result.waterproofing',
    },
    tips: const [
      'Используйте влагостойкий клей и затирку.',
      'Гидроизоляция обязательна для пола и нижней части стен.',
      'Проверьте ровность основания перед укладкой.',
      'Используйте крестики для равномерного шва.',
    ],
    useCase: CalculateBathroomTile(),
  ),
  CalculatorDefinition(
    id: 'bathroom_waterproof',
    titleKey: 'calculator.waterproofing',
    category: 'Внутренняя отделка',
    subCategory: 'Ванная / туалет',
    fields: [
      InputFieldDefinition(
        key: 'floorArea',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'wallHeight',
        labelKey: 'input.wallHeight',
        defaultValue: 0.3,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'floorArea': 'result.floorArea',
      'wallArea': 'result.wallArea',
      'totalArea': 'result.totalArea',
      'materialNeeded': 'result.material',
      'primerNeeded': 'result.primer',
      'tapeLength': 'result.tape',
    },
    tips: const [
      'Гидроизоляция обязательна для пола и стен на высоту 30 см.',
      'Используйте армирующую ленту для углов и стыков.',
      'Наносите материал в два слоя перпендикулярно.',
      'Проверьте целостность покрытия перед укладкой плитки.',
    ],
    useCase: CalculateWaterproofing(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ СМЕСЕЙ =====

final List<CalculatorDefinition> mixCalculators = [
  CalculatorDefinition(
    id: 'mixes_putty',
    titleKey: 'calculator.putty',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'puttyNeeded': 'result.putty',
      'primerNeeded': 'result.primer',
      'layers': 'result.layers',
      'spatulasNeeded': 'result.spatulas',
    },
    tips: const [
      'Стартовая шпаклёвка для выравнивания, финишная для гладкости.',
      'Наносите тонкими слоями.',
      'Шлифуйте между слоями.',
    ],
    useCase: CalculatePutty(),
  ),
  CalculatorDefinition(
    id: 'mixes_primer',
    titleKey: 'calculator.primer',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'primerNeeded': 'result.primer',
      'layers': 'result.layers',
      'rollersNeeded': 'result.rollers',
      'traysNeeded': 'result.trays',
    },
    tips: const [
      'Грунтовка улучшает адгезию материалов.',
      'Грунтовка глубокого проникновения для пористых поверхностей.',
      'Наносите равномерным слоем.',
    ],
    useCase: CalculatePrimer(),
  ),
  CalculatorDefinition(
    id: 'mixes_tile_glue',
    titleKey: 'calculator.tileGlue',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'tileSize',
        labelKey: 'input.tileSize',
        defaultValue: 30.0,
      ),
      InputFieldDefinition(
        key: 'layerThickness',
        labelKey: 'input.layerThickness',
        defaultValue: 5.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'glueNeeded': 'result.glue',
      'consumptionPerM2': 'result.consumption',
      'spatulasNeeded': 'result.spatulas',
    },
    tips: const [
      'Расход зависит от размера плитки и толщины слоя.',
      'Используйте зубчатый шпатель.',
      'Наносите клей на основание и плитку.',
    ],
    useCase: CalculateTileGlue(),
  ),
  CalculatorDefinition(
    id: 'mixes_plaster',
    titleKey: 'calculator.plaster',
    category: 'Внутренняя отделка',
    subCategory: 'Ровнители / смеси',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 10.0,
      ),
      InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'plasterNeeded': 'result.plaster',
      'primerNeeded': 'result.primer',
      'thickness': 'result.thickness',
      'beaconsNeeded': 'result.beacons',
    },
    tips: const [
      'Гипсовая штукатурка для внутренних работ.',
      'Цементная для влажных помещений и фасадов.',
      'Используйте маяки для ровной поверхности.',
    ],
    useCase: CalculatePlaster(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ ОКОН/ДВЕРЕЙ =====

final List<CalculatorDefinition> windowsDoorsCalculators = [
  CalculatorDefinition(
    id: 'windows_install',
    titleKey: 'calculator.windowInstallation',
    category: 'Внутренняя отделка',
    subCategory: 'Окна / двери',
    fields: [
      InputFieldDefinition(
        key: 'windows',
        labelKey: 'input.windows',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'windowWidth',
        labelKey: 'input.windowWidth',
        defaultValue: 1.5,
      ),
      InputFieldDefinition(
        key: 'windowHeight',
        labelKey: 'input.windowHeight',
        defaultValue: 1.4,
      ),
    ],
    resultLabels: {
      'windows': 'result.windows',
      'windowArea': 'result.windowArea',
      'foamNeeded': 'result.foam',
      'sillsNeeded': 'result.sills',
      'sillLength': 'result.sillLength',
      'slopeArea': 'result.slopeArea',
      'dripLength': 'result.dripLength',
    },
    tips: const [
      'Используйте монтажную пену для герметизации.',
      'Установите отливы для защиты от воды.',
      'Проверьте вертикальность и горизонтальность.',
    ],
    useCase: CalculateWindowInstallation(),
  ),
  CalculatorDefinition(
    id: 'doors_install',
    titleKey: 'calculator.doorInstallation',
    category: 'Внутренняя отделка',
    subCategory: 'Окна / двери',
    fields: [
      InputFieldDefinition(
        key: 'doors',
        labelKey: 'input.doors',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'doorWidth',
        labelKey: 'input.doorWidth',
        defaultValue: 0.9,
      ),
      InputFieldDefinition(
        key: 'doorHeight',
        labelKey: 'input.doorHeight',
        defaultValue: 2.1,
      ),
    ],
    resultLabels: {
      'doors': 'result.doors',
      'foamNeeded': 'result.foam',
      'architraveLength': 'result.architrave',
      'framesNeeded': 'result.frames',
      'hingesNeeded': 'result.hinges',
      'locksNeeded': 'result.locks',
    },
    tips: const [
      'Проверьте вертикальность дверной коробки.',
      'Используйте монтажную пену для фиксации.',
      'Установите наличники для завершения.',
    ],
    useCase: CalculateDoorInstallation(),
  ),
  CalculatorDefinition(
    id: 'slopes_finishing',
    titleKey: 'calculator.slopes',
    category: 'Внутренняя отделка',
    subCategory: 'Окна / двери',
    fields: [
      InputFieldDefinition(
        key: 'windows',
        labelKey: 'input.windows',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'windowWidth',
        labelKey: 'input.windowWidth',
        defaultValue: 1.5,
      ),
      InputFieldDefinition(
        key: 'windowHeight',
        labelKey: 'input.windowHeight',
        defaultValue: 1.4,
      ),
      InputFieldDefinition(
        key: 'slopeWidth',
        labelKey: 'input.slopeWidth',
        defaultValue: 0.3,
      ),
    ],
    resultLabels: {
      'windows': 'result.windows',
      'slopeArea': 'result.slopeArea',
      'puttyNeeded': 'result.putty',
      'primerNeeded': 'result.primer',
      'paintNeeded': 'result.paint',
      'cornerLength': 'result.corner',
    },
    tips: const [
      'Используйте уголки для ровных углов.',
      'Шпаклёвку наносите тонким слоем.',
      'Красьте в 2 слоя для равномерного покрытия.',
    ],
    useCase: CalculateSlopes(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ ШУМОИЗОЛЯЦИИ =====

final List<CalculatorDefinition> soundInsulationCalculators = [
  CalculatorDefinition(
    id: 'insulation_sound',
    titleKey: 'calculator.soundInsulation',
    category: 'Внутренняя отделка',
    subCategory: 'Шумоизоляция',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 50.0,
      ),
      InputFieldDefinition(
        key: 'insulationType',
        labelKey: 'input.insulationType',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'volume': 'result.volume',
      'sheetsNeeded': 'result.sheets',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Шумоизоляция особенно важна для межкомнатных перегородок.',
      'Используйте материалы с высоким коэффициентом звукопоглощения.',
      'Обеспечьте герметичность стыков.',
    ],
    useCase: CalculateSoundInsulation(),
  ),
];

/// ===== КАЛЬКУЛЯТОРЫ КОНСТРУКЦИЙ =====

final List<CalculatorDefinition> structureCalculators = [
  CalculatorDefinition(
    id: 'stairs',
    titleKey: 'calculator.stairs',
    category: 'Конструкции',
    subCategory: 'Лестницы',
    fields: [
      InputFieldDefinition(
        key: 'floorHeight',
        labelKey: 'input.floorHeight',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'stepHeight',
        labelKey: 'input.stepHeight',
        defaultValue: 0.18,
      ),
      InputFieldDefinition(
        key: 'stepWidth',
        labelKey: 'input.stepWidth',
        defaultValue: 0.28,
      ),
      InputFieldDefinition(
        key: 'stepCount',
        labelKey: 'input.stepCount',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'width',
        labelKey: 'input.width',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'materialType',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'floorHeight': 'result.height',
      'stepCount': 'result.steps',
      'stepHeight': 'result.stepHeight',
      'stepWidth': 'result.stepWidth',
      'flightLength': 'result.length',
      'stepArea': 'result.area',
      'totalArea': 'result.totalArea',
      'railingLength': 'result.railing',
      'balustersNeeded': 'result.balusters',
      'supportPosts': 'result.posts',
      'stringersNeeded': 'result.stringers',
      'concreteVolume': 'result.volume',
    },
    tips: const [
      'Высота ступени должна быть 15-20 см для комфортного подъёма.',
      'Ширина проступи (ступени) должна быть не менее 28 см.',
      'Ширина лестницы для жилых домов - минимум 90 см.',
      'Для деревянной лестницы используйте твёрдые породы дерева (дуб, ясень).',
      'Бетонная лестница требует армирования и опалубки.',
      'Перила должны быть на высоте 90-100 см от ступени.',
      'Балясины устанавливаются с шагом 10-15 см для безопасности детей.',
    ],
    useCase: CalculateStairs(),
  ),
  CalculatorDefinition(
    id: 'fence',
    titleKey: 'calculator.fence',
    category: 'Конструкции',
    subCategory: 'Заборы',
    fields: [
      InputFieldDefinition(
        key: 'length',
        labelKey: 'input.length',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.0,
      ),
      InputFieldDefinition(
        key: 'materialType',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'gates',
        labelKey: 'input.gates',
        defaultValue: 1.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'wickets',
        labelKey: 'input.wickets',
        defaultValue: 1.0,
        required: false,
      ),
    ],
    resultLabels: {
      'length': 'result.length',
      'height': 'result.height',
      'fenceArea': 'result.area',
      'postsNeeded': 'result.posts',
      'lagCount': 'result.lags',
      'lagLength': 'result.lagLength',
      'materialArea': 'result.material',
      'bricksNeeded': 'result.bricks',
      'mortarNeeded': 'result.mortar',
      'foundationVolume': 'result.volume',
      'gates': 'result.gates',
      'wickets': 'result.wickets',
      'fastenersNeeded': 'result.fasteners',
    },
    tips: const [
      'Столбы устанавливаются на глубину 1/3 от высоты забора.',
      'Для профлиста используйте оцинкованные саморезы с уплотнителями.',
      'Деревянный забор требует обработки антисептиком.',
      'Кирпичный забор нуждается в фундаменте.',
      'Расстояние между столбами: 2-3 метра в зависимости от материала.',
      'Ворота и калитки должны быть на 5-10 см выше уровня земли.',
    ],
    useCase: CalculateFence(),
  ),
  CalculatorDefinition(
    id: 'blind_area',
    titleKey: 'calculator.blindArea',
    category: 'Конструкции',
    subCategory: 'Отмостка',
    fields: [
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'width',
        labelKey: 'input.width',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 100.0,
      ),
      InputFieldDefinition(
        key: 'materialType',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulation',
        defaultValue: 0.0,
        required: false,
      ),
    ],
    resultLabels: {
      'perimeter': 'result.perimeter',
      'width': 'result.width',
      'area': 'result.area',
      'thickness': 'result.thickness',
      'volume': 'result.volume',
      'sandVolume': 'result.sand',
      'gravelVolume': 'result.gravel',
      'insulationVolume': 'result.insulationVolume',
      'insulationArea': 'result.insulationArea',
      'tilesNeeded': 'result.tiles',
      'curbLength': 'result.curb',
      'rebarNeeded': 'result.reinforcement',
      'jointsCount': 'result.joints',
    },
    tips: const [
      'Ширина отмостки должна быть не менее 1 метра.',
      'Отмостка должна иметь уклон 2-3% от стены для отвода воды.',
      'Бетонная отмостка требует деформационных швов каждые 2-3 метра.',
      'Утепление отмостки особенно важно для домов с цокольным этажом.',
      'Песчаная подушка должна быть утрамбована.',
      'Бордюр защищает отмостку от разрушения краёв.',
    ],
    useCase: CalculateBlindArea(),
  ),
  CalculatorDefinition(
    id: 'basement',
    titleKey: 'calculator.basement',
    category: 'Конструкции',
    subCategory: 'Подвал / Погреб',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.5,
      ),
      InputFieldDefinition(
        key: 'wallThickness',
        labelKey: 'input.thickness',
        defaultValue: 0.4,
      ),
      InputFieldDefinition(
        key: 'materialType',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'waterproofing',
        labelKey: 'input.waterproofing',
        defaultValue: 1.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulation',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'ventilation',
        labelKey: 'input.ventilation',
        defaultValue: 1.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'stairs',
        labelKey: 'input.stairs',
        defaultValue: 1.0,
        required: false,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'height': 'result.height',
      'volume': 'result.volume',
      'perimeter': 'result.perimeter',
      'wallArea': 'result.wallArea',
      'wallVolume': 'result.wallVolume',
      'floorArea': 'result.floorArea',
      'concreteVolume': 'result.volume',
      'bricksNeeded': 'result.bricks',
      'blocksNeeded': 'result.blocks',
      'mortarNeeded': 'result.mortar',
      'waterproofingArea': 'result.waterproofing',
      'insulationArea': 'result.insulationArea',
      'insulationVolume': 'result.insulationVolume',
      'rebarNeeded': 'result.reinforcement',
      'ventilationPipes': 'result.pipes',
      'ventilationGrilles': 'result.grilles',
      'stairsNeeded': 'result.stairs',
    },
    tips: const [
      'Гидроизоляция обязательна для подвалов и погребов.',
      'Вентиляция необходима для предотвращения сырости.',
      'Утепление стен снижает теплопотери и предотвращает промерзание.',
      'Бетонные стены требуют армирования.',
      'Пол должен иметь уклон к дренажному отверстию.',
      'Лестница должна быть удобной и безопасной.',
    ],
    useCase: CalculateBasement(),
  ),
  CalculatorDefinition(
    id: 'balcony',
    titleKey: 'calculator.balcony',
    category: 'Внутренняя отделка',
    subCategory: 'Балкон / Лоджия',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 1.1,
      ),
      InputFieldDefinition(
        key: 'glazing',
        labelKey: 'input.glazing',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulation',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'floorType',
        labelKey: 'input.floorType',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'wallFinish',
        labelKey: 'input.wallFinish',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'floorArea': 'result.floorArea',
      'wallArea': 'result.wallArea',
      'ceilingArea': 'result.ceilingArea',
      'glazingArea': 'result.glazing',
      'glazingLength': 'result.glazingLength',
      'insulationArea': 'result.insulationArea',
      'insulationVolume': 'result.insulationVolume',
      'vaporBarrierArea': 'result.vaporBarrier',
      'tilesNeeded': 'result.tiles',
      'selfLevelingMix': 'result.mix',
      'woodArea': 'result.wood',
      'paintNeeded': 'result.paint',
      'panelsNeeded': 'result.panels',
      'wallTilesNeeded': 'result.tiles',
      'ceilingPaintNeeded': 'result.paint',
      'railingLength': 'result.railing',
    },
    tips: const [
      'Остекление балкона значительно увеличивает полезную площадь.',
      'Тёплое остекление позволяет использовать балкон круглый год.',
      'Утепление обязательно для тёплого остекления.',
      'Пароизоляция защищает утеплитель от влаги.',
      'Для пола на открытом балконе используйте морозостойкую плитку.',
      'Террасная доска подходит для открытых балконов.',
    ],
    useCase: CalculateBalcony(),
  ),
  CalculatorDefinition(
    id: 'attic',
    titleKey: 'calculator.attic',
    category: 'Внутренняя отделка',
    subCategory: 'Мансарда',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'roofArea',
        labelKey: 'input.roofArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'wallArea',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'floorArea',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'windows',
        labelKey: 'input.windows',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulation',
        defaultValue: 1.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'wallFinish',
        labelKey: 'input.wallFinish',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'floorType',
        labelKey: 'input.floorType',
        defaultValue: 1.0,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'roofArea': 'result.roofArea',
      'wallArea': 'result.wallArea',
      'floorArea': 'result.floorArea',
      'insulationArea': 'result.insulationArea',
      'insulationVolume': 'result.insulationVolume',
      'vaporBarrierArea': 'result.vaporBarrier',
      'woodArea': 'result.wood',
      'gklSheets': 'result.sheets',
      'panelsNeeded': 'result.panels',
      'laminatePacks': 'result.packs',
      'parquetPlanks': 'result.planks',
      'linoleumRolls': 'result.rolls',
      'windows': 'result.windows',
      'windowArea': 'result.windowArea',
      'fixturesNeeded': 'result.fixtures',
    },
    tips: const [
      'Утепление мансарды обязательно для комфортного проживания.',
      'Толщина утеплителя должна быть не менее 15-20 см.',
      'Пароизоляция защищает утеплитель от влаги изнутри.',
      'Мансардные окна обеспечивают естественное освещение.',
      'Вагонка создаёт уютную атмосферу в мансарде.',
      'Проверьте несущую способность перекрытия перед укладкой пола.',
    ],
    useCase: CalculateAttic(),
  ),
  CalculatorDefinition(
    id: 'terrace',
    titleKey: 'calculator.terrace',
    category: 'Конструкции',
    subCategory: 'Терраса / Веранда',
    fields: [
      InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'floorType',
        labelKey: 'input.floorType',
        defaultValue: 1.0,
      ),
      InputFieldDefinition(
        key: 'railing',
        labelKey: 'input.railing',
        defaultValue: 1.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'roof',
        labelKey: 'input.roof',
        defaultValue: 0.0,
        required: false,
      ),
      InputFieldDefinition(
        key: 'roofType',
        labelKey: 'input.roofType',
        defaultValue: 1.0,
        required: false,
      ),
    ],
    resultLabels: {
      'area': 'result.area',
      'floorArea': 'result.floorArea',
      'deckingArea': 'result.decking',
      'tilesNeeded': 'result.tiles',
      'deckingBoards': 'result.boards',
      'railingLength': 'result.railing',
      'railingPosts': 'result.posts',
      'roofArea': 'result.roofArea',
      'polycarbonateSheets': 'result.sheets',
      'profiledSheets': 'result.sheets',
      'roofingMaterial': 'result.roofing',
      'roofPosts': 'result.posts',
      'foundationVolume': 'result.volume',
    },
    tips: const [
      'Террасная доска (декинг) устойчива к влаге и перепадам температур.',
      'Плитка для террасы должна быть морозостойкой и нескользкой.',
      'Ограждение обеспечивает безопасность, особенно если есть дети.',
      'Кровля защищает от дождя и солнца.',
      'Поликарбонат пропускает свет и создаёт лёгкую конструкцию.',
      'Столбы для кровли должны быть установлены на фундамент.',
    ],
    useCase: CalculateTerrace(),
  ),
];

/// Общий список всех калькуляторов приложения.
final List<CalculatorDefinition> finishCalculators = [];

final List<CalculatorDefinition> calculators = [
  ...foundationCalculators,
  ...wallCalculators,
  ...floorCalculators,
  ...ceilingCalculators,
  ...partitionCalculators,
  ...insulationCalculators,
  ...soundInsulationCalculators,
  ...exteriorCalculators,
  ...roofingCalculators,
  ...bathroomCalculators,
  ...engineeringCalculators,
  ...mixCalculators,
  ...windowsDoorsCalculators,
  ...structureCalculators,
  ...finishCalculators,
];

/// Найти калькулятор по ID.
CalculatorDefinition? findCalculatorById(String id) {
  try {
    return calculators.firstWhere((calc) => calc.id == id);
  } catch (_) {
    return null;
  }
}
