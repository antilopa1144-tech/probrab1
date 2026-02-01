import 'package:flutter/material.dart';

/// Единая палитра для каталога калькуляторов
///
/// Используется в обеих версиях: мобильной и веб.
/// Цвета синхронизированы с [CalculatorColors] для консистентности.
class CatalogPalette {
  final bool isDark;

  const CatalogPalette(this.isDark);

  // === ФОНЫ ===

  /// Основной фон экрана
  Color get background =>
      isDark ? const Color(0xFF1E1A18) : const Color(0xFFF6F2ED);

  /// Фон карточек и поверхностей
  Color get surface =>
      isDark ? const Color(0xFF3A322E) : const Color(0xFFFCFAF7);

  /// Приглушённый фон (для бейджей, чипов)
  Color get surfaceMuted =>
      isDark ? const Color(0xFF453C37) : const Color(0xFFF0E9E1);

  // === ГРАНИЦЫ ===

  /// Цвет границ
  Color get border =>
      isDark ? const Color(0xFF4D433E) : const Color(0xFFE2D9CF);

  // === ТЕКСТ ===

  /// Основной текст
  Color get textPrimary =>
      isDark ? const Color(0xFFF5EDE8) : const Color(0xFF1F1B16);

  /// Вторичный текст
  Color get textSecondary =>
      isDark ? const Color(0xFFBFAFA5) : const Color(0xFF6E645A);

  /// Приглушённый текст (подсказки, мета-информация)
  Color get textMuted =>
      isDark ? const Color(0xFF9A8A80) : const Color(0xFF8C8176);

  // === АКЦЕНТ ===

  /// Акцентный цвет
  Color get accent => const Color(0xFFE0823D);

  // === ТЕНИ ===

  /// Тень для карточек
  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
      blurRadius: isDark ? 16 : 12,
      offset: const Offset(0, 8),
    ),
  ];

  /// Тень для контролов (кнопок, полей ввода)
  List<BoxShadow> get controlShadow => [
    BoxShadow(
      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
      blurRadius: isDark ? 10 : 8,
      offset: const Offset(0, 4),
    ),
  ];
}
