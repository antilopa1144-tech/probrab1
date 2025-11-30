/// Типы строительных материалов.
enum MaterialType {
  /// Бетон
  concrete,

  /// Кирпич
  brick,

  /// Газоблок
  gasBlock,

  /// Дерево
  wood,

  /// Металл
  metal,

  /// Гипсокартон
  drywall,

  /// ГВЛ
  gvl,

  /// Утеплитель
  insulation,

  /// Краска
  paint,

  /// Обои
  wallpaper,

  /// Плитка керамическая
  ceramicTile,

  /// Ламинат
  laminate,

  /// Паркет
  parquet,

  /// Линолеум
  linoleum,

  /// Ковролин
  carpet,

  /// Штукатурка
  plaster,

  /// Шпаклёвка
  putty,

  /// Грунтовка
  primer,

  /// Клей
  glue,

  /// Цемент
  cement,

  /// Песок
  sand,

  /// Щебень
  gravel,

  /// Арматура
  rebar,

  /// Профиль металлический
  metalProfile,

  /// Сайдинг
  siding,

  /// Кровельный материал
  roofingMaterial,

  /// Гидроизоляция
  waterproofing,

  /// Теплоизоляция
  thermalInsulation,

  /// Звукоизоляция
  soundInsulation,

  /// Электропроводка
  wiring,

  /// Трубы
  pipes,

  /// Прочее
  other;

  /// Получить ключ перевода для типа материала
  String get translationKey {
    switch (this) {
      case MaterialType.concrete:
        return 'material.concrete';
      case MaterialType.brick:
        return 'material.brick';
      case MaterialType.gasBlock:
        return 'material.gas_block';
      case MaterialType.wood:
        return 'material.wood';
      case MaterialType.metal:
        return 'material.metal';
      case MaterialType.drywall:
        return 'material.drywall';
      case MaterialType.gvl:
        return 'material.gvl';
      case MaterialType.insulation:
        return 'material.insulation';
      case MaterialType.paint:
        return 'material.paint';
      case MaterialType.wallpaper:
        return 'material.wallpaper';
      case MaterialType.ceramicTile:
        return 'material.ceramic_tile';
      case MaterialType.laminate:
        return 'material.laminate';
      case MaterialType.parquet:
        return 'material.parquet';
      case MaterialType.linoleum:
        return 'material.linoleum';
      case MaterialType.carpet:
        return 'material.carpet';
      case MaterialType.plaster:
        return 'material.plaster';
      case MaterialType.putty:
        return 'material.putty';
      case MaterialType.primer:
        return 'material.primer';
      case MaterialType.glue:
        return 'material.glue';
      case MaterialType.cement:
        return 'material.cement';
      case MaterialType.sand:
        return 'material.sand';
      case MaterialType.gravel:
        return 'material.gravel';
      case MaterialType.rebar:
        return 'material.rebar';
      case MaterialType.metalProfile:
        return 'material.metal_profile';
      case MaterialType.siding:
        return 'material.siding';
      case MaterialType.roofingMaterial:
        return 'material.roofing_material';
      case MaterialType.waterproofing:
        return 'material.waterproofing';
      case MaterialType.thermalInsulation:
        return 'material.thermal_insulation';
      case MaterialType.soundInsulation:
        return 'material.sound_insulation';
      case MaterialType.wiring:
        return 'material.wiring';
      case MaterialType.pipes:
        return 'material.pipes';
      case MaterialType.other:
        return 'material.other';
    }
  }
}
