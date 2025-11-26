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
    final jsonString = await rootBundle
        .loadString('assets/lang/${locale.languageCode}.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value));
    return true;
  }

  /// Получение строки по ключу.
  String translate(String key) {
    return _localizedStrings[key] ?? key;
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
class AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return AppLocalizations.supportedLocales
        .any((l) => l.languageCode == locale.languageCode);
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