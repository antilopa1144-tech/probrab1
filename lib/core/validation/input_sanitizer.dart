/// Очистка и нормализация входных данных.
class InputSanitizer {
  /// Очистить строку от лишних символов
  static String sanitizeNumericInput(String input) {
    // Удаляем все кроме цифр, точки, запятой, минуса
    var cleaned = input.replaceAll(RegExp(r'[^\d.,\-]'), '');

    // Заменяем запятую на точку для парсинга
    cleaned = cleaned.replaceAll(',', '.');

    // Обрабатываем знак минуса: допускаем только один ведущий минус
    final isNegative = cleaned.startsWith('-');
    cleaned = cleaned.replaceAll('-', '');
    if (isNegative) {
      cleaned = '-$cleaned';
    }

    // Убираем множественные точки (оставляем только первую)
    final parts = cleaned.split('.');
    if (parts.length > 2) {
      cleaned = '${parts[0]}.${parts.skip(1).join('')}';
    }

    if (cleaned == '-') return '';

    return cleaned;
  }

  /// Форматировать число для отображения.
  ///
  /// По умолчанию использует точку как десятичный разделитель, чтобы
  /// формат был стабильным в тестах и при вводе.
  static String formatNumber(
    double value, {
    int decimals = 2,
    int? maxDecimals,
    bool removeTrailingZeros = true,
  }) {
    final fractionDigits = maxDecimals ?? decimals;
    String formatted = value.toStringAsFixed(fractionDigits);

    if (removeTrailingZeros && formatted.contains('.')) {
      formatted = formatted.replaceAll(RegExp(r'0+$'), '');
      if (formatted.endsWith('.')) {
        formatted = formatted.substring(0, formatted.length - 1);
      }
    }

    return formatted;
  }
  
  /// Распарсить строку в double
  static double? parseDouble(String input) {
    if (input.isEmpty) return null;

    final cleaned = sanitizeNumericInput(input);
    if (cleaned.isEmpty) return null;

    try {
      return double.parse(cleaned);
    } catch (_) {
      return null;
    }
  }

  // ... (остальные хелперы остаются без изменений)
  
  /// Нормализовать значение (привести к допустимому диапазону)
  static double normalizeValue(
    double value, {
    double? min,
    double? max,
    int? decimals,
  }) {
    var normalized = value;

    // Применяем ограничения
    if (min != null && normalized < min) {
      normalized = min;
    }
    if (max != null && normalized > max) {
      normalized = max;
    }

    // Округляем до указанного количества знаков
    if (decimals != null) {
      final factor = _pow10(decimals).toDouble();
      normalized = (normalized * factor).round() / factor;
    }

    return normalized;
  }

  /// Убрать лишние пробелы и символы
  static String trimAndClean(String input) {
    return input.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Проверить, является ли строка корректным числом
  static bool isValidNumber(String input) {
    if (input.isEmpty) return false;

    final cleaned = sanitizeNumericInput(input);
    if (cleaned.isEmpty) return false;

    try {
      double.parse(cleaned);
      return true;
    } catch (_) {
      return false;
    }
  }
  
  /// Округлить до шага
  static double roundToStep(double value, double step) {
    if (step <= 0) return value;
    return (value / step).round() * step;
  }

  /// Ограничить диапазон значений
  static double clamp(double value, double min, double max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  static int _pow10(int exponent) {
    int result = 1;
    for (int i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
