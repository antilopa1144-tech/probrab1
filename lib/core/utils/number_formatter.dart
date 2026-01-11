import 'dart:math' as math;

/// Утилита для форматирования чисел
class NumberFormatter {
  /// Форматировать число с разделителями тысяч (1000 -> "1 000")
  static String formatWithThousandsSeparator(
    num number, {
    String separator = ' ',
  }) {
    final parts = number.toString().split('.');
    final integerPart = parts[0];
    final decimalPart = parts.length > 1 ? parts[1] : null;

    // Добавить разделители в целую часть
    final formattedInteger = _addThousandsSeparator(integerPart, separator);

    if (decimalPart != null) {
      return '$formattedInteger.$decimalPart';
    }

    return formattedInteger;
  }

  /// Форматировать как валюту (1000.50 -> "1 000,50 ₽")
  static String formatCurrency(
    num amount, {
    String currencySymbol = '₽',
    int decimalPlaces = 2,
    String thousandsSeparator = ' ',
    String decimalSeparator = ',',
  }) {
    final rounded = _roundToDecimalPlaces(amount, decimalPlaces);
    final parts = rounded.toString().split('.');

    final integerPart = _addThousandsSeparator(parts[0], thousandsSeparator);
    final decimalPart = parts.length > 1 ? parts[1] : '';

    final formattedDecimal = decimalPart.padRight(decimalPlaces, '0');

    if (decimalPlaces > 0) {
      return '$integerPart$decimalSeparator$formattedDecimal $currencySymbol';
    }

    return '$integerPart $currencySymbol';
  }

  /// Округлить число до указанного количества знаков после запятой
  static double roundToDecimalPlaces(num number, int decimalPlaces) {
    return _roundToDecimalPlaces(number, decimalPlaces);
  }

  /// Форматировать число с фиксированным количеством десятичных знаков
  static String formatDecimal(
    num number, {
    int decimalPlaces = 2,
    String decimalSeparator = '.',
  }) {
    final rounded = _roundToDecimalPlaces(number, decimalPlaces);
    final formatted = rounded.toStringAsFixed(decimalPlaces);

    if (decimalSeparator != '.') {
      return formatted.replaceAll('.', decimalSeparator);
    }

    return formatted;
  }

  /// Форматировать процент (0.15 -> "15%")
  static String formatPercentage(
    num value, {
    int decimalPlaces = 0,
    bool includeSymbol = true,
  }) {
    final percentage = value * 100;
    final rounded = _roundToDecimalPlaces(percentage, decimalPlaces);
    final formatted = rounded.toStringAsFixed(decimalPlaces);

    if (includeSymbol) {
      return '$formatted%';
    }

    return formatted;
  }

  /// Форматировать компактное число (1000 -> "1K", 1000000 -> "1M")
  static String formatCompact(num number, {int decimalPlaces = 1}) {
    if (number.abs() < 1000) {
      return number.toString();
    }

    if (number.abs() < 1000000) {
      final value = number / 1000;
      final rounded = _roundToDecimalPlaces(value, decimalPlaces);
      return '${rounded.toStringAsFixed(decimalPlaces)}K';
    }

    if (number.abs() < 1000000000) {
      final value = number / 1000000;
      final rounded = _roundToDecimalPlaces(value, decimalPlaces);
      return '${rounded.toStringAsFixed(decimalPlaces)}M';
    }

    final value = number / 1000000000;
    final rounded = _roundToDecimalPlaces(value, decimalPlaces);
    return '${rounded.toStringAsFixed(decimalPlaces)}B';
  }

  /// Парсить число из строки с разделителями
  static double? parseNumber(String numberString, {String separator = ' '}) {
    try {
      final cleaned = numberString
          .replaceAll(separator, '')
          .replaceAll(',', '.')
          .trim();
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  /// Парсить валюту из строки
  static double? parseCurrency(
    String currencyString, {
    String currencySymbol = '₽',
    String thousandsSeparator = ' ',
    String decimalSeparator = ',',
  }) {
    try {
      final cleaned = currencyString
          .replaceAll(currencySymbol, '')
          .replaceAll(thousandsSeparator, '')
          .replaceAll(decimalSeparator, '.')
          .trim();
      return double.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  // Приватные методы

  static String _addThousandsSeparator(String number, String separator) {
    final buffer = StringBuffer();
    final length = number.length;

    for (var i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(number[i]);
    }

    return buffer.toString();
  }

  static double _roundToDecimalPlaces(num number, int decimalPlaces) {
    final multiplier = math.pow(10, decimalPlaces);
    return (number * multiplier).round() / multiplier;
  }
}
