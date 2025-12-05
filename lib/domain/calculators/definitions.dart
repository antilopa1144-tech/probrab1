// Репозиторий расчётов (цены и прочее)

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/core/cache/calculation_cache.dart';
// Модульные калькуляторы
import 'modules/all_modules.dart' as modules;
import 'package:probrab_ai/domain/usecases/calculate_sound_insulation.dart';
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
/// Перенесено в modules/walls/wall_calculators.dart
final List<CalculatorDefinition> wallCalculators = modules.wallCalculators;

/// ===== КАЛЬКУЛЯТОРЫ ПОЛОВ =====
/// Перенесено в modules/floors/floor_calculators.dart
final List<CalculatorDefinition> floorCalculators = modules.floorCalculators;

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
/// Перенесено в modules/exterior/exterior_calculators.dart
final List<CalculatorDefinition> exteriorCalculators = modules.exteriorCalculators;

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
