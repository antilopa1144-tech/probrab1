// Utility helpers for parsing user-entered numeric values that may include
// locale-specific separators (spaces, commas) or multiple decimal marks.
class NumberParser {
  const NumberParser._();

  /// Converts arbitrary string input like `1 200,5` or `2.5` into a double.
  ///
  /// Returns `null` when the value cannot be parsed.
  static double? parse(String? raw) {
    if (raw == null) return null;
    final normalized = normalize(raw);
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
  }

  /// Normalizes user input by:
  /// - removing non-numeric characters (except `.` and `-`)
  /// - converting commas to dots
  /// - removing thousands separators
  /// - keeping only the last dot as the decimal separator
  static String normalize(String value) {
    if (value.isEmpty) {
      return '';
    }

    // Replace comma with dot and remove spaces / NBSP / underscores.
    var sanitized = value
        .trim()
        .replaceAll('\u00A0', '')
        .replaceAll(RegExp(r'[\s_]'), '')
        .replaceAll(',', '.');

    // Keep sign if present at the beginning.
    final hasNegative = sanitized.startsWith('-');
    sanitized = sanitized.replaceAll('-', '');

    // Remove any characters except digits and dots.
    sanitized = sanitized.replaceAll(RegExp(r'[^0-9\.]'), '');

    if (sanitized.isEmpty) {
      return '';
    }

    // If there are multiple dots, treat the last one as decimal separator
    // and remove the rest (consider them thousands separators).
    final lastDotIndex = sanitized.lastIndexOf('.');
    if (lastDotIndex != -1) {
      final wholePart =
          sanitized.substring(0, lastDotIndex).replaceAll('.', '');
      final decimalPart =
          sanitized.substring(lastDotIndex + 1).replaceAll('.', '');
      sanitized =
          decimalPart.isEmpty ? wholePart : '$wholePart.$decimalPart';
    } else {
      // No decimal separator -> remove all dots just in case
      sanitized = sanitized.replaceAll('.', '');
    }

    return hasNegative ? '-$sanitized' : sanitized;
  }

  /// Formats a number without trailing zeros (1.50 -> "1.5").
  static String format(double value, {int fractionDigits = 2}) {
    final fixed = value.toStringAsFixed(fractionDigits);
    return fixed.contains('.')
        ? fixed.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '')
        : fixed;
  }
}
