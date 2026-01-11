import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/checklist.dart';
import 'package:probrab_ai/domain/models/checklist_template.dart';
import 'package:probrab_ai/presentation/views/checklist/create_checklist_bottom_sheet.dart';

void main() {
  group('CreateChecklistBottomSheet', () {
    Widget createTestWidget({int? projectId}) {
      return ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => SizedBox(
                      height: 600,
                      child: CreateChecklistBottomSheet(projectId: projectId),
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('отображает заголовок в AppBar', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Заголовок - в Row с иконкой
      expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
      // Есть текст "Создать чек-лист" (минимум 1 - в заголовке)
      expect(find.text('Создать чек-лист'), findsWidgets);
    });

    testWidgets('отображает кнопку закрытия', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('отображает первый шаблон', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text(template.name), findsOneWidget);
    });

    testWidgets('отображает описание первого шаблона', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text(template.description), findsOneWidget);
    });

    testWidgets('отображает количество задач', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text('${template.items.length} задач'), findsOneWidget);
    });

    testWidgets('выбранный шаблон показывает галочку', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // До выбора нет галочки
      expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

      // Выбираем первый шаблон
      final template = ChecklistTemplates.all.first;
      await tester.tap(find.text(template.name));
      await tester.pumpAndSettle();

      // После выбора появляется галочка
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('можно переключать выбор шаблона', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final templates = ChecklistTemplates.all;
      if (templates.length < 2) return;

      // Выбираем первый шаблон
      await tester.tap(find.text(templates[0].name));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Выбираем второй шаблон
      await tester.tap(find.text(templates[1].name));
      await tester.pumpAndSettle();

      // Всё ещё только одна галочка
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('закрывается по кнопке X', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsNothing);
    });

    testWidgets('отображает иконку задачи на кнопке', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add_task_rounded), findsOneWidget);
    });

    testWidgets('отображает иконку категории шаблона', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      final template = ChecklistTemplates.all.first;
      expect(find.text(template.category.icon), findsOneWidget);
    });

    testWidgets('принимает projectId без ошибок', (tester) async {
      await tester.pumpWidget(createTestWidget(projectId: 42));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);
    });

    testWidgets('содержит ListView для прокрутки', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('содержит DraggableScrollableSheet', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('отображает Divider', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('шаблоны отображаются в Card', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsWidgets);
    });
  });

  group('CreateChecklistBottomSheet.show', () {
    testWidgets('статический метод show открывает bottom sheet', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    CreateChecklistBottomSheet.show(context);
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);
    });

    testWidgets('статический метод show принимает projectId', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    CreateChecklistBottomSheet.show(context, projectId: 123);
                  },
                  child: const Text('Show'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateChecklistBottomSheet), findsOneWidget);
    });
  });
}
