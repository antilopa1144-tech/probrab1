import 'package:flutter/material.dart';

/// Навигационный обсервер, который скрывает клавиатуру при переходе назад.
///
/// Решает проблему появления клавиатуры при выходе из калькуляторов.
/// Добавляется в navigatorObservers MaterialApp.
class KeyboardDismissObserver extends NavigatorObserver {
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Скрываем клавиатуру при переходе назад
    FocusManager.instance.primaryFocus?.unfocus();
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Скрываем клавиатуру при переходе на новый экран
    FocusManager.instance.primaryFocus?.unfocus();
    super.didPush(route, previousRoute);
  }
}
