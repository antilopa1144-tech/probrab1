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
    title: 'work.area.interior.title',
    subtitle: 'work.area.interior.subtitle',
    icon: Icons.home_repair_service_rounded,
    color: Color(0xFF80DEEA),
    sections: [
      WorkSectionDefinition(
        id: 'walls',
        title: 'work.section.interior.walls.title',
        description: 'work.section.interior.walls.description',
        icon: Icons.format_paint_rounded,
        items: [
          WorkItemDefinition(
            id: 'walls_top',
            title: 'work.item.walls_top.title',
            icon: Icons.trending_up_rounded,
            description: 'work.item.walls_top.description',
          ),
          WorkItemDefinition(
            id: 'walls_paint',
            title: 'work.item.walls_paint.title',
            icon: Icons.format_paint,
            calculatorId: 'paint_universal',
            tips: [
              'work.item.walls_paint.tip.1',
              'work.item.walls_paint.tip.2',
              'work.item.walls_paint.tip.3',
              'work.item.walls_paint.tip.4',
              'work.item.walls_paint.tip.5',
            ],
          ),
          WorkItemDefinition(
            id: 'walls_wallpaper',
            title: 'work.item.walls_wallpaper.title',
            icon: Icons.wallpaper,
            calculatorId: 'walls_wallpaper',
            tips: [
              'work.item.walls_wallpaper.tip.1',
              'work.item.walls_wallpaper.tip.2',
              'work.item.walls_wallpaper.tip.3',
              'work.item.walls_wallpaper.tip.4',
            ],
          ),
          WorkItemDefinition(
            id: 'walls_decor_plaster',
            title: 'work.item.walls_decor_plaster.title',
            icon: Icons.style,
            description: 'work.item.walls_decor_plaster.description',
            calculatorId: 'walls_decor_plaster',
            tips: [
              'work.item.walls_decor_plaster.tip.1',
              'work.item.walls_decor_plaster.tip.2',
              'work.item.walls_decor_plaster.tip.3',
            ],
          ),
          WorkItemDefinition(
            id: 'walls_decor_stone',
            title: 'work.item.walls_decor_stone.title',
            icon: Icons.terrain,
            calculatorId: 'walls_decor_stone',
          ),
          WorkItemDefinition(
            id: 'walls_flex_stone',
            title: 'work.item.walls_flex_stone.title',
            icon: Icons.texture,
          ),
          WorkItemDefinition(
            id: 'walls_pvc_panels',
            title: 'work.item.walls_pvc_panels.title',
            icon: Icons.dashboard,
            calculatorId: 'walls_pvc_panels',
          ),
          WorkItemDefinition(
            id: 'walls_mdf_panels',
            title: 'work.item.walls_mdf_panels.title',
            icon: Icons.view_stream,
            calculatorId: 'walls_mdf_panels',
          ),
          WorkItemDefinition(
            id: 'walls_gipso_panels',
            title: 'work.item.walls_gipso_panels.title',
            icon: Icons.view_week,
          ),
          WorkItemDefinition(
            id: 'walls_3d_panels',
            title: 'work.item.walls_3d_panels.title',
            icon: Icons.auto_awesome_mosaic,
            calculatorId: 'walls_3d_panels',
          ),
          WorkItemDefinition(
            id: 'walls_wood',
            title: 'work.item.walls_wood.title',
            icon: Icons.park_rounded,
            calculatorId: 'walls_wood',
          ),
          WorkItemDefinition(
            id: 'walls_gkl',
            title: 'work.item.walls_gkl.title',
            icon: Icons.layers,
          ),
          WorkItemDefinition(
            id: 'walls_gvl',
            title: 'work.item.walls_gvl.title',
            icon: Icons.layers_clear,
          ),
          WorkItemDefinition(
            id: 'walls_tile',
            title: 'work.item.walls_tile.title',
            icon: Icons.apps,
          ),
          WorkItemDefinition(
            id: 'walls_mixes',
            title: 'work.item.walls_mixes.title',
            icon: Icons.inventory_2,
            description: 'work.item.walls_mixes.description',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'ceilings',
        title: 'work.section.interior.ceilings.title',
        description: 'work.section.interior.ceilings.description',
        icon: Icons.expand_less_rounded,
        items: [
          WorkItemDefinition(
            id: 'ceilings_paint',
            title: 'work.item.ceilings_paint.title',
            icon: Icons.brush_outlined,
            calculatorId: 'paint_universal',
          ),
          WorkItemDefinition(
            id: 'ceilings_stretch',
            title: 'work.item.ceilings_stretch.title',
            icon: Icons.blur_linear,
            calculatorId: 'ceilings_stretch',
          ),
          WorkItemDefinition(
            id: 'ceilings_gkl',
            title: 'work.item.ceilings_gkl.title',
            icon: Icons.grid_on,
          ),
          WorkItemDefinition(
            id: 'ceilings_rail',
            title: 'work.item.ceilings_rail.title',
            icon: Icons.view_column,
            calculatorId: 'ceilings_rail',
          ),
          WorkItemDefinition(
            id: 'ceilings_cassette',
            title: 'work.item.ceilings_cassette.title',
            icon: Icons.grid_4x4,
            calculatorId: 'ceilings_cassette',
          ),
          WorkItemDefinition(
            id: 'ceilings_tiles',
            title: 'work.item.ceilings_tiles.title',
            icon: Icons.apps_rounded,
          ),
          WorkItemDefinition(
            id: 'ceilings_insulation',
            title: 'work.item.ceilings_insulation.title',
            icon: Icons.ac_unit,
            calculatorId: 'ceilings_insulation',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'floors',
        title: 'work.section.interior.floors.title',
        description: 'work.section.interior.floors.description',
        icon: Icons.grid_view_rounded,
        items: [
          WorkItemDefinition(
            id: 'floors_laminate',
            title: 'work.item.floors_laminate.title',
            icon: Icons.view_day,
            calculatorId: 'floors_laminate',
            tips: [
              'work.item.floors_laminate.tip.1',
              'work.item.floors_laminate.tip.2',
              'work.item.floors_laminate.tip.3',
              'work.item.floors_laminate.tip.4',
            ],
          ),
          WorkItemDefinition(
            id: 'floors_linoleum',
            title: 'work.item.floors_linoleum.title',
            icon: Icons.splitscreen_rounded,
            calculatorId: 'floors_linoleum',
          ),
          WorkItemDefinition(
            id: 'floors_tile',
            title: 'work.item.floors_tile.title',
            icon: Icons.crop_square,
            calculatorId: 'floors_tile',
          ),
          WorkItemDefinition(
            id: 'floors_parquet',
            title: 'work.item.floors_parquet.title',
            icon: Icons.view_quilt,
            calculatorId: 'floors_parquet',
          ),
          WorkItemDefinition(
            id: 'floors_carpet',
            title: 'work.item.floors_carpet.title',
            icon: Icons.texture_outlined,
          ),
          WorkItemDefinition(
            id: 'floors_self_leveling',
            title: 'work.item.floors_self_leveling.title',
            icon: Icons.opacity,
            calculatorId: 'floors_self_leveling',
          ),
          WorkItemDefinition(
            id: 'floors_screed',
            title: 'work.item.floors_screed.title',
            icon: Icons.horizontal_rule,
            calculatorId: 'floors_screed',
          ),
          WorkItemDefinition(
            id: 'floors_warm',
            title: 'work.item.floors_warm.title',
            icon: Icons.waves,
            calculatorId: 'floors_warm',
          ),
          WorkItemDefinition(
            id: 'floors_insulation',
            title: 'work.item.floors_insulation.title',
            icon: Icons.ac_unit,
            tips: [
              'work.item.floors_insulation.tip.1',
              'work.item.floors_insulation.tip.2',
              'work.item.floors_insulation.tip.3',
              'work.item.floors_insulation.tip.4',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'bathroom',
        title: 'work.section.interior.bathroom.title',
        icon: Icons.bathtub_outlined,
        items: [
          WorkItemDefinition(
            id: 'bathroom_tile',
            title: 'work.item.bathroom_tile.title',
            icon: Icons.apps,
            calculatorId: 'bathroom_tile',
          ),
          WorkItemDefinition(
            id: 'bathroom_waterproof',
            title: 'work.item.bathroom_waterproof.title',
            icon: Icons.water_drop,
            calculatorId: 'bathroom_waterproof',
          ),
          WorkItemDefinition(
            id: 'bathroom_sanitary',
            title: 'work.item.bathroom_sanitary.title',
            icon: Icons.shower,
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'balcony',
        title: 'work.section.interior.balcony.title',
        icon: Icons.balcony,
        items: [
          WorkItemDefinition(
            id: 'balcony',
            title: 'work.item.balcony.title',
            icon: Icons.balcony,
            calculatorId: 'balcony',
            tips: [
              'work.item.balcony.tip.1',
              'work.item.balcony.tip.2',
              'work.item.balcony.tip.3',
              'work.item.balcony.tip.4',
              'work.item.balcony.tip.5',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'attic',
        title: 'work.section.interior.attic.title',
        icon: Icons.home_work,
        items: [
          WorkItemDefinition(
            id: 'attic',
            title: 'work.item.attic.title',
            icon: Icons.home_work,
            calculatorId: 'attic',
            tips: [
              'work.item.attic.tip.1',
              'work.item.attic.tip.2',
              'work.item.attic.tip.3',
              'work.item.attic.tip.4',
              'work.item.attic.tip.5',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'partitions',
        title: 'work.section.interior.partitions.title',
        icon: Icons.vertical_split_rounded,
        items: [
          WorkItemDefinition(
            id: 'partitions_gkl',
            title: 'work.item.partitions_gkl.title',
            icon: Icons.view_array,
            calculatorId: 'gypsum_board',
          ),
          WorkItemDefinition(
            id: 'partitions_blocks',
            title: 'work.item.partitions_blocks.title',
            icon: Icons.view_module,
            calculatorId: 'partitions_blocks',
          ),
          WorkItemDefinition(
            id: 'partitions_brick',
            title: 'work.item.partitions_brick.title',
            icon: Icons.apps_outage,
            calculatorId: 'partitions_brick',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'insulation',
        title: 'work.section.interior.insulation.title',
        icon: Icons.ac_unit_rounded,
        items: [
          WorkItemDefinition(
            id: 'insulation_mineral',
            title: 'work.item.insulation_mineral.title',
            icon: Icons.grass,
          ),
          WorkItemDefinition(
            id: 'insulation_foam',
            title: 'work.item.insulation_foam.title',
            icon: Icons.blur_circular,
          ),
          WorkItemDefinition(
            id: 'insulation_sound',
            title: 'work.item.insulation_sound.title',
            icon: Icons.hearing,
            calculatorId: 'insulation_sound',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'mixes',
        title: 'work.section.interior.mixes.title',
        icon: Icons.construction_rounded,
        items: [
          WorkItemDefinition(
            id: 'mixes_putty',
            title: 'work.item.mixes_putty.title',
            icon: Icons.layers_rounded,
            calculatorId: 'mixes_putty',
          ),
          WorkItemDefinition(
            id: 'mixes_primer',
            title: 'work.item.mixes_primer.title',
            icon: Icons.format_paint,
            calculatorId: 'mixes_primer',
          ),
          WorkItemDefinition(
            id: 'mixes_tile_glue',
            title: 'work.item.mixes_tile_glue.title',
            icon: Icons.construction,
            calculatorId: 'mixes_tile_glue',
          ),
          WorkItemDefinition(
            id: 'mixes_self_level',
            title: 'work.item.mixes_self_level.title',
            icon: Icons.format_line_spacing,
          ),
          WorkItemDefinition(
            id: 'mixes_plaster',
            title: 'work.item.mixes_plaster.title',
            icon: Icons.view_day_outlined,
            calculatorId: 'mixes_plaster',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'structures',
        title: 'work.section.interior.structures.title',
        icon: Icons.stairs,
        items: [
          WorkItemDefinition(
            id: 'stairs',
            title: 'work.item.stairs.title',
            icon: Icons.stairs,
            calculatorId: 'stairs',
            tips: [
              'work.item.stairs.tip.1',
              'work.item.stairs.tip.2',
              'work.item.stairs.tip.3',
              'work.item.stairs.tip.4',
              'work.item.stairs.tip.5',
            ],
          ),
          WorkItemDefinition(
            id: 'fence',
            title: 'work.item.fence.title',
            icon: Icons.fence,
            calculatorId: 'fence',
            tips: [
              'work.item.fence.tip.1',
              'work.item.fence.tip.2',
              'work.item.fence.tip.3',
              'work.item.fence.tip.4',
              'work.item.fence.tip.5',
            ],
          ),
          WorkItemDefinition(
            id: 'terrace',
            title: 'work.item.terrace.title',
            icon: Icons.deck,
            calculatorId: 'terrace',
            tips: [
              'work.item.terrace.tip.1',
              'work.item.terrace.tip.2',
              'work.item.terrace.tip.3',
              'work.item.terrace.tip.4',
              'work.item.terrace.tip.5',
            ],
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'windows_doors',
        title: 'work.section.interior.windows_doors.title',
        icon: Icons.window,
        items: [
          WorkItemDefinition(
            id: 'windows_install',
            title: 'work.item.windows_install.title',
            icon: Icons.window_rounded,
            calculatorId: 'windows_install',
          ),
          WorkItemDefinition(
            id: 'windows_slopes',
            title: 'work.item.windows_slopes.title',
            icon: Icons.space_dashboard,
            calculatorId: 'slopes_finishing',
          ),
          WorkItemDefinition(
            id: 'doors_install',
            title: 'work.item.doors_install.title',
            icon: Icons.door_front_door,
            calculatorId: 'doors_install',
          ),
        ],
      ),
    ],
  ),
  WorkAreaDefinition(
    id: 'exterior',
    title: 'work.area.exterior.title',
    subtitle: 'work.area.exterior.subtitle',
    icon: Icons.landscape_rounded,
    color: Color(0xFFA5D6A7),
    sections: [
      WorkSectionDefinition(
        id: 'foundation',
        title: 'work.section.exterior.foundation.title',
        icon: Icons.foundation,
        items: [
          WorkItemDefinition(
            id: 'foundation_strip',
            title: 'work.item.foundation_strip.title',
            icon: Icons.account_tree,
            calculatorId: 'foundation_strip',
          ),
          WorkItemDefinition(
            id: 'foundation_slab',
            title: 'work.item.foundation_slab.title',
            icon: Icons.layers_rounded,
            calculatorId: 'foundation_slab',
          ),
          WorkItemDefinition(
            id: 'foundation_basement',
            title: 'work.item.foundation_basement.title',
            icon: Icons.warehouse_outlined,
            calculatorId: 'foundation_basement',
          ),
          WorkItemDefinition(
            id: 'foundation_blind_area',
            title: 'work.item.foundation_blind_area.title',
            icon: Icons.landscape_rounded,
            calculatorId: 'foundation_blind_area',
          ),
        ],
      ),
      WorkSectionDefinition(
        id: 'facade_systems',
        title: 'work.section.exterior.facade_systems.title',
        icon: Icons.other_houses,
        items: [
          WorkItemDefinition(
            id: 'facade_siding',
            title: 'work.item.facade_siding.title',
            icon: Icons.layers_outlined,
            tips: [
              'work.item.facade_siding.tip.1',
              'work.item.facade_siding.tip.2',
            ],
          ),
          WorkItemDefinition(
            id: 'facade_brick',
            title: 'work.item.facade_brick.title',
            icon: Icons.apartment_rounded,
            calculatorId: 'exterior_brick',
          ),
          WorkItemDefinition(
            id: 'facade_panels',
            title: 'work.item.facade_panels.title',
            icon: Icons.grid_view,
            calculatorId: 'exterior_facade_panels',
          ),
          WorkItemDefinition(
            id: 'facade_stone',
            title: 'work.item.facade_stone.title',
            icon: Icons.terrain_rounded,
          ),
          WorkItemDefinition(
            id: 'facade_wood',
            title: 'work.item.facade_wood.title',
            icon: Icons.park,
          ),
          WorkItemDefinition(
            id: 'facade_insulation',
            title: 'work.item.facade_insulation.title',
            icon: Icons.thermostat_auto,
          ),
          WorkItemDefinition(
            id: 'facade_wet',
            title: 'work.item.facade_wet.title',
            icon: Icons.waterfall_chart_rounded,
          ),
          WorkItemDefinition(
            id: 'facade_membrane',
            title: 'work.item.facade_membrane.title',
            icon: Icons.shield,
          ),
        ],
      ),
    ],
  ),
  WorkAreaDefinition(
    id: 'roofing',
    title: 'work.area.roofing.title',
    subtitle: 'work.area.roofing.subtitle',
    icon: Icons.roofing_rounded,
    color: Color(0xFFFFF59D),
    sections: [
      WorkSectionDefinition(
        id: 'roof_cover',
        title: 'work.section.roofing.roof_cover.title',
        icon: Icons.roofing,
        items: [
          WorkItemDefinition(
            id: 'roof_metal',
            title: 'work.item.roof_metal.title',
            icon: Icons.home,
            calculatorId: 'roofing_unified',
          ),
          WorkItemDefinition(
            id: 'roof_soft',
            title: 'work.item.roof_soft.title',
            icon: Icons.home_work_outlined,
            calculatorId: 'roofing_unified',
          ),
          WorkItemDefinition(
            id: 'roof_gutters',
            title: 'work.item.roof_gutters.title',
            icon: Icons.water,
            calculatorId: 'roofing_gutters',
          ),
        ],
      ),
    ],
  ),
  WorkAreaDefinition(
    id: 'engineering',
    title: 'work.area.engineering.title',
    subtitle: 'work.area.engineering.subtitle',
    icon: Icons.device_hub_rounded,
    color: Color(0xFFFFAB91),
    sections: [
      WorkSectionDefinition(
        id: 'engineering_systems',
        title: 'work.section.engineering.engineering_systems.title',
        icon: Icons.settings_input_component,
        items: [
          WorkItemDefinition(
            id: 'engineering_warm_floor',
            title: 'work.item.engineering_warm_floor.title',
            icon: Icons.waves_outlined,
          ),
          WorkItemDefinition(
            id: 'engineering_electric',
            title: 'work.item.engineering_electric.title',
            icon: Icons.flash_on,
            calculatorId: 'engineering_electrics',
          ),
          // engineering_plumbing удалён - калькулятор не востребован
          WorkItemDefinition(
            id: 'engineering_heating',
            title: 'work.item.engineering_heating.title',
            icon: Icons.fireplace,
            calculatorId: 'engineering_heating',
          ),
          WorkItemDefinition(
            id: 'engineering_ventilation',
            title: 'work.item.engineering_ventilation.title',
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
