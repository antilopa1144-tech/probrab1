import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/calculator_share_button.dart';
import 'package:probrab_ai/presentation/widgets/common/share_options_dialog.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('CalculatorShareButton Tests', () {
    String generateTestText() => 'Результат расчёта:\nПлощадь: 100 м²\nМатериалы: 500 кг';

    testWidgets('должен отображать IconButton по умолчанию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('должен отображать FilledButton когда asIconButton = false',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              asIconButton: false,
              label: 'Поделиться результатом',
            ),
          ),
        ),
      );

      // Check for button text and icon
      expect(find.text('Поделиться результатом'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('должен использовать кастомную иконку', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              icon: Icons.send,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('должен показывать tooltip', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              tooltip: 'Экспортировать результат',
            ),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Экспортировать результат');
    });

    testWidgets('должен открывать ShareOptionsDialog при нажатии',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byType(ShareOptionsDialog), findsOneWidget);
      expect(find.text('Поделиться результатом'), findsOneWidget);
    });

    testWidgets('должен показывать QR опцию когда generateQrData предоставлен',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              generateQrData: () => 'qr-data-here',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('QR код'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    });

    testWidgets('не должен показывать QR опцию без generateQrData',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.text('QR код'), findsNothing);
    });

    testWidgets('должен копировать в буфер обмена при выборе Copy',
        (tester) async {
      // Setup test clipboard
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(
        log,
        contains(isA<MethodCall>().having(
          (call) => call.method,
          'method',
          'Clipboard.setData',
        )),
      );

      expect(find.text('Скопировано в буфер обмена'), findsOneWidget);
    });

    testWidgets('должен вызывать onCopied callback', (tester) async {
      var copyCallbackCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              onCopied: () {
                copyCallbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(copyCallbackCalled, true);
    });

    testWidgets('должен вызывать onShared callback при шаринге',
        (tester) async {
      var shareCallbackCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              onShared: () {
                shareCallbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Поделиться'));
      await tester.pumpAndSettle();

      expect(shareCallbackCalled, true);
    });

    testWidgets('должен вызывать onQrOpened callback при открытии QR',
        (tester) async {
      var qrCallbackCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              generateQrData: () => 'test-qr-data',
              onQrOpened: () {
                qrCallbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('QR код'));
      await tester.pumpAndSettle();

      expect(qrCallbackCalled, true);
    });

    testWidgets('должен показывать QR диалог при выборе QR опции',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              generateQrData: () => 'test-qr-data',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('QR код'));
      await tester.pumpAndSettle();

      expect(find.text('QR код расчёта'), findsOneWidget);
      expect(find.text('Отсканируйте QR код для импорта данных'), findsOneWidget);
    });

    testWidgets('должен показывать предупреждение если QR данные пустые',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              generateQrData: () => '',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('QR код'));
      await tester.pumpAndSettle();

      expect(
        find.text('QR код недоступен для текущих данных'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('должен показывать предупреждение если QR данные null',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              generateQrData: () => null,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('QR код'));
      await tester.pumpAndSettle();

      expect(
        find.text('QR код недоступен для текущих данных'),
        findsOneWidget,
      );
    });

    testWidgets('должен закрывать диалог при отмене', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(find.byType(ShareOptionsDialog), findsOneWidget);

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(find.byType(ShareOptionsDialog), findsNothing);
    });

    testWidgets('должен использовать subject при шаринге', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorShareButton(
              generateExportText: generateTestText,
              subject: 'Результаты расчёта калькулятора',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Поделиться'));
      await tester.pumpAndSettle();

      // Verify no errors occurred
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('CalculatorCopyButton Tests', () {
    String generateTestText() => 'Test calculation result';

    testWidgets('должен отображать кнопку копирования', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorCopyButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsOneWidget);
    });

    testWidgets('должен копировать текст при нажатии', (tester) async {
      final List<MethodCall> log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform,
              (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorCopyButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(
        log,
        contains(isA<MethodCall>().having(
          (call) => call.method,
          'method',
          'Clipboard.setData',
        )),
      );

      expect(find.text('Скопировано в буфер обмена'), findsOneWidget);
    });

    testWidgets('должен вызывать onCopied callback', (tester) async {
      var callbackCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorCopyButton(
              generateExportText: generateTestText,
              onCopied: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(callbackCalled, true);
    });

    testWidgets('должен использовать кастомный tooltip', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorCopyButton(
              generateExportText: generateTestText,
              tooltip: 'Скопировать результат',
            ),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Скопировать результат');
    });
  });

  group('CalculatorQuickShareButton Tests', () {
    String generateTestText() => 'Quick share test';

    testWidgets('должен отображать кнопку шаринга', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorQuickShareButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('должен делать share сразу без диалога', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorQuickShareButton(
              generateExportText: generateTestText,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Dialog should not appear
      expect(find.byType(ShareOptionsDialog), findsNothing);
    });

    testWidgets('должен вызывать onShared callback', (tester) async {
      var callbackCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorQuickShareButton(
              generateExportText: generateTestText,
              onShared: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      // onShared is called after share, which may complete before pumpAndSettle
      expect(callbackCalled, true);
    });

    testWidgets('должен использовать subject', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorQuickShareButton(
              generateExportText: generateTestText,
              subject: 'Test Subject',
            ),
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Verify no errors
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('должен использовать кастомный tooltip', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: CalculatorQuickShareButton(
              generateExportText: generateTestText,
              tooltip: 'Быстрый шаринг',
            ),
          ),
        ),
      );

      final button = tester.widget<IconButton>(find.byType(IconButton));
      expect(button.tooltip, 'Быстрый шаринг');
    });
  });

  group('Integration Tests', () {
    testWidgets('должны работать все три кнопки вместе', (tester) async {
      String generateText() => 'Test';
      var copyCount = 0;
      var shareCount = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                CalculatorCopyButton(
                  generateExportText: generateText,
                  onCopied: () => copyCount++,
                ),
                CalculatorQuickShareButton(
                  generateExportText: generateText,
                  onShared: () => shareCount++,
                ),
                CalculatorShareButton(
                  generateExportText: generateText,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsNWidgets(3));

      // Test copy button
      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();
      expect(copyCount, 1);

      // Test quick share button
      await tester.tap(find.byIcon(Icons.share).first);
      await tester.pump();
      // Give time for callback
      await tester.pump(const Duration(milliseconds: 100));
      expect(shareCount, 1);

      // Test full share button (opens dialog)
      await tester.tap(find.byIcon(Icons.share).last);
      await tester.pumpAndSettle();
      expect(find.byType(ShareOptionsDialog), findsOneWidget);
    });

    testWidgets('должны правильно генерировать разный текст', (tester) async {
      var callCount = 0;
      String generateText() {
        callCount++;
        return 'Text $callCount';
      }

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Column(
              children: [
                CalculatorCopyButton(generateExportText: generateText),
                CalculatorQuickShareButton(generateExportText: generateText),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.copy));
      await tester.pumpAndSettle();
      expect(callCount, 1);

      await tester.tap(find.byIcon(Icons.share));
      await tester.pumpAndSettle();
      expect(callCount, 2);
    });
  });
}
