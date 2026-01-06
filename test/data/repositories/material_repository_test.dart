import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/repositories/material_repository.dart';
import 'package:probrab_ai/domain/entities/material_comparison.dart';

void main() {
  group('MaterialRepository', () {
    late MaterialRepository repository;

    setUp(() {
      repository = MaterialRepository();
    });

    group('getAllMaterials', () {
      test('returns list of MaterialOptions', () async {
        final materials = await repository.getAllMaterials();

        expect(materials, isA<List<MaterialOption>>());
        expect(materials, isNotEmpty);
      });

      test('includes default options', () async {
        final materials = await repository.getAllMaterials();

        // Check for default options
        final names = materials.map((m) => m.name).toList();
        expect(names, contains('Эконом'));
        expect(names, contains('Стандарт'));
        expect(names, contains('Премиум'));
      });

      test('includes calculator-specific materials', () async {
        final materials = await repository.getAllMaterials();

        // Check that we have more materials than just defaults
        expect(materials.length, greaterThan(3));

        // Check for plaster materials by id instead of name
        final ids = materials.map((m) => m.id).toList();
        expect(ids, contains('plaster_basic'));
        expect(ids, contains('plaster_pro'));
      });

      test('all materials have required fields', () async {
        final materials = await repository.getAllMaterials();

        for (final material in materials) {
          expect(material.id, isNotEmpty);
          expect(material.name, isNotEmpty);
          expect(material.category, isNotEmpty);
          expect(material.pricePerUnit, greaterThan(0));
          expect(material.unit, isNotEmpty);
          expect(material.durabilityYears, greaterThan(0));
        }
      });
    });

    group('getMaterialsForCalculator', () {
      test('returns plaster materials for plaster calculator', () async {
        final materials = await repository.getMaterialsForCalculator('plaster');

        expect(materials, isNotEmpty);
        expect(materials.length, 2);

        final names = materials.map((m) => m.name).toList();
        expect(names, contains('Штукатурка базовая'));
        expect(names, contains('Штукатурка про'));
      });

      test('returns tile materials for tile calculator', () async {
        final materials = await repository.getMaterialsForCalculator('tile');

        expect(materials, isNotEmpty);
        expect(materials.length, 2);

        final names = materials.map((m) => m.name).toList();
        expect(names, contains('Плитка настенная'));
        expect(names, contains('Плитка напольная'));
      });

      test('returns default options for unknown calculator', () async {
        final materials = await repository.getMaterialsForCalculator('unknown');

        expect(materials, isNotEmpty);
        expect(materials.length, 3);

        final names = materials.map((m) => m.name).toList();
        expect(names, contains('Эконом'));
        expect(names, contains('Стандарт'));
        expect(names, contains('Премиум'));
      });

      test('plaster materials have correct properties', () async {
        final materials = await repository.getMaterialsForCalculator('plaster');

        final basicPlaster = materials.firstWhere(
          (m) => m.id == 'plaster_basic',
        );

        expect(basicPlaster.pricePerUnit, 520);
        expect(basicPlaster.unit, 'kg');
        expect(basicPlaster.durabilityYears, 7);
        expect(basicPlaster.properties['тип'], 'гипсовая');
      });

      test('tile materials have correct properties', () async {
        final materials = await repository.getMaterialsForCalculator('tile');

        final floorTile = materials.firstWhere(
          (m) => m.id == 'tile_floor',
        );

        expect(floorTile.pricePerUnit, 1450);
        expect(floorTile.unit, 'm2');
        expect(floorTile.durabilityYears, 20);
        expect(floorTile.properties['износостойкость'], 'PEI IV');
      });
    });

    group('MaterialOption', () {
      test('const constructor works correctly', () {
        const option = MaterialOption(
          id: 'test_id',
          name: 'Test Material',
          category: 'Test Category',
          pricePerUnit: 100,
          unit: 'm2',
          properties: {'key': 'value'},
          durabilityYears: 10,
        );

        expect(option.id, 'test_id');
        expect(option.name, 'Test Material');
        expect(option.category, 'Test Category');
        expect(option.pricePerUnit, 100);
        expect(option.unit, 'm2');
        expect(option.properties['key'], 'value');
        expect(option.durabilityYears, 10);
      });
    });
  });
}
