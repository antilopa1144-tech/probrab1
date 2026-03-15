import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/expert_recommendation.dart';
import '../../../core/localization/app_localizations.dart';

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
    final loc = AppLocalizations.of(context);
    final recommendations = ExpertRecommendationsDatabase.getRecommendations(workType);

    if (recommendations.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.translate('expert.title'))),
        body: Center(
          child: Text(loc.translate('expert.empty')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('expert.title'))),
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
              title: Text(loc.translate(rec.titleKey)),
              subtitle: Text(loc.translate('expert.level_value', {'level': _getLevelName(loc, rec.level)})),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.translate(rec.descriptionKey),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (rec.commonMistakeKeys.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('expert.common_mistakes'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...rec.commonMistakeKeys.map((mistakeKey) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.close, 
                                      color: Colors.red, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(loc.translate(mistakeKey))),
                                ],
                              ),
                            )),
                      ],
                      if (rec.bestPracticeKeys.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('expert.best_practices'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...rec.bestPracticeKeys.map((practiceKey) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(loc.translate(practiceKey))),
                                ],
                              ),
                            )),
                      ],
                      if (rec.toolKeys.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('expert.tools'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: rec.toolKeys
                              .map((toolKey) => Chip(label: Text(loc.translate(toolKey))))
                              .toList(),
                        ),
                      ],
                      if (rec.materialKeys.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          loc.translate('expert.materials'),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: rec.materialKeys
                              .map((materialKey) => Chip(label: Text(loc.translate(materialKey))))
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

  String _getLevelName(AppLocalizations loc, RecommendationLevel level) {
    switch (level) {
      case RecommendationLevel.beginner:
        return loc.translate('expert.level.beginner');
      case RecommendationLevel.intermediate:
        return loc.translate('expert.level.intermediate');
      case RecommendationLevel.advanced:
        return loc.translate('expert.level.advanced');
      case RecommendationLevel.expert:
        return loc.translate('expert.level.expert');
    }
  }
}



