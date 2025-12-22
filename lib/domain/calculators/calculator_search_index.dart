import '../../core/enums/calculator_category.dart';
import '../models/calculator_definition_v2.dart';

class CalculatorSearchIndex {
  final Map<String, Set<String>> _wordIndex = {};
  final Map<CalculatorCategory, List<String>> _categoryIndex = {};
  final Map<String, Set<String>> _tagIndex = {};

  void buildIndex(List<CalculatorDefinitionV2> calculators) {
    _wordIndex.clear();
    _categoryIndex.clear();
    _tagIndex.clear();

    for (final calc in calculators) {
      final words = _tokenize(calc.titleKey);
      for (final word in words) {
        _wordIndex.putIfAbsent(word, () => <String>{}).add(calc.id);
      }

      _categoryIndex.putIfAbsent(calc.category, () => <String>[]).add(calc.id);

      for (final tag in calc.tags) {
        _tagIndex.putIfAbsent(tag.toLowerCase(), () => <String>{}).add(calc.id);
      }
    }
  }

  List<String> search(String query) {
    final words = _tokenize(query);
    if (words.isEmpty) return [];

    Set<String>? result;
    for (final word in words) {
      final matches = _wordIndex[word] ?? _tagIndex[word] ?? <String>{};
      if (result == null) {
        result = Set<String>.from(matches);
      } else {
        result = result.intersection(matches);
      }
    }

    return result?.toList() ?? <String>[];
  }

  List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\sа-яё]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 2)
        .toList();
  }
}
