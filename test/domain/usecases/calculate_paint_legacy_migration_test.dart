import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/data/models/price_item.dart';
import 'package:probrab_ai/domain/usecases/calculate_paint.dart';

void main() {
  group('CalculatePaint legacy universal migration', () {
    final calculator = CalculatePaint();
    const emptyPriceList = <PriceItem>[];

    test('walls-only area mode preserves legacy rounded outputs', () {
      final result = calculator.calculate({
        'paintType': 0.0,
        'inputMode': 0.0,
        'wallArea': 50.0,
        'layers': 2.0,
        'reserve': 10.0,
        'consumption': 0.12,
      }, emptyPriceList);

      expect(result.values['wallArea'], equals(50.0));
      expect(result.values['ceilingArea'], equals(0.0));
      expect(result.values['totalArea'], equals(50.0));
      expect(result.values['paintLiters'], equals(15.0));
      expect(result.values['primerLiters'], closeTo(9.0, 1.0));
      expect(result.norms, contains('paint-canonical-v1'));
    });

    test('ceiling premium remains higher than walls for equal area', () {
      final ceilingResult = calculator.calculate({
        'paintType': 1.0,
        'inputMode': 0.0,
        'ceilingArea': 40.0,
        'layers': 2.0,
        'reserve': 0.0,
        'consumption': 0.10,
      }, emptyPriceList);
      final wallResult = calculator.calculate({
        'paintType': 0.0,
        'inputMode': 0.0,
        'wallArea': 40.0,
        'layers': 2.0,
        'reserve': 0.0,
        'consumption': 0.10,
      }, emptyPriceList);

      expect(
        ceilingResult.values['paintLiters']!,
        greaterThan(wallResult.values['paintLiters']!),
      );
    });

    test(
      'room dimensions + dark raw surface keeps practical scenario output',
      () {
        final result = calculator.calculate({
          'paintType': 2.0,
          'inputMode': 1.0,
          'length': 5.0,
          'width': 4.0,
          'height': 2.7,
          'doorsWindows': 5.0,
          'layers': 2.0,
          'reserve': 10.0,
          'consumption': 0.12,
          'surfacePrep': 2.0,
          'colorIntensity': 3.0,
        }, emptyPriceList);

        expect(result.values['wallArea'], closeTo(43.6, 0.5));
        expect(result.values['ceilingArea'], equals(20.0));
        expect(result.values['totalArea'], closeTo(63.6, 0.5));
        expect(result.values['paintLiters'], closeTo(31.0, 1.0));
        expect(result.values['primerLiters'], closeTo(11.0, 1.0));
        expect(result.values['surfacePrep'], equals(2.0));
        expect(result.values['colorIntensity'], equals(3.0));
      },
    );

    test('validation uses shared area or room dimensions message', () {
      final error = calculator.validateInputs({
        'inputMode': 0.0,
        'area': 0.0,
        'wallArea': 0.0,
        'ceilingArea': 0.0,
        'roomWidth': 0.0,
        'roomLength': 0.0,
        'roomHeight': 0.0,
        'layers': 2.0,
      });

      expect(error, equals('Необходимо указать площадь или размеры помещения'));
    });
  });
}
