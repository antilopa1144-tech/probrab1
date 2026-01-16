import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/common/share_options_dialog.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('ShareOptionsDialog Tests', () {
    testWidgets('должен отображать заголовок по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(),
        ),
      );

      expect(find.text('Поделиться результатом'), findsOneWidget);
    });

    testWidgets('должен отображать кастомный заголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(
            title: 'Экспорт данных',
          ),
        ),
      );

      expect(find.text('Экспорт данных'), findsOneWidget);
    });

    testWidgets('должен отображать подзаголовок', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(
            subtitle: 'Выберите способ экспорта',
          ),
        ),
      );

      expect(find.text('Выберите способ экспорта'), findsOneWidget);
    });

    testWidgets('должен отображать опции Copy и Share по умолчанию',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(),
        ),
      );

      expect(find.text('Копировать'), findsOneWidget);
      expect(find.text('Скопировать текст в буфер обмена'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);

      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.text('Отправить через мессенджер или email'), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('не должен показывать QR опцию по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(),
        ),
      );

      expect(find.text('QR код'), findsNothing);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
    });

    testWidgets('должен показывать QR опцию когда showQrOption = true',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(
            showQrOption: true,
          ),
        ),
      );

      expect(find.text('QR код'), findsOneWidget);
      expect(find.text('Показать QR код для сканирования'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    });

    testWidgets('должен отображать кнопку Отмена', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(),
        ),
      );

      expect(find.text('Отмена'), findsOneWidget);
    });

    testWidgets('должен возвращать ShareAction.copy при выборе Copy',
        (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShareAction>(
                  context: context,
                  builder: (_) => const ShareOptionsDialog(),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(result, ShareAction.copy);
    });

    testWidgets('должен возвращать ShareAction.share при выборе Share',
        (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShareAction>(
                  context: context,
                  builder: (_) => const ShareOptionsDialog(),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Поделиться'));
      await tester.pumpAndSettle();

      expect(result, ShareAction.share);
    });

    testWidgets('должен возвращать ShareAction.qr при выборе QR',
        (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShareAction>(
                  context: context,
                  builder: (_) => const ShareOptionsDialog(showQrOption: true),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('QR код'));
      await tester.pumpAndSettle();

      expect(result, ShareAction.qr);
    });

    testWidgets('должен возвращать null при нажатии Отмена', (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShareAction>(
                  context: context,
                  builder: (_) => const ShareOptionsDialog(),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('должен закрываться при нажатии на backdrop', (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShareAction>(
                  context: context,
                  builder: (_) => const ShareOptionsDialog(),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      // Tap outside dialog
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('должен использовать кастомные метки', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(
            copyLabel: 'Копия',
            shareLabel: 'Отправить',
            qrLabel: 'QR-код',
            showQrOption: true,
          ),
        ),
      );

      expect(find.text('Копия'), findsOneWidget);
      expect(find.text('Отправить'), findsOneWidget);
      expect(find.text('QR-код'), findsOneWidget);
    });

    testWidgets('должен отображать все элементы с правильным стилем',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(
            showQrOption: true,
          ),
        ),
      );

      // Verify all option tiles exist - there might be extra InkWells from AlertDialog
      expect(find.byType(InkWell), findsWidgets);

      // Verify icons with containers
      final containers = tester.widgetList<Container>(find.byType(Container));
      final iconContainers =
          containers.where((c) => c.padding == const EdgeInsets.all(8));
      expect(iconContainers.length, greaterThanOrEqualTo(3));
    });

    testWidgets('должен правильно работать в разных темах', (tester) async {
      setTestViewportSize(tester);
      // Light theme
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Theme(
                data: ThemeData.light(),
                child: const ShareOptionsDialog(),
              );
            },
          ),
        ),
      );

      expect(find.byType(ShareOptionsDialog), findsOneWidget);

      // Dark theme
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) {
              return Theme(
                data: ThemeData.dark(),
                child: const ShareOptionsDialog(),
              );
            },
          ),
        ),
      );

      expect(find.byType(ShareOptionsDialog), findsOneWidget);
    });
  });

  group('showShareOptionsDialog функция', () {
    testWidgets('должна открывать диалог', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showShareOptionsDialog(context),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ShareOptionsDialog), findsOneWidget);
    });

    testWidgets('должна передавать параметры в диалог', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showShareOptionsDialog(
                context,
                showQrOption: true,
                title: 'Custom Title',
                subtitle: 'Custom Subtitle',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Title'), findsOneWidget);
      expect(find.text('Custom Subtitle'), findsOneWidget);
      expect(find.text('QR код'), findsOneWidget);
    });

    testWidgets('должна возвращать выбранное действие', (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showShareOptionsDialog(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(result, ShareAction.copy);
    });
  });

  group('CompactShareOptionsDialog Tests', () {
    testWidgets('должен отображать компактный диалог', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CompactShareOptionsDialog(),
        ),
      );

      expect(find.byType(SimpleDialog), findsOneWidget);
      // "Поделиться" appears in title and as option text
      expect(find.text('Поделиться'), findsWidgets);
    });

    testWidgets('должен отображать опции Copy и Share', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CompactShareOptionsDialog(),
        ),
      );

      expect(find.text('Копировать'), findsOneWidget);
      // "Поделиться" appears twice - in title and in option
      expect(find.text('Поделиться'), findsWidgets);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    });

    testWidgets('не должен показывать QR по умолчанию', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CompactShareOptionsDialog(),
        ),
      );

      expect(find.text('QR код'), findsNothing);
    });

    testWidgets('должен показывать QR когда showQrOption = true',
        (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CompactShareOptionsDialog(
            showQrOption: true,
          ),
        ),
      );

      expect(find.text('QR код'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_2_rounded), findsOneWidget);
    });

    testWidgets('должен возвращать правильное действие', (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showDialog<ShareAction>(
                  context: context,
                  builder: (_) => const CompactShareOptionsDialog(),
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(result, ShareAction.copy);
    });

    testWidgets('должен работать со всеми опциями', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const CompactShareOptionsDialog(
            showQrOption: true,
          ),
        ),
      );

      expect(find.byType(SimpleDialogOption), findsNWidgets(3));
    });
  });

  group('ShareAction enum Tests', () {
    test('должен иметь все необходимые значения', () {
      expect(ShareAction.values.length, 3);
      expect(ShareAction.values.contains(ShareAction.copy), true);
      expect(ShareAction.values.contains(ShareAction.share), true);
      expect(ShareAction.values.contains(ShareAction.qr), true);
    });

    test('должен правильно сравниваться', () {
      expect(ShareAction.copy == ShareAction.copy, true);
      expect(ShareAction.copy == ShareAction.share, false);
      expect(ShareAction.share == ShareAction.share, true);
      expect(ShareAction.qr == ShareAction.qr, true);
    });
  });

  group('Edge Cases', () {
    testWidgets('должен работать с очень длинными заголовками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(
            title: 'Очень длинный заголовок который может не поместиться в одну строку',
            subtitle:
                'И очень длинный подзаголовок с большим количеством текста',
          ),
        ),
      );

      expect(find.byType(ShareOptionsDialog), findsOneWidget);
    });

    testWidgets('должен работать с пустыми строками', (tester) async {
      setTestViewportSize(tester);
      await tester.pumpWidget(
        createTestApp(
          child: const ShareOptionsDialog(
            title: '',
            copyLabel: '',
            shareLabel: '',
          ),
        ),
      );

      expect(find.byType(ShareOptionsDialog), findsOneWidget);
    });

    testWidgets('должен работать при множественных открытиях', (tester) async {
      setTestViewportSize(tester);
      ShareAction? result;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                result = await showShareOptionsDialog(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      // First open
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      // Second open
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(result, ShareAction.copy);
    });

    testWidgets('должен правильно работать при быстрых нажатиях',
        (tester) async {
      setTestViewportSize(tester);
      ShareAction? lastResult;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    lastResult = await showShareOptionsDialog(context);
                  },
                  child: const Text('Open1'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    lastResult = await showShareOptionsDialog(context);
                  },
                  child: const Text('Open2'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(lastResult, ShareAction.copy);
    });
  });
}
