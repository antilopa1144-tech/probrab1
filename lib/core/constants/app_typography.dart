import 'package:flutter/material.dart';

/// Единый источник типографики приложения.
///
/// Все стили текста определены здесь. Используется как напрямую,
/// так и через [CalculatorDesignSystem] для обратной совместимости.
///
/// Использование:
/// ```dart
/// Text('Заголовок', style: AppTypography.headlineLarge);
/// Text('Текст', style: AppTypography.bodyMedium.copyWith(color: colors.textPrimary));
/// ```
class AppTypography {
  AppTypography._();

  // === ЗАГОЛОВКИ ===

  /// Заголовки экранов
  static const headlineLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const headlineMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // === TITLE ===

  /// Заголовки секций
  static const titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  // === BODY ===

  /// Основной текст
  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // === LABEL ===

  /// Метки и подписи
  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.5,
  );

  // === РЕЗУЛЬТАТЫ ===

  /// Текст в результатах header (верхняя панель)
  static const headerLabel = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
  );

  static const headerValue = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );
}
