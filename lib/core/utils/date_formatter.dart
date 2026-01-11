/// Утилита для форматирования дат
class DateFormatter {
  /// Форматировать дату в формате DD.MM.YYYY
  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// Форматировать дату и время в формате DD.MM.YYYY HH:MM
  static String formatDateTime(DateTime date) {
    return '${formatDate(date)} ${formatTime(date)}';
  }

  /// Форматировать только время в формате HH:MM
  static String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Форматировать дату в формате YYYYMMDD для имён файлов
  static String formatDateForFilename(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  }

  /// Форматировать время в формате HHMM для имён файлов
  static String formatTimeForFilename(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  /// Форматировать дату в относительном формате (например, "2 часа назад")
  static String formatRelative(DateTime date, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final difference = current.difference(date);

    if (difference.inSeconds < 60) {
      return 'только что';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return _pluralizeMinutes(minutes);
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return _pluralizeHours(hours);
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return _pluralizeDays(days);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return _pluralizeWeeks(weeks);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return _pluralizeMonths(months);
    } else {
      final years = (difference.inDays / 365).floor();
      return _pluralizeYears(years);
    }
  }

  /// Парсить дату из строки в формате DD.MM.YYYY
  static DateTime? parseDate(String dateString) {
    try {
      final parts = dateString.split('.');
      if (parts.length != 3) return null;

      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);

      if (day == null || month == null || year == null) return null;
      if (day < 1 || day > 31) return null;
      if (month < 1 || month > 12) return null;
      if (year < 1900 || year > 2100) return null;

      return DateTime(year, month, day);
    } catch (_) {
      return null;
    }
  }

  /// Парсить дату и время из строки в формате DD.MM.YYYY HH:MM
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      final parts = dateTimeString.split(' ');
      if (parts.length != 2) return null;

      final date = parseDate(parts[0]);
      if (date == null) return null;

      final timeParts = parts[1].split(':');
      if (timeParts.length != 2) return null;

      final hour = int.tryParse(timeParts[0]);
      final minute = int.tryParse(timeParts[1]);

      if (hour == null || minute == null) return null;
      if (hour < 0 || hour > 23) return null;
      if (minute < 0 || minute > 59) return null;

      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static String _pluralizeMinutes(int minutes) {
    final suffix = _getRussianPluralSuffix(minutes, 'минуту', 'минуты', 'минут');
    return '$minutes $suffix назад';
  }

  static String _pluralizeHours(int hours) {
    final suffix = _getRussianPluralSuffix(hours, 'час', 'часа', 'часов');
    return '$hours $suffix назад';
  }

  static String _pluralizeDays(int days) {
    final suffix = _getRussianPluralSuffix(days, 'день', 'дня', 'дней');
    return '$days $suffix назад';
  }

  static String _pluralizeWeeks(int weeks) {
    final suffix = _getRussianPluralSuffix(weeks, 'неделю', 'недели', 'недель');
    return '$weeks $suffix назад';
  }

  static String _pluralizeMonths(int months) {
    final suffix = _getRussianPluralSuffix(months, 'месяц', 'месяца', 'месяцев');
    return '$months $suffix назад';
  }

  static String _pluralizeYears(int years) {
    final suffix = _getRussianPluralSuffix(years, 'год', 'года', 'лет');
    return '$years $suffix назад';
  }

  /// Получить правильное окончание для русского языка
  static String _getRussianPluralSuffix(
    int number,
    String one,
    String few,
    String many,
  ) {
    final mod10 = number % 10;
    final mod100 = number % 100;

    if (mod100 >= 11 && mod100 <= 19) {
      return many;
    }

    if (mod10 == 1) {
      return one;
    }

    if (mod10 >= 2 && mod10 <= 4) {
      return few;
    }

    return many;
  }
}
