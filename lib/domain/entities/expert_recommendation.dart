abstract final class ExpertWorkTypeId {
  static const String paint = 'paint';
  static const String tile = 'tile';
  static const String screed = 'screed';
  static const String wallpaper = 'wallpaper';
  static const String general = 'general';
}

abstract final class ExpertWorkTypeCatalog {
  static String normalize(String workType) {
    final raw = workType.trim().toLowerCase();
    if (raw.isEmpty) return ExpertWorkTypeId.general;

    if (_matchesAny(raw, const ['paint', 'покраска', 'краска'])) {
      return ExpertWorkTypeId.paint;
    }
    if (_matchesAny(raw, const ['tile', 'плитка'])) {
      return ExpertWorkTypeId.tile;
    }
    if (_matchesAny(raw, const ['screed', 'стяжка'])) {
      return ExpertWorkTypeId.screed;
    }
    if (_matchesAny(raw, const ['wallpaper', 'обои'])) {
      return ExpertWorkTypeId.wallpaper;
    }
    return ExpertWorkTypeId.general;
  }

  static bool _matchesAny(String raw, List<String> tokens) {
    for (final token in tokens) {
      if (raw.contains(token)) return true;
    }
    return false;
  }
}

/// Экспертная рекомендация для типа работ.
class ExpertRecommendation {
  final String workTypeId;
  final String titleKey;
  final String descriptionKey;
  final RecommendationLevel level;
  final List<String> commonMistakeKeys;
  final List<String> bestPracticeKeys;
  final List<String> toolKeys;
  final List<String> materialKeys;

  const ExpertRecommendation({
    required this.workTypeId,
    required this.titleKey,
    required this.descriptionKey,
    required this.level,
    this.commonMistakeKeys = const [],
    this.bestPracticeKeys = const [],
    this.toolKeys = const [],
    this.materialKeys = const [],
  });
}

enum RecommendationLevel {
  beginner,
  intermediate,
  advanced,
  expert,
}

/// База экспертных рекомендаций.
class ExpertRecommendationsDatabase {
  static List<ExpertRecommendation> getRecommendations(String workType) {
    final normalizedWorkType = ExpertWorkTypeCatalog.normalize(workType);
    final all = _getAllRecommendations();
    return all.where((recommendation) => recommendation.workTypeId == normalizedWorkType).toList();
  }

  static List<ExpertRecommendation> _getAllRecommendations() {
    return const [
      ExpertRecommendation(
        workTypeId: ExpertWorkTypeId.paint,
        titleKey: 'expert.rec.paint.title',
        descriptionKey: 'expert.rec.paint.description',
        level: RecommendationLevel.beginner,
        commonMistakeKeys: [
          'expert.rec.paint.mistake.no_primer',
          'expert.rec.paint.mistake.thick_layer',
          'expert.rec.paint.mistake.no_prep',
        ],
        bestPracticeKeys: [
          'expert.rec.paint.practice.use_primer',
          'expert.rec.paint.practice.thin_layers',
          'expert.rec.paint.practice.good_tools',
          'expert.rec.paint.practice.good_light',
        ],
        toolKeys: [
          'expert.tool.roller',
          'expert.tool.brushes',
          'expert.tool.tray',
          'expert.tool.masking_tape',
          'expert.tool.film',
        ],
        materialKeys: [
          'expert.material.paint',
          'expert.material.primer',
          'expert.material.putty',
        ],
      ),
      ExpertRecommendation(
        workTypeId: ExpertWorkTypeId.tile,
        titleKey: 'expert.rec.tile.title',
        descriptionKey: 'expert.rec.tile.description',
        level: RecommendationLevel.intermediate,
        commonMistakeKeys: [
          'expert.rec.tile.mistake.uneven_base',
          'expert.rec.tile.mistake.wrong_glue',
          'expert.rec.tile.mistake.no_joints',
        ],
        bestPracticeKeys: [
          'expert.rec.tile.practice.level_base',
          'expert.rec.tile.practice.use_level',
          'expert.rec.tile.practice.start_center',
          'expert.rec.tile.practice.use_crosses',
        ],
        toolKeys: [
          'expert.tool.notched_trowel',
          'expert.tool.level',
          'expert.tool.crosses',
          'expert.tool.tile_cutter',
        ],
        materialKeys: [
          'expert.material.tile',
          'expert.material.tile_glue',
          'expert.material.grout',
        ],
      ),
      ExpertRecommendation(
        workTypeId: ExpertWorkTypeId.screed,
        titleKey: 'expert.rec.screed.title',
        descriptionKey: 'expert.rec.screed.description',
        level: RecommendationLevel.intermediate,
        commonMistakeKeys: [
          'expert.rec.screed.mistake.unprepared_base',
          'expert.rec.screed.mistake.no_beacons',
          'expert.rec.screed.mistake.fast_drying',
        ],
        bestPracticeKeys: [
          'expert.rec.screed.practice.use_beacons',
          'expert.rec.screed.practice.wait_before_load',
          'expert.rec.screed.practice.protect_from_drafts',
          'expert.rec.screed.practice.check_level',
        ],
        toolKeys: [
          'expert.tool.beacons',
          'expert.tool.rule',
          'expert.tool.level',
          'expert.tool.spike_roller',
        ],
        materialKeys: [
          'expert.material.cement',
          'expert.material.sand',
          'expert.material.water',
        ],
      ),
      ExpertRecommendation(
        workTypeId: ExpertWorkTypeId.wallpaper,
        titleKey: 'expert.rec.wallpaper.title',
        descriptionKey: 'expert.rec.wallpaper.description',
        level: RecommendationLevel.beginner,
        commonMistakeKeys: [
          'expert.rec.wallpaper.mistake.wrong_glue',
          'expert.rec.wallpaper.mistake.ignore_rapport',
          'expert.rec.wallpaper.mistake.uneven_walls',
        ],
        bestPracticeKeys: [
          'expert.rec.wallpaper.practice.laser_first_strip',
          'expert.rec.wallpaper.practice.check_pattern',
          'expert.rec.wallpaper.practice.add_reserve',
          'expert.rec.wallpaper.practice.from_window',
        ],
        toolKeys: [
          'expert.tool.roller',
          'expert.tool.brush',
          'expert.tool.rubber_roller',
          'expert.tool.knife',
          'expert.tool.level',
        ],
        materialKeys: [
          'expert.material.wallpaper',
          'expert.material.wallpaper_glue',
        ],
      ),
    ];
  }
}
