import 'package:flutter/material.dart';

/// Единые стили для калькуляторов.
class CalculatorStyles {
  // Отступы
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 12.0;
  static const double paddingLarge = 16.0;
  static const double paddingXLarge = 24.0;
  static const double paddingXXLarge = 32.0;

  // Радиусы скругления
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;

  // Высота элементов
  static const double inputFieldHeight = 56.0;
  static const double buttonHeight = 48.0;

  // Отступы для экрана
  static const EdgeInsets screenPadding = EdgeInsets.all(paddingLarge);
  static const EdgeInsets cardPadding = EdgeInsets.all(paddingLarge);
  static const EdgeInsets sectionSpacing = EdgeInsets.only(bottom: paddingXLarge);

  // Стиль карточки
  static CardTheme get cardTheme => CardTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        elevation: 2,
        margin: const EdgeInsets.only(bottom: paddingMedium),
      );

  // Стиль поля ввода
  static InputDecorationTheme get inputDecorationTheme => InputDecorationTheme(
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingMedium,
        ),
      );

  // Стиль кнопки
  static ButtonStyle get filledButtonStyle => FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: paddingXLarge,
          vertical: paddingLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        minimumSize: const Size(double.infinity, buttonHeight),
      );

  static ButtonStyle get outlinedButtonStyle => OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: paddingXLarge,
          vertical: paddingLarge,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        minimumSize: const Size(double.infinity, buttonHeight),
      );

  // Стиль заголовка секции
  static TextStyle sectionTitleStyle(ThemeData theme) => theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ) ?? const TextStyle();

  // Стиль результата
  static TextStyle resultValueStyle(ThemeData theme) => theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.primary,
      ) ?? const TextStyle();
}

