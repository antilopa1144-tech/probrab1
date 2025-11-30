/// Типы строительных работ.
enum WorkType {
  /// Фундаментные работы
  foundation,

  /// Стены и перегородки
  walls,

  /// Кровельные работы
  roofing,

  /// Облицовка фасада
  facade,

  /// Утепление
  insulation,

  /// Черновые полы
  roughFlooring,

  /// Чистовые полы
  finishFlooring,

  /// Черновой потолок
  roughCeiling,

  /// Чистовой потолок
  finishCeiling,

  /// Штукатурные работы
  plastering,

  /// Шпаклёвка
  puttying,

  /// Грунтовка
  priming,

  /// Покраска
  painting,

  /// Обои
  wallpapering,

  /// Плитка
  tiling,

  /// Гидроизоляция
  waterproofing,

  /// Электрика
  electrical,

  /// Сантехника
  plumbing,

  /// Отопление
  heating,

  /// Вентиляция
  ventilation,

  /// Окна
  windows,

  /// Двери
  doors,

  /// Прочие работы
  other;

  /// Получить ключ перевода для типа работ
  String get translationKey {
    switch (this) {
      case WorkType.foundation:
        return 'work_type.foundation';
      case WorkType.walls:
        return 'work_type.walls';
      case WorkType.roofing:
        return 'work_type.roofing';
      case WorkType.facade:
        return 'work_type.facade';
      case WorkType.insulation:
        return 'work_type.insulation';
      case WorkType.roughFlooring:
        return 'work_type.rough_flooring';
      case WorkType.finishFlooring:
        return 'work_type.finish_flooring';
      case WorkType.roughCeiling:
        return 'work_type.rough_ceiling';
      case WorkType.finishCeiling:
        return 'work_type.finish_ceiling';
      case WorkType.plastering:
        return 'work_type.plastering';
      case WorkType.puttying:
        return 'work_type.puttying';
      case WorkType.priming:
        return 'work_type.priming';
      case WorkType.painting:
        return 'work_type.painting';
      case WorkType.wallpapering:
        return 'work_type.wallpapering';
      case WorkType.tiling:
        return 'work_type.tiling';
      case WorkType.waterproofing:
        return 'work_type.waterproofing';
      case WorkType.electrical:
        return 'work_type.electrical';
      case WorkType.plumbing:
        return 'work_type.plumbing';
      case WorkType.heating:
        return 'work_type.heating';
      case WorkType.ventilation:
        return 'work_type.ventilation';
      case WorkType.windows:
        return 'work_type.windows';
      case WorkType.doors:
        return 'work_type.doors';
      case WorkType.other:
        return 'work_type.other';
    }
  }
}
