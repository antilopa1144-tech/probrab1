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
  final String reason;
  final List<String> recommendations;
  final double? minTemperature;
  final double? maxTemperature;
  final double? maxHumidity;
  final bool requiresDryWeather;

  const WeatherAdvice({
    required this.workType,
    required this.canWork,
    required this.reason,
    this.recommendations = const [],
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
    final rules = _getWorkRules(workType);
    
    bool canWork = true;
    final reasons = <String>[];
    final recommendations = <String>[];
    
    // Проверка температуры
    if (rules.minTemperature != null && 
        conditions.temperature < rules.minTemperature!) {
      canWork = false;
      reasons.add('Температура слишком низкая (${conditions.temperature}°C < ${rules.minTemperature}°C)');
    }
    
    if (rules.maxTemperature != null && 
        conditions.temperature > rules.maxTemperature!) {
      canWork = false;
      reasons.add('Температура слишком высокая (${conditions.temperature}°C > ${rules.maxTemperature}°C)');
    }
    
    // Проверка влажности
    if (rules.maxHumidity != null && 
        conditions.humidity > rules.maxHumidity!) {
      canWork = false;
      reasons.add('Влажность слишком высокая (${conditions.humidity}% > ${rules.maxHumidity}%)');
    }
    
    // Проверка дождя
    if (rules.requiresDryWeather && conditions.isRaining) {
      canWork = false;
      reasons.add('Требуется сухая погода, идёт дождь');
    }
    
    // Проверка ветра
    if (conditions.windSpeed > 15 && workType.contains('фасад')) {
      recommendations.add('Сильный ветер - будьте осторожны при работе на высоте');
    }
    
    if (!canWork) {
      recommendations.add('Отложите работы до улучшения погодных условий');
    } else {
      recommendations.addAll(rules.recommendations);
    }
    
    return WeatherAdvice(
      workType: workType,
      canWork: canWork,
      reason: reasons.isEmpty ? 'Условия подходят для работ' : reasons.join('; '),
      recommendations: recommendations,
      minTemperature: rules.minTemperature,
      maxTemperature: rules.maxTemperature,
      maxHumidity: rules.maxHumidity,
      requiresDryWeather: rules.requiresDryWeather,
    );
  }

  static WeatherAdvice _getWorkRules(String workType) {
    // Правила для разных типов работ
    if (workType.contains('покраска') || workType.contains('краска')) {
      return const WeatherAdvice(
        workType: 'покраска',
        canWork: true,
        reason: '',
        recommendations: [
          'Идеальная температура: 15-25°C',
          'Избегайте прямых солнечных лучей',
          'Влажность должна быть 40-60%',
        ],
        minTemperature: 5.0,
        maxTemperature: 30.0,
        maxHumidity: 80.0,
        requiresDryWeather: true,
      );
    }
    
    if (workType.contains('штукатурка') || workType.contains('шпаклёвка')) {
      return const WeatherAdvice(
        workType: 'штукатурка',
        canWork: true,
        reason: '',
        recommendations: [
          'Температура должна быть выше +5°C',
          'Избегайте сквозняков',
          'Дайте материалу высохнуть естественным путём',
        ],
        minTemperature: 5.0,
        maxTemperature: 35.0,
        maxHumidity: 75.0,
        requiresDryWeather: false,
      );
    }
    
    if (workType.contains('фасад') || workType.contains('наружн')) {
      return const WeatherAdvice(
        workType: 'фасад',
        canWork: true,
        reason: '',
        recommendations: [
          'Работы при температуре +5°C и выше',
          'Избегайте дождя и сильного ветра',
          'Защитите материалы от влаги',
        ],
        minTemperature: 5.0,
        maxTemperature: 40.0,
        maxHumidity: 85.0,
        requiresDryWeather: true,
      );
    }
    
    // По умолчанию
    return const WeatherAdvice(
      workType: 'общие',
      canWork: true,
      reason: '',
      recommendations: ['Проверьте погодные условия перед началом работ'],
      minTemperature: 0.0,
      maxTemperature: 40.0,
      requiresDryWeather: false,
    );
  }
}

