import 'package:flutter/material.dart';
import '../dsp/project_state.dart';
import '../dsp/widgets/custom_tab_selector.dart';
import '../dsp/widgets/geometry_widget.dart';
import '../dsp/widgets/number_input.dart';
import '../dsp/widgets/results_sheet.dart';
import '../dsp/widgets/section_card.dart';

/// Экран расчета краски (Интерьер/Фасад) по образцу HTML-калькулятора
class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  final ProjectState _state = ProjectState();

  // 0: Интерьер, 1: Фасад
  int paintType = 0;

  // Индекс типа поверхности
  int surfaceIndex = 0;

  // Параметры
  double coverage = 10.0; // м²/л (по умолчанию для интерьера)
  int layers = 2;

  // Данные типов поверхностей
  final List<List<Map<String, dynamic>>> surfaces = [
    // Интерьер
    [
      {'name': 'Гладкая (х1.0)', 'factor': 1.0},
      {'name': 'Обои (х1.2)', 'factor': 1.2},
      {'name': 'Фактурная (х1.4)', 'factor': 1.4},
    ],
    // Фасад
    [
      {'name': 'Бетон (х1.0)', 'factor': 1.0},
      {'name': 'Кирпич (х1.15)', 'factor': 1.15},
      {'name': 'Короед (х1.4)', 'factor': 1.4},
    ],
  ];

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  // Обновление параметров при переключении типа краски
  void _onPaintTypeChanged(int newType) {
    setState(() {
      paintType = newType;
      surfaceIndex = 0;
      // Меняем стандартный расход: интерьер = 10, фасад = 7
      coverage = newType == 0 ? 10.0 : 7.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, child) {
        final netArea = _state.getNetArea();
        final perimeter = _state.getPerimeter();

        final surface = surfaces[paintType][surfaceIndex];
        final factor = surface['factor'] as double;

        // Расчет краски
        final liters = (netArea * layers * factor) / coverage;

        // Размер банок: интерьер = 9л, фасад = 10л
        final canSize = paintType == 0 ? 9 : 10;
        final cans = (liters / canSize).ceil();

        // Малярный скотч: периметр х 2 (обвод плинтуса и потолка) / 50м рулон
        final tape = ((perimeter * 2) / 50).ceil();

        // Предупреждение для короеда на фасаде
        final showWarning = paintType == 1 && surfaceIndex == 2;

        return Scaffold(
          appBar: AppBar(
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.format_paint_rounded),
                SizedBox(width: 10),
                Text('Покраска'),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Геометрия
              GeometryWidget(state: _state),
              const SizedBox(height: 16),

              // Параметры
              SectionCard(
                title: 'Параметры',
                icon: Icons.format_paint_rounded,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Тип краски',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTabSelector(
                      labels: const ['Интерьер', 'Фасад'],
                      selectedIndex: paintType,
                      onSelect: _onPaintTypeChanged,
                    ),
                    const SizedBox(height: 16),

                    // Выбор поверхности
                    const Text(
                      'Поверхность',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildSurfaceDropdown(),
                    const SizedBox(height: 16),

                    // Расход и Слои
                    Row(
                      children: [
                        Expanded(
                          child: NumberInput(
                            label: 'Расход (м²/л)',
                            value: coverage,
                            onChanged: (v) => setState(() => coverage = v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: NumberInput(
                            label: 'Слоев',
                            value: layers.toDouble(),
                            onChanged: (v) =>
                                setState(() => layers = v.toInt().clamp(1, 5)),
                          ),
                        ),
                      ],
                    ),

                    // Предупреждение для Короеда
                    if (showWarning)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_rounded,
                                  size: 20, color: Colors.orange[800]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Расход увеличен на 40% (Короед)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange[900],
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

              // Результаты
              const SizedBox(height: 16),
              ResultsSheet(
                title: 'Смета: Краска',
                rows: [
                  ResultRow('Площадь', '${netArea.toStringAsFixed(1)} м²'),
                  ResultRow(
                    'Краска',
                    '${liters.toStringAsFixed(1)} л',
                    subLabel: '$layers слоя, ${factor}x',
                  ),
                  ResultRow(
                    'Банки',
                    '$cans шт',
                    subLabel: 'по $canSize''л',
                  ),
                  ResultRow(
                    'Скотч',
                    '$tape шт',
                    subLabel: 'рулонов 50м',
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

  Widget _buildSurfaceDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentSurfaces = surfaces[paintType];

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
        children: List.generate(currentSurfaces.length, (index) {
          final isSelected = surfaceIndex == index;
          final surface = currentSurfaces[index];

          return GestureDetector(
            onTap: () => setState(() => surfaceIndex = index),
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
                    surface['name'],
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
