import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/constants/calculator_design_system.dart';

void main() {
  group('CalculatorDesignSystem', () {
    group('Typography', () {
      test('headlineLarge has correct properties', () {
        expect(CalculatorDesignSystem.headlineLarge.fontSize, 24);
        expect(CalculatorDesignSystem.headlineLarge.fontWeight, FontWeight.w600);
        expect(CalculatorDesignSystem.headlineLarge.letterSpacing, -0.5);
        expect(CalculatorDesignSystem.headlineLarge.height, 1.2);
      });

      test('headlineMedium has correct properties', () {
        expect(CalculatorDesignSystem.headlineMedium.fontSize, 20);
        expect(CalculatorDesignSystem.headlineMedium.fontWeight, FontWeight.w600);
        expect(CalculatorDesignSystem.headlineMedium.height, 1.3);
      });

      test('titleLarge has correct properties', () {
        expect(CalculatorDesignSystem.titleLarge.fontSize, 18);
        expect(CalculatorDesignSystem.titleLarge.fontWeight, FontWeight.w600);
      });

      test('titleMedium has correct properties', () {
        expect(CalculatorDesignSystem.titleMedium.fontSize, 16);
        expect(CalculatorDesignSystem.titleMedium.fontWeight, FontWeight.w500);
      });

      test('titleSmall has correct properties', () {
        expect(CalculatorDesignSystem.titleSmall.fontSize, 14);
        expect(CalculatorDesignSystem.titleSmall.fontWeight, FontWeight.w500);
      });

      test('bodyLarge has correct properties', () {
        expect(CalculatorDesignSystem.bodyLarge.fontSize, 16);
        expect(CalculatorDesignSystem.bodyLarge.fontWeight, FontWeight.w400);
        expect(CalculatorDesignSystem.bodyLarge.height, 1.5);
      });

      test('bodyMedium has correct properties', () {
        expect(CalculatorDesignSystem.bodyMedium.fontSize, 14);
        expect(CalculatorDesignSystem.bodyMedium.fontWeight, FontWeight.w400);
      });

      test('bodySmall has correct properties', () {
        expect(CalculatorDesignSystem.bodySmall.fontSize, 12);
        expect(CalculatorDesignSystem.bodySmall.fontWeight, FontWeight.w400);
      });

      test('labelLarge has correct properties', () {
        expect(CalculatorDesignSystem.labelLarge.fontSize, 14);
        expect(CalculatorDesignSystem.labelLarge.fontWeight, FontWeight.w500);
      });

      test('labelMedium has correct properties', () {
        expect(CalculatorDesignSystem.labelMedium.fontSize, 12);
        expect(CalculatorDesignSystem.labelMedium.fontWeight, FontWeight.w500);
      });

      test('labelSmall has correct properties', () {
        expect(CalculatorDesignSystem.labelSmall.fontSize, 10);
        expect(CalculatorDesignSystem.labelSmall.fontWeight, FontWeight.w500);
        expect(CalculatorDesignSystem.labelSmall.letterSpacing, 0.5);
      });

      test('headerLabel has correct properties', () {
        expect(CalculatorDesignSystem.headerLabel.fontSize, 10);
        expect(CalculatorDesignSystem.headerLabel.fontWeight, FontWeight.bold);
        expect(CalculatorDesignSystem.headerLabel.letterSpacing, 0.8);
      });

      test('headerValue has correct properties', () {
        expect(CalculatorDesignSystem.headerValue.fontSize, 18);
        expect(CalculatorDesignSystem.headerValue.fontWeight, FontWeight.bold);
      });
    });

    group('Spacing', () {
      test('spacingXS is 4', () {
        expect(CalculatorDesignSystem.spacingXS, 4.0);
      });

      test('spacingS is 8', () {
        expect(CalculatorDesignSystem.spacingS, 8.0);
      });

      test('spacingM is 16', () {
        expect(CalculatorDesignSystem.spacingM, 16.0);
      });

      test('spacingL is 24', () {
        expect(CalculatorDesignSystem.spacingL, 24.0);
      });

      test('spacingXL is 32', () {
        expect(CalculatorDesignSystem.spacingXL, 32.0);
      });

      test('spacingXXL is 40', () {
        expect(CalculatorDesignSystem.spacingXXL, 40.0);
      });

      test('spacing values increase progressively', () {
        expect(CalculatorDesignSystem.spacingXS, lessThan(CalculatorDesignSystem.spacingS));
        expect(CalculatorDesignSystem.spacingS, lessThan(CalculatorDesignSystem.spacingM));
        expect(CalculatorDesignSystem.spacingM, lessThan(CalculatorDesignSystem.spacingL));
        expect(CalculatorDesignSystem.spacingL, lessThan(CalculatorDesignSystem.spacingXL));
        expect(CalculatorDesignSystem.spacingXL, lessThan(CalculatorDesignSystem.spacingXXL));
      });
    });

    group('Border Radius', () {
      test('radiusXS is 4', () {
        expect(CalculatorDesignSystem.radiusXS, 4.0);
      });

      test('radiusS is 8', () {
        expect(CalculatorDesignSystem.radiusS, 8.0);
      });

      test('radiusM is 12', () {
        expect(CalculatorDesignSystem.radiusM, 12.0);
      });

      test('radiusL is 16', () {
        expect(CalculatorDesignSystem.radiusL, 16.0);
      });

      test('radiusXL is 20', () {
        expect(CalculatorDesignSystem.radiusXL, 20.0);
      });

      test('radiusXXL is 24', () {
        expect(CalculatorDesignSystem.radiusXXL, 24.0);
      });

      test('headerBorderRadius has rounded bottom corners', () {
        const radius = CalculatorDesignSystem.headerBorderRadius;
        expect(radius.bottomLeft, const Radius.circular(24.0));
        expect(radius.bottomRight, const Radius.circular(24.0));
        expect(radius.topLeft, Radius.zero);
        expect(radius.topRight, Radius.zero);
      });

      test('cardBorderRadius is circular with radiusL', () {
        final radius = CalculatorDesignSystem.cardBorderRadius;
        expect(radius, BorderRadius.circular(16.0));
      });

      test('inputBorderRadius is circular with radiusS', () {
        final radius = CalculatorDesignSystem.inputBorderRadius;
        expect(radius, BorderRadius.circular(8.0));
      });

      test('selectorBorderRadius is circular with radiusM', () {
        final radius = CalculatorDesignSystem.selectorBorderRadius;
        expect(radius, BorderRadius.circular(12.0));
      });
    });

    group('Sizes', () {
      test('inputHeight is 48', () {
        expect(CalculatorDesignSystem.inputHeight, 48.0);
      });

      test('buttonHeight is 48', () {
        expect(CalculatorDesignSystem.buttonHeight, 48.0);
      });

      test('buttonHeightSmall is 36', () {
        expect(CalculatorDesignSystem.buttonHeightSmall, 36.0);
      });

      test('borderWidthThin is 1', () {
        expect(CalculatorDesignSystem.borderWidthThin, 1.0);
      });

      test('borderWidthMedium is 2', () {
        expect(CalculatorDesignSystem.borderWidthMedium, 2.0);
      });

      test('iconSizeSmall is 16', () {
        expect(CalculatorDesignSystem.iconSizeSmall, 16.0);
      });

      test('iconSizeMedium is 24', () {
        expect(CalculatorDesignSystem.iconSizeMedium, 24.0);
      });

      test('iconSizeLarge is 32', () {
        expect(CalculatorDesignSystem.iconSizeLarge, 32.0);
      });
    });

    group('Padding', () {
      test('cardPadding is all spacingM', () {
        expect(CalculatorDesignSystem.cardPadding, const EdgeInsets.all(16.0));
      });

      test('cardPaddingLarge is all spacingL', () {
        expect(CalculatorDesignSystem.cardPaddingLarge, const EdgeInsets.all(24.0));
      });

      test('screenPadding is all spacingM', () {
        expect(CalculatorDesignSystem.screenPadding, const EdgeInsets.all(16.0));
      });

      test('screenPaddingHorizontal is symmetric horizontal', () {
        expect(
          CalculatorDesignSystem.screenPaddingHorizontal,
          const EdgeInsets.symmetric(horizontal: 16.0),
        );
      });

      test('screenPaddingVertical is symmetric vertical', () {
        expect(
          CalculatorDesignSystem.screenPaddingVertical,
          const EdgeInsets.symmetric(vertical: 16.0),
        );
      });

      test('inputPadding has correct values', () {
        expect(
          CalculatorDesignSystem.inputPadding,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        );
      });

      test('sectionPadding is symmetric vertical', () {
        expect(
          CalculatorDesignSystem.sectionPadding,
          const EdgeInsets.symmetric(vertical: 16.0),
        );
      });
    });

    group('Decorations', () {
      test('cardDecoration returns BoxDecoration with shadow', () {
        final decoration = CalculatorDesignSystem.cardDecoration();
        expect(decoration.color, Colors.white);
        expect(decoration.borderRadius, BorderRadius.circular(16.0));
        expect(decoration.boxShadow, isNotNull);
        expect(decoration.boxShadow!.length, 1);
      });

      test('cardDecoration accepts custom color', () {
        final decoration = CalculatorDesignSystem.cardDecoration(color: Colors.blue);
        expect(decoration.color, Colors.blue);
      });

      test('cardDecorationFlat returns BoxDecoration without shadow', () {
        final decoration = CalculatorDesignSystem.cardDecorationFlat();
        expect(decoration.color, Colors.white);
        expect(decoration.borderRadius, BorderRadius.circular(16.0));
        expect(decoration.boxShadow, isNull);
      });

      test('cardDecorationFlat accepts custom color and border', () {
        final decoration = CalculatorDesignSystem.cardDecorationFlat(
          color: Colors.red,
          borderColor: Colors.black,
        );
        expect(decoration.color, Colors.red);
        expect(decoration.border, isNotNull);
      });

      test('inputDecoration returns InputDecoration with label', () {
        final decoration = CalculatorDesignSystem.inputDecoration(label: 'Test Label');
        expect(decoration.labelText, 'Test Label');
        expect(decoration.filled, true);
      });

      test('inputDecoration accepts hint and suffix', () {
        final decoration = CalculatorDesignSystem.inputDecoration(
          label: 'Test',
          hint: 'Enter value',
          suffixIcon: const Icon(Icons.info),
          fillColor: Colors.grey,
        );
        expect(decoration.hintText, 'Enter value');
        expect(decoration.suffixIcon, isNotNull);
        expect(decoration.fillColor, Colors.grey);
      });
    });

    group('Animations', () {
      test('animationDurationFast is 150ms', () {
        expect(
          CalculatorDesignSystem.animationDurationFast,
          const Duration(milliseconds: 150),
        );
      });

      test('animationDurationMedium is 250ms', () {
        expect(
          CalculatorDesignSystem.animationDurationMedium,
          const Duration(milliseconds: 250),
        );
      });

      test('animationDurationSlow is 350ms', () {
        expect(
          CalculatorDesignSystem.animationDurationSlow,
          const Duration(milliseconds: 350),
        );
      });

      test('animation durations increase progressively', () {
        expect(
          CalculatorDesignSystem.animationDurationFast,
          lessThan(CalculatorDesignSystem.animationDurationMedium),
        );
        expect(
          CalculatorDesignSystem.animationDurationMedium,
          lessThan(CalculatorDesignSystem.animationDurationSlow),
        );
      });

      test('animationCurve is easeInOut', () {
        expect(CalculatorDesignSystem.animationCurve, Curves.easeInOut);
      });

      test('animationCurveFastOut is easeOut', () {
        expect(CalculatorDesignSystem.animationCurveFastOut, Curves.easeOut);
      });

      test('animationCurveSlowIn is easeIn', () {
        expect(CalculatorDesignSystem.animationCurveSlowIn, Curves.easeIn);
      });
    });

    group('Helper Widgets', () {
      testWidgets('verticalSpacingS creates correct SizedBox', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [CalculatorDesignSystem.verticalSpacingS],
            ),
          ),
        );
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.height, 8.0);
      });

      testWidgets('verticalSpacingM creates correct SizedBox', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [CalculatorDesignSystem.verticalSpacingM],
            ),
          ),
        );
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.height, 16.0);
      });

      testWidgets('verticalSpacingL creates correct SizedBox', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [CalculatorDesignSystem.verticalSpacingL],
            ),
          ),
        );
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.height, 24.0);
      });

      testWidgets('verticalSpacingXL creates correct SizedBox', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [CalculatorDesignSystem.verticalSpacingXL],
            ),
          ),
        );
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.height, 32.0);
      });

      testWidgets('horizontalSpacingS creates correct SizedBox', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Row(
              children: [CalculatorDesignSystem.horizontalSpacingS],
            ),
          ),
        );
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.width, 8.0);
      });

      testWidgets('horizontalSpacingM creates correct SizedBox', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Row(
              children: [CalculatorDesignSystem.horizontalSpacingM],
            ),
          ),
        );
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.width, 16.0);
      });

      testWidgets('horizontalSpacingL creates correct SizedBox', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Row(
              children: [CalculatorDesignSystem.horizontalSpacingL],
            ),
          ),
        );
        final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
        expect(sizedBox.width, 24.0);
      });

      testWidgets('divider creates Divider widget', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [CalculatorDesignSystem.divider()],
            ),
          ),
        );
        expect(find.byType(Divider), findsOneWidget);
      });

      testWidgets('divider accepts custom parameters', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Column(
              children: [
                CalculatorDesignSystem.divider(height: 32, color: Colors.red),
              ],
            ),
          ),
        );
        final divider = tester.widget<Divider>(find.byType(Divider));
        expect(divider.height, 32);
        expect(divider.color, Colors.red);
      });
    });
  });
}
