import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter', () {
    group('formatDate', () {
      test('форматирует дату в формате DD.MM.YYYY', () {
        final date = DateTime(2024, 3, 15);
        expect(DateFormatter.formatDate(date), equals('15.03.2024'));
      });

      test('добавляет ведущие нули для однозначных дней и месяцев', () {
        final date = DateTime(2024, 1, 5);
        expect(DateFormatter.formatDate(date), equals('05.01.2024'));
      });

      test('корректно форматирует последний день года', () {
        final date = DateTime(2023, 12, 31);
        expect(DateFormatter.formatDate(date), equals('31.12.2023'));
      });

      test('корректно форматирует первый день года', () {
        final date = DateTime(2024, 1, 1);
        expect(DateFormatter.formatDate(date), equals('01.01.2024'));
      });
    });

    group('formatDateTime', () {
      test('форматирует дату и время в формате DD.MM.YYYY HH:MM', () {
        final date = DateTime(2024, 3, 15, 14, 30);
        expect(DateFormatter.formatDateTime(date), equals('15.03.2024 14:30'));
      });

      test('добавляет ведущие нули для часов и минут', () {
        final date = DateTime(2024, 1, 5, 9, 5);
        expect(DateFormatter.formatDateTime(date), equals('05.01.2024 09:05'));
      });

      test('корректно форматирует полночь', () {
        final date = DateTime(2024, 6, 15, 0, 0);
        expect(DateFormatter.formatDateTime(date), equals('15.06.2024 00:00'));
      });

      test('корректно форматирует полдень', () {
        final date = DateTime(2024, 6, 15, 12, 0);
        expect(DateFormatter.formatDateTime(date), equals('15.06.2024 12:00'));
      });

      test('корректно форматирует конец дня', () {
        final date = DateTime(2024, 6, 15, 23, 59);
        expect(DateFormatter.formatDateTime(date), equals('15.06.2024 23:59'));
      });
    });

    group('formatTime', () {
      test('форматирует время в формате HH:MM', () {
        final date = DateTime(2024, 1, 1, 14, 30);
        expect(DateFormatter.formatTime(date), equals('14:30'));
      });

      test('добавляет ведущие нули', () {
        final date = DateTime(2024, 1, 1, 9, 5);
        expect(DateFormatter.formatTime(date), equals('09:05'));
      });

      test('корректно форматирует полночь', () {
        final date = DateTime(2024, 1, 1, 0, 0);
        expect(DateFormatter.formatTime(date), equals('00:00'));
      });
    });

    group('formatDateForFilename', () {
      test('форматирует дату в формате YYYYMMDD', () {
        final date = DateTime(2024, 3, 15);
        expect(DateFormatter.formatDateForFilename(date), equals('20240315'));
      });

      test('добавляет ведущие нули', () {
        final date = DateTime(2024, 1, 5);
        expect(DateFormatter.formatDateForFilename(date), equals('20240105'));
      });

      test('корректно форматирует декабрь', () {
        final date = DateTime(2023, 12, 31);
        expect(DateFormatter.formatDateForFilename(date), equals('20231231'));
      });
    });

    group('formatTimeForFilename', () {
      test('форматирует время в формате HHMM', () {
        final date = DateTime(2024, 1, 1, 14, 30);
        expect(DateFormatter.formatTimeForFilename(date), equals('1430'));
      });

      test('добавляет ведущие нули', () {
        final date = DateTime(2024, 1, 1, 9, 5);
        expect(DateFormatter.formatTimeForFilename(date), equals('0905'));
      });

      test('корректно форматирует полночь', () {
        final date = DateTime(2024, 1, 1, 0, 0);
        expect(DateFormatter.formatTimeForFilename(date), equals('0000'));
      });
    });

    group('formatRelative', () {
      test('возвращает "только что" для секунд', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(seconds: 30));
        expect(DateFormatter.formatRelative(date, now: now), equals('только что'));
      });

      test('возвращает "1 минуту назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(minutes: 1));
        expect(DateFormatter.formatRelative(date, now: now), equals('1 минуту назад'));
      });

      test('возвращает "2 минуты назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(minutes: 2));
        expect(DateFormatter.formatRelative(date, now: now), equals('2 минуты назад'));
      });

      test('возвращает "5 минут назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(minutes: 5));
        expect(DateFormatter.formatRelative(date, now: now), equals('5 минут назад'));
      });

      test('возвращает "1 час назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(hours: 1));
        expect(DateFormatter.formatRelative(date, now: now), equals('1 час назад'));
      });

      test('возвращает "2 часа назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(hours: 2));
        expect(DateFormatter.formatRelative(date, now: now), equals('2 часа назад'));
      });

      test('возвращает "5 часов назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(hours: 5));
        expect(DateFormatter.formatRelative(date, now: now), equals('5 часов назад'));
      });

      test('возвращает "1 день назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 1));
        expect(DateFormatter.formatRelative(date, now: now), equals('1 день назад'));
      });

      test('возвращает "2 дня назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 2));
        expect(DateFormatter.formatRelative(date, now: now), equals('2 дня назад'));
      });

      test('возвращает "5 дней назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 5));
        expect(DateFormatter.formatRelative(date, now: now), equals('5 дней назад'));
      });

      test('возвращает "1 неделю назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 7));
        expect(DateFormatter.formatRelative(date, now: now), equals('1 неделю назад'));
      });

      test('возвращает "2 недели назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 14));
        expect(DateFormatter.formatRelative(date, now: now), equals('2 недели назад'));
      });

      test('возвращает "3 недели назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 21));
        expect(DateFormatter.formatRelative(date, now: now), equals('3 недели назад'));
      });

      test('возвращает "1 месяц назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 30));
        expect(DateFormatter.formatRelative(date, now: now), equals('1 месяц назад'));
      });

      test('возвращает "2 месяца назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 60));
        expect(DateFormatter.formatRelative(date, now: now), equals('2 месяца назад'));
      });

      test('возвращает "5 месяцев назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 150));
        expect(DateFormatter.formatRelative(date, now: now), equals('5 месяцев назад'));
      });

      test('возвращает "1 год назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 365));
        expect(DateFormatter.formatRelative(date, now: now), equals('1 год назад'));
      });

      test('возвращает "2 года назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 730));
        expect(DateFormatter.formatRelative(date, now: now), equals('2 года назад'));
      });

      test('возвращает "5 лет назад"', () {
        final now = DateTime.now();
        final date = now.subtract(const Duration(days: 1825));
        expect(DateFormatter.formatRelative(date, now: now), equals('5 лет назад'));
      });

      test('использует текущую дату по умолчанию', () {
        final date = DateTime.now().subtract(const Duration(seconds: 30));
        expect(DateFormatter.formatRelative(date), equals('только что'));
      });
    });

    group('parseDate', () {
      test('парсит корректную дату в формате DD.MM.YYYY', () {
        final date = DateFormatter.parseDate('15.03.2024');
        expect(date, isNotNull);
        expect(date!.day, equals(15));
        expect(date.month, equals(3));
        expect(date.year, equals(2024));
      });

      test('парсит дату с ведущими нулями', () {
        final date = DateFormatter.parseDate('05.01.2024');
        expect(date, isNotNull);
        expect(date!.day, equals(5));
        expect(date.month, equals(1));
        expect(date.year, equals(2024));
      });

      test('возвращает null для некорректного формата', () {
        expect(DateFormatter.parseDate('2024-03-15'), isNull);
        expect(DateFormatter.parseDate('15/03/2024'), isNull);
        expect(DateFormatter.parseDate('15-03-2024'), isNull);
      });

      test('возвращает null для некорректного количества частей', () {
        expect(DateFormatter.parseDate('15.03'), isNull);
        expect(DateFormatter.parseDate('15.03.2024.extra'), isNull);
      });

      test('возвращает null для невалидных чисел', () {
        expect(DateFormatter.parseDate('abc.03.2024'), isNull);
        expect(DateFormatter.parseDate('15.abc.2024'), isNull);
        expect(DateFormatter.parseDate('15.03.abcd'), isNull);
      });

      test('возвращает null для невалидного дня', () {
        expect(DateFormatter.parseDate('0.03.2024'), isNull);
        expect(DateFormatter.parseDate('32.03.2024'), isNull);
      });

      test('возвращает null для невалидного месяца', () {
        expect(DateFormatter.parseDate('15.0.2024'), isNull);
        expect(DateFormatter.parseDate('15.13.2024'), isNull);
      });

      test('возвращает null для невалидного года', () {
        expect(DateFormatter.parseDate('15.03.1899'), isNull);
        expect(DateFormatter.parseDate('15.03.2101'), isNull);
      });

      test('возвращает null для пустой строки', () {
        expect(DateFormatter.parseDate(''), isNull);
      });

      test('возвращает null для некорректных данных', () {
        expect(DateFormatter.parseDate('invalid'), isNull);
      });
    });

    group('parseDateTime', () {
      test('парсит корректную дату и время', () {
        final dateTime = DateFormatter.parseDateTime('15.03.2024 14:30');
        expect(dateTime, isNotNull);
        expect(dateTime!.day, equals(15));
        expect(dateTime.month, equals(3));
        expect(dateTime.year, equals(2024));
        expect(dateTime.hour, equals(14));
        expect(dateTime.minute, equals(30));
      });

      test('парсит дату и время с ведущими нулями', () {
        final dateTime = DateFormatter.parseDateTime('05.01.2024 09:05');
        expect(dateTime, isNotNull);
        expect(dateTime!.day, equals(5));
        expect(dateTime.month, equals(1));
        expect(dateTime.hour, equals(9));
        expect(dateTime.minute, equals(5));
      });

      test('парсит полночь', () {
        final dateTime = DateFormatter.parseDateTime('15.03.2024 00:00');
        expect(dateTime, isNotNull);
        expect(dateTime!.hour, equals(0));
        expect(dateTime.minute, equals(0));
      });

      test('парсит конец дня', () {
        final dateTime = DateFormatter.parseDateTime('15.03.2024 23:59');
        expect(dateTime, isNotNull);
        expect(dateTime!.hour, equals(23));
        expect(dateTime.minute, equals(59));
      });

      test('возвращает null для некорректного формата', () {
        expect(DateFormatter.parseDateTime('15.03.2024'), isNull);
        expect(DateFormatter.parseDateTime('14:30'), isNull);
        expect(DateFormatter.parseDateTime('15.03.2024 14'), isNull);
      });

      test('возвращает null для некорректного разделителя времени', () {
        expect(DateFormatter.parseDateTime('15.03.2024 14.30'), isNull);
        expect(DateFormatter.parseDateTime('15.03.2024 14-30'), isNull);
      });

      test('возвращает null для невалидного часа', () {
        expect(DateFormatter.parseDateTime('15.03.2024 24:00'), isNull);
        expect(DateFormatter.parseDateTime('15.03.2024 -1:00'), isNull);
      });

      test('возвращает null для невалидной минуты', () {
        expect(DateFormatter.parseDateTime('15.03.2024 14:60'), isNull);
        expect(DateFormatter.parseDateTime('15.03.2024 14:-1'), isNull);
      });

      test('возвращает null для пустой строки', () {
        expect(DateFormatter.parseDateTime(''), isNull);
      });
    });

    group('русская плюрализация', () {
      test('правильные окончания для чисел 1, 2-4, 5-20', () {
        final now = DateTime.now();

        // 1 минута
        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(minutes: 1)), now: now),
          equals('1 минуту назад'),
        );

        // 2 минуты
        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(minutes: 2)), now: now),
          equals('2 минуты назад'),
        );

        // 5 минут
        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(minutes: 5)), now: now),
          equals('5 минут назад'),
        );

        // 11 минут (особый случай)
        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(minutes: 11)), now: now),
          equals('11 минут назад'),
        );

        // 21 минута
        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(minutes: 21)), now: now),
          equals('21 минуту назад'),
        );

        // 22 минуты
        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(minutes: 22)), now: now),
          equals('22 минуты назад'),
        );
      });

      test('правильные окончания для часов', () {
        final now = DateTime.now();

        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(hours: 1)), now: now),
          equals('1 час назад'),
        );

        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(hours: 2)), now: now),
          equals('2 часа назад'),
        );

        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(hours: 5)), now: now),
          equals('5 часов назад'),
        );
      });

      test('правильные окончания для дней', () {
        final now = DateTime.now();

        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(days: 1)), now: now),
          equals('1 день назад'),
        );

        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(days: 3)), now: now),
          equals('3 дня назад'),
        );

        expect(
          DateFormatter.formatRelative(now.subtract(const Duration(days: 6)), now: now),
          equals('6 дней назад'),
        );
      });
    });

    group('граничные случаи', () {
      test('корректно обрабатывает високосный год', () {
        final date = DateTime(2024, 2, 29); // 2024 - високосный год
        expect(DateFormatter.formatDate(date), equals('29.02.2024'));
      });

      test('корректно парсит високосный год', () {
        final date = DateFormatter.parseDate('29.02.2024');
        expect(date, isNotNull);
        expect(date!.day, equals(29));
        expect(date.month, equals(2));
      });

      test('корректно форматирует даты на границе столетий', () {
        final date1 = DateTime(1999, 12, 31);
        final date2 = DateTime(2000, 1, 1);

        expect(DateFormatter.formatDate(date1), equals('31.12.1999'));
        expect(DateFormatter.formatDate(date2), equals('01.01.2000'));
      });

      test('корректно обрабатывает очень старые даты', () {
        final date = DateTime(1900, 1, 1);
        expect(DateFormatter.formatDate(date), equals('01.01.1900'));
      });

      test('корректно обрабатывает даты в далёком будущем', () {
        final date = DateTime(2100, 12, 31);
        expect(DateFormatter.formatDate(date), equals('31.12.2100'));
      });
    });
  });
}
