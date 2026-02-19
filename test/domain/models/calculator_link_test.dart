import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/calculator_link.dart';

void main() {
  group('CalculatorLink', () {
    group('buildTargetInputs', () {
      test('маппирует ключи из results', () {
        const link = CalculatorLink(
          targetId: 'floors_tile_grout',
          labelKey: 'link.calculate_grout',
          inputMapping: {'totalArea': 'area'},
        );

        final result = link.buildTargetInputs(
          {'totalArea': 30.0},
          {},
        );

        expect(result['area'], equals(30.0));
      });

      test('fallback на inputs если ключа нет в results', () {
        const link = CalculatorLink(
          targetId: 'floors_tile_grout',
          labelKey: 'link.calculate_grout',
          inputMapping: {'tileSize': 'tileSize'},
        );

        final result = link.buildTargetInputs(
          {},
          {'tileSize': 300.0},
        );

        expect(result['tileSize'], equals(300.0));
      });

      test('results имеет приоритет над inputs при совпадении ключей', () {
        const link = CalculatorLink(
          targetId: 'mixes_primer',
          labelKey: 'link.calculate_primer',
          inputMapping: {'area': 'area'},
        );

        final result = link.buildTargetInputs(
          {'area': 50.0},
          {'area': 20.0}, // должен игнорироваться
        );

        expect(result['area'], equals(50.0));
      });

      test('staticInputs добавляются в результат', () {
        const link = CalculatorLink(
          targetId: 'floors_tile_grout',
          labelKey: 'link.calculate_grout',
          inputMapping: {'totalArea': 'area'},
          staticInputs: {'inputMode': 1},
        );

        final result = link.buildTargetInputs({'totalArea': 25.0}, {});

        expect(result['area'], equals(25.0));
        expect(result['inputMode'], equals(1.0));
      });

      test('staticInputs перезаписывают маппированные значения', () {
        const link = CalculatorLink(
          targetId: 'paint_universal',
          labelKey: 'link.calculate_paint',
          inputMapping: {'inputMode': 'inputMode'},
          staticInputs: {'inputMode': 0}, // overrides mapping
        );

        final result = link.buildTargetInputs({'inputMode': 1.0}, {});

        expect(result['inputMode'], equals(0.0));
      });

      test('несколько ключей маппируются одновременно', () {
        const link = CalculatorLink(
          targetId: 'floors_tile_grout',
          labelKey: 'link.calculate_grout',
          inputMapping: {
            'totalArea': 'area',
            'tileSize': 'tileSize',
            'jointWidth': 'jointWidth',
          },
          staticInputs: {'inputMode': 1},
        );

        final result = link.buildTargetInputs(
          {'totalArea': 30.0},
          {'tileSize': 300.0, 'jointWidth': 2.0},
        );

        expect(result['area'], equals(30.0));
        expect(result['tileSize'], equals(300.0));
        expect(result['jointWidth'], equals(2.0));
        expect(result['inputMode'], equals(1.0));
      });

      test('ключ пропускается если нет ни в results ни в inputs', () {
        const link = CalculatorLink(
          targetId: 'mixes_primer',
          labelKey: 'link.calculate_primer',
          inputMapping: {'missingKey': 'area'},
        );

        final result = link.buildTargetInputs({}, {});

        expect(result.containsKey('area'), isFalse);
      });
    });

    group('shouldShow', () {
      test('всегда показывать если showIfResultKey не задан', () {
        const link = CalculatorLink(
          targetId: 'mixes_primer',
          labelKey: 'link.calculate_primer',
          inputMapping: {},
        );

        expect(link.shouldShow({}), isTrue);
        expect(link.shouldShow({'area': 0.0}), isTrue);
      });

      test('показывать если showIfResultKey > 0', () {
        const link = CalculatorLink(
          targetId: 'mixes_primer',
          labelKey: 'link.calculate_primer',
          inputMapping: {},
          showIfResultKey: 'totalArea',
        );

        expect(link.shouldShow({'totalArea': 30.0}), isTrue);
      });

      test('скрыть если showIfResultKey == 0', () {
        const link = CalculatorLink(
          targetId: 'mixes_primer',
          labelKey: 'link.calculate_primer',
          inputMapping: {},
          showIfResultKey: 'totalArea',
        );

        expect(link.shouldShow({'totalArea': 0.0}), isFalse);
      });

      test('скрыть если showIfResultKey отсутствует в results', () {
        const link = CalculatorLink(
          targetId: 'mixes_primer',
          labelKey: 'link.calculate_primer',
          inputMapping: {},
          showIfResultKey: 'totalArea',
        );

        expect(link.shouldShow({}), isFalse);
      });
    });
  });
}
