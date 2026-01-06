import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/usecases/calculate_gypsum.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/core/exceptions/calculation_exception.dart';

void main() {
  group('CalculateGypsum', () {
    late CalculateGypsum calculator;
    late List<PriceItem> emptyPriceList;

    setUp(() {
      calculator = CalculateGypsum();
      emptyPriceList = <PriceItem>[];
    });

    group('validation', () {
      test('returns error for zero area', () {
        final error = calculator.validateInputs({'area': 0.0});
        expect(error, isNotNull);
        expect(error, contains('больше нуля'));
      });

      test('returns error for negative area', () {
        final error = calculator.validateInputs({'area': -10.0});
        expect(error, isNotNull);
      });

      test('returns error for area exceeding maximum', () {
        final error = calculator.validateInputs({'area': 15000.0});
        expect(error, isNotNull);
        expect(error, contains('максимум'));
      });

      test('returns error for invalid construction type', () {
        final error = calculator.validateInputs({
          'area': 20.0,
          'construction_type': 5.0,
        });
        expect(error, isNotNull);
        expect(error, contains('тип конструкции'));
      });

      test('returns null for valid inputs', () {
        final error = calculator.validateInputs({
          'area': 20.0,
          'construction_type': 1.0,
        });
        expect(error, isNull);
      });
    });

    group('wall lining (type 1)', () {
      test('calculates GKL sheets for wall lining', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
          'layers': 1.0,
        }, emptyPriceList);

        // 20 м² × 1.05 (запас) = 21 м² → 21/3 = 7 листов
        expect(result.values['gklSheets'], equals(7.0));
        expect(result.values['constructionType'], equals(1.0));
      });

      test('calculates profiles for wall lining', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
        }, emptyPriceList);

        // ПН: 20 × 0.8 = 16 м → ceil(16/3) = 6 штук
        expect(result.values['pnPieces'], equals(6.0));
        // ПП: 20 × 2.0 = 40 м → ceil(40/3) = 14 штук
        expect(result.values['ppPieces'], equals(14.0));
      });

      test('calculates suspensions for wall lining', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
        }, emptyPriceList);

        // Подвесы: ceil(20 × 1.3) = 26 шт
        expect(result.values['suspensions'], equals(26.0));
      });
    });

    group('partition (type 2)', () {
      test('calculates GKL for partition with double-sided coverage', () {
        final result = calculator({
          'area': 10.0,
          'construction_type': 2.0,
          'layers': 1.0,
        }, emptyPriceList);

        // 10 м² × 1.05 × 2 (две стороны) = 21 м² → 21/3 = 7 листов
        expect(result.values['gklSheets'], equals(7.0));
      });

      test('calculates profiles for partition', () {
        final result = calculator({
          'area': 10.0,
          'construction_type': 2.0,
        }, emptyPriceList);

        // ПН: 10 × 0.7 = 7 м → ceil(7/3) = 3 штуки
        expect(result.values['pnPieces'], equals(3.0));
        // ПС: 10 × 2.0 = 20 м → ceil(20/3) = 7 штук
        expect(result.values['ppPieces'], equals(7.0));
      });

      test('partition has no suspensions', () {
        final result = calculator({
          'area': 10.0,
          'construction_type': 2.0,
        }, emptyPriceList);

        expect(result.values.containsKey('suspensions'), isFalse);
      });
    });

    group('ceiling (type 3)', () {
      test('calculates GKL for ceiling', () {
        final result = calculator({
          'area': 15.0,
          'construction_type': 3.0,
          'layers': 1.0,
        }, emptyPriceList);

        // 15 м² × 1.05 = 15.75 м² → ceil(15.75/3) = 6 листов
        expect(result.values['gklSheets'], equals(6.0));
      });

      test('calculates connectors (crabs) for ceiling', () {
        final result = calculator({
          'area': 15.0,
          'construction_type': 3.0,
        }, emptyPriceList);

        // Крабы: ceil(15 × 1.7) = 26 шт
        expect(result.values['connectors'], equals(26.0));
      });
    });

    group('layers', () {
      test('calculates correctly for 2 layers', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
          'layers': 2.0,
        }, emptyPriceList);

        // 20 м² × 2 слоя × 1.05 = 42 м² → ceil(42/3) = 14 листов
        expect(result.values['gklSheets'], equals(14.0));
        // Саморезы 35мм для второго слоя
        expect(result.values.containsKey('screwsTN35'), isTrue);
      });

      test('single layer has no 35mm screws', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
          'layers': 1.0,
        }, emptyPriceList);

        expect(result.values.containsKey('screwsTN35'), isFalse);
      });
    });

    group('insulation', () {
      test('calculates insulation area when enabled', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 2.0,
          'use_insulation': 1.0,
        }, emptyPriceList);

        // 20 × 1.05 = 21 м² утеплителя
        expect(result.values['insulationArea'], closeTo(21.0, 0.1));
      });

      test('no insulation when disabled', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 2.0,
          'use_insulation': 0.0,
        }, emptyPriceList);

        expect(result.values.containsKey('insulationArea'), isFalse);
      });
    });

    group('finishing materials', () {
      test('calculates armature tape', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
        }, emptyPriceList);

        // 20 × 1.2 = 24 м
        expect(result.values['armatureTape'], equals(24.0));
      });

      test('calculates filler for wall lining', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
          'layers': 1.0,
        }, emptyPriceList);

        // 20 × 0.3 × 1 слой = 6 кг
        expect(result.values['fillerKg'], equals(6.0));
      });

      test('calculates more filler for partition', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 2.0,
          'layers': 1.0,
        }, emptyPriceList);

        // 20 × 0.6 × 1 слой = 12 кг (больше швов)
        expect(result.values['fillerKg'], equals(12.0));
      });

      test('calculates primer', () {
        final result = calculator({
          'area': 20.0,
          'construction_type': 1.0,
        }, emptyPriceList);

        // 20 × 0.1 = 2 л
        expect(result.values['primerLiters'], equals(2.0));
      });
    });

    group('edge cases', () {
      test('handles minimum valid area', () {
        final result = calculator({
          'area': 0.1,
          'construction_type': 1.0,
        }, emptyPriceList);

        expect(result.values['gklSheets'], greaterThan(0));
      });

      test('handles large area', () {
        final result = calculator({
          'area': 500.0,
          'construction_type': 1.0,
        }, emptyPriceList);

        expect(result.values['gklSheets'], greaterThan(150));
      });

      test('throws for zero area via calculate', () {
        expect(
          () => calculator({'area': 0.0}, emptyPriceList),
          throwsA(isA<CalculationException>()),
        );
      });
    });
  });
}
