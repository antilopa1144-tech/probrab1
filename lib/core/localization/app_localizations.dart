import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Простая локализационная система, которая загружает JSON файлы из
/// директории `assets/lang` и предоставляет доступ к строкам по ключам.
class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;

  AppLocalizations(this.locale);

  /// Загрузка JSON из assets в память.
  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/lang/${locale.languageCode}.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value));
    return true;
  }

  /// Получение строки по ключу.
  /// Поддерживает вложенные ключи через точку (например, "input.area").
  ///
  /// Структура JSON: {"input": {"area": "Площадь", "area.hint": "..."}}
  /// Ключи в коде: "input.area", "input.area.hint"
  String translate(String key) {
    // Если ключ содержит точку, ищем вложенное значение
    if (key.contains('.')) {
      final parts = key.split('.');
      dynamic value = _localizedStrings;

      // Проходим по всем частям кроме последней
      for (int i = 0; i < parts.length - 1; i++) {
        if (value is Map<String, dynamic>) {
          value = value[parts[i]];
          if (value == null) return key;
        } else {
          return key; // Не нашли вложенный ключ
        }
      }

      // Последняя часть - это ключ в последнем Map
      // Но может быть, что последние части нужно объединить (например, "area.hint")
      if (value is Map<String, dynamic>) {
        // Сначала пробуем найти полный ключ (например, "area.hint")
        final lastKey = parts.sublist(parts.length - 1).join('.');
        if (value.containsKey(lastKey)) {
          final result = value[lastKey];
          if (result is String) return result;
        }

        // Если не нашли, пробуем только последнюю часть (например, "hint")
        final simpleKey = parts.last;
        if (value.containsKey(simpleKey)) {
          final result = value[simpleKey];
          if (result is String) return result;
        }
      }

      return key;
    }

    // Плоский ключ
    final value = _localizedStrings[key];
    if (value is String) {
      return value;
    }
    return key;
  }

  /// Удобный метод доступа из контекста.
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// Доступные локали.
  static const List<Locale> supportedLocales = [
    Locale('ru'),
    Locale('en'),
    Locale('kk'), // Казахский
    Locale('ky'), // Киргизский
    Locale('tg'), // Таджикский
    Locale('tk'), // Туркменский
    Locale('uz'), // Узбекский
  ];
}

/// Делегат для загрузки локализации.
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
