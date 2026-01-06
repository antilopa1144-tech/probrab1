import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/constants/calculator_colors.dart';

void main() {
  group('CalculatorColors - Category Colors', () {
    test('interior colors are defined', () {
      expect(CalculatorColors.interior, const Color(0xFF10B981));
      expect(CalculatorColors.interiorLight, const Color(0xFFD1FAE5));
      expect(CalculatorColors.interiorDark, const Color(0xFF047857));
    });

    test('flooring colors are defined', () {
      expect(CalculatorColors.flooring, const Color(0xFFF59E0B));
      expect(CalculatorColors.flooringLight, const Color(0xFFFEF3C7));
      expect(CalculatorColors.flooringDark, const Color(0xFFD97706));
    });

    test('roofing colors are defined', () {
      expect(CalculatorColors.roofing, const Color(0xFFEF4444));
      expect(CalculatorColors.roofingLight, const Color(0xFFFEE2E2));
      expect(CalculatorColors.roofingDark, const Color(0xFFDC2626));
    });

    test('foundation colors are defined', () {
      expect(CalculatorColors.foundation, const Color(0xFF6366F1));
      expect(CalculatorColors.foundationLight, const Color(0xFFE0E7FF));
      expect(CalculatorColors.foundationDark, const Color(0xFF4F46E5));
    });

    test('facade colors are defined', () {
      expect(CalculatorColors.facade, const Color(0xFF8B5CF6));
      expect(CalculatorColors.facadeLight, const Color(0xFFEDE9FE));
      expect(CalculatorColors.facadeDark, const Color(0xFF7C3AED));
    });

    test('engineering colors are defined', () {
      expect(CalculatorColors.engineering, const Color(0xFF06B6D4));
      expect(CalculatorColors.engineeringLight, const Color(0xFFCFFAFE));
      expect(CalculatorColors.engineeringDark, const Color(0xFF0891B2));
    });

    test('walls colors are defined', () {
      expect(CalculatorColors.walls, const Color(0xFF14B8A6));
      expect(CalculatorColors.wallsLight, const Color(0xFFCCFBF1));
      expect(CalculatorColors.wallsDark, const Color(0xFF0F766E));
    });

    test('ceiling colors are defined', () {
      expect(CalculatorColors.ceiling, const Color(0xFF3B82F6));
      expect(CalculatorColors.ceilingLight, const Color(0xFFDBEAFE));
      expect(CalculatorColors.ceilingDark, const Color(0xFF2563EB));
    });
  });

  group('CalculatorColors - General Colors', () {
    test('background colors are defined', () {
      expect(CalculatorColors.backgroundPrimary, const Color(0xFFF8FAFC));
      expect(CalculatorColors.backgroundSecondary, const Color(0xFFFFFFFF));
    });

    test('card background colors are defined', () {
      expect(CalculatorColors.cardBackground, Colors.white);
      expect(CalculatorColors.cardBackgroundLight, const Color(0xFFF1F5F9));
    });

    test('input background colors are defined', () {
      expect(CalculatorColors.inputBackground, const Color(0xFFF1F5F9));
      expect(CalculatorColors.inputBackgroundFocused, Colors.white);
    });

    test('text colors are defined', () {
      expect(CalculatorColors.textPrimary, const Color(0xFF1E293B));
      expect(CalculatorColors.textSecondary, const Color(0xFF475569));
      expect(CalculatorColors.textTertiary, const Color(0xFF64748B));
      expect(CalculatorColors.textDisabled, const Color(0xFFCBD5E1));
    });

    test('border colors are defined', () {
      expect(CalculatorColors.borderDefault, const Color(0xFFE2E8F0));
      expect(CalculatorColors.borderFocused, const Color(0xFF94A3B8));
      expect(CalculatorColors.divider, const Color(0xFFE2E8F0));
    });

    test('result card colors are defined', () {
      expect(CalculatorColors.resultCardBackground, const Color(0xFF2D3748));
      expect(CalculatorColors.resultCardText, Colors.white);
      expect(CalculatorColors.resultCardTextSecondary, const Color(0xFF9CA3AF));
    });
  });

  group('CalculatorColors - Shadows', () {
    test('shadowSmall returns BoxShadow', () {
      final shadow = CalculatorColors.shadowSmall;
      expect(shadow, isA<BoxShadow>());
      expect(shadow.blurRadius, 4);
      expect(shadow.offset, const Offset(0, 2));
    });

    test('shadowMedium returns BoxShadow', () {
      final shadow = CalculatorColors.shadowMedium;
      expect(shadow, isA<BoxShadow>());
      expect(shadow.blurRadius, 10);
      expect(shadow.offset, const Offset(0, 4));
    });

    test('shadowLarge returns BoxShadow', () {
      final shadow = CalculatorColors.shadowLarge;
      expect(shadow, isA<BoxShadow>());
      expect(shadow.blurRadius, 15);
      expect(shadow.offset, const Offset(0, 5));
    });
  });

  group('CalculatorColors - getColorByCategory', () {
    test('returns correct color for each category', () {
      expect(CalculatorColors.getColorByCategory('interior'), CalculatorColors.interior);
      expect(CalculatorColors.getColorByCategory('flooring'), CalculatorColors.flooring);
      expect(CalculatorColors.getColorByCategory('roofing'), CalculatorColors.roofing);
      expect(CalculatorColors.getColorByCategory('foundation'), CalculatorColors.foundation);
      expect(CalculatorColors.getColorByCategory('facade'), CalculatorColors.facade);
      expect(CalculatorColors.getColorByCategory('engineering'), CalculatorColors.engineering);
      expect(CalculatorColors.getColorByCategory('walls'), CalculatorColors.walls);
      expect(CalculatorColors.getColorByCategory('ceiling'), CalculatorColors.ceiling);
    });

    test('returns interior as default for unknown category', () {
      expect(CalculatorColors.getColorByCategory('unknown'), CalculatorColors.interior);
      expect(CalculatorColors.getColorByCategory(''), CalculatorColors.interior);
    });

    test('is case insensitive', () {
      expect(CalculatorColors.getColorByCategory('INTERIOR'), CalculatorColors.interior);
      expect(CalculatorColors.getColorByCategory('Interior'), CalculatorColors.interior);
      expect(CalculatorColors.getColorByCategory('FLOORING'), CalculatorColors.flooring);
    });
  });

  group('CalculatorColors - getLightColorByCategory', () {
    test('returns correct light color for each category', () {
      expect(CalculatorColors.getLightColorByCategory('interior'), CalculatorColors.interiorLight);
      expect(CalculatorColors.getLightColorByCategory('flooring'), CalculatorColors.flooringLight);
      expect(CalculatorColors.getLightColorByCategory('roofing'), CalculatorColors.roofingLight);
      expect(CalculatorColors.getLightColorByCategory('foundation'), CalculatorColors.foundationLight);
      expect(CalculatorColors.getLightColorByCategory('facade'), CalculatorColors.facadeLight);
      expect(CalculatorColors.getLightColorByCategory('engineering'), CalculatorColors.engineeringLight);
      expect(CalculatorColors.getLightColorByCategory('walls'), CalculatorColors.wallsLight);
      expect(CalculatorColors.getLightColorByCategory('ceiling'), CalculatorColors.ceilingLight);
    });

    test('returns interiorLight as default for unknown category', () {
      expect(CalculatorColors.getLightColorByCategory('unknown'), CalculatorColors.interiorLight);
    });
  });

  group('CalculatorColors - getDarkColorByCategory', () {
    test('returns correct dark color for each category', () {
      expect(CalculatorColors.getDarkColorByCategory('interior'), CalculatorColors.interiorDark);
      expect(CalculatorColors.getDarkColorByCategory('flooring'), CalculatorColors.flooringDark);
      expect(CalculatorColors.getDarkColorByCategory('roofing'), CalculatorColors.roofingDark);
      expect(CalculatorColors.getDarkColorByCategory('foundation'), CalculatorColors.foundationDark);
      expect(CalculatorColors.getDarkColorByCategory('facade'), CalculatorColors.facadeDark);
      expect(CalculatorColors.getDarkColorByCategory('engineering'), CalculatorColors.engineeringDark);
      expect(CalculatorColors.getDarkColorByCategory('walls'), CalculatorColors.wallsDark);
      expect(CalculatorColors.getDarkColorByCategory('ceiling'), CalculatorColors.ceilingDark);
    });

    test('returns interiorDark as default for unknown category', () {
      expect(CalculatorColors.getDarkColorByCategory('unknown'), CalculatorColors.interiorDark);
    });
  });
}
