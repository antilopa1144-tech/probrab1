import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_slider_field.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  group('CalculatorSliderField', () {
    testWidgets('отображает label', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Тестовая метка',
              value: 50,
              min: 0,
              max: 100,
              suffix: 'м²',
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Label appears in header row and in the text field below
      expect(find.text('Тестовая метка'), findsAtLeastNWidgets(1));
    });

    testWidgets('отображает значение с суффиксом', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Площадь',
              value: 50,
              min: 0,
              max: 100,
              suffix: 'м²',
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('50 м²'), findsOneWidget);
    });

    testWidgets('форматирует целые числа без десятичных', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Тест',
              value: 25.0,
              min: 0,
              max: 100,
              suffix: 'шт',
              accentColor: Colors.green,
              onChanged: (_) {},
              decimalPlaces: 0,
            ),
          ),
        ),
      );

      expect(find.text('25 шт'), findsOneWidget);
    });

    testWidgets('форматирует значение с decimalPlaces', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Длина',
              value: 12.567,
              min: 0,
              max: 100,
              suffix: 'м',
              accentColor: Colors.red,
              onChanged: (_) {},
              decimalPlaces: 2,
            ),
          ),
        ),
      );

      expect(find.text('12.57 м'), findsOneWidget);
    });

    testWidgets('скрывает значение когда showValue=false', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              suffix: 'м²',
              accentColor: Colors.blue,
              onChanged: (_) {},
              showValue: false,
            ),
          ),
        ),
      );

      // Label appears in header row and in the text field below
      expect(find.text('Тест'), findsAtLeastNWidgets(1));
      expect(find.text('50 м²'), findsNothing);
    });

    testWidgets('отображает слайдер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              suffix: 'м²',
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('вызывает onChanged при перемещении слайдера', (tester) async {
      setTestViewportSize(tester);
      double currentValue = 50;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CalculatorSliderField(
                  label: 'Тест',
                  value: currentValue,
                  min: 0,
                  max: 100,
                  suffix: 'м²',
                  accentColor: Colors.blue,
                  onChanged: (v) {
                    setState(() => currentValue = v);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Перемещаем слайдер вправо
      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(currentValue, isNot(50));
    });

    testWidgets('применяет divisions к слайдеру', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              divisions: 10,
              suffix: 'м²',
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 10);
    });

    testWidgets('применяет accentColor к слайдеру', (tester) async {
      setTestViewportSize(tester);
      const testColor = Colors.purple;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              suffix: 'м²',
              accentColor: testColor,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.activeColor, testColor);
    });

    testWidgets('корректно работает с минимальным значением', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Минимум',
              value: 0,
              min: 0,
              max: 100,
              suffix: 'м²',
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('0 м²'), findsOneWidget);
    });

    testWidgets('корректно работает с максимальным значением', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Максимум',
              value: 100,
              min: 0,
              max: 100,
              suffix: 'м²',
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('100 м²'), findsOneWidget);
    });

    testWidgets('обрабатывает длинный label с overflow', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: CalculatorSliderField(
                label:
                    'Очень длинная метка которая не помещается в одну строку',
                value: 50,
                min: 0,
                max: 100,
                suffix: 'м²',
                accentColor: Colors.blue,
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      // Виджет должен отрендериться без ошибок
      expect(find.byType(CalculatorSliderField), findsOneWidget);
    });

    testWidgets('обрабатывает decimalPlaces=1', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderField(
              label: 'Тест',
              value: 12.34,
              min: 0,
              max: 100,
              suffix: 'м',
              accentColor: Colors.blue,
              onChanged: (_) {},
              decimalPlaces: 1,
            ),
          ),
        ),
      );

      expect(find.text('12.3 м'), findsOneWidget);
    });
  });

  group('CalculatorSliderFieldCompact', () {
    testWidgets('отображает label', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderFieldCompact(
              label: 'Компактная метка',
              value: 50,
              min: 0,
              max: 100,
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Компактная метка'), findsOneWidget);
    });

    testWidgets('не отображает значение', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderFieldCompact(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // В компактной версии нет отображения значения
      expect(find.text('50'), findsNothing);
    });

    testWidgets('отображает слайдер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderFieldCompact(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
    });

    testWidgets('вызывает onChanged при перемещении слайдера', (tester) async {
      setTestViewportSize(tester);
      double currentValue = 50;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CalculatorSliderFieldCompact(
                  label: 'Тест',
                  value: currentValue,
                  min: 0,
                  max: 100,
                  accentColor: Colors.blue,
                  onChanged: (v) {
                    setState(() => currentValue = v);
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.drag(find.byType(Slider), const Offset(100, 0));
      await tester.pump();

      expect(currentValue, isNot(50));
    });

    testWidgets('применяет divisions к слайдеру', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderFieldCompact(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              divisions: 5,
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.divisions, 5);
    });

    testWidgets('применяет accentColor к слайдеру', (tester) async {
      setTestViewportSize(tester);
      const testColor = Colors.orange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderFieldCompact(
              label: 'Тест',
              value: 50,
              min: 0,
              max: 100,
              accentColor: testColor,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.activeColor, testColor);
    });

    testWidgets('корректно работает с min/max', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalculatorSliderFieldCompact(
              label: 'Тест',
              value: 25,
              min: 10,
              max: 50,
              accentColor: Colors.blue,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final slider = tester.widget<Slider>(find.byType(Slider));
      expect(slider.min, 10);
      expect(slider.max, 50);
      expect(slider.value, 25);
    });
  });
}
