import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_text_field.dart';

void main() {
  group('CalculatorTextField', () {
    testWidgets('не уведомляет родителя до потери фокуса', (tester) async {
      var value = 3.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorTextField(
              label: 'Test',
              value: value,
              minValue: 3,
              maxValue: 100,
              isInteger: true,
              onChanged: (v) => value = v,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '15');
      await tester.pump();
      expect(find.text('15'), findsOneWidget);
      expect(value, 3.0);

      await tester.tap(find.byType(Scaffold));
      await tester.pump();
      expect(value, 15.0);
    });

    testWidgets('применяет minValue после потери фокуса', (tester) async {
      var value = 10.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorTextField(
              label: 'Test',
              value: value,
              minValue: 3,
              maxValue: 100,
              isInteger: true,
              onChanged: (v) => value = v,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '2');
      await tester.pump();
      expect(value, 10.0);

      await tester.tap(find.byType(Scaffold));
      await tester.pump();
      expect(find.text('3'), findsOneWidget);
      expect(value, 3.0);
    });
  });
}
