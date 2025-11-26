import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/weather_advice.dart';

/// Экран погодных рекомендаций.
class WeatherAdvisorScreen extends ConsumerStatefulWidget {
  final String workType;

  const WeatherAdvisorScreen({
    super.key,
    required this.workType,
  });

  @override
  ConsumerState<WeatherAdvisorScreen> createState() => _WeatherAdvisorScreenState();
}

class _WeatherAdvisorScreenState extends ConsumerState<WeatherAdvisorScreen> {
  final TextEditingController _tempController = TextEditingController(text: '20');
  final TextEditingController _humidityController = TextEditingController(text: '50');
  bool _isRaining = false;
  final TextEditingController _windController = TextEditingController(text: '5');

  @override
  void dispose() {
    _tempController.dispose();
    _humidityController.dispose();
    _windController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final conditions = WeatherConditions(
      temperature: double.tryParse(_tempController.text) ?? 20,
      humidity: double.tryParse(_humidityController.text) ?? 50,
      isRaining: _isRaining,
      windSpeed: double.tryParse(_windController.text) ?? 5,
      date: DateTime.now(),
    );
    
    final advice = WeatherAdvice.check(widget.workType, conditions);

    return Scaffold(
      appBar: AppBar(title: const Text('Погодные рекомендации')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ввод условий
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Текущие условия',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Температура (°C)',
                        prefixIcon: Icon(Icons.thermostat),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _humidityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Влажность (%)',
                        prefixIcon: Icon(Icons.water_drop),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Идёт дождь'),
                      value: _isRaining,
                      onChanged: (value) => setState(() => _isRaining = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _windController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Скорость ветра (м/с)',
                        prefixIcon: Icon(Icons.air),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Результат проверки
            Card(
              color: advice.canWork 
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          advice.canWork ? Icons.check_circle : Icons.cancel,
                          color: advice.canWork ? Colors.green : Colors.red,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            advice.canWork 
                                ? 'Условия подходят для работ'
                                : 'Условия не подходят',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: advice.canWork ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      advice.reason,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Рекомендации
            if (advice.recommendations.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Рекомендации',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...advice.recommendations.map((rec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline, size: 20),
                                const SizedBox(width: 8),
                                Expanded(child: Text(rec)),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            // Ограничения
            if (advice.minTemperature != null || advice.maxTemperature != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ограничения',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (advice.minTemperature != null)
                        Text('Минимальная температура: ${advice.minTemperature}°C'),
                      if (advice.maxTemperature != null)
                        Text('Максимальная температура: ${advice.maxTemperature}°C'),
                      if (advice.maxHumidity != null)
                        Text('Максимальная влажность: ${advice.maxHumidity}%'),
                      if (advice.requiresDryWeather)
                        const Text('Требуется сухая погода'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

