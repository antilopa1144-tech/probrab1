import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants.dart';
import 'presentation/providers/accent_color_provider.dart';
import 'core/theme.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/app/home_main.dart';
import 'presentation/providers/settings_provider.dart';

void main() {
  runApp(const ProviderScope(child: ProbuilderApp()));
}

/// Корневой виджет приложения. Выбирает режим и передаёт управление
/// соответствующему экрану.
class ProbuilderApp extends ConsumerWidget {
  const ProbuilderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(accentColorProvider);
    final settings = ref.watch(settingsProvider);
    final locale = Locale(settings.language);
    final isDarkMode = settings.darkMode;

    return MaterialApp(
      key: ValueKey('${settings.language}_${isDarkMode}_${accent.toARGB32()}'),
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? AppTheme.darkTheme(accent) : AppTheme.lightTheme(accent),
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
      home: const HomeMainScreen(),
    );
  }
}