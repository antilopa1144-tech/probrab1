import 'package:flutter/services.dart';

/// Сервис для тактильной обратной связи (Haptic Feedback).
///
/// Предоставляет единый интерфейс для вибрации при важных действиях.
class HapticFeedbackService {
  /// Лёгкая вибрация при выборе элемента.
  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Средняя вибрация при важных действиях (сохранение, удаление).
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Сильная вибрация при критических действиях (ошибка, успех).
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Вибрация при успешном действии.
  static void success() {
    HapticFeedback.mediumImpact();
  }

  /// Вибрация при ошибке.
  static void error() {
    HapticFeedback.heavyImpact();
  }

  /// Вибрация при нажатии кнопки.
  static void buttonPress() {
    HapticFeedback.selectionClick();
  }

  /// Вибрация при свайпе.
  static void swipe() {
    HapticFeedback.lightImpact();
  }
}
