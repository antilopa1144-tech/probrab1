/// Accuracy Mode System — practical calculation precision layer.
///
/// Three modes:
///  - basic:        normative estimate, minimal practical adjustments
///  - realistic:    default mode, accounts for typical renovation conditions
///  - professional: cautious mode for complex conditions and reliable procurement

/// Supported accuracy modes
enum AccuracyMode { basic, realistic, professional }

/// Default mode for all calculations
const AccuracyMode defaultAccuracyMode = AccuracyMode.realistic;

/// Per-category practical modifiers
class AccuracyModifiers {
  final double waste;
  final double cutting;
  final double unevenness;
  final double overconsumption;
  final double errorMargin;
  final double topUp;
  final double accessories;
  final double packagingRound;

  const AccuracyModifiers({
    this.waste = 1.0,
    this.cutting = 1.0,
    this.unevenness = 1.0,
    this.overconsumption = 1.0,
    this.errorMargin = 1.0,
    this.topUp = 1.0,
    this.accessories = 1.0,
    this.packagingRound = 1.0,
  });

  factory AccuracyModifiers.fromJson(Map<String, dynamic> json) {
    return AccuracyModifiers(
      waste: (json['waste'] as num?)?.toDouble() ?? 1.0,
      cutting: (json['cutting'] as num?)?.toDouble() ?? 1.0,
      unevenness: (json['unevenness'] as num?)?.toDouble() ?? 1.0,
      overconsumption: (json['overconsumption'] as num?)?.toDouble() ?? 1.0,
      errorMargin: (json['errorMargin'] as num?)?.toDouble() ?? 1.0,
      topUp: (json['topUp'] as num?)?.toDouble() ?? 1.0,
      accessories: (json['accessories'] as num?)?.toDouble() ?? 1.0,
      packagingRound: (json['packagingRound'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Combined multiplier for primary material (all factors except accessories)
  double get primaryMultiplier =>
      waste * cutting * unevenness * overconsumption * errorMargin * topUp * packagingRound;

  /// Combined multiplier including accessories
  double get totalMultiplier => primaryMultiplier * accessories;
}

/// Material categories with tailored modifier profiles
const List<String> materialCategories = [
  'tile', 'tile_adhesive', 'grout', 'primer', 'wallpaper', 'putty',
  'paint', 'plaster', 'decorative_stone', 'drywall', 'fasteners',
  'insulation', 'flooring', 'concrete', 'waterproofing', 'generic',
];
