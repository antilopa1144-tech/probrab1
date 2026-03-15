// ignore_for_file: prefer_const_declarations

import '../../data/models/price_item.dart';
import '../models/canonical_calculator_contract.dart';
import './calculator_usecase.dart';

/// Signature of every canonical adapter function.
///
/// All canonical adapters follow the pattern:
///   CanonicalCalculatorContractResult calculateCanonicalXxx(Map<String, double> inputs, {XxxSpec spec = ...})
///
/// Because the spec parameter is optional with a default, we can ignore it
/// and treat every adapter as this typedef.
typedef CanonicalAdapterFn = CanonicalCalculatorContractResult Function(
  Map<String, double> inputs,
);

/// Universal bridge that adapts any canonical adapter function into the
/// legacy [CalculatorUseCase] interface used by [CalculatorDefinitionV2].
///
/// The bridge:
/// 1. Calls the canonical adapter with the same `inputs` map.
/// 2. Converts [CanonicalCalculatorContractResult] to [CalculatorResult]:
///    - `values` is built from `totals` merged with material quantities
///      (keyed by sanitised material name) to preserve backward-compatible
///      output for the UI and caching layer.
///    - `totalPrice` is always `null` because canonical adapters do not
///      compute prices (price lookup is done at UI level).
///    - `norms` is populated from `warnings` for display in the result card.
///
/// ## Usage
///
/// ```dart
/// import 'concrete_canonical_adapter.dart';
///
/// final definition = CalculatorDefinitionV2(
///   ...
///   useCase: CanonicalBridgeUseCase(calculateCanonicalConcrete),
/// );
/// ```
class CanonicalBridgeUseCase implements CalculatorUseCase {
  final CanonicalAdapterFn _adapter;

  const CanonicalBridgeUseCase(this._adapter);

  @override
  CalculatorResult call(
    Map<String, double> inputs,
    List<PriceItem> priceList,
  ) {
    final canonical = _adapter(inputs);
    return convertCanonicalToResult(canonical);
  }

  /// Convert a [CanonicalCalculatorContractResult] to the legacy
  /// [CalculatorResult] format.
  ///
  /// Exposed as a static method so it can be reused outside the bridge
  /// (e.g. in tests or in screens that need both formats).
  static CalculatorResult convertCanonicalToResult(
    CanonicalCalculatorContractResult canonical,
  ) {
    // Start with all totals (the primary numeric outputs).
    final values = <String, double>{...canonical.totals};

    // Merge material quantities using sanitised keys so that the old
    // UI result renderers can pick them up.
    for (final material in canonical.materials) {
      final key = _sanitizeKey(material.name);
      values[key] = material.quantity;

      if (material.withReserve != null) {
        values['${key}_withReserve'] = material.withReserve!;
      }
      if (material.purchaseQty != null) {
        values['${key}_purchaseQty'] = material.purchaseQty!.toDouble();
      }
    }

    // Inject scenario data as flat keys for screens that display MIN/REC/MAX.
    for (final entry in canonical.scenarios.entries) {
      final prefix = entry.key.toLowerCase(); // min, rec, max
      final scenario = entry.value;
      values['${prefix}_exactNeed'] = scenario.exactNeed;
      values['${prefix}_purchaseQuantity'] = scenario.purchaseQuantity;
      values['${prefix}_leftover'] = scenario.leftover;
    }

    return CalculatorResult(
      values: values,
      totalPrice: null,
      norms: canonical.warnings,
    );
  }

  /// Turn a Russian/Unicode material name into a valid map key.
  ///
  /// - Strips parentheses and their content (e.g. "(50 кг)" removed)
  /// - Replaces non-ASCII chars and spaces with underscores
  /// - Collapses multiple underscores, trims leading/trailing
  /// - Lower-cases for consistency
  static String _sanitizeKey(String name) {
    // Remove content in parentheses
    var cleaned = name.replaceAll(RegExp(r'\([^)]*\)'), '');
    // Transliterate common Cyrillic to Latin for shorter keys
    cleaned = _transliterate(cleaned);
    // Replace non-alphanumeric with underscore
    cleaned = cleaned.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    // Collapse multiple underscores
    cleaned = cleaned.replaceAll(RegExp(r'_+'), '_');
    // Trim and lowercase
    cleaned = cleaned.trim().toLowerCase();
    if (cleaned.startsWith('_')) cleaned = cleaned.substring(1);
    if (cleaned.endsWith('_')) cleaned = cleaned.substring(0, cleaned.length - 1);
    return cleaned.isEmpty ? 'material' : cleaned;
  }

  static String _transliterate(String source) {
    const map = {
      'а': 'a', 'б': 'b', 'в': 'v', 'г': 'g', 'д': 'd',
      'е': 'e', 'ё': 'yo', 'ж': 'zh', 'з': 'z', 'и': 'i',
      'й': 'y', 'к': 'k', 'л': 'l', 'м': 'm', 'н': 'n',
      'о': 'o', 'п': 'p', 'р': 'r', 'с': 's', 'т': 't',
      'у': 'u', 'ф': 'f', 'х': 'kh', 'ц': 'ts', 'ч': 'ch',
      'ш': 'sh', 'щ': 'sch', 'ъ': '', 'ы': 'y', 'ь': '',
      'э': 'e', 'ю': 'yu', 'я': 'ya',
      'А': 'A', 'Б': 'B', 'В': 'V', 'Г': 'G', 'Д': 'D',
      'Е': 'E', 'Ё': 'Yo', 'Ж': 'Zh', 'З': 'Z', 'И': 'I',
      'Й': 'Y', 'К': 'K', 'Л': 'L', 'М': 'M', 'Н': 'N',
      'О': 'O', 'П': 'P', 'Р': 'R', 'С': 'S', 'Т': 'T',
      'У': 'U', 'Ф': 'F', 'Х': 'Kh', 'Ц': 'Ts', 'Ч': 'Ch',
      'Ш': 'Sh', 'Щ': 'Sch', 'Ъ': '', 'Ы': 'Y', 'Ь': '',
      'Э': 'E', 'Ю': 'Yu', 'Я': 'Ya',
    };
    final buffer = StringBuffer();
    for (final char in source.split('')) {
      buffer.write(map[char] ?? char);
    }
    return buffer.toString();
  }
}
