// Тесты для ExportableMixin и ExportableConsumerMixin.
// Проверяют публичные методы и геттеры миксинов.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/core/localization/app_localizations.dart';
import 'package:probrab_ai/presentation/mixins/exportable_mixin.dart';
import 'package:probrab_ai/presentation/mixins/exportable_consumer_mixin.dart';

// ─────────────────────────────────────────────────────────────────
// Stub AppLocalizations
// ─────────────────────────────────────────────────────────────────

class _StubLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _StubLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async => _StubAppLocalizations();

  @override
  bool shouldReload(_StubLocalizationsDelegate old) => false;
}

class _StubAppLocalizations extends AppLocalizations {
  _StubAppLocalizations() : super(const Locale('ru'));

  @override
  String translate(String key, [Map<String, String>? params]) => key;
}

// ─────────────────────────────────────────────────────────────────
// Test Widget with ExportableMixin
// ─────────────────────────────────────────────────────────────────

class _TestExportableWidget extends StatefulWidget {
  final String subject;
  final String exportText;

  const _TestExportableWidget({
    required this.subject,
    required this.exportText,
  });

  @override
  State<_TestExportableWidget> createState() => _TestExportableWidgetState();
}

class _TestExportableWidgetState extends State<_TestExportableWidget>
    with ExportableMixin {
  late AppLocalizations _loc;

  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => widget.subject;

  @override
  String generateExportText() => widget.exportText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Subject: $exportSubject'),
        Text('Text: ${generateExportText()}'),
        ...exportActions,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Test Widget with ExportableConsumerMixin
// ─────────────────────────────────────────────────────────────────

class _TestConsumerExportableWidget extends ConsumerStatefulWidget {
  final String subject;
  final String exportText;

  const _TestConsumerExportableWidget({
    required this.subject,
    required this.exportText,
  });

  @override
  ConsumerState<_TestConsumerExportableWidget> createState() =>
      _TestConsumerExportableWidgetState();
}

class _TestConsumerExportableWidgetState
    extends ConsumerState<_TestConsumerExportableWidget>
    with ExportableConsumerMixin {
  late AppLocalizations _loc;

  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => widget.subject;

  @override
  String generateExportText() => widget.exportText;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loc = AppLocalizations.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Subject: $exportSubject'),
        Text('Text: ${generateExportText()}'),
        ...exportActions,
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Helper
// ─────────────────────────────────────────────────────────────────

Widget _withLocalization(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        _StubLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ru')],
      locale: const Locale('ru'),
      home: Scaffold(body: child),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────

void main() {
  group('ExportableMixin', () {
    testWidgets('exportSubject возвращает переданное значение', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestExportableWidget(
            subject: 'Тестовый калькулятор',
            exportText: 'Результат: 42',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Subject: Тестовый калькулятор'), findsOneWidget);
    });

    testWidgets('generateExportText возвращает переданный текст', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestExportableWidget(
            subject: 'Калькулятор',
            exportText: 'Площадь: 100 м²',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Text: Площадь: 100 м²'), findsOneWidget);
    });

    testWidgets('exportActions содержит 3 IconButton', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestExportableWidget(
            subject: 'Test',
            exportText: 'Text',
          ),
        ),
      );
      await tester.pump();

      // copy, share, download
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('exportActions имеют правильные tooltips', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestExportableWidget(
            subject: 'Test',
            exportText: 'Text',
          ),
        ),
      );
      await tester.pump();

      // Stub возвращает ключ как tooltip
      final copyButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.copy_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(copyButton.tooltip, 'common.copy');

      final shareButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.share_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(shareButton.tooltip, 'common.share');

      final downloadButton = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.download_rounded),
          matching: find.byType(IconButton),
        ),
      );
      expect(downloadButton.tooltip, 'common.download_pdf');
    });
  });

  group('ExportableConsumerMixin', () {
    testWidgets('exportSubject возвращает переданное значение', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestConsumerExportableWidget(
            subject: 'Consumer Калькулятор',
            exportText: 'Результат: 100',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Subject: Consumer Калькулятор'), findsOneWidget);
    });

    testWidgets('generateExportText возвращает переданный текст', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestConsumerExportableWidget(
            subject: 'Test',
            exportText: 'Объём: 50 м³',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Text: Объём: 50 м³'), findsOneWidget);
    });

    testWidgets('exportActions содержит 3 базовых IconButton', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestConsumerExportableWidget(
            subject: 'Test',
            exportText: 'Text',
          ),
        ),
      );
      await tester.pump();

      // copy, share, download (без QR, т.к. calculatorId == null)
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
      expect(find.byIcon(Icons.share_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      // QR не должен появиться
      expect(find.byIcon(Icons.qr_code_2_rounded), findsNothing);
    });

    testWidgets('saveToProjectAction равен null по умолчанию', (tester) async {
      // saveToProjectAction возвращает null если isFromProject == false
      // Проверяем что кнопка сохранения не отображается
      await tester.pumpWidget(
        _withLocalization(
          const _TestConsumerExportableWidget(
            subject: 'Test',
            exportText: 'Text',
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.save_rounded), findsNothing);
    });
  });

  group('Mixin edge cases', () {
    testWidgets('работает с пустым exportText', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestExportableWidget(
            subject: 'Empty',
            exportText: '',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Text: '), findsOneWidget);
    });

    testWidgets('работает с очень длинным exportSubject', (tester) async {
      final longSubject = 'А' * 200;
      await tester.pumpWidget(
        _withLocalization(
          _TestExportableWidget(
            subject: longSubject,
            exportText: 'Text',
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Subject: АААА'), findsOneWidget);
    });

    testWidgets('работает с Unicode в exportText', (tester) async {
      await tester.pumpWidget(
        _withLocalization(
          const _TestExportableWidget(
            subject: 'Test',
            exportText: '▸ Пункт 1\n► Пункт 2\n• Итого: 100₽',
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('▸ Пункт 1'), findsOneWidget);
    });
  });
}
