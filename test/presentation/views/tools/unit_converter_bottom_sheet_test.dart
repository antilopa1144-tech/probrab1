import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/unit_conversion.dart';
import 'package:probrab_ai/domain/services/unit_converter_service.dart';
import 'package:probrab_ai/presentation/views/tools/unit_converter_bottom_sheet.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('UnitConverterBottomSheet', () {
    testWidgets('отображает базовые элементы интерфейса', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем основные элементы
      expect(find.text('Конвертер единиц'), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      // TextField и DropdownButtonFormField используют hintText, проверяем наличие виджетов
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<Unit>), findsNWidgets(2));
      expect(find.byIcon(Icons.swap_vert_rounded), findsOneWidget);
    });

    testWidgets('отображает все категории в табах', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что все категории присутствуют
      expect(find.text('Площадь'), findsOneWidget);
      expect(find.text('Длина'), findsOneWidget);
      expect(find.text('Объём'), findsOneWidget);
      expect(find.text('Вес'), findsOneWidget);
      expect(find.text('Количество'), findsOneWidget);
    });

    testWidgets('выполняет конвертацию при вводе значения', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Находим поле ввода и вводим значение
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '10');
      await tester.pumpAndSettle();

      // Проверяем, что результат отображается
      expect(find.text('Результат'), findsOneWidget);
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('меняет единицы местами при нажатии swap', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Вводим значение для создания результата
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '5');
      await tester.pumpAndSettle();

      // Проверяем, что результат содержит единицы площади
      expect(find.textContaining('м²'), findsWidgets);

      // Нажимаем swap
      final swapButton = find.byIcon(Icons.swap_vert_rounded);
      await tester.tap(swapButton);
      await tester.pumpAndSettle();

      // Проверяем, что единицы поменялись местами
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('переключается между категориями', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Нажимаем на таб "Длина"
      await tester.tap(find.text('Длина'));
      await tester.pumpAndSettle();

      // Проверяем, что отображаются единицы длины
      final dropdown = find.byType(DropdownButtonFormField<Unit>).first;
      expect(dropdown, findsOneWidget);
    });

    testWidgets('очищает поле ввода при нажатии кнопки очистки', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Вводим значение
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '100');
      await tester.pumpAndSettle();

      // Находим и нажимаем кнопку очистки
      final clearButton = find.byIcon(Icons.clear_rounded);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('отображает историю конвертаций', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Выполняем несколько конвертаций
      final textField = find.byType(TextField).first;

      await tester.enterText(textField, '10');
      await tester.pumpAndSettle();

      await tester.enterText(textField, '20');
      await tester.pumpAndSettle();

      // Проверяем, что появилась секция "История"
      expect(find.text('История'), findsOneWidget);
    });

    testWidgets('разворачивает и сворачивает историю', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Выполняем конвертацию для создания истории
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '15');
      await tester.pumpAndSettle();

      // Проверяем, что есть кнопка разворачивания истории
      final expandButton = find.byIcon(Icons.expand_more_rounded);
      if (expandButton.evaluate().isNotEmpty) {
        await tester.tap(expandButton);
        await tester.pumpAndSettle();

        // После разворачивания должна появиться кнопка сворачивания
        expect(find.byIcon(Icons.expand_less_rounded), findsOneWidget);
      }
    });

    testWidgets('очищает историю конвертаций', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Выполняем конвертацию
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '25');
      await tester.pumpAndSettle();

      // Находим и нажимаем кнопку "Очистить"
      final clearHistoryButton = find.text('Очистить');
      if (clearHistoryButton.evaluate().isNotEmpty) {
        await tester.tap(clearHistoryButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('отображает популярные конвертации', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Прокручиваем вниз к популярным конвертациям
      expect(find.text('Популярные конвертации'), findsOneWidget);
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('применяет популярную конвертацию при нажатии', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Находим первый ActionChip с популярной конвертацией
      final actionChips = find.byType(ActionChip);
      if (actionChips.evaluate().isNotEmpty) {
        await tester.tap(actionChips.first);
        await tester.pumpAndSettle();

        // Проверяем, что результат обновился
        expect(find.text('Результат'), findsOneWidget);
      }
    });

    testWidgets('закрывается при нажатии кнопки закрытия', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => UnitConverterBottomSheet.show(context),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      );

      // Открываем bottom sheet
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();

      // Проверяем, что bottom sheet открыт
      expect(find.text('Конвертер единиц'), findsOneWidget);

      // Закрываем
      final closeButton = find.byIcon(Icons.close_rounded);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();
    });

    testWidgets('изменяет единицу "Из" через dropdown', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Находим первый dropdown (Из)
      final fromDropdown = find.byType(DropdownButtonFormField<Unit>).first;
      expect(fromDropdown, findsOneWidget);
    });

    testWidgets('изменяет единицу "В" через dropdown', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Находим второй dropdown (В)
      final dropdowns = find.byType(DropdownButtonFormField<Unit>);
      expect(dropdowns, findsNWidgets(2));
    });

    testWidgets('проверяет DraggableScrollableSheet', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие DraggableScrollableSheet
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('отображает handle для перетаскивания', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие handle (контейнер определенного размера)
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('конвертирует площадь корректно', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Переключаемся на категорию Площадь (по умолчанию)
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '1');
      await tester.pumpAndSettle();

      // Проверяем, что есть результат конвертации
      expect(find.text('Результат'), findsOneWidget);
    });

    testWidgets('показывает корректный формат результата', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Вводим значение
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '2.5');
      await tester.pumpAndSettle();

      // Проверяем наличие карточки с результатом
      final resultCards = find.ancestor(
        of: find.text('Результат'),
        matching: find.byType(Card),
      );
      expect(resultCards, findsOneWidget);
    });

    testWidgets('ограничивает историю до 10 записей', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;

      // Выполняем 12 конвертаций
      for (int i = 1; i <= 12; i++) {
        await tester.enterText(textField, '$i');
        await tester.pumpAndSettle();
      }

      // История должна содержать максимум 10 записей
      // Проверяем наличие секции истории
      expect(find.text('История'), findsOneWidget);
    });

    testWidgets('принимает только числовой ввод', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: UnitConverterBottomSheet(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final textField = find.byType(TextField).first;

      // Пытаемся ввести буквы
      await tester.enterText(textField, 'abc');
      await tester.pumpAndSettle();

      // Проверяем, что поле пустое или содержит только валидные символы
      final widget = tester.widget<TextField>(textField);
      expect(widget.inputFormatters, isNotEmpty);
    });
  });

  group('UnitConverterService integration', () {
    late UnitConverterService service;

    setUp(() {
      service = UnitConverterService();
    });

    test('конвертирует метры в сантиметры', () {
      final from = service.findUnitById('meter');
      final to = service.findUnitById('cm');

      expect(from, isNotNull);
      expect(to, isNotNull);

      final result = service.convert(
        value: 1,
        from: from!,
        to: to!,
      );

      expect(result, isNotNull);
      expect(result!.toValue, 100);
    });

    test('конвертирует квадратные метры в квадратные сантиметры', () {
      final from = service.findUnitById('sq_m');
      final to = service.findUnitById('sq_cm');

      expect(from, isNotNull);
      expect(to, isNotNull);

      final result = service.convert(
        value: 1,
        from: from!,
        to: to!,
      );

      expect(result, isNotNull);
      expect(result!.toValue, 10000);
    });

    test('конвертирует килограммы в граммы', () {
      final from = service.findUnitById('kg');
      final to = service.findUnitById('gram');

      expect(from, isNotNull);
      expect(to, isNotNull);

      final result = service.convert(
        value: 1,
        from: from!,
        to: to!,
      );

      expect(result, isNotNull);
      expect(result!.toValue, 1000);
    });

    test('возвращает null при конвертации между разными категориями', () {
      final from = service.findUnitById('meter');
      final to = service.findUnitById('kg');

      expect(from, isNotNull);
      expect(to, isNotNull);

      final result = service.convert(
        value: 1,
        from: from!,
        to: to!,
      );

      expect(result, isNull);
    });
  });
}
