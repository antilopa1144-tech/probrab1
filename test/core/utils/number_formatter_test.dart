import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/utils/number_formatter.dart';

void main() {
  group('NumberFormatter', () {
    group('formatWithThousandsSeparator', () {
      test('форматирует число с разделителями тысяч', () {
        expect(NumberFormatter.formatWithThousandsSeparator(1000), equals('1 000'));
        expect(NumberFormatter.formatWithThousandsSeparator(10000), equals('10 000'));
        expect(NumberFormatter.formatWithThousandsSeparator(100000), equals('100 000'));
        expect(NumberFormatter.formatWithThousandsSeparator(1000000), equals('1 000 000'));
      });

      test('не добавляет разделитель для чисел меньше 1000', () {
        expect(NumberFormatter.formatWithThousandsSeparator(0), equals('0'));
        expect(NumberFormatter.formatWithThousandsSeparator(1), equals('1'));
        expect(NumberFormatter.formatWithThousandsSeparator(99), equals('99'));
        expect(NumberFormatter.formatWithThousandsSeparator(999), equals('999'));
      });

      test('сохраняет десятичную часть', () {
        expect(NumberFormatter.formatWithThousandsSeparator(1000.5), equals('1 000.5'));
        expect(NumberFormatter.formatWithThousandsSeparator(10000.123), equals('10 000.123'));
      });

      test('использует кастомный разделитель', () {
        expect(
          NumberFormatter.formatWithThousandsSeparator(1000, separator: ','),
          equals('1,000'),
        );
        expect(
          NumberFormatter.formatWithThousandsSeparator(1000000, separator: '_'),
          equals('1_000_000'),
        );
      });

      test('корректно обрабатывает отрицательные числа', () {
        expect(NumberFormatter.formatWithThousandsSeparator(-1000), equals('-1 000'));
        expect(NumberFormatter.formatWithThousandsSeparator(-1000000), equals('-1 000 000'));
      });

      test('корректно обрабатывает очень большие числа', () {
        expect(
          NumberFormatter.formatWithThousandsSeparator(1000000000000),
          equals('1 000 000 000 000'),
        );
      });
    });

    group('formatCurrency', () {
      test('форматирует валюту с символом рубля по умолчанию', () {
        expect(NumberFormatter.formatCurrency(1000), equals('1 000,00 ₽'));
        expect(NumberFormatter.formatCurrency(10000.50), equals('10 000,50 ₽'));
      });

      test('использует правильные разделители', () {
        expect(NumberFormatter.formatCurrency(1234.56), equals('1 234,56 ₽'));
      });

      test('округляет до указанного количества знаков', () {
        expect(
          NumberFormatter.formatCurrency(1234.567, decimalPlaces: 2),
          equals('1 234,57 ₽'),
        );
        expect(
          NumberFormatter.formatCurrency(1234.56, decimalPlaces: 0),
          equals('1 235 ₽'),
        );
      });

      test('использует кастомный символ валюты', () {
        expect(
          NumberFormatter.formatCurrency(1000, currencySymbol: '\$'),
          equals('1 000,00 \$'),
        );
        expect(
          NumberFormatter.formatCurrency(1000, currencySymbol: '€'),
          equals('1 000,00 €'),
        );
      });

      test('использует кастомные разделители', () {
        expect(
          NumberFormatter.formatCurrency(
            1234.56,
            thousandsSeparator: ',',
            decimalSeparator: '.',
          ),
          equals('1,234.56 ₽'),
        );
      });

      test('корректно обрабатывает отрицательные суммы', () {
        expect(NumberFormatter.formatCurrency(-1000.50), equals('-1 000,50 ₽'));
      });

      test('добавляет нули в десятичной части', () {
        expect(NumberFormatter.formatCurrency(1000.5), equals('1 000,50 ₽'));
        expect(NumberFormatter.formatCurrency(1000), equals('1 000,00 ₽'));
      });

      test('корректно обрабатывает целые числа без десятичных знаков', () {
        expect(
          NumberFormatter.formatCurrency(1000, decimalPlaces: 0),
          equals('1 000 ₽'),
        );
      });
    });

    group('roundToDecimalPlaces', () {
      test('округляет до указанного количества знаков', () {
        expect(NumberFormatter.roundToDecimalPlaces(1.234, 2), equals(1.23));
        expect(NumberFormatter.roundToDecimalPlaces(1.235, 2), equals(1.24));
        expect(NumberFormatter.roundToDecimalPlaces(1.236, 2), equals(1.24));
      });

      test('округляет до целого числа', () {
        expect(NumberFormatter.roundToDecimalPlaces(1.4, 0), equals(1));
        expect(NumberFormatter.roundToDecimalPlaces(1.5, 0), equals(2));
        expect(NumberFormatter.roundToDecimalPlaces(1.6, 0), equals(2));
      });

      test('не изменяет число с меньшим количеством знаков', () {
        expect(NumberFormatter.roundToDecimalPlaces(1.2, 5), equals(1.2));
      });

      test('корректно обрабатывает отрицательные числа', () {
        expect(NumberFormatter.roundToDecimalPlaces(-1.235, 2), equals(-1.24));
      });

      test('корректно обрабатывает ноль', () {
        expect(NumberFormatter.roundToDecimalPlaces(0, 2), equals(0));
        expect(NumberFormatter.roundToDecimalPlaces(0.001, 2), equals(0));
      });
    });

    group('formatDecimal', () {
      test('форматирует число с фиксированным количеством знаков', () {
        expect(NumberFormatter.formatDecimal(1.2), equals('1.20'));
        expect(NumberFormatter.formatDecimal(1.234), equals('1.23'));
        expect(NumberFormatter.formatDecimal(1.236), equals('1.24'));
      });

      test('использует кастомное количество знаков', () {
        expect(NumberFormatter.formatDecimal(1.23456, decimalPlaces: 3), equals('1.235'));
        expect(NumberFormatter.formatDecimal(1.23456, decimalPlaces: 0), equals('1'));
      });

      test('использует кастомный разделитель', () {
        expect(
          NumberFormatter.formatDecimal(1.23, decimalSeparator: ','),
          equals('1,23'),
        );
      });

      test('добавляет нули после запятой', () {
        expect(NumberFormatter.formatDecimal(1), equals('1.00'));
        expect(NumberFormatter.formatDecimal(1.5), equals('1.50'));
      });

      test('корректно обрабатывает отрицательные числа', () {
        expect(NumberFormatter.formatDecimal(-1.23), equals('-1.23'));
      });
    });

    group('formatPercentage', () {
      test('форматирует процент из десятичной дроби', () {
        expect(NumberFormatter.formatPercentage(0.15), equals('15%'));
        expect(NumberFormatter.formatPercentage(0.5), equals('50%'));
        expect(NumberFormatter.formatPercentage(1), equals('100%'));
      });

      test('использует кастомное количество десятичных знаков', () {
        expect(NumberFormatter.formatPercentage(0.155, decimalPlaces: 1), equals('15.5%'));
        expect(NumberFormatter.formatPercentage(0.1555, decimalPlaces: 2), equals('15.55%'));
      });

      test('может исключать символ процента', () {
        expect(
          NumberFormatter.formatPercentage(0.15, includeSymbol: false),
          equals('15'),
        );
      });

      test('корректно обрабатывает значения больше 1', () {
        expect(NumberFormatter.formatPercentage(1.5), equals('150%'));
        expect(NumberFormatter.formatPercentage(2), equals('200%'));
      });

      test('корректно обрабатывает отрицательные значения', () {
        expect(NumberFormatter.formatPercentage(-0.15), equals('-15%'));
      });

      test('корректно обрабатывает ноль', () {
        expect(NumberFormatter.formatPercentage(0), equals('0%'));
      });
    });

    group('formatCompact', () {
      test('не изменяет числа меньше 1000', () {
        expect(NumberFormatter.formatCompact(0), equals('0'));
        expect(NumberFormatter.formatCompact(1), equals('1'));
        expect(NumberFormatter.formatCompact(999), equals('999'));
        expect(NumberFormatter.formatCompact(-999), equals('-999'));
      });

      test('форматирует тысячи с суффиксом K', () {
        expect(NumberFormatter.formatCompact(1000), equals('1.0K'));
        expect(NumberFormatter.formatCompact(1500), equals('1.5K'));
        expect(NumberFormatter.formatCompact(10000), equals('10.0K'));
        expect(NumberFormatter.formatCompact(999999), equals('1000.0K'));
      });

      test('форматирует миллионы с суффиксом M', () {
        expect(NumberFormatter.formatCompact(1000000), equals('1.0M'));
        expect(NumberFormatter.formatCompact(1500000), equals('1.5M'));
        expect(NumberFormatter.formatCompact(10000000), equals('10.0M'));
      });

      test('форматирует миллиарды с суффиксом B', () {
        expect(NumberFormatter.formatCompact(1000000000), equals('1.0B'));
        expect(NumberFormatter.formatCompact(1500000000), equals('1.5B'));
      });

      test('использует кастомное количество десятичных знаков', () {
        expect(NumberFormatter.formatCompact(1500, decimalPlaces: 0), equals('2K'));
        expect(NumberFormatter.formatCompact(1500, decimalPlaces: 2), equals('1.50K'));
      });

      test('корректно обрабатывает отрицательные числа', () {
        expect(NumberFormatter.formatCompact(-1000), equals('-1.0K'));
        expect(NumberFormatter.formatCompact(-1000000), equals('-1.0M'));
      });
    });

    group('parseNumber', () {
      test('парсит число из строки с разделителями', () {
        expect(NumberFormatter.parseNumber('1 000'), equals(1000));
        expect(NumberFormatter.parseNumber('10 000'), equals(10000));
        expect(NumberFormatter.parseNumber('1 000 000'), equals(1000000));
      });

      test('парсит число с десятичной точкой', () {
        expect(NumberFormatter.parseNumber('1 234.56'), equals(1234.56));
      });

      test('парсит число с запятой как десятичным разделителем', () {
        expect(NumberFormatter.parseNumber('1 234,56'), equals(1234.56));
      });

      test('парсит число без разделителей', () {
        expect(NumberFormatter.parseNumber('1000'), equals(1000));
        expect(NumberFormatter.parseNumber('1234.56'), equals(1234.56));
      });

      test('использует кастомный разделитель', () {
        expect(NumberFormatter.parseNumber('1,000', separator: ','), equals(1000));
        expect(NumberFormatter.parseNumber('1_000', separator: '_'), equals(1000));
      });

      test('обрабатывает пробелы в начале и конце', () {
        expect(NumberFormatter.parseNumber('  1 000  '), equals(1000));
      });

      test('парсит отрицательные числа', () {
        expect(NumberFormatter.parseNumber('-1 000'), equals(-1000));
        expect(NumberFormatter.parseNumber('-1 234.56'), equals(-1234.56));
      });

      test('возвращает null для некорректной строки', () {
        expect(NumberFormatter.parseNumber('abc'), isNull);
        expect(NumberFormatter.parseNumber(''), isNull);
        expect(NumberFormatter.parseNumber('1,000,000.50.25'), isNull);
      });

      test('парсит ноль', () {
        expect(NumberFormatter.parseNumber('0'), equals(0));
        expect(NumberFormatter.parseNumber('0.0'), equals(0));
      });
    });

    group('parseCurrency', () {
      test('парсит валюту с символом рубля', () {
        expect(NumberFormatter.parseCurrency('1 000 ₽'), equals(1000));
        expect(NumberFormatter.parseCurrency('1 234,56 ₽'), equals(1234.56));
      });

      test('парсит валюту с кастомным символом', () {
        expect(
          NumberFormatter.parseCurrency(
            '1,000 \$',
            currencySymbol: '\$',
            thousandsSeparator: ',',
          ),
          equals(1000),
        );
        expect(NumberFormatter.parseCurrency('1 000 €', currencySymbol: '€'), equals(1000));
      });

      test('использует кастомные разделители', () {
        expect(
          NumberFormatter.parseCurrency(
            '1,234.56 \$',
            currencySymbol: '\$',
            thousandsSeparator: ',',
            decimalSeparator: '.',
          ),
          equals(1234.56),
        );
      });

      test('обрабатывает пробелы', () {
        expect(NumberFormatter.parseCurrency('  1 000 ₽  '), equals(1000));
      });

      test('парсит отрицательные суммы', () {
        expect(NumberFormatter.parseCurrency('-1 000 ₽'), equals(-1000));
      });

      test('возвращает null для некорректной строки', () {
        expect(NumberFormatter.parseCurrency('abc'), isNull);
        expect(NumberFormatter.parseCurrency(''), isNull);
      });

      test('парсит валюту без разделителей', () {
        expect(NumberFormatter.parseCurrency('1000₽'), equals(1000));
      });

      test('парсит ноль', () {
        expect(NumberFormatter.parseCurrency('0 ₽'), equals(0));
        expect(NumberFormatter.parseCurrency('0,00 ₽'), equals(0));
      });
    });

    group('граничные случаи', () {
      test('корректно обрабатывает очень большие числа', () {
        const veryLarge = 999999999999.99;
        final formatted = NumberFormatter.formatWithThousandsSeparator(veryLarge);
        expect(formatted, contains('999 999 999 999'));
      });

      test('корректно обрабатывает очень малые числа', () {
        expect(NumberFormatter.formatDecimal(0.001), equals('0.00'));
        expect(NumberFormatter.formatDecimal(0.001, decimalPlaces: 3), equals('0.001'));
      });

      test('корректно округляет числа', () {
        expect(NumberFormatter.roundToDecimalPlaces(1.4, 0), equals(1));
        expect(NumberFormatter.roundToDecimalPlaces(1.6, 0), equals(2));
        expect(NumberFormatter.roundToDecimalPlaces(2.5, 0), closeTo(2, 1));
      });

      test('корректно обрабатывает специальные значения', () {
        // Infinity, NaN и другие специальные значения обрабатываются корректно
        final infinity = NumberFormatter.formatWithThousandsSeparator(double.infinity);
        final negInfinity = NumberFormatter.formatWithThousandsSeparator(double.negativeInfinity);
        final nan = NumberFormatter.formatWithThousandsSeparator(double.nan);

        expect(infinity, isNotEmpty);
        expect(negInfinity, isNotEmpty);
        expect(nan, isNotEmpty);
      });
    });

    group('интеграционные тесты', () {
      test('форматирование и парсинг валюты сохраняют значение', () {
        const original = 1234.56;
        final formatted = NumberFormatter.formatCurrency(original);
        final parsed = NumberFormatter.parseCurrency(formatted);

        expect(parsed, equals(original));
      });

      test('форматирование и парсинг числа сохраняют значение', () {
        const original = 1234567.89;
        final formatted = NumberFormatter.formatWithThousandsSeparator(original);
        final parsed = NumberFormatter.parseNumber(formatted);

        expect(parsed, equals(original));
      });

      test('различные форматы валют', () {
        const amount = 1234.56;

        // Рубли
        expect(
          NumberFormatter.formatCurrency(amount),
          equals('1 234,56 ₽'),
        );

        // Доллары
        expect(
          NumberFormatter.formatCurrency(
            amount,
            currencySymbol: '\$',
            thousandsSeparator: ',',
            decimalSeparator: '.',
          ),
          equals('1,234.56 \$'),
        );

        // Евро
        expect(
          NumberFormatter.formatCurrency(amount, currencySymbol: '€'),
          equals('1 234,56 €'),
        );
      });

      test('комплексный сценарий с валютой', () {
        // Создать сумму
        const amount = 15678.9;

        // Отформатировать как валюту
        final formatted = NumberFormatter.formatCurrency(amount);
        expect(formatted, equals('15 678,90 ₽'));

        // Распарсить обратно
        final parsed = NumberFormatter.parseCurrency(formatted);
        expect(parsed, equals(amount));

        // Отформатировать компактно
        final compact = NumberFormatter.formatCompact(amount);
        expect(compact, equals('15.7K'));
      });
    });

    group('производительность', () {
      test('быстро обрабатывает множество чисел', () {
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 1000; i++) {
          NumberFormatter.formatWithThousandsSeparator(i * 1000);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });

      test('быстро обрабатывает валюту', () {
        final stopwatch = Stopwatch()..start();

        for (var i = 0; i < 1000; i++) {
          NumberFormatter.formatCurrency(i * 100.5);
        }

        stopwatch.stop();
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      });
    });
  });
}
