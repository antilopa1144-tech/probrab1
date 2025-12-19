import 'package:flutter/material.dart';
import '../dsp/project_state.dart';
import '../dsp/widgets/custom_tab_selector.dart';
import '../dsp/widgets/geometry_widget.dart';
import '../dsp/widgets/number_input.dart';
import '../dsp/widgets/results_sheet.dart';
import '../dsp/widgets/section_card.dart';

/// Экран расчета материалов для дерева (антисептик, краска, лак, масло)
class WoodScreen extends StatefulWidget {
  const WoodScreen({super.key});

  @override
  State<WoodScreen> createState() => _WoodScreenState();
}

class _WoodScreenState extends State<WoodScreen> {
  final ProjectState _state = ProjectState();

  // 0: Антисептик, 1: Краска, 2: Лак, 3: Масло
  int materialIndex = 0;

  // 0: Водная, 1: Алкидная
  int baseIndex = 0;

  // 0: Строганое (гладкое), 1: Пиленое (шероховатое)
  int textureIndex = 0;

  int layers = 2;

  // Данные материалов
  final List<Map<String, dynamic>> materials = [
    {'name': 'Антисептик', 'coverage': 7.0, 'canSize': 10.0},
    {'name': 'Краска', 'coverage': 10.0, 'canSize': 2.7},
    {'name': 'Лак', 'coverage': 12.0, 'canSize': 2.5},
    {'name': 'Масло', 'coverage': 15.0, 'canSize': 1.0},
  ];

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, child) {
        final netArea = _state.getNetArea();

        // Фактор текстуры: пиленое дерево впитывает в 1.6 раза больше
        final textureFactor = textureIndex == 0 ? 1.0 : 1.6;

        final material = materials[materialIndex];
        final baseCoverage = material['coverage'] as double;

        // Водная основа на пиленом дереве расходует больше (-1 к покрытию)
        final coverage = (baseIndex == 0 && textureIndex == 1)
            ? baseCoverage - 1
            : baseCoverage;

        // Расчет
        final liters = (netArea * layers * textureFactor) / coverage;
        final canSize = material['canSize'] as double;
        final cans = (liters / canSize).ceil();

        // Предупреждение
        final showWarning = textureIndex == 1;

        // Советы по инструментам
        final brushType = baseIndex == 0 ? 'Синтетика (для воды)' : 'Натуральная щетина';
        final cleanMethod = baseIndex == 0 ? 'Вода' : 'Уайт-спирит';

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.forest_rounded),
                SizedBox(width: 10),
                Text('Дерево'),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Геометрия
              GeometryWidget(state: _state),
              const SizedBox(height: 16),

              // Материал
              SectionCard(
                title: 'Материал',
                icon: Icons.forest_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Чем покрываем?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildMaterialDropdown(),
                    const SizedBox(height: 16),

                    // Основа
                    const Text(
                      'Основа',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTabSelector(
                      labels: const ['Водная', 'Алкидная'],
                      selectedIndex: baseIndex,
                      onSelect: (i) => setState(() => baseIndex = i),
                    ),
                    const SizedBox(height: 16),

                    // Текстура дерева
                    const Text(
                      'Текстура дерева',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTabSelector(
                      labels: const ['Строганое', 'Пиленое'],
                      selectedIndex: textureIndex,
                      onSelect: (i) => setState(() => textureIndex = i),
                    ),
                    const SizedBox(height: 16),

                    // Слои
                    NumberInput(
                      label: 'Слоев',
                      value: layers.toDouble(),
                      onChanged: (v) =>
                          setState(() => layers = v.toInt().clamp(1, 5)),
                    ),

                    // Предупреждение для пиленого дерева
                    if (showWarning)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_rounded,
                                  size: 20, color: Colors.amber[800]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Пиленая доска впитывает в 1.6 раза больше!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.amber[900],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Советы
              SectionCard(
                title: 'Советы',
                icon: Icons.brush_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Кисть: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          brushType,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Очистка: ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          cleanMethod,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Результаты
              ResultsSheet(
                title: 'Смета: Дерево',
                rows: [
                  ResultRow('Площадь', '${netArea.toStringAsFixed(1)} м²'),
                  ResultRow(
                    material['name'],
                    '${liters.toStringAsFixed(1)} л',
                    subLabel: 'расход $coverage м²/л',
                  ),
                  ResultRow(
                    'Банки',
                    '$cans шт',
                    subLabel: 'по $canSize''л',
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? const Color(0xFF475569)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: List.generate(materials.length, (index) {
          final isSelected = materialIndex == index;
          final material = materials[index];

          return GestureDetector(
            onTap: () => setState(() => materialIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF475569) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    material['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark ? Colors.white : Colors.black87)
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
