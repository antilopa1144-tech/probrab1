import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/constants/app_typography.dart';

void main() {
  group('AppTypography', () {
    group('Headlines', () {
      test('headlineLarge has correct properties', () {
        expect(AppTypography.headlineLarge.fontSize, 24);
        expect(AppTypography.headlineLarge.fontWeight, FontWeight.w600);
        expect(AppTypography.headlineLarge.letterSpacing, -0.5);
        expect(AppTypography.headlineLarge.height, 1.2);
      });

      test('headlineMedium has correct properties', () {
        expect(AppTypography.headlineMedium.fontSize, 20);
        expect(AppTypography.headlineMedium.fontWeight, FontWeight.w600);
        expect(AppTypography.headlineMedium.height, 1.3);
      });
    });

    group('Titles', () {
      test('titleLarge has correct properties', () {
        expect(AppTypography.titleLarge.fontSize, 18);
        expect(AppTypography.titleLarge.fontWeight, FontWeight.w600);
        expect(AppTypography.titleLarge.height, 1.4);
      });

      test('titleMedium has correct properties', () {
        expect(AppTypography.titleMedium.fontSize, 16);
        expect(AppTypography.titleMedium.fontWeight, FontWeight.w500);
        expect(AppTypography.titleMedium.height, 1.4);
      });

      test('titleSmall has correct properties', () {
        expect(AppTypography.titleSmall.fontSize, 14);
        expect(AppTypography.titleSmall.fontWeight, FontWeight.w500);
        expect(AppTypography.titleSmall.height, 1.4);
      });
    });

    group('Body', () {
      test('bodyLarge has correct properties', () {
        expect(AppTypography.bodyLarge.fontSize, 16);
        expect(AppTypography.bodyLarge.fontWeight, FontWeight.w400);
        expect(AppTypography.bodyLarge.height, 1.5);
      });

      test('bodyMedium has correct properties', () {
        expect(AppTypography.bodyMedium.fontSize, 14);
        expect(AppTypography.bodyMedium.fontWeight, FontWeight.w400);
        expect(AppTypography.bodyMedium.height, 1.5);
      });

      test('bodySmall has correct properties', () {
        expect(AppTypography.bodySmall.fontSize, 12);
        expect(AppTypography.bodySmall.fontWeight, FontWeight.w400);
        expect(AppTypography.bodySmall.height, 1.5);
      });
    });

    group('Labels', () {
      test('labelLarge has correct properties', () {
        expect(AppTypography.labelLarge.fontSize, 14);
        expect(AppTypography.labelLarge.fontWeight, FontWeight.w500);
        expect(AppTypography.labelLarge.height, 1.4);
      });

      test('labelMedium has correct properties', () {
        expect(AppTypography.labelMedium.fontSize, 12);
        expect(AppTypography.labelMedium.fontWeight, FontWeight.w500);
        expect(AppTypography.labelMedium.height, 1.4);
      });

      test('labelSmall has correct properties', () {
        expect(AppTypography.labelSmall.fontSize, 10);
        expect(AppTypography.labelSmall.fontWeight, FontWeight.w500);
        expect(AppTypography.labelSmall.height, 1.4);
        expect(AppTypography.labelSmall.letterSpacing, 0.5);
      });
    });

    group('Header (результаты)', () {
      test('headerLabel has correct properties', () {
        expect(AppTypography.headerLabel.fontSize, 12);
        expect(AppTypography.headerLabel.fontWeight, FontWeight.bold);
        expect(AppTypography.headerLabel.letterSpacing, 0.8);
      });

      test('headerValue has correct properties', () {
        expect(AppTypography.headerValue.fontSize, 18);
        expect(AppTypography.headerValue.fontWeight, FontWeight.bold);
        expect(AppTypography.headerValue.height, 1.3);
      });
    });

    group('Font size scale', () {
      test('font sizes increase progressively within each category', () {
        // Body: small < medium < large
        expect(AppTypography.bodySmall.fontSize,
            lessThan(AppTypography.bodyMedium.fontSize!));
        expect(AppTypography.bodyMedium.fontSize,
            lessThan(AppTypography.bodyLarge.fontSize!));

        // Title: small < medium < large
        expect(AppTypography.titleSmall.fontSize,
            lessThan(AppTypography.titleMedium.fontSize!));
        expect(AppTypography.titleMedium.fontSize,
            lessThan(AppTypography.titleLarge.fontSize!));

        // Label: small < medium < large
        expect(AppTypography.labelSmall.fontSize,
            lessThan(AppTypography.labelMedium.fontSize!));
        expect(AppTypography.labelMedium.fontSize,
            lessThan(AppTypography.labelLarge.fontSize!));

        // Headline: medium < large
        expect(AppTypography.headlineMedium.fontSize,
            lessThan(AppTypography.headlineLarge.fontSize!));
      });
    });
  });
}
