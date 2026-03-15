// GENERATED FILE — DO NOT EDIT MANUALLY
// Source: configs/calculators/*-canonical.v1.json
// Generated: 2026-03-15
// Run: npx tsx scripts/sync-specs-to-dart.ts

// ignore_for_file: prefer_single_quotes, lines_longer_than_80_chars

/// Generated from aerated-concrete-canonical.v1.json
const Map<String, dynamic> aeratedConcreteSpecData = {
  'calculator_id': 'aerated-concrete',
  'formula_version': 'aerated-concrete-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'wallWidth',
      'unit': 'm',
      'default_value': 10,
      'min': 1,
      'max': 100,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 1,
      'max': 5,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 27,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 5,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'blockThickness',
      'unit': 'mm',
      'default_value': 200,
      'min': 100,
      'max': 400,
    },
    {
      'key': 'blockHeight',
      'unit': 'mm',
      'default_value': 200,
      'min': 200,
      'max': 250,
    },
    {
      'key': 'blockLength',
      'unit': 'mm',
      'default_value': 600,
      'min': 600,
      'max': 625,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'block_thickness_options': [
      100,
      150,
      200,
      250,
      300,
      375,
      400,
    ],
    'block_height_options': [
      200,
      250,
    ],
    'block_length_options': [
      600,
      625,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'glue_kg_per_m3': 28,
    'glue_bag_kg': 25,
    'block_reserve': 1.05,
    'rebar_armoring_interval': 4,
    'rebar_reserve': 1.1,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can_l': 10,
    'corner_profile_length_m': 2.5,
    'corner_profile_count': 4,
  },
  'warnings_rules': {
    'non_load_bearing_thickness_mm': 150,
    'thermal_check_thickness_mm': 300,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from attic-canonical.v1.json
const Map<String, dynamic> atticSpecData = {
  'calculator_id': 'attic',
  'formula_version': 'attic-canonical-v1',
  'input_schema': [
    {
      'key': 'roofArea',
      'unit': 'm2',
      'default_value': 60,
      'min': 10,
      'max': 300,
    },
    {
      'key': 'insulationThickness',
      'unit': 'mm',
      'default_value': 200,
      'min': 150,
      'max': 250,
    },
    {
      'key': 'insulationType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'finishType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'withVapourBarrier',
      'default_value': 1,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'insulation_types': [
      0,
      1,
      2,
    ],
    'finish_types': [
      0,
      1,
      2,
    ],
    'vapour_barrier_types': [
      0,
      1,
      2,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'plate_thickness': {
      '0': 100,
      '1': 150,
      '2': 100,
    },
    'plate_area': {
      '0': 0.6,
      '1': 0.6,
      '2': 0.72,
    },
    'wind_membrane_roll': 70,
    'vapor_roll': 70,
    'tape_roll': 25,
    'plate_reserve': 1.05,
    'membrane_reserve': 1.15,
    'tape_area_coeff': 40,
    'panel_area': 0.288,
    'panel_reserve': 1.12,
    'batten_pitch': 0.4,
    'gkl_sheet': 3,
    'gkl_reserve': 1.1,
    'profile_step': 0.6,
    'putty_kg_per_m2': 0.5,
    'putty_bag': 25,
  },
  'warnings_rules': {
    'thin_insulation_threshold_mm': 200,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from balcony-canonical.v1.json
const Map<String, dynamic> balconySpecData = {
  'calculator_id': 'balcony',
  'formula_version': 'balcony-canonical-v1',
  'input_schema': [
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 3,
      'min': 1,
      'max': 10,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 1.2,
      'min': 0.6,
      'max': 3,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.5,
      'min': 2,
      'max': 3,
    },
    {
      'key': 'finishType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'insulationType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_areas': {
      '0': 0.288,
      '1': 0.3,
      '2': 0.288,
      '3': 0.576,
    },
    'batten_pitch': 0.4,
    'insulation_plate': 0.72,
    'insulation_reserve': 1.05,
    'finish_reserve': 1.1,
    'klaymer_per_panel': 3,
    'klaymer_reserve': 1.1,
  },
  'warnings_rules': {
    'large_balcony_area_threshold_m2': 15,
    'uninsulated_warning_threshold': 0,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from basement-canonical.v1.json
const Map<String, dynamic> basementSpecData = {
  'calculator_id': 'basement',
  'formula_version': 'basement-canonical-v1',
  'input_schema': [
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 8,
      'min': 3,
      'max': 30,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 6,
      'min': 3,
      'max': 20,
    },
    {
      'key': 'depth',
      'unit': 'm',
      'default_value': 2.5,
      'min': 1.5,
      'max': 4,
    },
    {
      'key': 'wallThickness',
      'unit': 'mm',
      'default_value': 200,
      'min': 150,
      'max': 300,
    },
    {
      'key': 'floorThickness',
      'unit': 'mm',
      'default_value': 150,
      'min': 100,
      'max': 200,
    },
    {
      'key': 'waterproofType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'waterproof_types': [
      0,
      1,
      2,
    ],
    'wall_thicknesses': [
      150,
      200,
      250,
      300,
    ],
    'floor_thicknesses': [
      100,
      150,
      200,
    ],
  },
  'packaging_rules': {
    'unit': 'м³',
    'package_size': 1,
  },
  'material_rules': {
    'floor_rebar_kg_per_m2': 22,
    'wall_rebar_kg_per_m2': 18,
    'wire_ratio': 0.01,
    'formwork_sheet_m2': 2.88,
    'formwork_reserve': 1.15,
    'geotextile_roll': 50,
    'drainage_membrane_roll': 20,
    'mastic_kg_per_m2': 1.5,
    'mastic_layers': 2,
    'roll_reserve': 1.15,
    'roll_m2': 10,
    'pen_kg_per_m2': 0.4,
    'pen_reserve': 1.1,
    'vent_per_area': 10,
    'min_vents': 4,
    'gravel_layer': 0.15,
    'sand_layer': 0.1,
    'epps_plate': 0.72,
    'epps_reserve': 1.05,
  },
  'warnings_rules': {
    'deep_basement_threshold_m': 3,
    'thin_wall_threshold_mm': 200,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from bathroom-canonical.v1.json
const Map<String, dynamic> bathroomSpecData = {
  'calculator_id': 'bathroom',
  'formula_version': 'bathroom-canonical-v1',
  'input_schema': [
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 2.5,
      'min': 1,
      'max': 10,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 1.7,
      'min': 1,
      'max': 10,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.5,
      'min': 2,
      'max': 3.5,
    },
    {
      'key': 'floorTileSize',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'wallTileSize',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'hasWaterproofing',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'doorWidth',
      'unit': 'm',
      'default_value': 0.7,
      'min': 0.6,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'floor_tile_sizes': {
      '0': {
        'w': 0.3,
        'h': 0.3,
      },
      '1': {
        'w': 0.45,
        'h': 0.45,
      },
      '2': {
        'w': 0.6,
        'h': 0.6,
      },
    },
    'wall_tile_sizes': {
      '0': {
        'w': 0.2,
        'h': 0.3,
      },
      '1': {
        'w': 0.25,
        'h': 0.4,
      },
      '2': {
        'w': 0.3,
        'h': 0.6,
      },
    },
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'floor_tile_sizes': {
      '0': {
        'w': 0.3,
        'h': 0.3,
      },
      '1': {
        'w': 0.45,
        'h': 0.45,
      },
      '2': {
        'w': 0.6,
        'h': 0.6,
      },
    },
    'wall_tile_sizes': {
      '0': {
        'w': 0.2,
        'h': 0.3,
      },
      '1': {
        'w': 0.25,
        'h': 0.4,
      },
      '2': {
        'w': 0.3,
        'h': 0.6,
      },
    },
    'tile_reserve': 1.1,
    'floor_adhesive_kg_per_m2': 5,
    'wall_adhesive_kg_per_m2': 3.5,
    'adhesive_bag_kg': 25,
    'grout_kg_per_m2': 0.5,
    'grout_bag_kg': 2,
    'waterproof_mastic_kg_per_m2': 1.5,
    'waterproof_bucket_kg': 4,
    'waterproof_wall_height': 0.2,
    'primer_l_per_m2': 0.2,
    'primer_can_l': 5,
    'crosses_per_tile': 3,
    'crosses_pack': 100,
    'silicone_m_per_tube': 3,
  },
  'warnings_rules': {
    'small_floor_area_threshold_m2': 2,
    'waterproofing_mandatory_code': 'SP 29.13330',
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from blind-area-canonical.v1.json
const Map<String, dynamic> blindAreaSpecData = {
  'calculator_id': 'blind-area',
  'formula_version': 'blind-area-canonical-v1',
  'input_schema': [
    {
      'key': 'perimeter',
      'unit': 'm',
      'default_value': 40,
      'min': 10,
      'max': 200,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 1,
      'min': 0.6,
      'max': 1.5,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 100,
      'min': 70,
      'max': 150,
    },
    {
      'key': 'materialType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'withInsulation',
      'unit': 'mm',
      'default_value': 0,
      'min': 0,
      'max': 100,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'material_types': [
      0,
      1,
      2,
    ],
    'widths': [
      0.6,
      0.8,
      1,
      1.2,
      1.5,
    ],
    'thicknesses': [
      70,
      100,
      150,
    ],
  },
  'packaging_rules': {
    'unit': 'м²',
    'package_size': 1,
  },
  'material_rules': {
    'concrete_reserve': 1.05,
    'mesh_reserve': 1.1,
    'damper_reserve': 1.05,
    'gravel_layer': 0.15,
    'sand_layer': 0.1,
    'tile_reserve': 1.08,
    'tile_mix_kg_per_m2': 6,
    'border_length': 0.5,
    'membrane_reserve': 1.15,
    'geotextile_roll': 50,
    'epps_plate': 0.72,
    'epps_reserve': 1.05,
  },
  'warnings_rules': {
    'narrow_width_threshold_m': 0.8,
    'thin_concrete_threshold_mm': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from brick-canonical.v1.json
const Map<String, dynamic> brickSpecData = {
  'calculator_id': 'brick',
  'formula_version': 'brick-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'wallWidth',
      'unit': 'm',
      'default_value': 5,
      'min': 0.5,
      'max': 50,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 3,
      'min': 0.5,
      'max': 10,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 15,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'brickType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'wallThickness',
      'default_value': 1,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'workingConditions',
      'default_value': 1,
      'min': 1,
      'max': 4,
    },
    {
      'key': 'wasteMode',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'bricks_per_sqm': {
      '0': {
        '0': 51,
        '1': 102,
        '2': 153,
        '3': 204,
      },
      '1': {
        '0': 39,
        '1': 78,
        '2': 117,
        '3': 156,
      },
      '2': {
        '0': 26,
        '1': 52,
        '2': 78,
        '3': 104,
      },
    },
    'mortar_per_sqm': {
      '0': {
        '0': 0.019,
        '1': 0.023,
        '2': 0.034,
        '3': 0.045,
      },
      '1': {
        '0': 0.016,
        '1': 0.02,
        '2': 0.029,
        '3': 0.038,
      },
      '2': {
        '0': 0.013,
        '1': 0.017,
        '2': 0.024,
        '3': 0.031,
      },
    },
    'wall_thickness_mm': {
      '0': 120,
      '1': 250,
      '2': 380,
      '3': 510,
    },
    'brick_height_mm': {
      '0': 65,
      '1': 88,
      '2': 138,
    },
    'conditions_multiplier': {
      '1': 1,
      '2': 1.05,
      '3': 1.1,
      '4': 1.08,
    },
    'waste_coeffs': {
      '0': 1.05,
      '1': 1.1,
      '2': 1.03,
    },
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'mortar_loss_factor': 1.12,
    'cement_kg_per_m3': 400,
    'cement_bag_kg': 50,
    'sand_m3_per_m3_mortar': 1.2,
    'mesh_joint_mm': 10,
    'mesh_overlap_factor': 1.1,
    'plasticizer_l_per_m3': 0.5,
    'flexible_ties_per_m2': 4,
    'flexible_ties_wall_thickness_threshold': 2,
  },
  'warnings_rules': {
    'non_load_bearing_wall_thickness': 0,
    'manual_mix_grade_threshold': 5,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from brickwork-canonical.v1.json
const Map<String, dynamic> brickworkSpecData = {
  'calculator_id': 'brickwork',
  'formula_version': 'brickwork-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'wallLength',
      'unit': 'm',
      'default_value': 10,
      'min': 1,
      'max': 100,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 1,
      'max': 5,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 27,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 5,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'brickFormat',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'wallThickness',
      'default_value': 1,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'mortarJoint',
      'unit': 'mm',
      'default_value': 10,
      'min': 8,
      'max': 15,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'bricks_per_sqm': {
      '0': {
        '0': 51,
        '1': 102,
        '2': 153,
        '3': 204,
      },
      '1': {
        '0': 39,
        '1': 78,
        '2': 117,
        '3': 156,
      },
      '2': {
        '0': 26,
        '1': 52,
        '2': 78,
        '3': 104,
      },
    },
    'mortar_per_m3': {
      '0': 0.221,
      '1': 0.195,
      '2': 0.166,
    },
    'wall_thickness_mm': {
      '0': 120,
      '1': 250,
      '2': 380,
      '3': 510,
    },
    'brick_heights': {
      '0': 65,
      '1': 88,
      '2': 138,
    },
    'bricks_per_pallet': {
      '0': 480,
      '1': 352,
      '2': 176,
    },
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'bricks_per_sqm': {
      '0': {
        '0': 51,
        '1': 102,
        '2': 153,
        '3': 204,
      },
      '1': {
        '0': 39,
        '1': 78,
        '2': 117,
        '3': 156,
      },
      '2': {
        '0': 26,
        '1': 52,
        '2': 78,
        '3': 104,
      },
    },
    'mortar_per_m3': {
      '0': 0.221,
      '1': 0.195,
      '2': 0.166,
    },
    'wall_thickness_mm': {
      '0': 120,
      '1': 250,
      '2': 380,
      '3': 510,
    },
    'brick_heights': {
      '0': 65,
      '1': 88,
      '2': 138,
    },
    'bricks_per_pallet': {
      '0': 480,
      '1': 352,
      '2': 176,
    },
    'block_reserve': 1.05,
    'mortar_density': 1700,
    'mortar_bag_kg': 50,
  },
  'warnings_rules': {
    'non_load_bearing_wall_thickness': 0,
    'armor_belt_height_threshold': 3,
    'armor_belt_wall_thickness_threshold': 2,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from ceiling-cassette-canonical.v1.json
const Map<String, dynamic> ceilingCassetteSpecData = {
  'calculator_id': 'ceiling-cassette',
  'formula_version': 'ceiling-cassette-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 30,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'cassetteSize',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'roomLength',
      'unit': 'm',
      'default_value': 6,
      'min': 2,
      'max': 50,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'cassette_sizes': [
      0,
      1,
      2,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'cassette_areas': {
      '0': 0.354,
      '1': 0.36,
      '2': 0.09,
    },
    'cassette_sizes': {
      '0': 0.595,
      '1': 0.6,
      '2': 0.3,
    },
    'cassette_reserve': 1.1,
    'main_profile_spacing': 1.2,
    'cross_profile_spacing': 0.6,
    'hanger_spacing': 1.2,
    'wall_profile_length': 3,
    'wall_profile_reserve': 1.05,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 200,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from ceiling-insulation-canonical.v1.json
const Map<String, dynamic> ceilingInsulationSpecData = {
  'calculator_id': 'ceiling-insulation',
  'formula_version': 'ceiling-insulation-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 40,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 100,
      'min': 50,
      'max': 200,
    },
    {
      'key': 'insulationType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'layers',
      'default_value': 1,
      'min': 1,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'insulation_types': [
      0,
      1,
      2,
      3,
    ],
    'thicknesses': [
      50,
      100,
      150,
      200,
    ],
  },
  'packaging_rules': {
    'unit': 'упаковок',
    'package_size': 1,
  },
  'material_rules': {
    'plate_pack_m2': 6,
    'roll_areas': {
      '50': 9,
      '100': 5,
    },
    'epps_plate': 0.72,
    'ecowool_density': 35,
    'ecowool_bag': 15,
    'plate_reserve': 1.05,
    'vapor_roll': 50,
    'vapor_reserve': 1.15,
    'tape_per_area': 50,
  },
  'warnings_rules': {
    'thin_insulation_threshold_mm': 50,
    'large_area_threshold_m2': 200,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from ceiling-rail-canonical.v1.json
const Map<String, dynamic> ceilingRailSpecData = {
  'calculator_id': 'ceiling-rail',
  'formula_version': 'ceiling-rail-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 20,
      'min': 1,
      'max': 200,
    },
    {
      'key': 'railWidth',
      'unit': 'mm',
      'default_value': 100,
      'min': 100,
      'max': 200,
    },
    {
      'key': 'railLength',
      'unit': 'm',
      'default_value': 3,
      'min': 3,
      'max': 4,
    },
    {
      'key': 'roomLength',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 30,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'rail_widths': [
      100,
      150,
      200,
    ],
    'rail_lengths': [
      3,
      3.6,
      4,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'rail_reserve': 1.1,
    't_profile_spacing': 1,
    't_profile_length': 3,
    't_reserve': 1.05,
    'hanger_spacing': 1.2,
    'screws_per_hanger': 4,
    'screws_per_rail': 2,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from ceiling-stretch-canonical.v1.json
const Map<String, dynamic> ceilingStretchSpecData = {
  'calculator_id': 'ceiling-stretch',
  'formula_version': 'ceiling-stretch-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 20,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'corners',
      'default_value': 4,
      'min': 3,
      'max': 20,
    },
    {
      'key': 'fixtures',
      'default_value': 4,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'type',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'ceiling_types': [
      0,
      1,
      2,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'baguet_reserve': 1.1,
    'baguet_length': 2.5,
    'insert_reserve': 1.1,
    'masking_tape_roll': 50,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 50,
    'many_fixtures_threshold': 20,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from concrete-canonical.v1.json
const Map<String, dynamic> concreteSpecData = {
  'calculator_id': 'concrete',
  'formula_version': 'concrete-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'concreteVolume',
      'unit': 'm3',
      'default_value': 5,
      'min': 0.1,
      'max': 500,
    },
    {
      'key': 'concreteGrade',
      'default_value': 3,
      'min': 1,
      'max': 7,
    },
    {
      'key': 'manualMix',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'reserve',
      'unit': '%',
      'default_value': 10,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 0.1,
      'max': 1000,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 200,
      'min': 50,
      'max': 1000,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'proportions': [
      {
        'grade': 1,
        'label': 'М100 (В7.5)',
        'cement_kg': 170,
        'sand_m3': 0.56,
        'gravel_m3': 0.88,
        'water_l': 210,
      },
      {
        'grade': 2,
        'label': 'М150 (В12.5)',
        'cement_kg': 215,
        'sand_m3': 0.54,
        'gravel_m3': 0.86,
        'water_l': 200,
      },
      {
        'grade': 3,
        'label': 'М200 (В15)',
        'cement_kg': 290,
        'sand_m3': 0.5,
        'gravel_m3': 0.82,
        'water_l': 190,
      },
      {
        'grade': 4,
        'label': 'М250 (В20)',
        'cement_kg': 340,
        'sand_m3': 0.47,
        'gravel_m3': 0.8,
        'water_l': 185,
      },
      {
        'grade': 5,
        'label': 'М300 (В22.5)',
        'cement_kg': 380,
        'sand_m3': 0.44,
        'gravel_m3': 0.78,
        'water_l': 180,
      },
      {
        'grade': 6,
        'label': 'М350 (В25)',
        'cement_kg': 420,
        'sand_m3': 0.41,
        'gravel_m3': 0.76,
        'water_l': 175,
      },
      {
        'grade': 7,
        'label': 'М400 (В30)',
        'cement_kg': 480,
        'sand_m3': 0.38,
        'gravel_m3': 0.73,
        'water_l': 170,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'м³',
    'volume_step_m3': 0.1,
    'cement_bag_kg': 50,
    'mastic_bucket_kg': 20,
    'film_roll_m2': 30,
  },
  'material_rules': {
    'waterproof_mastic_kg_per_m2': 1,
    'waterproof_reserve_factor': 1.15,
    'film_reserve_factor': 1.1,
    'sand_reserve_factor': 1.05,
    'gravel_reserve_factor': 1.05,
    'estimated_slab_thickness_m': 0.2,
  },
  'warnings_rules': {
    'small_volume_threshold_m3': 0.5,
    'manual_mix_max_grade': 5,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from decor-plaster-canonical.v1.json
const Map<String, dynamic> decorPlasterSpecData = {
  'calculator_id': 'decor-plaster',
  'formula_version': 'decor-plaster-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 50,
      'min': 1,
      'max': 1000,
    },
    {
      'key': 'texture',
      'default_value': 0,
      'min': 0,
      'max': 4,
    },
    {
      'key': 'surface',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'bagWeight',
      'unit': 'kg',
      'default_value': 25,
      'min': 15,
      'max': 25,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'textures': [
      0,
      1,
      2,
      3,
      4,
    ],
    'surfaces': [
      0,
      1,
    ],
  },
  'packaging_rules': {
    'unit': 'мешков',
    'package_size': 1,
  },
  'material_rules': {
    'consumption_kg_per_m2': {
      '0': 2.5,
      '1': 3.5,
      '2': 3,
      '3': 4,
      '4': 1.2,
    },
    'plaster_reserve': 1.05,
    'primer_deep_l_per_m2': 0.2,
    'primer_deep_reserve': 1.15,
    'primer_can': 10,
    'tinted_primer_l_per_m2': 0.15,
    'tinted_can': 5,
    'pigment_per_25kg': 1,
    'wax_l_per_m2': 0.1,
    'wax_can': 1,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 200,
    'venetian_facade_texture_id': 4,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from decor-stone-canonical.v1.json
const Map<String, dynamic> decorStoneSpecData = {
  'calculator_id': 'decor-stone',
  'formula_version': 'decor-stone-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 15,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'wallWidth',
      'unit': 'm',
      'default_value': 4,
      'min': 0.5,
      'max': 30,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 0.5,
      'max': 10,
    },
    {
      'key': 'stoneType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'jointWidth',
      'unit': 'mm',
      'default_value': 10,
      'min': 0,
      'max': 20,
    },
    {
      'key': 'needGrout',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'needPrimer',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'м²',
    'package_size': 1,
  },
  'material_rules': {
    'stone_reserve': 1.1,
    'glue_kg_per_m2': [
      3,
      5,
      7,
    ],
    'glue_reserve': 1.1,
    'glue_bag': 25,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.1,
    'primer_can': 10,
    'grout_base_factor': 0.2,
    'grout_reserve': 1.1,
    'grout_bag': 5,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 50,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from doors-canonical.v1.json
const Map<String, dynamic> doorsSpecData = {
  'calculator_id': 'doors',
  'formula_version': 'doors-canonical-v1',
  'input_schema': [
    {
      'key': 'doorCount',
      'default_value': 3,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'doorType',
      'default_value': 0,
      'min': 0,
      'max': 4,
    },
    {
      'key': 'wallThickness',
      'unit': 'mm',
      'default_value': 120,
      'min': 80,
      'max': 380,
    },
    {
      'key': 'withNalichnik',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'door_types': [
      0,
      1,
      2,
      3,
      4,
    ],
    'wall_thicknesses': [
      80,
      100,
      120,
      200,
      250,
      380,
    ],
  },
  'packaging_rules': {
    'unit': 'баллонов',
    'package_size': 1,
  },
  'material_rules': {
    'door_dims': {
      '0': [
        700,
        2000,
      ],
      '1': [
        800,
        2000,
      ],
      '2': [
        900,
        2000,
      ],
      '3': [
        860,
        2050,
      ],
      '4': [
        700,
        2100,
      ],
    },
    'box_depth': 70,
    'foam_ml_per_m': 100,
    'foam_can_ml': 750,
    'screws_per_door': 12,
    'dubels_per_door': 6,
    'glue_cartridge_per_door': 0.5,
    'dobor_standard_h': 2200,
    'nalichnik_standard_h': 2200,
    'foam_reserve': 1.1,
    'screw_pack': 50,
    'dubel_pack': 20,
  },
  'warnings_rules': {
    'thick_wall_threshold_mm': 200,
    'bulk_door_threshold': 10,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from drywall-canonical.v1.json
const Map<String, dynamic> drywallSpecData = {
  'calculator_id': 'drywall',
  'formula_version': 'drywall-canonical-v1',
  'input_schema': [
    {
      'key': 'workType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 0.5,
      'max': 30,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 1.5,
      'max': 5,
    },
    {
      'key': 'layers',
      'default_value': 1,
      'min': 1,
      'max': 2,
    },
    {
      'key': 'sheetSize',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'profileStep',
      'unit': 'm',
      'default_value': 0.6,
      'min': 0.4,
      'max': 0.6,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'sheet_sizes': {
      '0': {
        'id': 0,
        'w': 1.2,
        'h': 2.5,
        'area': 3,
      },
      '1': {
        'id': 1,
        'w': 1.2,
        'h': 3,
        'area': 3.6,
      },
      '2': {
        'id': 2,
        'w': 0.6,
        'h': 2.5,
        'area': 1.5,
      },
    },
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'sheet_reserve': 1.1,
    'profile_reserve': 1.05,
    'screws_tf_per_m2': 30,
    'screws_lb_per_profile': 4,
    'dowels_step_m': 0.6,
    'putty_start_kg_per_m2': 0.8,
    'putty_finish_kg_per_m2': 1,
    'putty_reserve': 1.15,
    'putty_bag_kg': 25,
    'serpyanka_m_per_sheet': 2.5,
    'serpyanka_reserve': 1.1,
    'serpyanka_roll_m': 90,
    'primer_l_per_m2': 0.3,
    'primer_reserve': 1.15,
    'primer_can_l': 10,
    'sandpaper_m2_per_sheet': 5,
    'sandpaper_pack': 10,
    'profile_length_m': 3,
    'sealing_tape_roll_m': 30,
  },
  'warnings_rules': {
    'wide_profile_height_threshold': 3.5,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from drywall-ceiling-canonical.v1.json
const Map<String, dynamic> drywallCeilingSpecData = {
  'calculator_id': 'drywall-ceiling',
  'formula_version': 'drywall-ceiling-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 200,
    },
    {
      'key': 'layers',
      'default_value': 1,
      'min': 1,
      'max': 2,
    },
    {
      'key': 'profileStep',
      'unit': 'mm',
      'default_value': 600,
      'min': 400,
      'max': 600,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'sheet_area': 3,
    'sheet_reserve': 1.1,
    'profile_reserve': 1.05,
    'cross_step': 1.2,
    'suspension_step': 0.7,
    'screws_per_sheet': 23,
    'screws_per_kg': 1000,
    'screw_reserve': 1.05,
    'clop_per_susp': 2,
    'clop_per_crab': 4,
    'dowel_step': 0.5,
    'serpyanka_coeff': 1.2,
    'serpyanka_reserve': 1.1,
    'serpyanka_roll': 45,
    'putty_kg_per_m': 0.25,
    'putty_bag': 25,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can': 10,
    'profile_length': 3,
  },
  'warnings_rules': {
    'deformation_joint_area_threshold_m2': 50,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from electric-canonical.v1.json
const Map<String, dynamic> electricSpecData = {
  'calculator_id': 'electric',
  'formula_version': 'electric-canonical-v1',
  'input_schema': [
    {
      'key': 'apartmentArea',
      'unit': 'm2',
      'default_value': 60,
      'min': 20,
      'max': 500,
    },
    {
      'key': 'roomsCount',
      'default_value': 3,
      'min': 1,
      'max': 10,
    },
    {
      'key': 'ceilingHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2.4,
      'max': 4,
    },
    {
      'key': 'wiringType',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'hasKitchen',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'reserve',
      'unit': '%',
      'default_value': 15,
      'min': 5,
      'max': 30,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'installation_method',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'wiring_types': [
      {
        'id': 0,
        'key': 'hidden',
        'label': 'Скрытая проводка',
      },
      {
        'id': 1,
        'key': 'open',
        'label': 'Открытая проводка',
      },
    ],
  },
  'packaging_rules': {
    'cable_spool_m': 50,
    'unit': 'бухт',
  },
  'material_rules': {
    'cable_15_rate': 1.1,
    'cable_25_rate': 1.6,
    'cable_6_kitchen_factor': 1.5,
    'cable_6_reserve': 1.2,
    'conduit_ratio': 0.8,
    'outlets_per_m2': 0.6,
    'outlets_per_room': 2,
    'switches_base': 2,
    'cable_spool_m': 50,
    'socket_box_reserve': 1.1,
    'ac_groups_divisor': 2,
  },
  'warnings_rules': {
    'three_phase_area_threshold': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from facade-brick-canonical.v1.json
const Map<String, dynamic> facadeBrickSpecData = {
  'calculator_id': 'facade-brick',
  'formula_version': 'facade-brick-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 80,
      'min': 5,
      'max': 1000,
    },
    {
      'key': 'brickType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'jointThickness',
      'unit': 'mm',
      'default_value': 10,
      'min': 8,
      'max': 12,
    },
    {
      'key': 'withTie',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'brick_dims': {
      '0': {
        'l': 250,
        'h': 65,
      },
      '1': {
        'l': 250,
        'h': 88,
      },
      '2': {
        'l': 250,
        'h': 138,
      },
      '3': {
        'l': 250,
        'h': 65,
      },
    },
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'brick_dims': {
      '0': {
        'l': 250,
        'h': 65,
      },
      '1': {
        'l': 250,
        'h': 88,
      },
      '2': {
        'l': 250,
        'h': 138,
      },
      '3': {
        'l': 250,
        'h': 65,
      },
    },
    'brick_reserve': 1.1,
    'masonry_thickness': 0.12,
    'mortar_volume_coeff': 0.23,
    'cement_kg_per_m3_mortar': 430,
    'cement_bag_kg': 50,
    'sand_coeff': 1.4,
    'ties_per_sqm': 5,
    'ties_reserve': 1.05,
    'hydro_coeff': 0.3,
    'hydro_reserve': 1.15,
    'hydro_roll_m2': 10,
    'vent_box_step_m': 2,
    'grout_kg_per_m2': 0.35,
    'grout_bag_kg': 25,
    'hydrophob_l_per_m2': 0.2,
    'hydrophob_reserve': 1.1,
    'hydrophob_can_l': 5,
  },
  'warnings_rules': {
    'clinker_max_joint_mm': 10,
    'vent_gap_note': '20-40mm vent gap required per SP 15.13330',
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from facade-insulation-canonical.v1.json
const Map<String, dynamic> facadeInsulationSpecData = {
  'calculator_id': 'facade-insulation',
  'formula_version': 'facade-insulation-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 100,
      'min': 10,
      'max': 2000,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 100,
      'min': 50,
      'max': 200,
    },
    {
      'key': 'insulationType',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'finishType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'insulation_types': [
      0,
      1,
    ],
    'finish_types': [
      0,
      1,
      2,
    ],
    'thicknesses': [
      50,
      80,
      100,
      120,
      150,
      200,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'plate_m2': 0.72,
    'plate_reserve': 1.05,
    'glue_kg_per_m2': {
      '0': 4,
      '1': 5,
    },
    'glue_bag': 25,
    'dowels_per_m2': {
      '0': 6,
      '1': 4,
    },
    'dowel_reserve': 1.05,
    'mesh_reserve': 1.15,
    'mesh_roll': 50,
    'armor_kg_per_m2': 4,
    'armor_bag': 25,
    'primer_l_per_m2': 0.25,
    'primer_can_l': 10,
    'primer_reserve': 1.1,
    'decor_consumption': {
      '0': 3.5,
      '1': 4.5,
      '2': 2.5,
    },
    'decor_bag': 25,
    'starter_length': 2,
    'starter_reserve': 1.05,
  },
  'warnings_rules': {
    'thick_insulation_threshold_mm': 150,
    'epps_adhesion_warning': true,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from facade-panels-canonical.v1.json
const Map<String, dynamic> facadePanelsSpecData = {
  'calculator_id': 'facade-panels',
  'formula_version': 'facade-panels-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 100,
      'min': 10,
      'max': 2000,
    },
    {
      'key': 'panelType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'substructure',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'insulationThickness',
      'unit': 'mm',
      'default_value': 0,
      'min': 0,
      'max': 100,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'panel_types': [
      0,
      1,
      2,
      3,
    ],
    'substructure_types': [
      0,
      1,
      2,
    ],
    'insulation_thicknesses': [
      0,
      50,
      100,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_areas': {
      '0': 3.6,
      '1': 0.72,
      '2': 2.928,
      '3': 0.23,
    },
    'panel_reserve': 1.1,
    'bracket_spacing_m2': 0.36,
    'bracket_reserve': 1.1,
    'guide_spacing': 0.6,
    'guide_length': 3,
    'guide_reserve': 1.1,
    'fasteners_per_panel': 8,
    'fastener_reserve': 1.05,
    'anchor_per_bracket': 2,
    'anchor_reserve': 1.05,
    'insulation_plate': 0.72,
    'insulation_reserve': 1.05,
    'insulation_dowels_per_m2': 6,
    'wind_membrane_roll': 50,
    'membrane_reserve': 1.15,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can': 10,
    'sealant_per_perim': 10,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 500,
    'thick_insulation_threshold_mm': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from fasteners-canonical.v1.json
const Map<String, dynamic> fastenersSpecData = {
  'calculator_id': 'fasteners',
  'formula_version': 'fasteners-canonical-v1',
  'input_schema': [
    {
      'key': 'materialType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'sheetCount',
      'default_value': 10,
      'min': 1,
      'max': 200,
    },
    {
      'key': 'fastenerStep',
      'unit': 'mm',
      'default_value': 200,
      'min': 150,
      'max': 300,
    },
    {
      'key': 'withFrameScrews',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'withDubels',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'material_types': [
      0,
      1,
      2,
      3,
    ],
    'fastener_steps': [
      150,
      200,
      250,
      300,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'screws_per_unit': {
      '0': 24,
      '1': 28,
      '2': 8,
      '3': 20,
    },
    'base_step': {
      '0': 250,
      '1': 200,
      '2': 200,
      '3': 200,
    },
    'screw_sizes': {
      '0': '3.5×25',
      '1': '3.5×35',
      '2': '4.8×35',
      '3': 'klaimers',
    },
    'per_kg': {
      '0': 1000,
      '1': 600,
      '2': 250,
      '3': 0,
    },
    'unit_area': {
      '0': 3,
      '1': 3.125,
      '2': 1,
      '3': 1,
    },
    'screw_reserve': 1.05,
    'klaymer_multiplier': 1.5,
    'frame_screws_per_unit': 4,
    'frame_screw_reserve': 1.05,
    'dubel_step': 0.5,
    'dubel_reserve': 1.05,
    'bits_per_screws': 500,
  },
  'warnings_rules': {
    'bulk_threshold': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from fence-canonical.v1.json
const Map<String, dynamic> fenceSpecData = {
  'calculator_id': 'fence',
  'formula_version': 'fence-canonical-v1',
  'input_schema': [
    {
      'key': 'fenceLength',
      'unit': 'm',
      'default_value': 50,
      'min': 5,
      'max': 500,
    },
    {
      'key': 'fenceHeight',
      'unit': 'm',
      'default_value': 2,
      'min': 1,
      'max': 3,
    },
    {
      'key': 'fenceType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'postStep',
      'unit': 'm',
      'default_value': 2.5,
      'min': 2,
      'max': 3,
    },
    {
      'key': 'gatesCount',
      'default_value': 1,
      'min': 0,
      'max': 5,
    },
    {
      'key': 'wicketsCount',
      'default_value': 1,
      'min': 0,
      'max': 5,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'fence_types': [
      0,
      1,
      2,
    ],
    'post_steps': [
      2,
      2.5,
      3,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'post_burial_m': 0.9,
    'profnastil_useful_width': 1.15,
    'profnastil_reserve': 1.02,
    'profnastil_screws_per_sheet': 7,
    'screws_pack': 200,
    'primer_spray_m_per_can': 20,
    'post_concrete_m3': 0.03,
    'caps_reserve': 1.05,
    'rabica_roll_m': 10,
    'tension_wire_reserve': 1.05,
    'slat_width': 0.1,
    'slat_gap': 0.03,
    'slat_reserve': 1.05,
    'antiseptic_l_per_m2': 0.15,
    'antiseptic_can_l': 5,
    'gate_width': 4,
    'wicket_width': 1,
  },
  'warnings_rules': {
    'reinforced_post_gate_threshold': 0,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from foam-blocks-canonical.v1.json
const Map<String, dynamic> foamBlocksSpecData = {
  'calculator_id': 'foam-blocks',
  'formula_version': 'foam-blocks-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'wallLength',
      'unit': 'm',
      'default_value': 10,
      'min': 1,
      'max': 100,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 1,
      'max': 5,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 27,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 5,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'blockSize',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'mortarType',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'block_sizes': {
      '0': {
        'l': 600,
        'h': 300,
        't': 200,
        'label': 'Пеноблок 600×300×200',
      },
      '1': {
        'l': 600,
        'h': 300,
        't': 100,
        'label': 'Пеноблок 600×300×100',
      },
      '2': {
        'l': 390,
        'h': 190,
        't': 188,
        'label': 'Керамзитоблок 390×190×188',
      },
      '3': {
        'l': 390,
        'h': 190,
        't': 90,
        'label': 'Керамзитоблок 390×190×90',
      },
    },
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'block_reserve': 1.05,
    'glue_kg_per_m3': 25,
    'glue_bag_kg': 25,
    'cps_kg_per_m3': 1700,
    'cps_volume_per_m3': 0.25,
    'cps_bag_kg': 50,
    'mesh_interval': 3,
    'rebar_interval': 4,
    'rebar_reserve': 1.1,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can_l': 10,
  },
  'warnings_rules': {
    'non_load_bearing_thickness_mm': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from foundation-slab-canonical.v1.json
const Map<String, dynamic> foundationSlabSpecData = {
  'calculator_id': 'foundation-slab',
  'formula_version': 'foundation-slab-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 60,
      'min': 10,
      'max': 500,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 200,
      'min': 150,
      'max': 300,
    },
    {
      'key': 'rebarDiam',
      'unit': 'mm',
      'default_value': 12,
      'min': 10,
      'max': 16,
    },
    {
      'key': 'rebarStep',
      'unit': 'mm',
      'default_value': 200,
      'min': 150,
      'max': 250,
    },
    {
      'key': 'insulationThickness',
      'unit': 'mm',
      'default_value': 0,
      'min': 0,
      'max': 150,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'м³',
    'volume_step_m3': 0.1,
  },
  'material_rules': {
    'weight_per_meter': {
      '10': 0.617,
      '12': 0.888,
      '14': 1.208,
      '16': 1.578,
    },
    'wire_per_joint': 0.02,
    'epps_plate_m2': 0.72,
    'geotextile_reserve': 1.2,
    'formwork_reserve': 1.1,
    'concrete_reserve': 1.05,
    'gravel_layer': 0.15,
    'sand_layer': 0.1,
    'insulation_reserve': 1.05,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 200,
    'thin_slab_threshold_mm': 150,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from frame-house-canonical.v1.json
const Map<String, dynamic> frameHouseSpecData = {
  'calculator_id': 'frame-house',
  'formula_version': 'frame-house-canonical-v1',
  'input_schema': [
    {
      'key': 'wallLength',
      'unit': 'm',
      'default_value': 30,
      'min': 1,
      'max': 100,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 4,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 10,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'studStep',
      'unit': 'mm',
      'default_value': 600,
      'min': 400,
      'max': 600,
    },
    {
      'key': 'insulationType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'outerSheathing',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'innerSheathing',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'insulation_types': [
      0,
      1,
      2,
    ],
    'stud_steps': [
      400,
      600,
    ],
  },
  'packaging_rules': {
    'unit': 'уп',
    'package_size': 8,
  },
  'material_rules': {
    'outer_sheet_area': {
      '0': 3.125,
      '1': 3.125,
      '2': 3.84,
    },
    'inner_sheet_area': {
      '0': 3.125,
      '1': 3,
      '2': 1,
    },
    'insulation_thickness': {
      '0': 0.15,
      '1': 0.2,
      '2': 0.15,
    },
    'plate_area': 0.72,
    'pack_size': 8,
    'vapor_roll': 75,
    'wind_roll': 75,
    'membrane_reserve': 1.15,
    'outer_reserve': 1.08,
    'inner_reserve': 1.1,
    'screws_per_sheet': 28,
    'nails_per_stud': 20,
    'screw_per_kg': 600,
    'nail_per_kg': 200,
    'stud_reserve': 1.05,
    'strapping_reserve': 1.05,
    'plate_reserve': 1.05,
  },
  'warnings_rules': {
    'large_wall_area_threshold_m2': 200,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from gutters-canonical.v1.json
const Map<String, dynamic> guttersSpecData = {
  'calculator_id': 'gutters',
  'formula_version': 'gutters-canonical-v1',
  'input_schema': [
    {
      'key': 'roofPerimeter',
      'unit': 'm',
      'default_value': 40,
      'min': 5,
      'max': 200,
    },
    {
      'key': 'roofHeight',
      'unit': 'm',
      'default_value': 5,
      'min': 2,
      'max': 15,
    },
    {
      'key': 'funnels',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'gutterDia',
      'unit': 'mm',
      'default_value': 90,
      'min': 75,
      'max': 125,
    },
    {
      'key': 'gutterLength',
      'unit': 'm',
      'default_value': 3,
      'min': 3,
      'max': 4,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'gutter_diameters': [
      75,
      90,
      110,
      125,
    ],
    'gutter_lengths': [
      3,
      4,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'gutter_reserve': 1.05,
    'hook_step_m': 0.6,
    'hook_reserve': 1.05,
    'pipe_clamp_step_m': 1.5,
    'pipe_clamp_reserve': 1.05,
    'building_corners': 8,
    'connector_reserve': 1.05,
    'sealant_connections_per_tube': 20,
    'sealant_tube_ml': 310,
    'recommended_funnel_interval_m': 11,
  },
  'warnings_rules': {
    'recommended_funnel_interval_m': 11,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from gypsum-board-canonical.v1.json
const Map<String, dynamic> gypsumBoardSpecData = {
  'calculator_id': 'gypsum-board',
  'formula_version': 'gypsum-board-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 40,
      'min': 1,
      'max': 1000,
    },
    {
      'key': 'constructionType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'layers',
      'default_value': 1,
      'min': 1,
      'max': 2,
    },
    {
      'key': 'gklType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'profileStep',
      'unit': 'mm',
      'default_value': 600,
      'min': 400,
      'max': 600,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'construction_types': [
      0,
      1,
      2,
    ],
    'gkl_types': [
      0,
      1,
      2,
    ],
    'profile_steps': [
      400,
      600,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'sheet_area': 3,
    'sheet_reserve': 1.1,
    'pp_step_default': 600,
    'screws_gkl_per_sheet': 24,
    'dubel_step': 0.5,
    'dubel_reserve': 1.1,
    'serpyanka_reserve': 1.1,
    'putty_per_serpyanka': 0.025,
    'putty_bag': 25,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can': 10,
    'profile_length': 3,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 200,
    'double_layer_note': true,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from heating-canonical.v1.json
const Map<String, dynamic> heatingSpecData = {
  'calculator_id': 'heating',
  'formula_version': 'heating-canonical-v1',
  'input_schema': [
    {
      'key': 'totalArea',
      'unit': 'm2',
      'default_value': 80,
      'min': 10,
      'max': 500,
    },
    {
      'key': 'ceilingHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2.5,
      'max': 3.5,
    },
    {
      'key': 'climateZone',
      'default_value': 1,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'buildingType',
      'default_value': 1,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'radiatorType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'roomCount',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'climate_zones': [
      {
        'id': 0,
        'key': 'south',
        'label': 'Юг (до -15°C)',
        'power_per_m2': 80,
      },
      {
        'id': 1,
        'key': 'central',
        'label': 'Центр (до -25°C)',
        'power_per_m2': 100,
      },
      {
        'id': 2,
        'key': 'urals',
        'label': 'Урал/Сибирь (до -35°C)',
        'power_per_m2': 130,
      },
      {
        'id': 3,
        'key': 'far_north',
        'label': 'Крайний Север (до -45°C)',
        'power_per_m2': 150,
      },
    ],
    'building_types': [
      {
        'id': 0,
        'key': 'corner_apt',
        'label': 'Угловая квартира',
        'coefficient': 1.3,
      },
      {
        'id': 1,
        'key': 'mid_floor_apt',
        'label': 'Квартира средний этаж',
        'coefficient': 1,
      },
      {
        'id': 2,
        'key': 'good_insulated',
        'label': 'Хорошее утепление',
        'coefficient': 1.1,
      },
      {
        'id': 3,
        'key': 'weak_insulated',
        'label': 'Слабое утепление',
        'coefficient': 1.4,
      },
    ],
    'radiator_types': [
      {
        'id': 0,
        'key': 'bimetallic',
        'label': 'Биметаллический 180 Вт',
        'watt_per_unit': 180,
      },
      {
        'id': 1,
        'key': 'aluminum',
        'label': 'Алюминиевый 200 Вт',
        'watt_per_unit': 200,
      },
      {
        'id': 2,
        'key': 'cast_iron_7s',
        'label': 'Чугунный 7-секц. 700 Вт',
        'watt_per_unit': 700,
      },
      {
        'id': 3,
        'key': 'panel',
        'label': 'Панельный 700 Вт',
        'watt_per_unit': 700,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'power_per_m2_base': [
      80,
      100,
      130,
      150,
    ],
    'building_coeff': [
      1.3,
      1,
      1.1,
      1.4,
    ],
    'radiator_power': [
      180,
      200,
      700,
      700,
    ],
    'pp_pipe_stick_m': 4,
    'pipe_rate': 10,
    'pipe_reserve': 1.15,
    'fittings_per_room': 6,
    'fittings_reserve': 1.1,
    'brackets_per_room': 3,
    'brackets_reserve': 1.05,
  },
  'warnings_rules': {
    'gas_boiler_power_threshold_kw': 20,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from insulation-canonical.v1.json
const Map<String, dynamic> insulationSpecData = {
  'calculator_id': 'insulation',
  'formula_version': 'insulation-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 40,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'insulationType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 100,
      'min': 50,
      'max': 200,
    },
    {
      'key': 'plateSize',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'reserve',
      'unit': '%',
      'default_value': 5,
      'min': 0,
      'max': 15,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'insulation_types': [
      {
        'id': 0,
        'key': 'mineral_wool',
        'label': 'Минеральная вата',
        'dowels_per_sqm': 7,
      },
      {
        'id': 1,
        'key': 'epps',
        'label': 'ЭППС / пеноплекс',
        'dowels_per_sqm': 5,
      },
      {
        'id': 2,
        'key': 'eps',
        'label': 'ЕПС / пенопласт',
        'dowels_per_sqm': 6,
      },
      {
        'id': 3,
        'key': 'ecowool',
        'label': 'Эковата',
        'dowels_per_sqm': 0,
      },
    ],
    'plate_sizes': [
      {
        'id': 0,
        'key': '1200x600',
        'label': '1200×600',
        'area_m2': 0.72,
      },
      {
        'id': 1,
        'key': '1000x500',
        'label': '1000×500',
        'area_m2': 0.5,
      },
      {
        'id': 2,
        'key': '2000x1000',
        'label': '2000×1000',
        'area_m2': 2,
      },
    ],
  },
  'packaging_rules': {
    'plate_unit': 'шт',
    'ecowool_unit': 'мешков',
  },
  'material_rules': {
    'plate_reserve': 1.05,
    'dowel_reserve': 1.05,
    'membrane_reserve': 1.15,
    'alu_tape_m2_per_m2': 2,
    'alu_tape_roll_m': 50,
    'glue_kg_per_m2': 2.5,
    'glue_bag_kg': 25,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can_l': 10,
    'ecowool_density': 35,
    'ecowool_waste': 1.1,
    'ecowool_bag_kg': 15,
  },
  'warnings_rules': {
    'thin_thickness_threshold_mm': 50,
    'ecowool_settle_threshold_mm': 150,
    'professional_area_threshold_m2': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from laminate-canonical.v1.json
const Map<String, dynamic> laminateSpecData = {
  'calculator_id': 'laminate',
  'formula_version': 'laminate-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'perimeter',
      'unit': 'm',
      'default_value': 0,
      'min': 0,
      'max': 200,
    },
    {
      'key': 'packArea',
      'unit': 'm2',
      'default_value': 2.397,
      'min': 0.5,
      'max': 5,
    },
    {
      'key': 'layoutProfileId',
      'default_value': 7,
      'min': 1,
      'max': 8,
    },
    {
      'key': 'reservePercent',
      'default_value': 10,
      'min': 0,
      'max': 25,
    },
    {
      'key': 'hasUnderlayment',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'underlaymentRollArea',
      'unit': 'm2',
      'default_value': 10,
      'min': 5,
      'max': 20,
    },
    {
      'key': 'doorThresholds',
      'default_value': 1,
      'min': 0,
      'max': 10,
    },
    {
      'key': 'underlayType',
      'default_value': 3,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'laminateClass',
      'default_value': 32,
      'min': 31,
      'max': 34,
    },
    {
      'key': 'laminateThickness',
      'default_value': 8,
      'min': 6,
      'max': 14,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'installation_method',
      'worker_skill',
    ],
  },
  'normative_formula': {
    'layout_profiles': [
      {
        'id': 1,
        'key': 'straight_random',
        'label': 'Прямая, хаотичное смещение',
        'waste_percent': 5,
      },
      {
        'id': 2,
        'key': 'straight_one_third',
        'label': 'Прямая, смещение 1/3',
        'waste_percent': 8,
      },
      {
        'id': 3,
        'key': 'straight_half',
        'label': 'Прямая, смещение 1/2',
        'waste_percent': 12,
      },
      {
        'id': 4,
        'key': 'diagonal',
        'label': 'Диагональная',
        'waste_percent': 15,
      },
      {
        'id': 5,
        'key': 'herringbone',
        'label': 'Ёлочка',
        'waste_percent': 20,
      },
      {
        'id': 6,
        'key': 'quarter_shift',
        'label': 'Смещение 1/4',
        'waste_percent': 7,
      },
      {
        'id': 7,
        'key': 'chaotic',
        'label': 'Хаотичная',
        'waste_percent': 10,
      },
      {
        'id': 8,
        'key': 'deck',
        'label': 'Палубная',
        'waste_percent': 12,
      },
    ],
  },
  'packaging_rules': {
    'laminate_pack_area_unit': 'м²',
    'plinth_piece_length_m': 2.5,
    'underlayment_roll_area_m2': 10,
  },
  'material_rules': {
    'small_room_threshold_m2': 15,
    'small_room_waste_per_m2_percent': 0.5,
    'reserve_percent_default': 10,
    'underlayment_overlap_percent': 5,
    'vapor_barrier_overlap_percent': 10,
    'wedge_spacing_m': 0.5,
    'default_door_opening_width_m': 0.9,
    'rectangle_inner_corners': 4,
  },
  'warnings_rules': {
    'small_area_warning_threshold_m2': 5,
    'diagonal_warning_profile_ids': [
      4,
    ],
    'herringbone_warning_profile_ids': [
      5,
    ],
    'half_shift_warning_profile_ids': [
      3,
      8,
    ],
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from linoleum-canonical.v1.json
const Map<String, dynamic> linoleumSpecData = {
  'calculator_id': 'linoleum',
  'formula_version': 'linoleum-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'roomWidth',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'perimeter',
      'unit': 'm',
      'default_value': 0,
      'min': 0,
      'max': 200,
    },
    {
      'key': 'rollWidth',
      'unit': 'm',
      'default_value': 3,
      'min': 1.5,
      'max': 5,
    },
    {
      'key': 'hasPattern',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'patternRepeatCm',
      'unit': 'cm',
      'default_value': 30,
      'min': 0,
      'max': 100,
    },
    {
      'key': 'needGlue',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'needPlinth',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'needTape',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'installation_method',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'linear_meter_unit': 'м.п.',
    'linear_meter_step_m': 0.1,
    'plinth_piece_length_m': 2.5,
    'primer_can_liters': 10,
    'glue_bucket_kg': 10,
    'cold_welding_tube_linear_m': 20,
  },
  'material_rules': {
    'trim_allowance_m': 0.1,
    'room_margin_m': 0.2,
    'glue_kg_per_m2': 0.4,
    'primer_liters_per_m2': 0.15,
    'plinth_reserve_percent': 5,
    'default_door_opening_width_m': 0.9,
    'tape_extra_perimeter_run': 1,
  },
  'warnings_rules': {
    'high_waste_percent_threshold': 25,
    'max_single_roll_width_m': 5,
    'low_roll_width_warning_threshold_m': 3,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from mdf-panels-canonical.v1.json
const Map<String, dynamic> mdfPanelsSpecData = {
  'calculator_id': 'mdf-panels',
  'formula_version': 'mdf-panels-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'wallWidth',
      'unit': 'm',
      'default_value': 4,
      'min': 0.5,
      'max': 30,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 0.5,
      'max': 10,
    },
    {
      'key': 'panelWidth',
      'unit': 'm',
      'default_value': 0.25,
      'min': 0.1,
      'max': 0.4,
    },
    {
      'key': 'panelType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'needProfile',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'needPlinth',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_reserve': 1.1,
    'profile_reserve': 1.1,
    'profile_step': 0.5,
    'standard_panel_length': 2.7,
    'clips_per_panel': 5,
    'plinth_length': 2.7,
    'plinth_extra': 2,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from paint-canonical.v1.json
const Map<String, dynamic> paintSpecData = {
  'calculator_id': 'paint',
  'formula_version': 'paint-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 40,
      'min': 0,
      'max': 1000,
    },
    {
      'key': 'wallArea',
      'unit': 'm2',
      'default_value': 40,
      'min': 0,
      'max': 1000,
    },
    {
      'key': 'ceilingArea',
      'unit': 'm2',
      'default_value': 20,
      'min': 0,
      'max': 1000,
    },
    {
      'key': 'doorsWindows',
      'unit': 'm2',
      'default_value': 0,
      'min': 0,
      'max': 200,
    },
    {
      'key': 'roomWidth',
      'unit': 'm',
      'default_value': 4,
      'min': 0.5,
      'max': 20,
    },
    {
      'key': 'roomLength',
      'unit': 'm',
      'default_value': 5,
      'min': 0.5,
      'max': 20,
    },
    {
      'key': 'roomHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 0,
      'min': 0,
      'max': 200,
    },
    {
      'key': 'paintType',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'surfaceType',
      'default_value': 0,
      'min': 0,
      'max': 8,
    },
    {
      'key': 'surfacePrep',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'colorIntensity',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'coats',
      'default_value': 2,
      'min': 1,
      'max': 5,
    },
    {
      'key': 'coverage',
      'unit': 'm2/l',
      'default_value': 10,
      'min': 4,
      'max': 15,
    },
    {
      'key': 'canSize',
      'unit': 'l',
      'default_value': 0,
      'min': 0,
      'max': 15,
    },
  ],
  'field_factors': {
    'enabled': [
      'surface_quality',
      'geometry_complexity',
      'installation_method',
      'worker_skill',
      'waste_factor',
      'logistics_buffer',
      'packaging_rounding',
    ],
  },
  'normative_formula': {
    'paint_types': [
      {
        'id': 0,
        'key': 'interior',
        'label': 'Интерьерная краска',
      },
      {
        'id': 1,
        'key': 'facade',
        'label': 'Фасадная краска',
      },
    ],
    'surface_types': [
      {
        'id': 0,
        'key': 'smooth_puttied',
        'label': 'Гладкая шпатлёванная',
        'multiplier': 1,
        'scope_ids': [
          0,
        ],
      },
      {
        'id': 1,
        'key': 'plaster_concrete',
        'label': 'Бетон, штукатурка',
        'multiplier': 1.15,
        'scope_ids': [
          0,
        ],
      },
      {
        'id': 2,
        'key': 'porous_block',
        'label': 'Пористая (газоблок, кирпич)',
        'multiplier': 1.3,
        'scope_ids': [
          0,
        ],
      },
      {
        'id': 3,
        'key': 'wood',
        'label': 'Дерево',
        'multiplier': 1.1,
        'scope_ids': [
          0,
        ],
      },
      {
        'id': 4,
        'key': 'wallpaper',
        'label': 'Обои под покраску',
        'multiplier': 1.2,
        'scope_ids': [
          0,
        ],
      },
      {
        'id': 5,
        'key': 'relief_texture',
        'label': 'Рельефная фактура',
        'multiplier': 1.4,
        'scope_ids': [
          0,
        ],
      },
      {
        'id': 6,
        'key': 'facade_concrete',
        'label': 'Фасад: бетон',
        'multiplier': 1,
        'scope_ids': [
          1,
        ],
      },
      {
        'id': 7,
        'key': 'facade_brick',
        'label': 'Фасад: кирпич',
        'multiplier': 1.15,
        'scope_ids': [
          1,
        ],
      },
      {
        'id': 8,
        'key': 'facade_bark_beetle',
        'label': 'Фасад: короед',
        'multiplier': 1.4,
        'scope_ids': [
          1,
        ],
      },
    ],
    'surface_preparations': [
      {
        'id': 0,
        'key': 'primed',
        'label': 'Загрунтованная',
        'multiplier': 1,
      },
      {
        'id': 1,
        'key': 'raw',
        'label': 'Новая необработанная',
        'multiplier': 1.2,
      },
      {
        'id': 2,
        'key': 'repainted',
        'label': 'Ранее окрашенная',
        'multiplier': 0.95,
      },
    ],
    'color_intensities': [
      {
        'id': 0,
        'key': 'light',
        'label': 'Светлый',
        'multiplier': 1,
      },
      {
        'id': 1,
        'key': 'bright',
        'label': 'Яркий',
        'multiplier': 1.15,
      },
      {
        'id': 2,
        'key': 'dark',
        'label': 'Тёмный',
        'multiplier': 1.3,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'л',
    'default_package_size': 5,
    'allowed_package_sizes': [
      3,
      5,
      9,
      10,
      15,
    ],
    'optimal_package_sizes': [
      3,
      5,
      10,
      15,
    ],
  },
  'material_rules': {
    'primer_l_per_m2': 0.11,
    'legacy_universal_primer_l_per_m2': 0.15,
    'primer_package_size_l': 10,
    'roller_area_m2_per_piece': 50,
    'legacy_brush_area_m2_per_piece': 40,
    'legacy_brushes_min': 2,
    'legacy_brushes_max': 10,
    'brushes_count': 1,
    'trays_count': 1,
    'tape_roll_length_m': 50,
    'tape_runs_per_room': 2,
    'tape_reserve_factor': 1.1,
    'ceiling_premium_factor': 1.15,
    'default_roller_absorption_l': 0.3,
    'legacy_first_coat_multiplier': 1.2,
  },
  'warnings_rules': {
    'primer_required_surface_ids': [
      2,
      4,
      5,
      7,
      8,
    ],
    'one_coat_warning_threshold': 1,
    'rough_surface_warning_ids': [
      5,
      8,
    ],
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from panels-3d-canonical.v1.json
const Map<String, dynamic> panels3dSpecData = {
  'calculator_id': 'panels-3d',
  'formula_version': 'panels-3d-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 10,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 12,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 4,
    },
    {
      'key': 'panelSize',
      'unit': 'cm',
      'default_value': 50,
      'min': 25,
      'max': 100,
    },
    {
      'key': 'paintable',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'withVarnish',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_reserve': 1.1,
    'glue_kg_per_m2': 5,
    'primer_l_per_m2': 0.18,
    'putty_kg_per_m2': 1,
    'paint_l_per_m2': 0.24,
    'varnish_l_per_m2': 0.08,
    'glue_bag': 5,
    'primer_can': 5,
    'putty_bag': 5,
    'paint_can': 3,
    'varnish_can': 1,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from parquet-canonical.v1.json
const Map<String, dynamic> parquetSpecData = {
  'calculator_id': 'parquet',
  'formula_version': 'parquet-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'perimeter',
      'unit': 'm',
      'default_value': 0,
      'min': 0,
      'max': 200,
    },
    {
      'key': 'packArea',
      'unit': 'm2',
      'default_value': 1.892,
      'min': 0.5,
      'max': 4,
    },
    {
      'key': 'layoutProfileId',
      'default_value': 1,
      'min': 1,
      'max': 3,
    },
    {
      'key': 'reservePercent',
      'default_value': 0,
      'min': 0,
      'max': 20,
    },
    {
      'key': 'needUnderlayment',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'needPlinth',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'needGlue',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'underlaymentRollArea',
      'unit': 'm2',
      'default_value': 10,
      'min': 5,
      'max': 20,
    },
    {
      'key': 'doorThresholds',
      'default_value': 1,
      'min': 0,
      'max': 10,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'installation_method',
      'worker_skill',
    ],
  },
  'normative_formula': {
    'layout_profiles': [
      {
        'id': 1,
        'key': 'straight',
        'label': 'Прямая',
        'waste_percent': 5,
      },
      {
        'id': 2,
        'key': 'diagonal',
        'label': 'Диагональная',
        'waste_percent': 15,
      },
      {
        'id': 3,
        'key': 'herringbone',
        'label': 'Ёлочка',
        'waste_percent': 20,
      },
    ],
  },
  'packaging_rules': {
    'parquet_pack_area_unit': 'м²',
    'underlayment_roll_area_m2': 10,
    'plinth_piece_length_m': 2.5,
    'glue_bucket_kg': 10,
  },
  'material_rules': {
    'reserve_percent_default': 0,
    'underlayment_overlap_percent': 10,
    'wedge_spacing_m': 0.5,
    'default_door_opening_width_m': 0.9,
    'glue_kg_per_m2': 1.5,
    'plinth_reserve_percent': 5,
  },
  'warnings_rules': {
    'small_area_warning_threshold_m2': 5,
    'diagonal_warning_profile_ids': [
      2,
    ],
    'herringbone_warning_profile_ids': [
      3,
    ],
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from partitions-canonical.v1.json
const Map<String, dynamic> partitionsSpecData = {
  'calculator_id': 'partitions',
  'formula_version': 'partitions-canonical-v1',
  'input_schema': [
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 4,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 100,
      'min': 75,
      'max': 200,
    },
    {
      'key': 'blockType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'block_types': [
      0,
      1,
      2,
    ],
    'thicknesses': [
      75,
      100,
      150,
      200,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'block_dims': {
      '0': [
        625,
        250,
      ],
      '1': [
        625,
        250,
      ],
      '2': [
        667,
        500,
      ],
    },
    'glue_rate': {
      '0': 1.5,
      '1': 1.5,
      '2': 0,
    },
    'gypsum_milk_rate': 0.8,
    'gypsum_bag': 20,
    'glue_bag': 25,
    'block_reserve': 1.05,
    'mesh_interval': 0.75,
    'mesh_reserve': 1.05,
    'mesh_roll': 50,
    'foam_per_perim': 5,
    'foam_can': 750,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can': 10,
    'seal_tape_reserve': 1.1,
  },
  'warnings_rules': {
    'high_wall_threshold_m': 3.5,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from plaster-canonical.v1.json
const Map<String, dynamic> plasterSpecData = {
  'calculator_id': 'plaster',
  'formula_version': 'plaster-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 50,
      'min': 0.1,
      'max': 100000,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 5,
      'min': 0,
      'max': 500,
    },
    {
      'key': 'plasterType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 15,
      'min': 5,
      'max': 100,
    },
    {
      'key': 'bagWeight',
      'unit': 'kg',
      'default_value': 30,
      'min': 25,
      'max': 40,
    },
    {
      'key': 'substrateType',
      'default_value': 1,
      'min': 1,
      'max': 5,
    },
    {
      'key': 'wallEvenness',
      'default_value': 1,
      'min': 1,
      'max': 3,
    },
  ],
  'field_factors': {
    'enabled': [
      'surface_quality',
      'geometry_complexity',
      'installation_method',
      'worker_skill',
      'waste_factor',
      'logistics_buffer',
      'packaging_rounding',
    ],
  },
  'normative_formula': {
    'plaster_types': [
      {
        'id': 0,
        'key': 'gypsum',
        'label': 'Гипсовая штукатурка',
        'base_kg_per_m2_10mm': 8.5,
        'default_bag_weight': 30,
        'allowed_bag_weights': [
          25,
          30,
          40,
        ],
      },
      {
        'id': 1,
        'key': 'cement',
        'label': 'Цементная штукатурка',
        'base_kg_per_m2_10mm': 17,
        'default_bag_weight': 25,
        'allowed_bag_weights': [
          25,
          30,
          40,
        ],
      },
      {
        'id': 2,
        'key': 'cement_lime',
        'label': 'Цементно-известковая штукатурка',
        'base_kg_per_m2_10mm': 13,
        'default_bag_weight': 25,
        'allowed_bag_weights': [
          25,
          30,
          40,
        ],
      },
    ],
    'substrate_types': [
      {
        'id': 1,
        'key': 'concrete',
        'label': 'Бетон',
        'multiplier': 1,
        'primer_type': 2,
      },
      {
        'id': 2,
        'key': 'new_brick',
        'label': 'Новый кирпич',
        'multiplier': 1.15,
        'primer_type': 1,
      },
      {
        'id': 3,
        'key': 'old_brick',
        'label': 'Старый кирпич',
        'multiplier': 1.3,
        'primer_type': 1,
      },
      {
        'id': 4,
        'key': 'gas_block',
        'label': 'Газоблок',
        'multiplier': 1.25,
        'primer_type': 1,
      },
      {
        'id': 5,
        'key': 'foam_concrete',
        'label': 'Пенобетон',
        'multiplier': 1.2,
        'primer_type': 1,
      },
    ],
    'wall_evenness_profiles': [
      {
        'id': 1,
        'key': 'even',
        'label': 'Ровные стены',
        'multiplier': 1,
      },
      {
        'id': 2,
        'key': 'uneven',
        'label': 'Неровные стены',
        'multiplier': 1.15,
      },
      {
        'id': 3,
        'key': 'very_uneven',
        'label': 'Очень неровные стены',
        'multiplier': 1.3,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'кг',
  },
  'material_rules': {
    'reserve_factor': 1.1,
    'deep_primer_l_per_m2': 0.1,
    'contact_primer_kg_per_m2': 0.3,
    'primer_package_size': 5,
    'beacons_area_m2_per_piece': 2.5,
    'beacon_thin_size_mm': 6,
    'beacon_standard_size_mm': 10,
    'thin_beacon_threshold_mm': 15,
    'mesh_overlap_factor': 1.1,
    'rule_size_m': 1.5,
    'rule_count': 1,
    'spatulas_count': 1,
    'buckets_count': 2,
    'mixer_count': 1,
    'gloves_pairs': 3,
    'corner_profile_length_m': 3,
    'corner_profile_count': 4,
  },
  'warnings_rules': {
    'gypsum_two_layer_threshold_mm': 20,
    'mesh_threshold_mm': 30,
    'small_area_threshold_m2': 5,
    'thick_layer_warning_threshold_mm': 40,
    'obryzg_tip_substrate_ids': [
      3,
    ],
    'obryzg_tip_evenness_ids': [
      3,
    ],
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from primer-canonical.v1.json
const Map<String, dynamic> primerSpecData = {
  'calculator_id': 'primer',
  'formula_version': 'primer-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 50,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'roomWidth',
      'unit': 'm',
      'default_value': 4,
      'min': 0.5,
      'max': 20,
    },
    {
      'key': 'roomLength',
      'unit': 'm',
      'default_value': 5,
      'min': 0.5,
      'max': 20,
    },
    {
      'key': 'roomHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'surfaceType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'primerType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'coats',
      'default_value': 1,
      'min': 1,
      'max': 3,
    },
    {
      'key': 'canSize',
      'unit': 'l',
      'default_value': 5,
      'min': 5,
      'max': 20,
    },
  ],
  'field_factors': {
    'enabled': [
      'surface_quality',
      'geometry_complexity',
      'installation_method',
      'worker_skill',
      'waste_factor',
      'logistics_buffer',
      'packaging_rounding',
    ],
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
  'normative_formula': {
    'surface_types': [
      {
        'id': 0,
        'key': 'absorbent_mineral',
        'label': 'Бетон, пеноблок (впитывающая)',
        'multiplier': 1.5,
      },
      {
        'id': 1,
        'key': 'plasterboard_and_plaster',
        'label': 'Гипсокартон, штукатурка',
        'multiplier': 1,
      },
      {
        'id': 2,
        'key': 'non_porous',
        'label': 'Кафель, стекло (непористая)',
        'multiplier': 1.2,
      },
      {
        'id': 3,
        'key': 'wood_osb',
        'label': 'Дерево, OSB',
        'multiplier': 1.3,
      },
    ],
    'primer_types': [
      {
        'id': 0,
        'key': 'deep_penetration',
        'label': 'Грунтовка глубокого проникновения',
        'base_l_per_m2': 0.1,
      },
      {
        'id': 1,
        'key': 'contact',
        'label': 'Бетон-контакт',
        'base_l_per_m2': 0.35,
      },
      {
        'id': 2,
        'key': 'for_gkl',
        'label': 'Грунтовка для ГКЛ',
        'base_l_per_m2': 0.12,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'л',
    'default_package_size': 5,
    'allowed_package_sizes': [
      5,
      10,
      15,
      20,
    ],
  },
  'material_rules': {
    'roller_area_m2_per_piece': 30,
    'brushes_count': 2,
    'trays_count': 1,
    'drying_time_hours_by_type': {
      '0': 4,
      '1': 3,
      '2': 2,
    },
  },
  'warnings_rules': {
    'absorbent_surface_ids': [
      0,
    ],
    'recommended_double_coat_surface_ids': [
      0,
    ],
  },
};

/// Generated from putty-canonical.v1.json
const Map<String, dynamic> puttySpecData = {
  'calculator_id': 'putty',
  'formula_version': 'putty-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 50,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'surface',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'puttyType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'bagWeight',
      'unit': 'kg',
      'default_value': 20,
      'min': 5,
      'max': 25,
    },
    {
      'key': 'qualityClass',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'layers',
      'default_value': 0,
      'min': 0,
      'max': 5,
    },
    {
      'key': 'startLayers',
      'default_value': 0,
      'min': 0,
      'max': 5,
    },
    {
      'key': 'finishLayers',
      'default_value': 0,
      'min': 0,
      'max': 5,
    },
  ],
  'normative_formula': {
    'components': [
      {
        'key': 'finish',
        'label': 'Финишная',
        'category': 'Финишная',
        'enabled_for_putty_types': [
          0,
          1,
        ],
        'consumption_kg_per_m2_mm': 1.1,
        'thickness_mm': 1,
      },
      {
        'key': 'start',
        'label': 'Стартовая',
        'category': 'Стартовая',
        'enabled_for_putty_types': [
          1,
          2,
        ],
        'consumption_kg_per_m2_mm': 2.7,
        'thickness_mm': 1,
      },
    ],
  },
  'quality_profiles': [
    {
      'id': 0,
      'key': 'legacy_web',
      'components': {
        'finish': {
          'consumption_kg_per_m2_layer': 1.1,
          'default_layers': 1,
        },
        'start': {
          'consumption_kg_per_m2_layer': 2.7,
          'default_layers': 1,
        },
      },
    },
    {
      'id': 1,
      'key': 'economy',
      'components': {
        'finish': {
          'consumption_kg_per_m2_layer': 1,
          'default_layers': 1,
        },
        'start': {
          'consumption_kg_per_m2_layer': 1.8,
          'default_layers': 1,
        },
      },
    },
    {
      'id': 2,
      'key': 'standard',
      'components': {
        'finish': {
          'consumption_kg_per_m2_layer': 0.8,
          'default_layers': 1,
        },
        'start': {
          'consumption_kg_per_m2_layer': 1.5,
          'default_layers': 2,
        },
      },
    },
    {
      'id': 3,
      'key': 'premium',
      'components': {
        'finish': {
          'consumption_kg_per_m2_layer': 0.5,
          'default_layers': 2,
        },
        'start': {
          'consumption_kg_per_m2_layer': 1.2,
          'default_layers': 2,
        },
      },
    },
  ],
  'field_factors': {
    'enabled': [
      'surface_quality',
      'geometry_complexity',
      'installation_method',
      'worker_skill',
      'waste_factor',
      'logistics_buffer',
      'packaging_rounding',
    ],
  },
  'packaging_rules': {
    'unit': 'kg',
    'default_package_size': 20,
    'allowed_package_sizes': [
      5,
      20,
      25,
    ],
  },
  'material_rules': {
    'primer_l_per_m2_per_coat': 0.15,
    'primer_coats': {
      'finish_only': 1,
      'with_start': 2,
      'start_only': 1,
    },
    'serpyanka_linear_m_per_m2': 1.2,
    'serpyanka_reserve_factor': 1.1,
    'serpyanka_roll_length_m': 45,
    'sandpaper_m2_per_sheet': 5,
    'sandpaper_reserve_factor': 1.1,
    'sandpaper_enabled_for_putty_types': [
      0,
      1,
    ],
  },
  'warnings_rules': {
    'mechanized_area_threshold_m2': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from pvc-panels-canonical.v1.json
const Map<String, dynamic> pvcPanelsSpecData = {
  'calculator_id': 'pvc-panels',
  'formula_version': 'pvc-panels-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 15,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'wallWidth',
      'unit': 'm',
      'default_value': 3,
      'min': 0.5,
      'max': 30,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.5,
      'min': 0.5,
      'max': 10,
    },
    {
      'key': 'panelWidth',
      'unit': 'm',
      'default_value': 0.25,
      'min': 0.1,
      'max': 0.5,
    },
    {
      'key': 'panelType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'needProfile',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'needCorners',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_reserve': 1.1,
    'profile_reserve': 1.1,
    'profile_step': 0.4,
    'panel_lengths': [
      2.7,
      3,
      2.7,
    ],
    'corner_profile_length': 3,
    'standard_corners': 4,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from rebar-canonical.v1.json
const Map<String, dynamic> rebarSpecData = {
  'calculator_id': 'rebar',
  'formula_version': 'rebar-canonical-v1',
  'input_schema': [
    {
      'key': 'structureType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 10,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 8,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 0.3,
      'min': 0.1,
      'max': 1.5,
    },
    {
      'key': 'mainDiameter',
      'unit': 'mm',
      'default_value': 12,
      'min': 6,
      'max': 16,
    },
    {
      'key': 'gridStep',
      'unit': 'mm',
      'default_value': 200,
      'min': 100,
      'max': 300,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'weight_per_meter': {
      '6': 0.222,
      '8': 0.395,
      '10': 0.617,
      '12': 0.888,
      '14': 1.21,
      '16': 1.58,
    },
    'standard_rod_length_m': 11.7,
    'wire_length_per_intersection_m': 0.3,
    'wire_kg_per_m': 0.006,
    'rebar_overlap_factor': 1.12,
    'allowed_diameters': [
      6,
      8,
      10,
      12,
      14,
      16,
    ],
    'allowed_grid_steps': [
      100,
      150,
      200,
      250,
      300,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'slab_main_reserve_factor': 1.05,
    'slab_vertical_tie_spacing_m': 0.6,
    'slab_vertical_tie_extra_m': 0.2,
    'slab_fixators_per_m2': 5,
    'strip_rod_count': 4,
    'strip_stirrup_spacing_m': 0.4,
    'strip_assumed_width_m': 0.3,
    'strip_stirrup_diameter': 8,
    'belt_rod_count': 4,
    'belt_height_m': 0.25,
    'belt_width_m': 0.3,
    'belt_stirrup_spacing_m': 0.4,
    'belt_stirrup_diameter': 6,
    'floor_main_reserve_factor': 1.05,
    'floor_secondary_diameter': 6,
    'floor_secondary_step_multiplier': 2,
  },
  'warnings_rules': {
    'slab_min_height_for_double_grid_m': 0.15,
    'min_diameter_for_foundation_mm': 10,
    'wide_step_threshold_mm': 250,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from roofing-canonical.v1.json
const Map<String, dynamic> roofingSpecData = {
  'calculator_id': 'roofing',
  'formula_version': 'roofing-canonical-v1',
  'input_schema': [
    {
      'key': 'roofingType',
      'default_value': 0,
      'min': 0,
      'max': 5,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 80,
      'min': 10,
      'max': 500,
    },
    {
      'key': 'slope',
      'unit': 'deg',
      'default_value': 30,
      'min': 5,
      'max': 60,
    },
    {
      'key': 'ridgeLength',
      'unit': 'm',
      'default_value': 8,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'sheetWidth',
      'unit': 'm',
      'default_value': 1.18,
      'min': 0.8,
      'max': 1.5,
    },
    {
      'key': 'sheetLength',
      'unit': 'm',
      'default_value': 2.5,
      'min': 1,
      'max': 8,
    },
    {
      'key': 'complexity',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'roofing_types': [
      {
        'id': 0,
        'key': 'metal_tile',
        'label': 'Металлочерепица',
      },
      {
        'id': 1,
        'key': 'soft',
        'label': 'Мягкая кровля',
      },
      {
        'id': 2,
        'key': 'profnastil',
        'label': 'Профнастил',
      },
      {
        'id': 3,
        'key': 'ondulin',
        'label': 'Ондулин',
      },
      {
        'id': 4,
        'key': 'shale',
        'label': 'Шифер',
      },
      {
        'id': 5,
        'key': 'ceramic',
        'label': 'Керамическая черепица',
      },
    ],
    'complexity_profiles': [
      {
        'id': 0,
        'key': 'simple',
        'label': 'Простая',
        'coefficient': 1.05,
      },
      {
        'id': 1,
        'key': 'medium',
        'label': 'Средняя',
        'coefficient': 1.15,
      },
      {
        'id': 2,
        'key': 'complex',
        'label': 'Сложная',
        'coefficient': 1.25,
      },
    ],
    'generic_sheet_specs': [
      {
        'id': 2,
        'key': 'profnastil',
        'label': 'Профнастил',
        'effective_width': 0,
        'effective_height': 0,
        'area': 0,
        'fasteners_per_m2': 10,
      },
      {
        'id': 3,
        'key': 'ondulin',
        'label': 'Ондулин',
        'effective_width': 0.83,
        'effective_height': 1.85,
        'area': 1.5355,
        'fasteners_per_m2': 20,
      },
      {
        'id': 4,
        'key': 'shale',
        'label': 'Шифер',
        'effective_width': 0.98,
        'effective_height': 1.55,
        'area': 1.519,
        'fasteners_per_m2': 4,
      },
      {
        'id': 5,
        'key': 'ceramic',
        'label': 'Керамическая черепица',
        'effective_width': 0,
        'effective_height': 0,
        'area': 0.07692,
        'fasteners_per_m2': 4,
      },
    ],
  },
  'packaging_rules': {
    'sheet_unit': 'листов',
    'tile_unit': 'шт',
    'pack_unit': 'упаковок',
  },
  'material_rules': {
    'metal_tile_overlap_horizontal_m': 0.08,
    'metal_tile_overlap_vertical_m': 0.15,
    'metal_tile_screws_per_m2': 9,
    'metal_tile_ridge_element_m': 2,
    'metal_tile_ridge_reserve': 1.05,
    'metal_tile_snow_guard_spacing_m': 3,
    'metal_tile_waterproofing_reserve': 1.15,
    'metal_tile_waterproofing_roll_m2': 75,
    'metal_tile_batten_step_m': 0.35,
    'metal_tile_batten_reserve': 1.1,
    'metal_tile_counter_batten_step_m': 1,
    'metal_tile_counter_batten_reserve': 1.1,
    'soft_pack_area_m2': 3,
    'soft_underlayment_roll_m2': 15,
    'soft_underlayment_reserve': 1.15,
    'soft_mastic_bucket_kg': 3,
    'soft_nails_per_m2': 80,
    'soft_nails_per_kg': 400,
    'soft_nails_reserve': 1.05,
    'soft_ridge_element_m': 0.5,
    'soft_ridge_reserve': 1.05,
    'soft_osb_sheet_m2': 3.125,
    'soft_osb_reserve': 1.05,
    'soft_vent_area_m2': 25,
    'soft_low_slope_threshold': 18,
    'generic_ridge_element_m': 0.33,
    'generic_ridge_reserve': 1.05,
    'generic_waterproofing_reserve': 1.15,
    'generic_waterproofing_roll_m2': 75,
  },
  'warnings_rules': {
    'metal_tile_min_slope': 14,
    'soft_roofing_min_slope': 12,
    'large_roof_area_threshold': 200,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from screed-canonical.v1.json
const Map<String, dynamic> screedSpecData = {
  'calculator_id': 'screed',
  'formula_version': 'screed-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 0.1,
      'max': 50,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 0.1,
      'max': 50,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 0.1,
      'max': 1000,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 50,
      'min': 30,
      'max': 200,
    },
    {
      'key': 'screedType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'screed_types': [
      {
        'id': 0,
        'key': 'cps_1_3',
        'label': 'ЦПС 1:3 (ручной замес)',
        'density_kg_per_m3': 0,
      },
      {
        'id': 1,
        'key': 'ready_cps_m150',
        'label': 'Готовая ЦПС М150',
        'density_kg_per_m3': 2000,
      },
      {
        'id': 2,
        'key': 'semi_dry',
        'label': 'Полусухая стяжка',
        'density_kg_per_m3': 1800,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'кг',
    'bag_weights': [
      40,
      50,
    ],
  },
  'material_rules': {
    'volume_multiplier': 1.08,
    'cement_density': 1300,
    'cement_fraction': 0.25,
    'sand_fraction': 0.75,
    'sand_density': 1.6,
    'water_per_m3': 200,
    'cps_density_ready': 2000,
    'cps_density_semidry': 1800,
    'fiber_kg_per_m2': 0.6,
    'mesh_margin': 1.15,
    'film_margin': 1.1,
    'damper_tape_reserve': 1.05,
    'beacons_area_per_piece': 2,
    'mesh_thickness_threshold_mm': 40,
    'min_thickness_mm': 30,
    'max_thickness_mm': 200,
  },
  'warnings_rules': {
    'thin_threshold_mm': 30,
    'thick_threshold_mm': 100,
    'large_area_cps_threshold_m2': 50,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from self-leveling-canonical.v1.json
const Map<String, dynamic> selfLevelingSpecData = {
  'calculator_id': 'self-leveling',
  'formula_version': 'self-leveling-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 1000,
    },
    {
      'key': 'thickness',
      'unit': 'mm',
      'default_value': 10,
      'min': 3,
      'max': 100,
    },
    {
      'key': 'mixtureType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'consumptionOverride',
      'unit': 'kg/m2/mm',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'bagWeight',
      'unit': 'kg',
      'default_value': 25,
      'min': 20,
      'max': 25,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'waste_factor',
      'logistics_buffer',
      'packaging_rounding',
    ],
  },
  'normative_formula': {
    'mixture_types': [
      {
        'id': 0,
        'key': 'leveling',
        'label': 'Выравнивающая смесь',
        'base_kg_per_m2_mm': 1.6,
      },
      {
        'id': 1,
        'key': 'finish',
        'label': 'Финишная смесь',
        'base_kg_per_m2_mm': 1.4,
      },
      {
        'id': 2,
        'key': 'fast',
        'label': 'Быстросхватывающаяся смесь',
        'base_kg_per_m2_mm': 1.8,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'кг',
    'primer_can_l': 5,
    'tape_roll_m': 25,
  },
  'material_rules': {
    'reserve_factor': 1.05,
    'primer_l_per_m2': 0.15,
    'leveling_min_thickness_mm': 5,
    'finish_max_thickness_mm': 30,
    'deformation_joint_area_threshold_m2': 30,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 30,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from sewage-canonical.v1.json
const Map<String, dynamic> sewageSpecData = {
  'calculator_id': 'sewage',
  'formula_version': 'sewage-canonical-v1',
  'input_schema': [
    {
      'key': 'residents',
      'default_value': 4,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'septikType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'chambersCount',
      'default_value': 2,
      'min': 1,
      'max': 3,
    },
    {
      'key': 'pipeLength',
      'unit': 'm',
      'default_value': 10,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'groundType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'septik_types': [
      {
        'id': 0,
        'key': 'concrete_rings',
        'label': 'Бетонные кольца',
      },
      {
        'id': 1,
        'key': 'plastic',
        'label': 'Пластиковый септик',
      },
      {
        'id': 2,
        'key': 'eurocubes',
        'label': 'Еврокубы',
      },
    ],
    'ground_types': [
      {
        'id': 0,
        'key': 'sand',
        'label': 'Песок',
        'gravel_m3': 0,
      },
      {
        'id': 1,
        'key': 'loam',
        'label': 'Суглинок',
        'gravel_m3': 2,
      },
      {
        'id': 2,
        'key': 'clay',
        'label': 'Глина',
        'gravel_m3': 4,
      },
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'liters_per_person_per_day': 200,
    'reserve_days': 3,
    'ring_volume_m3': 0.71,
    'eurocube_usable_m3': 0.8,
    'pipe_section_m': 3,
    'pipe_reserve': 1.05,
    'default_elbows': 3,
    'default_tees': 2,
    'gravel_by_ground': {
      '0': 0,
      '1': 2,
      '2': 4,
    },
    'geotextile_factor': 2,
    'sand_backfill_factor': 0.5,
  },
  'warnings_rules': {
    'bio_treatment_residents_threshold': 10,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from siding-canonical.v1.json
const Map<String, dynamic> sidingSpecData = {
  'calculator_id': 'siding',
  'formula_version': 'siding-canonical-v1',
  'input_schema': [
    {
      'key': 'facadeArea',
      'unit': 'm2',
      'default_value': 100,
      'min': 10,
      'max': 1000,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 10,
      'min': 0,
      'max': 100,
    },
    {
      'key': 'perimeter',
      'unit': 'm',
      'default_value': 40,
      'min': 10,
      'max': 200,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 5,
      'min': 2,
      'max': 15,
    },
    {
      'key': 'sidingType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'exteriorCorners',
      'default_value': 4,
      'min': 0,
      'max': 20,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'siding_types': [
      0,
      1,
      2,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_areas': {
      '0': 0.732,
      '1': 0.9,
      '2': 0.63,
    },
    'panel_reserve': 1.1,
    'starter_length': 3.66,
    'j_profile_length': 3.66,
    'corner_length': 3,
    'finish_length': 3.66,
    'screws_per_m2': 12,
    'screw_reserve': 1.05,
    'batten_step': 0.5,
    'batten_reserve': 1.05,
    'membrane_roll': 75,
    'membrane_reserve': 1.15,
    'sealant_per_perim': 15,
    'starter_reserve': 1.05,
    'j_reserve': 1.1,
    'corner_reserve': 1.05,
  },
  'warnings_rules': {
    'large_net_area_threshold_m2': 300,
    'high_openings_ratio': 0.3,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from slopes-canonical.v1.json
const Map<String, dynamic> slopesSpecData = {
  'calculator_id': 'slopes',
  'formula_version': 'slopes-canonical-v1',
  'input_schema': [
    {
      'key': 'openingCount',
      'default_value': 5,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'openingType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'slopeWidth',
      'unit': 'mm',
      'default_value': 350,
      'min': 150,
      'max': 500,
    },
    {
      'key': 'finishType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'opening_types': [
      0,
      1,
      2,
      3,
    ],
    'finish_types': [
      0,
      1,
      2,
      3,
    ],
    'opening_dims': {
      '0': [
        1200,
        1400,
        3,
      ],
      '1': [
        900,
        1200,
        3,
      ],
      '2': [
        800,
        2000,
        2,
      ],
      '3': [
        900,
        2000,
        3,
      ],
    },
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_m2': 3.6,
    'gkl_m2': 3,
    'plaster_kg_per_m2': 12,
    'putty_kg_per_m2': 1.2,
    'primer_l_per_m2': 0.15,
    'corner_profile_m': 3,
    'f_profile_m': 3,
    'panel_reserve': 1.12,
    'plaster_reserve': 1.1,
    'putty_reserve': 1.1,
    'gkl_reserve': 1.12,
    'primer_reserve': 1.15,
  },
  'warnings_rules': {
    'wide_slope_threshold_mm': 400,
    'bulk_opening_threshold': 15,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from soft-roofing-canonical.v1.json
const Map<String, dynamic> softRoofingSpecData = {
  'calculator_id': 'soft-roofing',
  'formula_version': 'soft-roofing-canonical-v1',
  'input_schema': [
    {
      'key': 'roofArea',
      'unit': 'm²',
      'default_value': 80,
      'min': 10,
      'max': 500,
    },
    {
      'key': 'slope',
      'unit': '°',
      'default_value': 30,
      'min': 12,
      'max': 60,
    },
    {
      'key': 'ridgeLength',
      'unit': 'm',
      'default_value': 8,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'eaveLength',
      'unit': 'm',
      'default_value': 20,
      'min': 0,
      'max': 100,
    },
    {
      'key': 'valleyLength',
      'unit': 'm',
      'default_value': 0,
      'min': 0,
      'max': 30,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'упаковок',
    'package_size': 1,
  },
  'material_rules': {
    'pack_area': 3,
    'pack_reserve': 1.05,
    'underlayment_roll': 15,
    'underlayment_full_reserve': 1.15,
    'slope_threshold': 18,
    'critical_zone_width': 1,
    'valley_roll': 10,
    'valley_reserve': 1.15,
    'mastic_linear_rate': 0.1,
    'mastic_area_rate': 0.1,
    'mastic_bucket': 3,
    'nails_per_m2': 80,
    'nails_per_kg': 400,
    'nail_reserve': 1.05,
    'eave_strip_length': 2,
    'eave_reserve': 1.05,
    'wind_strip_ratio': 0.4,
    'ridge_shingle_step': 0.5,
    'ridge_reserve': 1.05,
    'osb_sheet': 3.125,
    'osb_reserve': 1.05,
    'vent_per_area': 25,
  },
  'warnings_rules': {
    'low_slope_threshold': 18,
    'valley_warning': true,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from sound-insulation-canonical.v1.json
const Map<String, dynamic> soundInsulationSpecData = {
  'calculator_id': 'sound-insulation',
  'formula_version': 'sound-insulation-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 30,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'surfaceType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'system',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'surface_types': [
      0,
      1,
      2,
    ],
    'systems': [
      0,
      1,
      2,
      3,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'rockwool_plate': 0.6,
    'rockwool_reserve': 1.1,
    'gkl_sheet': 3,
    'gkl_reserve_2layers': 2,
    'pp_spacing': 0.6,
    'pp_length': 3,
    'vibro_per_m2': 2,
    'vibro_reserve': 1.05,
    'vibro_tape_roll': 30,
    'zips_plate': 0.72,
    'zips_reserve': 1.1,
    'zips_dubels_per_panel': 6,
    'zips_dubel_reserve': 1.05,
    'float_mat_roll': 20,
    'float_reserve': 1.1,
    'damp_tape_roll': 25,
    'screed_thickness': 0.05,
    'screed_density': 1800,
    'screed_bag': 50,
    'sealant_per_perim': 20,
    'seal_tape_roll': 30,
    'seal_tape_reserve': 1.1,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 200,
    'professional_system_note': true,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from stairs-canonical.v1.json
const Map<String, dynamic> stairsSpecData = {
  'calculator_id': 'stairs',
  'formula_version': 'stairs-canonical-v1',
  'input_schema': [
    {
      'key': 'floorHeight',
      'unit': 'm',
      'default_value': 2.8,
      'min': 2,
      'max': 6,
    },
    {
      'key': 'stepHeight',
      'unit': 'mm',
      'default_value': 170,
      'min': 150,
      'max': 200,
    },
    {
      'key': 'stepWidth',
      'unit': 'mm',
      'default_value': 280,
      'min': 250,
      'max': 320,
    },
    {
      'key': 'stairWidth',
      'unit': 'm',
      'default_value': 1,
      'min': 0.6,
      'max': 2,
    },
    {
      'key': 'materialType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'stringer_board': '50×250',
    'tread_board': '40×300',
    'riser_board': '20×170',
    'stringers_count': 2,
    'railing_spacing': 0.15,
    'concrete_density_for_stairs': 2400,
    'rebar_kg_per_step_width': 10,
  },
  'warnings_rules': {
    'steep_step_threshold_mm': 190,
    'max_steps_per_flight': 18,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from strip-foundation-canonical.v1.json
const Map<String, dynamic> stripFoundationSpecData = {
  'calculator_id': 'strip-foundation',
  'formula_version': 'strip-foundation-canonical-v1',
  'input_schema': [
    {
      'key': 'perimeter',
      'unit': 'm',
      'default_value': 40,
      'min': 10,
      'max': 200,
    },
    {
      'key': 'width',
      'unit': 'mm',
      'default_value': 400,
      'min': 200,
      'max': 600,
    },
    {
      'key': 'depth',
      'unit': 'mm',
      'default_value': 700,
      'min': 300,
      'max': 2000,
    },
    {
      'key': 'aboveGround',
      'unit': 'mm',
      'default_value': 300,
      'min': 0,
      'max': 600,
    },
    {
      'key': 'reinforcement',
      'default_value': 1,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'deliveryMethod',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'м³',
    'volume_step_m3': 0.1,
  },
  'material_rules': {
    'rebar_diameters': {
      '0': 12,
      '1': 12,
      '2': 14,
      '3': 12,
    },
    'rebar_threads': {
      '0': 2,
      '1': 4,
      '2': 4,
      '3': 6,
    },
    'weight_per_m': {
      '12': 0.888,
      '14': 1.21,
    },
    'clamp_weight': 0.395,
    'clamp_step': 0.4,
    'tech_loss': {
      '0': 0.5,
      '1': 0,
      '2': 0,
    },
    'concrete_reserve': 1.07,
    'overlap': 1.12,
  },
  'warnings_rules': {
    'shallow_depth_threshold_mm': 400,
    'large_perimeter_threshold_m': 100,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from terrace-canonical.v1.json
const Map<String, dynamic> terraceSpecData = {
  'calculator_id': 'terrace',
  'formula_version': 'terrace-canonical-v1',
  'input_schema': [
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 3,
      'min': 1,
      'max': 15,
    },
    {
      'key': 'boardType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'boardLength',
      'unit': 'mm',
      'default_value': 3000,
      'min': 2000,
      'max': 6000,
    },
    {
      'key': 'lagStep',
      'unit': 'mm',
      'default_value': 400,
      'min': 300,
      'max': 600,
    },
    {
      'key': 'withTreatment',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'board_types': [
      0,
      1,
      2,
      3,
    ],
    'board_lengths': [
      2000,
      3000,
      4000,
      6000,
    ],
    'lag_steps': [
      300,
      400,
      500,
      600,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'board_widths': {
      '0': 150,
      '1': 120,
      '2': 90,
      '3': 120,
    },
    'board_gaps': {
      '0': 5,
      '1': 5,
      '2': 5,
      '3': 0,
    },
    'lag_length': 3,
    'treatment_l_per_m2': 0.15,
    'treatment_layers': {
      '0': 0,
      '1': 2,
      '2': 2,
    },
    'geotextile_roll': 50,
    'board_reserve': 1.1,
    'lag_reserve': 1.05,
    'klaymer_count_per_lag_row': 1,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 50,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from tile-adhesive-canonical.v1.json
const Map<String, dynamic> tileAdhesiveSpecData = {
  'calculator_id': 'tile-adhesive',
  'formula_version': 'tile-adhesive-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 20,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'tileSize',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'laying',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'base',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'bagWeight',
      'unit': 'kg',
      'default_value': 25,
      'min': 5,
      'max': 25,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'tile_sizes': [
      0,
      1,
      2,
    ],
    'laying_types': [
      0,
      1,
      2,
    ],
    'base_types': [
      0,
      1,
      2,
    ],
  },
  'packaging_rules': {
    'unit': 'мешков',
    'default_bag_weight': 25,
    'allowed_bag_weights': [
      5,
      25,
    ],
  },
  'material_rules': {
    'base_consumption': {
      '0': 3,
      '1': 5,
      '2': 7.5,
    },
    'wall_factor': 0.85,
    'street_factor': 1.3,
    'old_tile_factor': 1.2,
    'adhesive_reserve': 1.1,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can': 10,
    'tile_sizes_for_cross': {
      '0': 0.3,
      '1': 0.45,
      '2': 0.6,
    },
    'crosses_per_tile': 4,
    'cross_reserve': 1.1,
    'cross_pack': 200,
  },
  'warnings_rules': {
    'large_tile_warning': true,
    'old_tile_primer_warning': true,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from tile-canonical.v1.json
const Map<String, dynamic> tileSpecData = {
  'calculator_id': 'tile',
  'formula_version': 'tile-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 1,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 4,
      'min': 0.5,
      'max': 30,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 3,
      'min': 0.5,
      'max': 30,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 12,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'tileWidthCm',
      'unit': 'cm',
      'default_value': 30,
      'min': 5,
      'max': 200,
    },
    {
      'key': 'tileHeightCm',
      'unit': 'cm',
      'default_value': 30,
      'min': 5,
      'max': 200,
    },
    {
      'key': 'jointWidth',
      'unit': 'mm',
      'default_value': 3,
      'min': 1,
      'max': 10,
    },
    {
      'key': 'groutDepth',
      'unit': 'mm',
      'default_value': 0,
      'min': 0,
      'max': 15,
    },
    {
      'key': 'layoutPattern',
      'default_value': 1,
      'min': 1,
      'max': 4,
    },
    {
      'key': 'roomComplexity',
      'default_value': 1,
      'min': 1,
      'max': 3,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'installation_method',
      'worker_skill',
    ],
  },
  'normative_formula': {
    'layouts': [
      {
        'id': 1,
        'key': 'straight',
        'label': 'Прямая укладка',
        'waste_percent': 10,
      },
      {
        'id': 2,
        'key': 'diagonal',
        'label': 'Диагональная укладка',
        'waste_percent': 15,
      },
      {
        'id': 3,
        'key': 'offset',
        'label': 'Укладка со смещением',
        'waste_percent': 10,
      },
      {
        'id': 4,
        'key': 'herringbone',
        'label': 'Укладка ёлочкой',
        'waste_percent': 20,
      },
    ],
    'room_complexities': [
      {
        'id': 1,
        'key': 'simple',
        'label': 'Прямоугольная комната',
        'waste_bonus_percent': 0,
      },
      {
        'id': 2,
        'key': 'l_shaped',
        'label': 'Г-образная комната',
        'waste_bonus_percent': 5,
      },
      {
        'id': 3,
        'key': 'complex',
        'label': 'Сложная геометрия',
        'waste_bonus_percent': 10,
      },
    ],
  },
  'packaging_rules': {
    'tile_unit': 'шт',
    'tile_package_size': 1,
    'glue_bag_kg': 25,
    'grout_bag_kg': 2,
    'primer_can_l': 5,
    'svp_pack_size': 100,
  },
  'material_rules': {
    'glue_kg_per_m2_small': 3.5,
    'glue_kg_per_m2_medium': 4,
    'glue_kg_per_m2_large': 5.5,
    'glue_kg_per_m2_xl': 6.5,
    'primer_l_per_m2': 0.15,
    'grout_density_kg_per_m3': 1600,
    'grout_loss_factor': 1.1,
    'crosses_reserve_factor': 1.2,
    'svp_threshold_cm': 45,
    'large_tile_extra_waste_percent': 5,
    'mosaic_waste_discount_percent': -3,
    'silicone_tube_area_m2': 15,
  },
  'warnings_rules': {
    'low_tile_count_threshold': 5,
    'large_tile_warning_threshold_cm': 60,
    'herringbone_large_area_m2': 30,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from tile-grout-canonical.v1.json
const Map<String, dynamic> tileGroutSpecData = {
  'calculator_id': 'tile-grout',
  'formula_version': 'tile-grout-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm²',
      'default_value': 20,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'tileWidth',
      'unit': 'mm',
      'default_value': 300,
      'min': 50,
      'max': 1200,
    },
    {
      'key': 'tileHeight',
      'unit': 'mm',
      'default_value': 300,
      'min': 50,
      'max': 1200,
    },
    {
      'key': 'tileThickness',
      'unit': 'mm',
      'default_value': 8,
      'min': 6,
      'max': 25,
    },
    {
      'key': 'jointWidth',
      'unit': 'mm',
      'default_value': 3,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'groutType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'bagSize',
      'unit': 'kg',
      'default_value': 2,
      'min': 1,
      'max': 5,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'grout_types': [
      0,
      1,
      2,
    ],
    'bag_sizes': [
      1,
      2,
      5,
    ],
  },
  'packaging_rules': {
    'unit': 'мешков',
    'default_bag_size': 2,
    'allowed_bag_sizes': [
      1,
      2,
      5,
    ],
  },
  'material_rules': {
    'grout_density': {
      '0': 1600,
      '1': 1400,
      '2': 1200,
    },
    'grout_reserve': 1.1,
  },
  'warnings_rules': {
    'wide_joint_threshold_mm': 10,
    'epoxy_warning': true,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from ventilation-canonical.v1.json
const Map<String, dynamic> ventilationSpecData = {
  'calculator_id': 'ventilation',
  'formula_version': 'ventilation-canonical-v1',
  'input_schema': [
    {
      'key': 'totalArea',
      'unit': 'm2',
      'default_value': 80,
      'min': 10,
      'max': 1000,
    },
    {
      'key': 'ceilingHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2.5,
      'max': 3.5,
    },
    {
      'key': 'buildingType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
    {
      'key': 'peopleCount',
      'default_value': 3,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'ductType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'building_types': [
      {
        'id': 0,
        'key': 'apartment',
        'label': 'Квартира',
        'exchange_rate': 1.5,
      },
      {
        'id': 1,
        'key': 'house',
        'label': 'Частный дом',
        'exchange_rate': 2,
      },
      {
        'id': 2,
        'key': 'office',
        'label': 'Офис',
        'exchange_rate': 3,
      },
      {
        'id': 3,
        'key': 'industrial',
        'label': 'Производство',
        'exchange_rate': 5,
      },
    ],
    'duct_types': [
      {
        'id': 0,
        'key': 'round',
        'label': 'Круглый ø100–160',
      },
      {
        'id': 1,
        'key': 'rect',
        'label': 'Прямоугольный 200×100',
      },
      {
        'id': 2,
        'key': 'flexible',
        'label': 'Гибкий ø125',
      },
    ],
  },
  'packaging_rules': {
    'unit': 'секций',
    'package_size': 1,
  },
  'material_rules': {
    'exchange_rates': [
      1.5,
      2,
      3,
      5,
    ],
    'air_per_person': 30,
    'fan_reserve': 1.2,
    'airflow_rounding': 50,
    'main_duct_length_coeff': 2.5,
    'main_duct_reserve': 1.15,
    'duct_section_m': 3,
    'flex_duct_coil_m': 10,
    'fittings_per_section': 0.5,
    'fittings_reserve': 1.1,
    'grille_area_m2': 15,
    'grille_base': 1,
    'clamps_per_section': 2,
    'clamps_reserve': 1.1,
    'silencer_count': 1,
  },
  'warnings_rules': {
    'professional_airflow_threshold': 2000,
    'supply_exhaust_people_threshold': 6,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from wall-panels-canonical.v1.json
const Map<String, dynamic> wallPanelsSpecData = {
  'calculator_id': 'wall-panels',
  'formula_version': 'wall-panels-canonical-v1',
  'input_schema': [
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 200,
    },
    {
      'key': 'panelType',
      'default_value': 0,
      'min': 0,
      'max': 4,
    },
    {
      'key': 'mountMethod',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 4,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'panel_types': [
      0,
      1,
      2,
      3,
      4,
    ],
    'mount_methods': [
      0,
      1,
    ],
  },
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'panel_areas': {
      '0': 0.75,
      '1': 0.494,
      '2': 0.25,
      '3': 0.3,
      '4': 0.5,
    },
    'panel_reserve': 1.1,
    'glue_coverage': 4,
    'primer_l_per_m2': 0.15,
    'primer_reserve': 1.15,
    'primer_can': 10,
    'batten_spacing': {
      '0': 0.5,
      '1': 0.5,
      '2': 0.4,
      '3': 0.4,
      '4': 0.4,
    },
    'batten_length': 3,
    'batten_reserve': 1.05,
    'dubel_step': 0.5,
    'klaymer_per_m2': 5,
    'molding_length': 3,
    'molding_reserve': 1.05,
    'sealant_per_perim': 10,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 100,
    'flat_surface_warning_panel_types': [
      2,
    ],
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from wallpaper-canonical.v1.json
const Map<String, dynamic> wallpaperSpecData = {
  'calculator_id': 'wallpaper',
  'formula_version': 'wallpaper-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'perimeter',
      'unit': 'm',
      'default_value': 14,
      'min': 1,
      'max': 200,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 40,
      'min': 0,
      'max': 1000,
    },
    {
      'key': 'roomWidth',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'roomLength',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'roomHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'wallHeight',
      'unit': 'm',
      'default_value': 2.7,
      'min': 2,
      'max': 5,
    },
    {
      'key': 'openingsArea',
      'unit': 'm2',
      'default_value': 0,
      'min': 0,
      'max': 500,
    },
    {
      'key': 'doorsCount',
      'default_value': 0,
      'min': 0,
      'max': 20,
    },
    {
      'key': 'windowsCount',
      'default_value': 0,
      'min': 0,
      'max': 20,
    },
    {
      'key': 'rollWidth',
      'unit': 'm',
      'default_value': 0.53,
      'min': 0.5,
      'max': 1.2,
    },
    {
      'key': 'rollLength',
      'unit': 'm',
      'default_value': 10.05,
      'min': 5,
      'max': 50,
    },
    {
      'key': 'rapport',
      'unit': 'cm',
      'default_value': 0,
      'min': 0,
      'max': 100,
    },
    {
      'key': 'wallpaperType',
      'default_value': 1,
      'min': 1,
      'max': 3,
    },
    {
      'key': 'reservePercent',
      'default_value': 0,
      'min': 0,
      'max': 100,
    },
    {
      'key': 'reserveRolls',
      'default_value': 0,
      'min': 0,
      'max': 10,
    },
  ],
  'field_factors': {
    'enabled': [
      'surface_quality',
      'geometry_complexity',
      'installation_method',
      'worker_skill',
    ],
  },
  'normative_formula': {
    'wallpaper_types': [
      {
        'id': 1,
        'key': 'paper',
        'label': 'Бумажные обои',
        'paste_kg_per_m2': 0.005,
      },
      {
        'id': 2,
        'key': 'vinyl',
        'label': 'Виниловые обои',
        'paste_kg_per_m2': 0.01,
      },
      {
        'id': 3,
        'key': 'fleece',
        'label': 'Флизелиновые обои',
        'paste_kg_per_m2': 0.008,
      },
    ],
    'opening_defaults': {
      'door_area_m2': 1.71,
      'window_area_m2': 1.68,
    },
  },
  'packaging_rules': {
    'roll_unit': 'рулонов',
    'roll_package_size': 1,
    'paste_pack_kg': 0.25,
    'primer_can_l': 5,
  },
  'material_rules': {
    'trim_allowance_m': 0.05,
    'primer_l_per_m2': 0.15,
    'primer_reserve_factor': 1.1,
    'paste_reserve_factor': 1.1,
    'glue_roller_count': 1,
    'wallpaper_spatula_count': 1,
    'knife_count': 1,
    'blades_pack_count': 1,
    'bucket_count': 1,
    'sponge_count': 2,
  },
  'warnings_rules': {
    'large_rapport_threshold_m': 0.32,
    'wide_roll_threshold_m': 0.7,
    'low_strips_per_roll_threshold': 2,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from warm-floor-canonical.v1.json
const Map<String, dynamic> warmFloorSpecData = {
  'calculator_id': 'warm-floor',
  'formula_version': 'warm-floor-canonical-v1',
  'input_schema': [
    {
      'key': 'roomArea',
      'unit': 'm2',
      'default_value': 10,
      'min': 1,
      'max': 100,
    },
    {
      'key': 'furnitureArea',
      'unit': 'm2',
      'default_value': 2,
      'min': 0,
      'max': 50,
    },
    {
      'key': 'heatingType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'powerDensity',
      'unit': 'W/m2',
      'default_value': 150,
      'min': 100,
      'max': 200,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'heating_types': [
      {
        'id': 0,
        'key': 'mat',
        'label': 'Нагревательный мат',
      },
      {
        'id': 1,
        'key': 'cable',
        'label': 'Кабель в стяжку',
      },
      {
        'id': 2,
        'key': 'water_pipes',
        'label': 'Водяные трубы',
      },
    ],
  },
  'packaging_rules': {
    'mat_unit': 'шт',
    'cable_unit': 'м',
    'pipe_unit': 'м',
  },
  'material_rules': {
    'mat_area': 2,
    'cable_step_m': 0.15,
    'cable_reserve': 1.05,
    'pipe_step_m': 0.15,
    'pipe_reserve': 1.05,
    'substrate_reserve': 1.1,
    'substrate_roll_m2': 25,
    'corrugated_tube_m': 1,
    'tile_adhesive_kg_per_m2': 5,
    'tile_adhesive_bag_kg': 25,
    'eps_sheet_m2': 0.72,
    'eps_reserve': 1.1,
    'screed_thickness_m': 0.04,
    'screed_density': 2000,
    'screed_bag_kg': 50,
    'mesh_reserve': 1.05,
    'mounting_tape_roll_m': 25,
    'pipe_insulation_reserve': 1,
    'max_circuit_m': 80,
  },
  'warnings_rules': {
    'separate_breaker_kw_threshold': 3.5,
    'ineffective_coverage_ratio': 0.5,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from warm-floor-pipes-canonical.v1.json
const Map<String, dynamic> warmFloorPipesSpecData = {
  'calculator_id': 'warm-floor-pipes',
  'formula_version': 'warm-floor-pipes-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 5,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'width',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 20,
      'min': 1,
      'max': 300,
    },
    {
      'key': 'pipeStep',
      'unit': 'mm',
      'default_value': 200,
      'min': 100,
      'max': 300,
    },
    {
      'key': 'pipeType',
      'default_value': 0,
      'min': 0,
      'max': 3,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'pipe_types': [
      {
        'id': 0,
        'key': 'pex_a',
        'label': 'PEX-a',
      },
      {
        'id': 1,
        'key': 'pex_b',
        'label': 'PEX-b',
      },
      {
        'id': 2,
        'key': 'pe_rt',
        'label': 'PE-RT',
      },
      {
        'id': 3,
        'key': 'metalplastic',
        'label': 'Металлопластик',
      },
    ],
    'allowed_pipe_steps_mm': [
      100,
      150,
      200,
      250,
      300,
    ],
  },
  'packaging_rules': {
    'unit': 'м',
    'coil_length_m': 200,
  },
  'material_rules': {
    'furniture_reduction': 0.85,
    'collector_addition_m': 3,
    'max_circuit_m': 80,
    'pipe_reserve': 1.05,
    'pipe_coil_m': 200,
    'epps_sheet_m2': 0.72,
    'epps_reserve': 1.05,
    'damper_tape_roll_m': 25,
    'damper_reserve': 1.05,
    'anchor_step_m': 0.3,
    'anchor_reserve': 1.05,
    'anchor_pack': 100,
    'screed_thickness_m': 0.05,
    'screed_density': 1500,
    'screed_bag_kg': 25,
  },
  'warnings_rules': {
    'multiple_circuits_pipe_threshold_m': 80,
    'professional_heat_loss_area_threshold_m2': 40,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from waterproofing-canonical.v1.json
const Map<String, dynamic> waterproofingSpecData = {
  'calculator_id': 'waterproofing',
  'formula_version': 'waterproofing-canonical-v1',
  'input_schema': [
    {
      'key': 'floorArea',
      'unit': 'm2',
      'default_value': 6,
      'min': 1,
      'max': 50,
    },
    {
      'key': 'wallHeight',
      'unit': 'mm',
      'default_value': 200,
      'min': 0,
      'max': 2000,
    },
    {
      'key': 'roomPerimeter',
      'unit': 'm',
      'default_value': 10,
      'min': 4,
      'max': 40,
    },
    {
      'key': 'masticType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
    {
      'key': 'layers',
      'default_value': 2,
      'min': 1,
      'max': 3,
    },
  ],
  'field_factors': {
    'enabled': [
      'surface_quality',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'mastic_types': [
      0,
      1,
      2,
    ],
    'wall_heights': [
      0,
      200,
      300,
      500,
      2000,
    ],
  },
  'packaging_rules': {
    'unit': 'вёдер',
    'package_size': 1,
  },
  'material_rules': {
    'consumption_per_layer': {
      '0': 1,
      '1': 1.2,
      '2': 0.8,
    },
    'bucket_kg': {
      '0': 15,
      '1': 20,
      '2': 15,
    },
    'tape_reserve': 1.1,
    'silicone_m_per_tube': 6,
    'primer_kg_per_m2': 0.15,
    'primer_can_kg': 2,
    'bitumen_l_per_m2': 0.3,
    'bitumen_can_l': 20,
    'joint_sealant_m_per_tube': 10,
  },
  'warnings_rules': {
    'min_layers_residential': 2,
    'min_wall_height_mm': 200,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from windows-canonical.v1.json
const Map<String, dynamic> windowsSpecData = {
  'calculator_id': 'windows',
  'formula_version': 'windows-canonical-v1',
  'input_schema': [
    {
      'key': 'windowCount',
      'default_value': 5,
      'min': 1,
      'max': 20,
    },
    {
      'key': 'windowWidth',
      'unit': 'mm',
      'default_value': 1200,
      'min': 600,
      'max': 2100,
    },
    {
      'key': 'windowHeight',
      'unit': 'mm',
      'default_value': 1400,
      'min': 900,
      'max': 2000,
    },
    {
      'key': 'wallThickness',
      'unit': 'mm',
      'default_value': 500,
      'min': 200,
      'max': 600,
    },
    {
      'key': 'slopeType',
      'default_value': 0,
      'min': 0,
      'max': 2,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {
    'slope_types': [
      0,
      1,
      2,
    ],
    'window_widths': [
      600,
      900,
      1200,
      1500,
      1800,
      2100,
    ],
    'window_heights': [
      900,
      1200,
      1400,
      1600,
      2000,
    ],
  },
  'packaging_rules': {
    'unit': 'баллонов',
    'package_size': 1,
  },
  'material_rules': {
    'psul_roll_m': 5.6,
    'iflul_roll_m': 8.5,
    'psul_reserve': 1.1,
    'anchor_step': 0.7,
    'foam_per_perim': 0.333,
    'foam_reserve': 1.1,
    'windowsill_overhang': 0.15,
    'windowsill_roll': 6,
    'sandwich_panel_m2': 3.6,
    'gkl_sheet_m2': 3,
    'plaster_kg_per_m2': 10,
    'plaster_bag': 25,
    'slope_sandwich_reserve': 1.1,
    'slope_gkl_reserve': 1.12,
    'anchor_reserve': 1.05,
    'screw_reserve': 1.05,
    'f_profile_length': 3,
  },
  'warnings_rules': {
    'wide_window_threshold_mm': 1800,
    'thick_wall_threshold_mm': 500,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Generated from wood-wall-canonical.v1.json
const Map<String, dynamic> woodWallSpecData = {
  'calculator_id': 'wood-wall',
  'formula_version': 'wood-wall-canonical-v1',
  'input_schema': [
    {
      'key': 'inputMode',
      'default_value': 0,
      'min': 0,
      'max': 1,
    },
    {
      'key': 'area',
      'unit': 'm2',
      'default_value': 15,
      'min': 1,
      'max': 500,
    },
    {
      'key': 'length',
      'unit': 'm',
      'default_value': 4,
      'min': 1,
      'max': 30,
    },
    {
      'key': 'height',
      'unit': 'm',
      'default_value': 2.5,
      'min': 2,
      'max': 4,
    },
    {
      'key': 'boardWidth',
      'unit': 'cm',
      'default_value': 10,
      'min': 5,
      'max': 20,
    },
    {
      'key': 'boardLength',
      'unit': 'm',
      'default_value': 3,
      'min': 2,
      'max': 6,
    },
  ],
  'field_factors': {
    'enabled': [
      'geometry_complexity',
      'worker_skill',
      'waste_factor',
    ],
  },
  'normative_formula': {},
  'packaging_rules': {
    'unit': 'шт',
    'package_size': 1,
  },
  'material_rules': {
    'board_reserve': 1.1,
    'antiseptic_l_per_m2': 0.3,
    'finish_l_per_m2': 0.1,
    'finish_layers': 2,
    'primer_l_per_m2': 0.1,
    'fasteners_per_board': 9,
    'clamps_per_board': 5,
    'batten_step': 0.55,
    'plinth_reserve': 1.03,
    'corner_ratio': 0.25,
    'corner_reserve': 1.05,
  },
  'warnings_rules': {
    'large_area_threshold_m2': 50,
  },
  'scenario_policy': {
    'contract': 'min-rec-max-v1',
  },
};

/// Index of all canonical specs by calculator_id.
const Map<String, Map<String, dynamic>> allCanonicalSpecs = {
  'aerated-concrete': aeratedConcreteSpecData,
  'attic': atticSpecData,
  'balcony': balconySpecData,
  'basement': basementSpecData,
  'bathroom': bathroomSpecData,
  'blind-area': blindAreaSpecData,
  'brick': brickSpecData,
  'brickwork': brickworkSpecData,
  'ceiling-cassette': ceilingCassetteSpecData,
  'ceiling-insulation': ceilingInsulationSpecData,
  'ceiling-rail': ceilingRailSpecData,
  'ceiling-stretch': ceilingStretchSpecData,
  'concrete': concreteSpecData,
  'decor-plaster': decorPlasterSpecData,
  'decor-stone': decorStoneSpecData,
  'doors': doorsSpecData,
  'drywall': drywallSpecData,
  'drywall-ceiling': drywallCeilingSpecData,
  'electric': electricSpecData,
  'facade-brick': facadeBrickSpecData,
  'facade-insulation': facadeInsulationSpecData,
  'facade-panels': facadePanelsSpecData,
  'fasteners': fastenersSpecData,
  'fence': fenceSpecData,
  'foam-blocks': foamBlocksSpecData,
  'foundation-slab': foundationSlabSpecData,
  'frame-house': frameHouseSpecData,
  'gutters': guttersSpecData,
  'gypsum-board': gypsumBoardSpecData,
  'heating': heatingSpecData,
  'insulation': insulationSpecData,
  'laminate': laminateSpecData,
  'linoleum': linoleumSpecData,
  'mdf-panels': mdfPanelsSpecData,
  'paint': paintSpecData,
  'panels-3d': panels3dSpecData,
  'parquet': parquetSpecData,
  'partitions': partitionsSpecData,
  'plaster': plasterSpecData,
  'primer': primerSpecData,
  'putty': puttySpecData,
  'pvc-panels': pvcPanelsSpecData,
  'rebar': rebarSpecData,
  'roofing': roofingSpecData,
  'screed': screedSpecData,
  'self-leveling': selfLevelingSpecData,
  'sewage': sewageSpecData,
  'siding': sidingSpecData,
  'slopes': slopesSpecData,
  'soft-roofing': softRoofingSpecData,
  'sound-insulation': soundInsulationSpecData,
  'stairs': stairsSpecData,
  'strip-foundation': stripFoundationSpecData,
  'terrace': terraceSpecData,
  'tile-adhesive': tileAdhesiveSpecData,
  'tile': tileSpecData,
  'tile-grout': tileGroutSpecData,
  'ventilation': ventilationSpecData,
  'wall-panels': wallPanelsSpecData,
  'wallpaper': wallpaperSpecData,
  'warm-floor': warmFloorSpecData,
  'warm-floor-pipes': warmFloorPipesSpecData,
  'waterproofing': waterproofingSpecData,
  'windows': windowsSpecData,
  'wood-wall': woodWallSpecData,
};

/// Default factor table from configs/factor-tables.json
const Map<String, Map<String, double>> defaultFactorTable = {
  'surface_quality': {'MIN': 0.95, 'REC': 1, 'MAX': 1.08},
  'geometry_complexity': {'MIN': 0.97, 'REC': 1, 'MAX': 1.12},
  'installation_method': {'MIN': 0.98, 'REC': 1, 'MAX': 1.1},
  'worker_skill': {'MIN': 0.96, 'REC': 1, 'MAX': 1.07},
  'waste_factor': {'MIN': 1, 'REC': 1.06, 'MAX': 1.15},
  'logistics_buffer': {'MIN': 1, 'REC': 1.02, 'MAX': 1.06},
  'packaging_rounding': {'MIN': 1, 'REC': 1.01, 'MAX': 1.03},
};
