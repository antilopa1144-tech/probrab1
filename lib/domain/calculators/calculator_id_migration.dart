/// Migration utilities for legacy calculator IDs.
///
/// This exists to keep stored data (favorites, history, projects) compatible
/// after renaming/removing old calculator identifiers.
class CalculatorIdMigration {
  static const Map<String, String> _legacyToCanonical = {
    // Old wall paint ID.
    'walls_paint': 'wall_paint',

    // Old foundation IDs.
    'calculator.stripTitle': 'foundation_strip',
    'strip_foundation': 'foundation_strip',
    'slab_foundation': 'foundation_slab',
    'basement': 'foundation_basement',
    'blind_area': 'foundation_blind_area',

    // Old engineering IDs.
    'warm_floor': 'floors_warm',
    'heating': 'engineering_heating',
  };

  static bool isLegacy(String id) => _legacyToCanonical.containsKey(id);

  static String canonicalize(String id) => _legacyToCanonical[id] ?? id;

  static List<String> canonicalizeList(
    Iterable<String> ids, {
    bool dedupe = true,
  }) {
    final result = <String>[];
    final seen = <String>{};

    for (final id in ids) {
      final next = canonicalize(id);
      if (dedupe) {
        if (seen.add(next)) result.add(next);
      } else {
        result.add(next);
      }
    }

    return result;
  }
}

