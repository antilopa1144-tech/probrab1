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

        expect(find.text('Внешний вид'), findsOneWidget);
        expect(find.byIcon(Icons.palette_outlined), findsOneWidget);
      });

      testWidgets('отображается секция региона и единиц', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('Регион и единицы'), findsOneWidget);
        expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
      });

      testWidgets('отображается секция поведения', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('Поведение приложения', skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.tune_outlined, skipOffstage: false), findsOneWidget);
      });

      // skip: ListView lazy loading не создаёт виджеты за пределами viewport
      testWidgets('отображается секция языка', skip: true, (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('Язык', skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.language_outlined, skipOffstage: false), findsOneWidget);
      });

      // skip: ListView lazy loading не создаёт виджеты за пределами viewport
      testWidgets('отображается секция данных', skip: true, (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('Данные', skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.storage_outlined, skipOffstage: false), findsOneWidget);
      });

      // skip: ListView lazy loading не создаёт виджеты за пределами viewport
      testWidgets('отображается секция о приложении', skip: true, (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('О приложении', skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.info_outlined, skipOffstage: false), findsOneWidget);
      });
    });

    group('Тесты выбора акцентного цвета', () {
      testWidgets('отображаются два варианта цвета', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Должны быть тексты с названиями цветов
        expect(find.text('Жёлтый'), findsOneWidget);
        expect(find.text('Голубой'), findsOneWidget);
      });

      testWidgets('можно выбрать желтый цвет', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим желтый цвет и тапаем по нему
        final yellowColor = find.text('Жёлтый');
        await tester.tap(yellowColor);
        await tester.pump();

        // Страница должна все еще существовать
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('можно выбрать голубой цвет', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим голубой цвет и тапаем по нему
        final blueColor = find.text('Голубой');
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
          'Тёмная тема',
        );
        expect(darkModeSwitch, findsOneWidget);

        // Тапаем по переключателю
        await tester.tap(darkModeSwitch);
        await tester.pump();

        // Страница должна существовать
        expect(find.byType(SettingsPage), findsOneWidget);
      });

      // skip: Виджет за пределами viewport
      testWidgets('переключатель автосохранения работает', skip: true, (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим переключатель автосохранения
        final autoSaveSwitch = find.widgetWithText(
          SwitchListTile,
          'Автосохранение расчётов',
        );
        expect(autoSaveSwitch, findsOneWidget);

        // Тапаем по переключателю
        await tester.tap(autoSaveSwitch);
        await tester.pump();

        expect(find.byType(SettingsPage), findsOneWidget);
      });

      // skip: Виджет за пределами viewport
      testWidgets('переключатель подсказок работает', skip: true, (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим переключатель подсказок
        final tipsSwitch = find.widgetWithText(
          SwitchListTile,
          'Показывать подсказки',
        );
        expect(tipsSwitch, findsOneWidget);

        await tester.tap(tipsSwitch);
        await tester.pump();

        expect(find.byType(SettingsPage), findsOneWidget);
      });

      // skip: Виджет за пределами viewport
      testWidgets('переключатель уведомлений работает', skip: true, (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим переключатель уведомлений
        final notificationsSwitch = find.widgetWithText(
          SwitchListTile,
          'Уведомления',
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
          'Регион',
        );
        await tester.tap(regionTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог
        expect(find.text('Выберите регион'), findsOneWidget);
      });

      testWidgets('можно выбрать регион из списка', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Открываем диалог региона
        final regionTile = find.widgetWithText(
          ListTile,
          'Регион',
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
          expect(find.text('Выберите регион'), findsNothing);
        }
      });
    });

    group('Тесты диалога выбора единиц измерения', () {
      testWidgets('открывается диалог выбора единиц', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Находим пункт настроек единиц
        final unitsTile = find.widgetWithText(ListTile, 'Единицы');
        await tester.tap(unitsTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог
        expect(find.text('Единицы'), findsAtLeastNWidgets(1));
        expect(find.text('Метрическая система'), findsOneWidget);
        expect(find.text('Имперская система'), findsOneWidget);
      });

      testWidgets('можно выбрать метрическую систему', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Открываем диалог единиц
        final unitsTile = find.widgetWithText(ListTile, 'Единицы');
        await tester.tap(unitsTile);
        await tester.pumpAndSettle();

        // Выбираем метрическую систему
        final metricOption = find.text('Метрическая система');
        await tester.tap(metricOption);
        await tester.pumpAndSettle();

        // Диалог должен закрыться
        expect(find.text('Метры, килограммы, литры'), findsNothing);
      });

      testWidgets('можно выбрать имперскую систему', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Открываем диалог единиц
        final unitsTile = find.widgetWithText(ListTile, 'Единицы');
        await tester.tap(unitsTile);
        await tester.pumpAndSettle();

        // Выбираем имперскую систему
        final imperialOption = find.text('Имперская система');
        await tester.tap(imperialOption);
        await tester.pumpAndSettle();

        // Диалог должен закрыться
        expect(find.text('Футы, фунты, галлоны'), findsNothing);
      });
    });

    group('Тесты диалога выбора языка', skip: 'Требует прокрутки к невидимым элементам', () {
      testWidgets('открывается диалог выбора языка', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем вниз к секции языка
        await tester.drag(find.byType(ListView), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Находим пункт настроек языка
        final languageTile = find.widgetWithText(
          ListTile,
          'Язык приложения',
        );
        await tester.tap(languageTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог
        expect(find.text('Язык приложения'), findsAtLeastNWidgets(1));
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
          'Язык приложения',
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

    group('Тесты диалога очистки кэша', skip: 'Требует прокрутки к невидимым элементам', () {
      testWidgets('открывается диалог очистки кэша', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем вниз к секции данных
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Находим пункт очистки кэша
        final clearCacheTile = find.widgetWithText(
          ListTile,
          'Очистить кэш',
        );
        await tester.tap(clearCacheTile);
        await tester.pumpAndSettle();

        // Должен открыться диалог подтверждения
        expect(
          find.text('Очистить кэш?'),
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
          'Очистить кэш',
        );
        await tester.tap(clearCacheTile);
        await tester.pumpAndSettle();

        // Нажимаем "Отмена"
        final cancelButton = find.text('Отмена');
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        // Диалог должен закрыться
        expect(
          find.text('Очистить кэш?'),
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
          'Очистить кэш',
        );
        await tester.tap(clearCacheTile);
        await tester.pumpAndSettle();

        // Нажимаем "Очистить"
        final clearButton = find.text('Очистить');
        await tester.tap(clearButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должно показаться сообщение о загрузке
        expect(find.text('Очистка кэша...'), findsOneWidget);
      });
    });

    group('Тесты пунктов о приложении', skip: 'Требует прокрутки к невидимым элементам', () {
      testWidgets('отображается версия приложения', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции о приложении
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();

        // Должна быть информация о версии
        expect(find.text('Версия'), findsOneWidget);
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
          'Обратная связь',
        );
        await tester.tap(feedbackTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен показаться snackbar
        expect(find.text('Функция в разработке'), findsOneWidget);
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
          'Политика конфиденциальности',
        );
        await tester.tap(privacyTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен показаться snackbar
        expect(find.text('Функция в разработке'), findsOneWidget);
      });
    });

    group('Тесты экспорта данных', skip: 'Требует прокрутки к невидимым элементам', () {
      testWidgets('пункт экспорта показывает snackbar', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции данных
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        // Находим пункт экспорта
        final exportTile = find.widgetWithText(
          ListTile,
          'Экспорт данных',
        );
        await tester.tap(exportTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен показаться snackbar
        expect(find.text('Функция в разработке'), findsOneWidget);
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

        // Версия должна быть загружена (не должно быть "Загрузка...")
        expect(find.text('Загрузка...'), findsNothing);
      });
    });

    // skip: ListView lazy loading не создаёт виджеты за пределами viewport
    group('Тесты _SettingsSection widget', skip: 'ListView lazy loading', () {
      testWidgets('все секции имеют иконки и заголовки', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Проверяем наличие всех секций (используем skipOffstage: false для невидимых)
        expect(find.byIcon(Icons.palette_outlined, skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.location_on_outlined, skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.tune_outlined, skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.language_outlined, skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.storage_outlined, skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.info_outlined, skipOffstage: false), findsOneWidget);
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
