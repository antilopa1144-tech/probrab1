/// Stable history categories used for storage and UI filtering.
///
/// Stored value recommendation: `HistoryCategory.name` (e.g. `foundation`).
enum HistoryCategory {
  all,
  foundation,
  walls,
  roofing,
  finishing;
}

extension HistoryCategoryX on HistoryCategory {
  String get translationKey {
    switch (this) {
      case HistoryCategory.all:
        return 'history.category.all';
      case HistoryCategory.foundation:
        return 'history.category.foundation';
      case HistoryCategory.walls:
        return 'history.category.walls';
      case HistoryCategory.roofing:
        return 'history.category.roofing';
      case HistoryCategory.finishing:
        return 'history.category.finishing';
    }
  }
}

class HistoryCategoryResolver {
  static HistoryCategory? tryParse(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return null;

    for (final c in HistoryCategory.values) {
      if (raw == c.name) return c;
    }

    for (final c in HistoryCategory.values) {
      if (raw == c.translationKey) return c;
    }

    // Backward compat: old stored labels.
    switch (raw.toLowerCase()) {
      case 'фундамент':
        return HistoryCategory.foundation;
      case 'стены':
        return HistoryCategory.walls;
      case 'кровля':
        return HistoryCategory.roofing;
      case 'отделка':
        return HistoryCategory.finishing;
      case 'все':
        return HistoryCategory.all;
    }

    return null;
  }

  static HistoryCategory fromCalculatorId(
    String calculatorId, {
    String? fallbackStoredCategory,
  }) {
    final id = calculatorId;

    if (id.startsWith('foundation_')) return HistoryCategory.foundation;
    if (id.startsWith('roofing_')) return HistoryCategory.roofing;
    if (id.startsWith('walls_') || id.startsWith('wall_')) {
      return HistoryCategory.walls;
    }

    final parsed =
        fallbackStoredCategory == null ? null : tryParse(fallbackStoredCategory);
    if (parsed != null && parsed != HistoryCategory.all) return parsed;

    return HistoryCategory.finishing;
  }
}

