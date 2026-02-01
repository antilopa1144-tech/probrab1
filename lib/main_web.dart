// Веб-версия приложения
// Калькуляторы работают полностью
// Проекты и чек-листы будут добавлены позже с веб-совместимыми моделями

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/accent_color_provider.dart';
import 'core/theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/calculator_memory_service.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/views/calculator/modern_calculator_catalog_screen_web.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Firebase для веба
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    debugPrint('Firebase init error (web): $e');
  }

  final prefs = await SharedPreferences.getInstance();

  // Обработка ошибок
  FlutterError.onError = (details) {
    debugPrint('Flutter Error: ${details.exception}');
  };

  runApp(
    ProviderScope(
      overrides: [
        calculatorMemoryProvider.overrideWithValue(
          CalculatorMemoryService(prefs),
        ),
      ],
      child: const ProbuilderWebApp(),
    ),
  );
}

/// Корневой виджет веб-приложения
class ProbuilderWebApp extends ConsumerWidget {
  const ProbuilderWebApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final settings = ref.watch(settingsProvider);
    final locale = Locale(settings.language);
    final isDarkMode = settings.darkMode;

    return MaterialApp(
      key: ValueKey('web_${settings.language}_${isDarkMode}_${accent.toARGB32()}'),
      title: '${AppConstants.appName} - Веб',
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? AppTheme.darkTheme(accent)
          : AppTheme.lightTheme(accent),
      darkTheme: AppTheme.darkTheme(accent),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const ModernCalculatorCatalogScreenWeb(),
    );
  }
}
