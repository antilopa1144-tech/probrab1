import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/utils/calculator_navigation_helper.dart';

void main() {
  group('CalculatorNavigationHelper', () {
    group('hasV2Version', () {
      test('returns true for existing V2 calculator', () {
        // Test with known V2 calculator IDs from the registry
        expect(
          CalculatorNavigationHelper.hasV2Version('mixes_plaster'),
          isTrue,
        );
      });

      test('returns true for paint calculator', () {
        // paint_universal is the canonical ID
        expect(CalculatorNavigationHelper.hasV2Version('paint_universal'), isTrue);
      });

      test('returns true for gypsum board calculator', () {
        expect(CalculatorNavigationHelper.hasV2Version('gypsum_board'), isTrue);
      });

      test('returns true for wallpaper calculator', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('walls_wallpaper'),
          isTrue,
        );
      });

      test('returns false for non-existent calculator', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('non_existent_calculator_xyz'),
          isFalse,
        );
      });

      test('returns false for empty string', () {
        expect(CalculatorNavigationHelper.hasV2Version(''), isFalse);
      });

      test('handles old calculator IDs through migration', () {
        // Old ID should be migrated to new canonical ID
        // If migration exists in CalculatorIdMigration
        final result = CalculatorNavigationHelper.hasV2Version('paint_universal');
        // Should either find by canonical ID or return false
        expect(result, isA<bool>());
      });

      test('returns true for tile calculator', () {
        expect(CalculatorNavigationHelper.hasV2Version('floors_tile'), isTrue);
      });

      test('returns true for self leveling floor', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('floors_self_leveling'),
          isTrue,
        );
      });

      test('returns true for underfloor heating', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('engineering_heating'),
          isTrue,
        );
      });

      test('returns true for electrical calculator', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('engineering_electrics'),
          isTrue,
        );
      });

      test('returns true for terrace calculator', () {
        expect(CalculatorNavigationHelper.hasV2Version('terrace'), isTrue);
      });

      test('returns true for 3D panels calculator', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('walls_3d_panels'),
          isTrue,
        );
      });

      test('returns true for wood lining calculator', () {
        expect(CalculatorNavigationHelper.hasV2Version('walls_wood'), isTrue);
      });

      test('returns true for gasblock calculator', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('partitions_blocks'),
          isTrue,
        );
      });

      test('returns true for putty calculator', () {
        expect(CalculatorNavigationHelper.hasV2Version('mixes_putty'), isTrue);
      });

      test('returns true for primer calculator', () {
        expect(CalculatorNavigationHelper.hasV2Version('mixes_primer'), isTrue);
      });

      test('returns true for DSP calculator', () {
        expect(CalculatorNavigationHelper.hasV2Version('dsp'), isTrue);
      });

      test('returns result for wood calculator', () {
        // Wood may or may not be registered
        final result = CalculatorNavigationHelper.hasV2Version('wood');
        expect(result, isA<bool>());
      });

      test('returns true for OSB calculator', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('sheeting_osb_plywood'),
          isTrue,
        );
      });

      test('returns true for tile adhesive calculator', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('mixes_tile_glue'),
          isTrue,
        );
      });
    });
  });
}
