// Парсер для преобразования русских числительных в числа

/// Парсер русских числительных в числовые значения
class RussianNumberParser {
  // Единицы (0-9)
  static const Map<String, int> _units = {
    'ноль': 0,
    'один': 1,
    'одна': 1,
    'два': 2,
    'две': 2,
    'три': 3,
    'четыре': 4,
    'пять': 5,
    'шесть': 6,
    'семь': 7,
    'восемь': 8,
    'девять': 9,
  };

  // Числа 10-19
  static const Map<String, int> _teens = {
    'десять': 10,
    'одиннадцать': 11,
    'двенадцать': 12,
    'тринадцать': 13,
    'четырнадцать': 14,
    'пятнадцать': 15,
    'шестнадцать': 16,
    'семнадцать': 17,
    'восемнадцать': 18,
    'девятнадцать': 19,
  };

  // Десятки (20-90)
  static const Map<String, int> _tens = {
    'двадцать': 20,
    'тридцать': 30,
    'сорок': 40,
    'пятьдесят': 50,
    'шестьдесят': 60,
    'семьдесят': 70,
    'восемьдесят': 80,
    'девяносто': 90,
  };

  // Сотни (100-900)
  static const Map<String, int> _hundreds = {
    'сто': 100,
    'двести': 200,
    'триста': 300,
    'четыреста': 400,
    'пятьсот': 500,
    'шестьсот': 600,
    'семьсот': 700,
    'восемьсот': 800,
    'девятьсот': 900,
  };

  // Специальные дробные числа (все склонения)
  static const Map<String, double> _specialFractions = {
    'половина': 0.5,
    'половину': 0.5,
    'половиной': 0.5,
    'половины': 0.5,
    'полтора': 1.5,
    'полторы': 1.5,
    'четверть': 0.25,
    'четвертью': 0.25,
    'четверти': 0.25,
    'треть': 0.33,
    'третью': 0.33,
    'трети': 0.33,
  };

  // Слова для дробей
  static const _decimalSeparators = ['целых', 'целая', 'целое'];
  static const Map<String, int> _decimalDenominators = {
    'десятая': 10,
    'десятых': 10,
    'сотая': 100,
    'сотых': 100,
    'тысячная': 1000,
    'тысячных': 1000,
  };

  // Игнорируемые слова (единицы измерения и соединительные)
  static const _ignoredWords = {
    'метр',
    'метра',
    'метров',
    'сантиметр',
    'сантиметра',
    'сантиметров',
    'миллиметр',
    'миллиметра',
    'миллиметров',
    'квадратный',
    'квадратных',
    'кубический',
    'кубических',
    'и',
    'с',
    'со',
  };

  /// Парсит русский текст с числительными в double
  ///
  /// Примеры:
  /// - "три" → 3.0
  /// - "двадцать пять" → 25.0
  /// - "три с половиной" → 3.5
  /// - "три целых сорок пять сотых" → 3.45
  /// - "три метра сорок пять" → 3.45
  static double? parse(String text) {
    if (text.trim().isEmpty) return null;

    // Нормализация текста
    final normalized = text.toLowerCase().trim();

    // Попытка парсинга как обычного числа
    final directNumber = double.tryParse(normalized);
    if (directNumber != null) return directNumber;

    // Разбиваем на слова
    final words = normalized.split(RegExp(r'\s+'));

    // Проверка на специальные дроби
    if (words.length == 1 && _specialFractions.containsKey(words[0])) {
      return _specialFractions[words[0]];
    }

    // Проверка на формат "X с половиной/четвертью"
    final withFractionMatch = _parseWithFraction(words);
    if (withFractionMatch != null) return withFractionMatch;

    // Проверка на формат "X целых Y десятых/сотых/тысячных"
    final decimalMatch = _parseDecimal(words);
    if (decimalMatch != null) return decimalMatch;

    // Парсинг целого числа
    final integerValue = _parseInteger(words);
    if (integerValue != null) return integerValue.toDouble();

    return null;
  }

  /// Парсит целое число из списка слов
  static int? _parseInteger(List<String> words) {
    var result = 0;
    var currentNumber = 0;
    var foundAny = false; // Флаг: нашли ли хоть одно распознанное слово

    for (final word in words) {
      // Пропускаем игнорируемые слова
      if (_ignoredWords.contains(word)) continue;

      // Проверяем сотни
      if (_hundreds.containsKey(word)) {
        currentNumber += _hundreds[word]!;
        foundAny = true;
        continue;
      }

      // Проверяем десятки
      if (_tens.containsKey(word)) {
        currentNumber += _tens[word]!;
        foundAny = true;
        continue;
      }

      // Проверяем числа 10-19
      if (_teens.containsKey(word)) {
        currentNumber += _teens[word]!;
        foundAny = true;
        continue;
      }

      // Проверяем единицы
      if (_units.containsKey(word)) {
        currentNumber += _units[word]!;
        foundAny = true;
        continue;
      }

      // Если встретили тысячи
      if (word == 'тысяча' || word == 'тысячи' || word == 'тысяч') {
        result += (currentNumber == 0 ? 1 : currentNumber) * 1000;
        currentNumber = 0;
        foundAny = true;
        continue;
      }

      // Если встретили миллионы
      if (word == 'миллион' || word == 'миллиона' || word == 'миллионов') {
        result += (currentNumber == 0 ? 1 : currentNumber) * 1000000;
        currentNumber = 0;
        foundAny = true;
        continue;
      }
    }

    result += currentNumber;

    // Возвращаем результат только если нашли хотя бы одно распознанное слово
    return foundAny ? result : null;
  }

  /// Парсит число в формате "X с половиной/четвертью"
  static double? _parseWithFraction(List<String> words) {
    // Ищем паттерн: число + "с/со" + дробь
    for (var i = 0; i < words.length - 2; i++) {
      if ((words[i + 1] == 'с' || words[i + 1] == 'со') &&
          _specialFractions.containsKey(words[i + 2])) {
        final integerPart = _parseInteger([words[i]]);
        if (integerPart != null) {
          return integerPart + _specialFractions[words[i + 2]]!;
        }
      }
    }

    // Паттерн без "с": "три половины" → 3.5
    for (var i = 0; i < words.length - 1; i++) {
      if (_specialFractions.containsKey(words[i + 1])) {
        final integerPart = _parseInteger([words[i]]);
        if (integerPart != null) {
          return integerPart + _specialFractions[words[i + 1]]!;
        }
      }
    }

    return null;
  }

  /// Парсит число в формате "X целых Y десятых/сотых"
  static double? _parseDecimal(List<String> words) {
    // Ищем слово "целых"/"целая"/"целое"
    for (var i = 0; i < words.length; i++) {
      if (_decimalSeparators.contains(words[i])) {
        // Целая часть - всё до "целых"
        final integerWords = words.sublist(0, i);
        final integerPart = _parseInteger(integerWords) ?? 0;

        // Дробная часть - после "целых"
        final fractionalWords = words.sublist(i + 1);

        // Ищем знаменатель
        for (final word in fractionalWords) {
          if (_decimalDenominators.containsKey(word)) {
            final denominator = _decimalDenominators[word]!;

            // Числитель - слова между "целых" и знаменателем
            final numeratorWords = fractionalWords
                .takeWhile((w) => !_decimalDenominators.containsKey(w))
                .toList();
            final numerator = _parseInteger(numeratorWords) ?? 0;

            return integerPart + (numerator / denominator);
          }
        }
      }
    }

    return null;
  }

  /// Парсит формат "X метра Y" как X.Y (например, "три метра сорок пять" → 3.45)
  static double? parseWithUnit(String text) {
    final normalized = text.toLowerCase().trim();
    final words = normalized.split(RegExp(r'\s+'));

    // Ищем единицу измерения
    var unitIndex = -1;
    for (var i = 0; i < words.length; i++) {
      if (words[i].startsWith('метр') ||
          words[i].startsWith('сантиметр') ||
          words[i].startsWith('миллиметр')) {
        unitIndex = i;
        break;
      }
    }

    if (unitIndex == -1) return parse(text);

    // Целая часть - до единицы измерения
    final integerWords = words.sublist(0, unitIndex);
    final integerPart = _parseInteger(integerWords) ?? 0;

    // Дробная часть - после единицы измерения
    if (unitIndex < words.length - 1) {
      final fractionalWords = words.sublist(unitIndex + 1);
      final fractionalPart = _parseInteger(fractionalWords) ?? 0;

      if (fractionalPart > 0) {
        // Определяем количество десятичных знаков
        final fractionalDigits = fractionalPart.toString().length;
        final divisor = [1, 10, 100, 1000][fractionalDigits.clamp(0, 3)];
        return integerPart + (fractionalPart / divisor);
      }
    }

    return integerPart.toDouble();
  }

  /// Пытается извлечь число из текста с любым форматом
  static double? parseAny(String text) {
    // Сначала пробуем с единицей измерения
    final withUnit = parseWithUnit(text);
    if (withUnit != null) return withUnit;

    // Затем обычный парсинг
    return parse(text);
  }

  /// Проверяет, содержит ли текст русское числительное
  static bool containsRussianNumber(String text) {
    final normalized = text.toLowerCase();

    return _units.keys.any((key) => normalized.contains(key)) ||
        _teens.keys.any((key) => normalized.contains(key)) ||
        _tens.keys.any((key) => normalized.contains(key)) ||
        _hundreds.keys.any((key) => normalized.contains(key)) ||
        _specialFractions.keys.any((key) => normalized.contains(key)) ||
        _decimalSeparators.any((key) => normalized.contains(key));
  }
}
