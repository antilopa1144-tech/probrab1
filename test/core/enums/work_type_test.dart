import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/work_type.dart';

void main() {
  group('WorkType', () {
    test('has all expected values', () {
      expect(WorkType.values, contains(WorkType.foundation));
      expect(WorkType.values, contains(WorkType.walls));
      expect(WorkType.values, contains(WorkType.roofing));
      expect(WorkType.values, contains(WorkType.facade));
      expect(WorkType.values, contains(WorkType.insulation));
      expect(WorkType.values, contains(WorkType.roughFlooring));
      expect(WorkType.values, contains(WorkType.finishFlooring));
      expect(WorkType.values, contains(WorkType.roughCeiling));
      expect(WorkType.values, contains(WorkType.finishCeiling));
      expect(WorkType.values, contains(WorkType.plastering));
      expect(WorkType.values, contains(WorkType.puttying));
      expect(WorkType.values, contains(WorkType.priming));
      expect(WorkType.values, contains(WorkType.painting));
      expect(WorkType.values, contains(WorkType.wallpapering));
      expect(WorkType.values, contains(WorkType.tiling));
      expect(WorkType.values, contains(WorkType.waterproofing));
      expect(WorkType.values, contains(WorkType.electrical));
      expect(WorkType.values, contains(WorkType.plumbing));
      expect(WorkType.values, contains(WorkType.heating));
      expect(WorkType.values, contains(WorkType.ventilation));
      expect(WorkType.values, contains(WorkType.windows));
      expect(WorkType.values, contains(WorkType.doors));
      expect(WorkType.values, contains(WorkType.other));
    });

    test('has exactly 23 values', () {
      expect(WorkType.values.length, 23);
    });

    group('translationKey', () {
      test('foundation returns correct key', () {
        expect(WorkType.foundation.translationKey, 'work_type.foundation');
      });

      test('walls returns correct key', () {
        expect(WorkType.walls.translationKey, 'work_type.walls');
      });

      test('roofing returns correct key', () {
        expect(WorkType.roofing.translationKey, 'work_type.roofing');
      });

      test('facade returns correct key', () {
        expect(WorkType.facade.translationKey, 'work_type.facade');
      });

      test('insulation returns correct key', () {
        expect(WorkType.insulation.translationKey, 'work_type.insulation');
      });

      test('roughFlooring returns correct key', () {
        expect(WorkType.roughFlooring.translationKey, 'work_type.rough_flooring');
      });

      test('finishFlooring returns correct key', () {
        expect(WorkType.finishFlooring.translationKey, 'work_type.finish_flooring');
      });

      test('roughCeiling returns correct key', () {
        expect(WorkType.roughCeiling.translationKey, 'work_type.rough_ceiling');
      });

      test('finishCeiling returns correct key', () {
        expect(WorkType.finishCeiling.translationKey, 'work_type.finish_ceiling');
      });

      test('plastering returns correct key', () {
        expect(WorkType.plastering.translationKey, 'work_type.plastering');
      });

      test('puttying returns correct key', () {
        expect(WorkType.puttying.translationKey, 'work_type.puttying');
      });

      test('priming returns correct key', () {
        expect(WorkType.priming.translationKey, 'work_type.priming');
      });

      test('painting returns correct key', () {
        expect(WorkType.painting.translationKey, 'work_type.painting');
      });

      test('wallpapering returns correct key', () {
        expect(WorkType.wallpapering.translationKey, 'work_type.wallpapering');
      });

      test('tiling returns correct key', () {
        expect(WorkType.tiling.translationKey, 'work_type.tiling');
      });

      test('waterproofing returns correct key', () {
        expect(WorkType.waterproofing.translationKey, 'work_type.waterproofing');
      });

      test('electrical returns correct key', () {
        expect(WorkType.electrical.translationKey, 'work_type.electrical');
      });

      test('plumbing returns correct key', () {
        expect(WorkType.plumbing.translationKey, 'work_type.plumbing');
      });

      test('heating returns correct key', () {
        expect(WorkType.heating.translationKey, 'work_type.heating');
      });

      test('ventilation returns correct key', () {
        expect(WorkType.ventilation.translationKey, 'work_type.ventilation');
      });

      test('windows returns correct key', () {
        expect(WorkType.windows.translationKey, 'work_type.windows');
      });

      test('doors returns correct key', () {
        expect(WorkType.doors.translationKey, 'work_type.doors');
      });

      test('other returns correct key', () {
        expect(WorkType.other.translationKey, 'work_type.other');
      });

      test('all values have non-empty translationKey', () {
        for (final type in WorkType.values) {
          expect(type.translationKey, isNotEmpty);
          expect(type.translationKey, startsWith('work_type.'));
        }
      });
    });
  });
}
