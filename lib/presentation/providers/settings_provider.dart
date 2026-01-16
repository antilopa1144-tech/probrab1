import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/notification_service.dart';

/// Настройки приложения
class AppSettings {
  final String region;
  final String language;
  final bool autoSave;
  final bool notificationsEnabled;
  final String unitSystem; // 'metric' или 'imperial'
  final bool showTips;
  final bool darkMode;

  const AppSettings({
    this.region = 'Москва',
    this.language = 'ru',
    this.autoSave = true,
    this.notificationsEnabled = true,
    this.unitSystem = 'metric',
    this.showTips = true,
    this.darkMode = false,
  });

  AppSettings copyWith({
    String? region,
    String? language,
    bool? autoSave,
    bool? notificationsEnabled,
    String? unitSystem,
    bool? showTips,
    bool? darkMode,
  }) {
    return AppSettings(
      region: region ?? this.region,
      language: language ?? this.language,
      autoSave: autoSave ?? this.autoSave,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      unitSystem: unitSystem ?? this.unitSystem,
      showTips: showTips ?? this.showTips,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'region': region,
      'language': language,
      'autoSave': autoSave,
      'notificationsEnabled': notificationsEnabled,
      'unitSystem': unitSystem,
      'showTips': showTips,
      'darkMode': darkMode,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      region: json['region'] ?? 'Москва',
      language: json['language'] ?? 'ru',
      autoSave: json['autoSave'] ?? true,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      unitSystem: json['unitSystem'] ?? 'metric',
      showTips: json['showTips'] ?? true,
      darkMode: json['darkMode'] ?? false,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Загружаем настройки по отдельности для надежности
    final region = prefs.getString('region') ?? 'Москва';
    final language = prefs.getString('language') ?? 'ru';
    final autoSave = prefs.getBool('autoSave') ?? true;
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    final unitSystem = prefs.getString('unitSystem') ?? 'metric';
    final showTips = prefs.getBool('showTips') ?? true;
    final darkMode = prefs.getBool('darkMode') ?? false;

    state = AppSettings(
      region: region,
      language: language,
      autoSave: autoSave,
      notificationsEnabled: notificationsEnabled,
      unitSystem: unitSystem,
      showTips: showTips,
      darkMode: darkMode,
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('region', state.region);
    await prefs.setString('language', state.language);
    await prefs.setBool('autoSave', state.autoSave);
    await prefs.setBool('notificationsEnabled', state.notificationsEnabled);
    await prefs.setString('unitSystem', state.unitSystem);
    await prefs.setBool('showTips', state.showTips);
    await prefs.setBool('darkMode', state.darkMode);
  }

  Future<void> updateRegion(String region) async {
    state = state.copyWith(region: region);
    await _saveSettings();
  }

  Future<void> updateLanguage(String language) async {
    state = state.copyWith(language: language);
    await _saveSettings();
  }

  Future<void> updateAutoSave(bool autoSave) async {
    state = state.copyWith(autoSave: autoSave);
    await _saveSettings();
  }

  Future<void> updateNotifications(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();

    // Sync with NotificationService
    await NotificationService.setNotificationsEnabled(enabled);
    if (enabled) {
      await NotificationService.requestPermission();
    }
  }

  Future<void> updateUnitSystem(String unitSystem) async {
    state = state.copyWith(unitSystem: unitSystem);
    await _saveSettings();
  }

  Future<void> updateShowTips(bool showTips) async {
    state = state.copyWith(showTips: showTips);
    await _saveSettings();
  }

  Future<void> updateDarkMode(bool darkMode) async {
    state = state.copyWith(darkMode: darkMode);
    await _saveSettings();
  }
}

final settingsProvider = 
    StateNotifierProvider<SettingsNotifier, AppSettings>(
  (ref) => SettingsNotifier(),
);

