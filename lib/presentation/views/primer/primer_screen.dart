import 'package:flutter/material.dart';

import '../dsp/project_state.dart';
import '../dsp/widgets/custom_tab_selector.dart';
import '../dsp/widgets/geometry_widget.dart';
import '../dsp/widgets/results_sheet.dart';
import '../dsp/widgets/section_card.dart';

class PrimerScreen extends StatefulWidget {
  const PrimerScreen({super.key});

  @override
  State<PrimerScreen> createState() => _PrimerScreenState();
}

class _PrimerScreenState extends State<PrimerScreen> {
  final ProjectState _state = ProjectState();

  int typeIndex = 0;
  int layers = 1;
  double dilutionWater = 3.0; // Для концентрата: 1 часть грунта к N частям воды

  final List<Map<String, Object>> primers = const [
    {
      'name': 'Универсальная',
      'desc': 'Глубокого проникновения (обычная белая водичка). Для шпатлевки, штукатурки.',
      'consumption': 0.15, // л/м2
      'unit': 'л',
      'pack_size': 10.0, // Канистра
      'is_concentrate': false,
    },
    {
      'name': 'Концентрат',
      'desc': 'Требует разбавления водой. Выгоднее при больших объемах.',
      'consumption': 0.15, // л/м2 (готового раствора!)
      'unit': 'л',
      'pack_size': 1.0, // Бутылка 1л
      'is_concentrate': true,
    },
    {
      'name': 'Бетоноконтакт',
      'desc': 'С кварцевым песком. Только для гладкого бетона под гипсовую штукатурку.',
      'consumption': 0.35, // кг/м2
      'unit': 'кг',
      'pack_size': 15.0, // Ведро
      'is_concentrate': false,
    },
    {
      'name': 'Супер-Адгезия',
      'desc': 'Для сложных поверхностей: старая плитка, OSB, пластик, масляная краска.',
      'consumption': 0.2, // кг/м2
      'unit': 'кг',
      'pack_size': 3.0, // Маленькое ведерко
      'is_concentrate': false,
    },
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
        final area = _state.getNetArea();
        final primer = primers[typeIndex];

        final double consumption = primer['consumption'] as double;
        final bool isConcentrate = primer['is_concentrate'] as bool;
        final double packSize = primer['pack_size'] as double;
        final String unit = primer['unit'] as String;

        // 1. Расчет общего объема ГОТОВОГО раствора
        final double totalSolutionNeeded = area * layers * consumption;

        double buyAmount;
        double waterAmount = 0;

        if (isConcentrate) {
          // Пропорция 1 : N (например 1:3). Всего частей = 1 + 3 = 4.
          final double totalParts = 1 + dilutionWater;
          buyAmount = totalSolutionNeeded / totalParts; // Чистый концентрат
          waterAmount = totalSolutionNeeded - buyAmount; // Вода
        } else {
          buyAmount = totalSolutionNeeded;
        }

        final int packs = (buyAmount / packSize).ceil();

        return Scaffold(
          appBar: AppBar(title: const Text('Грунтовка')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GeometryWidget(state: _state),
              const SizedBox(height: 16),

              SectionCard(
                title: 'Тип грунта',
                icon: Icons.water_drop,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: List.generate(primers.length, (index) {
                          final bool isSelected = typeIndex == index;
                          final String name = primers[index]['name'] as String;
                          final String desc = primers[index]['desc'] as String;

                          return GestureDetector(
                            onTap: () => setState(() => typeIndex = index),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(11),
                                boxShadow: isSelected
                                    ? [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 4)]
                                    : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: const Color(0xFF2563EB),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isSelected ? const Color(0xFF2563EB) : Colors.black87,
                                          ),
                                        ),
                                        Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        const Text('Количество слоев:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTabSelector(
                            labels: const ['1 слой', '2 слоя', '3 слоя'],
                            selectedIndex: layers - 1,
                            onSelect: (i) => setState(() => layers = i + 1),
                          ),
                        ),
                      ],
                    ),

                    if (isConcentrate) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[100]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Разбавление водой (1 : ${dilutionWater.toInt()})',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 8),
                            Slider(
                              value: dilutionWater,
                              min: 1,
                              max: 9,
                              divisions: 8,
                              label: '1 : ${dilutionWater.toInt()}',
                              activeColor: const Color(0xFF2563EB),
                              onChanged: (v) => setState(() => dilutionWater = v),
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1:1 (Сильная)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                Text('1:9 (Слабая)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                              ],
                            )
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),

              ResultsSheet(
                title: 'Смета: Грунтовка',
                rows: [
                  ResultRow('Обрабатываемая площадь', '${area.toStringAsFixed(1)} м²'),
                  ResultRow(
                    isConcentrate ? 'Концентрат (Покупка)' : 'Грунтовка',
                    '${buyAmount.toStringAsFixed(1)} $unit',
                    subValue: '$packs шт',
                    subLabel: '${packSize.toStringAsFixed(packSize.truncateToDouble() == packSize ? 0 : 1)}$unit',
                  ),
                  if (isConcentrate)
                    ResultRow(
                      'Вода для смеси',
                      '${waterAmount.toStringAsFixed(1)} л',
                      subLabel: 'добавить',
                    ),
                  if (isConcentrate)
                    ResultRow(
                      'Итого раствора',
                      '${totalSolutionNeeded.toStringAsFixed(1)} л',
                      subLabel: 'готовой смеси',
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
}
