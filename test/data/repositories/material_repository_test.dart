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

      test('can create with empty properties map', () {
        const option = MaterialOption(
          id: 'test_id',
          name: 'Test Material',
          category: 'Test Category',
          pricePerUnit: 100,
          unit: 'm2',
          properties: {},
          durabilityYears: 10,
        );

        expect(option.properties, isEmpty);
      });

      test('supports various units', () {
        const units = ['m2', 'm3', 'kg', 'шт', 'л', 'упаковка', 'рулон', 'мешок'];

        for (final unit in units) {
          final option = MaterialOption(
            id: 'test',
            name: 'Test',
            category: 'Test',
            pricePerUnit: 100,
            unit: unit,
            properties: const {},
            durabilityYears: 10,
          );

          expect(option.unit, unit);
        }
      });

      test('supports different price ranges', () {
        const cheap = MaterialOption(
          id: 'cheap',
          name: 'Cheap',
          category: 'Economy',
          pricePerUnit: 50,
          unit: 'm2',
          properties: {},
          durabilityYears: 5,
        );

        const expensive = MaterialOption(
          id: 'expensive',
          name: 'Expensive',
          category: 'Premium',
          pricePerUnit: 5000,
          unit: 'm2',
          properties: {},
          durabilityYears: 25,
        );

        expect(cheap.pricePerUnit, lessThan(expensive.pricePerUnit));
        expect(cheap.durabilityYears, lessThan(expensive.durabilityYears));
      });

      test('properties map can contain multiple key-value pairs', () {
        const option = MaterialOption(
          id: 'test',
          name: 'Test',
          category: 'Test',
          pricePerUnit: 100,
          unit: 'm2',
          properties: {
            'тип': 'гипсовая',
            'толщина': '10 мм',
            'цвет': 'белый',
            'производитель': 'Test Brand',
          },
          durabilityYears: 10,
        );

        expect(option.properties.length, 4);
        expect(option.properties['тип'], 'гипсовая');
        expect(option.properties['толщина'], '10 мм');
        expect(option.properties['цвет'], 'белый');
        expect(option.properties['производитель'], 'Test Brand');
      });
    });

    group('default materials', () {
      test('default economy material has correct values', () async {
        final materials = await repository.getMaterialsForCalculator('unknown');

        final economy = materials.firstWhere((m) => m.id == 'default_economy');

        expect(economy.name, 'Эконом');
        expect(economy.category, 'Базовый');
        expect(economy.pricePerUnit, 450);
        expect(economy.unit, 'm2');
        expect(economy.durabilityYears, 5);
        expect(economy.properties['плотность'], '850 кг/м3');
      });

      test('default standard material has correct values', () async {
        final materials = await repository.getMaterialsForCalculator('unknown');

        final standard = materials.firstWhere((m) => m.id == 'default_standard');

        expect(standard.name, 'Стандарт');
        expect(standard.category, 'Средний');
        expect(standard.pricePerUnit, 750);
        expect(standard.unit, 'm2');
        expect(standard.durabilityYears, 10);
        expect(standard.properties['плотность'], '920 кг/м3');
      });

      test('default premium material has correct values', () async {
        final materials = await repository.getMaterialsForCalculator('unknown');

        final premium = materials.firstWhere((m) => m.id == 'default_premium');

        expect(premium.name, 'Премиум');
        expect(premium.category, 'Высокий');
        expect(premium.pricePerUnit, 1200);
        expect(premium.unit, 'm2');
        expect(premium.durabilityYears, 18);
        expect(premium.properties['плотность'], '980 кг/м3');
      });

      test('default materials are sorted by price', () async {
        final materials = await repository.getMaterialsForCalculator('unknown');

        final defaults = materials.where((m) => m.id.startsWith('default_')).toList();

        for (int i = 0; i < defaults.length - 1; i++) {
          expect(
            defaults[i].pricePerUnit,
            lessThan(defaults[i + 1].pricePerUnit),
          );
        }
      });
    });

    group('calculator-specific materials', () {
      test('plaster materials have unique properties', () async {
        final materials = await repository.getMaterialsForCalculator('plaster');

        for (final material in materials) {
          expect(material.properties.containsKey('тип'), true);
          expect(material.properties.containsKey('рекомендованная толщина'), true);
        }
      });

      test('tile materials have wear resistance properties', () async {
        final materials = await repository.getMaterialsForCalculator('tile');

        for (final material in materials) {
          expect(material.properties.containsKey('износостойкость'), true);
          expect(material.properties['износостойкость'], contains('PEI'));
        }
      });

      test('all plaster materials use kg unit', () async {
        final materials = await repository.getMaterialsForCalculator('plaster');

        for (final material in materials) {
          expect(material.unit, 'kg');
        }
      });

      test('all tile materials use m2 unit', () async {
        final materials = await repository.getMaterialsForCalculator('tile');

        for (final material in materials) {
          expect(material.unit, 'm2');
        }
      });
    });

    group('edge cases', () {
      test('handles empty calculator id', () async {
        final materials = await repository.getMaterialsForCalculator('');

        expect(materials, isNotEmpty);
        expect(materials.length, 3); // Default materials
      });

      test('handles null-like calculator id', () async {
        final materials = await repository.getMaterialsForCalculator('null');

        expect(materials, isNotEmpty);
        expect(materials.length, 3); // Default materials
      });

      test('getAllMaterials does not return duplicates', () async {
        final materials = await repository.getAllMaterials();

        final ids = materials.map((m) => m.id).toList();
        final uniqueIds = ids.toSet();

        expect(ids.length, equals(uniqueIds.length));
      });

      test('getAllMaterials includes all calculator-specific materials', () async {
        final allMaterials = await repository.getAllMaterials();
        final plasterMaterials = await repository.getMaterialsForCalculator('plaster');
        final tileMaterials = await repository.getMaterialsForCalculator('tile');

        for (final material in plasterMaterials) {
          expect(
            allMaterials.any((m) => m.id == material.id),
            true,
            reason: 'Plaster material ${material.id} should be in all materials',
          );
        }

        for (final material in tileMaterials) {
          expect(
            allMaterials.any((m) => m.id == material.id),
            true,
            reason: 'Tile material ${material.id} should be in all materials',
          );
        }
      });
    });

    group('performance', () {
      test('getMaterialsForCalculator completes within reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        await repository.getMaterialsForCalculator('plaster');

        stopwatch.stop();

        // Should complete within 500ms (includes 250ms artificial delay)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('getAllMaterials completes within reasonable time', () async {
        final stopwatch = Stopwatch()..start();

        await repository.getAllMaterials();

        stopwatch.stop();

        // Should complete within 500ms (includes 250ms artificial delay)
        expect(stopwatch.elapsedMilliseconds, lessThan(500));
      });

      test('multiple calls complete independently', () async {
        final future1 = repository.getMaterialsForCalculator('plaster');
        final future2 = repository.getMaterialsForCalculator('tile');
        final future3 = repository.getAllMaterials();

        final results = await Future.wait([future1, future2, future3]);

        expect(results[0], isNotEmpty); // plaster
        expect(results[1], isNotEmpty); // tile
        expect(results[2], isNotEmpty); // all
      });
    });

    group('material quality tiers', () {
      test('economy materials are cheapest with lowest durability', () async {
        final materials = await repository.getMaterialsForCalculator('unknown');

        final economy = materials.firstWhere((m) => m.category == 'Базовый');
        final standard = materials.firstWhere((m) => m.category == 'Средний');
        final premium = materials.firstWhere((m) => m.category == 'Высокий');

        expect(economy.pricePerUnit, lessThan(standard.pricePerUnit));
        expect(standard.pricePerUnit, lessThan(premium.pricePerUnit));

        expect(economy.durabilityYears, lessThan(standard.durabilityYears));
        expect(standard.durabilityYears, lessThan(premium.durabilityYears));
      });

      test('plaster materials have price-quality correlation', () async {
        final materials = await repository.getMaterialsForCalculator('plaster');

        for (int i = 0; i < materials.length - 1; i++) {
          if (materials[i].pricePerUnit < materials[i + 1].pricePerUnit) {
            expect(
              materials[i].durabilityYears,
              lessThanOrEqualTo(materials[i + 1].durabilityYears),
            );
          }
        }
      });

      test('tile materials have different wear resistance levels', () async {
        final materials = await repository.getMaterialsForCalculator('tile');

        final wallTile = materials.firstWhere((m) => m.id == 'tile_wall');
        final floorTile = materials.firstWhere((m) => m.id == 'tile_floor');

        expect(wallTile.properties['износостойкость'], 'PEI III');
        expect(floorTile.properties['износостойкость'], 'PEI IV');
        expect(floorTile.pricePerUnit, greaterThan(wallTile.pricePerUnit));
      });
    });
  });
}
