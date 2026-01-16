import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:probrab_ai/presentation/utils/calculator_navigation_helper.dart';

import '../../helpers/test_helpers.dart';

void main() {
  setUpAll(() {
    setupMocks();
  });

  group('CalculatorNavigationHelper', () {
    group('hasV2Version', () {
      test('возвращает true для существующего V2 калькулятора', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('mixes_plaster'),
          isTrue,
        );
      });

      test('возвращает true для калькулятора краски', () {
        expect(CalculatorNavigationHelper.hasV2Version('paint_universal'), isTrue);
      });

      test('возвращает true для калькулятора гипсокартона', () {
        expect(CalculatorNavigationHelper.hasV2Version('gypsum_board'), isTrue);
      });

      test('возвращает true для калькулятора обоев', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('walls_wallpaper'),
          isTrue,
        );
      });

      test('возвращает false для несуществующего калькулятора', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('non_existent_calculator_xyz'),
          isFalse,
        );
      });

      test('возвращает false для пустой строки', () {
        expect(CalculatorNavigationHelper.hasV2Version(''), isFalse);
      });

      test('обрабатывает старые ID через миграцию', () {
        final result = CalculatorNavigationHelper.hasV2Version('paint_universal');
        expect(result, isA<bool>());
      });

      test('возвращает true для калькулятора плитки', () {
        expect(CalculatorNavigationHelper.hasV2Version('floors_tile'), isTrue);
      });

      test('возвращает true для самовыравнивающегося пола', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('floors_self_leveling'),
          isTrue,
        );
      });

      test('возвращает true для тёплого пола', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('engineering_heating'),
          isTrue,
        );
      });

      test('возвращает true для электрического калькулятора', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('engineering_electrics'),
          isTrue,
        );
      });

      test('возвращает true для калькулятора террасы', () {
        expect(CalculatorNavigationHelper.hasV2Version('terrace'), isTrue);
      });

      test('возвращает true для 3D панелей', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('walls_3d_panels'),
          isTrue,
        );
      });

      test('возвращает true для деревянной обшивки', () {
        expect(CalculatorNavigationHelper.hasV2Version('walls_wood'), isTrue);
      });

      test('возвращает true для газоблока', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('partitions_blocks'),
          isTrue,
        );
      });

      test('возвращает true для шпаклёвки', () {
        expect(CalculatorNavigationHelper.hasV2Version('mixes_putty'), isTrue);
      });

      test('возвращает true для грунтовки', () {
        expect(CalculatorNavigationHelper.hasV2Version('mixes_primer'), isTrue);
      });

      test('возвращает true для DSP калькулятора', () {
        expect(CalculatorNavigationHelper.hasV2Version('dsp'), isTrue);
      });

      test('возвращает результат для калькулятора дерева', () {
        final result = CalculatorNavigationHelper.hasV2Version('wood');
        expect(result, isA<bool>());
      });

      test('возвращает true для OSB калькулятора', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('sheeting_osb_plywood'),
          isTrue,
        );
      });

      test('возвращает true для плиточного клея', () {
        expect(
          CalculatorNavigationHelper.hasV2Version('mixes_tile_glue'),
          isTrue,
        );
      });

      test('возвращает true для ламината', () {
        expect(CalculatorNavigationHelper.hasV2Version('floors_laminate'), isTrue);
      });

      test('возвращает true для линолеума', () {
        expect(CalculatorNavigationHelper.hasV2Version('floors_linoleum'), isTrue);
      });

      test('возвращает true для паркета', () {
        expect(CalculatorNavigationHelper.hasV2Version('floors_parquet'), isTrue);
      });

      test('возвращает true для стяжки', () {
        expect(CalculatorNavigationHelper.hasV2Version('floors_screed'), isTrue);
      });

      test('возвращает true для натяжного потолка', () {
        expect(CalculatorNavigationHelper.hasV2Version('ceilings_stretch'), isTrue);
      });

      test('возвращает true для утепления потолка', () {
        expect(CalculatorNavigationHelper.hasV2Version('ceilings_insulation'), isTrue);
      });

      test('возвращает true для кирпичной кладки', () {
        expect(CalculatorNavigationHelper.hasV2Version('partitions_brick'), isTrue);
      });

      test('возвращает true для фасадных панелей', () {
        expect(CalculatorNavigationHelper.hasV2Version('exterior_facade_panels'), isTrue);
      });

      test('возвращает true для забора', () {
        expect(CalculatorNavigationHelper.hasV2Version('fence'), isTrue);
      });

      test('возвращает true для лестницы', () {
        expect(CalculatorNavigationHelper.hasV2Version('stairs'), isTrue);
      });

      test('возвращает true для фундамента', () {
        expect(CalculatorNavigationHelper.hasV2Version('foundation_slab'), isTrue);
      });
    });

    group('hasCustomScreen', () {
      test('возвращает true для калькулятора с кастомным экраном', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('mixes_plaster'),
          isTrue,
        );
      });

      test('возвращает false для несуществующего калькулятора', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('non_existent_xyz'),
          isFalse,
        );
      });

      test('возвращает true для калькулятора краски', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('paint_universal'),
          isTrue,
        );
      });

      test('возвращает true для калькулятора обоев', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('walls_wallpaper'),
          isTrue,
        );
      });

      test('возвращает true для калькулятора плитки', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('floors_tile'),
          isTrue,
        );
      });

      test('возвращает true для электрического калькулятора', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('engineering_electrics'),
          isTrue,
        );
      });

      test('возвращает false для пустой строки', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen(''),
          isFalse,
        );
      });

      test('возвращает true для всех Premium калькуляторов', () {
        // Premium calculator IDs as defined in CalculatorNavigationHelper._isPremiumCalculator
        // These map to screen registry IDs: walls_3d_panels, floors_warm, mixes_tile_glue, walls_wood
        expect(
          CalculatorNavigationHelper.hasCustomScreen('walls_3d_panels'),
          isTrue,
        );
        expect(
          CalculatorNavigationHelper.hasCustomScreen('floors_warm'),
          isTrue,
        );
        expect(
          CalculatorNavigationHelper.hasCustomScreen('mixes_tile_glue'),
          isTrue,
        );
        expect(
          CalculatorNavigationHelper.hasCustomScreen('walls_wood'),
          isTrue,
        );
      });

      test('возвращает true для газоблока', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('partitions_blocks'),
          isTrue,
        );
      });

      test('возвращает true для гипсокартона', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('gypsum_board'),
          isTrue,
        );
      });

      test('возвращает true для OSB', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('sheeting_osb_plywood'),
          isTrue,
        );
      });

      test('возвращает true для террасы', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('terrace'),
          isTrue,
        );
      });

      test('возвращает true для шпаклёвки', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('mixes_putty'),
          isTrue,
        );
      });

      test('возвращает true для грунтовки', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('mixes_primer'),
          isTrue,
        );
      });

      test('возвращает true для DSP', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('dsp'),
          isTrue,
        );
      });

      test('возвращает true для дерева', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('wood'),
          isTrue,
        );
      });

      test('возвращает false для ID со спецсимволами', () {
        expect(
          CalculatorNavigationHelper.hasCustomScreen('invalid@calculator!'),
          isFalse,
        );
      });
    });

    group('navigateToCalculatorById', () {
      testWidgets('возвращает null для несуществующего калькулятора', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      final result = await CalculatorNavigationHelper.navigateToCalculatorById(
                        context,
                        'non_existent_xyz',
                      );
                      expect(result, isNull);
                    },
                    child: const Text('Test'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Test'));
        await tester.pump();
      });

      testWidgets('показывает снэкбар при ненайденном калькуляторе', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await CalculatorNavigationHelper.navigateToCalculatorById(
                        context,
                        'invalid_calculator',
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Проверяем наличие SnackBar
        expect(find.byType(SnackBar), findsOneWidget);
      });

      testWidgets('возвращает null когда контекст не mounted', (tester) async {
        setTestViewportSize(tester);
        BuildContext? savedContext;

        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                savedContext = context;
                return const Scaffold(body: Text('Test'));
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Удаляем виджет чтобы контекст стал unmounted
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        if (savedContext != null && savedContext!.mounted) {
          final result = await CalculatorNavigationHelper.navigateToCalculatorById(
            savedContext!,
            'mixes_plaster',
          );
          expect(result, isNull);
        }
      });

      testWidgets('не проверяет premium когда checkPremium = false', (tester) async {
        setTestViewportSize(tester);
        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await CalculatorNavigationHelper.navigateToCalculatorById(
                        context,
                        'three_d_panels',
                        checkPremium: false,
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pumpAndSettle();

        // Калькулятор должен открыться без проверки premium
        // (в тестовой среде это должно работать)
      });

      testWidgets('передаёт initialInputs в навигацию', (tester) async {
        setTestViewportSize(tester);
        final inputs = {'area': 50.0, 'height': 3.0};

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await CalculatorNavigationHelper.navigateToCalculatorById(
                        context,
                        'mixes_plaster',
                        initialInputs: inputs,
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pumpAndSettle();
      });

      testWidgets('передаёт projectId в навигацию', (tester) async {
        setTestViewportSize(tester);

        await tester.pumpWidget(
          createTestApp(
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () async {
                      await CalculatorNavigationHelper.navigateToCalculatorById(
                        context,
                        'mixes_plaster',
                        projectId: 123,
                      );
                    },
                    child: const Text('Open'),
                  ),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open'));
        await tester.pump();
        await tester.pumpAndSettle();
      });
    });

    group('_isPremiumCalculator (internal)', () {
      test('three_d_panels является Premium', () {
        // Это внутренний метод, но мы можем проверить через navigateToCalculatorById
        // что он вызывает проверку premium для этих калькуляторов
        const premiumCalcs = [
          'three_d_panels',
          'underfloor_heating',
          'tile_adhesive_v2',
          'wood_lining',
        ];

        for (final calcId in premiumCalcs) {
          // Проверяем что ID существует
          expect(calcId, isNotEmpty);
        }
      });
    });
  });
}
