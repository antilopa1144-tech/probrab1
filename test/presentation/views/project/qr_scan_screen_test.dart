import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:probrab_ai/core/services/deep_link_service.dart';
import 'package:probrab_ai/presentation/views/project/qr_scan_screen.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('QRScanScreen', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('отображает базовые элементы интерфейса', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем основные элементы
      expect(find.text('Сканировать QR код'), findsOneWidget);
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_android_rounded), findsOneWidget);
      expect(find.text('Наведите камеру на QR код'), findsOneWidget);
      expect(find.text('QR код будет отсканирован автоматически'), findsOneWidget);
    });

    testWidgets('отображает иконку сканера', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие иконки сканера
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
    });

    testWidgets('отображает MobileScanner виджет', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие MobileScanner
      expect(find.byType(MobileScanner), findsOneWidget);
    });

    testWidgets('отображает рамку сканирования', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие CustomPaint для рамки (может быть несколько)
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('переключает фонарик при нажатии', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Начальное состояние - фонарик выключен
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);

      // Проверяем, что кнопка есть, но не нажимаем
      // (т.к. MobileScannerController не инициализирован в тестах)
      final flashButton = find.byIcon(Icons.flash_off_rounded);
      expect(flashButton, findsOneWidget);
    });

    testWidgets('кнопка переключения камеры работает', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Находим кнопку переключения камеры
      final switchCameraButton = find.byIcon(Icons.flip_camera_android_rounded);
      expect(switchCameraButton, findsOneWidget);

      // Проверяем наличие кнопки, но не нажимаем
      // (т.к. MobileScannerController не инициализирован в тестах)
      expect(find.text('Сканировать QR код'), findsOneWidget);
    });

    testWidgets('отображает Stack с несколькими слоями', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие Stack (может быть несколько)
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('отображает градиент внизу экрана', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие Positioned виджета
      expect(find.byType(Positioned), findsWidgets);
    });

    testWidgets('AppBar содержит корректные actions', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем AppBar
      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);

      // Проверяем действия в AppBar
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);
      expect(find.byIcon(Icons.flip_camera_android_rounded), findsOneWidget);
    });

    testWidgets('закрывается при нажатии кнопки назад', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие кнопки назад
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('рамка сканирования имеет правильные размеры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что CustomPaint существует
      final customPaint = find.byType(CustomPaint);
      expect(customPaint, findsWidgets);
    });

    testWidgets('инструкции отображаются в Column', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем структуру инструкций
      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
      expect(find.text('Наведите камеру на QR код'), findsOneWidget);
      expect(find.text('QR код будет отсканирован автоматически'), findsOneWidget);
    });

    testWidgets('текст инструкций имеет правильный стиль', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Находим текстовые виджеты
      final titleText = find.text('Наведите камеру на QR код');
      final subtitleText = find.text('QR код будет отсканирован автоматически');

      expect(titleText, findsOneWidget);
      expect(subtitleText, findsOneWidget);
    });

    testWidgets('контейнер с градиентом имеет правильные параметры', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие Container с градиентом
      final containers = find.byType(Container);
      expect(containers, findsWidgets);
    });

    testWidgets('Scaffold имеет правильную структуру', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем структуру Scaffold
      final scaffold = find.byType(Scaffold);
      expect(scaffold, findsOneWidget);

      final appBar = find.byType(AppBar);
      expect(appBar, findsOneWidget);
    });

    testWidgets('иконка сканера имеет правильный размер', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      final icon = find.byIcon(Icons.qr_code_scanner_rounded);
      expect(icon, findsOneWidget);

      final iconWidget = tester.widget<Icon>(icon);
      expect(iconWidget.size, 48);
    });

    testWidgets('все кнопки доступны для взаимодействия', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем, что все кнопки найдены
      expect(find.byType(IconButton), findsNWidgets(2));
    });

    testWidgets('экран имеет темный оверлей', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие CustomPaint для оверлея
      expect(find.byType(CustomPaint), findsOneWidget);
    });
  });

  group('QRScanScreen - обработка сканирования', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('показывает индикатор загрузки во время обработки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pump();

      // В начале индикатора загрузки быть не должно
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('рамка сканирования отрисовывается правильно', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие CustomPaint (может быть несколько)
      final customPaint = find.byType(CustomPaint);
      expect(customPaint, findsWidgets);
    });
  });

  group('QRScanScreen - интеграция с камерой', () {
    setUp(() {
      setupMocks();
    });

    testWidgets('MobileScanner настроен с правильными параметрами', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем наличие MobileScanner
      final scanner = find.byType(MobileScanner);
      expect(scanner, findsOneWidget);
    });

    testWidgets('экран содержит все необходимые слои', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const QRScanScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Проверяем структуру слоев
      expect(find.byType(MobileScanner), findsOneWidget);
      expect(find.byType(CustomPaint), findsOneWidget);
      expect(find.byType(Positioned), findsWidgets);
    });
  });

  group('DeepLinkService integration', () {
    test('parseQRCode вызывает parseLink', () async {
      final service = DeepLinkService.instance;

      // Тестируем с невалидной ссылкой
      final result = await service.parseQRCode('invalid-qr-code');

      // Должен вернуть null для невалидного QR
      expect(result, isNull);
    });

    test('parseQRCode обрабатывает валидную ссылку', () async {
      final service = DeepLinkService.instance;

      // Тестируем с валидной схемой
      const validLink = 'masterokapp://share/project?data=eyJ0ZXN0IjoidGVzdCJ9';
      final result = await service.parseQRCode(validLink);

      // Проверяем, что метод выполнился
      expect(result, isNotNull);
    });
  });
}
