import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_text_field.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  // Helper function to wrap widgets in ProviderScope (required for Riverpod)
  Widget wrapWithProviders(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('CalculatorTextField - Voice Input Integration', () {
    testWidgets('показывает кнопку микрофона по умолчанию', (tester) async {
      setTestViewportSize(tester);
      double value = 0.0;

      await tester.pumpWidget(
        wrapWithProviders(
          CalculatorTextField(
            label: 'Тест',
            value: value,
            onChanged: (v) => value = v,
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    });

    testWidgets('не показывает кнопку микрофона если enableVoiceInput=false',
        (tester) async {
      setTestViewportSize(tester);
      double value = 0.0;

      await tester.pumpWidget(
        wrapWithProviders(
          CalculatorTextField(
            label: 'Тест',
            value: value,
            onChanged: (v) => value = v,
            enableVoiceInput: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsNothing);
    });

    testWidgets('обновляет значение через ручной ввод', (tester) async {
      setTestViewportSize(tester);
      double value = 5.0;

      await tester.pumpWidget(
        wrapWithProviders(
          CalculatorTextField(
            label: 'Длина (м)',
            value: value,
            onChanged: (v) => value = v,
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, '10.5');
      await tester.pump();

      expect(value, 10.5);
    });

    testWidgets('применяет minValue к ручному вводу', (tester) async {
      setTestViewportSize(tester);
      double value = 5.0;

      await tester.pumpWidget(
        wrapWithProviders(
          CalculatorTextField(
            label: 'Длина (м)',
            value: value,
            onChanged: (v) => value = v,
            minValue: 1.0,
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, '0.5');
      await tester.pump();

      expect(value, 1.0);
    });

    testWidgets('обрабатывает запятую как десятичный разделитель',
        (tester) async {
      setTestViewportSize(tester);
      double value = 0.0;

      await tester.pumpWidget(
        wrapWithProviders(
          CalculatorTextField(
            label: 'Тест',
            value: value,
            onChanged: (v) => value = v,
          ),
        ),
      );

      final textField = find.byType(TextField);
      await tester.enterText(textField, '3,5');
      await tester.pump();

      expect(value, 3.5);
    });
  });

  group('RoomDimensionsFields - Интеграция', () {
    testWidgets('создаёт три поля для размеров комнаты', (tester) async {
      setTestViewportSize(tester);
      double length = 4.0;
      double width = 3.0;
      double height = 2.7;

      await tester.pumpWidget(
        wrapWithProviders(
          RoomDimensionsFields(
            length: length,
            width: width,
            height: height,
            onLengthChanged: (v) => length = v,
            onWidthChanged: (v) => width = v,
            onHeightChanged: (v) => height = v,
          ),
        ),
      );

      expect(find.byType(CalculatorTextField), findsNWidgets(3));
      expect(find.text('Длина (м)'), findsOneWidget);
      expect(find.text('Ширина (м)'), findsOneWidget);
      expect(find.text('Высота потолка (м)'), findsOneWidget);
    });

    testWidgets('все три поля имеют кнопки микрофона', (tester) async {
      setTestViewportSize(tester);
      double length = 4.0;
      double width = 3.0;
      double height = 2.7;

      await tester.pumpWidget(
        wrapWithProviders(
          RoomDimensionsFields(
            length: length,
            width: width,
            height: height,
            onLengthChanged: (v) => length = v,
            onWidthChanged: (v) => width = v,
            onHeightChanged: (v) => height = v,
          ),
        ),
      );

      expect(find.byIcon(Icons.mic_rounded), findsNWidgets(3));
    });
  });
}
