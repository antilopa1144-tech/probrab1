abstract final class WeatherWorkTypeId {
  static const String paint = 'paint';
  static const String plaster = 'plaster';
  static const String facade = 'facade';
  static const String general = 'general';
}

abstract final class WeatherWorkTypeCatalog {
  static String normalize(String workType) {
    final raw = workType.trim().toLowerCase();
    if (raw.isEmpty) return WeatherWorkTypeId.general;

    if (_matchesAny(raw, const ['paint', 'покраска', 'краска'])) {
      return WeatherWorkTypeId.paint;
    }
    if (_matchesAny(raw, const ['plaster', 'штукатурка', 'шпаклёвка', 'шпаклевка'])) {
      return WeatherWorkTypeId.plaster;
    }
    if (_matchesAny(raw, const ['facade', 'фасад', 'наружн'])) {
      return WeatherWorkTypeId.facade;
    }
    return WeatherWorkTypeId.general;
  }

  static bool _matchesAny(String raw, List<String> tokens) {
    for (final token in tokens) {
      if (raw.contains(token)) return true;
    }
    return false;
  }
}

/// Погодные условия для работ.
class WeatherConditions {
  final double temperature;
  final double humidity;
  final bool isRaining;
  final double windSpeed;
  final DateTime date;

  const WeatherConditions({
    required this.temperature,
    required this.humidity,
    required this.isRaining,
    required this.windSpeed,
    required this.date,
  });
}

/// Рекомендации по погоде для типа работ.
class WeatherAdvice {
  final String workType;
  final bool canWork;
  final List<String> issueKeys;
  final List<Map<String, String>> issueParams;
  final List<String> recommendationKeys;
  final double? minTemperature;
  final double? maxTemperature;
  final double? maxHumidity;
  final bool requiresDryWeather;

  const WeatherAdvice({
    required this.workType,
    required this.canWork,
    this.issueKeys = const [],
    this.issueParams = const [],
    this.recommendationKeys = const [],
    this.minTemperature,
    this.maxTemperature,
    this.maxHumidity,
    this.requiresDryWeather = false,
  });

  /// Проверить условия для конкретного типа работ.
  factory WeatherAdvice.check(
    String workType,
    WeatherConditions conditions,
  ) {
    final normalizedWorkType = WeatherWorkTypeCatalog.normalize(workType);
    final rules = _getWorkRules(normalizedWorkType);

    bool canWork = true;
    final issueKeys = <String>[];
    final issueParams = <Map<String, String>>[];
    final recommendationKeys = <String>[];

    if (rules.minTemperature != null &&
        conditions.temperature < rules.minTemperature!) {
      canWork = false;
      issueKeys.add('weather.issue.temp_low');
      issueParams.add({
        'current': conditions.temperature.toStringAsFixed(1),
        'limit': rules.minTemperature!.toStringAsFixed(1),
      });
    }

    if (rules.maxTemperature != null &&
        conditions.temperature > rules.maxTemperature!) {
      canWork = false;
      issueKeys.add('weather.issue.temp_high');
      issueParams.add({
        'current': conditions.temperature.toStringAsFixed(1),
        'limit': rules.maxTemperature!.toStringAsFixed(1),
      });
    }

    if (rules.maxHumidity != null &&
        conditions.humidity > rules.maxHumidity!) {
      canWork = false;
      issueKeys.add('weather.issue.humidity_high');
      issueParams.add({
        'current': conditions.humidity.toStringAsFixed(0),
        'limit': rules.maxHumidity!.toStringAsFixed(0),
      });
    }

    if (rules.requiresDryWeather && conditions.isRaining) {
      canWork = false;
      issueKeys.add('weather.issue.rain');
      issueParams.add(const {});
    }

    if (conditions.windSpeed > 15 && normalizedWorkType == WeatherWorkTypeId.facade) {
      recommendationKeys.add('weather.recommendation.wind_high');
    }

    if (!canWork) {
      recommendationKeys.add('weather.recommendation.wait');
    } else {
      recommendationKeys.addAll(rules.recommendationKeys);
    }

    return WeatherAdvice(
      workType: normalizedWorkType,
      canWork: canWork,
      issueKeys: issueKeys,
      issueParams: issueParams,
      recommendationKeys: recommendationKeys,
      minTemperature: rules.minTemperature,
      maxTemperature: rules.maxTemperature,
      maxHumidity: rules.maxHumidity,
      requiresDryWeather: rules.requiresDryWeather,
    );
  }

  static WeatherAdvice _getWorkRules(String workType) {
    switch (WeatherWorkTypeCatalog.normalize(workType)) {
      case WeatherWorkTypeId.paint:
        return const WeatherAdvice(
          workType: WeatherWorkTypeId.paint,
        canWork: true,
        recommendationKeys: [
          'weather.recommendation.paint_ideal',
          'weather.recommendation.paint_sun',
          'weather.recommendation.paint_humidity',
        ],
        minTemperature: 5.0,
        maxTemperature: 30.0,
        maxHumidity: 80.0,
        requiresDryWeather: true,
      );
      case WeatherWorkTypeId.plaster:
        return const WeatherAdvice(
          workType: WeatherWorkTypeId.plaster,
        canWork: true,
        recommendationKeys: [
          'weather.recommendation.plaster_temp',
          'weather.recommendation.plaster_draft',
          'weather.recommendation.plaster_dry',
        ],
        minTemperature: 5.0,
        maxTemperature: 35.0,
        maxHumidity: 75.0,
        requiresDryWeather: false,
      );
      case WeatherWorkTypeId.facade:
        return const WeatherAdvice(
          workType: WeatherWorkTypeId.facade,
        canWork: true,
        recommendationKeys: [
          'weather.recommendation.facade_temp',
          'weather.recommendation.facade_rain',
          'weather.recommendation.facade_protect',
        ],
        minTemperature: 5.0,
        maxTemperature: 40.0,
        maxHumidity: 85.0,
        requiresDryWeather: true,
      );
      case WeatherWorkTypeId.general:
        return const WeatherAdvice(
          workType: WeatherWorkTypeId.general,
          canWork: true,
          recommendationKeys: ['weather.recommendation.common'],
          minTemperature: 0.0,
          maxTemperature: 40.0,
          requiresDryWeather: false,
        );
    }

    return const WeatherAdvice(
      workType: WeatherWorkTypeId.general,
      canWork: true,
      recommendationKeys: ['weather.recommendation.common'],
      minTemperature: 0.0,
      maxTemperature: 40.0,
      requiresDryWeather: false,
    );
  }
}

