import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Цветовая палитра для калькуляторов.
///
/// **Все цвета делегируют в [AppColors]** — единый источник правды.
/// Этот класс сохранён для обратной совместимости с 68+ файлами.
///
/// Для нового кода предпочтительнее использовать `AppColors.of(context)`.
class CalculatorColors {
  // === АКЦЕНТНЫЕ ЦВЕТА ПО КАТЕГОРИЯМ (делегируют в AppColors) ===

  static const interior = AppColors.interior;
  static const interiorLight = AppColors.interiorLight;
  static const interiorDark = AppColors.interiorDark;

  static const flooring = AppColors.flooring;
  static const flooringLight = AppColors.flooringLight;
  static const flooringDark = AppColors.flooringDark;

  static const roofing = AppColors.roofing;
  static const roofingLight = AppColors.roofingLight;
  static const roofingDark = AppColors.roofingDark;

  static const foundation = AppColors.foundation;
  static const foundationLight = AppColors.foundationLight;
  static const foundationDark = AppColors.foundationDark;

  static const facade = AppColors.facade;
  static const facadeLight = AppColors.facadeLight;
  static const facadeDark = AppColors.facadeDark;

  static const engineering = AppColors.engineering;
  static const engineeringLight = AppColors.engineeringLight;
  static const engineeringDark = AppColors.engineeringDark;

  static const walls = AppColors.walls;
  static const wallsLight = AppColors.wallsLight;
  static const wallsDark = AppColors.wallsDark;

  static const ceiling = AppColors.ceiling;
  static const ceilingLight = AppColors.ceilingLight;
  static const ceilingDark = AppColors.ceilingDark;

  // === СВЕТЛАЯ ТЕМА (статические ссылки — для legacy кода) ===

  static Color get backgroundPrimary => AppColors.light.backgroundPrimary;
  static Color get backgroundSecondary => AppColors.light.backgroundSecondary;
  static Color get cardBackground => AppColors.light.cardBackground;
  static Color get cardBackgroundLight => AppColors.light.cardBackgroundLight;
  static Color get inputBackground => AppColors.light.inputBackground;
  static Color get inputBackgroundFocused => AppColors.light.inputBackgroundFocused;
  static Color get headerBackground => AppColors.light.headerBackground;
  static Color get resultCardBackground => AppColors.light.resultCardBackground;
  static Color get resultCardText => AppColors.light.resultCardText;
  static Color get resultCardTextSecondary => AppColors.light.resultCardTextSecondary;
  static Color get textPrimary => AppColors.light.textPrimary;
  static Color get textSecondary => AppColors.light.textSecondary;
  static Color get textTertiary => AppColors.light.textTertiary;
  static Color get textDisabled => AppColors.light.textDisabled;
  static Color get borderDefault => AppColors.light.borderDefault;
  static Color get borderFocused => AppColors.light.borderFocused;
  static Color get divider => AppColors.light.divider;

  // === ТЁМНАЯ ТЕМА (статические ссылки — для legacy кода) ===

  static Color get backgroundPrimaryDark => AppColors.dark.backgroundPrimary;
  static Color get backgroundSecondaryDark => AppColors.dark.backgroundSecondary;
  static Color get cardBackgroundDark => AppColors.dark.cardBackground;
  static Color get cardBackgroundLightDark => AppColors.dark.cardBackgroundLight;
  static Color get inputBackgroundDark => AppColors.dark.inputBackground;
  static Color get inputBackgroundFocusedDark => AppColors.dark.inputBackgroundFocused;
  static Color get headerBackgroundDark => AppColors.dark.headerBackground;
  static Color get resultCardBackgroundDark => AppColors.dark.resultCardBackground;
  static Color get resultCardTextDark => AppColors.dark.resultCardText;
  static Color get resultCardTextSecondaryDark => AppColors.dark.resultCardTextSecondary;
  static Color get textPrimaryDark => AppColors.dark.textPrimary;
  static Color get textSecondaryDark => AppColors.dark.textSecondary;
  static Color get textTertiaryDark => AppColors.dark.textTertiary;
  static Color get textDisabledDark => AppColors.dark.textDisabled;
  static Color get borderDefaultDark => AppColors.dark.borderDefault;
  static Color get borderFocusedDark => AppColors.dark.borderFocused;
  static Color get dividerDark => AppColors.dark.divider;

  // === АДАПТИВНЫЕ ГЕТТЕРЫ (делегируют в AppColors.resolve) ===

  static Color getBackgroundPrimary(bool isDark) =>
      AppColors.resolve(isDark).backgroundPrimary;

  static Color getCardBackground(bool isDark) =>
      AppColors.resolve(isDark).cardBackground;

  static Color getCardBackgroundLight(bool isDark) =>
      AppColors.resolve(isDark).cardBackgroundLight;

  static Color getInputBackground(bool isDark) =>
      AppColors.resolve(isDark).inputBackground;

  static Color getHeaderBackground(bool isDark) =>
      AppColors.resolve(isDark).headerBackground;

  static Color getTextPrimary(bool isDark) =>
      AppColors.resolve(isDark).textPrimary;

  static Color textPrimaryOf(BuildContext context) =>
      AppColors.of(context).textPrimary;

  static Color getTextSecondary(bool isDark) =>
      AppColors.resolve(isDark).textSecondary;

  static Color textSecondaryOf(BuildContext context) =>
      AppColors.of(context).textSecondary;

  static Color getTextTertiary(bool isDark) =>
      AppColors.resolve(isDark).textTertiary;

  static Color getBorderDefault(bool isDark) =>
      AppColors.resolve(isDark).borderDefault;

  static Color getDivider(bool isDark) =>
      AppColors.resolve(isDark).divider;

  // === ТЕНИ ===

  static BoxShadow get shadowSmall => BoxShadow(
    color: AppColors.light.shadowColor,
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  static BoxShadow get shadowMedium => BoxShadow(
    color: AppColors.light.shadowColorMedium,
    blurRadius: 10,
    offset: const Offset(0, 4),
  );

  static BoxShadow get shadowLarge => BoxShadow(
    color: AppColors.light.shadowColorLarge,
    blurRadius: 15,
    offset: const Offset(0, 5),
  );

  // === ХЕЛПЕРЫ ===

  static Color getColorByCategory(String category) =>
      AppColors.getColorByCategory(category);

  static Color getLightColorByCategory(String category) =>
      AppColors.getLightColorByCategory(category);

  static Color getDarkColorByCategory(String category) =>
      AppColors.getDarkColorByCategory(category);
}
