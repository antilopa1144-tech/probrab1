import 'accuracy_mode.dart';
import '../generated/accuracy_profiles.g.dart';

/// Service for accuracy mode calculations.
///
/// Loads modifier profiles from generated data (synced from web JSON).
class AccuracyService {
  const AccuracyService._();

  /// Get modifiers for a material category and accuracy mode.
  static AccuracyModifiers getModifiers(String category, AccuracyMode mode) {
    final modeKey = mode.name; // 'basic', 'realistic', 'professional'
    final categoryProfiles = accuracyProfiles[category] ?? accuracyProfiles['generic']!;
    final modeProfile = categoryProfiles[modeKey];
    if (modeProfile == null) {
      return const AccuracyModifiers(); // all 1.0
    }
    return AccuracyModifiers.fromJson(modeProfile);
  }

  /// Get primary material multiplier (excludes accessories).
  static double getPrimaryMultiplier(String category, AccuracyMode mode) {
    return getModifiers(category, mode).primaryMultiplier;
  }

  /// Get accessories multiplier only.
  static double getAccessoriesMultiplier(String category, AccuracyMode mode) {
    return getModifiers(category, mode).accessories;
  }

  /// Get total multiplier (primary + accessories).
  static double getTotalMultiplier(String category, AccuracyMode mode) {
    return getModifiers(category, mode).totalMultiplier;
  }
}
