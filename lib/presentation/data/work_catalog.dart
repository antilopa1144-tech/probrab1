import 'package:flutter/material.dart';

import '../../domain/entities/object_type.dart';

class WorkItemDefinition {
  final String id;
  final String title;
  final IconData icon;
  final String? description;
  final List<String> tags;
  final List<String> tips;
  final String? calculatorId;

  const WorkItemDefinition({
    required this.id,
    required this.title,
    required this.icon,
    this.description,
    this.tags = const [],
    this.tips = const [],
    this.calculatorId,
  });
}

class WorkSectionDefinition {
  final String id;
  final String title;
  final IconData icon;
  final String? description;
  final List<WorkItemDefinition> items;

  const WorkSectionDefinition({
    required this.id,
    required this.title,
    required this.icon,
    this.description,
    this.items = const [],
  });
}

class WorkAreaDefinition {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<WorkSectionDefinition> sections;

  const WorkAreaDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.sections = const [],
  });
}

class WorkCatalog {
  static List<WorkAreaDefinition> areasFor(ObjectType type) {
    return _catalog[type] ?? _houseAreas;
  }

  static WorkAreaDefinition? findArea(ObjectType type, String areaId) {
    final areas = areasFor(type);
    try {
      return areas.firstWhere((area) => area.id == areaId);
    } catch (_) {
      return areas.isNotEmpty ? areas.first : null;
    }
  }

  static WorkSectionDefinition? findSection(
    ObjectType type,
    String areaId,
    String sectionId,
  ) {
    final area = findArea(type, areaId);
    if (area == null) return null;
    try {
      return area.sections.firstWhere((section) => section.id == sectionId);
    } catch (_) {
      return null;
    }
  }
}

const List<WorkAreaDefinition> _houseAreas = [
  WorkAreaDefinition(
    id: 'interior',
    title: 'Внутренняя отделка',
    subtitle: 'Стены, потолки, полы, перегородки и окна',
    icon: Icons.home_repair_service_rounded,
    color: Color(0xFF80DEEA),
    sections: [
      WorkSectionDefinition(
        id: 'walls',
        title: 'Стены',
        description: 'Покраска, обои, штукатурка, панели и камень',
        icon: Icons.format_paint_rounded,
        items: [
          WorkItemDefinition(
            id: 'walls_top',
            title: 'Стены (ТОП-использование)',
            icon: Icons.trending_up_rounded,
            description: 'Подбор популярных решений по стенам',
          ),
          WorkItemDefinition(
            id: 'walls_paint',
            title: 'Покраска',
            icon: Icons.format_paint,
            calculatorId: 'wall_paint',
            tips: [
              'Рекомендуется купить грунтовку для улучшения сцепления.',
              'Используйте малярный скотч для защиты углов и плинтуса.',
              'Возьмите валик средней ворсистости и кювету.',
              'Для углов пригодятся кисти шириной 50 мм.',
              'Не забудьте плёнку для защиты пола и мебели.',
            ],
          ),
          WorkItemDefinition(
            id: 'walls_wallpaper',
            title: 'Обои с раппортом',
            icon: Icons.wallpaper,
            calculatorId: 'walls_wallpaper',
            tips: [
              'Проверьте совпадение рисунка (раппорта) перед поклейкой.',
              'Рекомендуется добавить 10 % к площади для подрезки.',
              'Используйте лазерный уровень для контроля вертикали.',
              'Клей подбирайте по типу обоев (флизелиновые/виниловые).',
            ],
          ),
          WorkItemDefinition(
            id: 'walls_decor_plaster',
            title: 'Декоративная штукатурка',
            icon: Icons.style,
            description: 'Венецианка, фактура, структурные покрытия',
            calculatorId: 'walls_decor_plaster',
            tips: [
              'Используйте грунтовку глубокого проникновения.',
              'Возьмите шпатели и кельмы разных размеров.',
              'Для венецианской штукатурки нужна кельма из нержавейки.',
            ],
          ),
          WorkItemDefinition(
            id: 'walls_decor_stone',
            title: 'Декоративный камень',
            icon: Icons.terrain,
            calculatorId: 'walls_decor_stone',
          ),
          WorkItemDefinition(
            id: 'walls_flex_stone',
            title: 'Гибкий камень',
            icon: Icons.texture,
          ),
          WorkItemDefinition(
            id: 'walls_pvc_panels',
            title: 'Панели ПВХ',
            icon: Icons.dashboard,
            calculatorId: 'walls_pvc_panels',
          ),
          WorkItemDefinition(
            id: 'walls_mdf_panels',
            title: 'Панели МДФ',
            icon: Icons.view_stream,
            calculatorId: 'walls_mdf_panels',
          ),
          WorkItemDefinition(
            id: 'walls_gipso_panels',
            title: 'Панели гипсовинил',
            icon: Icons.view_week,
          ),
          WorkItemDefinition(
            id: 'walls_3d_panels',
            title: '3D панели',
            icon: Icons.auto_awesome_mosaic,
            calculatorId: 'walls_3d_panels',
          ),
          WorkItemDefinition(
            id: 'walls_wood',
            title: 'Вагонка / брус',
            icon: Icons.park_rounded,
            calculatorId: 'walls_wood',
          ),
          WorkItemDefinition(
            id: 'walls_gkl',
            title: 'Обшивка ГКЛ',
            icon: Icons.layers,
          ),
          WorkItemDefinition(
            id: 'walls_gvl',
            title: 'Обшивка ГВЛ',
            icon: Icons.layers_clear,
            calculatorId: 'walls_gvl',
          ),
          WorkItemDefinition(
            id: 'walls_tile',
            title: 'Плитка на стены',
            icon: Icons.apps,
            calculatorId: 'walls_tile',
          ),
          WorkItemDefinition(
            id: 'walls_mixes',
            title: 'Смеси для стен',
            icon: Icons.inventory_2,
            description: 'Шпаклёвка старт/финиш, грунт, клей',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'ceilings',
        title: 'Потолки',
        description: 'Покраска, натяжные, подвесные и утепление',
        icon: Icons.expand_less_rounded,
        items: [
          WorkItemDefinition(
            id: 'ceilings_paint',
            title: 'Покраска / побелка',
            icon: Icons.brush_outlined,
            calculatorId: 'ceilings_paint',
          ),
          WorkItemDefinition(
            id: 'ceilings_stretch',
            title: 'Натяжной потолок',
            icon: Icons.blur_linear,
            calculatorId: 'ceilings_stretch',
          ),
          WorkItemDefinition(
            id: 'ceilings_gkl',
            title: 'Подвесной ГКЛ',
            icon: Icons.grid_on,
            calculatorId: 'ceilings_gkl',
          ),
          WorkItemDefinition(
            id: 'ceilings_rail',
            title: 'Реечный потолок',
            icon: Icons.view_column,
            calculatorId: 'ceilings_rail',
          ),
          WorkItemDefinition(
            id: 'ceilings_cassette',
            title: 'Кассетный',
            icon: Icons.grid_4x4,
            calculatorId: 'ceilings_cassette',
          ),
          WorkItemDefinition(
            id: 'ceilings_tiles',
            title: 'Потолочная плитка',
            icon: Icons.apps_rounded,
            calculatorId: 'ceilings_tiles',
          ),
          WorkItemDefinition(
            id: 'ceilings_insulation',
            title: 'Утепление потолка',
            icon: Icons.ac_unit,
            calculatorId: 'ceilings_insulation',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'floors',
        title: 'Полы',
        description: 'Ламинат, линолеум, плитка, стяжка и тёплый пол',
        icon: Icons.grid_view_rounded,
        items: [
          WorkItemDefinition(
            id: 'floors_laminate',
            title: 'Ламинат',
            icon: Icons.view_day,
            calculatorId: 'floors_laminate',
            tips: [
              'Возьмите клинья для компенсационного зазора 10 мм.',
              'Подложку выбирайте толщиной 2–3 мм.',
              'Крестики не нужны, но контрольные клинья пригодятся.',
              'Проверьте ровность основания — перепад более 3 мм нежелателен.',
            ],
          ),
          WorkItemDefinition(
            id: 'floors_linoleum',
            title: 'Линолеум',
            icon: Icons.splitscreen_rounded,
            calculatorId: 'floors_linoleum',
          ),
          WorkItemDefinition(
            id: 'floors_tile',
            title: 'Плитка / керамогранит',
            icon: Icons.crop_square,
            calculatorId: 'floors_tile',
          ),
          WorkItemDefinition(
            id: 'floors_parquet',
            title: 'Паркет / массив',
            icon: Icons.view_quilt,
            calculatorId: 'floors_parquet',
          ),
          WorkItemDefinition(
            id: 'floors_carpet',
            title: 'Ковролин',
            icon: Icons.texture_outlined,
            calculatorId: 'floors_carpet',
          ),
          WorkItemDefinition(
            id: 'floors_self_leveling',
            title: 'Наливной пол',
            icon: Icons.opacity,
            calculatorId: 'floors_self_leveling',
          ),
          WorkItemDefinition(
            id: 'floors_screed',
            title: 'Стяжка',
            icon: Icons.horizontal_rule,
            calculatorId: 'floors_screed',
          ),
          WorkItemDefinition(
            id: 'floors_warm',
            title: 'Тёплый пол',
            icon: Icons.waves,
            calculatorId: 'floors_warm',
          ),
          WorkItemDefinition(
            id: 'floors_insulation',
            title: 'Утепление пола',
            icon: Icons.ac_unit,
            calculatorId: 'floors_insulation',
            tips: [
              'Утепление пола особенно важно для первого этажа.',
              'Для минваты обязательна гидроизоляция снизу.',
              'Пароизоляция укладывается сверху утеплителя.',
              'Оставляйте зазор 2-3 см для вентиляции.',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'bathroom',
        title: 'Ванная / туалет',
        icon: Icons.bathtub_outlined,
        items: [
          WorkItemDefinition(
            id: 'bathroom_tile',
            title: 'Плитка и затирка',
            icon: Icons.apps,
            calculatorId: 'bathroom_tile',
          ),
          WorkItemDefinition(
            id: 'bathroom_waterproof',
            title: 'Гидроизоляция',
            icon: Icons.water_drop,
            calculatorId: 'bathroom_waterproof',
          ),
          WorkItemDefinition(
            id: 'bathroom_sanitary',
            title: 'Сантехника',
            icon: Icons.shower,
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'balcony',
        title: 'Балкон / Лоджия',
        icon: Icons.balcony,
        items: [
          WorkItemDefinition(
            id: 'balcony',
            title: 'Балкон / Лоджия',
            icon: Icons.balcony,
            calculatorId: 'balcony',
            tips: [
              'Остекление балкона значительно увеличивает полезную площадь.',
              'Тёплое остекление позволяет использовать балкон круглый год.',
              'Утепление обязательно для тёплого остекления.',
              'Пароизоляция защищает утеплитель от влаги.',
              'Для пола на открытом балконе используйте морозостойкую плитку.',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'attic',
        title: 'Мансарда',
        icon: Icons.home_work,
        items: [
          WorkItemDefinition(
            id: 'attic',
            title: 'Мансарда',
            icon: Icons.home_work,
            calculatorId: 'attic',
            tips: [
              'Утепление мансарды обязательно для комфортного проживания.',
              'Толщина утеплителя должна быть не менее 15-20 см.',
              'Пароизоляция защищает утеплитель от влаги изнутри.',
              'Мансардные окна обеспечивают естественное освещение.',
              'Вагонка создаёт уютную атмосферу в мансарде.',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'partitions',
        title: 'Перегородки',
        icon: Icons.vertical_split_rounded,
        items: [
          WorkItemDefinition(
            id: 'partitions_gkl',
            title: 'Перегородки ГКЛ',
            icon: Icons.view_array,
            calculatorId: 'partitions_gkl',
          ),
          WorkItemDefinition(
            id: 'partitions_blocks',
            title: 'Газоблок / пеноблок',
            icon: Icons.view_module,
            calculatorId: 'partitions_blocks',
          ),
          WorkItemDefinition(
            id: 'partitions_brick',
            title: 'Кирпич',
            icon: Icons.apps_outage,
            calculatorId: 'partitions_brick',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'insulation',
        title: 'Утепление',
        icon: Icons.ac_unit_rounded,
        items: [
          WorkItemDefinition(
            id: 'insulation_mineral',
            title: 'Минвата',
            icon: Icons.grass,
            calculatorId: 'insulation_mineral',
          ),
          WorkItemDefinition(
            id: 'insulation_foam',
            title: 'Пенопласт',
            icon: Icons.blur_circular,
            calculatorId: 'insulation_foam',
          ),
          WorkItemDefinition(
            id: 'insulation_sound',
            title: 'Шумоизоляция',
            icon: Icons.hearing,
            calculatorId: 'insulation_sound',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'mixes',
        title: 'Ровнители / смеси',
        icon: Icons.construction_rounded,
        items: [
          WorkItemDefinition(
            id: 'mixes_putty',
            title: 'Шпаклёвка старт/финиш',
            icon: Icons.layers_rounded,
            calculatorId: 'mixes_putty',
          ),
          WorkItemDefinition(
            id: 'mixes_primer',
            title: 'Грунтовка',
            icon: Icons.format_paint,
            calculatorId: 'mixes_primer',
          ),
          WorkItemDefinition(
            id: 'mixes_tile_glue',
            title: 'Клей для плитки',
            icon: Icons.construction,
            calculatorId: 'mixes_tile_glue',
          ),
          WorkItemDefinition(
            id: 'mixes_self_level',
            title: 'Наливной раствор',
            icon: Icons.format_line_spacing,
          ),
          WorkItemDefinition(
            id: 'mixes_plaster',
            title: 'Штукатурка',
            icon: Icons.view_day_outlined,
            calculatorId: 'mixes_plaster',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'structures',
        title: 'Конструкции',
        icon: Icons.stairs,
        items: [
          WorkItemDefinition(
            id: 'stairs',
            title: 'Лестница',
            icon: Icons.stairs,
            calculatorId: 'stairs',
            tips: [
              'Высота ступени должна быть 15-20 см для комфортного подъёма.',
              'Ширина проступи (ступени) должна быть не менее 28 см.',
              'Ширина лестницы для жилых домов - минимум 90 см.',
              'Для деревянной лестницы используйте твёрдые породы дерева.',
              'Перила должны быть на высоте 90-100 см от ступени.',
            ],
          ),
          WorkItemDefinition(
            id: 'fence',
            title: 'Забор',
            icon: Icons.fence,
            calculatorId: 'fence',
            tips: [
              'Столбы устанавливаются на глубину 1/3 от высоты забора.',
              'Для профлиста используйте оцинкованные саморезы.',
              'Деревянный забор требует обработки антисептиком.',
              'Кирпичный забор нуждается в фундаменте.',
              'Расстояние между столбами: 2-3 метра.',
            ],
          ),
          WorkItemDefinition(
            id: 'terrace',
            title: 'Терраса / Веранда',
            icon: Icons.deck,
            calculatorId: 'terrace',
            tips: [
              'Террасная доска (декинг) устойчива к влаге и перепадам температур.',
              'Плитка для террасы должна быть морозостойкой и нескользкой.',
              'Ограждение обеспечивает безопасность.',
              'Кровля защищает от дождя и солнца.',
              'Поликарбонат пропускает свет и создаёт лёгкую конструкцию.',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'windows_doors',
        title: 'Окна / двери',
        icon: Icons.window,
        items: [
          WorkItemDefinition(
            id: 'windows_install',
            title: 'Вставка окон',
            icon: Icons.window_rounded,
            calculatorId: 'windows_install',
          ),
          WorkItemDefinition(
            id: 'windows_slopes',
            title: 'Откосы',
            icon: Icons.space_dashboard,
            calculatorId: 'slopes_finishing',
          ),
          WorkItemDefinition(
            id: 'doors_install',
            title: 'Монтаж дверей',
            icon: Icons.door_front_door,
            calculatorId: 'doors_install',
          ),
        ],
      ),
    ],
  ),
  WorkAreaDefinition(
    id: 'exterior',
    title: 'Наружная отделка',
    subtitle: 'Фасады, утепление и изоляция',
    icon: Icons.landscape_rounded,
    color: Color(0xFFA5D6A7),
    sections: [
      WorkSectionDefinition(
        id: 'foundation',
        title: 'Фундамент',
        icon: Icons.foundation,
        items: [
          WorkItemDefinition(
            id: 'foundation_strip',
            title: 'Ленточный фундамент',
            icon: Icons.account_tree,
            calculatorId: 'foundation_strip',
          ),
          WorkItemDefinition(
            id: 'foundation_slab',
            title: 'Плитный фундамент',
            icon: Icons.layers_rounded,
            calculatorId: 'foundation_slab',
          ),
          WorkItemDefinition(
            id: 'foundation_basement',
            title: 'Цокольный этаж',
            icon: Icons.warehouse_outlined,
            calculatorId: 'foundation_basement',
          ),
          WorkItemDefinition(
            id: 'foundation_blind_area',
            title: 'Отмостка',
            icon: Icons.landscape_rounded,
            calculatorId: 'foundation_blind_area',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'facade_systems',
        title: 'Фасадные решения',
        icon: Icons.other_houses,
        items: [
          WorkItemDefinition(
            id: 'facade_siding',
            title: 'Сайдинг (ПВХ/металл/фиброцемент)',
            icon: Icons.layers_outlined,
            calculatorId: 'exterior_siding',
            tips: [
              'Не забудьте J‑профиль, углы, стартовую и финишную планку.',
              'Оставляйте температурные зазоры в 5–7 мм.',
            ],
          ),
          WorkItemDefinition(
            id: 'facade_brick',
            title: 'Кирпич облицовочный',
            icon: Icons.apartment_rounded,
            calculatorId: 'exterior_brick',
          ),
          WorkItemDefinition(
            id: 'facade_panels',
            title: 'Фасадные панели',
            icon: Icons.grid_view,
            calculatorId: 'exterior_facade_panels',
          ),
          WorkItemDefinition(
            id: 'facade_stone',
            title: 'Камень (натуральный/искусственный)',
            icon: Icons.terrain_rounded,
          ),
          WorkItemDefinition(
            id: 'facade_wood',
            title: 'Дерево (вагонка, планкен, блок-хаус)',
            icon: Icons.park,
            calculatorId: 'exterior_wood',
          ),
          WorkItemDefinition(
            id: 'facade_insulation',
            title: 'Утепление фасада',
            icon: Icons.thermostat_auto,
          ),
          WorkItemDefinition(
            id: 'facade_wet',
            title: 'Мокрый фасад',
            icon: Icons.waterfall_chart_rounded,
            calculatorId: 'exterior_wet_facade',
          ),
          WorkItemDefinition(
            id: 'facade_membrane',
            title: 'Ветро-гидроизоляция',
            icon: Icons.shield,
          ),
        ],
      ),
    ],
  ),
  WorkAreaDefinition(
    id: 'roofing',
    title: 'Кровля',
    subtitle: 'Крыша и водосточные системы',
    icon: Icons.roofing_rounded,
    color: Color(0xFFFFF59D),
    sections: [
      WorkSectionDefinition(
        id: 'roof_cover',
        title: 'Кровельные материалы',
        icon: Icons.roofing,
        items: [
          WorkItemDefinition(
            id: 'roof_metal',
            title: 'Кровля',
            icon: Icons.home,
            calculatorId: 'roofing_metal',
          ),
          WorkItemDefinition(
            id: 'roof_soft',
            title: 'Мягкая кровля',
            icon: Icons.home_work_outlined,
            calculatorId: 'roofing_soft',
          ),
          WorkItemDefinition(
            id: 'roof_gutters',
            title: 'Водостоки',
            icon: Icons.water,
            calculatorId: 'roofing_gutters',
          ),
        ],
      ),
    ],
  ),
  WorkAreaDefinition(
    id: 'engineering',
    title: 'Инженерные работы',
    subtitle: 'Электрика, отопление, вентиляция',
    icon: Icons.device_hub_rounded,
    color: Color(0xFFFFAB91),
    sections: [
      WorkSectionDefinition(
        id: 'engineering_systems',
        title: 'Инженерия',
        icon: Icons.settings_input_component,
        items: [
          WorkItemDefinition(
            id: 'engineering_warm_floor',
            title: 'Тёплый пол',
            icon: Icons.waves_outlined,
          ),
          WorkItemDefinition(
            id: 'engineering_electric',
            title: 'Электрика',
            icon: Icons.flash_on,
            calculatorId: 'engineering_electrics',
          ),
          WorkItemDefinition(
            id: 'engineering_plumbing',
            title: 'Сантехника',
            icon: Icons.plumbing,
            calculatorId: 'engineering_plumbing',
          ),
          WorkItemDefinition(
            id: 'engineering_heating',
            title: 'Отопление',
            icon: Icons.fireplace,
            calculatorId: 'engineering_heating',
          ),
          WorkItemDefinition(
            id: 'engineering_ventilation',
            title: 'Вентиляция',
            icon: Icons.air,
            calculatorId: 'engineering_ventilation',
          ),
        ],
      ),
    ],
  ),
];

// Унифицированный каталог: две категории (внутренняя/наружная),
// кровля переносится в наружные, инженерка добавляется к внутренним.
final WorkAreaDefinition _interiorArea =
    _houseAreas.firstWhere((area) => area.id == 'interior');
final WorkAreaDefinition _exteriorArea =
    _houseAreas.firstWhere((area) => area.id == 'exterior');
final WorkAreaDefinition _roofingArea =
    _houseAreas.firstWhere((area) => area.id == 'roofing');
final WorkAreaDefinition _engineeringArea =
    _houseAreas.firstWhere((area) => area.id == 'engineering');

final List<WorkAreaDefinition> _mainAreas = [
  WorkAreaDefinition(
    id: _interiorArea.id,
    title: _interiorArea.title,
    subtitle: _interiorArea.subtitle,
    icon: _interiorArea.icon,
    color: _interiorArea.color,
    sections: [
      ..._interiorArea.sections,
      ..._engineeringArea.sections,
    ],
  ),
  WorkAreaDefinition(
    id: _exteriorArea.id,
    title: _exteriorArea.title,
    subtitle: _exteriorArea.subtitle,
    icon: _exteriorArea.icon,
    color: _exteriorArea.color,
    sections: [
      ..._exteriorArea.sections,
      ..._roofingArea.sections,
    ],
  ),
];

// Каталог для КВАРТИРЫ: используем унифицированный набор
final List<WorkAreaDefinition> _flatAreas = _mainAreas;

// Каталог для ГАРАЖА: используем унифицированный набор
final List<WorkAreaDefinition> _garageAreas = _mainAreas;

final Map<ObjectType, List<WorkAreaDefinition>> _catalog = {
  ObjectType.house: _mainAreas,
  ObjectType.flat: _flatAreas,
  ObjectType.garage: _garageAreas,
};

