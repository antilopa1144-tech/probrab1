import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/calculator_category.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/data/models/price_item.dart';

class _MockUseCase implements CalculatorUseCase {
  @override
  CalculatorResult call(Map<String, double> inputs, List<PriceItem> priceList) {
    return const CalculatorResult(values: {});
  }
}

void main() {
  group('CalculatorScreenRegistry', () {
    test('has screens for key calculators', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_plaster'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_putty'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_tile'), isTrue);
    });

    test('hasCustomScreen returns false for nonexistent ID', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('nonexistent'), isFalse);
    });

    test('supports more than 50 calculators', () {
      final registeredIds = [
        'mixes_plaster', 'mixes_putty', 'mixes_primer', 'mixes_tile_glue',
        'dsp', 'sheeting_osb_plywood', 'gypsum_board',
        'paint_universal', 'paint', 'wood',
        'walls_wallpaper', 'walls_3d_panels', 'walls_wood',
        'walls_decor_plaster', 'walls_decor_stone', 'walls_mdf_panels', 'walls_pvc_panels',
        'partitions_blocks', 'partitions_brick', 'exterior_brick',
        'floors_tile', 'floors_self_leveling', 'floors_laminate',
        'floors_linoleum', 'floors_parquet', 'floors_screed', 'floors_warm',
        'ceilings_stretch', 'ceilings_insulation', 'ceilings_cassette', 'ceilings_rail',
        'engineering_heating', 'engineering_electrics', 'engineering_plumbing', 'engineering_ventilation',
        'terrace', 'attic', 'balcony', 'bathroom_waterproof',
        'doors_install', 'windows_install', 'slopes_finishing',
        'insulation_sound',
        'exterior_facade_panels', 'fence', 'stairs',
        'foundation_basement', 'foundation_blind_area', 'foundation_slab',
        'roofing_gutters',
      ];

      expect(registeredIds.length, greaterThanOrEqualTo(50));

      for (final id in registeredIds) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Calculator $id should be registered');
      }
    });

    test('build returns null for nonexistent ID', () {
      final definition = CalculatorDefinitionV2(
        id: 'nonexistent',
        titleKey: 'test.title',
        category: CalculatorCategory.interior,
        subCategoryKey: 'test.sub',
        fields: [],
        useCase: _MockUseCase(),
      );

      final screen = CalculatorScreenRegistry.build(
        'nonexistent',
        definition,
        null,
      );

      expect(screen, isNull);
    });

    test('buildWithFallback always returns a screen', () {
      final definition = CalculatorDefinitionV2(
        id: 'nonexistent',
        titleKey: 'test.title',
        category: CalculatorCategory.interior,
        subCategoryKey: 'test.sub',
        fields: [],
        useCase: _MockUseCase(),
      );

      final screen = CalculatorScreenRegistry.buildWithFallback(
        definition,
        null,
      );

      expect(screen, isNotNull);
    });
  });
}
