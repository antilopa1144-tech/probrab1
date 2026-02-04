import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/presentation/widgets/calculator/result_export_button.dart';

/// Stub-делегат локализации для тестов.
class _StubLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _StubLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return _StubAppLocalizations();
  }

  @override
  bool shouldReload(_StubLocalizationsDelegate old) => false;
}

/// Подкласс AppLocalizations без загрузки assets — возвращает ключ как перевод.
class _StubAppLocalizations extends AppLocalizations {
  _StubAppLocalizations() : super(const Locale('ru'));

  @override
  String translate(String key, [Map<String, String>? params]) => key;
}

/// Обёртка для виджет-тестов: подставляет stub-локализацию и Material/Cupertino делегаты.
Widget _withLocalization(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      _StubLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ru')],
    locale: const Locale('ru'),
    home: Scaffold(body: child),
  );
}

/// Открывает popup меню тапом по иконке и ждёт анимацию.
Future<void> _openPopup(WidgetTester tester) async {
  await tester.pump();
  await tester.tap(find.byIcon(Icons.file_upload_outlined));
  await tester.pumpAndSettle();
}

void main() {
  // ─────────────────────────────────────────────────
  // Видимость кнопки и иконки
  // ─────────────────────────────────────────────────
  group('ResultExportButton — рендеринг', () {
    testWidgets('рендерит иконку file_upload_outlined', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(ResultExportButton(onShare: () {})),
      );
      await tester.pump();
      expect(find.byIcon(Icons.file_upload_outlined), findsOneWidget);
    });

    testWidgets('кнопка отключена когда enabled: false', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(ResultExportButton(onShare: () {}, enabled: false)),
      );
      await tester.pump();
      final PopupMenuButton<ExportAction> button =
          tester.widget(find.byType(PopupMenuButton<ExportAction>));
      expect(button.enabled, false);
    });

    testWidgets('кнопка включена по умолчанию', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(ResultExportButton(onShare: () {})),
      );
      await tester.pump();
      final PopupMenuButton<ExportAction> button =
          tester.widget(find.byType(PopupMenuButton<ExportAction>));
      expect(button.enabled, true);
    });

    testWidgets('tooltip по умолчанию — ключ из локализации', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(ResultExportButton(onShare: () {})),
      );
      await tester.pump();
      final PopupMenuButton<ExportAction> button =
          tester.widget(find.byType(PopupMenuButton<ExportAction>));
      expect(button.tooltip, 'common.export_results');
    });

    testWidgets('custom tooltip передаётся в PopupMenuButton', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(ResultExportButton(onShare: () {}, tooltip: 'Мой экспорт')),
      );
      await tester.pump();
      final PopupMenuButton<ExportAction> button =
          tester.widget(find.byType(PopupMenuButton<ExportAction>));
      expect(button.tooltip, 'Мой экспорт');
    });
  });

  // ─────────────────────────────────────────────────
  // Видимость пунктов меню
  // ─────────────────────────────────────────────────
  group('ResultExportButton — пункты меню', () {
    testWidgets('при всех callback — все 5 иконок пунктов видны', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(
          ResultExportButton(
            onShare: () {},
            onCopy: () {},
            onExportCsv: () {},
            onExportPdf: () {},
            onDownloadPdf: () {},
          ),
        ),
      );
      await _openPopup(tester);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('без callback — меню пуст', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(ResultExportButton()),
      );
      await _openPopup(tester);
      expect(find.byIcon(Icons.share_rounded), findsNothing);
      expect(find.byIcon(Icons.copy_rounded), findsNothing);
      expect(find.byIcon(Icons.table_chart_outlined), findsNothing);
      expect(find.byIcon(Icons.picture_as_pdf_outlined), findsNothing);
      expect(find.byIcon(Icons.download_rounded), findsNothing);
    });

    testWidgets('только onShare — видна только иконка share', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(ResultExportButton(onShare: () {})),
      );
      await _openPopup(tester);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsNothing);
    });

    testWidgets('onShare + onDownloadPdf — видны share и download', (WidgetTester tester) async {
      await tester.pumpWidget(
        _withLocalization(
          ResultExportButton(onShare: () {}, onDownloadPdf: () {}),
        ),
      );
      await _openPopup(tester);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────
  // Тапы по пунктам меню — callback вызовы
  // ─────────────────────────────────────────────────
  group('ResultExportButton — тапы по меню', () {
    testWidgets('тап «Share» вызывает onShare', (WidgetTester tester) async {
      var called = false;
      await tester.pumpWidget(
        _withLocalization(ResultExportButton(onShare: () => called = true)),
      );
      await _openPopup(tester);
      await tester.tap(find.byIcon(Icons.share_rounded));
      await tester.pumpAndSettle();
      expect(called, true);
    });

    testWidgets('тап «Copy» вызывает onCopy', (WidgetTester tester) async {
      var called = false;
      await tester.pumpWidget(
        _withLocalization(
          ResultExportButton(onShare: () {}, onCopy: () => called = true),
        ),
      );
      await _openPopup(tester);
      await tester.tap(find.byIcon(Icons.copy_rounded));
      await tester.pumpAndSettle();
      expect(called, true);
    });

    testWidgets('тап «Download PDF» вызывает onDownloadPdf', (WidgetTester tester) async {
      var called = false;
      await tester.pumpWidget(
        _withLocalization(
          ResultExportButton(onShare: () {}, onDownloadPdf: () => called = true),
        ),
      );
      await _openPopup(tester);
      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();
      expect(called, true);
    });

    testWidgets('тап «Export PDF» вызывает onExportPdf', (WidgetTester tester) async {
      var called = false;
      await tester.pumpWidget(
        _withLocalization(
          ResultExportButton(onShare: () {}, onExportPdf: () => called = true),
        ),
      );
      await _openPopup(tester);
      await tester.tap(find.byIcon(Icons.picture_as_pdf_outlined));
      await tester.pumpAndSettle();
      expect(called, true);
    });

    testWidgets('тап «Export CSV» вызывает onExportCsv', (WidgetTester tester) async {
      var called = false;
      await tester.pumpWidget(
        _withLocalization(
          ResultExportButton(onShare: () {}, onExportCsv: () => called = true),
        ),
      );
      await _openPopup(tester);
      await tester.tap(find.byIcon(Icons.table_chart_outlined));
      await tester.pumpAndSettle();
      expect(called, true);
    });
  });

  // ─────────────────────────────────────────────────
  // enum ExportAction
  // ─────────────────────────────────────────────────
  group('ExportAction enum', () {
    test('содержит 5 значений', () {
      expect(ExportAction.values.length, 5);
    });

    test('все значения уникальны', () {
      expect(ExportAction.values.toSet().length, 5);
    });

    test('содержит share', () {
      expect(ExportAction.values, contains(ExportAction.share));
    });

    test('содержит copy', () {
      expect(ExportAction.values, contains(ExportAction.copy));
    });

    test('содержит csv', () {
      expect(ExportAction.values, contains(ExportAction.csv));
    });

    test('содержит pdf', () {
      expect(ExportAction.values, contains(ExportAction.pdf));
    });

    test('содержит downloadPdf', () {
      expect(ExportAction.values, contains(ExportAction.downloadPdf));
    });
  });

  // ─────────────────────────────────────────────────
  // Свойства конструктора (без рендера)
  // ─────────────────────────────────────────────────
  group('ResultExportButton — конструктор', () {
    test('все callback-поля по умолчанию null', () {
      final btn = ResultExportButton();
      expect(btn.onShare, isNull);
      expect(btn.onCopy, isNull);
      expect(btn.onExportCsv, isNull);
      expect(btn.onExportPdf, isNull);
      expect(btn.onDownloadPdf, isNull);
    });

    test('callback-поля присваиваются и вызываются корректно', () {
      var shareCount = 0;
      var copyCount = 0;
      var csvCount = 0;
      var pdfCount = 0;
      var downloadPdfCount = 0;

      final btn = ResultExportButton(
        onShare: () => shareCount++,
        onCopy: () => copyCount++,
        onExportCsv: () => csvCount++,
        onExportPdf: () => pdfCount++,
        onDownloadPdf: () => downloadPdfCount++,
      );

      btn.onShare!();
      btn.onCopy!();
      btn.onExportCsv!();
      btn.onExportPdf!();
      btn.onDownloadPdf!();

      expect(shareCount, 1);
      expect(copyCount, 1);
      expect(csvCount, 1);
      expect(pdfCount, 1);
      expect(downloadPdfCount, 1);
    });

    test('enabled по умолчанию true', () {
      final btn = ResultExportButton();
      expect(btn.enabled, true);
    });

    test('tooltip по умолчанию null', () {
      final btn = ResultExportButton();
      expect(btn.tooltip, isNull);
    });

    test('custom tooltip передаётся', () {
      final btn = ResultExportButton(tooltip: 'Мой тултип');
      expect(btn.tooltip, 'Мой тултип');
    });
  });
}
