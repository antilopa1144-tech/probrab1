import os

# Test 1: calculator_screen_registry_test.dart
registry_test = '''import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';

void main() {
  group('CalculatorScreenRegistry', () {
    test('\u0438\u043c\u0435\u0435\u0442 \u044d\u043a\u0440\u0430\u043d\u044b \u0434\u043b\u044f \u0432\u0441\u0435\u0445 \u043a\u0430\u0442\u0435\u0433\u043e\u0440\u0438\u0439', () {
      // \u041f\u0440\u043e\u0432\u0435\u0440\u044f\u0435\u043c \u043d\u0430\u043b\u0438\u0447\u0438\u0435 \u043a\u043b\u044e\u0447\u0435\u0432\u044b\u0445 \u043a\u0430\u043b\u044c\u043a\u0443\u043b\u044f\u0442\u043e\u0440\u043e\u0432
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_plaster'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_putty'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_primer'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_tile_glue'), isTrue);
    });

    test('hasCustomScreen \u0432\u043e\u0437\u0432\u0440\u0430\u0449\u0430\u0435\u0442 false \u0434\u043b\u044f \u043d\u0435\u0441\u0443\u0449\u0435\u0441\u0442\u0432\u0443\u044e\u0449\u0435\u0433\u043e ID', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('nonexistent'), isFalse);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u043b\u0438\u0441\u0442\u043e\u0432\u044b\u0435 \u043c\u0430\u0442\u0435\u0440\u0438\u0430\u043b\u044b', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('dsp'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('sheeting_osb_plywood'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('gypsum_board'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u043a\u0440\u0430\u0441\u043a\u0443 \u0438 \u0434\u0435\u0440\u0435\u0432\u043e', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('paint_universal'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('paint'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('wood'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u043a\u0430\u043b\u044c\u043a\u0443\u043b\u044f\u0442\u043e\u0440\u044b \u0441\u0442\u0435\u043d', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('walls_wallpaper'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('walls_3d_panels'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('walls_wood'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('walls_decor_plaster'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('walls_decor_stone'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('walls_mdf_panels'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('walls_pvc_panels'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u043a\u0430\u043b\u044c\u043a\u0443\u043b\u044f\u0442\u043e\u0440\u044b \u043f\u0435\u0440\u0435\u0433\u043e\u0440\u043e\u0434\u043e\u043a', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('partitions_blocks'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('partitions_brick'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('exterior_brick'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u043a\u0430\u043b\u044c\u043a\u0443\u043b\u044f\u0442\u043e\u0440\u044b \u043f\u043e\u043b\u043e\u0432', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_tile'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_self_leveling'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_laminate'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_linoleum'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_parquet'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_screed'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_warm'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u043a\u0430\u043b\u044c\u043a\u0443\u043b\u044f\u0442\u043e\u0440\u044b \u043f\u043e\u0442\u043e\u043b\u043a\u043e\u0432', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('ceilings_stretch'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('ceilings_insulation'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('ceilings_cassette'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('ceilings_rail'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u043a\u0430\u043b\u044c\u043a\u0443\u043b\u044f\u0442\u043e\u0440\u044b \u0438\u043d\u0436\u0435\u043d\u0435\u0440\u0438\u0438', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('engineering_heating'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('engineering_electrics'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('engineering_plumbing'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('engineering_ventilation'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u0441\u043f\u0435\u0446\u0438\u0430\u043b\u044c\u043d\u044b\u0435 \u043f\u043e\u043c\u0435\u0449\u0435\u043d\u0438\u044f', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('terrace'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('attic'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('balcony'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('bathroom_waterproof'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u0434\u0432\u0435\u0440\u0438 \u0438 \u043e\u043a\u043d\u0430', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('doors_install'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('windows_install'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('slopes_finishing'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u0438\u0437\u043e\u043b\u044f\u0446\u0438\u044e', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('insulation_sound'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u044d\u043a\u0441\u0442\u0435\u0440\u044c\u0435\u0440', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('exterior_facade_panels'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('fence'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('stairs'), isTrue);
    });

    test('\u043f\u043e\u0434\u0434\u0435\u0440\u0436\u0438\u0432\u0430\u0435\u0442 \u0444\u0443\u043d\u0434\u0430\u043c\u0435\u043d\u0442', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('foundation_basement'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('foundation_blind_area'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('foundation_slab'), isTrue);
    });

    test('
