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
      await tester.pumpWidget(
        createTestApp(child: const SettingsPage()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Проверяем что страница создаётся
      expect(find.byType(SettingsPage, skipOffstage: false), findsOneWidget);

      // Проверяем что есть AppBar
      expect(find.byType(AppBar, skipOffstage: false), findsOneWidget);
    });
  });
}
