import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Режимы темы приложения
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Состояние темы приложения
class ThemeState {
  final AppThemeMode themeMode;
  final Color? primaryColor;
  final bool useSystemTheme;
  final bool useDynamicColors;
  final double fontSize;
  final String fontFamily;

  const ThemeState({
    this.themeMode = AppThemeMode.system,
    this.primaryColor,
    this.useSystemTheme = true,
    this.useDynamicColors = false,
    this.fontSize = 14.0,
    this.fontFamily = 'Roboto',
  });

  ThemeState copyWith({
    AppThemeMode? themeMode,
    Color? primaryColor,
    bool? useSystemTheme,
    bool? useDynamicColors,
    double? fontSize,
    String? fontFamily,
  }) {
    return ThemeState(
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      useSystemTheme: useSystemTheme ?? this.useSystemTheme,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  /// Получить текущую яркость с учётом системной темы
  Brightness getBrightness(Brightness systemBrightness) {
    if (useSystemTheme) {
      return systemBrightness;
    }

    switch (themeMode) {
      case AppThemeMode.light:
        return Brightness.light;
      case AppThemeMode.dark:
        return Brightness.dark;
      case AppThemeMode.system:
        return systemBrightness;
    }
  }

  bool isDark(Brightness systemBrightness) {
    return getBrightness(systemBrightness) == Brightness.dark;
  }

  bool isLight(Brightness systemBrightness) {
    return getBrightness(systemBrightness) == Brightness.light;
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.toString().split('.').last,
      'primaryColor': primaryColor?.toARGB32(),
      'useSystemTheme': useSystemTheme,
      'useDynamicColors': useDynamicColors,
      'fontSize': fontSize,
      'fontFamily': fontFamily,
    };
  }

  factory ThemeState.fromJson(Map<String, dynamic> json) {
    return ThemeState(
      themeMode: _parseThemeMode(json['themeMode'] as String?),
      primaryColor: json['primaryColor'] != null
          ? Color(json['primaryColor'] as int)
          : null,
      useSystemTheme: json['useSystemTheme'] as bool? ?? true,
      useDynamicColors: json['useDynamicColors'] as bool? ?? false,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 14.0,
      fontFamily: json['fontFamily'] as String? ?? 'Roboto',
    );
  }

  static AppThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}

/// Управление темой приложения
class ThemeNotifier extends StateNotifier<ThemeState> {
  ThemeNotifier() : super(const ThemeState()) {
    _loadTheme();
  }

  static const String _prefsKey = 'app_theme';

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);

      if (jsonString != null) {
        // Простое парсинг JSON вручную для надёжности
        final parts = jsonString.split('|');
        if (parts.length >= 6) {
          state = ThemeState(
            themeMode: ThemeState._parseThemeMode(parts[0]),
            primaryColor:
                parts[1].isNotEmpty ? Color(int.parse(parts[1])) : null,
            useSystemTheme: parts[2] == 'true',
            useDynamicColors: parts[3] == 'true',
            fontSize: double.tryParse(parts[4]) ?? 14.0,
            fontFamily: parts[5],
          );
        }
      }
    } catch (e) {
      // Игнорируем ошибки загрузки, используем значения по умолчанию
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Простое сохранение в формате разделённых значений
      final jsonString = [
        state.themeMode.toString().split('.').last,
        state.primaryColor?.toARGB32().toString() ?? '',
        state.useSystemTheme.toString(),
        state.useDynamicColors.toString(),
        state.fontSize.toString(),
        state.fontFamily,
      ].join('|');

      await prefs.setString(_prefsKey, jsonString);
    } catch (e) {
      // Игнорируем ошибки сохранения
    }
  }

  /// Установить режим темы
  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _saveTheme();
  }

  /// Переключиться в светлую тему
  Future<void> setLightTheme() async {
    await setThemeMode(AppThemeMode.light);
    state = state.copyWith(useSystemTheme: false);
    await _saveTheme();
  }

  /// Переключиться в тёмную тему
  Future<void> setDarkTheme() async {
    await setThemeMode(AppThemeMode.dark);
    state = state.copyWith(useSystemTheme: false);
    await _saveTheme();
  }

  /// Использовать системную тему
  Future<void> useSystemTheme() async {
    state = state.copyWith(
      useSystemTheme: true,
      themeMode: AppThemeMode.system,
    );
    await _saveTheme();
  }

  /// Переключить между светлой и тёмной темой
  Future<void> toggleTheme() async {
    if (state.useSystemTheme) {
      // Если используется системная тема, переключаемся на светлую
      await setLightTheme();
    } else {
      switch (state.themeMode) {
        case AppThemeMode.light:
          await setDarkTheme();
          break;
        case AppThemeMode.dark:
          await setLightTheme();
          break;
        case AppThemeMode.system:
          await setLightTheme();
          break;
      }
    }
  }

  /// Установить основной цвет
  Future<void> setPrimaryColor(Color color) async {
    state = state.copyWith(primaryColor: color);
    await _saveTheme();
  }

  /// Сбросить основной цвет
  Future<void> resetPrimaryColor() async {
    state = state.copyWith(primaryColor: null);
    await _saveTheme();
  }

  /// Включить/выключить динамические цвета
  Future<void> setUseDynamicColors(bool value) async {
    state = state.copyWith(useDynamicColors: value);
    await _saveTheme();
  }

  /// Установить размер шрифта
  Future<void> setFontSize(double size) async {
    if (size < 8.0 || size > 32.0) return;

    state = state.copyWith(fontSize: size);
    await _saveTheme();
  }

  /// Увеличить размер шрифта
  Future<void> increaseFontSize() async {
    final newSize = (state.fontSize + 1.0).clamp(8.0, 32.0);
    await setFontSize(newSize);
  }

  /// Уменьшить размер шрифта
  Future<void> decreaseFontSize() async {
    final newSize = (state.fontSize - 1.0).clamp(8.0, 32.0);
    await setFontSize(newSize);
  }

  /// Сбросить размер шрифта
  Future<void> resetFontSize() async {
    await setFontSize(14.0);
  }

  /// Установить семейство шрифтов
  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _saveTheme();
  }

  /// Сбросить настройки темы
  Future<void> resetTheme() async {
    state = const ThemeState();
    await _saveTheme();
  }

  /// Получить яркость с учётом системной темы
  Brightness getBrightness(Brightness systemBrightness) {
    return state.getBrightness(systemBrightness);
  }

  /// Является ли текущая тема тёмной
  bool isDark(Brightness systemBrightness) {
    return state.isDark(systemBrightness);
  }

  /// Является ли текущая тема светлой
  bool isLight(Brightness systemBrightness) {
    return state.isLight(systemBrightness);
  }

  /// Применить предустановленную тему
  Future<void> applyPreset(ThemePreset preset) async {
    switch (preset) {
      case ThemePreset.defaultLight:
        await setLightTheme();
        await resetPrimaryColor();
        await resetFontSize();
        break;
      case ThemePreset.defaultDark:
        await setDarkTheme();
        await resetPrimaryColor();
        await resetFontSize();
        break;
      case ThemePreset.blueLight:
        await setLightTheme();
        await setPrimaryColor(Colors.blue);
        break;
      case ThemePreset.blueDark:
        await setDarkTheme();
        await setPrimaryColor(Colors.blue);
        break;
      case ThemePreset.greenLight:
        await setLightTheme();
        await setPrimaryColor(Colors.green);
        break;
      case ThemePreset.greenDark:
        await setDarkTheme();
        await setPrimaryColor(Colors.green);
        break;
      case ThemePreset.system:
        await useSystemTheme();
        await resetPrimaryColor();
        break;
    }
  }

  /// Экспортировать настройки темы
  Map<String, dynamic> exportSettings() {
    return state.toJson();
  }

  /// Импортировать настройки темы
  Future<void> importSettings(Map<String, dynamic> settings) async {
    try {
      state = ThemeState.fromJson(settings);
      await _saveTheme();
    } catch (e) {
      // Игнорируем ошибки импорта
    }
  }
}

/// Предустановленные темы
enum ThemePreset {
  defaultLight,
  defaultDark,
  blueLight,
  blueDark,
  greenLight,
  greenDark,
  system,
}

/// Провайдер темы
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeState>((ref) {
  return ThemeNotifier();
});

/// Провайдер режима темы (для удобства)
final themeModeProvider = Provider<AppThemeMode>((ref) {
  return ref.watch(themeProvider).themeMode;
});

/// Провайдер текущей яркости (для удобства)
final brightnessProvider = Provider<Brightness>((ref) {
  final themeState = ref.watch(themeProvider);
  // В тестах используем светлую тему по умолчанию
  return themeState.getBrightness(Brightness.light);
});

/// Провайдер является ли тема тёмной (для удобства)
final isDarkThemeProvider = Provider<bool>((ref) {
  return ref.watch(brightnessProvider) == Brightness.dark;
});
