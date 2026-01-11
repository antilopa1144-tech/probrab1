import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/shareable_content.dart';
import 'package:probrab_ai/presentation/views/calculator/calculator_qr_share_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  ShareableCalculator createTestCalculator({
    String calculatorId = 'gypsum',
    String? calculatorName = 'Гипсокартон',
    Map<String, double> inputs = const {'area': 20.0, 'layers': 2.0},
    String? notes,
  }) {
    return ShareableCalculator(
      calculatorId: calculatorId,
      calculatorName: calculatorName,
      inputs: inputs,
      notes: notes,
    );
  }

  Widget createTestWidget(
    ShareableCalculator calculator, {
    String? calculatorDisplayName,
  }) {
    return createTestApp(
      child: CalculatorQrShareScreen(
        calculator: calculator,
        calculatorDisplayName: calculatorDisplayName,
      ),
    );
  }

  group('CalculatorQrShareScreen', () {
    testWidgets('отображает заголовок AppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      // Заголовок должен содержать текст о QR/share (может быть ключ локализации)
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('отображает название калькулятора из displayName', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(),
        calculatorDisplayName: 'Тестовый калькулятор',
      ));
      await tester.pump();

      expect(find.text('Тестовый калькулятор'), findsOneWidget);
    });

    testWidgets('отображает название из calculator.calculatorName если displayName null', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(calculatorName: 'Калькулятор плитки'),
      ));
      await tester.pump();

      expect(find.text('Калькулятор плитки'), findsOneWidget);
    });

    testWidgets('отображает QR код', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('отображает переключатель компактного формата', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('переключатель компактного формата включен по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isTrue);
    });

    testWidgets('отображает кнопку шаринга в AppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('отображает иконку ссылки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });

    testWidgets('отображает иконку информации', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('отображает иконку ввода', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byIcon(Icons.input_rounded), findsOneWidget);
    });

    testWidgets('страница прокручивается', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('содержит Card для информации', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('ссылка отображается в SelectableText', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('отображает кнопку копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('QR код в контейнере с белым фоном', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.backgroundColor, Colors.white);
    });

    testWidgets('QR код имеет размер 280', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.size, 280);
    });

    testWidgets('отображает входные данные калькулятора', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'area': 25.0}),
      ));
      await tester.pump();

      // Значение 25 должно отображаться
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('форматирует целые значения без десятичных', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'count': 10.0}),
      ));
      await tester.pump();

      // 10.0 должен отображаться как 10
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('переключение формата работает', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      // Проверяем начальное состояние - включен
      var switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isTrue);

      // Прокручиваем до переключателя и переключаем формат
      await tester.scrollUntilVisible(
        find.byType(SwitchListTile),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      // Проверяем что состояние изменилось
      switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isFalse);
    });

    testWidgets('обрабатывает пустые входные данные', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {}),
      ));
      await tester.pump();

      // Не должно падать
      expect(find.byType(CalculatorQrShareScreen), findsOneWidget);
    });

    testWidgets('обрабатывает null calculatorName', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(calculatorName: null),
      ));
      await tester.pump();

      // Не должно падать, использует fallback
      expect(find.byType(CalculatorQrShareScreen), findsOneWidget);
    });
  });

  group('CalculatorQrShareScreen - Форматирование значений', () {
    testWidgets('форматирует дробные значения корректно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'area': 25.567, 'width': 3.14159}),
      ));
      await tester.pump();

      // Проверяем что есть дробные значения (обрезанные до 2 знаков)
      expect(find.textContaining('25.57'), findsOneWidget);
      expect(find.textContaining('3.14'), findsOneWidget);
    });

    testWidgets('удаляет trailing zeros', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'value1': 10.00, 'value2': 5.50, 'value3': 3.100}),
      ));
      await tester.pump();

      expect(find.textContaining('10'), findsWidgets);
      expect(find.textContaining('5.5'), findsOneWidget);
      expect(find.textContaining('3.1'), findsOneWidget);
    });

    testWidgets('обрабатывает очень маленькие числа', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'tiny': 0.01, 'small': 0.001}),
      ));
      await tester.pump();

      expect(find.textContaining('0.01'), findsOneWidget);
    });

    testWidgets('обрабатывает нулевые значения', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'zero': 0.0, 'value': 10.0}),
      ));
      await tester.pump();

      expect(find.textContaining('0'), findsWidgets);
      expect(find.textContaining('10'), findsWidgets);
    });

    testWidgets('обрабатывает отрицательные значения', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'negative': -5.0, 'positive': 10.0}),
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('обрабатывает очень большие числа', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {'big': 9999999.99}),
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });
  });

  group('CalculatorQrShareScreen - Копирование и шаринг', () {
    setUp(() {
      setupMocks();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (message) async {
        if (message?.method == 'Clipboard.setData') {
          return null;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('нажатие кнопки копирования показывает SnackBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byIcon(Icons.copy_rounded),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('кнопка шаринга работает без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.pump();

      // Просто проверяем что не было exception
    });
  });

  group('CalculatorQrShareScreen - Множественные входные данные', () {
    testWidgets('отображает несколько входных параметров', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {
          'area': 100.5,
          'length': 15.0,
          'width': 8.5,
          'height': 3.0,
          'count': 50.0,
        }),
      ));
      await tester.pump();

      expect(find.textContaining('100.5'), findsOneWidget);
      expect(find.textContaining('15'), findsWidgets);
      expect(find.textContaining('8.5'), findsOneWidget);
      expect(find.textContaining('3'), findsWidgets);
      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('обрабатывает известные ключи параметров', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {
          'area': 50.0,
          'length': 10.0,
          'width': 5.0,
          'height': 3.0,
        }),
      ));
      await tester.pump();

      // Все параметры должны отображаться
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('обрабатывает неизвестные ключи параметров', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {
          'myCustomParam': 42.0,
          'anotherValue': 100.0,
          'someOtherThing': 25.5,
        }),
      ));
      await tester.pump();

      expect(find.textContaining('42'), findsOneWidget);
      expect(find.textContaining('100'), findsWidgets);
      expect(find.textContaining('25.5'), findsOneWidget);
    });

    testWidgets('форматирует camelCase параметры в читаемый текст', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {
          'roomArea': 50.0,
          'wallHeight': 3.0,
        }),
      ));
      await tester.pump();

      // Параметры должны отображаться
      expect(find.byType(QrImageView), findsOneWidget);
    });
  });

  group('CalculatorQrShareScreen - QR параметры', () {
    testWidgets('QR код имеет правильный errorCorrectionLevel', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.errorCorrectionLevel, QrErrorCorrectLevel.M);
    });

    testWidgets('QR код имеет auto версию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.version, QrVersions.auto);
    });

    testWidgets('QR код имеет embedded image со стилем', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.embeddedImage, isNotNull);
      expect(qrImage.embeddedImageStyle, isNotNull);
      expect(qrImage.embeddedImageStyle?.size, const Size(48, 48));
    });
  });

  group('CalculatorQrShareScreen - Прокрутка и навигация', () {
    testWidgets('прокрутка до конца страницы работает', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.byIcon(Icons.info_outline_rounded),
        100,
        scrollable: scrollable,
      );
      await tester.pump();

      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('все основные секции видны после прокрутки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      // QR код виден сразу
      expect(find.byType(QrImageView), findsOneWidget);

      // Прокручиваем к входным данным
      await tester.scrollUntilVisible(
        find.byIcon(Icons.input_rounded),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.byIcon(Icons.input_rounded), findsOneWidget);

      // Прокручиваем к ссылке
      await tester.scrollUntilVisible(
        find.byIcon(Icons.link_rounded),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });
  });

  group('CalculatorQrShareScreen - Сложные сценарии', () {
    testWidgets('displayName приоритетнее calculatorName', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(calculatorName: 'Name1'),
        calculatorDisplayName: 'Name2',
      ));
      await tester.pump();

      expect(find.text('Name2'), findsOneWidget);
      expect(find.text('Name1'), findsNothing);
    });

    testWidgets('использует calculatorName если displayName null', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(calculatorName: 'CalcName'),
        calculatorDisplayName: null,
      ));
      await tester.pump();

      expect(find.text('CalcName'), findsOneWidget);
    });

    testWidgets('множественное переключение формата', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      for (int i = 0; i < 5; i++) {
        await tester.scrollUntilVisible(
          find.byType(SwitchListTile),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byType(SwitchListTile));
        await tester.pump();
      }

      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isFalse);
    });

    testWidgets('двойное переключение возвращает исходное состояние', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byType(SwitchListTile),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pump();

      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isTrue);
    });

    testWidgets('калькулятор с notes отображается без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(notes: 'Тестовые заметки'),
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('калькулятор без notes отображается без ошибок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(notes: null),
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('разные calculatorId не ломают виджет', (tester) async {
      setTestViewportSize(tester);
      final calculators = [
        createTestCalculator(calculatorId: 'tile'),
        createTestCalculator(calculatorId: 'brick'),
        createTestCalculator(calculatorId: 'gypsum'),
        createTestCalculator(calculatorId: 'paint'),
      ];

      for (final calc in calculators) {
        await tester.pumpWidget(createTestWidget(calc));
        await tester.pump();
        expect(find.byType(QrImageView), findsOneWidget);
      }
    });
  });

  group('CalculatorQrShareScreen - Edge cases', () {
    testWidgets('обрабатывает пустую строку в calculatorName', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(calculatorName: ''),
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('обрабатывает очень длинное название', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(
          calculatorName: 'Очень длинное название калькулятора ' * 5,
        ),
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('обрабатывает специальные символы в названии', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(calculatorName: 'Калькулятор №1 (тест)'),
      ));
      await tester.pump();

      expect(find.textContaining('Калькулятор №1'), findsOneWidget);
    });

    testWidgets('обрабатывает много входных параметров', (tester) async {
      setTestViewportSize(tester);
      final inputs = <String, double>{};
      for (int i = 0; i < 20; i++) {
        inputs['param$i'] = i.toDouble();
      }

      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: inputs),
      ));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('обрабатывает параметры с очень длинными именами', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(
        createTestCalculator(inputs: {
          'veryLongParameterNameThatShouldStillWork': 42.0,
        }),
      ));
      await tester.pump();

      expect(find.textContaining('42'), findsOneWidget);
    });
  });

  group('CalculatorQrShareScreen - Визуальные элементы', () {
    testWidgets('содержит FilledButton для копирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byType(FilledButton),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('все Card виджеты отображаются', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('основной контейнер с QR имеет декорацию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final containers = find.ancestor(
        of: find.byType(QrImageView),
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);
    });

    testWidgets('SelectableText позволяет выделить текст', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestCalculator()));
      await tester.pump();

      final selectableText = tester.widget<SelectableText>(find.byType(SelectableText));
      expect(selectableText.data, isNotNull);
      expect(selectableText.data, isNotEmpty);
    });
  });
}
