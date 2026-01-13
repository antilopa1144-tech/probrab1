import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeState', () {
    test('создаёт начальное состояние с системной темой', () {
      const state = ThemeState();

      expect(state.themeMode, AppThemeMode.system);
      expect(state.primaryColor, isNull);
      expect(state.useSystemTheme, true);
      expect(state.useDynamicColors, false);
      expect(state.fontSize, 14.0);
      expect(state.fontFamily, 'Roboto');
    });

    test('copyWith создаёт новое состояние с обновлёнными полями', () {
      const state = ThemeState();

      final newState = state.copyWith(
        themeMode: AppThemeMode.dark,
        primaryColor: Colors.blue,
        fontSize: 16.0,
      );

      expect(newState.themeMode, AppThemeMode.dark);
      expect(newState.primaryColor, Colors.blue);
      expect(newState.fontSize, 16.0);
      expect(newState.useSystemTheme, true); // Не изменилось
    });

    test('getBrightness возвращает системную яркость при useSystemTheme', () {
      const state = ThemeState(useSystemTheme: true);

      expect(state.getBrightness(Brightness.light), Brightness.light);
      expect(state.getBrightness(Brightness.dark), Brightness.dark);
    });

    test('getBrightness возвращает светлую яркость для light режима', () {
      const state = ThemeState(
        themeMode: AppThemeMode.light,
        useSystemTheme: false,
      );

      expect(state.getBrightness(Brightness.dark), Brightness.light);
    });

    test('getBrightness возвращает тёмную яркость для dark режима', () {
      const state = ThemeState(
        themeMode: AppThemeMode.dark,
        useSystemTheme: false,
      );

      expect(state.getBrightness(Brightness.light), Brightness.dark);
    });

    test('getBrightness возвращает системную яркость для system режима', () {
      const state = ThemeState(
        themeMode: AppThemeMode.system,
        useSystemTheme: false,
      );

      expect(state.getBrightness(Brightness.light), Brightness.light);
      expect(state.getBrightness(Brightness.dark), Brightness.dark);
    });

    test('isDark определяет тёмную тему', () {
      const lightState = ThemeState(
        themeMode: AppThemeMode.light,
        useSystemTheme: false,
      );
      const darkState = ThemeState(
        themeMode: AppThemeMode.dark,
        useSystemTheme: false,
      );

      expect(lightState.isDark(Brightness.light), false);
      expect(darkState.isDark(Brightness.light), true);
    });

    test('isLight определяет светлую тему', () {
      const lightState = ThemeState(
        themeMode: AppThemeMode.light,
        useSystemTheme: false,
      );
      const darkState = ThemeState(
        themeMode: AppThemeMode.dark,
        useSystemTheme: false,
      );

      expect(lightState.isLight(Brightness.light), true);
      expect(darkState.isLight(Brightness.light), false);
    });

    test('toJson сериализует состояние', () {
      const state = ThemeState(
        themeMode: AppThemeMode.dark,
        primaryColor: Colors.blue,
        useSystemTheme: false,
        useDynamicColors: true,
        fontSize: 16.0,
        fontFamily: 'Arial',
      );

      final json = state.toJson();

      expect(json['themeMode'], 'dark');
      expect(json['primaryColor'], Colors.blue.toARGB32());
      expect(json['useSystemTheme'], false);
      expect(json['useDynamicColors'], true);
      expect(json['fontSize'], 16.0);
      expect(json['fontFamily'], 'Arial');
    });

    test('toJson обрабатывает null значения', () {
      const state = ThemeState();

      final json = state.toJson();

      expect(json['primaryColor'], isNull);
    });

    test('fromJson десериализует состояние', () {
      final json = {
        'themeMode': 'dark',
        'primaryColor': Colors.red.toARGB32(),
        'useSystemTheme': false,
        'useDynamicColors': true,
        'fontSize': 18.0,
        'fontFamily': 'Times',
      };

      final state = ThemeState.fromJson(json);

      expect(state.themeMode, AppThemeMode.dark);
      expect(state.primaryColor, Color(Colors.red.toARGB32()));
      expect(state.useSystemTheme, false);
      expect(state.useDynamicColors, true);
      expect(state.fontSize, 18.0);
      expect(state.fontFamily, 'Times');
    });

    test('fromJson использует значения по умолчанию для отсутствующих полей',
        () {
      final state = ThemeState.fromJson({});

      expect(state.themeMode, AppThemeMode.system);
      expect(state.primaryColor, isNull);
      expect(state.useSystemTheme, true);
      expect(state.useDynamicColors, false);
      expect(state.fontSize, 14.0);
      expect(state.fontFamily, 'Roboto');
    });

    test('fromJson корректно парсит все режимы темы', () {
      expect(ThemeState.fromJson({'themeMode': 'light'}).themeMode,
          AppThemeMode.light);
      expect(ThemeState.fromJson({'themeMode': 'dark'}).themeMode,
          AppThemeMode.dark);
      expect(ThemeState.fromJson({'themeMode': 'system'}).themeMode,
          AppThemeMode.system);
      expect(ThemeState.fromJson({'themeMode': 'invalid'}).themeMode,
          AppThemeMode.system);
    });
  });

  group('ThemeNotifier - установка режима темы', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      // Ждём загрузки настроек
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('setThemeMode устанавливает режим темы', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setThemeMode(AppThemeMode.dark);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
    });

    test('setLightTheme переключает на светлую тему', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setLightTheme();

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
      expect(state.useSystemTheme, false);
    });

    test('setDarkTheme переключает на тёмную тему', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.useSystemTheme, false);
    });

    test('useSystemTheme включает системную тему', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();
      await notifier.useSystemTheme();

      final state = container.read(themeProvider);
      expect(state.useSystemTheme, true);
      expect(state.themeMode, AppThemeMode.system);
    });

    test('toggleTheme переключает между светлой и тёмной', () async {
      final notifier = container.read(themeProvider.notifier);

      // С системной на светлую
      await notifier.toggleTheme();
      var state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);

      // Со светлой на тёмную
      await notifier.toggleTheme();
      state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);

      // С тёмной на светлую
      await notifier.toggleTheme();
      state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
    });

    test('toggleTheme с system режимом переходит в light', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setThemeMode(AppThemeMode.system);
      await notifier.toggleTheme();

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
      expect(state.useSystemTheme, false);
    });
  });

  group('ThemeNotifier - настройка цветов', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('setPrimaryColor устанавливает основной цвет', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setPrimaryColor(Colors.blue);

      final state = container.read(themeProvider);
      expect(state.primaryColor, Colors.blue);
    });

    test('resetPrimaryColor сбрасывает основной цвет', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setPrimaryColor(Colors.blue);
      await notifier.resetPrimaryColor();

      final state = container.read(themeProvider);
      expect(state.primaryColor, isNull);
    });

    test('setUseDynamicColors включает динамические цвета', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setUseDynamicColors(true);

      final state = container.read(themeProvider);
      expect(state.useDynamicColors, true);
    });

    test('setUseDynamicColors выключает динамические цвета', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setUseDynamicColors(true);
      await notifier.setUseDynamicColors(false);

      final state = container.read(themeProvider);
      expect(state.useDynamicColors, false);
    });
  });

  group('ThemeNotifier - настройка шрифтов', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('setFontSize устанавливает размер шрифта', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(16.0);

      final state = container.read(themeProvider);
      expect(state.fontSize, 16.0);
    });

    test('setFontSize игнорирует слишком маленькие значения', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(5.0);

      final state = container.read(themeProvider);
      expect(state.fontSize, 14.0); // Не изменился
    });

    test('setFontSize игнорирует слишком большие значения', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(50.0);

      final state = container.read(themeProvider);
      expect(state.fontSize, 14.0); // Не изменился
    });

    test('increaseFontSize увеличивает размер шрифта', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(14.0);
      await notifier.increaseFontSize();

      final state = container.read(themeProvider);
      expect(state.fontSize, 15.0);
    });

    test('increaseFontSize не превышает максимум', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(32.0);
      await notifier.increaseFontSize();

      final state = container.read(themeProvider);
      expect(state.fontSize, 32.0); // Не превысил максимум
    });

    test('decreaseFontSize уменьшает размер шрифта', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(16.0);
      await notifier.decreaseFontSize();

      final state = container.read(themeProvider);
      expect(state.fontSize, 15.0);
    });

    test('decreaseFontSize не опускается ниже минимума', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(8.0);
      await notifier.decreaseFontSize();

      final state = container.read(themeProvider);
      expect(state.fontSize, 8.0); // Не опустился ниже минимума
    });

    test('resetFontSize сбрасывает размер шрифта', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontSize(20.0);
      await notifier.resetFontSize();

      final state = container.read(themeProvider);
      expect(state.fontSize, 14.0);
    });

    test('setFontFamily устанавливает семейство шрифтов', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setFontFamily('Arial');

      final state = container.read(themeProvider);
      expect(state.fontFamily, 'Arial');
    });
  });

  group('ThemeNotifier - персистентность', () {
    test('сохраняет и загружает настройки темы', () async {
      SharedPreferences.setMockInitialValues({});

      // Создаём первый контейнер и устанавливаем настройки
      var container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(themeProvider.notifier);
      await notifier.setDarkTheme();
      await notifier.setPrimaryColor(Colors.blue);
      await notifier.setFontSize(16.0);
      await notifier.setFontFamily('Arial');

      await Future.delayed(const Duration(milliseconds: 50));
      container.dispose();

      // Создаём новый контейнер и проверяем что настройки загрузились
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.primaryColor, Color(Colors.blue.toARGB32()));
      expect(state.fontSize, 16.0);
      expect(state.fontFamily, 'Arial');

      container.dispose();
    });

    test('работает с пустыми настройками при первом запуске', () async {
      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system);
      expect(state.primaryColor, isNull);

      container.dispose();
    });

    test('игнорирует повреждённые данные при загрузке', () async {
      SharedPreferences.setMockInitialValues({
        'app_theme': 'corrupted_data',
      });

      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system); // Значения по умолчанию

      container.dispose();
    });
  });

  group('ThemeNotifier - предустановки', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('applyPreset применяет defaultLight', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.applyPreset(ThemePreset.defaultLight);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
      expect(state.primaryColor, isNull);
      expect(state.fontSize, 14.0);
    });

    test('applyPreset применяет defaultDark', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.applyPreset(ThemePreset.defaultDark);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.primaryColor, isNull);
    });

    test('applyPreset применяет blueLight', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.applyPreset(ThemePreset.blueLight);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
      expect(state.primaryColor, Colors.blue);
    });

    test('applyPreset применяет blueDark', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.applyPreset(ThemePreset.blueDark);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.primaryColor, Colors.blue);
    });

    test('applyPreset применяет greenLight', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.applyPreset(ThemePreset.greenLight);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
      expect(state.primaryColor, Colors.green);
    });

    test('applyPreset применяет greenDark', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.applyPreset(ThemePreset.greenDark);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.primaryColor, Colors.green);
    });

    test('applyPreset применяет system', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();
      await notifier.applyPreset(ThemePreset.system);

      final state = container.read(themeProvider);
      expect(state.useSystemTheme, true);
      expect(state.primaryColor, isNull);
    });
  });

  group('ThemeNotifier - импорт/экспорт', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('exportSettings экспортирует настройки', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();
      await notifier.setPrimaryColor(Colors.red);
      await notifier.setFontSize(18.0);

      final settings = notifier.exportSettings();

      expect(settings['themeMode'], 'dark');
      expect(settings['primaryColor'], Colors.red.toARGB32());
      expect(settings['fontSize'], 18.0);
    });

    test('importSettings импортирует настройки', () async {
      final notifier = container.read(themeProvider.notifier);

      final settings = {
        'themeMode': 'light',
        'primaryColor': Colors.green.toARGB32(),
        'useSystemTheme': false,
        'useDynamicColors': true,
        'fontSize': 20.0,
        'fontFamily': 'Times',
      };

      await notifier.importSettings(settings);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
      expect(state.primaryColor, Color(Colors.green.toARGB32()));
      expect(state.useSystemTheme, false);
      expect(state.useDynamicColors, true);
      expect(state.fontSize, 20.0);
      expect(state.fontFamily, 'Times');
    });

    test('importSettings игнорирует некорректные данные', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();

      // Импортируем некорректные данные
      await notifier.importSettings({'invalid': 'data'});

      // Состояние должно измениться на значения по умолчанию
      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system);
    });
  });

  group('ThemeNotifier - вспомогательные методы', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('resetTheme сбрасывает все настройки', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();
      await notifier.setPrimaryColor(Colors.blue);
      await notifier.setFontSize(20.0);
      await notifier.setFontFamily('Arial');

      await notifier.resetTheme();

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system);
      expect(state.primaryColor, isNull);
      expect(state.fontSize, 14.0);
      expect(state.fontFamily, 'Roboto');
    });

    test('getBrightness возвращает текущую яркость', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();

      final brightness = notifier.getBrightness(Brightness.light);
      expect(brightness, Brightness.dark);
    });

    test('isDark определяет тёмную тему', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setLightTheme();
      expect(notifier.isDark(Brightness.light), false);

      await notifier.setDarkTheme();
      expect(notifier.isDark(Brightness.light), true);
    });

    test('isLight определяет светлую тему', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setLightTheme();
      expect(notifier.isLight(Brightness.light), true);

      await notifier.setDarkTheme();
      expect(notifier.isLight(Brightness.light), false);
    });
  });

  group('ThemeNotifier - вспомогательные провайдеры', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      container.dispose();
    });

    test('themeModeProvider возвращает режим темы', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setDarkTheme();

      final themeMode = container.read(themeModeProvider);
      expect(themeMode, AppThemeMode.dark);
    });

    test('brightnessProvider возвращает яркость', () {
      final brightness = container.read(brightnessProvider);
      expect(brightness, isA<Brightness>());
    });

    test('isDarkThemeProvider определяет тёмную тему', () async {
      final notifier = container.read(themeProvider.notifier);

      await notifier.setLightTheme();
      var isDark = container.read(isDarkThemeProvider);
      expect(isDark, false);

      await notifier.setDarkTheme();
      isDark = container.read(isDarkThemeProvider);
      expect(isDark, true);
    });
  });

  group('ThemeNotifier - интеграционные тесты', () {
    test('полный цикл работы с темой', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(themeProvider.notifier);

      // 1. Начальное состояние
      var state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system);

      // 2. Устанавливаем светлую тему
      await notifier.setLightTheme();
      state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);

      // 3. Настраиваем внешний вид
      await notifier.setPrimaryColor(Colors.blue);
      await notifier.setFontSize(16.0);

      state = container.read(themeProvider);
      expect(state.primaryColor, Colors.blue);
      expect(state.fontSize, 16.0);

      // 4. Переключаем на тёмную
      await notifier.toggleTheme();
      state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);

      // 5. Сбрасываем
      await notifier.resetTheme();
      state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.system);
      expect(state.primaryColor, isNull);

      container.dispose();
    });

    test('работа с размером шрифта', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(themeProvider.notifier);

      // Увеличиваем несколько раз
      await notifier.increaseFontSize();
      await notifier.increaseFontSize();
      await notifier.increaseFontSize();

      var state = container.read(themeProvider);
      expect(state.fontSize, 17.0);

      // Уменьшаем
      await notifier.decreaseFontSize();

      state = container.read(themeProvider);
      expect(state.fontSize, 16.0);

      // Сбрасываем
      await notifier.resetFontSize();

      state = container.read(themeProvider);
      expect(state.fontSize, 14.0);

      container.dispose();
    });

    test('смена предустановок темы', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(themeProvider.notifier);

      // Применяем разные предустановки
      await notifier.applyPreset(ThemePreset.blueLight);
      var state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.light);
      expect(state.primaryColor, Colors.blue);

      await notifier.applyPreset(ThemePreset.greenDark);
      state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.primaryColor, Colors.green);

      await notifier.applyPreset(ThemePreset.system);
      state = container.read(themeProvider);
      expect(state.useSystemTheme, true);

      container.dispose();
    });

    test('экспорт и импорт настроек', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));

      final notifier = container.read(themeProvider.notifier);

      // Настраиваем тему
      await notifier.setDarkTheme();
      await notifier.setPrimaryColor(Colors.purple);
      await notifier.setFontSize(18.0);
      await notifier.setFontFamily('Georgia');

      // Экспортируем
      final settings = notifier.exportSettings();

      // Сбрасываем
      await notifier.resetTheme();

      // Импортируем обратно
      await notifier.importSettings(settings);

      final state = container.read(themeProvider);
      expect(state.themeMode, AppThemeMode.dark);
      expect(state.primaryColor, Color(Colors.purple.toARGB32()));
      expect(state.fontSize, 18.0);
      expect(state.fontFamily, 'Georgia');

      container.dispose();
    });
  });
}
