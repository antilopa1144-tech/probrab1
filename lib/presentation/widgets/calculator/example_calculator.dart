/// ПРИМЕР КАЛЬКУЛЯТОРА С ИСПОЛЬЗОВАНИЕМ ДИЗАЙН-СИСТЕМЫ
///
/// Этот файл демонстрирует, как создать калькулятор используя все компоненты
/// дизайн-системы. Используйте его как шаблон для новых калькуляторов.
///
/// ВАЖНО: Этот файл создан только для демонстрации и не используется в приложении!
library;

import 'package:flutter/material.dart';
import 'calculator_widgets.dart';

/// Пример калькулятора покраски стен
class ExamplePaintCalculatorScreen extends StatefulWidget {
  const ExamplePaintCalculatorScreen({super.key});

  @override
  State<ExamplePaintCalculatorScreen> createState() =>
      _ExamplePaintCalculatorScreenState();
}

class _ExamplePaintCalculatorScreenState
    extends State<ExamplePaintCalculatorScreen> {
  // === СОСТОЯНИЕ ===

  // Режим ввода: 0 = Комната, 1 = Список стен
  int _mode = 0;

  // Тип краски: 0 = Интерьер, 1 = Фасад
  int _paintType = 0;

  // Размеры комнаты
  double _length = 4.0;
  double _width = 3.0;
  double _height = 2.7;

  // Параметры покраски
  double _coverage = 10.0; // м²/л
  int _layers = 2;

  // Результаты
  double _area = 0;
  double _liters = 0;
  int _cans = 0;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  // === РАСЧЁТ ===

  void _calculate() {
    setState(() {
      // Площадь стен
      final perimeter = (_length + _width) * 2;
      _area = perimeter * _height;

      // Расход краски
      _liters = (_area * _layers) / _coverage;

      // Количество банок (9л для интерьера, 10л для фасада)
      final canSize = _paintType == 0 ? 9 : 10;
      _cans = (_liters / canSize).ceil();
    });
  }

  // === UI ===

  @override
  Widget build(BuildContext context) {
    // Акцентный цвет по категории
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: 'Покраска стен (пример)',
      accentColor: accentColor,

      // === HEADER С РЕЗУЛЬТАТАМИ ===
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: 'ПЛОЩАДЬ',
            value: '${_area.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: 'КРАСКА',
            value: '${_liters.toStringAsFixed(1)} л',
            icon: Icons.format_paint,
          ),
          ResultItem(
            label: 'БАНКИ',
            value: '$_cans шт',
            icon: Icons.shopping_bag,
          ),
        ],
      ),

      // === ТЕЛО ЭКРАНА ===
      children: [
        // 1. Выбор типа краски (визуальные карточки)
        TypeSelectorGroup(
          options: const [
            TypeSelectorOption(
              icon: Icons.home,
              title: 'Интерьер',
              subtitle: '10 м²/л',
            ),
            TypeSelectorOption(
              icon: Icons.apartment,
              title: 'Фасад',
              subtitle: '7 м²/л',
            ),
          ],
          selectedIndex: _paintType,
          onSelect: (index) {
            setState(() {
              _paintType = index;
              _coverage = index == 0 ? 10.0 : 7.0;
            });
            _calculate();
          },
          accentColor: accentColor,
        ),

        CalculatorDesignSystem.verticalSpacingM,

        // 2. Переключатель режима ввода (табы)
        ModeSelector(
          options: const ['Комната', 'Список стен'],
          selectedIndex: _mode,
          onSelect: (index) {
            setState(() => _mode = index);
          },
          accentColor: accentColor,
        ),

        CalculatorDesignSystem.verticalSpacingM,

        // 3. Группа полей "Геометрия" (с цветным фоном)
        InputGroupColored(
          title: 'Геометрия комнаты',
          icon: Icons.straighten,
          accentColor: accentColor,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: CalculatorDesignSystem.inputDecoration(
                      label: 'Длина (м)',
                      fillColor: Colors.white,
                    ),
                    controller: TextEditingController(
                      text: _length.toStringAsFixed(1),
                    ),
                    onChanged: (value) {
                      _length = double.tryParse(value) ?? 0;
                      _calculate();
                    },
                  ),
                ),
                CalculatorDesignSystem.horizontalSpacingM,
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: CalculatorDesignSystem.inputDecoration(
                      label: 'Ширина (м)',
                      fillColor: Colors.white,
                    ),
                    controller: TextEditingController(
                      text: _width.toStringAsFixed(1),
                    ),
                    onChanged: (value) {
                      _width = double.tryParse(value) ?? 0;
                      _calculate();
                    },
                  ),
                ),
              ],
            ),
            TextField(
              keyboardType: TextInputType.number,
              decoration: CalculatorDesignSystem.inputDecoration(
                label: 'Высота потолка (м)',
                fillColor: Colors.white,
              ),
              controller: TextEditingController(
                text: _height.toStringAsFixed(1),
              ),
              onChanged: (value) {
                _height = double.tryParse(value) ?? 0;
                _calculate();
              },
            ),
          ],
        ),

        CalculatorDesignSystem.verticalSpacingM,

        // 4. Группа полей "Параметры" (обычная с тенью)
        InputGroup(
          title: 'Параметры покраски',
          icon: Icons.settings,
          accentColor: accentColor,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: CalculatorDesignSystem.inputDecoration(
                      label: 'Расход (м²/л)',
                    ),
                    controller: TextEditingController(
                      text: _coverage.toStringAsFixed(1),
                    ),
                    onChanged: (value) {
                      _coverage = double.tryParse(value) ?? 10;
                      _calculate();
                    },
                  ),
                ),
                CalculatorDesignSystem.horizontalSpacingM,
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: CalculatorDesignSystem.inputDecoration(
                      label: 'Слои',
                    ),
                    controller: TextEditingController(
                      text: _layers.toString(),
                    ),
                    onChanged: (value) {
                      _layers = int.tryParse(value) ?? 2;
                      _calculate();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        CalculatorDesignSystem.verticalSpacingM,

        // 5. Collapsible группа "Дополнительно"
        InputGroup(
          title: 'Дополнительные материалы',
          icon: Icons.add_shopping_cart,
          accentColor: accentColor,
          isCollapsible: true,
          initiallyExpanded: false,
          children: [
            // Расчёт малярного скотча, грунтовки и т.д.
            const Text('Малярный скотч: 2 рулона'),
            CalculatorDesignSystem.divider(),
            const Text('Грунтовка: 5 л'),
            CalculatorDesignSystem.divider(),
            const Text('Валики и кисти: 1 комплект'),
          ],
        ),

        CalculatorDesignSystem.verticalSpacingXL,

        // 6. Итоговая информация (пример использования карточки)
        Container(
          padding: CalculatorDesignSystem.cardPadding,
          decoration: CalculatorDesignSystem.cardDecoration(
            color: CalculatorColors.resultCardBackground,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: CalculatorColors.interior),
                  CalculatorDesignSystem.horizontalSpacingS,
                  Text(
                    'Итого к покупке',
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              CalculatorDesignSystem.divider(color: Colors.white24),
              _buildResultRow('Краска', '$_cans банок по ${_paintType == 0 ? 9 : 10}л'),
              _buildResultRow('Грунтовка', '1 канистра 10л'),
              _buildResultRow('Малярный скотч', '2 рулона по 50м'),
              CalculatorDesignSystem.divider(color: Colors.white24),
              _buildResultRow(
                'Ориентировочная стоимость',
                '${_cans * 1500 + 500 + 400} ₽',
                isTotal: true,
              ),
            ],
          ),
        ),

        // Дополнительный отступ снизу
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildResultRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: CalculatorDesignSystem.bodyMedium.copyWith(
              color: isTotal ? Colors.white : Colors.white70,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: CalculatorDesignSystem.bodyMedium.copyWith(
              color: isTotal ? CalculatorColors.interior : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
