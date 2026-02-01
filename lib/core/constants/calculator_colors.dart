import 'package:flutter/material.dart';

/// Цветовая палитра для калькуляторов
///
/// Эталонный дизайн основан на калькуляторе "Шпатлёвка" (putty_calculator_screen.dart)
/// Светлая тема с цветными акцентами по категориям
class CalculatorColors {
  // === АКЦЕНТНЫЕ ЦВЕТА ПО КАТЕГОРИЯМ ===

  /// Интерьерные работы (шпатлёвка, штукатурка)
  static const interior = Color(0xFF10B981); // Зелёный
  static const interiorLight = Color(0xFFD1FAE5); // Светло-зелёный
  static const interiorDark = Color(0xFF047857); // Тёмно-зелёный

  /// Напольные покрытия (ламинат, стяжка, ЦПС)
  static const flooring = Color(0xFFF59E0B); // Жёлтый/Оранжевый
  static const flooringLight = Color(0xFFFEF3C7);
  static const flooringDark = Color(0xFFD97706);

  /// Кровельные работы
  static const roofing = Color(0xFFEF4444); // Красный
  static const roofingLight = Color(0xFFFEE2E2);
  static const roofingDark = Color(0xFFDC2626);

  /// Фундаментные работы и бетон
  static const foundation = Color(0xFF6366F1); // Синий/Индиго
  static const foundationLight = Color(0xFFE0E7FF);
  static const foundationDark = Color(0xFF4F46E5);

  /// Фасадные работы
  static const facade = Color(0xFF8B5CF6); // Фиолетовый
  static const facadeLight = Color(0xFFEDE9FE);
  static const facadeDark = Color(0xFF7C3AED);

  /// Инженерные системы
  static const engineering = Color(0xFF06B6D4); // Бирюзовый/Циан
  static const engineeringLight = Color(0xFFCFFAFE);
  static const engineeringDark = Color(0xFF0891B2);

  /// Стены и перегородки
  static const walls = Color(0xFF14B8A6); // Teal
  static const wallsLight = Color(0xFFCCFBF1);
  static const wallsDark = Color(0xFF0F766E);

  /// Потолочные работы
  static const ceiling = Color(0xFF3B82F6); // Голубой
  static const ceilingLight = Color(0xFFDBEAFE);
  static const ceilingDark = Color(0xFF2563EB);

  // === ОБЩИЕ ЦВЕТА (СВЕТЛАЯ ТЕМА) ===

  /// Фон экрана
  static const backgroundPrimary = Color(0xFFF8FAFC); // Светло-серый
  static const backgroundSecondary = Color(0xFFFFFFFF); // Белый

  /// Фон карточек
  static const cardBackground = Colors.white;
  static const cardBackgroundLight = Color(0xFFF1F5F9);

  /// Фон полей ввода
  static const inputBackground = Color(0xFFF1F5F9);
  static const inputBackgroundFocused = Colors.white;

  /// Фон header с результатами
  static const headerBackground = Color(0xFFF8FAFC);

  /// Фон карточки результатов (тёмная)
  static const resultCardBackground = Color(0xFF2D3748); // Тёмно-серый
  static const resultCardText = Colors.white;
  static const resultCardTextSecondary = Color(0xFF9CA3AF);

  // === ТЕКСТ (СВЕТЛАЯ ТЕМА) ===

  static const textPrimary = Color(0xFF1E293B); // Основной текст
  static const textSecondary = Color(0xFF475569); // Вторичный текст (улучшенный контраст)
  static const textTertiary = Color(0xFF64748B); // Подсказки (улучшенный контраст)
  static const textDisabled = Color(0xFFCBD5E1);

  // === ГРАНИЦЫ И РАЗДЕЛИТЕЛИ (СВЕТЛАЯ ТЕМА) ===

  static const borderDefault = Color(0xFFE2E8F0);
  static const borderFocused = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);

  // === ТЁМНАЯ ТЕМА (мягкий персиковый стиль) ===

  /// Фон экрана (тёмная тема) - тёплый тёмный с персиковым оттенком
  static const backgroundPrimaryDark = Color(0xFF1E1A18);
  static const backgroundSecondaryDark = Color(0xFF282220);

  /// Фон карточек (тёмная тема) - заметный персиковый оттенок
  static const cardBackgroundDark = Color(0xFF3A322E);
  static const cardBackgroundLightDark = Color(0xFF453C37);

  /// Фон полей ввода (тёмная тема) - персиковый
  static const inputBackgroundDark = Color(0xFF342C28);
  static const inputBackgroundFocusedDark = Color(0xFF3F3632);

  /// Фон header с результатами (тёмная тема)
  static const headerBackgroundDark = Color(0xFF2A2421);

  /// Фон карточки результатов (тёмная тема)
  static const resultCardBackgroundDark = Color(0xFF2A2421);
  static const resultCardTextDark = Color(0xFFF5EDE8);
  static const resultCardTextSecondaryDark = Color(0xFFBFAFA5);

  // === ТЕКСТ (ТЁМНАЯ ТЕМА) - тёплые оттенки ===

  static const textPrimaryDark = Color(0xFFF5EDE8); // Тёплый почти белый
  static const textSecondaryDark = Color(0xFFBFAFA5); // Тёплый серый
  static const textTertiaryDark = Color(0xFF9A8A80); // Приглушённый
  static const textDisabledDark = Color(0xFF6B5F58);

  // === ГРАНИЦЫ И РАЗДЕЛИТЕЛИ (ТЁМНАЯ ТЕМА) - тёплые ===

  static const borderDefaultDark = Color(0xFF3D3430);
  static const borderFocusedDark = Color(0xFF4D433E);
  static const dividerDark = Color(0xFF3D3430);

  // === АДАПТИВНЫЕ ГЕТТЕРЫ ===

  /// Получить фон экрана в зависимости от темы
  static Color getBackgroundPrimary(bool isDark) =>
      isDark ? backgroundPrimaryDark : backgroundPrimary;

  /// Получить фон карточки в зависимости от темы
  static Color getCardBackground(bool isDark) =>
      isDark ? cardBackgroundDark : cardBackground;

  /// Получить светлый фон карточки в зависимости от темы
  static Color getCardBackgroundLight(bool isDark) =>
      isDark ? cardBackgroundLightDark : cardBackgroundLight;

  /// Получить фон поля ввода в зависимости от темы
  static Color getInputBackground(bool isDark) =>
      isDark ? inputBackgroundDark : inputBackground;

  /// Получить фон header в зависимости от темы
  static Color getHeaderBackground(bool isDark) =>
      isDark ? headerBackgroundDark : headerBackground;

  /// Получить основной цвет текста в зависимости от темы
  static Color getTextPrimary(bool isDark) =>
      isDark ? textPrimaryDark : textPrimary;

  /// Получить основной цвет текста автоматически из контекста
  static Color textPrimaryOf(BuildContext context) =>
      getTextPrimary(Theme.of(context).brightness == Brightness.dark);

  /// Получить вторичный цвет текста в зависимости от темы
  static Color getTextSecondary(bool isDark) =>
      isDark ? textSecondaryDark : textSecondary;

  /// Получить вторичный цвет текста автоматически из контекста
  static Color textSecondaryOf(BuildContext context) =>
      getTextSecondary(Theme.of(context).brightness == Brightness.dark);

  /// Получить третичный цвет текста в зависимости от темы
  static Color getTextTertiary(bool isDark) =>
      isDark ? textTertiaryDark : textTertiary;

  /// Получить цвет границы в зависимости от темы
  static Color getBorderDefault(bool isDark) =>
      isDark ? borderDefaultDark : borderDefault;

  /// Получить цвет разделителя в зависимости от темы
  static Color getDivider(bool isDark) =>
      isDark ? dividerDark : divider;

  // === ТЕНИ ===

  static BoxShadow get shadowSmall => const BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.05),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static BoxShadow get shadowMedium => const BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.08),
    blurRadius: 10,
    offset: Offset(0, 4),
  );

  static BoxShadow get shadowLarge => const BoxShadow(
    color: Color.fromRGBO(0, 0, 0, 0.1),
    blurRadius: 15,
    offset: Offset(0, 5),
  );

  // === ХЕЛПЕРЫ ===

  /// Получить цвет по категории калькулятора
  static Color getColorByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'interior':
        return interior;
      case 'flooring':
        return flooring;
      case 'roofing':
        return roofing;
      case 'foundation':
        return foundation;
      case 'facade':
        return facade;
      case 'engineering':
        return engineering;
      case 'walls':
        return walls;
      case 'ceiling':
        return ceiling;
      default:
        return interior; // Дефолтный цвет
    }
  }

  /// Получить светлый оттенок по категории
  static Color getLightColorByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'interior':
        return interiorLight;
      case 'flooring':
        return flooringLight;
      case 'roofing':
        return roofingLight;
      case 'foundation':
        return foundationLight;
      case 'facade':
        return facadeLight;
      case 'engineering':
        return engineeringLight;
      case 'walls':
        return wallsLight;
      case 'ceiling':
        return ceilingLight;
      default:
        return interiorLight;
    }
  }

  /// Получить тёмный оттенок по категории
  static Color getDarkColorByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'interior':
        return interiorDark;
      case 'flooring':
        return flooringDark;
      case 'roofing':
        return roofingDark;
      case 'foundation':
        return foundationDark;
      case 'facade':
        return facadeDark;
      case 'engineering':
        return engineeringDark;
      case 'walls':
        return wallsDark;
      case 'ceiling':
        return ceilingDark;
      default:
        return interiorDark;
    }
  }
}
