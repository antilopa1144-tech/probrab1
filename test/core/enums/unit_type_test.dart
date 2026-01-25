import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/enums/unit_type.dart';

void main() {
  group('UnitType', () {
    group('symbol', () {
      test('returns correct symbol for squareMeters', () {
        expect(UnitType.squareMeters.symbol, equals('м²'));
      });

      test('returns correct symbol for cubicMeters', () {
        expect(UnitType.cubicMeters.symbol, equals('м³'));
      });

      test('returns correct symbol for linearMeters', () {
        expect(UnitType.linearMeters.symbol, equals('пог. м'));
      });

      test('returns correct symbol for pieces', () {
        expect(UnitType.pieces.symbol, equals('шт.'));
      });

      test('returns correct symbol for liters', () {
        expect(UnitType.liters.symbol, equals('л'));
      });

      test('returns correct symbol for kilograms', () {
        expect(UnitType.kilograms.symbol, equals('кг'));
      });

      test('returns correct symbol for tons', () {
        expect(UnitType.tons.symbol, equals('т'));
      });

      test('returns correct symbol for bags', () {
        expect(UnitType.bags.symbol, equals('меш.'));
      });

      test('returns correct symbol for packages', () {
        expect(UnitType.packages.symbol, equals('уп.'));
      });

      test('returns correct symbol for rolls', () {
        expect(UnitType.rolls.symbol, equals('рул.'));
      });

      test('returns correct symbol for sheets', () {
        expect(UnitType.sheets.symbol, equals('лист.'));
      });

      test('returns correct symbol for meters', () {
        expect(UnitType.meters.symbol, equals('м'));
      });

      test('returns correct symbol for centimeters', () {
        expect(UnitType.centimeters.symbol, equals('см'));
      });

      test('returns correct symbol for millimeters', () {
        expect(UnitType.millimeters.symbol, equals('мм'));
      });

      test('returns correct symbol for percent', () {
        expect(UnitType.percent.symbol, equals('%'));
      });

      test('returns correct symbol for hours', () {
        expect(UnitType.hours.symbol, equals('ч'));
      });

      test('returns correct symbol for days', () {
        expect(UnitType.days.symbol, equals('дн.'));
      });

      test('returns correct symbol for rubles', () {
        expect(UnitType.rubles.symbol, equals('₽'));
      });
    });

    group('translationKey', () {
      test('returns correct key for squareMeters', () {
        expect(UnitType.squareMeters.translationKey, equals('unit.square_meters'));
      });

      test('returns correct key for cubicMeters', () {
        expect(UnitType.cubicMeters.translationKey, equals('unit.cubic_meters'));
      });

      test('returns correct key for linearMeters', () {
        expect(UnitType.linearMeters.translationKey, equals('unit.linear_meters'));
      });

      test('returns correct key for pieces', () {
        expect(UnitType.pieces.translationKey, equals('unit.pieces'));
      });

      test('returns correct key for liters', () {
        expect(UnitType.liters.translationKey, equals('unit.liters'));
      });

      test('returns correct key for kilograms', () {
        expect(UnitType.kilograms.translationKey, equals('unit.kilograms'));
      });

      test('returns correct key for tons', () {
        expect(UnitType.tons.translationKey, equals('unit.tons'));
      });

      test('returns correct key for bags', () {
        expect(UnitType.bags.translationKey, equals('unit.bags'));
      });

      test('returns correct key for packages', () {
        expect(UnitType.packages.translationKey, equals('unit.packages'));
      });

      test('returns correct key for rolls', () {
        expect(UnitType.rolls.translationKey, equals('unit.rolls'));
      });

      test('returns correct key for sheets', () {
        expect(UnitType.sheets.translationKey, equals('unit.sheets'));
      });

      test('returns correct key for meters', () {
        expect(UnitType.meters.translationKey, equals('unit.meters'));
      });

      test('returns correct key for centimeters', () {
        expect(UnitType.centimeters.translationKey, equals('unit.centimeters'));
      });

      test('returns correct key for millimeters', () {
        expect(UnitType.millimeters.translationKey, equals('unit.millimeters'));
      });

      test('returns correct key for percent', () {
        expect(UnitType.percent.translationKey, equals('unit.percent'));
      });

      test('returns correct key for hours', () {
        expect(UnitType.hours.translationKey, equals('unit.hours'));
      });

      test('returns correct key for days', () {
        expect(UnitType.days.translationKey, equals('unit.days'));
      });

      test('returns correct key for rubles', () {
        expect(UnitType.rubles.translationKey, equals('unit.rubles'));
      });
    });

    test('has all expected enum values', () {
      const values = UnitType.values;
      expect(values.length, equals(20));
      expect(values, contains(UnitType.squareMeters));
      expect(values, contains(UnitType.cubicMeters));
      expect(values, contains(UnitType.linearMeters));
      expect(values, contains(UnitType.pieces));
      expect(values, contains(UnitType.liters));
      expect(values, contains(UnitType.kilograms));
      expect(values, contains(UnitType.tons));
      expect(values, contains(UnitType.bags));
      expect(values, contains(UnitType.packages));
      expect(values, contains(UnitType.rolls));
      expect(values, contains(UnitType.sheets));
      expect(values, contains(UnitType.meters));
      expect(values, contains(UnitType.centimeters));
      expect(values, contains(UnitType.millimeters));
      expect(values, contains(UnitType.percent));
      expect(values, contains(UnitType.hours));
      expect(values, contains(UnitType.days));
      expect(values, contains(UnitType.rubles));
      expect(values, contains(UnitType.litersPerSqm));
      expect(values, contains(UnitType.degrees));
    });
  });
}
