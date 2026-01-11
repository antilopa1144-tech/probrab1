import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/utils/russian_number_parser.dart';

void main() {
  group('RussianNumberParser - Единицы (0-9)', () {
    test('парсит ноль', () {
      expect(RussianNumberParser.parse('ноль'), 0.0);
    });

    test('парсит один/одна', () {
      expect(RussianNumberParser.parse('один'), 1.0);
      expect(RussianNumberParser.parse('одна'), 1.0);
    });

    test('парсит два/две', () {
      expect(RussianNumberParser.parse('два'), 2.0);
      expect(RussianNumberParser.parse('две'), 2.0);
    });

    test('парсит цифры 3-9', () {
      expect(RussianNumberParser.parse('три'), 3.0);
      expect(RussianNumberParser.parse('четыре'), 4.0);
      expect(RussianNumberParser.parse('пять'), 5.0);
      expect(RussianNumberParser.parse('шесть'), 6.0);
      expect(RussianNumberParser.parse('семь'), 7.0);
      expect(RussianNumberParser.parse('восемь'), 8.0);
      expect(RussianNumberParser.parse('девять'), 9.0);
    });
  });

  group('RussianNumberParser - Числа 10-19', () {
    test('парсит десять', () {
      expect(RussianNumberParser.parse('десять'), 10.0);
    });

    test('парсит 11-19', () {
      expect(RussianNumberParser.parse('одиннадцать'), 11.0);
      expect(RussianNumberParser.parse('двенадцать'), 12.0);
      expect(RussianNumberParser.parse('тринадцать'), 13.0);
      expect(RussianNumberParser.parse('четырнадцать'), 14.0);
      expect(RussianNumberParser.parse('пятнадцать'), 15.0);
      expect(RussianNumberParser.parse('шестнадцать'), 16.0);
      expect(RussianNumberParser.parse('семнадцать'), 17.0);
      expect(RussianNumberParser.parse('восемнадцать'), 18.0);
      expect(RussianNumberParser.parse('девятнадцать'), 19.0);
    });
  });

  group('RussianNumberParser - Десятки (20-90)', () {
    test('парсит круглые десятки', () {
      expect(RussianNumberParser.parse('двадцать'), 20.0);
      expect(RussianNumberParser.parse('тридцать'), 30.0);
      expect(RussianNumberParser.parse('сорок'), 40.0);
      expect(RussianNumberParser.parse('пятьдесят'), 50.0);
      expect(RussianNumberParser.parse('шестьдесят'), 60.0);
      expect(RussianNumberParser.parse('семьдесят'), 70.0);
      expect(RussianNumberParser.parse('восемьдесят'), 80.0);
      expect(RussianNumberParser.parse('девяносто'), 90.0);
    });

    test('парсит составные числа 21-99', () {
      expect(RussianNumberParser.parse('двадцать один'), 21.0);
      expect(RussianNumberParser.parse('тридцать пять'), 35.0);
      expect(RussianNumberParser.parse('сорок два'), 42.0);
      expect(RussianNumberParser.parse('пятьдесят семь'), 57.0);
      expect(RussianNumberParser.parse('девяносто девять'), 99.0);
    });
  });

  group('RussianNumberParser - Сотни (100-900)', () {
    test('парсит круглые сотни', () {
      expect(RussianNumberParser.parse('сто'), 100.0);
      expect(RussianNumberParser.parse('двести'), 200.0);
      expect(RussianNumberParser.parse('триста'), 300.0);
      expect(RussianNumberParser.parse('четыреста'), 400.0);
      expect(RussianNumberParser.parse('пятьсот'), 500.0);
      expect(RussianNumberParser.parse('шестьсот'), 600.0);
      expect(RussianNumberParser.parse('семьсот'), 700.0);
      expect(RussianNumberParser.parse('восемьсот'), 800.0);
      expect(RussianNumberParser.parse('девятьсот'), 900.0);
    });

    test('парсит составные числа с сотнями', () {
      expect(RussianNumberParser.parse('сто двадцать три'), 123.0);
      expect(RussianNumberParser.parse('двести пятьдесят'), 250.0);
      expect(RussianNumberParser.parse('триста сорок пять'), 345.0);
      expect(RussianNumberParser.parse('пятьсот шестьдесят семь'), 567.0);
      expect(RussianNumberParser.parse('девятьсот девяносто девять'), 999.0);
    });
  });

  group('RussianNumberParser - Специальные дроби', () {
    test('парсит половину/полтора', () {
      expect(RussianNumberParser.parse('половина'), 0.5);
      expect(RussianNumberParser.parse('половину'), 0.5);
      expect(RussianNumberParser.parse('полтора'), 1.5);
      expect(RussianNumberParser.parse('полторы'), 1.5);
    });

    test('парсит четверть/треть', () {
      expect(RussianNumberParser.parse('четверть'), 0.25);
      expect(RussianNumberParser.parse('треть'), 0.33);
    });
  });

  group('RussianNumberParser - "X с половиной/четвертью"', () {
    test('парсит "число с половиной"', () {
      expect(RussianNumberParser.parse('три с половиной'), 3.5);
      expect(RussianNumberParser.parse('пять с половиной'), 5.5);
      expect(RussianNumberParser.parse('десять с половиной'), 10.5);
      expect(RussianNumberParser.parse('двадцать с половиной'), 20.5);
    });

    test('парсит "число со половиной" (вариант "со")', () {
      expect(RussianNumberParser.parse('три со половиной'), 3.5);
    });

    test('парсит "число с четвертью"', () {
      expect(RussianNumberParser.parse('три с четвертью'), 3.25);
      expect(RussianNumberParser.parse('пять с четвертью'), 5.25);
    });

    test('парсит "число с третью"', () {
      expect(RussianNumberParser.parse('два с третью'), closeTo(2.33, 0.01));
    });
  });

  group('RussianNumberParser - Десятичные дроби', () {
    test('парсит "X целых Y десятых"', () {
      expect(RussianNumberParser.parse('три целых пять десятых'), 3.5);
      expect(RussianNumberParser.parse('два целых три десятых'), 2.3);
      expect(RussianNumberParser.parse('десять целых семь десятых'), 10.7);
    });

    test('парсит "X целых Y сотых"', () {
      expect(RussianNumberParser.parse('три целых сорок пять сотых'), 3.45);
      expect(RussianNumberParser.parse('пять целых двадцать пять сотых'), 5.25);
      expect(RussianNumberParser.parse('один целая пять сотых'), 1.05);
    });

    test('парсит "X целых Y тысячных"', () {
      expect(
        RussianNumberParser.parse('два целых сто двадцать три тысячных'),
        2.123,
      );
    });
  });

  group('RussianNumberParser - С единицами измерения', () {
    test('парсит "X метра Y" как X.Y', () {
      expect(RussianNumberParser.parseWithUnit('три метра сорок пять'), 3.45);
      expect(RussianNumberParser.parseWithUnit('пять метров двадцать'), 5.2);
      expect(RussianNumberParser.parseWithUnit('десять метров пять'), 10.5);
    });

    test('парсит "X метра" как X.0', () {
      expect(RussianNumberParser.parseWithUnit('три метра'), 3.0);
      expect(RussianNumberParser.parseWithUnit('пять метров'), 5.0);
    });

    test('парсит с сантиметрами', () {
      expect(
        RussianNumberParser.parseWithUnit('два сантиметра пять'),
        2.5,
      );
    });

    test('парсит с миллиметрами', () {
      expect(
        RussianNumberParser.parseWithUnit('четыре миллиметра семь'),
        4.7,
      );
    });
  });

  group('RussianNumberParser - parseAny (универсальный)', () {
    test('парсит все форматы', () {
      expect(RussianNumberParser.parseAny('три'), 3.0);
      expect(RussianNumberParser.parseAny('три с половиной'), 3.5);
      expect(RussianNumberParser.parseAny('три целых сорок пять сотых'), 3.45);
      expect(RussianNumberParser.parseAny('три метра сорок пять'), 3.45);
    });

    test('парсит обычные числа', () {
      expect(RussianNumberParser.parseAny('3'), 3.0);
      expect(RussianNumberParser.parseAny('3.5'), 3.5);
      expect(RussianNumberParser.parseAny('3.45'), 3.45);
    });
  });

  group('RussianNumberParser - Игнорирование лишних слов', () {
    test('игнорирует единицы измерения в середине', () {
      expect(RussianNumberParser.parse('три квадратных метра'), 3.0);
      expect(RussianNumberParser.parse('пять кубических метров'), 5.0);
    });

    test('игнорирует союзы', () {
      expect(RussianNumberParser.parse('три и пять'), isNotNull);
      expect(RussianNumberParser.parse('два со половиной'), 2.5);
    });
  });

  group('RussianNumberParser - Проверки', () {
    test('containsRussianNumber возвращает true для русских чисел', () {
      expect(RussianNumberParser.containsRussianNumber('три'), true);
      expect(RussianNumberParser.containsRussianNumber('двадцать пять'), true);
      expect(RussianNumberParser.containsRussianNumber('половина'), true);
      expect(RussianNumberParser.containsRussianNumber('три целых пять'), true);
    });

    test('containsRussianNumber возвращает false для обычного текста', () {
      expect(RussianNumberParser.containsRussianNumber('hello'), false);
      expect(RussianNumberParser.containsRussianNumber('test'), false);
    });
  });

  group('RussianNumberParser - Граничные случаи', () {
    test('возвращает null для пустой строки', () {
      expect(RussianNumberParser.parse(''), null);
      expect(RussianNumberParser.parse('   '), null);
    });

    test('возвращает null для нераспознанного текста', () {
      expect(RussianNumberParser.parse('абракадабра'), null);
      expect(RussianNumberParser.parse('hello world'), null);
    });

    test('работает с разным регистром', () {
      expect(RussianNumberParser.parse('ТРИ'), 3.0);
      expect(RussianNumberParser.parse('Три'), 3.0);
      expect(RussianNumberParser.parse('тРи'), 3.0);
    });

    test('работает с лишними пробелами', () {
      expect(RussianNumberParser.parse('  три  '), 3.0);
      expect(RussianNumberParser.parseWithUnit('три   метра   сорок   пять'), 3.45);
    });
  });

  group('RussianNumberParser - Реальные примеры использования', () {
    test('сценарий: пользователь говорит размеры комнаты', () {
      expect(RussianNumberParser.parseWithUnit('три метра сорок'), 3.4);
      expect(RussianNumberParser.parseWithUnit('четыре метра двадцать пять'), 4.25);
      expect(RussianNumberParser.parseWithUnit('два метра восемьдесят'), 2.8);
    });

    test('сценарий: пользователь говорит высоту потолка', () {
      expect(RussianNumberParser.parseAny('два с половиной'), 2.5);
      expect(RussianNumberParser.parseAny('три целых пять десятых'), 3.5);
    });

    test('сценарий: пользователь говорит площадь', () {
      expect(RussianNumberParser.parse('двадцать пять'), 25.0);
      expect(RussianNumberParser.parse('пятьдесят'), 50.0);
      expect(RussianNumberParser.parse('сто двадцать'), 120.0);
    });
  });
}
