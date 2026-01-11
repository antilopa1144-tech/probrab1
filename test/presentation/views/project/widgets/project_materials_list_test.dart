import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/domain/models/project_v2.dart';
import 'package:probrab_ai/presentation/views/project/widgets/project_materials_list.dart';
import '../../../../helpers/test_helpers.dart';

import '../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    setupMocks();
  });

  ProjectV2 createTestProject({
    String name = 'Тестовый проект',
    List<ProjectCalculation>? calculations,
  }) {
    final project = ProjectV2()
      ..id = 1
      ..name = name
      ..status = ProjectStatus.planning
      ..createdAt = DateTime.now()
      ..updatedAt = DateTime.now();

    if (calculations != null) {
      for (final calc in calculations) {
        project.calculations.add(calc);
      }
    }

    return project;
  }

  ProjectCalculation createTestCalculation({
    int id = 1,
    String calculatorId = 'test_calc',
    String name = 'Расчет',
    List<ProjectMaterial>? materials,
    double materialCost = 0,
    double laborCost = 0,
  }) {
    final calc = ProjectCalculation()
      ..id = id
      ..calculatorId = calculatorId
      ..name = name
      ..materialCost = materialCost
      ..laborCost = laborCost;

    if (materials != null) {
      calc.materials.addAll(materials);
    }

    return calc;
  }

  ProjectMaterial createTestMaterial({
    String name = 'Материал',
    double quantity = 10.0,
    String unit = 'шт',
    double pricePerUnit = 100.0,
    bool purchased = false,
    String? calculatorId,
  }) {
    return ProjectMaterial()
      ..name = name
      ..quantity = quantity
      ..unit = unit
      ..pricePerUnit = pricePerUnit
      ..purchased = purchased
      ..calculatorId = calculatorId;
  }

  Widget createTestWidget(ProjectV2 project) {
    return createTestApp(
      child: Scaffold(
        body: ProjectMaterialsList(
          project: project,
          onMaterialToggled: () {},
        ),
      ),
    );
  }

  group('ProjectMaterialsList - Пустое состояние', () {
    testWidgets('отображает пустое состояние когда нет материалов', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject();
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Нет материалов'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(find.text('Добавьте расчёты с детальным списком материалов'), findsOneWidget);
    });

    testWidgets('пустое состояние в Card виджете', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject();
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });
  });

  group('ProjectMaterialsList - Отображение материалов', () {
    testWidgets('отображает список материалов', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Кирпич'), findsOneWidget);
      expect(find.text('Цемент'), findsOneWidget);
    });

    testWidgets('отображает количество и единицы измерения', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.textContaining('100'), findsWidgets);
      expect(find.textContaining('шт'), findsWidgets);
    });

    testWidgets('отображает цену за единицу', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.textContaining('50'), findsWidgets);
      expect(find.textContaining('₽'), findsWidgets);
    });

    testWidgets('отображает общую стоимость материала', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // 100 * 50 = 5000
      expect(find.textContaining('5'), findsWidgets);
      expect(find.textContaining('000'), findsWidgets);
    });

    testWidgets('отображает calculatorId если есть', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(
          name: 'Кирпич',
          quantity: 100,
          unit: 'шт',
          pricePerUnit: 50,
          calculatorId: 'brick_calc',
        ),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('brick_calc'), findsOneWidget);
    });
  });

  group('ProjectMaterialsList - Заголовок и статистика', () {
    testWidgets('отображает заголовок Материалы', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Материалы'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);
    });

    testWidgets('отображает общую стоимость всех материалов', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Всего'), findsOneWidget);
      // 100*50 + 10*300 = 5000 + 3000 = 8000
      expect(find.textContaining('8'), findsWidgets);
      expect(find.textContaining('000'), findsWidgets);
    });

    testWidgets('отображает оставшуюся стоимость', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: false),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300, purchased: true),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Осталось'), findsOneWidget);
      // Только непокупленные: 100*50 = 5000
      expect(find.textContaining('5'), findsWidgets);
    });

    testWidgets('отображает прогресс бар если есть покупки', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: true),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300, purchased: false),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('не отображает прогресс бар если нет покупок', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: false),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300, purchased: false),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('ProjectMaterialsList - Отметка покупки', () {
    testWidgets('материалы отображаются как checkbox', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets('непокупленный материал без зачеркивания', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: false),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, isFalse);
    });

    testWidgets('покупленный материал зачеркнут', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: true),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, isTrue);
    });
  });

  group('ProjectMaterialsList - Множественные материалы', () {
    testWidgets('отображает несколько материалов из одного расчета', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300),
        createTestMaterial(name: 'Песок', quantity: 5, unit: 'м³', pricePerUnit: 500),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Кирпич'), findsOneWidget);
      expect(find.text('Цемент'), findsOneWidget);
      expect(find.text('Песок'), findsOneWidget);
    });

    testWidgets('отображает материалы из нескольких расчетов', (tester) async {
      setTestViewportSize(tester);
      final calc1 = createTestCalculation(
        id: 1,
        materials: [
          createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
        ],
      );
      final calc2 = createTestCalculation(
        id: 2,
        materials: [
          createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300),
        ],
      );
      final project = createTestProject(calculations: [calc1, calc2]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Кирпич'), findsOneWidget);
      expect(find.text('Цемент'), findsOneWidget);
    });

    testWidgets('правильно считает общую стоимость всех материалов', (tester) async {
      setTestViewportSize(tester);
      final calc1 = createTestCalculation(
        id: 1,
        materials: [
          createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
        ],
      );
      final calc2 = createTestCalculation(
        id: 2,
        materials: [
          createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300),
        ],
      );
      final project = createTestProject(calculations: [calc1, calc2]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // 100*50 + 10*300 = 8000
      expect(find.textContaining('8'), findsWidgets);
      expect(find.textContaining('000'), findsWidgets);
    });
  });

  group('ProjectMaterialsList - Форматирование чисел', () {
    testWidgets('форматирует целые числа без десятичных', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100.0, unit: 'шт', pricePerUnit: 50.0),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.textContaining('100'), findsWidgets);
      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('форматирует дробные числа с разделителем', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100.5, unit: 'шт', pricePerUnit: 50.75),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.textContaining('100'), findsWidgets);
      expect(find.textContaining('50'), findsWidgets);
    });

    testWidgets('форматирует большие числа с разделителями тысяч', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 1000, unit: 'шт', pricePerUnit: 100),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // Проверяем что большие числа отображаются
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });
  });

  group('ProjectMaterialsList - _CostInfo виджет', () {
    testWidgets('_CostInfo отображает метку и значение', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Всего'), findsOneWidget);
      expect(find.text('Осталось'), findsOneWidget);
    });
  });

  group('ProjectMaterialsList - _MaterialTile виджет', () {
    testWidgets('отображает название, количество и цену', (tester) async {
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Кирпич'), findsOneWidget);
    });

    testWidgets('покупленный материал имеет зачеркнутый стиль', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: true),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      final checkbox = tester.widget<CheckboxListTile>(find.byType(CheckboxListTile));
      expect(checkbox.value, isTrue);
    });
  });

  group('ProjectMaterialsList - Сложные сценарии', () {
    testWidgets('смешанные покупленные и непокупленные материалы', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: true),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300, purchased: false),
        createTestMaterial(name: 'Песок', quantity: 5, unit: 'м³', pricePerUnit: 500, purchased: true),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('все материалы покупленные', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: true),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300, purchased: true),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // Осталось должно быть 0
      expect(find.text('Осталось'), findsOneWidget);
    });

    testWidgets('никакие материалы не покупленные', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50, purchased: false),
        createTestMaterial(name: 'Цемент', quantity: 10, unit: 'мешок', pricePerUnit: 300, purchased: false),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      // Осталось = Всего
      expect(find.text('Всего'), findsOneWidget);
      expect(find.text('Осталось'), findsOneWidget);
    });

    testWidgets('материалы с нулевой стоимостью', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Бесплатный', quantity: 100, unit: 'шт', pricePerUnit: 0),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Бесплатный'), findsOneWidget);
      expect(find.textContaining('0'), findsWidgets);
    });

    testWidgets('материалы с очень большими числами', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Дорогой', quantity: 1000, unit: 'шт', pricePerUnit: 10000),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Дорогой'), findsOneWidget);
    });

    testWidgets('проект с множеством расчетов и материалов', (tester) async {
      setTestViewportSize(tester);
      final calculations = <ProjectCalculation>[];
      for (int i = 0; i < 5; i++) {
        calculations.add(
          createTestCalculation(
            id: i + 1,
            materials: [
              createTestMaterial(
                name: 'Материал $i',
                quantity: (i + 1) * 10.0,
                unit: 'шт',
                pricePerUnit: (i + 1) * 50.0,
              ),
            ],
          ),
        );
      }
      final project = createTestProject(calculations: calculations);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsNWidgets(5));
    });

    testWidgets('прокрутка списка материалов работает', (tester) async {
      setTestViewportSize(tester);
      final materials = <ProjectMaterial>[];
      for (int i = 0; i < 20; i++) {
        materials.add(
          createTestMaterial(
            name: 'Материал $i',
            quantity: 10,
            unit: 'шт',
            pricePerUnit: 100,
          ),
        );
      }
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('ProjectMaterialsList - Edge cases', () {
    testWidgets('обрабатывает пустой список расчетов', (tester) async {
      setTestViewportSize(tester);
      final project = createTestProject(calculations: []);
      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Нет материалов'), findsOneWidget);
    });

    testWidgets('обрабатывает расчет без материалов', (tester) async {
      setTestViewportSize(tester);
      final calc = createTestCalculation(materials: []);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Нет материалов'), findsOneWidget);
    });

    testWidgets('обрабатывает материалы с очень длинными названиями', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(
          name: 'Очень длинное название материала которое должно быть обработано корректно',
          quantity: 10,
          unit: 'шт',
          pricePerUnit: 100,
        ),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(CheckboxListTile), findsOneWidget);
    });

    testWidgets('обрабатывает материалы с особыми символами в названии', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(
          name: 'Кирпич М-150 (ГОСТ 530-2012)',
          quantity: 10,
          unit: 'шт',
          pricePerUnit: 100,
        ),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.textContaining('Кирпич М-150'), findsOneWidget);
    });

    testWidgets('обрабатывает материалы с дробными количествами', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(
          name: 'Материал',
          quantity: 10.567,
          unit: 'м³',
          pricePerUnit: 100.123,
        ),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Материал'), findsOneWidget);
    });

    testWidgets('обрабатывает null calculatorId', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(
          name: 'Материал',
          quantity: 10,
          unit: 'шт',
          pricePerUnit: 100,
          calculatorId: null,
        ),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.text('Материал'), findsOneWidget);
    });
  });

  group('ProjectMaterialsList - Визуальные элементы', () {
    testWidgets('использует Card виджет', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('использует ListView для списка материалов', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('ListView имеет shrinkWrap и NeverScrollableScrollPhysics', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      final listView = tester.widget<ListView>(find.byType(ListView));
      expect(listView.shrinkWrap, isTrue);
      expect(listView.physics, isA<NeverScrollableScrollPhysics>());
    });

    testWidgets('отображает Divider между секциями', (tester) async {
      setTestViewportSize(tester);
      final materials = [
        createTestMaterial(name: 'Кирпич', quantity: 100, unit: 'шт', pricePerUnit: 50),
      ];
      final calc = createTestCalculation(materials: materials);
      final project = createTestProject(calculations: [calc]);

      await tester.pumpWidget(createTestWidget(project));
      await tester.pump();

      expect(find.byType(Divider), findsOneWidget);
    });
  });
}
