/// Universal edge-case tests for ALL Flutter canonical adapters.
///
/// Tests every adapter with:
/// 1. Empty inputs — no crash
/// 2. All-zero inputs — no NaN/Infinity
/// 3. Very large inputs — no crash
/// 4. MIN <= REC <= MAX
/// 5. Accuracy mode: basic <= realistic <= professional

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
import 'package:probrab_ai/domain/usecases/facade_brick_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/facade_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/fasteners_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/fence_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/foam_blocks_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/frame_house_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/gutters_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/gypsum_board_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/insulation_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/mdf_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/panels_3d_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/partitions_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/plaster_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/pvc_panels_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/roofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/screed_canonical_adapter.dart';
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
import 'package:probrab_ai/domain/usecases/warm_floor_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/warm_floor_pipes_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/waterproofing_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/windows_canonical_adapter.dart';
import 'package:probrab_ai/domain/usecases/wood_wall_canonical_adapter.dart';

import 'package:probrab_ai/domain/models/canonical_calculator_contract.dart';

typedef CalcFn = CanonicalCalculatorContractResult Function(Map<String, double>);

// These adapters have spec_reader issues with nested material_rules Maps
// and crash on empty/zero inputs. Tracked as known bugs.
const _knownBrokenAdapters = <String>{};

final Map<String, CalcFn> _adapters = {
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
  'drywall': calculateCanonicalDrywall,
  'drywall_ceiling': calculateCanonicalDrywallCeiling,
  'facade_brick': calculateCanonicalFacadeBrick,
  'facade_insulation': calculateCanonicalFacadeInsulation,
  'facade_panels': calculateCanonicalFacadePanels,
  'fasteners': calculateCanonicalFasteners,
  'fence': calculateCanonicalFence,
  'foam_blocks': calculateCanonicalFoamBlocks,
  'frame_house': calculateCanonicalFrameHouse,
  'gutters': calculateCanonicalGutters,
  'gypsum_board': calculateCanonicalGypsumBoard,
  'insulation': calculateCanonicalInsulation,
  'mdf_panels': calculateCanonicalMdfPanels,
  'panels_3d': calculateCanonicalPanels3d,
  'partitions': calculateCanonicalPartitions,
  'plaster': calculateCanonicalPlaster,
  'pvc_panels': calculateCanonicalPvcPanels,
  'roofing': calculateCanonicalRoofing,
  'screed': calculateCanonicalScreed,
  'self_leveling': calculateCanonicalSelfLeveling,
  'siding': calculateCanonicalSiding,
  'slopes': calculateCanonicalSlopes,
  'soft_roofing': calculateCanonicalSoftRoofing,
  'sound_insulation': calculateCanonicalSoundInsulation,
  'strip_foundation': calculateCanonicalStripFoundation,
  'terrace': calculateCanonicalTerrace,
  'tile': calculateCanonicalTile,
  'tile_adhesive': calculateCanonicalTileAdhesive,
  'tile_grout': calculateCanonicalTileGrout,
  'ventilation': calculateCanonicalVentilation,
  'wall_panels': calculateCanonicalWallPanels,
  'warm_floor': calculateCanonicalWarmFloor,
  'warm_floor_pipes': calculateCanonicalWarmFloorPipes,
  'waterproofing': calculateCanonicalWaterproofing,
  'windows': calculateCanonicalWindows,
  'wood_wall': calculateCanonicalWoodWall,
};

void _assertValidResult(CanonicalCalculatorContractResult r, String label) {
  expect(r.scenarios.containsKey('MIN'), isTrue, reason: '$label: has MIN');
  expect(r.scenarios.containsKey('REC'), isTrue, reason: '$label: has REC');
  expect(r.scenarios.containsKey('MAX'), isTrue, reason: '$label: has MAX');

  for (final key in ['MIN', 'REC', 'MAX']) {
    final s = r.scenarios[key]!;
    expect(s.exactNeed.isFinite, isTrue, reason: '$label: $key.exactNeed finite');
    expect(s.purchaseQuantity.isFinite, isTrue, reason: '$label: $key.purchaseQuantity finite');
    expect(s.leftover.isFinite, isTrue, reason: '$label: $key.leftover finite');
  }

  for (final m in r.materials) {
    expect(m.quantity.isFinite, isTrue, reason: '$label: material ${m.name} quantity finite');
    if (m.purchaseQty != null) {
      expect(m.purchaseQty!.isFinite, isTrue, reason: '$label: material ${m.name} purchaseQty finite');
      expect(m.purchaseQty! >= 0, isTrue, reason: '$label: material ${m.name} purchaseQty >= 0');
    }
  }
}

void main() {
  final testedAdapters = Map.fromEntries(
    _adapters.entries.where((e) => !_knownBrokenAdapters.contains(e.key)),
  );

  group('Universal edge-cases: ${testedAdapters.length} adapters (${_knownBrokenAdapters.length} skipped)', () {
    // 1. Empty inputs
    group('Empty inputs — no crash', () {
      for (final e in testedAdapters.entries) {
        test(e.key, () {
          final r = e.value({'accuracyMode': 0});
          _assertValidResult(r, '${e.key}/empty');
        });
      }
    });

    // 2. All-zero inputs
    group('All-zero inputs — no NaN/Infinity', () {
      for (final e in testedAdapters.entries) {
        test(e.key, () {
          final r = e.value({'area': 0, 'length': 0, 'width': 0, 'height': 0, 'thickness': 0, 'accuracyMode': 0});
          _assertValidResult(r, '${e.key}/zeros');
        });
      }
    });

    // 3. Very large inputs
    group('Large inputs — no crash', () {
      for (final e in testedAdapters.entries) {
        test(e.key, () {
          final r = e.value({'area': 9999, 'length': 999, 'width': 999, 'height': 10, 'thickness': 999, 'accuracyMode': 0});
          _assertValidResult(r, '${e.key}/large');
        });
      }
    });

    // 4. MIN <= REC <= MAX
    group('MIN <= REC <= MAX (exact_need)', () {
      for (final e in testedAdapters.entries) {
        test(e.key, () {
          final r = e.value({'accuracyMode': 0});
          expect(r.scenarios['MIN']!.exactNeed, lessThanOrEqualTo(r.scenarios['REC']!.exactNeed + 0.001),
              reason: '${e.key}: MIN <= REC');
          expect(r.scenarios['REC']!.exactNeed, lessThanOrEqualTo(r.scenarios['MAX']!.exactNeed + 0.001),
              reason: '${e.key}: REC <= MAX');
        });
      }
    });

    // 5. Accuracy: basic <= realistic <= professional
    group('Accuracy: basic <= realistic <= professional', () {
      for (final e in testedAdapters.entries) {
        test(e.key, () {
          final basic = e.value({'accuracyMode': 0});
          final realistic = e.value({'accuracyMode': 1});
          final professional = e.value({'accuracyMode': 2});

          expect(basic.scenarios['REC']!.exactNeed,
              lessThanOrEqualTo(realistic.scenarios['REC']!.exactNeed + 0.01),
              reason: '${e.key}: basic <= realistic');
          expect(realistic.scenarios['REC']!.exactNeed,
              lessThanOrEqualTo(professional.scenarios['REC']!.exactNeed + 0.01),
              reason: '${e.key}: realistic <= professional');
        });
      }
    });
  });
}
