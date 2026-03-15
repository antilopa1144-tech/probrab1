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
      );

      expect(advice.workType, 'painting');
      expect(advice.canWork, isTrue);
      expect(advice.issueKeys, isEmpty);
      expect(advice.recommendationKeys, isEmpty);
      expect(advice.minTemperature, isNull);
      expect(advice.maxTemperature, isNull);
      expect(advice.maxHumidity, isNull);
      expect(advice.requiresDryWeather, isFalse);
    });

    test('creates with all parameters', () {
      const advice = WeatherAdvice(
        workType: 'painting',
        canWork: true,
        issueKeys: ['weather.issue.temp_low'],
        recommendationKeys: ['Tip 1', 'Tip 2'],
        minTemperature: 5.0,
        maxTemperature: 30.0,
        maxHumidity: 80.0,
        requiresDryWeather: true,
      );

      expect(advice.recommendationKeys.length, 2);
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
        expect(advice.workType, WeatherWorkTypeId.paint);
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
        expect(advice.issueKeys, contains('weather.issue.rain'));
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
        expect(advice.issueKeys, contains('weather.issue.temp_low'));
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
        expect(advice.issueKeys, contains('weather.issue.temp_high'));
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
        expect(advice.issueKeys, contains('weather.issue.humidity_high'));
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
          advice.recommendationKeys.any((r) => r.contains('wind_high')),
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
          advice.recommendationKeys.any((r) => r.contains('wait')),
          isTrue,
        );
      });

      test('returns multiple issues when multiple conditions fail', () {
        final conditions = WeatherConditions(
          temperature: 0.0,
          humidity: 95.0,
          isRaining: true,
          windSpeed: 5.0,
          date: DateTime(2024, 1, 15),
        );

        final advice = WeatherAdvice.check('покраска', conditions);

        expect(advice.canWork, isFalse);
        // Should have multiple failure issue keys
        expect(advice.issueKeys.length, greaterThan(1));
      });
    });
  });
}
