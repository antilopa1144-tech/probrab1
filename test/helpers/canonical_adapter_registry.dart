import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';
import 'package:probrab_ai/domain/usecases/aerated_concrete_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/attic_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/balcony_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/basement_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/bathroom_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/blind_area_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/brick_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/brickwork_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/ceiling_cassette_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/ceiling_insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/ceiling_rail_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/ceiling_stretch_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/concrete_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/decor_plaster_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/decor_stone_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/doors_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/drainage_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/drywall_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/drywall_ceiling_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_brick_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/electric_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/foundation_slab_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/fasteners_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/fence_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/foam_blocks_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/frame_house_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/greenhouse_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/gutters_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/gypsum_board_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/heating_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/laminate_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/lawn_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/linoleum_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/mdf_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/paint_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/panels_3d_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/parquet_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/partitions_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/plaster_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/paving_tiles_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/primer_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/pvc_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/rebar_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/roofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/screed_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/putty_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/septic_rings_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/sewage_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/stairs_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/self_leveling_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/siding_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/slopes_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/soft_roofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/sound_insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/strip_foundation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/terrace_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/tile_adhesive_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/tile_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/tile_grout_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/ventilation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wall_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wallpaper_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_pipes_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/waterproofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/windows_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wood_wall_canonical_adapter.dart';

typedef CanonicalAdapterFn = CanonicalCalculatorContractResult Function(
  Map<String, double> inputs,
);

/// Canonical adapters keyed by calculator_id (underscore form).
const Map<String, CanonicalAdapterFn> canonicalAdapterRegistry = {
  'aerated_concrete': calculateCanonicalAeratedConcrete,
  'attic': calculateCanonicalAttic,
  'balcony': calculateCanonicalBalcony,
  'basement': calculateCanonicalBasement,
  'bathroom': calculateCanonicalBathroom,
  'blind_area': calculateCanonicalBlindArea,
  'brick': calculateCanonicalBrick,
  'brickwork': calculateCanonicalBrickwork,
  'ceiling_cassette': calculateCanonicalCeilingCassette,
  'ceiling_insulation': calculateCanonicalCeilingInsulation,
  'ceiling_rail': calculateCanonicalCeilingRail,
  'ceiling_stretch': calculateCanonicalCeilingStretch,
  'concrete': calculateCanonicalConcrete,
  'decor_plaster': calculateCanonicalDecorPlaster,
  'decor_stone': calculateCanonicalDecorStone,
  'doors': calculateCanonicalDoors,
  'drainage': calculateCanonicalDrainage,
  'drywall': calculateCanonicalDrywall,
  'drywall_ceiling': calculateCanonicalDrywallCeiling,
  'facade_brick': calculateCanonicalFacadeBrick,
  'facade_insulation': calculateCanonicalFacadeInsulation,
  'electric': calculateCanonicalElectric,
  'facade_panels': calculateCanonicalFacadePanels,
  'fasteners': calculateCanonicalFasteners,
  'fence': calculateCanonicalFence,
  'foam_blocks': calculateCanonicalFoamBlocks,
  'foundation_slab': calculateCanonicalFoundationSlab,
  'frame_house': calculateCanonicalFrameHouse,
  'greenhouse': calculateCanonicalGreenhouse,
  'gutters': calculateCanonicalGutters,
  'gypsum_board': calculateCanonicalGypsumBoard,
  'heating': calculateCanonicalHeating,
  'insulation': calculateCanonicalInsulation,
  'laminate': calculateCanonicalLaminate,
  'lawn': calculateCanonicalLawn,
  'linoleum': calculateCanonicalLinoleum,
  'mdf_panels': calculateCanonicalMdfPanels,
  'paint': calculateCanonicalPaint,
  'panels_3d': calculateCanonicalPanels3d,
  'parquet': calculateCanonicalParquet,
  'partitions': calculateCanonicalPartitions,
  'plaster': calculateCanonicalPlaster,
  'paving_tiles': calculateCanonicalPavingTiles,
  'primer': calculateCanonicalPrimer,
  'putty': calculateCanonicalPutty,
  'pvc_panels': calculateCanonicalPvcPanels,
  'rebar': calculateCanonicalRebar,
  'roofing': calculateCanonicalRoofing,
  'screed': calculateCanonicalScreed,
  'self_leveling': calculateCanonicalSelfLeveling,
  'septic_rings': calculateCanonicalSepticRings,
  'sewage': calculateCanonicalSewage,
  'siding': calculateCanonicalSiding,
  'slopes': calculateCanonicalSlopes,
  'soft_roofing': calculateCanonicalSoftRoofing,
  'sound_insulation': calculateCanonicalSoundInsulation,
  'stairs': calculateCanonicalStairs,
  'strip_foundation': calculateCanonicalStripFoundation,
  'terrace': calculateCanonicalTerrace,
  'tile': calculateCanonicalTile,
  'tile_adhesive': calculateCanonicalTileAdhesive,
  'tile_grout': calculateCanonicalTileGrout,
  'ventilation': calculateCanonicalVentilation,
  'wall_panels': calculateCanonicalWallPanels,
  'wallpaper': calculateCanonicalWallpaper,
  'warm_floor': calculateCanonicalWarmFloor,
  'warm_floor_pipes': calculateCanonicalWarmFloorPipes,
  'waterproofing': calculateCanonicalWaterproofing,
  'windows': calculateCanonicalWindows,
  'wood_wall': calculateCanonicalWoodWall,
};

/// Adapters planned but not yet implemented in Flutter.
const Set<String> pendingCanonicalAdapterIds = {};

CanonicalAdapterFn? lookupCanonicalAdapter(String calculatorId) {
  final normalized = calculatorId.replaceAll('-', '_');
  return canonicalAdapterRegistry[normalized];
}
