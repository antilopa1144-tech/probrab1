import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/utils/number_parser.dart';

void main() {
  group('NumberParser', () {
    test('parses decimal with comma separator', () {
      expect(NumberParser.parse('2,5'), equals(2.5));
    });

    test('parses spaced thousands', () {
      expect(NumberParser.parse('1 250,75'), equals(1250.75));
    });

    test('parses dotted thousands with comma decimals', () {
      expect(NumberParser.parse('1.200,50'), equals(1200.5));
    });

    test('parses input with extra characters', () {
      expect(NumberParser.parse('~ 3 500 мм'), equals(3500));
    });

    test('returns null for invalid numbers', () {
      expect(NumberParser.parse('abc'), isNull);
    });

    test('format removes trailing zeros', () {
      expect(NumberParser.format(12.5000), equals('12.5'));
      expect(NumberParser.format(10.0), equals('10'));
    });
  });
}
