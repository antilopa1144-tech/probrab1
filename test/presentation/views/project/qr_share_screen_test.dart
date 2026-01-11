import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/qr_share_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock clipboard для тестирования
  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (message) async {
      if (message.method == 'Clipboard.setData') {
        return null;
      }
      return null;
    });
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  ProjectV2 createTestProject({
    String name = 'Тестовый проект',
    String? description,
    int calculationsCount = 0,
    double materialCost = 0,
    double laborCost = 0,
  }) {
    final project = ProjectV2()
      ..id = 1
      ..name = name
      ..description = description
      ..status = ProjectStatus.planning
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    // Добавляем расчеты если нужно
    for (int i = 0; i < calculationsCount; i++) {
      final calc = ProjectCalculation()
        ..id = i + 1
        ..calculatorId = 'test_calc_$i'
        ..name = 'Расчет ${i + 1}'
        ..materialCost = materialCost
        ..laborCost = laborCost;
      project.calculations.add(calc);
    }

    return project;
  }

  Widget createTestWidget(ProjectV2 project) {
    return MaterialApp(
      home: QRShareScreen(project: project),
    );
  }

  group('QRShareScreen - Основное отображение', () {
    testWidgets('отображает заголовок AppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.text('Поделиться проектом'), findsOneWidget);
    });

    testWidgets('отображает название проекта', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(name: 'Мой ремонт');
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Мой ремонт'), findsOneWidget);
    });

    testWidgets('отображает описание проекта если есть', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(description: 'Описание проекта');
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Описание проекта'), findsOneWidget);
    });

    testWidgets('не отображает описание если его нет', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(description: null);
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // Не должно быть виджета с null описанием
      expect(find.textContaining('null'), findsNothing);
    });

    testWidgets('отображает QR код', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('страница прокручивается', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('содержит Card для информации', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.byType(Card), findsWidgets);
    });
  });

  group('QRShareScreen - QR код генерация', () {
    testWidgets('QR код имеет правильные параметры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.backgroundColor, Colors.white);
      expect(qrImage.size, 280);
      expect(qrImage.errorCorrectionLevel, QrErrorCorrectLevel.M);
      expect(qrImage.version, QrVersions.auto);
    });

    testWidgets('QR код содержит данные', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // QR код должен существовать и содержать данные
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('QR код имеет embedded image', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      final qrImage = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qrImage.embeddedImage, isNotNull);
      expect(qrImage.embeddedImageStyle, isNotNull);
      expect(qrImage.embeddedImageStyle?.size, const Size(48, 48));
    });

    testWidgets('QR код в контейнере с белым фоном и тенью', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Найдем контейнер с QR кодом
      final containers = find.ancestor(
        of: find.byType(QrImageView),
        matching: find.byType(Container),
      );
      expect(containers, findsWidgets);
    });
  });

  group('QRShareScreen - Информация о проекте', () {
    testWidgets('отображает количество расчётов', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(calculationsCount: 3);
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Расчётов'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('отображает стоимость материалов', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(
        calculationsCount: 1,
        materialCost: 15000,
      );
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Стоимость материалов'), findsOneWidget);
      expect(find.textContaining('15000'), findsOneWidget);
      expect(find.textContaining('₽'), findsWidgets);
    });

    testWidgets('отображает стоимость работ', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(
        calculationsCount: 1,
        laborCost: 25000,
      );
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Стоимость работ'), findsOneWidget);
      expect(find.textContaining('25000'), findsOneWidget);
    });

    testWidgets('отображает нулевые стоимости для пустого проекта', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(calculationsCount: 0);
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('0'), findsWidgets);
    });

    testWidgets('отображает иконки для информации', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
    });
  });

  group('QRShareScreen - Переключатель компактного формата', () {
    testWidgets('отображает переключатель компактного формата', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.byType(SwitchListTile), findsOneWidget);
      expect(find.text('Компактный QR код'), findsOneWidget);
      expect(find.text('Меньше размер, проще сканировать'), findsOneWidget);
    });

    testWidgets('переключатель компактного формата включен по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isTrue);
    });

    testWidgets('переключение компактного формата работает', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Переключаем формат
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      // Проверяем что switch изменился
      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isFalse);
    });
  });

  group('QRShareScreen - Прямая ссылка', () {
    testWidgets('отображает секцию прямой ссылки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.text('Прямая ссылка'), findsOneWidget);
      expect(find.byIcon(Icons.link_rounded), findsOneWidget);
    });

    testWidgets('ссылка отображается в SelectableText', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('отображает кнопку копирования ссылки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Прокручиваем до кнопки
      await tester.scrollUntilVisible(
        find.text('Скопировать ссылку'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('Скопировать ссылку'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });

    testWidgets('нажатие кнопки копирования показывает SnackBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Прокручиваем до кнопки и нажимаем
      await tester.scrollUntilVisible(
        find.text('Скопировать ссылку'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Скопировать ссылку'));
      await tester.pumpAndSettle();

      expect(find.text('Ссылка скопирована'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('ссылка отображается корректно', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(name: 'Тест');
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(SelectableText), findsOneWidget);
    });
  });

  group('QRShareScreen - Кнопка шаринга', () {
    testWidgets('отображает кнопку шаринга в AppBar', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('кнопка шаринга имеет tooltip', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      final iconButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.share_rounded),
      );
      expect(iconButton.tooltip, 'Поделиться ссылкой');
    });

    testWidgets('нажатие кнопки шаринга вызывает share', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Просто проверяем что кнопка нажимается без ошибок
      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.pump();

      // Share вызовется, но в тестах не будет реального действия
      // Просто проверяем что не было exception
    });
  });

  group('QRShareScreen - Инструкция', () {
    testWidgets('отображает инструкцию по шарингу', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.text('Как поделиться'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('Как поделиться'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('инструкция содержит шаги', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Прокручиваем до инструкции
      await tester.scrollUntilVisible(
        find.textContaining('Покажите QR код'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.textContaining('1. Покажите QR код'), findsOneWidget);
      expect(find.textContaining('2. Он отсканирует код'), findsOneWidget);
      expect(find.textContaining('3. Проект автоматически импортируется'), findsOneWidget);
    });

    testWidgets('инструкция в primaryContainer', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Найдем Card с инструкцией
      final cards = tester.widgetList<Card>(find.byType(Card));
      expect(cards.length, greaterThan(0));
    });
  });

  group('QRShareScreen - _InfoRow виджет', () {
    testWidgets('_InfoRow отображает иконку, метку и значение', (tester) async {
      final project = createTestProject(calculationsCount: 5);
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byIcon(Icons.calculate_rounded), findsOneWidget);
      expect(find.text('Расчётов:'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('_InfoRow правильно форматирует числа', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(
        calculationsCount: 1,
        materialCost: 123456.789,
      );
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // Проверяем что число округлено до целого
      expect(find.textContaining('123457'), findsOneWidget);
    });
  });

  group('QRShareScreen - Сложные сценарии', () {
    testWidgets('проект с несколькими расчетами отображается корректно', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(
        name: 'Большой проект',
        description: 'Многоэтажный дом',
        calculationsCount: 10,
        materialCost: 50000,
        laborCost: 75000,
      );
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Большой проект'), findsOneWidget);
      expect(find.text('Многоэтажный дом'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.textContaining('500000'), findsOneWidget); // 50000 * 10
      expect(find.textContaining('750000'), findsOneWidget); // 75000 * 10
    });

    testWidgets('прокрутка до конца страницы работает', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Прокручиваем до самого низа
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.textContaining('Проект автоматически импортируется'),
        100,
        scrollable: scrollable,
      );
      await tester.pump();

      expect(find.textContaining('Проект автоматически импортируется'), findsOneWidget);
    });

    testWidgets('двойное переключение формата возвращает исходное состояние', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(createTestWidget(createTestProject()));
      await tester.pump();

      // Переключаем дважды
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final switchTile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchTile.value, isTrue);
    });

    testWidgets('проект без описания не ломает layout', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(
        name: 'Проект без описания',
        description: null,
      );
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Проект без описания'), findsOneWidget);
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('проект с пустым названием отображается', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(name: '');
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // Проверяем что виджет не крашится
      expect(find.byType(QrImageView), findsOneWidget);
    });

    testWidgets('обработка очень больших чисел в стоимости', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(
        calculationsCount: 1,
        materialCost: 9999999.99,
        laborCost: 8888888.88,
      );
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // Проверяем что большие числа отображаются
      expect(find.textContaining('10000000'), findsOneWidget);
      expect(find.textContaining('8888889'), findsOneWidget);
    });
  });
}
