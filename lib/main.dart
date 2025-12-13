import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'presentation/providers/accent_color_provider.dart';
import 'core/theme.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/app/main_shell.dart';
import 'presentation/providers/settings_provider.dart';
import 'core/errors/global_error_handler.dart';
import 'presentation/views/onboarding/onboarding_screen.dart';
import 'core/performance/frame_timing_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FrameTimingLogger.maybeInit();

  // Инициализация Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Передача Flutter ошибок в Crashlytics
  FlutterError.onError = (details) {
    // Логирование в консоль и Firebase
    GlobalErrorHandler.logFatalError(
      details.exception,
      details.stack ?? StackTrace.current,
      'FlutterError',
    );

    // Также отправляем напрямую в Crashlytics
    try {
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    } catch (e) {
      // Игнорируем ошибки Firebase, если сервис недоступен
    }
  };

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
      home: const _HomeSelector(),
    );
  }
}

/// Виджет, который выбирает между онбордингом и главным экраном.
class _HomeSelector extends ConsumerStatefulWidget {
  const _HomeSelector();

  @override
  ConsumerState<_HomeSelector> createState() => _HomeSelectorState();
}

class _HomeSelectorState extends ConsumerState<_HomeSelector> {
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    final shouldShow = await OnboardingScreen.shouldShow();
    setState(() {
      _showOnboarding = shouldShow;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_showOnboarding) {
      return const OnboardingScreen();
    }

    return const MainShell();
  }
}
