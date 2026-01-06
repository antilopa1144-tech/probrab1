import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/entities/expert_recommendation.dart';

void main() {
  group('RecommendationLevel', () {
    test('has beginner value', () {
      expect(RecommendationLevel.beginner, isNotNull);
      expect(RecommendationLevel.beginner.name, 'beginner');
    });

    test('has intermediate value', () {
      expect(RecommendationLevel.intermediate, isNotNull);
      expect(RecommendationLevel.intermediate.name, 'intermediate');
    });

    test('has advanced value', () {
      expect(RecommendationLevel.advanced, isNotNull);
      expect(RecommendationLevel.advanced.name, 'advanced');
    });

    test('has expert value', () {
      expect(RecommendationLevel.expert, isNotNull);
      expect(RecommendationLevel.expert.name, 'expert');
    });

    test('has exactly 4 values', () {
      expect(RecommendationLevel.values.length, 4);
    });
  });

  group('ExpertRecommendation', () {
    test('creates with required parameters', () {
      const rec = ExpertRecommendation(
        workType: 'painting',
        title: 'Painting Tips',
        description: 'How to paint walls',
        level: RecommendationLevel.beginner,
      );

      expect(rec.workType, 'painting');
      expect(rec.title, 'Painting Tips');
      expect(rec.description, 'How to paint walls');
      expect(rec.level, RecommendationLevel.beginner);
      expect(rec.commonMistakes, isEmpty);
      expect(rec.bestPractices, isEmpty);
      expect(rec.tools, isEmpty);
      expect(rec.materials, isEmpty);
    });

    test('creates with all parameters', () {
      const rec = ExpertRecommendation(
        workType: 'tiling',
        title: 'Tiling Guide',
        description: 'Professional tiling',
        level: RecommendationLevel.intermediate,
        commonMistakes: ['Mistake 1', 'Mistake 2'],
        bestPractices: ['Practice 1', 'Practice 2'],
        tools: ['Tool 1', 'Tool 2'],
        materials: ['Material 1'],
      );

      expect(rec.commonMistakes.length, 2);
      expect(rec.bestPractices.length, 2);
      expect(rec.tools.length, 2);
      expect(rec.materials.length, 1);
    });
  });

  group('ExpertRecommendationsDatabase', () {
    test('getRecommendations returns recommendations for painting', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('покраска');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workType == 'покраска'),
        isTrue,
      );
    });

    test('getRecommendations returns recommendations for tiles', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('плитка');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workType == 'плитка'),
        isTrue,
      );
    });

    test('getRecommendations returns recommendations for screed', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('стяжка');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workType == 'стяжка'),
        isTrue,
      );
    });

    test('getRecommendations returns recommendations for wallpaper', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('обои');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workType == 'обои'),
        isTrue,
      );
    });

    test('getRecommendations is case insensitive', () {
      final lower =
          ExpertRecommendationsDatabase.getRecommendations('покраска');
      final upper =
          ExpertRecommendationsDatabase.getRecommendations('ПОКРАСКА');
      final mixed =
          ExpertRecommendationsDatabase.getRecommendations('ПоКрАсКа');

      expect(lower.length, equals(upper.length));
      expect(lower.length, equals(mixed.length));
    });

    test('getRecommendations returns empty list for unknown work type', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('xyz123');

      expect(recommendations, isEmpty);
    });

    test('painting recommendation has correct level', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('покраска');

      final paintingRec = recommendations.first;
      expect(paintingRec.level, RecommendationLevel.beginner);
    });

    test('tiling recommendation has correct level', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('плитка');

      final tilingRec = recommendations.first;
      expect(tilingRec.level, RecommendationLevel.intermediate);
    });

    test('recommendations have common mistakes', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('покраска');

      expect(recommendations.first.commonMistakes, isNotEmpty);
    });

    test('recommendations have best practices', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('плитка');

      expect(recommendations.first.bestPractices, isNotEmpty);
    });

    test('recommendations have tools', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('стяжка');

      expect(recommendations.first.tools, isNotEmpty);
    });

    test('recommendations have materials', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('обои');

      expect(recommendations.first.materials, isNotEmpty);
    });

    test('partial match works for work type', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('крас');

      // Should match "покраска"
      expect(recommendations, isNotEmpty);
    });
  });
}
