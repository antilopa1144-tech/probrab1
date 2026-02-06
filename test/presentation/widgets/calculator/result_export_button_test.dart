import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/calculator/result_export_button.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('ResultExportButton -', () {
    testWidgets('отображает кнопку экспорта', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: ResultExportButton(),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<ExportAction>), findsOneWidget);
      expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
    });

    testWidgets('показывает меню при нажатии', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () {},
              onCopy: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.text('Копировать'), findsOneWidget);
    });

    testWidgets('показывает только указанные опции', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.text('Копировать'), findsNothing);
      expect(find.text('Экспорт в CSV'), findsNothing);
      expect(find.text('Экспорт в PDF'), findsNothing);
    });

    testWidgets('вызывает onShare callback', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      var called = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Поделиться'));
      await tester.pumpAndSettle();

      expect(called, true);
    });

    testWidgets('вызывает onCopy callback', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      var called = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onCopy: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(called, true);
    });

    testWidgets('вызывает onExportCsv callback', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      var called = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onExportCsv: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в CSV'));
      await tester.pumpAndSettle();

      expect(called, true);
    });

    testWidgets('вызывает onExportPdf callback', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      var called = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onExportPdf: () => called = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(called, true);
    });

    testWidgets('отключается когда enabled=false', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: ResultExportButton(
              enabled: false,
            ),
          ),
        ),
      );

      final button = tester.widget<PopupMenuButton<ExportAction>>(
        find.byType(PopupMenuButton<ExportAction>),
      );

      expect(button.enabled, false);
    });

    testWidgets('активна когда enabled=true', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: ResultExportButton(
              enabled: true,
            ),
          ),
        ),
      );

      final button = tester.widget<PopupMenuButton<ExportAction>>(
        find.byType(PopupMenuButton<ExportAction>),
      );

      expect(button.enabled, true);
    });

    testWidgets('использует кастомный tooltip', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: ResultExportButton(
              tooltip: 'Custom tooltip',
            ),
          ),
        ),
      );

      final button = tester.widget<PopupMenuButton<ExportAction>>(
        find.byType(PopupMenuButton<ExportAction>),
      );

      expect(button.tooltip, 'Custom tooltip');
    });

    testWidgets('использует дефолтный tooltip', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: ResultExportButton(),
          ),
        ),
      );

      final button = tester.widget<PopupMenuButton<ExportAction>>(
        find.byType(PopupMenuButton<ExportAction>),
      );

      expect(button.tooltip, 'Экспорт результатов');
    });

    testWidgets('показывает все опции когда все callbacks указаны', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () {},
              onCopy: () {},
              onExportCsv: () {},
              onExportPdf: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.text('Копировать'), findsOneWidget);
      expect(find.text('Экспорт в CSV'), findsOneWidget);
      expect(find.text('Экспорт в PDF'), findsOneWidget);
    });

    testWidgets('показывает иконки в меню', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () {},
              onCopy: () {},
              onExportCsv: () {},
              onExportPdf: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
    });

    testWidgets('не вызывает callback если он null', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();

      // Только Share доступен, другие опции не показаны
      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.text('Копировать'), findsNothing);
    });

    testWidgets('каждый callback вызывается независимо', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      var shareCalled = 0;
      var copyCalled = 0;
      var csvCalled = 0;
      var pdfCalled = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () => shareCalled++,
              onCopy: () => copyCalled++,
              onExportCsv: () => csvCalled++,
              onExportPdf: () => pdfCalled++,
            ),
          ),
        ),
      );

      // Тест Share
      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Поделиться'));
      await tester.pumpAndSettle();

      expect(shareCalled, 1);
      expect(copyCalled, 0);

      // Тест Copy
      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Копировать'));
      await tester.pumpAndSettle();

      expect(copyCalled, 1);
      expect(csvCalled, 0);

      // Тест CSV
      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Экспорт в CSV'));
      await tester.pumpAndSettle();

      expect(csvCalled, 1);
      expect(pdfCalled, 0);

      // Тест PDF
      await tester.tap(find.byType(PopupMenuButton<ExportAction>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(pdfCalled, 1);
    });

    testWidgets('может быть вызвана несколько раз', (tester) async {
      setTestViewportSize(tester);
      addTearDown(tester.view.resetPhysicalSize);
      var callCount = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: ResultExportButton(
              onShare: () => callCount++,
            ),
          ),
        ),
      );

      for (var i = 0; i < 3; i++) {
        await tester.tap(find.byType(PopupMenuButton<ExportAction>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Поделиться'));
        await tester.pumpAndSettle();
      }

      expect(callCount, 3);
    });

    group('ExportAction enum', () {
      test('имеет все необходимые значения', () {
        expect(ExportAction.values.length, 5);
        expect(ExportAction.values.contains(ExportAction.share), true);
        expect(ExportAction.values.contains(ExportAction.copy), true);
        expect(ExportAction.values.contains(ExportAction.csv), true);
        expect(ExportAction.values.contains(ExportAction.pdf), true);
        expect(ExportAction.values.contains(ExportAction.downloadPdf), true);
      });
    });
  });
}
