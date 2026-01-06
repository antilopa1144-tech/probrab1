import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/material_type.dart';

void main() {
  group('MaterialType', () {
    test('has all expected values', () {
      expect(MaterialType.values, contains(MaterialType.concrete));
      expect(MaterialType.values, contains(MaterialType.brick));
      expect(MaterialType.values, contains(MaterialType.gasBlock));
      expect(MaterialType.values, contains(MaterialType.wood));
      expect(MaterialType.values, contains(MaterialType.metal));
      expect(MaterialType.values, contains(MaterialType.drywall));
      expect(MaterialType.values, contains(MaterialType.gvl));
      expect(MaterialType.values, contains(MaterialType.insulation));
      expect(MaterialType.values, contains(MaterialType.paint));
      expect(MaterialType.values, contains(MaterialType.wallpaper));
      expect(MaterialType.values, contains(MaterialType.ceramicTile));
      expect(MaterialType.values, contains(MaterialType.laminate));
      expect(MaterialType.values, contains(MaterialType.parquet));
      expect(MaterialType.values, contains(MaterialType.linoleum));
      expect(MaterialType.values, contains(MaterialType.carpet));
      expect(MaterialType.values, contains(MaterialType.plaster));
      expect(MaterialType.values, contains(MaterialType.putty));
      expect(MaterialType.values, contains(MaterialType.primer));
      expect(MaterialType.values, contains(MaterialType.glue));
      expect(MaterialType.values, contains(MaterialType.cement));
      expect(MaterialType.values, contains(MaterialType.sand));
      expect(MaterialType.values, contains(MaterialType.gravel));
      expect(MaterialType.values, contains(MaterialType.rebar));
      expect(MaterialType.values, contains(MaterialType.metalProfile));
      expect(MaterialType.values, contains(MaterialType.siding));
      expect(MaterialType.values, contains(MaterialType.roofingMaterial));
      expect(MaterialType.values, contains(MaterialType.waterproofing));
      expect(MaterialType.values, contains(MaterialType.thermalInsulation));
      expect(MaterialType.values, contains(MaterialType.soundInsulation));
      expect(MaterialType.values, contains(MaterialType.wiring));
      expect(MaterialType.values, contains(MaterialType.pipes));
      expect(MaterialType.values, contains(MaterialType.other));
    });

    test('has exactly 32 values', () {
      expect(MaterialType.values.length, 32);
    });

    group('translationKey', () {
      test('concrete returns correct key', () {
        expect(MaterialType.concrete.translationKey, 'material.concrete');
      });

      test('brick returns correct key', () {
        expect(MaterialType.brick.translationKey, 'material.brick');
      });

      test('gasBlock returns correct key', () {
        expect(MaterialType.gasBlock.translationKey, 'material.gas_block');
      });

      test('wood returns correct key', () {
        expect(MaterialType.wood.translationKey, 'material.wood');
      });

      test('metal returns correct key', () {
        expect(MaterialType.metal.translationKey, 'material.metal');
      });

      test('drywall returns correct key', () {
        expect(MaterialType.drywall.translationKey, 'material.drywall');
      });

      test('gvl returns correct key', () {
        expect(MaterialType.gvl.translationKey, 'material.gvl');
      });

      test('insulation returns correct key', () {
        expect(MaterialType.insulation.translationKey, 'material.insulation');
      });

      test('paint returns correct key', () {
        expect(MaterialType.paint.translationKey, 'material.paint');
      });

      test('wallpaper returns correct key', () {
        expect(MaterialType.wallpaper.translationKey, 'material.wallpaper');
      });

      test('ceramicTile returns correct key', () {
        expect(MaterialType.ceramicTile.translationKey, 'material.ceramic_tile');
      });

      test('laminate returns correct key', () {
        expect(MaterialType.laminate.translationKey, 'material.laminate');
      });

      test('parquet returns correct key', () {
        expect(MaterialType.parquet.translationKey, 'material.parquet');
      });

      test('linoleum returns correct key', () {
        expect(MaterialType.linoleum.translationKey, 'material.linoleum');
      });

      test('carpet returns correct key', () {
        expect(MaterialType.carpet.translationKey, 'material.carpet');
      });

      test('plaster returns correct key', () {
        expect(MaterialType.plaster.translationKey, 'material.plaster');
      });

      test('putty returns correct key', () {
        expect(MaterialType.putty.translationKey, 'material.putty');
      });

      test('primer returns correct key', () {
        expect(MaterialType.primer.translationKey, 'material.primer');
      });

      test('glue returns correct key', () {
        expect(MaterialType.glue.translationKey, 'material.glue');
      });

      test('cement returns correct key', () {
        expect(MaterialType.cement.translationKey, 'material.cement');
      });

      test('sand returns correct key', () {
        expect(MaterialType.sand.translationKey, 'material.sand');
      });

      test('gravel returns correct key', () {
        expect(MaterialType.gravel.translationKey, 'material.gravel');
      });

      test('rebar returns correct key', () {
        expect(MaterialType.rebar.translationKey, 'material.rebar');
      });

      test('metalProfile returns correct key', () {
        expect(MaterialType.metalProfile.translationKey, 'material.metal_profile');
      });

      test('siding returns correct key', () {
        expect(MaterialType.siding.translationKey, 'material.siding');
      });

      test('roofingMaterial returns correct key', () {
        expect(
          MaterialType.roofingMaterial.translationKey,
          'material.roofing_material',
        );
      });

      test('waterproofing returns correct key', () {
        expect(
          MaterialType.waterproofing.translationKey,
          'material.waterproofing',
        );
      });

      test('thermalInsulation returns correct key', () {
        expect(
          MaterialType.thermalInsulation.translationKey,
          'material.thermal_insulation',
        );
      });

      test('soundInsulation returns correct key', () {
        expect(
          MaterialType.soundInsulation.translationKey,
          'material.sound_insulation',
        );
      });

      test('wiring returns correct key', () {
        expect(MaterialType.wiring.translationKey, 'material.wiring');
      });

      test('pipes returns correct key', () {
        expect(MaterialType.pipes.translationKey, 'material.pipes');
      });

      test('other returns correct key', () {
        expect(MaterialType.other.translationKey, 'material.other');
      });

      test('all values have non-empty translationKey', () {
        for (final type in MaterialType.values) {
          expect(type.translationKey, isNotEmpty);
          expect(type.translationKey, startsWith('material.'));
        }
      });
    });
  });
}
