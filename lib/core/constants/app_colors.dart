import 'package:flutter/material.dart';

/// Единый источник цветов для светлой и тёмной тем.
///
/// Использование:
/// ```dart
/// final colors = AppColors.of(context);
/// Text('Hello', style: TextStyle(color: colors.textPrimary));
/// Container(color: colors.cardBackground);
/// ```
///
/// Или через isDark:
/// ```dart
/// final colors = AppColors.resolve(isDark);
/// ```
class AppColors {
  // Не создавать экземпляры напрямую — только через of()/resolve()
  AppColors._();

  /// Получить набор цветов из BuildContext
  static AppColorScheme of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? dark
        : light;
  }

  /// Получить набор цветов по флагу isDark
  static AppColorScheme resolve(bool isDark) {
    return isDark ? dark : light;
  }

  // ═══════════════════════════════════════════════════════
  //  СВЕТЛАЯ ТЕМА
  // ═══════════════════════════════════════════════════════
  static const light = AppColorScheme(
    // --- Фоны ---
    scaffoldBackground: Color(0xFFFAFAFA),
    backgroundPrimary: Color(0xFFF8FAFC),
    backgroundSecondary: Color(0xFFFFFFFF),
    cardBackground: Colors.white,
    cardBackgroundLight: Color(0xFFF1F5F9),
    inputBackground: Color(0xFFF1F5F9),
    inputBackgroundFocused: Colors.white,
    headerBackground: Color(0xFFF8FAFC),

    // --- Карточка результатов (тёмная по дизайну) ---
    resultCardBackground: Color(0xFF2D3748),
    resultCardText: Colors.white,
    resultCardTextSecondary: Color(0xFF9CA3AF),

    // --- Текст ---
    textPrimary: Color(0xFF1E293B),     // основной текст (slate-800)
    textSecondary: Color(0xFF475569),   // вторичный текст (slate-600)
    textTertiary: Color(0xFF64748B),    // подсказки (slate-500)
    textDisabled: Color(0xFFCBD5E1),

    // --- Границы и разделители ---
    borderDefault: Color(0xFFE2E8F0),
    borderFocused: Color(0xFF94A3B8),
    divider: Color(0xFFE2E8F0),

    // --- Тени ---
    shadowColor: Color.fromRGBO(0, 0, 0, 0.05),
    shadowColorMedium: Color.fromRGBO(0, 0, 0, 0.08),
    shadowColorLarge: Color.fromRGBO(0, 0, 0, 0.1),

    // --- Поверхности для Theme ---
    surface: Colors.white,
    surfaceContainerHighest: Color(0xFFF5F5F5),
    surfaceContainerHigh: Color(0xFFEEEEEE),
    surfaceContainer: Color(0xFFE8E8E8),
    surfaceContainerLow: Color(0xFFE0E0E0),
    surfaceContainerLowest: Color(0xFFD9D9D9),

    // --- AppBar ---
    appBarBackground: Color(0xFFFAFAFA),
    appBarBackgroundAlpha: 0.85,

    // --- Outline alpha для enabledBorder ---
    outlineAlpha: 0.15,
  );

  // ═══════════════════════════════════════════════════════
  //  ТЁМНАЯ ТЕМА (тёплый персиковый стиль)
  // ═══════════════════════════════════════════════════════
  static const dark = AppColorScheme(
    // --- Фоны ---
    scaffoldBackground: Color(0xFF1E1A18),
    backgroundPrimary: Color(0xFF1E1A18),
    backgroundSecondary: Color(0xFF282220),
    cardBackground: Color(0xFF3A322E),
    cardBackgroundLight: Color(0xFF453C37),
    inputBackground: Color(0xFF342C28),
    inputBackgroundFocused: Color(0xFF3F3632),
    headerBackground: Color(0xFF2A2421),

    // --- Карточка результатов ---
    resultCardBackground: Color(0xFF2A2421),
    resultCardText: Color(0xFFF5EDE8),
    resultCardTextSecondary: Color(0xFFBFAFA5),

    // --- Текст ---
    textPrimary: Color(0xFFF5EDE8),     // тёплый почти белый
    textSecondary: Color(0xFFBFAFA5),   // тёплый серый
    textTertiary: Color(0xFF9A8A80),    // приглушённый тёплый
    textDisabled: Color(0xFF6B5F58),

    // --- Границы и разделители ---
    borderDefault: Color(0xFF3D3430),
    borderFocused: Color(0xFF4D433E),
    divider: Color(0xFF3D3430),

    // --- Тени ---
    shadowColor: Color.fromRGBO(0, 0, 0, 0.3),
    shadowColorMedium: Color.fromRGBO(0, 0, 0, 0.3),
    shadowColorLarge: Color.fromRGBO(0, 0, 0, 0.3),

    // --- Поверхности для Theme ---
    surface: Color(0xFF1E1A18),
    surfaceContainerHighest: Color(0xFF3A322E),
    surfaceContainerHigh: Color(0xFF453C37),
    surfaceContainer: Color(0xFF342C28),
    surfaceContainerLow: Color(0xFF3F3632),
    surfaceContainerLowest: Color(0xFF282220),

    // --- AppBar ---
    appBarBackground: Color(0xFF1E1A18),
    appBarBackgroundAlpha: 0.85,

    // --- Outline alpha для enabledBorder ---
    outlineAlpha: 0.35,
  );

  // ═══════════════════════════════════════════════════════
  //  АКЦЕНТНЫЕ ЦВЕТА ПО КАТЕГОРИЯМ (не зависят от темы)
  // ═══════════════════════════════════════════════════════
  static const interior = Color(0xFF10B981);
  static const interiorLight = Color(0xFFD1FAE5);
  static const interiorDark = Color(0xFF047857);

  static const flooring = Color(0xFFF59E0B);
  static const flooringLight = Color(0xFFFEF3C7);
  static const flooringDark = Color(0xFFD97706);

  static const roofing = Color(0xFFEF4444);
  static const roofingLight = Color(0xFFFEE2E2);
  static const roofingDark = Color(0xFFDC2626);

  static const foundation = Color(0xFF6366F1);
  static const foundationLight = Color(0xFFE0E7FF);
  static const foundationDark = Color(0xFF4F46E5);

  static const facade = Color(0xFF8B5CF6);
  static const facadeLight = Color(0xFFEDE9FE);
  static const facadeDark = Color(0xFF7C3AED);

  static const engineering = Color(0xFF06B6D4);
  static const engineeringLight = Color(0xFFCFFAFE);
  static const engineeringDark = Color(0xFF0891B2);

  static const walls = Color(0xFF14B8A6);
  static const wallsLight = Color(0xFFCCFBF1);
  static const wallsDark = Color(0xFF0F766E);

  static const ceiling = Color(0xFF3B82F6);
  static const ceilingLight = Color(0xFFDBEAFE);
  static const ceilingDark = Color(0xFF2563EB);

  /// Цвет по категории
  static Color getColorByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'interior': return interior;
      case 'flooring': return flooring;
      case 'roofing': return roofing;
      case 'foundation': return foundation;
      case 'facade': return facade;
      case 'engineering': return engineering;
      case 'walls': return walls;
      case 'ceiling': return ceiling;
      default: return interior;
    }
  }

  /// Светлый оттенок по категории
  static Color getLightColorByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'interior': return interiorLight;
      case 'flooring': return flooringLight;
      case 'roofing': return roofingLight;
      case 'foundation': return foundationLight;
      case 'facade': return facadeLight;
      case 'engineering': return engineeringLight;
      case 'walls': return wallsLight;
      case 'ceiling': return ceilingLight;
      default: return interiorLight;
    }
  }

  /// Тёмный оттенок по категории
  static Color getDarkColorByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'interior': return interiorDark;
      case 'flooring': return flooringDark;
      case 'roofing': return roofingDark;
      case 'foundation': return foundationDark;
      case 'facade': return facadeDark;
      case 'engineering': return engineeringDark;
      case 'walls': return wallsDark;
      case 'ceiling': return ceilingDark;
      default: return interiorDark;
    }
  }
}

/// Набор цветов для одной темы.
///
/// Единственный класс с ПОЛНЫМ набором цветов.
/// Экземпляры создаются только в [AppColors.light] и [AppColors.dark].
class AppColorScheme {
  // --- Фоны ---
  final Color scaffoldBackground;
  final Color backgroundPrimary;
  final Color backgroundSecondary;
  final Color cardBackground;
  final Color cardBackgroundLight;
  final Color inputBackground;
  final Color inputBackgroundFocused;
  final Color headerBackground;

  // --- Карточка результатов ---
  final Color resultCardBackground;
  final Color resultCardText;
  final Color resultCardTextSecondary;

  // --- Текст ---
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;

  // --- Границы и разделители ---
  final Color borderDefault;
  final Color borderFocused;
  final Color divider;

  // --- Тени ---
  final Color shadowColor;
  final Color shadowColorMedium;
  final Color shadowColorLarge;

  // --- Поверхности для Theme ---
  final Color surface;
  final Color surfaceContainerHighest;
  final Color surfaceContainerHigh;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerLowest;

  // --- AppBar ---
  final Color appBarBackground;
  final double appBarBackgroundAlpha;

  // --- Outline ---
  final double outlineAlpha;

  const AppColorScheme({
    required this.scaffoldBackground,
    required this.backgroundPrimary,
    required this.backgroundSecondary,
    required this.cardBackground,
    required this.cardBackgroundLight,
    required this.inputBackground,
    required this.inputBackgroundFocused,
    required this.headerBackground,
    required this.resultCardBackground,
    required this.resultCardText,
    required this.resultCardTextSecondary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.borderDefault,
    required this.borderFocused,
    required this.divider,
    required this.shadowColor,
    required this.shadowColorMedium,
    required this.shadowColorLarge,
    required this.surface,
    required this.surfaceContainerHighest,
    required this.surfaceContainerHigh,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerLowest,
    required this.appBarBackground,
    required this.appBarBackgroundAlpha,
    required this.outlineAlpha,
  });
}
