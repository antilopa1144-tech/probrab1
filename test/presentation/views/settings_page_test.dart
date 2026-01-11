import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/settings_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMocks();
  });

  group('SettingsPage', () {
    testWidgets('renders settings page with AppBar', (tester) async {
      await tester.pumpWidget(createTestApp(child: const SettingsPage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Проверяем что страница создаётся
      expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);

      // Проверяем что есть AppBar
      expect(find.byType(AppBar, skipOffstage: false), findsOneWidget);
    });

    group('Тесты отображения секций', () {
      testWidgets('отображается секция внешнего вида', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('settings.section.appearance'), findsOneWidget);
        expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      });

      testWidgets('отображается секция региона и единиц', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('settings.section.region_units'), findsOneWidget);
        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('отображается секция поведения', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('settings.section.behavior'), findsOneWidget);
        expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
      });

      testWidgets('отображается секция языка', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('settings.section.language'), findsOneWidget);
        expect(find.byIcon(Icons.language_outlined), findsOneWidget);
      });

      testWidgets('отображается секция данных', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('settings.section.data'), findsOneWidget);
        expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
      });

      testWidgets('отображается секция о приложении', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('settings.section.about'), findsOneWidget);
        expect(find.byIcon(Icons.info_outlined), findsOneWidget);
      });
    });

    group('Тесты выбора акцентного цвета', () {
      testWidgets('отображаются два варианта цвета', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Должны быть тексты с названиями цветов
        expect(find.text('settings.appearance.color.yellow'), findsOneWidget);
        expect(find.text('settings.appearance.color.blue'), findsOneWidget);
      });

      testWidgets('можно выбрать желтый цвет', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим желтый цвет и тапаем по нему
        final yellowColor = find.text('settings.appearance.color.yellow');
        await tester.tap(yellowColor);
        await tester.pump();

        // Страница должна все еще существовать
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('можно выбрать голубой цвет', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим голубой цвет и тапаем по нему
        final blueColor = find.text('settings.appearance.color.blue');
        await tester.tap(blueColor);
        await tester.pump();

        // Страница должна все еще существовать
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Тесты переключателей', () {
      testWidgets('переключатель темной темы работает', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим переключатель темной темы
        final darkModeSwitch = find.widgetWithText(
          SwitchListTile,
          'settings.appearance.dark_theme.title',
        );
        expect(darkModeSwitch, findsOneWidget);

        // Тапаем по переключателю
        await tester.tap(darkModeSwitch);
        await tester.pump();

        // Страница должна существовать
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('переключатель автосохранения работает', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим переключатель автосохранения
        final autoSaveSwitch = find.widgetWithText(
          SwitchListTile,
          'settings.behavior.autosave.title',
        );
        expect(autoSaveSwitch, findsOneWidget);

        // Тапаем по переключателю
        await tester.tap(autoSaveSwitch);
        await tester.pump();

        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('переключатель подсказок работает', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим переключатель подсказок
        final tipsSwitch = find.widgetWithText(
          SwitchListTile,
          'settings.behavior.show_tips.title',
        );
        expect(tipsSwitch, findsOneWidget);

        await tester.tap(tipsSwitch);
        await tester.pump();

        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('переключатель уведомлений работает', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим переключатель уведомлений
        final notificationsSwitch = find.widgetWithText(
          SwitchListTile,
          'settings.behavior.notifications.title',
        );
        expect(notificationsSwitch, findsOneWidget);

        await tester.tap(notificationsSwitch);
        await tester.pump();

        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Тесты диалога выбора региона', () {
      testWidgets('открывается диалог выбора региона', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим пункт настроек региона
        final regionTile = find.widgetWithText(
          ListTile,
          'settings.region.title',
        );
        await tester.tap(regionTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог
        expect(find.text('settings.region.dialog_title'), findsOneWidget);
      });

      testWidgets('можно выбрать регион из списка', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Открываем диалог региона
        final regionTile = find.widgetWithText(
          ListTile,
          'settings.region.title',
        );
        await tester.tap(regionTile);
        await tester.pumpAndSettle();

        // Находим любой регион в списке и выбираем его
        final regionOptions = find.byType(ListTile);
        if (regionOptions.evaluate().length > 1) {
          // Тапаем по первому региону в диалоге (не заголовок)
          await tester.tap(regionOptions.at(1));
          await tester.pumpAndSettle();

          // Диалог должен закрыться
          expect(find.text('settings.region.dialog_title'), findsNothing);
        }
      });
    });

    group('Тесты диалога выбора единиц измерения', () {
      testWidgets('открывается диалог выбора единиц', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим пункт настроек единиц
        final unitsTile = find.widgetWithText(ListTile, 'settings.units.title');
        await tester.tap(unitsTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог
        expect(find.text('settings.units.title'), findsAtLeastNWidgets(1));
        expect(find.text('settings.units.metric.title'), findsOneWidget);
        expect(find.text('settings.units.imperial.title'), findsOneWidget);
      });

      testWidgets('можно выбрать метрическую систему', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Открываем диалог единиц
        final unitsTile = find.widgetWithText(ListTile, 'settings.units.title');
        await tester.tap(unitsTile);
        await tester.pumpAndSettle();

        // Выбираем метрическую систему
        final metricOption = find.text('settings.units.metric.title');
        await tester.tap(metricOption);
        await tester.pumpAndSettle();

        // Диалог должен закрыться
        expect(find.text('settings.units.metric.subtitle'), findsNothing);
      });

      testWidgets('можно выбрать имперскую систему', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Открываем диалог единиц
        final unitsTile = find.widgetWithText(ListTile, 'settings.units.title');
        await tester.tap(unitsTile);
        await tester.pumpAndSettle();

        // Выбираем имперскую систему
        final imperialOption = find.text('settings.units.imperial.title');
        await tester.tap(imperialOption);
        await tester.pumpAndSettle();

        // Диалог должен закрыться
        expect(find.text('settings.units.imperial.subtitle'), findsNothing);
      });
    });

    group('Тесты диалога выбора языка', () {
      testWidgets('открывается диалог выбора языка', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем вниз к секции языка
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Находим пункт настроек языка
        final languageTile = find.widgetWithText(
          ListTile,
          'settings.language.title',
        );
        await tester.tap(languageTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог
        expect(find.text('settings.language.title'), findsAtLeastNWidgets(1));
      });

      testWidgets('можно выбрать язык из списка', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем вниз к секции языка
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Открываем диалог языка
        final languageTile = find.widgetWithText(
          ListTile,
          'settings.language.title',
        );
        await tester.tap(languageTile);
        await tester.pumpAndSettle();

        // Находим варианты языков
        final languageOptions = find.byWidgetPredicate(
          (widget) => widget is ListTile && widget.leading is Icon,
        );

        if (languageOptions.evaluate().isNotEmpty) {
          // Выбираем первый язык
          await tester.tap(languageOptions.first);
          await tester.pumpAndSettle();

          // Диалог должен закрыться
          expect(find.byType(AlertDialog), findsNothing);
        }
      });
    });

    group('Тесты диалога очистки кэша', () {
      testWidgets('открывается диалог очистки кэша', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем вниз к секции данных
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Находим пункт очистки кэша
        final clearCacheTile = find.widgetWithText(
          ListTile,
          'settings.data.clear_cache.title',
        );
        await tester.tap(clearCacheTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог подтверждения
        expect(
          find.text('settings.data.clear_cache.dialog_title'),
          findsOneWidget,
        );
      });

      testWidgets('можно отменить очистку кэша', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем и открываем диалог
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        final clearCacheTile = find.widgetWithText(
          ListTile,
          'settings.data.clear_cache.title',
        );
        await tester.tap(clearCacheTile);
        await tester.pumpAndSettle();

        // Нажимаем "Отмена"
        final cancelButton = find.text('button.cancel');
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Диалог должен закрыться
        expect(
          find.text('settings.data.clear_cache.dialog_title'),
          findsNothing,
        );
      });

      testWidgets('можно подтвердить очистку кэша', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем и открываем диалог
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        final clearCacheTile = find.widgetWithText(
          ListTile,
          'settings.data.clear_cache.title',
        );
        await tester.tap(clearCacheTile);
        await tester.pumpAndSettle();

        // Нажимаем "Очистить"
        final clearButton = find.text('button.clear');
        await tester.tap(clearButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должно показаться сообщение о загрузке
        expect(find.text('settings.data.clear_cache.clearing'), findsOneWidget);
      });
    });

    group('Тесты пунктов о приложении', () {
      testWidgets('отображается версия приложения', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции о приложении
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        // Должна быть информация о версии
        expect(find.text('settings.about.version.title'), findsOneWidget);
      });

      testWidgets('пункт обратной связи показывает snackbar', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции о приложении
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        // Находим пункт обратной связи
        final feedbackTile = find.widgetWithText(
          ListTile,
          'settings.about.feedback.title',
        );
        await tester.tap(feedbackTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен показаться snackbar
        expect(find.text('common.feature_in_development'), findsOneWidget);
      });

      testWidgets('пункт политики конфиденциальности показывает snackbar', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции о приложении
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        // Находим пункт политики конфиденциальности
        final privacyTile = find.widgetWithText(
          ListTile,
          'settings.about.privacy.title',
        );
        await tester.tap(privacyTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен показаться snackbar
        expect(find.text('common.feature_in_development'), findsOneWidget);
      });
    });

    group('Тесты экспорта данных', () {
      testWidgets('пункт экспорта показывает snackbar', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции данных
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Находим пункт экспорта
        final exportTile = find.widgetWithText(
          ListTile,
          'settings.data.export.title',
        );
        await tester.tap(exportTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен показаться snackbar
        expect(find.text('common.feature_in_development'), findsOneWidget);
      });
    });

    group('Тесты загрузки версии приложения', () {
      testWidgets('версия приложения загружается корректно', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));

        // Ждем загрузки версии
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Прокручиваем к секции о приложении
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        // Версия должна быть загружена (не должно быть "common.loading")
        expect(find.text('common.loading'), findsNothing);
      });
    });

    group('Тесты _SettingsSection widget', () {
      testWidgets('все секции имеют иконки и заголовки', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Проверяем наличие всех секций
        expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
        expect(find.byIcon(Icons.tune_outlined), findsOneWidget);
        expect(find.byIcon(Icons.language_outlined), findsOneWidget);
        expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
        expect(find.byIcon(Icons.info_outlined), findsOneWidget);
      });
    });

    testWidgets('страница корректно dispose', (tester) async {
      await tester.pumpWidget(createTestApp(child: const SettingsPage()));
      await tester.pumpAndSettle();

      // Заменяем виджет
      await tester.pumpWidget(createTestApp(child: const SizedBox.shrink()));

      // SettingsPage больше не должен существовать
      expect(find.byType(SettingsPage), findsNothing);
    });
  });
}
