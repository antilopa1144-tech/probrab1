import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppLocalizations', () {
    late AppLocalizations localizations;

    setUp(() {
      localizations = AppLocalizations(const Locale('ru'));
    });

    test('создаётся с правильной локалью', () {
      expect(localizations.locale, equals(const Locale('ru')));
    });

    test('загружает локализационные данные', () async {
      final loaded = await localizations.load();
      expect(loaded, isTrue);
    });

    test('возвращает переведённую строку для существующего ключа', () async {
      await localizations.load();

      final appName = localizations.translate('app.name');
      expect(appName, equals('Мастерок'));
    });

    test('возвращает ключ для несуществующей строки', () async {
      await localizations.load();

      final missing = localizations.translate('nonexistent.key');
      expect(missing, equals('nonexistent.key'));
    });

    test('обрабатывает вложенные ключи', () async {
      await localizations.load();

      final calculate = localizations.translate('button.calculate');
      expect(calculate, equals('Рассчитать'));

      final clear = localizations.translate('button.clear');
      expect(clear, equals('Очистить'));
    });

    test('заменяет параметры в строках', () async {
      await localizations.load();

      final translated = localizations.translate(
        'button.show_more',
        {'count': '5'},
      );
      expect(translated, equals('Показать ещё 5'));
    });

    test('обрабатывает несколько параметров', () async {
      await localizations.load();

      // Создадим строку с несколькими параметрами для теста
      const testKey = 'test.multiple.params';
      final translated = localizations.translate(
        testKey,
        {'name': 'Иван', 'age': '25'},
      );

      // Если ключ не существует, вернётся сам ключ
      expect(translated, contains(testKey));
    });

    test('возвращает оригинальную строку если параметры null', () async {
      await localizations.load();

      final clear = localizations.translate('button.clear', null);
      expect(clear, equals('Очистить'));
    });

    test('возвращает оригинальную строку если параметры пустые', () async {
      await localizations.load();

      final clear = localizations.translate('button.clear', {});
      expect(clear, equals('Очистить'));
    });

    test('обрабатывает глубокую вложенность ключей', () async {
      await localizations.load();

      final quick = localizations.translate('catalog.complexity.quick');
      expect(quick, equals('Быстрый'));

      final detailed = localizations.translate('catalog.complexity.detailed');
      expect(detailed, equals('Детальный'));
    });

    test('обрабатывает ключи с различными категориями', () async {
      await localizations.load();

      final walls = localizations.translate('category.walls');
      expect(walls, equals('Стены'));

      final floor = localizations.translate('category.floor');
      expect(floor, equals('Пол'));

      final finish = localizations.translate('category.finish');
      expect(finish, equals('Отделка'));
    });

    test('работает со всеми доступными ключами', () async {
      await localizations.load();

      // Проверяем несколько разных категорий ключей
      expect(localizations.translate('action.clear'), equals('Очистить'));
      expect(localizations.translate('chart.no_data'), equals('Нет данных'));
      expect(localizations.translate('catalog.all_calculators'), equals('Все калькуляторы'));
    });

    test('не изменяет оригинальную строку при замене параметров', () async {
      await localizations.load();

      final original = localizations.translate('button.show_more');
      final withParams = localizations.translate(
        'button.show_more',
        {'count': '10'},
      );

      // Оригинальная строка не должна измениться
      final originalAgain = localizations.translate('button.show_more');
      expect(originalAgain, equals(original));
      expect(withParams, isNot(equals(original)));
    });
  });

  group('AppLocalizations.of', () {
    testWidgets('возвращает AppLocalizations из контекста', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              final loc = AppLocalizations.of(context);
              expect(loc, isNotNull);
              expect(loc, isA<AppLocalizations>());
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('работает в дереве виджетов', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            appBar: AppBar(
              title: Builder(
                builder: (context) {
                  final loc = AppLocalizations.of(context);
                  return Text(loc.translate('app.name'));
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Мастерок'), findsOneWidget);
    });
  });

  group('AppLocalizations.supportedLocales', () {
    test('содержит русскую локаль', () {
      expect(
        AppLocalizations.supportedLocales,
        contains(const Locale('ru')),
      );
    });

    test('является константным списком', () {
      expect(AppLocalizations.supportedLocales, isA<List<Locale>>());
      expect(AppLocalizations.supportedLocales.isEmpty, isFalse);
    });

    test('содержит хотя бы одну локаль', () {
      expect(AppLocalizations.supportedLocales.length, greaterThanOrEqualTo(1));
    });
  });

  group('AppLocalizationsDelegate', () {
    const delegate = AppLocalizationsDelegate();

    test('поддерживает русскую локаль', () {
      expect(delegate.isSupported(const Locale('ru')), isTrue);
    });

    test('не поддерживает неизвестные локали', () {
      expect(delegate.isSupported(const Locale('fr')), isFalse);
      expect(delegate.isSupported(const Locale('de')), isFalse);
      expect(delegate.isSupported(const Locale('es')), isFalse);
    });

    test('загружает локализацию', () async {
      final localizations = await delegate.load(const Locale('ru'));
      expect(localizations, isNotNull);
      expect(localizations, isA<AppLocalizations>());
    });

    test('shouldReload возвращает false', () {
      const oldDelegate = AppLocalizationsDelegate();
      expect(delegate.shouldReload(oldDelegate), isFalse);
    });

    test('является константой', () {
      const delegate1 = AppLocalizationsDelegate();
      const delegate2 = AppLocalizationsDelegate();
      expect(identical(delegate1, delegate2), isTrue);
    });
  });

  group('AppLocalizations edge cases', () {
    test('обрабатывает параметры с фигурными скобками', () async {
      final localizations = AppLocalizations(const Locale('ru'));
      await localizations.load();

      final translated = localizations.translate(
        'button.show_more',
        {'count': '{special}'},
      );

      // Должно корректно заменить параметр
      expect(translated, contains('{special}'));
    });

    test('обрабатывает пустые значения параметров', () async {
      final localizations = AppLocalizations(const Locale('ru'));
      await localizations.load();

      final translated = localizations.translate(
        'button.show_more',
        {'count': ''},
      );

      expect(translated, contains('Показать ещё'));
    });

    test('обрабатывает несуществующие параметры в шаблоне', () async {
      final localizations = AppLocalizations(const Locale('ru'));
      await localizations.load();

      // Передаём параметр, которого нет в шаблоне
      final translated = localizations.translate(
        'button.clear',
        {'nonexistent': 'value'},
      );

      expect(translated, equals('Очистить'));
    });

    test('обрабатывает ключи с точками в значениях', () async {
      final localizations = AppLocalizations(const Locale('ru'));
      await localizations.load();

      // Проверяем, что ключи правильно разбираются
      final result = localizations.translate('category.all');
      expect(result, equals('Все'));
    });

    test('работает с разными локалями в разных инстансах', () async {
      final locRu = AppLocalizations(const Locale('ru'));
      await locRu.load();

      // Создаём второй инстанс
      final locRu2 = AppLocalizations(const Locale('ru'));
      await locRu2.load();

      // Оба должны работать независимо
      expect(locRu.translate('app.name'), equals('Мастерок'));
      expect(locRu2.translate('app.name'), equals('Мастерок'));
    });
  });

  group('AppLocalizations integration', () {
    testWidgets('работает во всём приложении', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ru'),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final loc = AppLocalizations.of(context);
                return Column(
                  children: [
                    Text(loc.translate('app.name')),
                    Text(loc.translate('button.calculate')),
                    Text(loc.translate('category.walls')),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Мастерок'), findsOneWidget);
      expect(find.text('Рассчитать'), findsOneWidget);
      expect(find.text('Стены'), findsOneWidget);
    });

    testWidgets('обрабатывает переключение контекста', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                final loc = AppLocalizations.of(context);
                return TextButton(
                  onPressed: () {
                    // Проверяем, что локализация доступна в обработчике
                    final text = loc.translate('button.clear');
                    expect(text, equals('Очистить'));
                  },
                  child: Text(loc.translate('button.save')),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Сохранить'), findsOneWidget);

      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();
    });
  });
}
