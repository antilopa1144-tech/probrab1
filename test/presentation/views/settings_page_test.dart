import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/presentation/views/settings_page.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUp(() {
    setupMocks();
  });

  group('SettingsPage', () {
    testWidgets('renders settings page with AppBar', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: SettingsPage()),
        ),
      );
      await pumpAndSettleWithTimeout(tester, timeout: const Duration(seconds: 2));

      // Проверяем что страница создаётся
      expect(find.byType(SettingsPage), findsOneWidget);

      // Проверяем что есть AppBar
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
