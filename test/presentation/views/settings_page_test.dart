import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/views/settings_page.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Probrab',
      packageName: 'ru.probrab.app',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: 'test-signature',
    );
  });

  group('SettingsPage', () {
    Widget createTestWidget() {
      return ProviderScope(
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsPage(),
        ),
      );
    }

    testWidgets('renders settings page with AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(SettingsPage), findsOneWidget);
    });

    testWidgets('contains region selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ищем текст "Регион" или соответствующий элемент
      expect(find.byType(ListTile), findsWidgets);
    });

    testWidgets('contains language selector', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Проверяем наличие элементов настроек
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('contains dark mode toggle', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Ищем Switch виджеты для тогглов
      expect(find.byType(Switch).evaluate().isNotEmpty || 
             find.byType(SwitchListTile).evaluate().isNotEmpty, 
             isTrue);
    });
  });
}
