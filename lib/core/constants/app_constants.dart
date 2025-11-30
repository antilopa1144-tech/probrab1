/// Основные константы приложения.
class AppConstants {
  // Название приложения
  static const String appName = 'Прораб AI';
  static const String appVersion = '1.0.0';

  // Цвета по умолчанию
  static const int primaryColor = 0xFF121212;
  static const int accentColor = 0xFFFFC107;

  // Поддерживаемые языки
  static const List<String> supportedLanguages = ['ru', 'en'];
  static const String defaultLanguage = 'ru';

  // Настройки по умолчанию
  static const bool defaultDarkMode = true;
  static const String defaultRegion = 'Москва';

  // Регионы для цен
  static const List<String> regions = [
    'Москва',
    'Санкт-Петербург',
    'Екатеринбург',
    'Краснодар',
    'Регионы РФ',
  ];

  // Лимиты и ограничения
  static const int maxProjectNameLength = 100;
  static const int maxCalculationsPerProject = 50;
  static const double maxCalculationArea = 10000.0; // м²
  static const double maxCalculationVolume = 1000.0; // м³

  // Форматирование
  static const int decimalPlaces = 2;
  static const String currencySymbol = '₽';

  // Кэширование
  static const Duration cacheDuration = Duration(hours: 24);
  static const int maxCacheSize = 100;

  // Экспорт
  static const String exportFilePrefix = 'probrab_ai';
  static const String pdfAuthor = 'Прораб AI';
}
