import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/project/project_export_menu.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('ProjectExportMenu Widget Tests', () {
    testWidgets('должен отображать кнопку меню', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('должен отображать кастомную иконку', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  icon: Icons.file_download,
                  onExportPDF: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('должен показывать tooltip', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  tooltip: 'Экспортировать проект',
                  onExportPDF: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      final button = find.byType(PopupMenuButton<String>);
      expect(button, findsOneWidget);

      // Проверка tooltip через widget tree
      final popupButton = tester.widget<PopupMenuButton<String>>(button);
      expect(popupButton.tooltip, 'Экспортировать проект');
    });

    testWidgets('должен отображать только PDF опцию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Экспорт в PDF'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.text('Экспорт в CSV'), findsNothing);
      expect(find.text('Поделиться'), findsNothing);
    });

    testWidgets('должен отображать только CSV опцию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportCSV: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Экспорт в CSV'), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.text('Экспорт в PDF'), findsNothing);
      expect(find.text('Поделиться'), findsNothing);
    });

    testWidgets('должен отображать только Share опцию', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onShare: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
      expect(find.text('Экспорт в PDF'), findsNothing);
      expect(find.text('Экспорт в CSV'), findsNothing);
    });

    testWidgets('должен отображать все опции', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {},
                  onExportCSV: () async {},
                  onShare: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Экспорт в PDF'), findsOneWidget);
      expect(find.text('Экспорт в CSV'), findsOneWidget);
      expect(find.text('Поделиться'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
      expect(find.byIcon(Icons.share), findsOneWidget);
    });

    testWidgets('должен вызывать onExportPDF callback', (tester) async {
      var pdfExported = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {
                    pdfExported = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(pdfExported, true);
    });

    testWidgets('должен вызывать onExportCSV callback', (tester) async {
      var csvExported = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportCSV: () async {
                    csvExported = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в CSV'));
      await tester.pumpAndSettle();

      expect(csvExported, true);
    });

    testWidgets('должен вызывать onShare callback', (tester) async {
      var shared = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onShare: () async {
                    shared = true;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Поделиться'));
      await tester.pumpAndSettle();

      expect(shared, true);
    });

    testWidgets('должен показывать success snackbar после PDF экспорта',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(find.text('PDF экспортирован'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('должен показывать success snackbar после CSV экспорта',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportCSV: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в CSV'));
      await tester.pumpAndSettle();

      expect(find.text('CSV экспортирован'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('должен показывать error snackbar при ошибке экспорта',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {
                    throw Exception('Ошибка экспорта');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ошибка экспорта'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('не должен показывать Share когда нет onShare и shareText',
        (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {},
                  onExportCSV: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Share option should not appear
      expect(find.text('Поделиться'), findsNothing);
      expect(find.text('Экспорт в PDF'), findsOneWidget);
      expect(find.text('Экспорт в CSV'), findsOneWidget);
    });

    testWidgets('должен закрывать меню после выбора опции', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {},
                  onExportCSV: () async {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      expect(find.text('Экспорт в PDF'), findsOneWidget);

      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      // Menu should be closed
      expect(find.text('Экспорт в PDF'), findsNothing);
    });

    testWidgets('должен работать с несколькими последовательными действиями',
        (tester) async {
      var pdfCount = 0;
      var csvCount = 0;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            appBar: AppBar(
              actions: [
                ProjectExportMenu(
                  onExportPDF: () async {
                    pdfCount++;
                  },
                  onExportCSV: () async {
                    csvCount++;
                  },
                ),
              ],
            ),
          ),
        ),
      );

      // Первый экспорт PDF
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(pdfCount, 1);

      // Второй экспорт CSV
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Экспорт в CSV'));
      await tester.pumpAndSettle();

      expect(csvCount, 1);

      // Третий экспорт PDF
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(pdfCount, 2);
      expect(csvCount, 1);
    });

    testWidgets('должен корректно работать в различных Scaffold контекстах',
        (tester) async {
      var exported = false;

      await tester.pumpWidget(
        createTestApp(
          child: Builder(
            builder: (context) => Scaffold(
              appBar: AppBar(
                actions: [
                  ProjectExportMenu(
                    onExportPDF: () async {
                      exported = true;
                    },
                  ),
                ],
              ),
              body: const Center(child: Text('Content')),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Экспорт в PDF'));
      await tester.pumpAndSettle();

      expect(exported, true);
      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
