/// Format weight in human-friendly Russian:
/// - < 0.01 кг → "< 10 г"
/// - < 1 кг → grams (e.g., "150 г")
/// - >= 1 кг → kg (e.g., "2,5 кг")
String formatWeightRu(double kg) {
  if (!kg.isFinite || kg <= 0) return '0 г';
  if (kg < 0.01) return '< 10 г';
  if (kg < 1) return '${(kg * 1000).round()} г';
  if (kg == kg.roundToDouble()) return '${kg.toInt()} кг';
  return '${kg.toStringAsFixed(2).replaceAll('.', ',')} кг';
}
