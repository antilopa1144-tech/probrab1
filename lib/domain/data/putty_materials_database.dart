/// База данных шпаклёвочных материалов
///
/// Содержит информацию о популярных брендах шпаклёвок с характеристиками
/// расхода, фасовки и применения.
library;

/// Тип шпаклёвки по назначению
enum PuttyPurpose {
  /// Стартовая (базовая, выравнивающая) - слой 3-50мм
  start,

  /// Финишная - слой 0.5-3мм
  finish,

  /// Универсальная - слой 1-10мм
  universal,
}

/// Форма выпуска
enum PuttyForm {
  /// Сухая смесь (мешки)
  dry,

  /// Готовая паста (вёдра)
  paste,
}

/// Состав шпаклёвки
enum PuttyComposition {
  /// Гипсовая - только сухие помещения
  gypsum,

  /// Полимерная (латексная, акриловая) - универсальная
  polymer,

  /// Цементная - фасад, влажные помещения
  cement,
}

/// Тип поверхности для применения
enum SurfaceType {
  /// Только стены
  wall,

  /// Только потолок (лёгкие пасты)
  ceiling,

  /// Универсальная (стены и потолок)
  universal,
}

/// Расширение для SurfaceType
extension SurfaceTypeExtension on SurfaceType {
  String get labelKey {
    switch (this) {
      case SurfaceType.wall:
        return 'putty.surface.wall';
      case SurfaceType.ceiling:
        return 'putty.surface.ceiling';
      case SurfaceType.universal:
        return 'putty.surface.universal';
    }
  }

  String get descriptionKey {
    switch (this) {
      case SurfaceType.wall:
        return 'putty.surface.wall_desc';
      case SurfaceType.ceiling:
        return 'putty.surface.ceiling_desc';
      case SurfaceType.universal:
        return 'putty.surface.universal_desc';
    }
  }
}

/// Материал шпаклёвки
class PuttyMaterial {
  final String id;
  final String brand;
  final String name;
  final PuttyPurpose purpose;
  final PuttyForm form;
  final PuttyComposition composition;

  /// Расход кг/м² при слое 1мм
  final double consumptionPerMm;

  /// Размер упаковки по умолчанию (кг для сухих, л для паст)
  final double packageSize;

  /// Единица измерения упаковки
  final String packageUnit;

  /// Доступные фасовки (кг)
  final List<double> availableWeights;

  /// Тип поверхности (стены, потолок, универсальная)
  final SurfaceType surfaceType;

  /// Максимальная толщина слоя (мм)
  final double maxLayerThickness;

  /// Минимальная толщина слоя (мм)
  final double minLayerThickness;

  /// Время высыхания между слоями (часы)
  final int dryingTimeHours;

  /// Подходит для влажных помещений
  final bool isWaterproof;

  /// Рекомендуемое применение (ключ локализации)
  final String recommendationKey;

  /// Популярность (для сортировки, 1-10)
  final int popularity;

  const PuttyMaterial({
    required this.id,
    required this.brand,
    required this.name,
    required this.purpose,
    required this.form,
    required this.composition,
    required this.consumptionPerMm,
    required this.packageSize,
    required this.packageUnit,
    this.availableWeights = const [],
    this.surfaceType = SurfaceType.universal,
    required this.maxLayerThickness,
    required this.minLayerThickness,
    required this.dryingTimeHours,
    required this.isWaterproof,
    required this.recommendationKey,
    required this.popularity,
  });

  /// Полное название (бренд + название)
  String get fullName => '$brand $name';

  /// Доступные веса для выбора (если список пуст, используем packageSize)
  List<double> get weights =>
      availableWeights.isNotEmpty ? availableWeights : [packageSize];

  /// Расчёт количества упаковок для указанного веса
  int calculatePackagesForWeight(
      double area, double layerThickness, int layers, double weight) {
    final totalConsumption = area * consumptionPerMm * layerThickness * layers;
    return (totalConsumption / weight).ceil();
  }

  /// Расчёт количества упаковок (использует packageSize по умолчанию)
  int calculatePackages(double area, double layerThickness, int layers) {
    return calculatePackagesForWeight(area, layerThickness, layers, packageSize);
  }

  /// Расчёт общего расхода в кг
  double calculateTotalConsumption(
      double area, double layerThickness, int layers) {
    return area * consumptionPerMm * layerThickness * layers;
  }
}

/// База данных шпаклёвочных материалов
class PuttyMaterialsDatabase {
  PuttyMaterialsDatabase._();

  // ═══════════════════════════════════════════════════════════════════════════
  // СТАРТОВЫЕ ШПАКЛЁВКИ (БАЗОВЫЕ / ВЫРАВНИВАЮЩИЕ)
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<PuttyMaterial> startMaterials = [
    // --- Knauf ---
    PuttyMaterial(
      id: 'knauf_hp_start',
      brand: 'Knauf',
      name: 'HP Start',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.9,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [10, 25, 30],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 15,
      minLayerThickness: 3,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.knauf_hp_start.rec',
      popularity: 10,
    ),
    PuttyMaterial(
      id: 'knauf_fugen',
      brand: 'Knauf',
      name: 'Фуген',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.8,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 10, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 10,
      minLayerThickness: 1,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.knauf_fugen.rec',
      popularity: 9,
    ),
    PuttyMaterial(
      id: 'knauf_uniflott',
      brand: 'Knauf',
      name: 'Унифлотт',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.3,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 5,
      minLayerThickness: 1,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.knauf_uniflott.rec',
      popularity: 8,
    ),

    // --- Волма ---
    PuttyMaterial(
      id: 'volma_sloy',
      brand: 'Волма',
      name: 'Слой',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.9,
      packageSize: 30,
      packageUnit: 'кг',
      availableWeights: [15, 30],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 60,
      minLayerThickness: 5,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.volma_sloy.rec',
      popularity: 8,
    ),
    PuttyMaterial(
      id: 'volma_standard',
      brand: 'Волма',
      name: 'Стандарт',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 25],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 10,
      minLayerThickness: 1,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.volma_standard.rec',
      popularity: 7,
    ),

    // --- Terraco ---
    PuttyMaterial(
      id: 'terraco_handycoat_start',
      brand: 'Terraco',
      name: 'Handycoat Start',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 15, 25],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 8,
      minLayerThickness: 1,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.terraco_start.rec',
      popularity: 7,
    ),

    // --- Ceresit ---
    PuttyMaterial(
      id: 'ceresit_ct29',
      brand: 'Ceresit',
      name: 'CT 29',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.cement,
      consumptionPerMm: 1.8,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 25],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 20,
      minLayerThickness: 2,
      dryingTimeHours: 48,
      isWaterproof: true,
      recommendationKey: 'putty.material.ceresit_ct29.rec',
      popularity: 6,
    ),

    // --- Bergauf ---
    PuttyMaterial(
      id: 'bergauf_easy_band',
      brand: 'Bergauf',
      name: 'Easy Band',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.9,
      packageSize: 30,
      packageUnit: 'кг',
      availableWeights: [5, 30],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 40,
      minLayerThickness: 5,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.bergauf_easy.rec',
      popularity: 6,
    ),

    // --- Unis ---
    PuttyMaterial(
      id: 'unis_teplolon',
      brand: 'Unis',
      name: 'Теплон',
      purpose: PuttyPurpose.start,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.9,
      packageSize: 30,
      packageUnit: 'кг',
      availableWeights: [15, 30],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 50,
      minLayerThickness: 5,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.unis_teplolon.rec',
      popularity: 5,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ФИНИШНЫЕ ШПАКЛЁВКИ - СУХИЕ
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<PuttyMaterial> finishDryMaterials = [
    // --- Weber-Vetonit ---
    PuttyMaterial(
      id: 'vetonit_lr_plus',
      brand: 'Weber-Vetonit',
      name: 'LR+',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.2,
      packageSize: 20,
      packageUnit: 'кг',
      availableWeights: [5, 20, 25],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 5,
      minLayerThickness: 0.3,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.vetonit_lr.rec',
      popularity: 10,
    ),
    PuttyMaterial(
      id: 'vetonit_kr',
      brand: 'Weber-Vetonit',
      name: 'KR',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.2,
      packageSize: 20,
      packageUnit: 'кг',
      availableWeights: [5, 20],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 4,
      minLayerThickness: 0.3,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.vetonit_kr.rec',
      popularity: 8,
    ),
    PuttyMaterial(
      id: 'vetonit_vh',
      brand: 'Weber-Vetonit',
      name: 'VH',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.cement,
      consumptionPerMm: 1.2,
      packageSize: 20,
      packageUnit: 'кг',
      availableWeights: [5, 20],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 4,
      minLayerThickness: 0.3,
      dryingTimeHours: 48,
      isWaterproof: true,
      recommendationKey: 'putty.material.vetonit_vh.rec',
      popularity: 7,
    ),

    // --- Knauf ---
    PuttyMaterial(
      id: 'knauf_hp_finish',
      brand: 'Knauf',
      name: 'HP Finish',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.9,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 10, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 3,
      minLayerThickness: 0.5,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.knauf_finish.rec',
      popularity: 8,
    ),
    PuttyMaterial(
      id: 'knauf_rotband_finish',
      brand: 'Knauf',
      name: 'Ротбанд Финиш',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 25],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 5,
      minLayerThickness: 0.2,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.knauf_rotband_finish.rec',
      popularity: 7,
    ),

    // --- Terraco ---
    PuttyMaterial(
      id: 'terraco_handycoat_finish',
      brand: 'Terraco',
      name: 'Handycoat Finish',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.1,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 15, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.terraco_finish.rec',
      popularity: 6,
    ),

    // --- Волма ---
    PuttyMaterial(
      id: 'volma_finish',
      brand: 'Волма',
      name: 'Финиш',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 20, 25],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 3,
      minLayerThickness: 0.2,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.volma_finish.rec',
      popularity: 6,
    ),

    // --- Старатели ---
    PuttyMaterial(
      id: 'starateli_finish_plus',
      brand: 'Старатели',
      name: 'Финишная Плюс',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 1.0,
      packageSize: 20,
      packageUnit: 'кг',
      availableWeights: [5, 20],
      surfaceType: SurfaceType.wall,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.starateli_finish.rec',
      popularity: 5,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ФИНИШНЫЕ ШПАКЛЁВКИ - ГОТОВЫЕ ПАСТЫ
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<PuttyMaterial> finishPasteMaterials = [
    // --- Sheetrock ---
    PuttyMaterial(
      id: 'sheetrock_superfinish',
      brand: 'Sheetrock',
      name: 'SuperFinish',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.0,
      packageSize: 28,
      packageUnit: 'кг',
      availableWeights: [5.6, 17, 28],
      surfaceType: SurfaceType.ceiling,
      maxLayerThickness: 2,
      minLayerThickness: 0.2,
      dryingTimeHours: 6,
      isWaterproof: false,
      recommendationKey: 'putty.material.sheetrock_super.rec',
      popularity: 10,
    ),
    PuttyMaterial(
      id: 'sheetrock_fill_finish',
      brand: 'Sheetrock',
      name: 'Fill & Finish Light',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 0.7,
      packageSize: 17,
      packageUnit: 'кг',
      availableWeights: [3.5, 17],
      surfaceType: SurfaceType.ceiling,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 5,
      isWaterproof: false,
      recommendationKey: 'putty.material.sheetrock_fill.rec',
      popularity: 8,
    ),

    // --- Danogips ---
    PuttyMaterial(
      id: 'danogips_superfinish',
      brand: 'Danogips',
      name: 'SuperFinish',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.0,
      packageSize: 17,
      packageUnit: 'кг',
      availableWeights: [3.5, 17, 28],
      surfaceType: SurfaceType.ceiling,
      maxLayerThickness: 2,
      minLayerThickness: 0.2,
      dryingTimeHours: 6,
      isWaterproof: false,
      recommendationKey: 'putty.material.danogips_super.rec',
      popularity: 9,
    ),
    PuttyMaterial(
      id: 'danogips_dano_jet_9',
      brand: 'Danogips',
      name: 'Dano Jet 9',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 0.9,
      packageSize: 10,
      packageUnit: 'кг',
      availableWeights: [3, 10, 20],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 4,
      isWaterproof: false,
      recommendationKey: 'putty.material.danogips_jet.rec',
      popularity: 7,
    ),

    // --- Terraco ---
    PuttyMaterial(
      id: 'terraco_handycoat_ready',
      brand: 'Terraco',
      name: 'Handycoat Ready Mix',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 15, 25],
      surfaceType: SurfaceType.ceiling,
      maxLayerThickness: 2,
      minLayerThickness: 0.2,
      dryingTimeHours: 6,
      isWaterproof: false,
      recommendationKey: 'putty.material.terraco_ready.rec',
      popularity: 8,
    ),
    PuttyMaterial(
      id: 'terraco_handycoat_lite',
      brand: 'Terraco',
      name: 'Handycoat Lite',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 0.8,
      packageSize: 15,
      packageUnit: 'кг',
      availableWeights: [5, 15],
      surfaceType: SurfaceType.ceiling,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 4,
      isWaterproof: false,
      recommendationKey: 'putty.material.terraco_lite.rec',
      popularity: 7,
    ),

    // --- Текс ---
    PuttyMaterial(
      id: 'teks_profit',
      brand: 'Текс',
      name: 'Профи',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.1,
      packageSize: 16,
      packageUnit: 'кг',
      availableWeights: [1.5, 5, 16],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 2,
      minLayerThickness: 0.3,
      dryingTimeHours: 5,
      isWaterproof: false,
      recommendationKey: 'putty.material.teks_profit.rec',
      popularity: 5,
    ),

    // --- Semin ---
    PuttyMaterial(
      id: 'semin_sem_light',
      brand: 'Semin',
      name: 'Sem-Light',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 25],
      surfaceType: SurfaceType.ceiling,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 4,
      isWaterproof: false,
      recommendationKey: 'putty.material.semin_light.rec',
      popularity: 6,
    ),
    PuttyMaterial(
      id: 'semin_sem_joint',
      brand: 'Semin',
      name: 'Sem-Joint',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [7, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 4,
      isWaterproof: false,
      recommendationKey: 'putty.material.semin_joint.rec',
      popularity: 7,
    ),

    // --- VGT ---
    PuttyMaterial(
      id: 'vgt_premium',
      brand: 'VGT',
      name: 'Premium',
      purpose: PuttyPurpose.finish,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 0.9,
      packageSize: 16,
      packageUnit: 'кг',
      availableWeights: [1.5, 3.6, 7, 16, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 3,
      minLayerThickness: 0.3,
      dryingTimeHours: 4,
      isWaterproof: false,
      recommendationKey: 'putty.material.vgt_premium.rec',
      popularity: 6,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // УНИВЕРСАЛЬНЫЕ ШПАКЛЁВКИ
  // ═══════════════════════════════════════════════════════════════════════════

  static const List<PuttyMaterial> universalMaterials = [
    // --- Knauf ---
    PuttyMaterial(
      id: 'knauf_fugen_universal',
      brand: 'Knauf',
      name: 'Фуген',
      purpose: PuttyPurpose.universal,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.8,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 10, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 10,
      minLayerThickness: 0.5,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.knauf_fugen_uni.rec',
      popularity: 9,
    ),
    PuttyMaterial(
      id: 'knauf_multi_finish',
      brand: 'Knauf',
      name: 'Мульти-Финиш',
      purpose: PuttyPurpose.universal,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 5,
      minLayerThickness: 0.2,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.knauf_multi.rec',
      popularity: 8,
    ),

    // --- Terraco ---
    PuttyMaterial(
      id: 'terraco_handycoat_universal',
      brand: 'Terraco',
      name: 'Handycoat Universal',
      purpose: PuttyPurpose.universal,
      form: PuttyForm.paste,
      composition: PuttyComposition.polymer,
      consumptionPerMm: 1.0,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 15, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 5,
      minLayerThickness: 0.3,
      dryingTimeHours: 6,
      isWaterproof: false,
      recommendationKey: 'putty.material.terraco_universal.rec',
      popularity: 7,
    ),

    // --- Волма ---
    PuttyMaterial(
      id: 'volma_silk',
      brand: 'Волма',
      name: 'Шёлк',
      purpose: PuttyPurpose.universal,
      form: PuttyForm.dry,
      composition: PuttyComposition.gypsum,
      consumptionPerMm: 0.9,
      packageSize: 25,
      packageUnit: 'кг',
      availableWeights: [5, 15, 25],
      surfaceType: SurfaceType.universal,
      maxLayerThickness: 5,
      minLayerThickness: 0.2,
      dryingTimeHours: 24,
      isWaterproof: false,
      recommendationKey: 'putty.material.volma_silk.rec',
      popularity: 6,
    ),
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ
  // ═══════════════════════════════════════════════════════════════════════════

  /// Все материалы
  static List<PuttyMaterial> get allMaterials => [
        ...startMaterials,
        ...finishDryMaterials,
        ...finishPasteMaterials,
        ...universalMaterials,
      ];

  /// Получить материал по ID
  static PuttyMaterial? getById(String id) {
    for (final material in allMaterials) {
      if (material.id == id) return material;
    }
    return null;
  }

  /// Получить стартовые материалы отсортированные по популярности
  static List<PuttyMaterial> getStartMaterialsSorted() {
    final list = List<PuttyMaterial>.from(startMaterials);
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list;
  }

  /// Получить финишные сухие материалы отсортированные по популярности
  static List<PuttyMaterial> getFinishDryMaterialsSorted() {
    final list = List<PuttyMaterial>.from(finishDryMaterials);
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list;
  }

  /// Получить финишные пасты отсортированные по популярности
  static List<PuttyMaterial> getFinishPasteMaterialsSorted() {
    final list = List<PuttyMaterial>.from(finishPasteMaterials);
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list;
  }

  /// Получить универсальные материалы
  static List<PuttyMaterial> getUniversalMaterialsSorted() {
    final list = List<PuttyMaterial>.from(universalMaterials);
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list;
  }

  /// Получить материалы для влажных помещений
  static List<PuttyMaterial> getWaterproofMaterials() {
    return allMaterials.where((m) => m.isWaterproof).toList();
  }

  /// Получить материалы по бренду
  static List<PuttyMaterial> getByBrand(String brand) {
    return allMaterials.where((m) => m.brand == brand).toList();
  }

  /// Все бренды
  static List<String> get allBrands {
    final brands = <String>{};
    for (final m in allMaterials) {
      brands.add(m.brand);
    }
    final list = brands.toList();
    list.sort();
    return list;
  }

  /// Получить материалы для стен (wall + universal)
  static List<PuttyMaterial> getWallMaterials() {
    return allMaterials
        .where((m) =>
            m.surfaceType == SurfaceType.wall ||
            m.surfaceType == SurfaceType.universal)
        .toList();
  }

  /// Получить материалы для потолка (ceiling + universal)
  static List<PuttyMaterial> getCeilingMaterials() {
    return allMaterials
        .where((m) =>
            m.surfaceType == SurfaceType.ceiling ||
            m.surfaceType == SurfaceType.universal)
        .toList();
  }

  /// Получить материалы по типу поверхности
  static List<PuttyMaterial> getBySurfaceType(SurfaceType type) {
    if (type == SurfaceType.wall) {
      return getWallMaterials();
    } else if (type == SurfaceType.ceiling) {
      return getCeilingMaterials();
    }
    return allMaterials;
  }

  /// Получить финишные материалы для стен
  static List<PuttyMaterial> getFinishWallMaterialsSorted() {
    final list = [...finishDryMaterials, ...finishPasteMaterials]
        .where((m) =>
            m.surfaceType == SurfaceType.wall ||
            m.surfaceType == SurfaceType.universal)
        .toList();
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list;
  }

  /// Получить финишные материалы для потолка (лёгкие пасты)
  static List<PuttyMaterial> getFinishCeilingMaterialsSorted() {
    final list = [...finishDryMaterials, ...finishPasteMaterials]
        .where((m) =>
            m.surfaceType == SurfaceType.ceiling ||
            m.surfaceType == SurfaceType.universal)
        .toList();
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list;
  }

  /// Получить все финишные материалы отсортированные
  static List<PuttyMaterial> getAllFinishMaterialsSorted() {
    final list = [...finishDryMaterials, ...finishPasteMaterials];
    list.sort((a, b) => b.popularity.compareTo(a.popularity));
    return list;
  }
}

/// Состояние стен
enum WallCondition {
  /// Ровные (новостройка, ГКЛ) - множитель ×1
  smooth,

  /// Средние (небольшие неровности) - множитель ×1.5
  medium,

  /// Кривые (старый фонд, большие перепады) - множитель ×2
  rough,
}

/// Расширение для получения множителя
extension WallConditionExtension on WallCondition {
  double get multiplier {
    switch (this) {
      case WallCondition.smooth:
        return 1.0;
      case WallCondition.medium:
        return 1.5;
      case WallCondition.rough:
        return 2.0;
    }
  }

  String get labelKey {
    switch (this) {
      case WallCondition.smooth:
        return 'putty.wall_condition.smooth';
      case WallCondition.medium:
        return 'putty.wall_condition.medium';
      case WallCondition.rough:
        return 'putty.wall_condition.rough';
    }
  }

  String get descriptionKey {
    switch (this) {
      case WallCondition.smooth:
        return 'putty.wall_condition.smooth_desc';
      case WallCondition.medium:
        return 'putty.wall_condition.medium_desc';
      case WallCondition.rough:
        return 'putty.wall_condition.rough_desc';
    }
  }
}

/// Пресеты типовых комнат
class RoomPreset {
  final String id;
  final String labelKey;
  final double length;
  final double width;
  final double height;

  const RoomPreset({
    required this.id,
    required this.labelKey,
    required this.length,
    required this.width,
    required this.height,
  });
}

/// Пресеты комнат
class RoomPresets {
  RoomPresets._();

  static const List<RoomPreset> presets = [
    RoomPreset(
      id: 'bathroom_small',
      labelKey: 'preset.bathroom_small',
      length: 2.0,
      width: 1.5,
      height: 2.7,
    ),
    RoomPreset(
      id: 'bathroom',
      labelKey: 'preset.bathroom',
      length: 2.5,
      width: 2.0,
      height: 2.7,
    ),
    RoomPreset(
      id: 'toilet',
      labelKey: 'preset.toilet',
      length: 1.5,
      width: 1.0,
      height: 2.7,
    ),
    RoomPreset(
      id: 'kitchen_small',
      labelKey: 'preset.kitchen_small',
      length: 3.0,
      width: 2.5,
      height: 2.7,
    ),
    RoomPreset(
      id: 'kitchen',
      labelKey: 'preset.kitchen',
      length: 4.0,
      width: 3.0,
      height: 2.7,
    ),
    RoomPreset(
      id: 'bedroom',
      labelKey: 'preset.bedroom',
      length: 4.0,
      width: 3.5,
      height: 2.7,
    ),
    RoomPreset(
      id: 'living_room',
      labelKey: 'preset.living_room',
      length: 5.0,
      width: 4.0,
      height: 2.7,
    ),
    RoomPreset(
      id: 'studio',
      labelKey: 'preset.studio',
      length: 6.0,
      width: 4.0,
      height: 2.7,
    ),
    RoomPreset(
      id: 'corridor',
      labelKey: 'preset.corridor',
      length: 5.0,
      width: 1.5,
      height: 2.7,
    ),
  ];
}
