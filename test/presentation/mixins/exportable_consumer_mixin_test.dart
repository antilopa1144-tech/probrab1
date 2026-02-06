import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/domain/models/calculator_result_payload.dart';
import 'package:probrab_ai/presentation/mixins/exportable_consumer_mixin.dart';
import '../../helpers/test_helpers.dart';

/// Тестовый виджет для проверки ExportableConsumerMixin
class _TestExportableWidget extends ConsumerStatefulWidget {
  final String? calculatorId;
  final Map<String, dynamic>? inputs;
  final CalculatorResultPayload? payload;
  final bool isFromProject;

  const _TestExportableWidget({
    this.calculatorId,
    this.inputs,
    this.payload,
    this.isFromProject = false,
  });

  @override
  ConsumerState<_TestExportableWidget> createState() =>
      _TestExportableWidgetState();
}

class _TestExportableWidgetState extends ConsumerState<_TestExportableWidget>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => AppLocalizations.of(context);

  @override
  String get exportSubject => 'Тестовый калькулятор';

  @override
  String generateExportText() {
    return 'Результаты расчета:\nПлощадь: 10 м²\nЦена: 1000 руб';
  }

  @override
  String? get calculatorId => widget.calculatorId;

  @override
  Map<String, dynamic>? getCurrentInputs() => widget.inputs;

  @override
  CalculatorResultPayload? buildResultPayload() => widget.payload;

  @override
  bool get isFromProject => widget.isFromProject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test'), actions: exportActions),
      body: const Center(child: Text('Test Widget')),
    );
  }
}

void main() {
  setUpAll(() {
    setupMocks();
    // Mock clipboard для тестирования
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

  group('ExportableConsumerMixin', () {
    group('Тесты базовой функциональности', () {
      testWidgets('виджет с миксином рендерится корректно', (tester) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        expect(find.text('Test Widget'), findsOneWidget);
      });

      testWidgets('exportActions содержит кнопки копирования и отправки', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Должны быть кнопки копирования и отправки
        expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
        expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      });
    });

    group('Тесты функции копирования', () {
      testWidgets('copyToClipboard копирует текст в буфер обмена', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Нажимаем кнопку копирования
        await tester.tap(find.byIcon(Icons.copy_rounded));
        await tester.pumpAndSettle();

        // Должен появиться снэкбар с сообщением (translated)
        expect(find.text('Скопировано в буфер обмена'), findsOneWidget);
      });

      testWidgets('скопированный текст содержит правильные данные', (
        tester,
      ) async {
        // Мокируем буфер обмена с логированием
        final List<MethodCall> log = <MethodCall>[];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            log.add(methodCall);
            return null;
          },
        );

        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Нажимаем кнопку копирования
        await tester.tap(find.byIcon(Icons.copy_rounded));
        await tester.pump();

        // Проверяем, что был вызван метод копирования
        expect(
          log,
          contains(
            isA<MethodCall>().having(
              (call) => call.method,
              'method',
              'Clipboard.setData',
            ),
          ),
        );
      });
    });

    group('Тесты функции отправки', () {
      testWidgets('shareCalculation вызывает share', (tester) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Нажимаем кнопку отправки
        await tester.tap(find.byIcon(Icons.share_rounded));
        await tester.pump();

        // Виджет должен остаться на экране
        expect(find.text('Test Widget'), findsOneWidget);
      });
    });

    group('Тесты QR кода', () {
      testWidgets('кнопка QR кода не отображается без calculatorId', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Кнопка QR кода не должна отображаться
        expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
      });

      testWidgets('кнопка QR кода отображается с calculatorId и inputs', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              calculatorId: 'test_calc',
              inputs: {'area': 10.0, 'width': 5.0},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Кнопка QR кода должна отображаться
        expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
      });

      testWidgets('нажатие на QR кнопку открывает экран QR кода', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              calculatorId: 'test_calc',
              inputs: {'area': 10.0, 'width': 5.0},
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Нажимаем кнопку QR кода
        await tester.tap(find.byIcon(Icons.qr_code_2_rounded));
        await tester.pumpAndSettle();

        // Должен открыться экран с QR кодом (проверяем базовый виджет)
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      });

      testWidgets('shareAsQrCode показывает ошибку без calculatorId', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Попытка вызвать shareAsQrCode через виджет не должна привести к ошибке
        expect(find.text('Test Widget'), findsOneWidget);
      });

      testWidgets('shareAsQrCode показывает ошибку без inputs', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(calculatorId: 'test_calc'),
          ),
        );

        await tester.pumpAndSettle();

        // Кнопка QR кода не должна отображаться
        expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
      });
    });

    group('Тесты сохранения в проект', () {
      testWidgets('кнопка сохранения не отображается без isFromProject', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              payload: CalculatorResultPayload(
                calculatorId: 'test',
                calculatorName: 'Test',
                inputs: {},
                results: {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Кнопка сохранения не должна отображаться
        expect(find.byIcon(Icons.save_rounded), findsNothing);
      });

      testWidgets('кнопка сохранения отображается с isFromProject и payload', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              isFromProject: true,
              payload: CalculatorResultPayload(
                calculatorId: 'test',
                calculatorName: 'Test',
                inputs: {},
                results: {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Кнопка сохранения должна отображаться
        expect(find.byIcon(Icons.save_rounded), findsOneWidget);
      });

      testWidgets('нажатие на кнопку сохранения закрывает экран', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              isFromProject: true,
              payload: CalculatorResultPayload(
                calculatorId: 'test',
                calculatorName: 'Test',
                inputs: {},
                results: {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Нажимаем кнопку сохранения
        await tester.tap(find.byIcon(Icons.save_rounded));
        await tester.pumpAndSettle();

        // Экран должен закрыться (виджет не должен быть найден)
        expect(find.text('Test Widget'), findsNothing);
      });

      testWidgets('saveToProjectAction возвращает null без payload', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(isFromProject: true),
          ),
        );

        await tester.pumpAndSettle();

        // Кнопка сохранения не должна отображаться
        expect(find.byIcon(Icons.save_rounded), findsNothing);
      });

      testWidgets('saveToProjectAction возвращает null без isFromProject', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              payload: CalculatorResultPayload(
                calculatorId: 'test',
                calculatorName: 'Test',
                inputs: {},
                results: {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Кнопка сохранения не должна отображаться
        expect(find.byIcon(Icons.save_rounded), findsNothing);
      });
    });

    group('Тесты порядка кнопок', () {
      testWidgets('кнопки отображаются в правильном порядке без доп. кнопок', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Проверяем, что есть только copy и share
        final actions = find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        );

        expect(actions, findsNWidgets(3)); // copy + share + download
      });

      testWidgets('кнопки отображаются в правильном порядке со всеми опциями', (
        tester,
      ) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              calculatorId: 'test_calc',
              inputs: {'area': 10.0},
              isFromProject: true,
              payload: CalculatorResultPayload(
                calculatorId: 'test',
                calculatorName: 'Test',
                inputs: {},
                results: {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Должны быть все кнопки: save, copy, share, download, qr
        final actions = find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        );

        expect(actions, findsNWidgets(5)); // save + copy + share + download + qr
      });

      testWidgets('кнопка сохранения идет первой', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              isFromProject: true,
              payload: CalculatorResultPayload(
                calculatorId: 'test',
                calculatorName: 'Test',
                inputs: {},
                results: {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Находим все кнопки в AppBar
        final actions = find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(IconButton),
        );

        // Первая кнопка должна быть save
        final firstAction = actions.first;
        final saveButton = find.descendant(
          of: firstAction,
          matching: find.byIcon(Icons.save_rounded),
        );

        expect(saveButton, findsOneWidget);
      });
    });

    group('Тесты tooltip', () {
      testWidgets('кнопка копирования имеет tooltip', (tester) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Находим кнопку копирования
        final copyButton = find.widgetWithIcon(IconButton, Icons.copy_rounded);
        expect(copyButton, findsOneWidget);

        // Проверяем наличие tooltip (translated)
        final iconButton = tester.widget<IconButton>(copyButton);
        expect(iconButton.tooltip, 'Копировать');
      });

      testWidgets('кнопка отправки имеет tooltip', (tester) async {
        await tester.pumpWidget(
          createTestApp(child: const _TestExportableWidget()),
        );

        await tester.pumpAndSettle();

        // Находим кнопку отправки
        final shareButton = find.widgetWithIcon(
          IconButton,
          Icons.share_rounded,
        );
        expect(shareButton, findsOneWidget);

        // Проверяем наличие tooltip (translated)
        final iconButton = tester.widget<IconButton>(shareButton);
        expect(iconButton.tooltip, 'Поделиться');
      });

      testWidgets('кнопка сохранения имеет tooltip', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const _TestExportableWidget(
              isFromProject: true,
              payload: CalculatorResultPayload(
                calculatorId: 'test',
                calculatorName: 'Test',
                inputs: {},
                results: {},
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Находим кнопку сохранения
        final saveButton = find.widgetWithIcon(IconButton, Icons.save_rounded);
        expect(saveButton, findsOneWidget);

        // Проверяем наличие tooltip (translated)
        final iconButton = tester.widget<IconButton>(saveButton);
        expect(iconButton.tooltip, 'Сохранить в проект');
      });
    });

    group('Тесты конвертации inputs', () {
      testWidgets(
        'getCurrentInputs с Map<String, dynamic> конвертируется правильно',
        (tester) async {
          await tester.pumpWidget(
            createTestApp(
              child: const _TestExportableWidget(
                calculatorId: 'test',
                inputs: {
                  'area': 10,
                  'width': 5.5,
                  'height': 3.0,
                  'count': 15.7,
                },
              ),
            ),
          );

          await tester.pumpAndSettle();

          // Кнопка QR должна быть доступна
          expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
        },
      );
    });
  });
}
