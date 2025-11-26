import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/expert_recommendation.dart';

/// Экран экспертных рекомендаций.
class ExpertRecommendationsScreen extends ConsumerWidget {
  final String workType;

  const ExpertRecommendationsScreen({
    super.key,
    required this.workType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recommendations = ExpertRecommendationsDatabase.getRecommendations(workType);

    if (recommendations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Экспертные рекомендации')),
        body: const Center(
          child: Text('Рекомендации для этого типа работ пока не добавлены'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Экспертные рекомендации')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recommendations.length,
        itemBuilder: (context, index) {
          final rec = recommendations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ExpansionTile(
              leading: CircleAvatar(
                backgroundColor: _getLevelColor(rec.level),
                child: Text(_getLevelIcon(rec.level)),
              ),
              title: Text(rec.title),
              subtitle: Text('Уровень: ${_getLevelName(rec.level)}'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rec.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (rec.commonMistakes.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Типичные ошибки',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...rec.commonMistakes.map((mistake) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.close, 
                                      color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(mistake)),
                                ],
                              ),
                            )),
                      ],
                      if (rec.bestPractices.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Лучшие практики',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...rec.bestPractices.map((practice) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(practice)),
                                ],
                              ),
                            )),
                      ],
                      if (rec.tools.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Необходимые инструменты',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: rec.tools
                              .map((tool) => Chip(label: Text(tool)))
                              .toList(),
                        ),
                      ],
                      if (rec.materials.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Необходимые материалы',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: rec.materials
                              .map((material) => Chip(label: Text(material)))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getLevelColor(RecommendationLevel level) {
    switch (level) {
      case RecommendationLevel.beginner:
        return Colors.green;
      case RecommendationLevel.intermediate:
        return Colors.blue;
      case RecommendationLevel.advanced:
        return Colors.orange;
      case RecommendationLevel.expert:
        return Colors.red;
    }
  }

  String _getLevelIcon(RecommendationLevel level) {
    switch (level) {
      case RecommendationLevel.beginner:
        return '1';
      case RecommendationLevel.intermediate:
        return '2';
      case RecommendationLevel.advanced:
        return '3';
      case RecommendationLevel.expert:
        return '4';
    }
  }

  String _getLevelName(RecommendationLevel level) {
    switch (level) {
      case RecommendationLevel.beginner:
        return 'Новичок';
      case RecommendationLevel.intermediate:
        return 'Средний';
      case RecommendationLevel.advanced:
        return 'Продвинутый';
      case RecommendationLevel.expert:
        return 'Эксперт';
    }
  }
}

