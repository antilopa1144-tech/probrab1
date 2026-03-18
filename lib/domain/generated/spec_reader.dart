/// Utility to read values from generated canonical spec Maps.
///
/// Usage in adapters:
/// ```dart
/// import '../generated/canonical_specs.g.dart';
/// import '../generated/spec_reader.dart';
///
/// final spec = SpecReader(tileSpecData);
/// final glueRate = spec.materialRule<double>('glue_kg_per_m2_medium');
/// final bagKg = spec.packagingRule<double>('glue_bag_kg');
/// ```
class SpecReader {
  final Map<String, dynamic> _data;

  const SpecReader(this._data);

  /// Raw data map.
  Map<String, dynamic> get raw => _data;

  String get calculatorId => _data['calculator_id'] as String;
  String get formulaVersion => _data['formula_version'] as String;

  List<Map<String, dynamic>> get inputSchema =>
      (_data['input_schema'] as List).cast<Map<String, dynamic>>();

  List<String> get enabledFactors =>
      ((_data['field_factors'] as Map<String, dynamic>)['enabled'] as List)
          .cast<String>();

  /// Get a value from `packaging_rules`.
  T packagingRule<T>(String key, [T? fallback]) {
    final rules = _data['packaging_rules'] as Map<String, dynamic>?;
    final value = rules?[key] as T?;
    if (value != null) return value;
    if (fallback != null) return fallback;
    assert(false, 'SpecReader: missing packaging_rules key "$key" and no fallback');
    return _zeroDefault<T>();
  }

  /// Get a value from `material_rules`.
  T materialRule<T>(String key, [T? fallback]) {
    final rules = _data['material_rules'] as Map<String, dynamic>?;
    final value = rules?[key] as T?;
    if (value != null) return value;
    if (fallback != null) return fallback;
    assert(false, 'SpecReader: missing material_rules key "$key" and no fallback');
    return _zeroDefault<T>();
  }

  /// Get a value from `warnings_rules`.
  T warningRule<T>(String key, [T? fallback]) {
    final rules = _data['warnings_rules'] as Map<String, dynamic>?;
    final value = rules?[key] as T?;
    if (value != null) return value;
    if (fallback != null) return fallback;
    assert(false, 'SpecReader: missing warnings_rules key "$key" and no fallback');
    return _zeroDefault<T>();
  }

  /// Safe zero-value fallback to prevent null crashes in release.
  static T _zeroDefault<T>() {
    if (T == num || T == double) return 0.0 as T;
    if (T == int) return 0 as T;
    if (T == String) return '' as T;
    if (T == bool) return false as T;
    return 0 as T;
  }

  /// Get a typed list from `normative_formula`, falling back to root level.
  List<Map<String, dynamic>> normativeList(String key) {
    final formula = _data['normative_formula'] as Map<String, dynamic>?;
    final list = (formula?[key] as List?) ?? (_data[key] as List?);
    return list?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Get a raw value from `normative_formula`.
  T? normativeValue<T>(String key) =>
      (_data['normative_formula'] as Map<String, dynamic>?)?[key] as T?;

  /// Get default value for an input field.
  double inputDefault(String key, [double fallback = 0]) {
    for (final field in inputSchema) {
      if (field['key'] == key) {
        return (field['default_value'] as num?)?.toDouble() ?? fallback;
      }
    }
    return fallback;
  }
}
