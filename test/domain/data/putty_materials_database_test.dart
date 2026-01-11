import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/data/putty_materials_database.dart';

void main() {
  group('PuttyMaterial', () {
    test('создаёт материал с правильными значениями', () {
      const material = PuttyMaterial(
        id: 'test_id',
        brand: 'TestBrand',
        name: 'Test Material',
        purpose: PuttyPurpose.start,
        form: PuttyForm.dry,
        composition: PuttyComposition.gypsum,
        consumptionPerMm: 0.9,
        packageSize: 25,
        packageUnit: 'кг',
        maxLayerThickness: 15,
        minLayerThickness: 3,
        dryingTimeHours: 24,
        isWaterproof: false,
        recommendationKey: 'test.rec',
        popularity: 10,
      );

      expect(material.id, 'test_id');
      expect(material.brand, 'TestBrand');
      expect(material.name, 'Test Material');
    });

    test('fullName объединяет бренд и название', () {
      const material = PuttyMaterial(
        id: 'test',
        brand: 'Knauf',
        name: 'HP Start',
        purpose: PuttyPurpose.start,
        form: PuttyForm.dry,
        composition: PuttyComposition.gypsum,
        consumptionPerMm: 0.9,
        packageSize: 25,
        packageUnit: 'кг',
        maxLayerThickness: 15,
        minLayerThickness: 3,
        dryingTimeHours: 24,
        isWaterproof: false,
        recommendationKey: 'test.rec',
        popularity: 10,
      );

      expect(material.fullName, 'Knauf HP Start');
    });

    test('calculatePackages возвращает правильное количество', () {
      const material = PuttyMaterial(
        id: 'test',
        brand: 'Test',
        name: 'Material',
        purpose: PuttyPurpose.start,
        form: PuttyForm.dry,
        composition: PuttyComposition.gypsum,
        consumptionPerMm: 1.0,
        packageSize: 25,
        packageUnit: 'кг',
        maxLayerThickness: 15,
        minLayerThickness: 3,
        dryingTimeHours: 24,
        isWaterproof: false,
        recommendationKey: 'test.rec',
        popularity: 10,
      );

      final packages = material.calculatePackages(10, 5, 2);
      expect(packages, 4);
    });
  });

  group('PuttyMaterialsDatabase', () {
    test('allMaterials не пустой', () {
      expect(PuttyMaterialsDatabase.allMaterials, isNotEmpty);
    });

    test('все ID материалов уникальны', () {
      final allIds = PuttyMaterialsDatabase.allMaterials.map((m) => m.id).toList();
      final uniqueIds = allIds.toSet();
      expect(allIds.length, uniqueIds.length);
    });

    test('getById находит существующий материал', () {
      final material = PuttyMaterialsDatabase.getById('knauf_hp_start');
      expect(material, isNotNull);
      expect(material!.brand, 'Knauf');
    });

    test('getById возвращает null для несуществующего ID', () {
      final material = PuttyMaterialsDatabase.getById('nonexistent');
      expect(material, isNull);
    });

    test('allBrands содержит известные бренды', () {
      final brands = PuttyMaterialsDatabase.allBrands;
      expect(brands, contains('Knauf'));
      expect(brands, contains('Волма'));
    });
  });

  group('WallCondition', () {
    test('smooth multiplier равен 1.0', () {
      expect(WallCondition.smooth.multiplier, 1.0);
    });

    test('medium multiplier равен 1.5', () {
      expect(WallCondition.medium.multiplier, 1.5);
    });

    test('rough multiplier равен 2.0', () {
      expect(WallCondition.rough.multiplier, 2.0);
    });
  });

  group('RoomPresets', () {
    test('presets не пустой', () {
      expect(RoomPresets.presets, isNotEmpty);
    });

    test('все пресеты имеют положительные размеры', () {
      for (final preset in RoomPresets.presets) {
        expect(preset.length, greaterThan(0));
        expect(preset.width, greaterThan(0));
        expect(preset.height, greaterThan(0));
      }
    });
  });
}
