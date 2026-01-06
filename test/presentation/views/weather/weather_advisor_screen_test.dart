import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/views/weather/weather_advisor_screen.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('WeatherAdvisorScreen', () {
    testWidgets('renders with app bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Погодные рекомендации'), findsOneWidget);
    });

    testWidgets('shows current conditions card', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Текущие условия'), findsOneWidget);
    });

    testWidgets('shows temperature input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Температура (°C)'), findsOneWidget);
      expect(find.byIcon(Icons.thermostat), findsOneWidget);
    });

    testWidgets('shows humidity input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Влажность (%)'), findsOneWidget);
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
    });

    testWidgets('shows rain switch', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Идёт дождь'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('shows wind speed input', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Скорость ветра (м/с)'), findsOneWidget);
      expect(find.byIcon(Icons.air), findsOneWidget);
    });

    testWidgets('shows positive result for good conditions', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      // Default values are good (temp=20, humidity=50, no rain)
      expect(find.text('Условия подходят для работ'), findsWidgets);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('can toggle rain switch', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      // Initially off
      final switchFinder = find.byType(Switch);
      expect(tester.widget<Switch>(switchFinder).value, false);

      // Toggle on
      await tester.tap(find.text('Идёт дождь'));
      await tester.pump();

      // Should show negative result (painting requires dry weather)
      expect(find.text('Условия не подходят'), findsOneWidget);
    });

    testWidgets('updates when temperature changes', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      // Initially shows good conditions
      expect(find.text('Условия подходят для работ'), findsWidgets);

      // Find the temperature TextField and enter very low temperature
      final tempFields = find.byType(TextField);
      await tester.enterText(tempFields.first, '-10');
      await tester.pump();

      // Should show negative result
      expect(find.text('Условия не подходят'), findsOneWidget);
    });

    testWidgets('shows recommendations section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Рекомендации'), findsOneWidget);
    });

    testWidgets('shows limitations section', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.text('Ограничения'), findsOneWidget);
    });

    testWidgets('shows min temperature limit', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.textContaining('Минимальная температура'), findsOneWidget);
    });

    testWidgets('shows max temperature limit', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.textContaining('Максимальная температура'), findsOneWidget);
    });

    testWidgets('works with different work types', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'штукатурка'),
        ),
      );

      expect(find.text('Погодные рекомендации'), findsOneWidget);
      // The text appears in both the header and reason field
      expect(find.text('Условия подходят для работ'), findsWidgets);
    });

    testWidgets('scrollable content', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const WeatherAdvisorScreen(workType: 'покраска'),
        ),
      );

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });
}
