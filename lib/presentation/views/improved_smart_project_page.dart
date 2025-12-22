import 'package:flutter/material.dart';
import '../../core/localization/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Улучшенный умный мастер проектов с пошаговым интерфейсом
class ImprovedSmartProjectPage extends ConsumerStatefulWidget {
  const ImprovedSmartProjectPage({super.key});

  @override
  ConsumerState<ImprovedSmartProjectPage> createState() =>
      _ImprovedSmartProjectPageState();
}

class _ImprovedSmartProjectPageState
    extends ConsumerState<ImprovedSmartProjectPage> {
  int _currentStep = 0;

  // Размеры дома
  final _lengthController = TextEditingController(text: '10');
  final _widthController = TextEditingController(text: '8');
  final _heightController = TextEditingController(text: '3');

  // Выбранные разделы
  bool _includeFoundation = true;
  bool _includeWalls = true;
  bool _includeRoof = true;
  bool _includeFinish = true;

  // Результаты
  Map<String, double>? _results;

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculate() {
    final length = double.tryParse(_lengthController.text) ?? 10;
    final width = double.tryParse(_widthController.text) ?? 8;
    final height = double.tryParse(_heightController.text) ?? 3;

    final results = <String, double>{};

    final perimeter = 2 * (length + width);
    final area = length * width;

    // Фундамент - ленточный
    if (_includeFoundation) {
      final foundationVolume =
          perimeter * 0.4 * 0.6; // периметр * ширина 40см * высота 60см
      final concreteCost = foundationVolume * 6500; // цена бетона М300
      final rebarWeight =
          foundationVolume * 0.012 * 7850; // объём * коэф * плотность
      final rebarCost = rebarWeight * 100; // цена арматуры
      final foundationCost = concreteCost + rebarCost;
      results['Фундамент (ленточный)'] = foundationCost;
      results['  Бетон (м³)'] = foundationVolume;
      results['  Арматура (кг)'] = rebarWeight;
    }

    // Стены - газоблок
    if (_includeWalls) {
      final wallArea = perimeter * height;
      final wallVolume = wallArea * 0.3; // толщина 30см
      const blockVolume = 0.6 * 0.2 * 0.3; // размер блока
      final blocks = (wallVolume / blockVolume * 1.05).ceil(); // +5% запас
      final wallsCost = blocks * 200; // цена газоблока
      results['Стены (газоблок)'] = wallsCost.toDouble();
      results['  Блоков (шт)'] = blocks.toDouble();
      results['  Площадь стен (м²)'] = wallArea;
    }

    // Кровля - металлочерепица
    if (_includeRoof) {
      final roofArea = area * 1.3; // с учётом скатов (+30%)
      final sheets = (roofArea / 2).ceil(); // один лист = 2м²
      final materialCost = sheets * 600; // металлочерепица
      final raftersCost = roofArea * 800; // стропильная система
      final roofCost = materialCost + raftersCost;
      results['Кровля (металлочерепица)'] = roofCost;
      results['  Площадь крыши (м²)'] = roofArea;
      results['  Листов (шт)'] = sheets.toDouble();
    }

    // Отделка - черновая
    if (_includeFinish) {
      final floorArea = area;
      final wallsForFinish =
          perimeter * height * 0.7; // 70% от стен (за вычетом проёмов)
      final plasterCost = wallsForFinish * 500; // штукатурка
      final floorCost = floorArea * 1500; // стяжка + покрытие
      final paintCost = wallsForFinish * 300; // покраска

      final finishCost = plasterCost + floorCost + paintCost;
      results['Отделка (черновая)'] = finishCost;
      results['  Площадь пола (м²)'] = floorArea;
      results['  Площадь стен (м²)'] = wallsForFinish;
      // totalCost += finishCost;
    }

    // Цены временно скрыты до интеграции с магазинами
    // results['💰 ИТОГО'] = totalCost;

    setState(() {
      _results = results;
      _currentStep = 3; // Переходим к результатам
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Умный мастер проектов'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 3) {
            setState(() => _currentStep++);
          } else {
            _calculate();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        onStepTapped: (step) => setState(() => _currentStep = step),
        controlsBuilder: (context, details) {
          return Row(
            children: [
              ElevatedButton(
                onPressed: details.onStepContinue,
                child: Text(_currentStep == 2 ? 'Рассчитать' : 'Далее'),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: const Text('Назад'),
                ),
              ],
            ],
          );
        },
        steps: [
          // Шаг 1: Размеры дома
          Step(
            title: const Text('Размеры дома'),
            subtitle: const Text('Укажите основные размеры'),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                const _InfoCard(
                  icon: Icons.home,
                  title: 'Простой способ',
                  description:
                      'Измерьте рулеткой длину и ширину вашего дома или участка под дом',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lengthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Длина дома (метры)',
                    prefixIcon: Icon(Icons.straighten),
                    helperText: 'Например: 10 метров',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _widthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Ширина дома (метры)',
                    prefixIcon: Icon(Icons.straighten),
                    helperText: 'Например: 8 метров',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Высота стен (метры)',
                    prefixIcon: Icon(Icons.height),
                    helperText: 'Обычно: 2.5-3 метра',
                  ),
                ),
              ],
            ),
          ),

          // Шаг 2: Выбор разделов
          Step(
            title: const Text('Что строим?'),
            subtitle: const Text('Выберите разделы'),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                const _InfoCard(
                  icon: Icons.construction,
                  title: 'Что включить?',
                  description:
                      'Отметьте галочками что нужно построить. Всё остальное рассчитается автоматически!',
                ),
                const SizedBox(height: 16),
                _SectionCheckbox(
                  value: _includeFoundation,
                  title: 'Фундамент',
                  subtitle: 'Ленточный фундамент из бетона М300',
                  icon: Icons.foundation,
                  onChanged: (v) =>
                      setState(() => _includeFoundation = v ?? false),
                ),
                _SectionCheckbox(
                  value: _includeWalls,
                  title: 'Стены',
                  subtitle: 'Газоблок 300мм',
                  icon: Icons.view_column,
                  onChanged: (v) => setState(() => _includeWalls = v ?? false),
                ),
                _SectionCheckbox(
                  value: _includeRoof,
                  title: 'Кровля',
                  subtitle: 'Металлочерепица со стропилами',
                  icon: Icons.roofing,
                  onChanged: (v) => setState(() => _includeRoof = v ?? false),
                ),
                _SectionCheckbox(
                  value: _includeFinish,
                  title: 'Отделка',
                  subtitle: 'Черновая отделка (штукатурка, стяжка)',
                  icon: Icons.format_paint,
                  onChanged: (v) => setState(() => _includeFinish = v ?? false),
                ),
              ],
            ),
          ),

          // Шаг 3: Подтверждение
          Step(
            title: const Text('Проверка'),
            subtitle: const Text('Всё правильно?'),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Проверьте параметры перед расчётом:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  icon: Icons.home,
                  label: 'Размеры дома',
                  value:
                      '${_lengthController.text}м × ${_widthController.text}м × ${_heightController.text}м',
                ),
                const Divider(),
                _SummaryRow(
                  icon: Icons.foundation,
                  label: 'Фундамент',
                  value: _includeFoundation ? 'Да' : 'Нет',
                  enabled: _includeFoundation,
                ),
                _SummaryRow(
                  icon: Icons.view_column,
                  label: 'Стены',
                  value: _includeWalls ? 'Да' : 'Нет',
                  enabled: _includeWalls,
                ),
                _SummaryRow(
                  icon: Icons.roofing,
                  label: 'Кровля',
                  value: _includeRoof ? 'Да' : 'Нет',
                  enabled: _includeRoof,
                ),
                _SummaryRow(
                  icon: Icons.format_paint,
                  label: 'Отделка',
                  value: _includeFinish ? 'Да' : 'Нет',
                  enabled: _includeFinish,
                ),
              ],
            ),
          ),

          // Шаг 4: Результаты
          Step(
            title: const Text('Результаты'),
            subtitle: const Text('Смета проекта'),
            isActive: _currentStep >= 3,
            state: _results != null ? StepState.complete : StepState.indexed,
            content: _results == null
                ? Text(
                    AppLocalizations.of(context)
                        .translate('smart_project.press_calculate_hint'),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Расчёт готов!',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    'Ниже подробная смета вашего проекта',
                                    style: TextStyle(
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      ..._results!.entries.map((e) {
                        final isSubItem = e.key.startsWith('  ');

                        // Цены временно скрыты до интеграции с магазинами
                        // if (isTotal) {
                        //   return Container(
                        //     margin: const EdgeInsets.only(top: 16),
                        //     padding: const EdgeInsets.all(20),
                        //     decoration: BoxDecoration(
                        //       color: Theme.of(
                        //         context,
                        //       ).colorScheme.primary.withValues(alpha: 0.2),
                        //       borderRadius: BorderRadius.circular(12),
                        //       border: Border.all(
                        //         color: Theme.of(context).colorScheme.primary,
                        //         width: 2,
                        //       ),
                        //     ),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //       children: [
                        //         const Text(
                        //           'ИТОГО:',
                        //           style: TextStyle(
                        //             fontSize: 22,
                        //             fontWeight: FontWeight.bold,
                        //           ),
                        //         ),
                        //         Text(
                        //           '${e.value.toStringAsFixed(0)} ₽',
                        //           style: TextStyle(
                        //             fontSize: 26,
                        //             fontWeight: FontWeight.bold,
                        //             color: Theme.of(
                        //               context,
                        //             ).colorScheme.primary,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   );
                        // }

                        // Скрыть элементы с ценами (все основные разделы кроме подпунктов с единицами измерения)
                        final isCostItem = !isSubItem && !e.key.contains('Площадь') &&
                                          !e.key.contains('Блоков') && !e.key.contains('Листов') &&
                                          !e.key.contains('Бетон') && !e.key.contains('Арматура');
                        if (isCostItem) {
                          return const SizedBox.shrink(); // Скрыть элемент с ценой
                        }

                        return Padding(
                          padding: EdgeInsets.only(
                            left: isSubItem ? 24 : 0,
                            bottom: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: isSubItem ? 14 : 16,
                                    fontWeight: isSubItem
                                        ? FontWeight.normal
                                        : FontWeight.bold,
                                    color: isSubItem
                                        ? Colors.grey.shade400
                                        : null,
                                  ),
                                ),
                              ),
                              Text(
                                e.value.toStringAsFixed(0),
                                style: TextStyle(
                                  fontSize: isSubItem ? 14 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: isSubItem
                                      ? Colors.grey.shade400
                                      : Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _results = null;
                            _currentStep = 0;
                          });
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Новый расчёт'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCheckbox extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<bool?> onChanged;

  const _SectionCheckbox({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        secondary: CircleAvatar(
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.2),
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool enabled;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled
                ? Theme.of(context).colorScheme.primary
                : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: enabled ? null : Colors.grey,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: enabled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
