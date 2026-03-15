import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/localization/app_localizations.dart';
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
    final loc = AppLocalizations.of(context);

    final conditions = WeatherConditions(
      temperature: double.tryParse(_tempController.text) ?? 20,
      humidity: double.tryParse(_humidityController.text) ?? 50,
      isRaining: _isRaining,
      windSpeed: double.tryParse(_windController.text) ?? 5,
      date: DateTime.now(),
    );

    final advice = WeatherAdvice.check(widget.workType, conditions);
    final reason = _buildReasonText(loc, advice);

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('weather.title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.translate('weather.current_conditions'),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _tempController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.translate('weather.field.temperature'),
                        prefixIcon: const Icon(Icons.thermostat),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _humidityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.translate('weather.field.humidity'),
                        prefixIcon: const Icon(Icons.water_drop),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(loc.translate('weather.field.raining')),
                      value: _isRaining,
                      onChanged: (value) => setState(() => _isRaining = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _windController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: loc.translate('weather.field.wind'),
                        prefixIcon: const Icon(Icons.air),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
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
                                ? loc.translate('weather.status.good')
                                : loc.translate('weather.status.bad'),
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
                      reason,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (advice.recommendationKeys.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('weather.recommendations'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...advice.recommendationKeys.map(
                        (key) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(loc.translate(key))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (advice.minTemperature != null || advice.maxTemperature != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('weather.constraints'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (advice.minTemperature != null)
                        Text(
                          loc.translate('weather.constraint.min_temperature', {
                            'value': advice.minTemperature!.toStringAsFixed(1),
                          }),
                        ),
                      if (advice.maxTemperature != null)
                        Text(
                          loc.translate('weather.constraint.max_temperature', {
                            'value': advice.maxTemperature!.toStringAsFixed(1),
                          }),
                        ),
                      if (advice.maxHumidity != null)
                        Text(
                          loc.translate('weather.constraint.max_humidity', {
                            'value': advice.maxHumidity!.toStringAsFixed(0),
                          }),
                        ),
                      if (advice.requiresDryWeather)
                        Text(loc.translate('weather.constraint.dry_weather')),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildReasonText(AppLocalizations loc, WeatherAdvice advice) {
    if (advice.issueKeys.isEmpty) {
      return loc.translate('weather.status.good_reason');
    }

    final parts = <String>[];
    for (var index = 0; index < advice.issueKeys.length; index++) {
      final params = index < advice.issueParams.length ? advice.issueParams[index] : null;
      parts.add(loc.translate(advice.issueKeys[index], params));
    }
    return parts.join('; ');
  }
}
