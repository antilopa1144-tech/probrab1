import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_text_field.dart';

void main() {
  group('CalculatorTextField', () {
    testWidgets('renders correctly with basic properties', (tester) async {
      double testValue = 10.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Длина (м)',
                value: testValue,
                onChanged: (value) => testValue = value,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Длина (м)'), findsOneWidget);
      expect(find.text('10.0'), findsOneWidget);
    });

    testWidgets('calls onChanged when value is entered', (tester) async {
      const double testValue = 5.0;
      double? changedValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Ширина (м)',
                value: testValue,
                onChanged: (value) => changedValue = value,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '15.5');
      await tester.pump();

      expect(changedValue, 15.5);
    });

    testWidgets('handles integer mode correctly', (tester) async {
      const double testValue = 5.0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Количество',
                value: testValue,
                onChanged: (value) {},
                isInteger: true,
              ),
            ),
          ),
        ),
      );

      // В integer режиме значение должно отображаться без десятичной части
      expect(find.text('5'), findsOneWidget);
      expect(find.text('5.0'), findsNothing);
    });

    testWidgets('shows suffix when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Площадь',
                value: 25.5,
                onChanged: (value) {},
                suffix: 'м²',
              ),
            ),
          ),
        ),
      );

      expect(find.text('м²'), findsOneWidget);
    });

    testWidgets('shows hint when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Высота',
                value: 0.0,
                onChanged: (value) {},
                hint: 'Введите высоту',
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.decoration?.hintText, 'Введите высоту');
    });

    testWidgets('shows icon when provided', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Длина',
                value: 10.0,
                onChanged: (value) {},
                icon: Icons.straighten,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.straighten), findsOneWidget);
    });

    testWidgets('enforces minValue constraint', (tester) async {
      const double testValue = 5.0;
      double? finalValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Площадь',
                value: testValue,
                onChanged: (value) => finalValue = value,
                minValue: 10.0,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '3.0');
      await tester.pump();

      // Значение должно быть скорректировано до minValue
      expect(finalValue, 10.0);
    });

    testWidgets('enforces maxValue constraint', (tester) async {
      const double testValue = 50.0;
      double? finalValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Площадь',
                value: testValue,
                onChanged: (value) => finalValue = value,
                maxValue: 100.0,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '150.0');
      await tester.pump();

      // Значение должно быть скорректировано до maxValue
      expect(finalValue, 100.0);
    });

    testWidgets('handles empty input as 0', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Значение',
                value: 10.0,
                onChanged: (value) => changedValue = value,
              ),
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();

      expect(changedValue, 0.0);
    });

    testWidgets('respects decimal places setting', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Точность',
                value: 3.14159,
                onChanged: (value) {},
                decimalPlaces: 2,
              ),
            ),
          ),
        ),
      );

      expect(find.text('3.14'), findsOneWidget);
    });

    testWidgets('handles disabled state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Заблокировано',
                value: 5.0,
                onChanged: (value) {},
                enabled: false,
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('applies custom accent color', (tester) async {
      const customColor = Color(0xFFFF5722);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Цветное поле',
                value: 10.0,
                onChanged: (value) {},
                accentColor: customColor,
              ),
            ),
          ),
        ),
      );

      // Виджет должен создаться успешно с кастомным цветом
      expect(find.byType(CalculatorTextField), findsOneWidget);
    });

    testWidgets('has proper textAlignVertical and isDense', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Тест выравнивания',
                value: 10.0,
                onChanged: (value) {},
              ),
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));

      // Проверяем новые UI-исправления
      expect(textField.textAlignVertical, TextAlignVertical.center);
      expect(textField.decoration?.isDense, isTrue);
    });

    testWidgets('text does not overflow with increased textScaleFactor',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
              child: Scaffold(
                body: SizedBox(
                  width: 250,
                  child: CalculatorTextField(
                    label: 'Длинный лейбл для теста',
                    value: 123456.78,
                    onChanged: (value) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Не должно быть overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles invalid input gracefully', (tester) async {
      double? changedValue;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextField(
                label: 'Значение',
                value: 10.0,
                onChanged: (value) => changedValue = value,
              ),
            ),
          ),
        ),
      );

      // Пытаемся ввести невалидный текст (должен быть отфильтрован inputFormatter)
      // При вводе 'abc' inputFormatter фильтрует символы, остаётся пустая строка
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump();

      // Пустая строка обрабатывается как 0.0
      expect(changedValue, 0.0);
    });
  });

  group('CalculatorTextFieldCompact', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CalculatorTextFieldCompact(
                label: 'Компактное',
                value: 5.0,
                onChanged: (value) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Компактное'), findsOneWidget);
      expect(find.text('5.0'), findsOneWidget);
    });
  });

  group('RoomDimensionsFields', () {
    testWidgets('renders all three dimension fields', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RoomDimensionsFields(
                length: 4.0,
                width: 3.0,
                height: 2.7,
                onLengthChanged: (value) {},
                onWidthChanged: (value) {},
                onHeightChanged: (value) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Длина (м)'), findsOneWidget);
      expect(find.text('Ширина (м)'), findsOneWidget);
      expect(find.text('Высота потолка (м)'), findsOneWidget);
      expect(find.byIcon(Icons.straighten), findsNWidgets(2));
      expect(find.byIcon(Icons.height), findsOneWidget);
    });

    testWidgets('calls callbacks on value change', (tester) async {
      double? newLength;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RoomDimensionsFields(
                length: 4.0,
                width: 3.0,
                height: 2.7,
                onLengthChanged: (value) => newLength = value,
                onWidthChanged: (value) {},
                onHeightChanged: (value) {},
              ),
            ),
          ),
        ),
      );

      // Находим поле "Длина (м)" и меняем его значение
      final lengthFields = find.byType(CalculatorTextField);
      await tester.enterText(lengthFields.first, '5.5');
      await tester.pump();

      expect(newLength, 5.5);
    });
  });
}
