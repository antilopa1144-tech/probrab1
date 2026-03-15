import 'package:flutter_test/flutter_test.dart';

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
import 'package:probrab_ai/domain/usecases/drywall_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/drywall_ceiling_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/electric_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_brick_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/fasteners_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/fence_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/foam_blocks_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/foundation_slab_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/frame_house_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/gutters_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/gypsum_board_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/heating_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/laminate_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/linoleum_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/mdf_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/paint_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/panels_3d_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/parquet_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/partitions_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/plaster_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/primer_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/putty_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/pvc_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/rebar_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/roofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/screed_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/self_leveling_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/sewage_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/siding_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/slopes_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/soft_roofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/sound_insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/stairs_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/strip_foundation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/terrace_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/tile_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/tile_adhesive_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/tile_grout_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/ventilation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wall_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wallpaper_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_pipes_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/waterproofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/windows_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wood_wall_canonical_adapter.dart';

import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';

void main() {
  group('Canonical adapter parity — all 65 calculators with empty inputs', () {
    // Helper that runs the four standard assertions on every adapter result.
    void assertCanonicalContract(
      String adapterId,
      CanonicalCalculatorContractResult result,
    ) {
      // 1. Result is not null (Dart non-nullable, but verify object is usable)
      expect(result, isNotNull, reason: '$adapterId: result must not be null');

      // 2. Materials list is not empty
      expect(result.materials, isNotEmpty,
          reason: '$adapterId: materials must not be empty');

      // 3. Scenarios contains MIN, REC, MAX
      expect(result.scenarios.containsKey('MIN'), isTrue,
          reason: '$adapterId: scenarios must contain MIN');
      expect(result.scenarios.containsKey('REC'), isTrue,
          reason: '$adapterId: scenarios must contain REC');
      expect(result.scenarios.containsKey('MAX'), isTrue,
          reason: '$adapterId: scenarios must contain MAX');

      // 4. formulaVersion is not empty
      expect(result.formulaVersion, isNotEmpty,
          reason: '$adapterId: formulaVersion must not be empty');
    }

    test('aerated_concrete', () {
      final result = calculateCanonicalAeratedConcrete(<String, double>{});
      assertCanonicalContract('aerated_concrete', result);
    });

    test('attic', () {
      final result = calculateCanonicalAttic(<String, double>{});
      assertCanonicalContract('attic', result);
    });

    test('balcony', () {
      final result = calculateCanonicalBalcony(<String, double>{});
      assertCanonicalContract('balcony', result);
    });

    test('basement', () {
      final result = calculateCanonicalBasement(<String, double>{});
      assertCanonicalContract('basement', result);
    });

    test('bathroom', () {
      final result = calculateCanonicalBathroom(<String, double>{});
      assertCanonicalContract('bathroom', result);
    });

    test('blind_area', () {
      final result = calculateCanonicalBlindArea(<String, double>{});
      assertCanonicalContract('blind_area', result);
    });

    test('brick', () {
      final result = calculateCanonicalBrick(<String, double>{});
      assertCanonicalContract('brick', result);
    });

    test('brickwork', () {
      final result = calculateCanonicalBrickwork(<String, double>{});
      assertCanonicalContract('brickwork', result);
    });

    test('ceiling_cassette', () {
      final result = calculateCanonicalCeilingCassette(<String, double>{});
      assertCanonicalContract('ceiling_cassette', result);
    });

    test('ceiling_insulation', () {
      final result = calculateCanonicalCeilingInsulation(<String, double>{});
      assertCanonicalContract('ceiling_insulation', result);
    });

    test('ceiling_rail', () {
      final result = calculateCanonicalCeilingRail(<String, double>{});
      assertCanonicalContract('ceiling_rail', result);
    });

    test('ceiling_stretch', () {
      final result = calculateCanonicalCeilingStretch(<String, double>{});
      assertCanonicalContract('ceiling_stretch', result);
    });

    test('concrete', () {
      final result = calculateCanonicalConcrete(<String, double>{});
      assertCanonicalContract('concrete', result);
    });

    test('decor_plaster', () {
      final result = calculateCanonicalDecorPlaster(<String, double>{});
      assertCanonicalContract('decor_plaster', result);
    });

    test('decor_stone', () {
      final result = calculateCanonicalDecorStone(<String, double>{});
      assertCanonicalContract('decor_stone', result);
    });

    test('doors', () {
      final result = calculateCanonicalDoors(<String, double>{});
      assertCanonicalContract('doors', result);
    });

    test('drywall', () {
      final result = calculateCanonicalDrywall(<String, double>{});
      assertCanonicalContract('drywall', result);
    });

    test('drywall_ceiling', () {
      final result = calculateCanonicalDrywallCeiling(<String, double>{});
      assertCanonicalContract('drywall_ceiling', result);
    });

    test('electric', () {
      final result = calculateCanonicalElectric(<String, double>{});
      assertCanonicalContract('electric', result);
    });

    test('facade_brick', () {
      final result = calculateCanonicalFacadeBrick(<String, double>{});
      assertCanonicalContract('facade_brick', result);
    });

    test('facade_insulation', () {
      final result = calculateCanonicalFacadeInsulation(<String, double>{});
      assertCanonicalContract('facade_insulation', result);
    });

    test('facade_panels', () {
      final result = calculateCanonicalFacadePanels(<String, double>{});
      assertCanonicalContract('facade_panels', result);
    });

    test('fasteners', () {
      final result = calculateCanonicalFasteners(<String, double>{});
      assertCanonicalContract('fasteners', result);
    });

    test('fence', () {
      final result = calculateCanonicalFence(<String, double>{});
      assertCanonicalContract('fence', result);
    });

    test('foam_blocks', () {
      final result = calculateCanonicalFoamBlocks(<String, double>{});
      assertCanonicalContract('foam_blocks', result);
    });

    test('foundation_slab', () {
      final result = calculateCanonicalFoundationSlab(<String, double>{});
      assertCanonicalContract('foundation_slab', result);
    });

    test('frame_house', () {
      final result = calculateCanonicalFrameHouse(<String, double>{});
      assertCanonicalContract('frame_house', result);
    });

    test('gutters', () {
      final result = calculateCanonicalGutters(<String, double>{});
      assertCanonicalContract('gutters', result);
    });

    test('gypsum_board', () {
      final result = calculateCanonicalGypsumBoard(<String, double>{});
      assertCanonicalContract('gypsum_board', result);
    });

    test('heating', () {
      final result = calculateCanonicalHeating(<String, double>{});
      assertCanonicalContract('heating', result);
    });

    test('insulation', () {
      final result = calculateCanonicalInsulation(<String, double>{});
      assertCanonicalContract('insulation', result);
    });

    test('laminate', () {
      final result = calculateCanonicalLaminate(<String, double>{});
      assertCanonicalContract('laminate', result);
    });

    test('linoleum', () {
      final result = calculateCanonicalLinoleum(<String, double>{});
      assertCanonicalContract('linoleum', result);
    });

    test('mdf_panels', () {
      final result = calculateCanonicalMdfPanels(<String, double>{});
      assertCanonicalContract('mdf_panels', result);
    });

    test('paint', () {
      final result = calculateCanonicalPaint(<String, double>{});
      assertCanonicalContract('paint', result);
    });

    test('panels_3d', () {
      final result = calculateCanonicalPanels3d(<String, double>{});
      assertCanonicalContract('panels_3d', result);
    });

    test('parquet', () {
      final result = calculateCanonicalParquet(<String, double>{});
      assertCanonicalContract('parquet', result);
    });

    test('partitions', () {
      final result = calculateCanonicalPartitions(<String, double>{});
      assertCanonicalContract('partitions', result);
    });

    test('plaster', () {
      final result = calculateCanonicalPlaster(<String, double>{});
      assertCanonicalContract('plaster', result);
    });

    test('primer', () {
      final result = calculateCanonicalPrimer(<String, double>{});
      assertCanonicalContract('primer', result);
    });

    test('putty', () {
      final result = calculateCanonicalPutty(<String, double>{});
      assertCanonicalContract('putty', result);
    });

    test('pvc_panels', () {
      final result = calculateCanonicalPvcPanels(<String, double>{});
      assertCanonicalContract('pvc_panels', result);
    });

    test('rebar', () {
      final result = calculateCanonicalRebar(<String, double>{});
      assertCanonicalContract('rebar', result);
    });

    test('roofing', () {
      final result = calculateCanonicalRoofing(<String, double>{});
      assertCanonicalContract('roofing', result);
    });

    test('screed', () {
      final result = calculateCanonicalScreed(<String, double>{});
      assertCanonicalContract('screed', result);
    });

    test('self_leveling', () {
      final result = calculateCanonicalSelfLeveling(<String, double>{});
      assertCanonicalContract('self_leveling', result);
    });

    test('sewage', () {
      final result = calculateCanonicalSewage(<String, double>{});
      assertCanonicalContract('sewage', result);
    });

    test('siding', () {
      final result = calculateCanonicalSiding(<String, double>{});
      assertCanonicalContract('siding', result);
    });

    test('slopes', () {
      final result = calculateCanonicalSlopes(<String, double>{});
      assertCanonicalContract('slopes', result);
    });

    test('soft_roofing', () {
      final result = calculateCanonicalSoftRoofing(<String, double>{});
      assertCanonicalContract('soft_roofing', result);
    });

    test('sound_insulation', () {
      final result = calculateCanonicalSoundInsulation(<String, double>{});
      assertCanonicalContract('sound_insulation', result);
    });

    test('stairs', () {
      final result = calculateCanonicalStairs(<String, double>{});
      assertCanonicalContract('stairs', result);
    });

    test('strip_foundation', () {
      final result = calculateCanonicalStripFoundation(<String, double>{});
      assertCanonicalContract('strip_foundation', result);
    });

    test('terrace', () {
      final result = calculateCanonicalTerrace(<String, double>{});
      assertCanonicalContract('terrace', result);
    });

    test('tile', () {
      final result = calculateCanonicalTile(<String, double>{});
      assertCanonicalContract('tile', result);
    });

    test('tile_adhesive', () {
      final result = calculateCanonicalTileAdhesive(<String, double>{});
      assertCanonicalContract('tile_adhesive', result);
    });

    test('tile_grout', () {
      final result = calculateCanonicalTileGrout(<String, double>{});
      assertCanonicalContract('tile_grout', result);
    });

    test('ventilation', () {
      final result = calculateCanonicalVentilation(<String, double>{});
      assertCanonicalContract('ventilation', result);
    });

    test('wall_panels', () {
      final result = calculateCanonicalWallPanels(<String, double>{});
      assertCanonicalContract('wall_panels', result);
    });

    test('wallpaper', () {
      final result = calculateCanonicalWallpaper(<String, double>{});
      assertCanonicalContract('wallpaper', result);
    });

    test('warm_floor', () {
      final result = calculateCanonicalWarmFloor(<String, double>{});
      assertCanonicalContract('warm_floor', result);
    });

    test('warm_floor_pipes', () {
      final result = calculateCanonicalWarmFloorPipes(<String, double>{});
      assertCanonicalContract('warm_floor_pipes', result);
    });

    test('waterproofing', () {
      final result = calculateCanonicalWaterproofing(<String, double>{});
      assertCanonicalContract('waterproofing', result);
    });

    test('windows', () {
      final result = calculateCanonicalWindows(<String, double>{});
      assertCanonicalContract('windows', result);
    });

    test('wood_wall', () {
      final result = calculateCanonicalWoodWall(<String, double>{});
      assertCanonicalContract('wood_wall', result);
    });
  });
}
