import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/weather_advice.dart';

void main() {
  group('WeatherConditions', () {
    test('creates with required parameters', () {
      final conditions = WeatherConditions(
        temperature: 20.0,
        humidity: 60.0,
        isRaining: false,
        windSpeed: 5.0,
        date: DateTime(2024, 6, 15),
      );

      expect(conditions.temperature, 20.0);
      expect(conditions.humidity, 60.0);
      expect(conditions.isRaining, isFalse);
      expect(conditions.windSpeed, 5.0);
      expect(conditions.date, DateTime(2024, 6, 15));
    });
  });

  group('WeatherAdvice', () {
    test('creates with required parameters', () {
      const advice = WeatherAdvice(
        workType: 'painting',
        canWork: true,
        reason: 'Good conditions',
      );

      expect(advice.workType, 'painting');
      expect(advice.canWork, isTrue);
      expect(advice.reason, 'Good conditions');
      expect(advice.recommendations, isEmpty);
      expect(advice.minTemperature, isNull);
      expect(advice.maxTemperature, isNull);
      expect(advice.maxHumidity, isNull);
      expect(advice.requiresDryWeather, isFalse);
    });

    test('creates with all parameters', () {
      const advice = WeatherAdvice(
        workType: 'painting',
        canWork: true,
        reason: 'Good',
        recommendations: ['Tip 1', 'Tip 2'],
        minTemperature: 5.0,
        maxTemperature: 30.0,
        maxHumidity: 80.0,
        requiresDryWeather: true,
      );

      expect(advice.recommendations.length, 2);
      expect(advice.minTemperature, 5.0);
      expect(advice.maxTemperature, 30.0);
      expect(advice.maxHumidity, 80.0);
      expect(advice.requiresDryWeather, isTrue);
    });

    group('check factory', () {
      test('allows work in good conditions for painting', () {
        final conditions = WeatherConditions(
          temperature: 20.0,
          humidity: 50.0,
          isRaining: false,
          windSpeed: 5.0,
          date: DateTime(2024, 6, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isTrue);
        expect(advice.workType, 'покраска');
      });

      test('rejects work in rain for painting', () {
        final conditions = WeatherConditions(
          temperature: 20.0,
          humidity: 50.0,
          isRaining: true,
          windSpeed: 5.0,
          date: DateTime(2024, 6, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isFalse);
        expect(advice.reason, contains('дождь'));
      });

      test('rejects work in low temperature for painting', () {
        final conditions = WeatherConditions(
          temperature: 0.0,
          humidity: 50.0,
          isRaining: false,
          windSpeed: 5.0,
          date: DateTime(2024, 1, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isFalse);
        expect(advice.reason, contains('низкая'));
      });

      test('rejects work in high temperature for painting', () {
        final conditions = WeatherConditions(
          temperature: 40.0,
          humidity: 50.0,
          isRaining: false,
          windSpeed: 5.0,
          date: DateTime(2024, 7, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isFalse);
        expect(advice.reason, contains('высокая'));
      });

      test('rejects work in high humidity for painting', () {
        final conditions = WeatherConditions(
          temperature: 20.0,
          humidity: 95.0,
          isRaining: false,
          windSpeed: 5.0,
          date: DateTime(2024, 6, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isFalse);
        expect(advice.reason, contains('Влажность'));
      });

      test('allows work for plastering (штукатурка)', () {
        final conditions = WeatherConditions(
          temperature: 20.0,
          humidity: 60.0,
          isRaining: false,
          windSpeed: 5.0,
          date: DateTime(2024, 6, 15),
        );

        final advice = WeatherAdvice.check('штукатурка', conditions);

        expect(advice.canWork, isTrue);
      });

      test('provides recommendations for facade work in strong wind', () {
        final conditions = WeatherConditions(
          temperature: 20.0,
          humidity: 50.0,
          isRaining: false,
          windSpeed: 20.0,
          date: DateTime(2024, 6, 15),
        );

        final advice = WeatherAdvice.check('фасад', conditions);

        expect(
          advice.recommendations.any((r) => r.contains('ветер')),
          isTrue,
        );
      });

      test('uses default rules for unknown work type', () {
        final conditions = WeatherConditions(
          temperature: 20.0,
          humidity: 50.0,
          isRaining: false,
          windSpeed: 5.0,
          date: DateTime(2024, 6, 15),
        );

        final advice = WeatherAdvice.check('unknown_work', conditions);

        expect(advice.canWork, isTrue);
      });

      test('adds recommendation to postpone when cannot work', () {
        final conditions = WeatherConditions(
          temperature: -10.0,
          humidity: 50.0,
          isRaining: false,
          windSpeed: 5.0,
          date: DateTime(2024, 1, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isFalse);
        expect(
          advice.recommendations.any((r) => r.contains('Отложите')),
          isTrue,
        );
      });

      test('returns multiple reasons when multiple conditions fail', () {
        final conditions = WeatherConditions(
          temperature: 0.0,
          humidity: 95.0,
          isRaining: true,
          windSpeed: 5.0,
          date: DateTime(2024, 1, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isFalse);
        // Should have multiple failure reasons joined with ;
        expect(advice.reason, contains(';'));
      });
    });
  });
}
