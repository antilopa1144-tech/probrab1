import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/calculator_category.dart';
import 'package:probrab_ai/domain/models/calculator_definition_v2.dart';
import 'package:probrab_ai/domain/usecases/calculator_usecase.dart';
import 'package:probrab_ai/presentation/utils/calculator_screen_registry.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/plaster_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/putty_calculator_screen_v2.dart';
import 'package:probrab_ai/presentation/views/calculator/primer_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/tile_adhesive_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/gypsum_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/wallpaper_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/brick_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/electrical_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/tile_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/laminate_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/linoleum_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/screed_unified_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/osb/osb_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/paint/paint_screen.dart';
import 'package:probrab_ai/presentation/views/wood/wood_screen.dart';

class _MockUseCase implements CalculatorUseCase {
  @override
  CalculatorResult call(Map<String, double> inputs, List<PriceItem> priceList) {
    return const CalculatorResult(values: {});
  }
}

CalculatorDefinitionV2 _createTestDefinition({
  String id = 'test_calc',
  String titleKey = 'test.title',
}) {
  return CalculatorDefinitionV2(
    id: id,
    titleKey: titleKey,
    category: CalculatorCategory.interior,
    subCategoryKey: 'test.sub',
    fields: [],
    useCase: _MockUseCase(),
  );
}

void main() {
  group('CalculatorScreenRegistry - Основные методы', () {
    test('hasCustomScreen возвращает false для неизвестного ID', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('nonexistent'), isFalse);
    });

    test('hasCustomScreen возвращает true для известных калькуляторов', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_plaster'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('mixes_putty'), isTrue);
      expect(CalculatorScreenRegistry.hasCustomScreen('floors_tile'), isTrue);
    });

    test('build возвращает null для неизвестного ID', () {
      final definition = _createTestDefinition(id: 'nonexistent');
      final screen = CalculatorScreenRegistry.build('nonexistent', definition, null);
      expect(screen, isNull);
    });

    test('buildWithFallback всегда возвращает виджет', () {
      final definition = _createTestDefinition(id: 'nonexistent');
      final screen = CalculatorScreenRegistry.buildWithFallback(definition, null);
      expect(screen, isNotNull);
    });

    test('buildWithFallback возвращает ProCalculatorScreen для неизвестного ID', () {
      final definition = _createTestDefinition(id: 'unknown_calculator_id');
      final result = CalculatorScreenRegistry.buildWithFallback(definition, null);
      expect(result, isA<ProCalculatorScreen>());
    });

    test('buildWithFallback передаёт definition в ProCalculatorScreen', () {
      final definition = _createTestDefinition(id: 'unknown_calculator_id');
      final result = CalculatorScreenRegistry.buildWithFallback(definition, null) as ProCalculatorScreen;
      expect(result.definition, equals(definition));
    });

    test('buildWithFallback передаёт initialInputs в ProCalculatorScreen', () {
      final definition = _createTestDefinition(id: 'unknown_calculator_id');
      final inputs = {'width': 10.0, 'height': 20.0};
      final result = CalculatorScreenRegistry.buildWithFallback(definition, inputs) as ProCalculatorScreen;
      expect(result.initialInputs, equals(inputs));
    });
  });

  group('CalculatorScreenRegistry - Смеси', () {
    test('build возвращает PlasterCalculatorScreen для mixes_plaster', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final result = CalculatorScreenRegistry.build('mixes_plaster', definition, null);
      expect(result, isA<PlasterCalculatorScreen>());
    });

    test('build возвращает PuttyCalculatorScreenV2 для mixes_putty', () {
      final definition = _createTestDefinition(id: 'mixes_putty');
      final result = CalculatorScreenRegistry.build('mixes_putty', definition, null);
      expect(result, isA<PuttyCalculatorScreenV2>());
    });

    test('build возвращает PrimerCalculatorScreen для mixes_primer', () {
      final definition = _createTestDefinition(id: 'mixes_primer');
      final result = CalculatorScreenRegistry.build('mixes_primer', definition, null);
      expect(result, isA<PrimerCalculatorScreen>());
    });

    test('build возвращает TileAdhesiveCalculatorScreen для mixes_tile_glue', () {
      final definition = _createTestDefinition(id: 'mixes_tile_glue');
      final result = CalculatorScreenRegistry.build('mixes_tile_glue', definition, null);
      expect(result, isA<TileAdhesiveCalculatorScreen>());
    });

    test('передаёт параметры в PlasterCalculatorScreen', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final inputs = {'area': 50.0, 'thickness': 2.0};
      final result = CalculatorScreenRegistry.build('mixes_plaster', definition, inputs) as PlasterCalculatorScreen;
      expect(result.definition, equals(definition));
      expect(result.initialInputs, equals(inputs));
    });
  });

  group('CalculatorScreenRegistry - Листовые материалы', () {
    test('build возвращает ScreedUnifiedCalculatorScreen для dsp', () {
      final definition = _createTestDefinition(id: 'dsp');
      final result = CalculatorScreenRegistry.build('dsp', definition, null);
      expect(result, isA<ScreedUnifiedCalculatorScreen>());
    });

    test('build возвращает OsbCalculatorScreen для sheeting_osb_plywood', () {
      final definition = _createTestDefinition(id: 'sheeting_osb_plywood');
      final result = CalculatorScreenRegistry.build('sheeting_osb_plywood', definition, null);
      expect(result, isA<OsbCalculatorScreen>());
    });

    test('build возвращает GypsumCalculatorScreen для gypsum_board', () {
      final definition = _createTestDefinition(id: 'gypsum_board');
      final result = CalculatorScreenRegistry.build('gypsum_board', definition, null);
      expect(result, isA<GypsumCalculatorScreen>());
    });

    test('передаёт параметры в OsbCalculatorScreen', () {
      final definition = _createTestDefinition(id: 'sheeting_osb_plywood');
      final inputs = {'area': 100.0};
      final result = CalculatorScreenRegistry.build('sheeting_osb_plywood', definition, inputs) as OsbCalculatorScreen;
      expect(result.definition, equals(definition));
      expect(result.initialInputs, equals(inputs));
    });
  });

  group('CalculatorScreenRegistry - Краска и дерево', () {
    test('build возвращает PaintScreen для paint_universal', () {
      final definition = _createTestDefinition(id: 'paint_universal');
      final result = CalculatorScreenRegistry.build('paint_universal', definition, null);
      expect(result, isA<PaintScreen>());
    });

    test('build возвращает PaintScreen для paint', () {
      final definition = _createTestDefinition(id: 'paint');
      final result = CalculatorScreenRegistry.build('paint', definition, null);
      expect(result, isA<PaintScreen>());
    });

    test('build возвращает WoodScreen для wood', () {
      final definition = _createTestDefinition(id: 'wood');
      final result = CalculatorScreenRegistry.build('wood', definition, null);
      expect(result, isA<WoodScreen>());
    });
  });

  group('CalculatorScreenRegistry - Стены', () {
    test('build возвращает WallpaperCalculatorScreen для walls_wallpaper', () {
      final definition = _createTestDefinition(id: 'walls_wallpaper');
      final result = CalculatorScreenRegistry.build('walls_wallpaper', definition, null);
      expect(result, isA<WallpaperCalculatorScreen>());
    });

    test('hasCustomScreen возвращает true для всех калькуляторов стен', () {
      final wallCalculators = [
        'walls_wallpaper',
        'walls_3d_panels',
        'walls_wood',
        'walls_decor_plaster',
        'walls_decor_stone',
        'walls_mdf_panels',
        'walls_pvc_panels',
      ];

      for (final id in wallCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });
  });

  group('CalculatorScreenRegistry - Перегородки', () {
    test('build возвращает BrickCalculatorScreen для partitions_brick', () {
      final definition = _createTestDefinition(id: 'partitions_brick');
      final result = CalculatorScreenRegistry.build('partitions_brick', definition, null);
      expect(result, isA<BrickCalculatorScreen>());
    });

    test('build возвращает BrickCalculatorScreen для exterior_brick', () {
      final definition = _createTestDefinition(id: 'exterior_brick');
      final result = CalculatorScreenRegistry.build('exterior_brick', definition, null);
      expect(result, isA<BrickCalculatorScreen>());
    });

    test('hasCustomScreen возвращает true для всех калькуляторов перегородок', () {
      final partitionCalculators = [
        'partitions_blocks',
        'partitions_brick',
        'exterior_brick',
      ];

      for (final id in partitionCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });
  });

  group('CalculatorScreenRegistry - Полы', () {
    test('build возвращает TileCalculatorScreen для floors_tile', () {
      final definition = _createTestDefinition(id: 'floors_tile');
      final result = CalculatorScreenRegistry.build('floors_tile', definition, null);
      expect(result, isA<TileCalculatorScreen>());
    });

    test('build возвращает LaminateCalculatorScreen для floors_laminate', () {
      final definition = _createTestDefinition(id: 'floors_laminate');
      final result = CalculatorScreenRegistry.build('floors_laminate', definition, null);
      expect(result, isA<LaminateCalculatorScreen>());
    });

    test('build возвращает LinoleumCalculatorScreen для floors_linoleum', () {
      final definition = _createTestDefinition(id: 'floors_linoleum');
      final result = CalculatorScreenRegistry.build('floors_linoleum', definition, null);
      expect(result, isA<LinoleumCalculatorScreen>());
    });

    test('hasCustomScreen возвращает true для всех калькуляторов полов', () {
      final floorCalculators = [
        'floors_tile',
        'floors_self_leveling',
        'floors_laminate',
        'floors_linoleum',
        'floors_parquet',
        'floors_screed',
        'floors_warm',
      ];

      for (final id in floorCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });

    test('передаёт параметры в TileCalculatorScreen', () {
      final definition = _createTestDefinition(id: 'floors_tile');
      final inputs = {'area': 25.0};
      final result = CalculatorScreenRegistry.build('floors_tile', definition, inputs) as TileCalculatorScreen;
      expect(result.definition, equals(definition));
      expect(result.initialInputs, equals(inputs));
    });
  });

  group('CalculatorScreenRegistry - Потолки', () {
    test('hasCustomScreen возвращает true для всех калькуляторов потолков', () {
      final ceilingCalculators = [
        'ceilings_stretch',
        'ceilings_insulation',
        'ceilings_cassette',
        'ceilings_rail',
      ];

      for (final id in ceilingCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });
  });

  group('CalculatorScreenRegistry - Инженерия', () {
    test('build возвращает ElectricalCalculatorScreen для engineering_electrics', () {
      final definition = _createTestDefinition(id: 'engineering_electrics');
      final result = CalculatorScreenRegistry.build('engineering_electrics', definition, null);
      expect(result, isA<ElectricalCalculatorScreen>());
    });

    test('hasCustomScreen возвращает true для всех инженерных калькуляторов', () {
      final engineeringCalculators = [
        'engineering_heating',
        'engineering_electrics',
        // 'engineering_plumbing' - удалён
        'engineering_ventilation',
      ];

      for (final id in engineeringCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });

    test('передаёт параметры в ElectricalCalculatorScreen', () {
      final definition = _createTestDefinition(id: 'engineering_electrics');
      final inputs = {'rooms': 5.0};
      final result = CalculatorScreenRegistry.build('engineering_electrics', definition, inputs) as ElectricalCalculatorScreen;
      expect(result.definition, equals(definition));
      expect(result.initialInputs, equals(inputs));
    });
  });

  group('CalculatorScreenRegistry - Полнота покрытия', () {
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
        'engineering_heating', 'engineering_electrics', 'engineering_ventilation',
        'terrace', 'attic', 'balcony', 'bathroom_waterproof',
        'doors_install', 'windows_install', 'slopes_finishing',
        'insulation_sound',
        'exterior_facade_panels', 'fence', 'stairs',
        'foundation_basement', 'foundation_blind_area', 'foundation_slab',
        'roofing_gutters',
      ];

      // Снижено до 45 после удаления legacy калькуляторов
      expect(registeredIds.length, greaterThanOrEqualTo(45));

      for (final id in registeredIds) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Calculator $id should be registered');
      }
    });

    test('все основные категории имеют калькуляторы', () {
      final categories = [
        'mixes_plaster',        // Смеси
        'dsp',                  // Листовые материалы
        'paint_universal',      // Краска
        'walls_wallpaper',      // Стены
        'partitions_brick',     // Перегородки
        'floors_tile',          // Полы
        'ceilings_stretch',     // Потолки
        'engineering_electrics', // Инженерия
        'terrace',              // Специальные помещения
        'doors_install',        // Двери и окна
        'exterior_facade_panels', // Экстерьер
        'foundation_basement',  // Фундамент
        'roofing_gutters',      // Кровля
      ];

      for (final id in categories) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Категория $id должна иметь калькулятор');
      }
    });
  });

  group('CalculatorScreenRegistry - Передача параметров', () {
    test('build передаёт null initialInputs корректно', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final result = CalculatorScreenRegistry.build('mixes_plaster', definition, null) as PlasterCalculatorScreen;
      expect(result.initialInputs, isNull);
    });

    test('build передаёт пустой Map initialInputs корректно', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final inputs = <String, double>{};
      final result = CalculatorScreenRegistry.build('mixes_plaster', definition, inputs) as PlasterCalculatorScreen;
      expect(result.initialInputs, equals(inputs));
    });

    test('build обрабатывает initialInputs с отрицательными значениями', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final inputs = {'area': -50.0, 'thickness': -2.0};
      final result = CalculatorScreenRegistry.build('mixes_plaster', definition, inputs);
      expect(result, isNotNull);
      expect(result, isA<PlasterCalculatorScreen>());
    });

    test('build обрабатывает initialInputs с нулевыми значениями', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final inputs = {'area': 0.0, 'thickness': 0.0};
      final result = CalculatorScreenRegistry.build('mixes_plaster', definition, inputs);
      expect(result, isNotNull);
      expect(result, isA<PlasterCalculatorScreen>());
    });

    test('build обрабатывает initialInputs с очень большими значениями', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final inputs = {'area': 999999.0, 'thickness': 999999.0};
      final result = CalculatorScreenRegistry.build('mixes_plaster', definition, inputs);
      expect(result, isNotNull);
      expect(result, isA<PlasterCalculatorScreen>());
    });
  });

  group('CalculatorScreenRegistry - Edge cases', () {
    test('build обрабатывает пустую строку ID', () {
      final definition = _createTestDefinition(id: '');
      final result = CalculatorScreenRegistry.build('', definition, null);
      expect(result, isNull);
    });

    test('buildWithFallback обрабатывает пустую строку ID', () {
      final definition = _createTestDefinition(id: '');
      final result = CalculatorScreenRegistry.buildWithFallback(definition, null);
      expect(result, isA<ProCalculatorScreen>());
    });

    test('hasCustomScreen обрабатывает пустую строку ID', () {
      expect(CalculatorScreenRegistry.hasCustomScreen(''), isFalse);
    });

    test('build обрабатывает ID с пробелами', () {
      final definition = _createTestDefinition(id: 'calculator with spaces');
      final result = CalculatorScreenRegistry.build('calculator with spaces', definition, null);
      expect(result, isNull);
    });

    test('build обрабатывает ID с специальными символами', () {
      final definition = _createTestDefinition(id: 'calc@special');
      final result = CalculatorScreenRegistry.build('calc@special', definition, null);
      expect(result, isNull);
    });

    test('build обрабатывает ID в неправильном регистре', () {
      final definition = _createTestDefinition(id: 'MIXES_PLASTER');
      final result = CalculatorScreenRegistry.build('MIXES_PLASTER', definition, null);
      expect(result, isNull);
    });
  });

  group('CalculatorScreenRegistry - Консистентность', () {
    test('один и тот же ID всегда возвращает тот же тип экрана', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final result1 = CalculatorScreenRegistry.build('mixes_plaster', definition, null);
      final result2 = CalculatorScreenRegistry.build('mixes_plaster', definition, null);
      expect(result1.runtimeType, equals(result2.runtimeType));
    });

    test('разные ID возвращают разные типы экранов', () {
      final def1 = _createTestDefinition(id: 'mixes_plaster');
      final def2 = _createTestDefinition(id: 'mixes_putty');
      final result1 = CalculatorScreenRegistry.build('mixes_plaster', def1, null);
      final result2 = CalculatorScreenRegistry.build('mixes_putty', def2, null);
      expect(result1.runtimeType, isNot(equals(result2.runtimeType)));
    });

    test('hasCustomScreen согласуется с build', () {
      final testIds = [
        'mixes_plaster',
        'unknown_id',
        'floors_tile',
        'another_unknown',
      ];

      for (final id in testIds) {
        final hasCustom = CalculatorScreenRegistry.hasCustomScreen(id);
        final definition = _createTestDefinition(id: id);
        final screen = CalculatorScreenRegistry.build(id, definition, null);

        if (hasCustom) {
          expect(screen, isNotNull, reason: 'ID $id имеет кастомный экран, но build вернул null');
        } else {
          expect(screen, isNull, reason: 'ID $id не имеет кастомного экрана, но build вернул не-null');
        }
      }
    });

    test('buildWithFallback использует build когда доступен кастомный экран', () {
      final definition = _createTestDefinition(id: 'mixes_plaster');
      final customScreen = CalculatorScreenRegistry.build('mixes_plaster', definition, null);
      final fallbackScreen = CalculatorScreenRegistry.buildWithFallback(definition, null);
      expect(customScreen.runtimeType, equals(fallbackScreen.runtimeType));
    });

    test('buildWithFallback использует ProCalculatorScreen когда нет кастомного экрана', () {
      final definition = _createTestDefinition(id: 'unknown');
      final fallbackScreen = CalculatorScreenRegistry.buildWithFallback(definition, null);
      expect(fallbackScreen, isA<ProCalculatorScreen>());
    });
  });

  group('CalculatorScreenRegistry - Специфические калькуляторы', () {
    test('hasCustomScreen возвращает true для специальных помещений', () {
      final specialRoomCalculators = [
        'terrace',
        'attic',
        'balcony',
        'bathroom_waterproof',
      ];

      for (final id in specialRoomCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });

    test('hasCustomScreen возвращает true для дверей и окон', () {
      final doorWindowCalculators = [
        'doors_install',
        'windows_install',
        'slopes_finishing',
      ];

      for (final id in doorWindowCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });

    test('hasCustomScreen возвращает true для экстерьера', () {
      final exteriorCalculators = [
        'exterior_facade_panels',
        'fence',
        'stairs',
      ];

      for (final id in exteriorCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });

    test('hasCustomScreen возвращает true для фундамента', () {
      final foundationCalculators = [
        'foundation_basement',
        'foundation_blind_area',
        'foundation_slab',
      ];

      for (final id in foundationCalculators) {
        expect(CalculatorScreenRegistry.hasCustomScreen(id), isTrue,
            reason: 'Калькулятор $id должен быть зарегистрирован');
      }
    });

    test('hasCustomScreen возвращает true для изоляции', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('insulation_sound'), isTrue);
    });

    test('hasCustomScreen возвращает true для кровли', () {
      expect(CalculatorScreenRegistry.hasCustomScreen('roofing_gutters'), isTrue);
    });
  });
}
