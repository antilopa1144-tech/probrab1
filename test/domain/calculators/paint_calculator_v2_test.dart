import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/calculators/paint_calculator_v2.dart';
import 'package:probrab_ai/domain/usecases/base_calculator.dart';

void main() {
  group('PaintCalculatorV2 Logic', () {
    final calculator = paintCalculatorV2.useCase as BaseCalculator;

    test('calculates correctly in "by dimensions" mode', () {
      // --- Arrange ---
      // Калькулятор теперь сам вычисляет area и perimeter из размеров
      const length = 5.0;
      const width = 4.0;
      const height = 2.5;

      final inputs = {
        'inputMode': 0.0, // Режим "по размерам"
        'length': length,
        'width': width,
        'height': height,
        // area и perimeter больше не нужно передавать - калькулятор сам вычислит
        'layers': 2.0,
        'reserve': 10.0, // 10%
        'consumption': 0.1, // 0.1 л/м²
      };

      // --- Act ---
      final result = calculator.calculate(inputs, []);

      // --- Assert ---
      // Expected calculation:
      // area = (5 + 4) * 2 * 2.5 = 45.0
      // perimeter = (5 + 4) * 2 = 18.0
      // usefulArea = 45.0
      // consumption = 0.1
      // layers = 2
      // firstLayer = 0.1 * 1.2 = 0.12
      // otherLayers = (2-1) * 0.1 = 0.1
      // rawPaint = 45.0 * (0.12 + 0.1) = 45.0 * 0.22 = 9.9
      // withReserve = 9.9 * 1.10 = 10.89
      // finalPaint = roundBulk(10.89) = 11
      expect(result.values['paintNeededLiters'], 11);

      // primer: 45.0 * 0.12 * 1.10 = 5.94 -> roundBulk -> 6.0
      expect(result.values['primerNeededLiters'], 6.0);

      // tape: 18.0 * 1.2 * 1.10 = 23.76 -> roundBulk -> 24
      expect(result.values['tapeNeededMeters'], 24);

      // rollers: ceil(45 / 50) = 1
      expect(result.values['rollersNeeded'], 1.0);
    });

    test('calculates correctly in "by area" mode', () {
      // --- Arrange ---
      final inputs = {
        'inputMode': 1.0, // Режим "по площади"
        'area': 100.0,
        'perimeter': 40.0,
        'layers': 2.0,
        'reserve': 5.0, // 5%
        'consumption': 0.12,
      };

      // --- Act ---
      final result = calculator.calculate(inputs, []);

      // --- Assert ---
      // Expected logic:
      // usefulArea = 100.0
      // consumption = 0.12
      // layers = 2
      // firstLayer = 0.12 * 1.2 = 0.144
      // otherLayers = (2-1) * 0.12 = 0.12
      // rawPaint = 100.0 * (0.144 + 0.12) = 100.0 * 0.264 = 26.4
      // withReserve = 26.4 * 1.05 = 27.72
      // finalPaint = roundBulk(27.72) = 28
      expect(result.values['paintNeededLiters'], 28);
    });

    test('handles zero reserve', () {
      // --- Arrange ---
      final inputs = {
        'inputMode': 1.0,
        'area': 10.0,
        'perimeter': 14.0,
        'layers': 1.0,
        'reserve': 0.0, // 0%
        'consumption': 0.1,
      };

      // --- Act ---
      final result = calculator.calculate(inputs, []);

      // --- Assert ---
      // rawPaint = 10.0 * (0.1 * 1.2) = 1.2
      // withReserve = 1.2 * 1.0 = 1.2
      // roundBulk(1.2) = 1.5 (округление до 0.5 для диапазона 1-10)
      expect(result.values['paintNeededLiters'], 1.5);
    });

    test('subtracts openings area correctly', () {
       // --- Arrange ---
      final inputs = {
        'inputMode': 1.0,
        'area': 100.0,
        'perimeter': 40.0,
        'windowsArea': 5.0,
        'doorsArea': 2.5,
        'layers': 1.0,
        'reserve': 0.0,
        'consumption': 0.1,
      };

      // --- Act ---
      final result = calculator.calculate(inputs, []);

      // --- Assert ---
      // usefulArea = 100 - 5 - 2.5 = 92.5
      // roundBulk(92.5) = 93.0 (округление до целых для диапазона 10-100)
      // rawPaint = 92.5 * (0.1 * 1.2) = 11.1
      // roundBulk(11.1) = 12 (округление до целых для диапазона 10-100)
      expect(result.values['usefulArea'], 93.0);
      expect(result.values['paintNeededLiters'], 12);
    });
  });
}
