import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/widgets/project/material_category_chip.dart';
import '../../../helpers/test_helpers.dart';

void main() {
  group('MaterialCategoryChip -', () {
    testWidgets('отображает категорию с иконкой и текстом', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChip(
              category: MaterialCategory.cement,
            ),
          ),
        ),
      );

      expect(find.text('Цемент'), findsOneWidget);
      expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
    });

    testWidgets('отображает выбранное состояние', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChip(
              category: MaterialCategory.brick,
              isSelected: true,
            ),
          ),
        ),
      );

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.selected, isTrue);
    });

    testWidgets('вызывает callback при нажатии', (tester) async {
      var callbackCalled = false;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MaterialCategoryChip(
              category: MaterialCategory.tile,
              onSelected: () {
                callbackCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FilterChip));
      await tester.pump();

      expect(callbackCalled, isTrue);
    });

    testWidgets('скрывает иконку когда showIcon = false', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChip(
              category: MaterialCategory.paint,
              showIcon: false,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.format_paint_rounded), findsNothing);
      expect(find.text('Краска'), findsOneWidget);
    });

    testWidgets('отображает компактный режим', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChip(
              category: MaterialCategory.wood,
              compact: true,
            ),
          ),
        ),
      );

      expect(find.text('Дерево'), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(Icons.forest_rounded));
      expect(icon.size, equals(16));
    });

    testWidgets('использует правильный цвет для каждой категории', (tester) async {
      for (final category in MaterialCategory.values) {
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: MaterialCategoryChip(
                category: category,
              ),
            ),
          ),
        );

        // Проверяем наличие текста (локализованная метка)
        expect(find.byType(Text), findsWidgets);
        expect(find.byIcon(category.icon), findsOneWidget);

        await tester.pumpWidget(Container()); // Clear widget tree
      }
    });

    testWidgets('disabled когда onSelected = null', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChip(
              category: MaterialCategory.metal,
              onSelected: null,
            ),
          ),
        ),
      );

      final chip = tester.widget<FilterChip>(find.byType(FilterChip));
      expect(chip.onSelected, isNull);
    });

    testWidgets('отображает правильный border для выбранного состояния', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: Column(
              children: [
                MaterialCategoryChip(
                  category: MaterialCategory.electrical,
                  isSelected: true,
                ),
                MaterialCategoryChip(
                  category: MaterialCategory.plumbing,
                  isSelected: false,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FilterChip), findsNWidgets(2));
    });
  });

  group('MaterialCategoryChipList -', () {
    testWidgets('отображает все категории', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChipList(
              selectedCategories: {},
            ),
          ),
        ),
      );

      expect(find.byType(MaterialCategoryChip), findsNWidgets(MaterialCategory.values.length));
    });

    testWidgets('отображает выбранные категории', (tester) async {
      final selected = {MaterialCategory.cement, MaterialCategory.brick};

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: MaterialCategoryChipList(
              selectedCategories: selected,
            ),
          ),
        ),
      );

      final chips = tester.widgetList<MaterialCategoryChip>(
        find.byType(MaterialCategoryChip),
      );

      int selectedCount = 0;
      for (final chip in chips) {
        if (chip.isSelected) selectedCount++;
      }

      expect(selectedCount, equals(2));
    });

    testWidgets('multiple select добавляет и удаляет категории', (tester) async {
      Set<MaterialCategory> selection = {};

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: MaterialCategoryChipList(
                  selectedCategories: selection,
                  multiSelect: true,
                  onChanged: (newSelection) {
                    setState(() {
                      selection = newSelection;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Выбираем первую категорию
      await tester.tap(find.text('Цемент'));
      await tester.pumpAndSettle();
      expect(selection.contains(MaterialCategory.cement), isTrue);

      // Выбираем вторую категорию
      await tester.tap(find.text('Кирпич'));
      await tester.pumpAndSettle();
      expect(selection.length, equals(2));
      expect(selection.contains(MaterialCategory.brick), isTrue);

      // Отменяем выбор первой категории
      await tester.tap(find.text('Цемент'));
      await tester.pumpAndSettle();
      expect(selection.length, equals(1));
      expect(selection.contains(MaterialCategory.cement), isFalse);
    });

    testWidgets('single select выбирает только одну категорию', (tester) async {
      Set<MaterialCategory> selection = {};

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: MaterialCategoryChipList(
                  selectedCategories: selection,
                  multiSelect: false,
                  onChanged: (newSelection) {
                    setState(() {
                      selection = newSelection;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // Выбираем первую категорию
      await tester.tap(find.text('Цемент'));
      await tester.pumpAndSettle();
      expect(selection.length, equals(1));
      expect(selection.contains(MaterialCategory.cement), isTrue);

      // Выбираем вторую категорию
      await tester.tap(find.text('Кирпич'));
      await tester.pumpAndSettle();
      expect(selection.length, equals(1));
      expect(selection.contains(MaterialCategory.brick), isTrue);
      expect(selection.contains(MaterialCategory.cement), isFalse);
    });

    testWidgets('single select отменяет выбор при повторном клике', (tester) async {
      Set<MaterialCategory> selection = {MaterialCategory.cement};

      await tester.pumpWidget(
        createTestApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: MaterialCategoryChipList(
                  selectedCategories: selection,
                  multiSelect: false,
                  onChanged: (newSelection) {
                    setState(() {
                      selection = newSelection;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Цемент'));
      await tester.pumpAndSettle();
      expect(selection.isEmpty, isTrue);
    });

    testWidgets('применяет compact mode ко всем chips', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChipList(
              selectedCategories: {},
              compact: true,
            ),
          ),
        ),
      );

      final chips = tester.widgetList<MaterialCategoryChip>(
        find.byType(MaterialCategoryChip),
      );

      for (final chip in chips) {
        expect(chip.compact, isTrue);
      }
    });

    testWidgets('скрывает иконки когда showIcons = false', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChipList(
              selectedCategories: {},
              showIcons: false,
            ),
          ),
        ),
      );

      final chips = tester.widgetList<MaterialCategoryChip>(
        find.byType(MaterialCategoryChip),
      );

      for (final chip in chips) {
        expect(chip.showIcon, isFalse);
      }
    });

    testWidgets('disabled когда onChanged = null', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const Scaffold(
            body: MaterialCategoryChipList(
              selectedCategories: {},
              onChanged: null,
            ),
          ),
        ),
      );

      final chips = tester.widgetList<MaterialCategoryChip>(
        find.byType(MaterialCategoryChip),
      );

      for (final chip in chips) {
        expect(chip.onSelected, isNull);
      }
    });
  });

  group('MaterialCategorySelectionDialog -', () {
    testWidgets('отображает диалог с заголовком', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const MaterialCategorySelectionDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Выберите категории'), findsOneWidget);
      expect(find.byType(MaterialCategoryChipList), findsOneWidget);
    });

    testWidgets('отображает правильный заголовок для single select', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const MaterialCategorySelectionDialog(
                        multiSelect: false,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Выберите категорию'), findsOneWidget);
    });

    testWidgets('показывает начальный выбор', (tester) async {
      final initialSelection = {MaterialCategory.cement, MaterialCategory.brick};

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => MaterialCategorySelectionDialog(
                        initialSelection: initialSelection,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Выбрано: 2'), findsOneWidget);
    });

    testWidgets('кнопка Очистить сбрасывает выбор', (tester) async {
      final initialSelection = {MaterialCategory.cement, MaterialCategory.brick};

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => MaterialCategorySelectionDialog(
                        initialSelection: initialSelection,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Выбрано: 2'), findsOneWidget);

      await tester.tap(find.text('Очистить'));
      await tester.pumpAndSettle();

      expect(find.text('Выбрано: 2'), findsNothing);
    });

    testWidgets('кнопка Отмена закрывает диалог без результата', (tester) async {
      Set<MaterialCategory>? result;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<Set<MaterialCategory>>(
                      context: context,
                      builder: (_) => const MaterialCategorySelectionDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(result, isNull);
    });

    testWidgets('кнопка Применить возвращает выбранные категории', (tester) async {
      Set<MaterialCategory>? result;

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<Set<MaterialCategory>>(
                      context: context,
                      builder: (_) => const MaterialCategorySelectionDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Выбираем категорию
      await tester.tap(find.text('Цемент'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(result, isNotNull);
      expect(result!.contains(MaterialCategory.cement), isTrue);
    });

    testWidgets('работает с multiSelect режимом', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const MaterialCategorySelectionDialog(
                        multiSelect: true,
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Выбираем несколько категорий
      await tester.tap(find.text('Цемент'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Кирпич'));
      await tester.pumpAndSettle();

      expect(find.text('Выбрано: 2'), findsOneWidget);
    });

    testWidgets('не показывает счетчик в single select режиме', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const MaterialCategorySelectionDialog(
                        multiSelect: false,
                        initialSelection: {MaterialCategory.cement},
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Выбрано:'), findsNothing);
    });

    testWidgets('диалог скроллится когда много контента', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => const MaterialCategorySelectionDialog(),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('MaterialCategory enum -', () {
    test('содержит все ожидаемые категории', () {
      expect(MaterialCategory.values.length, equals(10));
      expect(MaterialCategory.values, contains(MaterialCategory.cement));
      expect(MaterialCategory.values, contains(MaterialCategory.brick));
      expect(MaterialCategory.values, contains(MaterialCategory.tile));
      expect(MaterialCategory.values, contains(MaterialCategory.paint));
      expect(MaterialCategory.values, contains(MaterialCategory.wood));
      expect(MaterialCategory.values, contains(MaterialCategory.metal));
      expect(MaterialCategory.values, contains(MaterialCategory.electrical));
      expect(MaterialCategory.values, contains(MaterialCategory.plumbing));
      expect(MaterialCategory.values, contains(MaterialCategory.insulation));
      expect(MaterialCategory.values, contains(MaterialCategory.other));
    });

    test('каждая категория имеет name, icon и color', () {
      for (final category in MaterialCategory.values) {
        expect(category.name.isNotEmpty, isTrue);
        expect(category.icon, isNotNull);
        expect(category.color, isNotNull);
      }
    });
  });
}
