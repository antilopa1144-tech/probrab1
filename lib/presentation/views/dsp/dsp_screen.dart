import 'package:flutter/material.dart';
import 'project_state.dart';
import 'widgets/cement_icon.dart';
import 'widgets/geometry_widget.dart';
import 'widgets/custom_tab_selector.dart';
import 'widgets/number_input.dart';
import 'widgets/section_card.dart';
import 'widgets/results_sheet.dart';

class DspScreen extends StatefulWidget {
  const DspScreen({super.key});

  @override
  State<DspScreen> createState() => _DspScreenState();
}

class _DspScreenState extends State<DspScreen> {
  final ProjectState _state = ProjectState();
  
  // 0: Пол (Стяжка), 1: Стены (Штукатурка)
  int applicationIndex = 0; 
  
  // 0: М300 (Пескобетон), 1: М150 (Универсальная)
  int mixIndex = 0;
  
  double thickness = 40.0; // мм (стандарт для стяжки)
  double bagWeight = 40.0; // Пескобетон часто идет по 40кг или 50кг

  // Данные смесей
  final List<Map<String, dynamic>> mixes = [
    {
      'name': 'М300 (Пескобетон)',
      'desc': 'Крупная фракция. Для прочной стяжки пола.',
      'consumption': 2.0, // кг/м²/1мм (Около 20-22 кг на 1см)
    },
    {
      'name': 'М150 (Универсальная)',
      'desc': 'Мелкая фракция. Для штукатурки и кладки.',
      'consumption': 1.8, // кг/м²/1мм (Около 18 кг на 1см)
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
        final state = _state;
        // --- 1. Логика Расчета Площади ---
        final double area = applicationIndex == 0
            ? state.roomL * state.roomW
            // Если Штукатурка Стен - берем чистую площадь стен
            : state.getNetArea();

        // --- 2. Расход ---
        final mix = mixes[mixIndex];
        final double consumptionPerMm = mix['consumption']; 
        final double totalWeightKg = area * thickness * consumptionPerMm;
        final int bags = (totalWeightKg / bagWeight).ceil();
        final double totalWeightTons = totalWeightKg / 1000;

        // --- 3. Доп. материалы (Армирование и Лента) ---
        // Сетка: только для пола, с запасом 10% на нахлест
        final double meshArea = applicationIndex == 0 ? area * 1.1 : 0;
        // Лента: периметр комнаты
        final double tapeMeters = applicationIndex == 0 ? state.getPerimeter() : 0;

        // --- 4. Валидация (Предупреждение) ---
        // Стяжка тоньше 30мм из ЦПС часто трескается без спец добавок
        final bool thicknessWarning = applicationIndex == 0 && thickness < 30;

        return Scaffold(
          appBar: AppBar(
            // Используем нашу кастомную иконку рядом с заголовком
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CementIcon(size: 24, color: Theme.of(context).primaryColor),
                const SizedBox(width: 10),
                const Text('ЦПС / Стяжка'),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Общий виджет геометрии
              GeometryWidget(state: state),
              
              // Подсказка, если пользователь в режиме "Стены" пытается считать пол
              if (applicationIndex == 0 && state.mode == CalculationMode.walls)
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 8.0),
                   child: Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(8)),
                     child: Row(
                       children: [
                         Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                         const SizedBox(width: 8),
                         Expanded(child: Text('Для стяжки используются размеры пола (Длина х Ширина)', style: TextStyle(fontSize: 12, color: Colors.orange[900]))),
                       ],
                     ),
                   ),
                 ),
                 
              const SizedBox(height: 16),

              // Карточка настроек
              SectionCard(
                title: 'Параметры работ',
                icon: Icons.layers, 
                child: Column(
                  children: [
                    // Переключатель Пол/Стены
                    const Text('Тип работ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    CustomTabSelector(
                      labels: const ['Стяжка (Пол)', 'Штукатурка (Стены)'],
                      selectedIndex: applicationIndex,
                      onSelect: (i) => setState(() {
                        applicationIndex = i;
                        // Умное переключение: Пол -> М300 (40мм), Стены -> М150 (20мм)
                        mixIndex = i == 0 ? 0 : 1; 
                        thickness = i == 0 ? 40.0 : 20.0;
                      }),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Выбор смеси (Карточки с описанием)
                    const Text('Марка смеси', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: List.generate(mixes.length, (index) {
                          final bool isSelected = mixIndex == index;
                          return GestureDetector(
                            onTap: () => setState(() => mixIndex = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: Colors.grey[300]!) : Border.all(color: Colors.transparent),
                                boxShadow: isSelected ? [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 4)] : [],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(mixes[index]['name'], style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey[700])),
                                        Text(mixes[index]['desc'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
                    
                    // Инпуты (Толщина и Вес)
                    Row(
                      children: [
                        Expanded(child: NumberInput(label: 'Слой (мм)', value: thickness, onChanged: (v) => setState(() => thickness = v))),
                        const SizedBox(width: 12),
                        Expanded(child: NumberInput(label: 'Мешок (кг)', value: bagWeight, onChanged: (v) => setState(() => bagWeight = v))),
                      ],
                    ),
                    
                    // Предупреждение о толщине
                    if (thicknessWarning)
                       Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              Icon(Icons.warning, size: 16, color: Colors.red[700]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Слой <30мм для стяжки ЦПС опасен (трещины). Используйте Наливной пол.',
                                  // ignore: lines_longer_than_80_chars
                                  style: TextStyle(fontSize: 11, color: Colors.red[900], fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Итоговая смета
              ResultsSheet(
                title: 'Смета: ЦПС',
                rows: [
                  ResultRow('Площадь', '${area.toStringAsFixed(1)} м²'),
                  
                  // Вес - самое важное для ЦПС
                  ResultRow(
                    'Сухая смесь', 
                    '$bags шт', 
                    subValue: '${totalWeightTons.toStringAsFixed(2)} т', // Тонны!
                    subLabel: '${totalWeightKg.toInt()} кг (${bags}x${bagWeight.toInt()})'
                  ),
                  
                  // Специфика пола
                  if (applicationIndex == 0) ...[
                    ResultRow('Сетка армирующая', '${meshArea.ceil()} м²', subLabel: 'ячейка 100х100'),
                    ResultRow('Демпферная лента', '${tapeMeters.toStringAsFixed(1)} м', subLabel: 'по периметру'),
                    ResultRow('Маяки (10мм)', '${(area/1.5).ceil()} шт', subLabel: 'шаг 1-1.5м'),
                  ],
                  
                  // Специфика стен
                  if (applicationIndex == 1)
                    ResultRow('Грунтовка', '${(area * 0.2 / 10).ceil()} шт', subLabel: 'канистр 10л'),
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
