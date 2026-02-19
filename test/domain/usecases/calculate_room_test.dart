import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_room.dart';

void main() {
  late CalculateRoom useCase;

  setUp(() {
    useCase = CalculateRoom();
  });

  // Комната 5×4×2.7: периметр=18, стены брутто=48.6, нетто=48.6-1.6-1.82=45.18
  Map<String, double> baseInputs({
    double length = 5.0,
    double width = 4.0,
    double height = 2.7,
    int doors = 1,
    int windows = 1,
    bool plaster = false,
    bool putty = false,
    bool paintWalls = false,
    bool wallpaper = false,
    bool paintCeiling = false,
    bool laminate = false,
    bool tile = false,
  }) =>
      {
        'length': length,
        'width': width,
        'height': height,
        'doorsCount': doors.toDouble(),
        'windowsCount': windows.toDouble(),
        'doPlaster': plaster ? 1.0 : 0.0,
        'doPutty': putty ? 1.0 : 0.0,
        'doPaintWalls': paintWalls ? 1.0 : 0.0,
        'doWallpaper': wallpaper ? 1.0 : 0.0,
        'doPaintCeiling': paintCeiling ? 1.0 : 0.0,
        'doLaminate': laminate ? 1.0 : 0.0,
        'doTile': tile ? 1.0 : 0.0,
        'plasterThickness': 10.0,
        'plasterType': 1.0,
        'puttyQuality': 2.0,
        'paintLayers': 2.0,
        'laminatePackArea': 2.0,
        'tileSizeRoom': 60.0,
      };

  group('Базовые площади', () {
    test('всегда рассчитываются, даже если все работы выключены', () {
      final result = useCase.call(baseInputs(), []);
      expect(result.values['floorArea'], closeTo(20.0, 0.01));
      expect(result.values['ceilingArea'], closeTo(20.0, 0.01));
      expect(result.values['wallAreaGross'], closeTo(48.6, 0.1));
      expect(result.values['perimeter'], closeTo(18.0, 0.01));
    });

    test('wallAreaNet вычитает площади проёмов (1 дверь + 1 окно)', () {
      final result = useCase.call(baseInputs(), []);
      // дверь 0.8×2.0 = 1.6, окно 1.4×1.3 = 1.82
      const expected = 48.6 - 1.6 - 1.82;
      expect(result.values['wallAreaNet'], closeTo(expected, 0.1));
    });

    test('без проёмов wallAreaNet == wallAreaGross', () {
      final result = useCase.call(baseInputs(doors: 0, windows: 0), []);
      expect(result.values['wallAreaNet'],
          closeTo(result.values['wallAreaGross']!, 0.01));
    });

    test('2 двери + 2 окна уменьшают wallAreaNet', () {
      final result1 = useCase.call(baseInputs(doors: 1, windows: 1), []);
      final result2 = useCase.call(baseInputs(doors: 2, windows: 2), []);
      expect(result2.values['wallAreaNet'],
          lessThan(result1.values['wallAreaNet']!));
    });
  });

  group('Штукатурка стен', () {
    test('при doPlaster=true появляются ключи walls_plaster_*', () {
      final result = useCase.call(baseInputs(plaster: true), []);
      expect(result.values.keys.any((k) => k.startsWith('walls_plaster_')),
          isTrue);
    });

    test('при doPlaster=false ключи walls_plaster_* отсутствуют', () {
      final result = useCase.call(baseInputs(plaster: false), []);
      expect(result.values.keys.any((k) => k.startsWith('walls_plaster_')),
          isFalse);
    });

    test('plasterBags > 0 для стандартной комнаты 5×4×2.7', () {
      final result = useCase.call(baseInputs(plaster: true), []);
      final bags = result.values['walls_plaster_plasterBags'];
      expect(bags, isNotNull);
      expect(bags, greaterThan(0));
    });

    test('больше штукатурки при большей толщине слоя', () {
      final inputs10mm = baseInputs(plaster: true)..['plasterThickness'] = 10.0;
      final inputs20mm = baseInputs(plaster: true)..['plasterThickness'] = 20.0;
      final bags10 = useCase.call(inputs10mm, []).values['walls_plaster_plasterBags']!;
      final bags20 = useCase.call(inputs20mm, []).values['walls_plaster_plasterBags']!;
      expect(bags20, greaterThan(bags10));
    });
  });

  group('Шпаклёвка стен', () {
    test('при doPutty=true появляются ключи walls_putty_*', () {
      final result = useCase.call(baseInputs(putty: true), []);
      expect(result.values.keys.any((k) => k.startsWith('walls_putty_')),
          isTrue);
    });

    test('при doPutty=false ключи walls_putty_* отсутствуют', () {
      final result = useCase.call(baseInputs(putty: false), []);
      expect(result.values.keys.any((k) => k.startsWith('walls_putty_')),
          isFalse);
    });
  });

  group('Покраска стен', () {
    test('при doPaintWalls=true появляются ключи walls_paint_*', () {
      final result = useCase.call(baseInputs(paintWalls: true), []);
      expect(result.values.keys.any((k) => k.startsWith('walls_paint_')),
          isTrue);
    });

    test('больше краски при большем количестве слоёв', () {
      final inputs1 = baseInputs(paintWalls: true)..['paintLayers'] = 1.0;
      final inputs3 = baseInputs(paintWalls: true)..['paintLayers'] = 3.0;
      final liters1 = useCase.call(inputs1, []).values['walls_paint_paintLiters']!;
      final liters3 = useCase.call(inputs3, []).values['walls_paint_paintLiters']!;
      expect(liters3, greaterThan(liters1));
    });
  });

  group('Обои', () {
    test('при doWallpaper=true появляются ключи walls_wallpaper_*', () {
      final result = useCase.call(baseInputs(wallpaper: true), []);
      expect(result.values.keys.any((k) => k.startsWith('walls_wallpaper_')),
          isTrue);
    });

    test('при doWallpaper=false ключи walls_wallpaper_* отсутствуют', () {
      final result = useCase.call(baseInputs(wallpaper: false), []);
      expect(result.values.keys.any((k) => k.startsWith('walls_wallpaper_')),
          isFalse);
    });
  });

  group('Покраска потолка', () {
    test('при doPaintCeiling=true появляются ключи ceiling_paint_*', () {
      final result = useCase.call(baseInputs(paintCeiling: true), []);
      expect(result.values.keys.any((k) => k.startsWith('ceiling_paint_')),
          isTrue);
    });

    test('при doPaintCeiling=false ключи ceiling_paint_* отсутствуют', () {
      final result = useCase.call(baseInputs(paintCeiling: false), []);
      expect(result.values.keys.any((k) => k.startsWith('ceiling_paint_')),
          isFalse);
    });
  });

  group('Ламинат', () {
    test('при doLaminate=true появляются ключи floor_laminate_*', () {
      final result = useCase.call(baseInputs(laminate: true), []);
      expect(result.values.keys.any((k) => k.startsWith('floor_laminate_')),
          isTrue);
    });

    test('при doLaminate=false ключи floor_laminate_* отсутствуют', () {
      final result = useCase.call(baseInputs(laminate: false), []);
      expect(result.values.keys.any((k) => k.startsWith('floor_laminate_')),
          isFalse);
    });

    test('packsNeeded > 0 для комнаты 5×4', () {
      final result = useCase.call(baseInputs(laminate: true), []);
      final packs = result.values['floor_laminate_packsNeeded'];
      expect(packs, isNotNull);
      expect(packs, greaterThan(0));
    });

    test('больше упаковок для большей комнаты', () {
      final small = useCase.call(
          baseInputs(length: 3.0, width: 3.0, laminate: true), []);
      final large = useCase.call(
          baseInputs(length: 8.0, width: 6.0, laminate: true), []);
      expect(large.values['floor_laminate_packsNeeded'],
          greaterThan(small.values['floor_laminate_packsNeeded']!));
    });
  });

  group('Плитка', () {
    test('при doTile=true появляются ключи floor_tile_*', () {
      final result = useCase.call(baseInputs(tile: true), []);
      expect(result.values.keys.any((k) => k.startsWith('floor_tile_')),
          isTrue);
    });

    test('при doTile=false ключи floor_tile_* отсутствуют', () {
      final result = useCase.call(baseInputs(tile: false), []);
      expect(result.values.keys.any((k) => k.startsWith('floor_tile_')),
          isFalse);
    });
  });

  group('Комплексный расчёт', () {
    test('все виды работ одновременно — все группы результатов присутствуют', () {
      final result = useCase.call(
        baseInputs(
          plaster: true,
          putty: true,
          paintWalls: true,
          paintCeiling: true,
          laminate: true,
        ),
        [],
      );
      final keys = result.values.keys;
      expect(keys.any((k) => k.startsWith('walls_plaster_')), isTrue);
      expect(keys.any((k) => k.startsWith('walls_putty_')), isTrue);
      expect(keys.any((k) => k.startsWith('walls_paint_')), isTrue);
      expect(keys.any((k) => k.startsWith('ceiling_paint_')), isTrue);
      expect(keys.any((k) => k.startsWith('floor_laminate_')), isTrue);
    });

    test('все работы выключены — только базовые площади', () {
      final result = useCase.call(baseInputs(), []);
      final nonBase = result.values.keys
          .where((k) =>
              k.startsWith('walls_') ||
              k.startsWith('floor_') ||
              k.startsWith('ceiling_'))
          .toList();
      expect(nonBase, isEmpty);
    });

    test('все значения не отрицательные', () {
      final result = useCase.call(
        baseInputs(
          plaster: true,
          putty: true,
          paintWalls: true,
          paintCeiling: true,
          laminate: true,
        ),
        [],
      );
      for (final entry in result.values.entries) {
        expect(entry.value, greaterThanOrEqualTo(0),
            reason: '${entry.key} не должен быть отрицательным');
      }
    });
  });

  group('Граничные условия', () {
    test('минимальные размеры комнаты — расчёт без ошибок', () {
      final result = useCase.call(
        baseInputs(length: 1.0, width: 1.0, height: 2.0, laminate: true),
        [],
      );
      expect(result.values['floorArea'], closeTo(1.0, 0.01));
    });

    test('очень много проёмов — wallAreaNet не уходит в минус', () {
      final result = useCase.call(
        baseInputs(doors: 5, windows: 10, putty: true),
        [],
      );
      expect(result.values['wallAreaNet'], greaterThanOrEqualTo(0));
    });

    test('результаты округлены до 2 знаков', () {
      final result = useCase.call(baseInputs(putty: true), []);
      for (final value in result.values.values) {
        final rounded = (value * 100).roundToDouble() / 100;
        expect(value, closeTo(rounded, 0.001),
            reason: '$value должен быть округлён до 2 знаков');
      }
    });
  });

  group('Санитарная проверка формул (для комнаты 5×4×2.7)', () {
    test('floorArea = 5×4 = 20 м²', () {
      final r = useCase.call(baseInputs(), []);
      expect(r.values['floorArea'], closeTo(20.0, 0.01));
    });

    test('wallAreaGross = 2×(5+4)×2.7 = 48.6 м²', () {
      final r = useCase.call(baseInputs(), []);
      expect(r.values['wallAreaGross'], closeTo(48.6, 0.1));
    });

    test('openingsArea = 1×1.6 + 1×1.82 = 3.42 м²', () {
      final r = useCase.call(baseInputs(), []);
      expect(r.values['openingsArea'], closeTo(3.42, 0.05));
    });

    test('ламинат на 20 м² даёт разумное кол-во упаковок (8-15 при packArea=2)', () {
      final r = useCase.call(baseInputs(laminate: true), []);
      final packs = r.values['floor_laminate_packsNeeded']!;
      // 20 м² / 2.0 м² × коэф ≈ 10-11 упаковок
      expect(packs, greaterThanOrEqualTo(8));
      expect(packs, lessThanOrEqualTo(15));
    });
  });
}
