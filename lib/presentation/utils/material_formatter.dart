import '../../core/utils/format_weight.dart';
import '../../core/utils/pluralize_ru.dart';
import '../../domain/models/canonical_calculator_contract.dart';

/// Format a [CanonicalMaterialResult] for display.
///
/// Returns a record with formatted value, display unit, and optional package subtitle.
/// Handles:
/// - Weight in grams for < 1 кг (e.g., "150 г" instead of "0.2 кг")
/// - Russian pluralization of package units ("1 мешок", "3 мешка", "5 мешков")
({String displayValue, String displayUnit, String? packageSubtitle}) formatMaterialForDisplay(
  CanonicalMaterialResult material,
) {
  final qty = material.purchaseQty ?? material.withReserve ?? material.quantity;

  // Weight formatting: < 1 кг → grams
  if (material.unit == 'кг' && qty > 0 && qty < 1) {
    final grams = (qty * 1000).round();
    return (
      displayValue: '$grams',
      displayUnit: 'г',
      packageSubtitle: _buildPackageSubtitle(material),
    );
  }

  // Format based on unit type
  final formatted = _formatQty(qty, material.unit);
  return (
    displayValue: formatted,
    displayUnit: material.unit,
    packageSubtitle: _buildPackageSubtitle(material),
  );
}

/// Format weight as human-readable string (delegates to formatWeightRu).
/// 0.15 кг → "150 г", 2.5 кг → "2,5 кг"
String formatMaterialWeight(double kg) => formatWeightRu(kg);

/// Build the package subtitle line (e.g., "3 мешка × 25 кг")
String? _buildPackageSubtitle(CanonicalMaterialResult material) {
  final pkg = material.packageInfo;
  if (pkg == null) return null;

  final count = (pkg['count'] as num?)?.toInt() ?? 0;
  final size = pkg['size'] as num? ?? 0;
  final rawUnit = pkg['packageUnit'] as String? ?? '';

  if (count <= 0 || rawUnit.isEmpty) return null;

  final pluralized = pluralizePackageUnit(count, rawUnit);
  return '$count $pluralized × $size ${material.unit}';
}

String _formatQty(double value, String unit) {
  if (value.isNaN || value.isInfinite) return '—';

  // Integer units — always round up
  const integerUnits = {
    'шт', 'мешков', 'рулонов', 'листов', 'упаковок', 'канистр',
    'уп', 'упак.', 'рулон', 'ведро', 'баллон', 'вёдер', 'банок', 'туб', 'г',
  };
  if (integerUnits.contains(unit)) {
    return value.ceil().toString();
  }

  // Weight/volume — 1 decimal
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(1).replaceAll('.', ',');
}
