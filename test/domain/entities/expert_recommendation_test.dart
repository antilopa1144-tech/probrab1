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
        workTypeId: 'painting',
        titleKey: 'Painting Tips',
        descriptionKey: 'How to paint walls',
        level: RecommendationLevel.beginner,
      );

      expect(rec.workTypeId, 'painting');
      expect(rec.titleKey, 'Painting Tips');
      expect(rec.descriptionKey, 'How to paint walls');
      expect(rec.level, RecommendationLevel.beginner);
      expect(rec.commonMistakeKeys, isEmpty);
      expect(rec.bestPracticeKeys, isEmpty);
      expect(rec.toolKeys, isEmpty);
      expect(rec.materialKeys, isEmpty);
    });

    test('creates with all parameters', () {
      const rec = ExpertRecommendation(
        workTypeId: 'tiling',
        titleKey: 'Tiling Guide',
        descriptionKey: 'Professional tiling',
        level: RecommendationLevel.intermediate,
        commonMistakeKeys: ['Mistake 1', 'Mistake 2'],
        bestPracticeKeys: ['Practice 1', 'Practice 2'],
        toolKeys: ['Tool 1', 'Tool 2'],
        materialKeys: ['Material 1'],
      );

      expect(rec.commonMistakeKeys.length, 2);
      expect(rec.bestPracticeKeys.length, 2);
      expect(rec.toolKeys.length, 2);
      expect(rec.materialKeys.length, 1);
    });
  });

  group('ExpertRecommendationsDatabase', () {
    test('getRecommendations returns recommendations for painting', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('покраска');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workTypeId == ExpertWorkTypeId.paint),
        isTrue,
      );
    });

    test('getRecommendations returns recommendations for tiles', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('плитка');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workTypeId == ExpertWorkTypeId.tile),
        isTrue,
      );
    });

    test('getRecommendations returns recommendations for screed', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('стяжка');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workTypeId == ExpertWorkTypeId.screed),
        isTrue,
      );
    });

    test('getRecommendations returns recommendations for wallpaper', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('обои');

      expect(recommendations, isNotEmpty);
      expect(
        recommendations.any((r) => r.workTypeId == ExpertWorkTypeId.wallpaper),
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

      expect(recommendations.first.commonMistakeKeys, isNotEmpty);
    });

    test('recommendations have best practices', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('плитка');

      expect(recommendations.first.bestPracticeKeys, isNotEmpty);
    });

    test('recommendations have tools', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('стяжка');

      expect(recommendations.first.toolKeys, isNotEmpty);
    });

    test('recommendations have materials', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('обои');

      expect(recommendations.first.materialKeys, isNotEmpty);
    });

    test('partial match works for work type', () {
      final recommendations =
          ExpertRecommendationsDatabase.getRecommendations('крас');

      // Should match "покраска" via normalize -> paint
      expect(recommendations, isNotEmpty);
    });
  });
}
