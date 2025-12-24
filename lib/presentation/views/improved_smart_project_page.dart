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

  static const String _resultFoundationKey =
      'smart_project.result.foundation.title';
  static const String _resultFoundationConcreteKey =
      'smart_project.result.foundation.concrete_volume';
  static const String _resultFoundationRebarKey =
      'smart_project.result.foundation.rebar_weight';
  static const String _resultWallsKey = 'smart_project.result.walls.title';
  static const String _resultWallsBlocksKey =
      'smart_project.result.walls.blocks_count';
  static const String _resultWallsAreaKey = 'smart_project.result.walls.area';
  static const String _resultRoofKey = 'smart_project.result.roof.title';
  static const String _resultRoofAreaKey = 'smart_project.result.roof.area';
  static const String _resultRoofSheetsKey =
      'smart_project.result.roof.sheets_count';
  static const String _resultFinishKey = 'smart_project.result.finish.title';
  static const String _resultFinishFloorKey =
      'smart_project.result.finish.floor_area';
  static const String _resultFinishWallKey =
      'smart_project.result.finish.wall_area';

  static const Set<String> _resultSubItemKeys = {
    _resultFoundationConcreteKey,
    _resultFoundationRebarKey,
    _resultWallsBlocksKey,
    _resultWallsAreaKey,
    _resultRoofAreaKey,
    _resultRoofSheetsKey,
    _resultFinishFloorKey,
    _resultFinishWallKey,
  };

  static const Set<String> _resultCostItemKeys = {
    _resultFoundationKey,
    _resultWallsKey,
    _resultRoofKey,
    _resultFinishKey,
  };

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
      results[_resultFoundationKey] = foundationCost;
      results[_resultFoundationConcreteKey] = foundationVolume;
      results[_resultFoundationRebarKey] = rebarWeight;
    }

    // Стены - газоблок
    if (_includeWalls) {
      final wallArea = perimeter * height;
      final wallVolume = wallArea * 0.3; // толщина 30см
      const blockVolume = 0.6 * 0.2 * 0.3; // размер блока
      final blocks = (wallVolume / blockVolume * 1.05).ceil(); // +5% запас
      final wallsCost = blocks * 200; // цена газоблока
      results[_resultWallsKey] = wallsCost.toDouble();
      results[_resultWallsBlocksKey] = blocks.toDouble();
      results[_resultWallsAreaKey] = wallArea;
    }

    // Кровля - металлочерепица
    if (_includeRoof) {
      final roofArea = area * 1.3; // с учётом скатов (+30%)
      final sheets = (roofArea / 2).ceil(); // один лист = 2м²
      final materialCost = sheets * 600; // металлочерепица
      final raftersCost = roofArea * 800; // стропильная система
      final roofCost = materialCost + raftersCost;
      results[_resultRoofKey] = roofCost;
      results[_resultRoofAreaKey] = roofArea;
      results[_resultRoofSheetsKey] = sheets.toDouble();
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
      results[_resultFinishKey] = finishCost;
      results[_resultFinishFloorKey] = floorArea;
      results[_resultFinishWallKey] = wallsForFinish;
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
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('smart_project.title')),
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
                child: Text(
                  _currentStep == 2
                      ? loc.translate('button.calculate')
                      : loc.translate('button.next'),
                ),
              ),
              if (_currentStep > 0) ...[
                const SizedBox(width: 12),
                TextButton(
                  onPressed: details.onStepCancel,
                  child: Text(loc.translate('button.back')),
                ),
              ],
            ],
          );
        },
        steps: [
          // Шаг 1: Размеры дома
          Step(
            title: Text(loc.translate('smart_project.step.dimensions.title')),
            subtitle:
                Text(loc.translate('smart_project.step.dimensions.subtitle')),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                _InfoCard(
                  icon: Icons.home,
                  title:
                      loc.translate('smart_project.step.dimensions.info.title'),
                  description: loc.translate(
                    'smart_project.step.dimensions.info.description',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _lengthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.translate(
                      'smart_project.step.dimensions.length.label',
                    ),
                    prefixIcon: const Icon(Icons.straighten),
                    helperText: loc.translate(
                      'smart_project.step.dimensions.length.helper',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _widthController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.translate(
                      'smart_project.step.dimensions.width.label',
                    ),
                    prefixIcon: const Icon(Icons.straighten),
                    helperText: loc.translate(
                      'smart_project.step.dimensions.width.helper',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _heightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: loc.translate(
                      'smart_project.step.dimensions.height.label',
                    ),
                    prefixIcon: const Icon(Icons.height),
                    helperText: loc.translate(
                      'smart_project.step.dimensions.height.helper',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Шаг 2: Выбор разделов
          Step(
            title: Text(loc.translate('smart_project.step.sections.title')),
            subtitle: Text(loc.translate('smart_project.step.sections.subtitle')),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                _InfoCard(
                  icon: Icons.construction,
                  title: loc.translate('smart_project.step.sections.info.title'),
                  description: loc.translate(
                    'smart_project.step.sections.info.description',
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCheckbox(
                  value: _includeFoundation,
                  title: loc.translate('smart_project.section.foundation.title'),
                  subtitle: loc.translate(
                    'smart_project.section.foundation.subtitle',
                  ),
                  icon: Icons.foundation,
                  onChanged: (v) =>
                      setState(() => _includeFoundation = v ?? false),
                ),
                _SectionCheckbox(
                  value: _includeWalls,
                  title: loc.translate('smart_project.section.walls.title'),
                  subtitle:
                      loc.translate('smart_project.section.walls.subtitle'),
                  icon: Icons.view_column,
                  onChanged: (v) => setState(() => _includeWalls = v ?? false),
                ),
                _SectionCheckbox(
                  value: _includeRoof,
                  title: loc.translate('smart_project.section.roof.title'),
                  subtitle:
                      loc.translate('smart_project.section.roof.subtitle'),
                  icon: Icons.roofing,
                  onChanged: (v) => setState(() => _includeRoof = v ?? false),
                ),
                _SectionCheckbox(
                  value: _includeFinish,
                  title: loc.translate('smart_project.section.finish.title'),
                  subtitle:
                      loc.translate('smart_project.section.finish.subtitle'),
                  icon: Icons.format_paint,
                  onChanged: (v) => setState(() => _includeFinish = v ?? false),
                ),
              ],
            ),
          ),

          // Шаг 3: Подтверждение
          Step(
            title: Text(loc.translate('smart_project.step.confirm.title')),
            subtitle: Text(loc.translate('smart_project.step.confirm.subtitle')),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.translate('smart_project.step.confirm.prompt'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _SummaryRow(
                  icon: Icons.home,
                  label:
                      loc.translate('smart_project.summary.dimensions.label'),
                  value:
                      '${_lengthController.text} ${loc.translate('unit.meters')} '
                      'x ${_widthController.text} ${loc.translate('unit.meters')} '
                      'x ${_heightController.text} ${loc.translate('unit.meters')}',
                ),
                const Divider(),
                _SummaryRow(
                  icon: Icons.foundation,
                  label: loc.translate('smart_project.summary.foundation.label'),
                  value: _includeFoundation
                      ? loc.translate('common.yes')
                      : loc.translate('common.no'),
                  enabled: _includeFoundation,
                ),
                _SummaryRow(
                  icon: Icons.view_column,
                  label: loc.translate('smart_project.summary.walls.label'),
                  value: _includeWalls
                      ? loc.translate('common.yes')
                      : loc.translate('common.no'),
                  enabled: _includeWalls,
                ),
                _SummaryRow(
                  icon: Icons.roofing,
                  label: loc.translate('smart_project.summary.roof.label'),
                  value: _includeRoof
                      ? loc.translate('common.yes')
                      : loc.translate('common.no'),
                  enabled: _includeRoof,
                ),
                _SummaryRow(
                  icon: Icons.format_paint,
                  label: loc.translate('smart_project.summary.finish.label'),
                  value: _includeFinish
                      ? loc.translate('common.yes')
                      : loc.translate('common.no'),
                  enabled: _includeFinish,
                ),
              ],
            ),
          ),

          // Шаг 4: Результаты
          Step(
            title: Text(loc.translate('smart_project.step.results.title')),
            subtitle: Text(loc.translate('smart_project.step.results.subtitle')),
            isActive: _currentStep >= 3,
            state: _results != null ? StepState.complete : StepState.indexed,
            content: _results == null
                ? Text(
                    loc.translate('smart_project.press_calculate_hint'),
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
                                  Text(
                                    loc.translate(
                                      'smart_project.results.ready.title',
                                    ),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  Text(
                                    loc.translate(
                                      'smart_project.results.ready.subtitle',
                                    ),
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
                        final isSubItem = _resultSubItemKeys.contains(e.key);

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
                        final isCostItem = _resultCostItemKeys.contains(e.key);
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
                                  loc.translate(e.key),
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
                        label:
                            Text(loc.translate('smart_project.results.new')),
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
