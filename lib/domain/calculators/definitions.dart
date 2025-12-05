// Репозиторий расчётов (цены и прочее)

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/core/cache/calculation_cache.dart';
// Модульные калькуляторы
import 'modules/all_modules.dart' as modules;
import 'package:probrab_ai/domain/usecases/calculate_wall_paint.dart';
import 'package:probrab_ai/domain/usecases/calculate_wallpaper.dart';
import 'package:probrab_ai/domain/usecases/calculate_decorative_plaster.dart';
import 'package:probrab_ai/domain/usecases/calculate_laminate.dart';
import 'package:probrab_ai/domain/usecases/calculate_screed.dart';
import 'package:probrab_ai/domain/usecases/calculate_tile.dart';
import 'package:probrab_ai/domain/usecases/calculate_linoleum.dart';
import 'package:probrab_ai/domain/usecases/calculate_warm_floor.dart';
import 'package:probrab_ai/domain/usecases/calculate_parquet.dart';
import 'package:probrab_ai/domain/usecases/calculate_self_leveling_floor.dart';
import 'package:probrab_ai/domain/usecases/calculate_siding.dart';
import 'package:probrab_ai/domain/usecases/calculate_wet_facade.dart';
import 'package:probrab_ai/domain/usecases/calculate_carpet.dart';
import 'package:probrab_ai/domain/usecases/calculate_brick_facing.dart';
import 'package:probrab_ai/domain/usecases/calculate_wall_tile.dart';
import 'package:probrab_ai/domain/usecases/calculate_mdf_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_pvc_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_decorative_stone.dart';
import 'package:probrab_ai/domain/usecases/calculate_wood_wall.dart';
import 'package:probrab_ai/domain/usecases/calculate_gvl_wall.dart';
import 'package:probrab_ai/domain/usecases/calculate_3d_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_facade_panels.dart';
import 'package:probrab_ai/domain/usecases/calculate_wood_facade.dart';
import 'package:probrab_ai/domain/usecases/calculate_sound_insulation.dart';
import 'package:probrab_ai/domain/usecases/calculate_floor_insulation.dart';
import 'package:probrab_ai/domain/usecases/calculate_stairs.dart';
import 'package:probrab_ai/domain/usecases/calculate_fence.dart';
import 'package:probrab_ai/domain/usecases/calculate_blind_area.dart';
import 'package:probrab_ai/domain/usecases/calculate_basement.dart';
import 'package:probrab_ai/domain/usecases/calculate_balcony.dart';
import 'package:probrab_ai/domain/usecases/calculate_attic.dart';
import 'package:probrab_ai/domain/usecases/calculate_terrace.dart';

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
        // НЕ логируем в Analytics для кэшированных результатов
        return CalculatorResult(values: cachedValues, totalPrice: null);
      }
    }

    // Выполняем расчёт
    final result = useCase.call(inputs, priceList);

    // Логирование использования калькулятора в Firebase Analytics
    // ТОЛЬКО для новых расчётов (не из кэша)
    try {
      FirebaseAnalytics.instance.logEvent(
        name: 'calculator_used',
        parameters: {
          'calculator_id': id,
          'calculator_category': category,
          'calculator_subcategory': subCategory,
        },
      );
    } catch (e) {
      // Игнорируем ошибки Firebase в тестах
    }

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
/// Импортированы из модуля modules/foundation/
final List<CalculatorDefinition> foundationCalculators = modules.foundationCalculators;

/// ===== КАЛЬКУЛЯТОРЫ СТЕН =====

final List<CalculatorDefinition> wallCalculators = [
  CalculatorDefinition(
    id: 'walls_paint',
    titleKey: 'calculator.wallPaint',
    category: 'Внутренняя отделка',
    subCategory: 'Стены',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 1000.0,
      ),
      const InputFieldDefinition(
        key: 'layers',
        labelKey: 'input.layers',
        defaultValue: 2.0,
        minValue: 1.0,
        maxValue: 5.0,
      ),
      const InputFieldDefinition(
        key: 'consumption',
        labelKey: 'input.consumption',
        defaultValue: 0.15,
        minValue: 0.05,
        maxValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 500.0,
      ),
      const InputFieldDefinition(
        key: 'rollWidth',
        labelKey: 'input.rollWidth',
        defaultValue: 0.53,
        minValue: 0.3,
        maxValue: 1.5,
      ),
      const InputFieldDefinition(
        key: 'rollLength',
        labelKey: 'input.rollLength',
        defaultValue: 10.05,
        minValue: 5.0,
        maxValue: 25.0,
      ),
      const InputFieldDefinition(
        key: 'rapport',
        labelKey: 'input.rapport',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 1.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'wallHeight',
        labelKey: 'input.wallHeight',
        defaultValue: 2.5,
        minValue: 2.0,
        maxValue: 5.0,
      ),
      const InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 100.0,
        required: false,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 2.0,
      ),
      const InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'tileWidth',
        labelKey: 'input.tileWidth',
        defaultValue: 30.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 500.0,
      ),
      const InputFieldDefinition(
        key: 'packArea',
        labelKey: 'input.packArea',
        defaultValue: 2.0,
        minValue: 1.0,
        maxValue: 5.0,
      ),
      const InputFieldDefinition(
        key: 'underlayThickness',
        labelKey: 'input.underlayThickness',
        defaultValue: 3.0,
        minValue: 2.0,
        maxValue: 10.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 1000.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 50.0,
        minValue: 20.0,
        maxValue: 200.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 0.5,
        maxValue: 500.0,
      ),
      const InputFieldDefinition(
        key: 'tileWidth',
        labelKey: 'input.tileWidth',
        defaultValue: 30.0,
        minValue: 10.0,
        maxValue: 120.0,
      ),
      const InputFieldDefinition(
        key: 'tileHeight',
        labelKey: 'input.tileHeight',
        defaultValue: 30.0,
        minValue: 10.0,
        maxValue: 120.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'rollWidth',
        labelKey: 'input.rollWidth',
        defaultValue: 3.0,
      ),
      const InputFieldDefinition(
        key: 'rollLength',
        labelKey: 'input.rollLength',
        defaultValue: 30.0,
      ),
      const InputFieldDefinition(
        key: 'overlap',
        labelKey: 'input.overlap',
        defaultValue: 5.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 1.0,
        maxValue: 200.0,
      ),
      const InputFieldDefinition(
        key: 'power',
        labelKey: 'input.power',
        defaultValue: 150.0,
        minValue: 80.0,
        maxValue: 250.0,
      ),
      const InputFieldDefinition(
        key: 'type',
        labelKey: 'input.type',
        defaultValue: 2.0,
        minValue: 1.0,
        maxValue: 2.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'plankWidth',
        labelKey: 'input.plankWidth',
        defaultValue: 7.0,
      ),
      const InputFieldDefinition(
        key: 'plankLength',
        labelKey: 'input.plankLength',
        defaultValue: 40.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'insulationThickness',
        labelKey: 'input.insulationThickness',
        defaultValue: 100.0,
      ),
      const InputFieldDefinition(
        key: 'insulationType',
        labelKey: 'input.insulationType',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
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
/// Перенесено в modules/ceilings/ceiling_calculators.dart
final List<CalculatorDefinition> ceilingCalculators = modules.ceilingCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ПЕРЕГОРОДОК =====
/// Перенесено в modules/partitions/partition_calculators.dart
final List<CalculatorDefinition> partitionCalculators = modules.partitionCalculators;

/// ===== КАЛЬКУЛЯТОРЫ УТЕПЛЕНИЯ =====
/// Перенесено в modules/insulation/insulation_calculators.dart
final List<CalculatorDefinition> insulationCalculators = modules.insulationCalculators;

/// ===== КАЛЬКУЛЯТОРЫ НАРУЖНОЙ ОТДЕЛКИ =====

final List<CalculatorDefinition> exteriorCalculators = [
  CalculatorDefinition(
    id: 'exterior_siding',
    titleKey: 'calculator.siding',
    category: 'Наружная отделка',
    subCategory: 'Сайдинг',
    fields: [
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        minValue: 10.0,
        maxValue: 1000.0,
      ),
      const InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 20.0,
        minValue: 10.0,
        maxValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'panelLength',
        labelKey: 'input.panelLength',
        defaultValue: 300.0,
        minValue: 200.0,
        maxValue: 600.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        minValue: 0.0,
        maxValue: 200.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'corners',
        labelKey: 'input.corners',
        defaultValue: 4.0,
        minValue: 4.0,
        maxValue: 20.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'panelWidth',
        labelKey: 'input.panelWidth',
        defaultValue: 50.0,
      ),
      const InputFieldDefinition(
        key: 'panelHeight',
        labelKey: 'input.panelHeight',
        defaultValue: 100.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'boardWidth',
        labelKey: 'input.boardWidth',
        defaultValue: 14.0,
      ),
      const InputFieldDefinition(
        key: 'boardLength',
        labelKey: 'input.boardLength',
        defaultValue: 3.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 0.5,
      ),
      const InputFieldDefinition(
        key: 'windowsArea',
        labelKey: 'input.windowsArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'doorsArea',
        labelKey: 'input.doorsArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'insulationThickness',
        labelKey: 'input.insulationThickness',
        defaultValue: 100.0,
      ),
      const InputFieldDefinition(
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
/// Перенесено в modules/roofing/roofing_calculators.dart
final List<CalculatorDefinition> roofingCalculators = modules.roofingCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ИНЖЕНЕРНЫХ РАБОТ =====
/// Перенесено в modules/engineering/engineering_calculators.dart
final List<CalculatorDefinition> engineeringCalculators = modules.engineeringCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ВАННОЙ =====

/// Перенесено в modules/bathroom/bathroom_calculators.dart
final List<CalculatorDefinition> bathroomCalculators = modules.bathroomCalculators;

/// ===== КАЛЬКУЛЯТОРЫ СМЕСЕЙ =====
/// Перенесено в modules/mix/mix_calculators.dart
final List<CalculatorDefinition> mixCalculators = modules.mixCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ОКОН/ДВЕРЕЙ =====
/// Перенесено в modules/windows_doors/windows_doors_calculators.dart
final List<CalculatorDefinition> windowsDoorsCalculators = modules.windowsDoorsCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ШУМОИЗОЛЯЦИИ =====

final List<CalculatorDefinition> soundInsulationCalculators = [
  CalculatorDefinition(
    id: 'insulation_sound',
    titleKey: 'calculator.soundInsulation',
    category: 'Внутренняя отделка',
    subCategory: 'Шумоизоляция',
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
      const InputFieldDefinition(
        key: 'floorHeight',
        labelKey: 'input.floorHeight',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'stepHeight',
        labelKey: 'input.stepHeight',
        defaultValue: 0.18,
      ),
      const InputFieldDefinition(
        key: 'stepWidth',
        labelKey: 'input.stepWidth',
        defaultValue: 0.28,
      ),
      const InputFieldDefinition(
        key: 'stepCount',
        labelKey: 'input.stepCount',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'width',
        labelKey: 'input.width',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'length',
        labelKey: 'input.length',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.0,
      ),
      const InputFieldDefinition(
        key: 'materialType',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'gates',
        labelKey: 'input.gates',
        defaultValue: 1.0,
        required: false,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'width',
        labelKey: 'input.width',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'thickness',
        labelKey: 'input.thickness',
        defaultValue: 100.0,
      ),
      const InputFieldDefinition(
        key: 'materialType',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 2.5,
      ),
      const InputFieldDefinition(
        key: 'wallThickness',
        labelKey: 'input.thickness',
        defaultValue: 0.4,
      ),
      const InputFieldDefinition(
        key: 'materialType',
        labelKey: 'input.type',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'waterproofing',
        labelKey: 'input.waterproofing',
        defaultValue: 1.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulation',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'ventilation',
        labelKey: 'input.ventilation',
        defaultValue: 1.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'height',
        labelKey: 'input.height',
        defaultValue: 1.1,
      ),
      const InputFieldDefinition(
        key: 'glazing',
        labelKey: 'input.glazing',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulation',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'floorType',
        labelKey: 'input.floorType',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'roofArea',
        labelKey: 'input.roofArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'wallArea',
        labelKey: 'input.wallArea',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'floorArea',
        labelKey: 'input.floorArea',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'windows',
        labelKey: 'input.windows',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'insulation',
        labelKey: 'input.insulation',
        defaultValue: 1.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'wallFinish',
        labelKey: 'input.wallFinish',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
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
      const InputFieldDefinition(
        key: 'area',
        labelKey: 'input.area',
        defaultValue: 0.0,
      ),
      const InputFieldDefinition(
        key: 'perimeter',
        labelKey: 'input.perimeter',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'floorType',
        labelKey: 'input.floorType',
        defaultValue: 1.0,
      ),
      const InputFieldDefinition(
        key: 'railing',
        labelKey: 'input.railing',
        defaultValue: 1.0,
        required: false,
      ),
      const InputFieldDefinition(
        key: 'roof',
        labelKey: 'input.roof',
        defaultValue: 0.0,
        required: false,
      ),
      const InputFieldDefinition(
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

/// Централизованный реестр всех калькуляторов приложения.
/// Предоставляет оптимизированный доступ к калькуляторам через индексы.
///
/// Использование:
/// ```dart
/// final calc = CalculatorRegistryV1.instance.getById('laminate');
/// final floors = CalculatorRegistryV1.instance.getByCategory('Полы');
/// final results = CalculatorRegistryV1.instance.search('ламинат');
/// ```
class CalculatorRegistryV1 {
  // Singleton pattern
  static final CalculatorRegistryV1 _instance = CalculatorRegistryV1._internal();
  static CalculatorRegistryV1 get instance => _instance;

  CalculatorRegistryV1._internal() {
    _buildIndices();
  }

  /// Индекс для быстрого поиска по ID (O(1))
  final Map<String, CalculatorDefinition> _idIndex = {};

  /// Индекс для быстрого поиска по категории (O(1))
  final Map<String, List<CalculatorDefinition>> _categoryIndex = {};

  /// Индекс для быстрого поиска по подкатегории (O(1))
  final Map<String, List<CalculatorDefinition>> _subCategoryIndex = {};

  /// Построить все индексы из существующего списка calculators
  void _buildIndices() {
    _idIndex.clear();
    _categoryIndex.clear();
    _subCategoryIndex.clear();

    for (final calc in calculators) {
      // Индекс по ID
      _idIndex[calc.id] = calc;

      // Индекс по категории
      _categoryIndex.putIfAbsent(calc.category, () => []).add(calc);

      // Индекс по подкатегории
      if (calc.subCategory.isNotEmpty) {
        _subCategoryIndex.putIfAbsent(calc.subCategory, () => []).add(calc);
      }
    }
  }

  /// Получить калькулятор по ID (O(1))
  CalculatorDefinition? getById(String id) {
    return _idIndex[id];
  }

  /// Получить все калькуляторы категории (O(1))
  List<CalculatorDefinition> getByCategory(String category) {
    return _categoryIndex[category] ?? [];
  }

  /// Получить все калькуляторы подкатегории (O(1))
  List<CalculatorDefinition> getBySubCategory(String subCategory) {
    return _subCategoryIndex[subCategory] ?? [];
  }

  /// Получить все уникальные категории
  List<String> getAllCategories() {
    return _categoryIndex.keys.toList()..sort();
  }

  /// Получить все подкатегории для категории
  List<String> getSubCategories(String category) {
    final calculators = getByCategory(category);
    final subCategories = calculators
        .map((c) => c.subCategory)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return subCategories..sort();
  }

  /// Поиск калькуляторов по запросу
  /// Возвращает список калькуляторов, отсортированных по релевантности
  List<CalculatorDefinition> search(String query) {
    if (query.isEmpty) {
      return [];
    }

    final normalizedQuery = query.toLowerCase().trim();
    final results = <_SearchResultV1>[];

    for (final calculator in calculators) {
      int relevance = 0;

      // Поиск в ID (наивысший приоритет)
      if (calculator.id.toLowerCase().contains(normalizedQuery)) {
        relevance += 100;
      }

      // Поиск в titleKey
      if (calculator.titleKey.toLowerCase().contains(normalizedQuery)) {
        relevance += 50;
      }

      // Поиск в категории
      if (calculator.category.toLowerCase().contains(normalizedQuery)) {
        relevance += 30;
      }

      // Поиск в подкатегории
      if (calculator.subCategory.toLowerCase().contains(normalizedQuery)) {
        relevance += 20;
      }

      if (relevance > 0) {
        results.add(_SearchResultV1(calculator, relevance));
      }
    }

    // Сортировка по релевантности
    results.sort((a, b) => b.relevance.compareTo(a.relevance));

    return results.map((r) => r.calculator).toList();
  }

  /// Получить все калькуляторы
  List<CalculatorDefinition> getAll() {
    return List.unmodifiable(calculators);
  }

  /// Получить количество калькуляторов
  int get count => calculators.length;

  /// Проверить, существует ли калькулятор с данным ID
  bool contains(String id) {
    return _idIndex.containsKey(id);
  }

  /// Получить статистику по категориям
  Map<String, int> getCategoryStats() {
    return _categoryIndex.map((category, calculators) {
      return MapEntry(category, calculators.length);
    });
  }

  /// Фильтровать калькуляторы по условию
  List<CalculatorDefinition> filter(
    bool Function(CalculatorDefinition) predicate,
  ) {
    return calculators.where(predicate).toList();
  }

  /// Пересоздать индексы (используется при динамическом обновлении списка)
  void rebuildIndices() {
    _buildIndices();
  }
}

/// Внутренний класс для хранения результатов поиска с релевантностью
class _SearchResultV1 {
  final CalculatorDefinition calculator;
  final int relevance;

  _SearchResultV1(this.calculator, this.relevance);
}
