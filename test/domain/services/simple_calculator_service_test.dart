import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/services/simple_calculator_service.dart';

void main() {
  late SimpleCalculatorService calc;

  setUp(() {
    calc = SimpleCalculatorService();
  });

  group('SimpleCalculatorService', () {
    group('Базовые операции', () {
      test('2 + 3 = 5', () {
        calc.inputDigit('2');
        calc.inputOperator('+');
        calc.inputDigit('3');
        calc.calculate();

        expect(calc.displayValue, '5');
      });

      test('10 - 7 = 3', () {
        calc.inputDigit('1');
        calc.inputDigit('0');
        calc.inputOperator('-');
        calc.inputDigit('7');
        calc.calculate();

        expect(calc.displayValue, '3');
      });

      test('6 × 8 = 48', () {
        calc.inputDigit('6');
        calc.inputOperator('×');
        calc.inputDigit('8');
        calc.calculate();

        expect(calc.displayValue, '48');
      });

      test('15 ÷ 4 = 3.75', () {
        calc.inputDigit('1');
        calc.inputDigit('5');
        calc.inputOperator('÷');
        calc.inputDigit('4');
        calc.calculate();

        expect(calc.displayValue, '3.75');
      });
    });

    group('Деление на ноль', () {
      test('5 ÷ 0 = Ошибка', () {
        calc.inputDigit('5');
        calc.inputOperator('÷');
        calc.inputDigit('0');
        calc.calculate();

        expect(calc.displayValue, 'Ошибка');
      });

      test('после ошибки можно начать новый расчёт', () {
        calc.inputDigit('5');
        calc.inputOperator('÷');
        calc.inputDigit('0');
        calc.calculate();
        expect(calc.displayValue, 'Ошибка');

        calc.inputDigit('3');
        expect(calc.displayValue, '3');
      });
    });

    group('Цепочка операций', () {
      test('2 + 3 + 5 = 10 (последовательное вычисление)', () {
        calc.inputDigit('2');
        calc.inputOperator('+');
        calc.inputDigit('3');
        calc.inputOperator('+');
        // Промежуточный: 2+3 = 5
        expect(calc.displayValue, '5');
        calc.inputDigit('5');
        calc.calculate();

        expect(calc.displayValue, '10');
      });

      test('10 - 3 × 2 = 14 (без приоритета, последовательно)', () {
        calc.inputDigit('1');
        calc.inputDigit('0');
        calc.inputOperator('-');
        calc.inputDigit('3');
        calc.inputOperator('×');
        // Промежуточный: 10-3 = 7
        expect(calc.displayValue, '7');
        calc.inputDigit('2');
        calc.calculate();

        expect(calc.displayValue, '14');
      });
    });

    group('Десятичные числа', () {
      test('1.5 + 2.3 = 3.8', () {
        calc.inputDigit('1');
        calc.inputDecimal();
        calc.inputDigit('5');
        calc.inputOperator('+');
        calc.inputDigit('2');
        calc.inputDecimal();
        calc.inputDigit('3');
        calc.calculate();

        expect(calc.displayValue, '3.8');
      });

      test('двойная точка игнорируется', () {
        calc.inputDigit('1');
        calc.inputDecimal();
        calc.inputDecimal(); // вторая точка
        calc.inputDigit('5');

        expect(calc.displayValue, '1.5');
      });

      test('точка в начале → 0.', () {
        calc.inputDecimal();
        expect(calc.displayValue, '0.');
        calc.inputDigit('5');
        expect(calc.displayValue, '0.5');
      });
    });

    group('Clear (C)', () {
      test('полная очистка', () {
        calc.inputDigit('5');
        calc.inputOperator('+');
        calc.inputDigit('3');
        calc.clear();

        expect(calc.displayValue, '0');
        expect(calc.expressionValue, '');
      });
    });

    group('Clear Entry (CE)', () {
      test('сбрасывает только текущее число', () {
        calc.inputDigit('5');
        calc.inputOperator('+');
        calc.inputDigit('3');
        calc.clearEntry();

        expect(calc.displayValue, '0');
        // Выражение остаётся
        expect(calc.expressionValue, '5 +');
      });
    });

    group('Backspace (⌫)', () {
      test('удаляет последнюю цифру', () {
        calc.inputDigit('1');
        calc.inputDigit('2');
        calc.inputDigit('3');
        calc.backspace();

        expect(calc.displayValue, '12');
      });

      test('одна цифра → 0', () {
        calc.inputDigit('5');
        calc.backspace();

        expect(calc.displayValue, '0');
      });

      test('после = не работает', () {
        calc.inputDigit('2');
        calc.inputOperator('+');
        calc.inputDigit('3');
        calc.calculate();
        calc.backspace();

        expect(calc.displayValue, '5'); // не изменился
      });
    });

    group('Toggle Sign (+/-)', () {
      test('положительное → отрицательное', () {
        calc.inputDigit('5');
        calc.toggleSign();

        expect(calc.displayValue, '-5');
      });

      test('отрицательное → положительное', () {
        calc.inputDigit('5');
        calc.toggleSign();
        calc.toggleSign();

        expect(calc.displayValue, '5');
      });

      test('ноль не меняет знак', () {
        calc.toggleSign();
        expect(calc.displayValue, '0');
      });
    });

    group('Percent (%)', () {
      test('200 + 15% = 230 (процент от первого операнда)', () {
        calc.inputDigit('2');
        calc.inputDigit('0');
        calc.inputDigit('0');
        calc.inputOperator('+');
        calc.inputDigit('1');
        calc.inputDigit('5');
        calc.percent();
        // 15% от 200 = 30, дисплей показывает 30
        expect(calc.displayValue, '30');
        calc.calculate();
        // 200 + 30 = 230
        expect(calc.displayValue, '230');
      });

      test('50 без операции → 0.5 (делим на 100)', () {
        calc.inputDigit('5');
        calc.inputDigit('0');
        calc.percent();

        expect(calc.displayValue, '0.5');
      });
    });

    group('Дисплей', () {
      test('начальное состояние — 0', () {
        expect(calc.displayValue, '0');
        expect(calc.expressionValue, '');
      });

      test('ведущие нули не добавляются', () {
        calc.inputDigit('0');
        calc.inputDigit('0');
        calc.inputDigit('5');

        expect(calc.displayValue, '5');
      });

      test('expression отображается при вводе оператора', () {
        calc.inputDigit('5');
        calc.inputOperator('+');

        expect(calc.expressionValue, '5 +');
      });

      test('expression показывает полное выражение после =', () {
        calc.inputDigit('5');
        calc.inputOperator('+');
        calc.inputDigit('3');
        calc.calculate();

        expect(calc.expressionValue, '5 + 3 =');
        expect(calc.displayValue, '8');
      });
    });

    group('После = начинается новый расчёт', () {
      test('ввод цифры после = сбрасывает', () {
        calc.inputDigit('2');
        calc.inputOperator('+');
        calc.inputDigit('3');
        calc.calculate();
        expect(calc.displayValue, '5');

        calc.inputDigit('7');
        expect(calc.displayValue, '7');
        expect(calc.expressionValue, '');
      });
    });

    group('Точка после оператора', () {
      test('оператор → точка → цифра', () {
        calc.inputDigit('5');
        calc.inputOperator('+');
        calc.inputDecimal();
        calc.inputDigit('5');
        calc.calculate();

        expect(calc.displayValue, '5.5');
      });
    });
  });
}
