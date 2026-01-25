import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/app/main_shell.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/presentation/views/calculator/pro_calculator_screen.dart';
import 'package:probrab_ai/presentation/views/calculator/calculator_catalog_screen.dart';
import 'package:probrab_ai/presentation/widgets/common/app_number_field.dart';

import '../helpers/test_helpers.dart';

Finder _homeSearchField() {
  return find.byType(TextField);
}

Finder _numberFieldWithLabel(String labelText) {
  final appNumberField = find.ancestor(
    of: find.text(labelText),
    matching: find.byType(AppNumberField),
  );
  if (appNumberField.evaluate().isNotEmpty) {
    return find.descendant(
      of: appNumberField,
      matching: find.byWidgetPredicate(
        (widget) => widget is TextFormField || widget is TextField,
      ),
    );
  }
  final inputDecorator = find.byWidgetPredicate((widget) {
    if (widget is! InputDecorator) return false;
    final decoration = widget.decoration;
    if (decoration.labelText == labelText) return true;
    final label = decoration.label;
    if (label is Text && label.data == labelText) return true;
    if (label is RichText &&
        label.text.toPlainText() == labelText) {
      return true;
    }
    return false;
  });
  if (inputDecorator.evaluate().isNotEmpty) {
    return find.descendant(
      of: inputDecorator,
      matching: find.byType(EditableText),
    );
  }
  final label = find.text(labelText);
  final column = find.ancestor(of: label, matching: find.byType(Column));
  if (column.evaluate().isNotEmpty) {
    final editable = find.descendant(
      of: column.first,
      matching: find.byType(EditableText),
    );
    if (editable.evaluate().isNotEmpty) {
      return editable;
    }
    return find.descendant(
      of: column.first,
      matching: find.byWidgetPredicate(
        (widget) => widget is TextFormField || widget is TextField,
      ),
    );
  }
  return find.byType(EditableText).first;
}

Finder _calculatorListView() {
  Finder verticalScrollable(Finder root) {
    return find.descendant(
      of: root,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Scrollable &&
            widget.axisDirection == AxisDirection.down,
      ),
    );
  }

  return verticalScrollable(find.byType(ProCalculatorScreen));
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
  String translate(String key, [Map<String, String>? params]) {
    dynamic current = jsonMap;
    for (final part in key.split('.')) {
      if (current is Map<String, dynamic> && current.containsKey(part)) {
        current = current[part];
      } else {
        return key;
      }
    }

    if (current is String) {
      var resolved = current;
      if (params != null && params.isNotEmpty) {
        for (final entry in params.entries) {
          resolved = resolved.replaceAll('{${entry.key}}', entry.value);
        }
      }
      return resolved;
    }
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

  final target = find.text(title).first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
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

  // TODO: Требует обновления после изменения UI калькуляторов
  testWidgets(
    'User scenarios: search → open → validate → favorites → category',
    skip: true,
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
        query: 'бетон',
        title: 'Универсальный бетон',
      );
      final isProScreen = find.byType(ProCalculatorScreen).evaluate().isNotEmpty;

      if (isProScreen) {
        await tester.enterText(_numberFieldWithLabel('Объём бетона'), '5');
        await tester.pump(const Duration(milliseconds: 50));
        await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));
        expect(find.textContaining('БЕТОН'), findsWidgets);
      } else {
        // 2) Сделать расчёт без ввода (не должно ругаться "сразу при открытии").
        expect(find.textContaining('Поле "'), findsNothing);

        // 3) Частично заполнить: ошибка только на <Рассчитать>, а не от ввода в другое поле.
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
      }

      // Возврат на главный экран.
      await tester.tap(find.byType(BackButton).first);
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      // 5) Добавить в избранное и открыть из избранного.
      final bottomNav = find.byType(BottomNavigationBar);
      final favoriteButton = find.byTooltip('В избранное');
      if (favoriteButton.evaluate().isNotEmpty) {
        await tester.tap(favoriteButton.first);
        await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

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
      }

      // 6) Вернуться на главную через нижнюю навигацию.
      await tester.tap(
        find.descendant(of: bottomNav, matching: find.text('Главная')),
      );
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      // 7) Открыть из категории.
      await tester.enterText(_homeSearchField(), '');
      await tester.pump(const Duration(milliseconds: 300)); // debounce
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      final floorsCategory = find.text('Полы');
      if (floorsCategory.evaluate().isNotEmpty) {
        await tester.ensureVisible(floorsCategory.first);
        await tester.tap(floorsCategory.first);
        await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

        final plinthItem = find.text('Плинтус');
        for (int i = 0; i < 10 && plinthItem.evaluate().isEmpty; i++) {
          await tester.drag(_catalogListView(), const Offset(0, -300));
          await tester.pump(const Duration(milliseconds: 100));
        }
        if (plinthItem.evaluate().isNotEmpty) {
          await tester.tap(plinthItem.first);
          await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));
          expect(find.text('Плинтус'), findsWidgets);
        }
      }
    },
  );
}

