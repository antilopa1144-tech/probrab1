/// Russian pluralization by number.
///
/// ```dart
/// pluralizeRu(1, ['мешок', 'мешка', 'мешков']) // → 'мешок'
/// pluralizeRu(2, ['мешок', 'мешка', 'мешков']) // → 'мешка'
/// pluralizeRu(5, ['мешок', 'мешка', 'мешков']) // → 'мешков'
/// ```
String pluralizeRu(int n, List<String> forms) {
  assert(forms.length == 3, 'forms must have exactly 3 elements');
  final abs = n.abs() % 100;
  final lastDigit = abs % 10;
  if (abs >= 11 && abs <= 19) return forms[2];
  if (lastDigit == 1) return forms[0];
  if (lastDigit >= 2 && lastDigit <= 4) return forms[1];
  return forms[2];
}

/// Lookup table: genitive plural → [nominative, genitive singular, genitive plural]
const Map<String, List<String>> packageUnitForms = {
  'мешков':   ['мешок', 'мешка', 'мешков'],
  'вёдер':    ['ведро', 'ведра', 'вёдер'],
  'канистр':  ['канистра', 'канистры', 'канистр'],
  'рулонов':  ['рулон', 'рулона', 'рулонов'],
  'упаковок': ['упаковка', 'упаковки', 'упаковок'],
  'банок':    ['банка', 'банки', 'банок'],
  'бухт':     ['бухта', 'бухты', 'бухт'],
  'доставок': ['доставка', 'доставки', 'доставок'],
  'прутков':  ['пруток', 'прутка', 'прутков'],
  'досок':    ['доска', 'доски', 'досок'],
  'щитков':   ['щиток', 'щитка', 'щитков'],
  'листов':   ['лист', 'листа', 'листов'],
  'баллонов': ['баллон', 'баллона', 'баллонов'],
  'модулей':  ['модуль', 'модуля', 'модулей'],
};

/// Pluralize a packageUnit string by count.
String pluralizePackageUnit(int count, String rawUnit) {
  final forms = packageUnitForms[rawUnit];
  return forms != null ? pluralizeRu(count, forms) : rawUnit;
}
