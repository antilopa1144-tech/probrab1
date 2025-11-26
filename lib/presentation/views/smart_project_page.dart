import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/smart_project_provider.dart';

/// Страница умного мастера‑проекта.  Позволяет пользователю
/// выбрать основные разделы проекта (фундамент, стены, крыша, отделка) и
/// получить приблизительный расчёт общей стоимости.  В дальнейшем
/// возможна интеграция с реальными калькуляторами.
class SmartProjectPage extends ConsumerWidget {
  const SmartProjectPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final state = ref.watch(smartProjectProvider);
    final notifier = ref.read(smartProjectProvider.notifier);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('smartProject.title')),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.translate('smartProject.description'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: state.foundation,
              title: Text(loc.translate('categories.foundation')),
              onChanged: (val) => notifier.toggleFoundation(val ?? false),
            ),
            CheckboxListTile(
              value: state.walls,
              title: Text(loc.translate('categories.walls')),
              onChanged: (val) => notifier.toggleWalls(val ?? false),
            ),
            CheckboxListTile(
              value: state.roof,
              title: Text(loc.translate('categories.roof')),
              onChanged: (val) => notifier.toggleRoof(val ?? false),
            ),
            CheckboxListTile(
              value: state.finish,
              title: Text(loc.translate('categories.finish')),
              onChanged: (val) => notifier.toggleFinish(val ?? false),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.calculate(),
              child: Text(loc.translate('button.calculate')),
            ),
            const SizedBox(height: 24),
            if (state.results.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate('smartProject.resultTitle'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      for (final entry in state.results.entries)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${loc.translate('smartProject.${entry.key}')}: ${entry.value.toStringAsFixed(2)}',
                          ),
                        ),
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