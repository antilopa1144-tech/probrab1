import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/app/main_shell.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/presentation/views/calculator/universal_calculator_v2_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/calculator_catalog_screen.dart';

import '../helpers/test_helpers.dart';

Finder _homeSearchField() {
  return find.byType(TextField);
}

Finder _numberFieldWithLabel(String labelText) {
  final label = find.text(labelText);
  return find.ancestor(of: label, matching: find.byType(TextFormField));
}

Finder _calculatorListView() {
  return find.descendant(
    of: find.byType(UniversalCalculatorV2Screen),
    matching: find.byType(ListView),
  );
}

Finder _catalogListView() {
  return find.descendant(
    of: find.byType(CalculatorCatalogScreen),
    matching: find.byType(ListView),
  );
}

class _JsonAppLocalizations extends AppLocalizations {
  final Map<String, dynamic> jsonMap;

  _JsonAppLocalizations(super.locale, this.jsonMap);

  @override
  String translate(String key) {
    dynamic current = jsonMap;
    for (final part in key.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return key;
      }
    }

    if (current is String) return current;
    if (current is Map<String, dynamic> &&
        current.containsKey('title') &&
        current['title'] is String) {
      return current['title'] as String;
    }
    return key;
  }
}

class _TestAppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  final AppLocalizations localizations;

  const _TestAppLocalizationsDelegate(this.localizations);

  @override
  bool isSupported(Locale locale) => locale.languageCode == localizations.locale.languageCode;

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture<AppLocalizations>(localizations);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}

Widget _buildTestApp({
  required Widget home,
  required Locale locale,
}) {
  final langFile = File('assets/lang/${locale.languageCode}.json');
  final map =
      json.decode(langFile.readAsStringSync(encoding: utf8)) as Map<String, dynamic>;
  final loc = _JsonAppLocalizations(locale, map);

  return ProviderScope(
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: [
        _TestAppLocalizationsDelegate(loc),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

Future<void> _openCalculatorViaSearch(
  WidgetTester tester, {
  required String query,
  required String title,
}) async {
  expect(find.byType(TextField), findsOneWidget);
  await tester.enterText(_homeSearchField(), query);
  await tester.pump(const Duration(milliseconds: 300)); // debounce
  await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

  await tester.tap(find.text(title).first);
  await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));
}

void main() {
  setUp(() {
    setupMocks(
      sharedPreferencesValues: {
        'onboarding_completed': true,
        'language': 'ru',
      },
    );
  });

  testWidgets(
    'User scenarios: search → open → validate → favorites → category',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        _buildTestApp(
          locale: const Locale('ru'),
          home: const MainShell(key: ValueKey('main_shell_test')),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // 1) Найти калькулятор через поиск и открыть.
      await _openCalculatorViaSearch(
        tester,
        query: 'плинтус',
        title: 'Плинтус',
      );

      // 2) Сделать расчёт без ввода (не должно ругаться "сразу при открытии").
      expect(find.textContaining('Поле "'), findsNothing);

      // 3) Частично заполнить: ошибка только на «Рассчитать», а не от ввода в другое поле.
      await tester.enterText(_numberFieldWithLabel('Длина'), '5');
      await tester.pump(const Duration(milliseconds: 50));
      expect(find.textContaining('Поле "width"'), findsNothing);

      final calculateButton = find.text('Рассчитать');
      for (int i = 0; i < 12 && calculateButton.evaluate().isEmpty; i++) {
        await tester.drag(_calculatorListView(), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(calculateButton.first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));
      expect(find.textContaining('Поле "width"'), findsOneWidget);

      // 4) Заполнить недостающее и получить результат.
      await tester.enterText(_numberFieldWithLabel('Ширина'), '4');
      for (int i = 0; i < 12 && calculateButton.evaluate().isEmpty; i++) {
        await tester.drag(_calculatorListView(), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(calculateButton.first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 3));

      expect(find.textContaining('Поле "'), findsNothing);
      expect(find.text('Результаты расчёта'), findsOneWidget);

      // Возврат на главный экран.
      await tester.tap(find.byType(BackButton).first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      // 5) Добавить в избранное и открыть из избранного.
      await tester.tap(find.byTooltip('В избранное').first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      final bottomNav = find.byType(BottomNavigationBar);
      await tester.tap(
        find.descendant(of: bottomNav, matching: find.text('Избранное')),
      );
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      expect(find.text('Плинтус'), findsWidgets);
      await tester.tap(find.text('Плинтус').first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));
      expect(find.text('Плинтус'), findsWidgets);

      await tester.tap(find.byType(BackButton).first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      // 6) Вернуться на главную через нижнюю навигацию.
      await tester.tap(
        find.descendant(of: bottomNav, matching: find.text('Главная')),
      );
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      // 7) Открыть из категории.
      await tester.enterText(_homeSearchField(), '');
      await tester.pump(const Duration(milliseconds: 300)); // debounce
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      await tester.tap(find.text('Полы').first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      final plinthItem = find.text('Плинтус');
      for (int i = 0; i < 10 && plinthItem.evaluate().isEmpty; i++) {
        await tester.drag(_catalogListView(), const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.tap(plinthItem.first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));
      expect(find.text('Плинтус'), findsWidgets);
    },
  );
}
