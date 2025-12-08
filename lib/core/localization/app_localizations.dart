import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Простая локализационная система, которая загружает JSON файлы из
/// директории `assets/lang` и предоставляет доступ к строкам по ключам.
class AppLocalizations {
  final Locale locale;
  late Map<String, dynamic> _localizedStrings;
  late Map<String, String> _flattenedStrings;

  AppLocalizations(this.locale);

  /// Загрузка JSON из assets в память.
  Future<bool> load() async {
    final jsonString = await rootBundle.loadString(
      'assets/lang/${locale.languageCode}.json',
    );
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value));
    _flattenedStrings = {};
    _flattenJson(_localizedStrings);
    return true;
  }

  /// Получение строки по ключу с поддержкой вложенных структур и ключей с точками.
  String translate(String key) {
    return _flattenedStrings[key] ?? key;
  }

  /// Превращает произвольную вложенную карту в плоский список ключей `a.b.c`.
  void _flattenJson(dynamic value, [String prefix = '']) {
    if (value is Map<String, dynamic>) {
      if (prefix.isNotEmpty &&
          value.containsKey('title') &&
          value['title'] is String) {
        _flattenedStrings[prefix] = value['title'] as String;
      }
      value.forEach((key, nested) {
        final nextPrefix = prefix.isEmpty ? key : '$prefix.$key';
        _flattenJson(nested, nextPrefix);
      });
    } else if (value is String) {
      _flattenedStrings[prefix] = value;
    }
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
