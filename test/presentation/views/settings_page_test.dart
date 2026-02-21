import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/settings_page.dart';

import '../../helpers/test_helpers.dart';

/// Вспомогательная функция для прокрутки ListView до видимости элемента.
/// Использует scrollUntilVisible, который инкрементально прокручивает
/// Scrollable до тех пор, пока виджет не будет создан и виден.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200.0,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

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

      testWidgets('отображается секция поведения', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        expect(find.text('Поведение приложения', skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.tune_outlined, skipOffstage: false), findsOneWidget);
      });

      testWidgets('отображается секция данных', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции данных
        await _scrollTo(tester, find.text('Данные'));

        expect(find.text('Данные'), findsOneWidget);
        expect(find.byIcon(Icons.storage_outlined), findsOneWidget);
      });

      testWidgets('отображается секция о приложении', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к секции о приложении
        await _scrollTo(tester, find.text('О приложении'));

        expect(find.text('О приложении'), findsOneWidget);
        expect(find.byIcon(Icons.info_outlined), findsOneWidget);
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

      testWidgets('переключатель автосохранения работает', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к переключателю автосохранения
        final autoSaveSwitch = find.widgetWithText(
          SwitchListTile,
          'Автосохранение расчётов',
        );
        await _scrollTo(tester, autoSaveSwitch);

        expect(autoSaveSwitch, findsOneWidget);

        // Тапаем по переключателю
        await tester.tap(autoSaveSwitch);
        await tester.pump();

        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('переключатель подсказок работает', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к переключателю подсказок
        final tipsSwitch = find.widgetWithText(
          SwitchListTile,
          'Показывать подсказки',
        );
        await _scrollTo(tester, tipsSwitch);

        expect(tipsSwitch, findsOneWidget);

        await tester.tap(tipsSwitch);
        await tester.pump();

        expect(find.byType(SettingsPage), findsOneWidget);
      });

      testWidgets('переключатель уведомлений отображается', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к переключателю уведомлений
        final notificationsSwitch = find.widgetWithText(
          SwitchListTile,
          'Уведомления',
        );
        await _scrollTo(tester, notificationsSwitch);

        expect(notificationsSwitch, findsOneWidget);

        // Примечание: тап по переключателю не тестируем, т.к.
        // FlutterLocalNotificationsPlugin не инициализирован
        // в тестовом окружении и вызывает LateInitializationError.
        // Для полного теста нужен мок NotificationService.
        expect(find.byType(SettingsPage), findsOneWidget);
      });
    });

    group('Тесты диалога очистки кэша', () {
      testWidgets('открывается диалог очистки кэша', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к пункту очистки кэша
        final clearCacheTile = find.widgetWithText(
          ListTile,
          'Очистить кэш',
        );
        await _scrollTo(tester, clearCacheTile);

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

        // Прокручиваем к пункту очистки кэша
        final clearCacheTile = find.widgetWithText(
          ListTile,
          'Очистить кэш',
        );
        await _scrollTo(tester, clearCacheTile);

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

        // Прокручиваем к пункту очистки кэша
        final clearCacheTile = find.widgetWithText(
          ListTile,
          'Очистить кэш',
        );
        await _scrollTo(tester, clearCacheTile);

        await tester.tap(clearCacheTile);
        await tester.pumpAndSettle();

        // Нажимаем "Очистить"
        final clearButton = find.text('Очистить');
        await tester.tap(clearButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должно показаться сообщение о загрузке
        expect(find.text('Очистка кэша...'), findsOneWidget);

        // Прокачиваем таймер Future.delayed(800ms) из _showClearCacheDialog
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();
      });
    });

    group('Тесты пунктов о приложении', () {
      testWidgets('отображается версия приложения', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к пункту версии
        await _scrollTo(tester, find.text('Версия'));

        // Должна быть информация о версии
        expect(find.text('Версия'), findsOneWidget);
      });

      testWidgets('пункт оценки приложения отображается', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к пункту оценки приложения
        final rateAppTile = find.widgetWithText(
          ListTile,
          'Оценить приложение',
        );
        await _scrollTo(tester, rateAppTile);

        expect(rateAppTile, findsOneWidget);
        expect(find.text('Оставьте отзыв в RuStore'), findsOneWidget);
      });

      testWidgets('пункт политики конфиденциальности показывает snackbar', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к пункту политики конфиденциальности
        final privacyTile = find.widgetWithText(
          ListTile,
          'Политика конфиденциальности',
        );
        await _scrollTo(tester, privacyTile);

        await tester.tap(privacyTile);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Должен показаться snackbar
        expect(find.text('Функция в разработке'), findsOneWidget);
      });
    });

    group('Тесты экспорта данных', () {
      testWidgets('пункт экспорта показывает snackbar', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Прокручиваем к пункту экспорта
        final exportTile = find.widgetWithText(
          ListTile,
          'Экспорт данных',
        );
        await _scrollTo(tester, exportTile);

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
        await _scrollTo(tester, find.text('Версия'));

        // Версия должна быть загружена (не должно быть "Загрузка...")
        expect(find.text('Загрузка...'), findsNothing);
      });
    });

    group('Тесты _SettingsSection widget', () {
      testWidgets('все секции имеют иконки и заголовки', (tester) async {
        await tester.pumpWidget(createTestApp(child: const SettingsPage()));
        await tester.pumpAndSettle();

        // Проверяем каждую секцию последовательно, прокручивая к ней.
        // После прокрутки предыдущие секции могут покинуть viewport,
        // поэтому проверяем по одной.

        // Секция 1: Внешний вид (видна без прокрутки)
        expect(find.byIcon(Icons.palette_outlined), findsOneWidget);

        // Секция 2: Поведение (может быть на границе viewport)
        await _scrollTo(tester, find.byIcon(Icons.tune_outlined));
        expect(find.byIcon(Icons.tune_outlined), findsOneWidget);

        // Секция 3: Данные
        await _scrollTo(tester, find.byIcon(Icons.storage_outlined));
        expect(find.byIcon(Icons.storage_outlined), findsOneWidget);

        // Секция 4: О приложении
        await _scrollTo(tester, find.byIcon(Icons.info_outlined));
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
