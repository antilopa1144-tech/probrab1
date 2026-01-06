import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/data/putty_materials_database.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

/// Упрощённый калькулятор шпаклёвки V2 с выбором класса материалов
class PuttyCalculatorScreenV2 extends StatefulWidget {
  const PuttyCalculatorScreenV2({super.key});

  @override
  State<PuttyCalculatorScreenV2> createState() => _PuttyCalculatorScreenV2State();
}

enum InputMode { byArea, byDimensions }

enum MaterialTier {
  economy('Эконом', 'Бюджетный вариант', Icons.savings),
  standard('Стандарт', 'Оптимальное качество', Icons.verified),
  premium('Премиум', 'Лучшее качество', Icons.star);

  final String name;
  final String description;
  final IconData icon;
  const MaterialTier(this.name, this.description, this.icon);
}

class _PuttyCalculatorScreenV2State extends State<PuttyCalculatorScreenV2> {
  // === СОСТОЯНИЕ ===
  InputMode _inputMode = InputMode.byArea;
  double _area = 15.0;
  double _length = 4.0;
  double _width = 3.75;
  double _height = 2.7;

  // Цель: обои или покраска
  bool _isPainting = false;

  // Состояние стен
  WallCondition _wallCondition = WallCondition.smooth;

  // Класс материалов
  MaterialTier _materialTier = MaterialTier.standard;

  // Проёмы (скрыты по умолчанию)
  bool _showOpenings = false;
  final List<_Opening> _openings = [_Opening()];

  late _CalculationResult _result;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    // Периметр × высота
    return (_length + _width) * 2 * _height;
  }

  double get _netArea {
    final calculatedArea = _getCalculatedArea();

    if (!_showOpenings) {
      return calculatedArea;
    }

    double openingsArea = 0;
    for (final op in _openings) {
      openingsArea += op.width * op.height * op.count;
    }

    return (calculatedArea - openingsArea).clamp(0, double.infinity);
  }

  int get _startLayers => _isPainting ? 2 : 1;
  int get _finishLayers => _isPainting ? 2 : 1;

  double get _startLayerThickness {
    switch (_wallCondition) {
      case WallCondition.smooth:
        return 1.5;
      case WallCondition.medium:
        return 3.0;
      case WallCondition.rough:
        return 5.0;
    }
  }

  double get _finishLayerThickness => 1.0;

  // Получить материалы по тиру
  PuttyMaterial _getStartMaterialForTier() {
    final materials = PuttyMaterialsDatabase.startMaterials;
    switch (_materialTier) {
      case MaterialTier.economy:
        return materials.firstWhere((m) => m.brand == 'Волма', orElse: () => materials.first);
      case MaterialTier.standard:
        return materials.firstWhere((m) => m.brand == 'Knauf', orElse: () => materials.first);
      case MaterialTier.premium:
        return materials.firstWhere((m) => m.brand == 'Terraco', orElse: () => materials.first);
    }
  }

  PuttyMaterial _getFinishMaterialForTier() {
    switch (_materialTier) {
      case MaterialTier.economy:
        final dryMaterials = PuttyMaterialsDatabase.finishDryMaterials;
        return dryMaterials.firstWhere((m) => m.brand == 'Старатели', orElse: () => dryMaterials.first);
      case MaterialTier.standard:
        final pasteMaterials = PuttyMaterialsDatabase.finishPasteMaterials;
        return pasteMaterials.firstWhere((m) => m.brand == 'Sheetrock', orElse: () => pasteMaterials.first);
      case MaterialTier.premium:
        final pasteMaterials = PuttyMaterialsDatabase.finishPasteMaterials;
        return pasteMaterials.firstWhere((m) => m.brand == 'Terraco', orElse: () => pasteMaterials.first);
    }
  }

  _CalculationResult _calculate() {
    final startMaterial = _getStartMaterialForTier();
    final finishMaterial = _getFinishMaterialForTier();

    // Расчёт старта
    final startConsumption = _netArea *
        startMaterial.consumptionPerMm *
        _startLayerThickness *
        _startLayers;
    final startPackages = (startConsumption / startMaterial.packageSize).ceil();

    // Расчёт финиша
    final finishConsumption = _netArea *
        finishMaterial.consumptionPerMm *
        _finishLayerThickness *
        _finishLayers;
    final finishPackages = (finishConsumption / finishMaterial.packageSize).ceil();

    // Грунтовка: 0.15 л/м² на каждый слой
    final primerLayers = _startLayers + _finishLayers + 1;
    final primerVolume = _netArea * 0.15 * primerLayers;
    final primerCanisters = (primerVolume / 10).ceil();

    // Абразив: 1 лист на 10 м², 2 этапа шлифовки
    final sandingSheets = ((_netArea / 10) * 2).ceil();

    // Время работы (часы)
    final workTime = _calculateWorkTime();

    return _CalculationResult(
      netArea: _netArea,
      startMaterial: startMaterial,
      startPackages: startPackages,
      startWeight: startConsumption,
      finishMaterial: finishMaterial,
      finishPackages: finishPackages,
      finishWeight: finishConsumption,
      primerVolume: primerVolume,
      primerCanisters: primerCanisters,
      sandingSheets: sandingSheets,
      workTimeHours: workTime,
      totalDays: _calculateTotalDays(),
    );
  }

  int _calculateWorkTime() {
    const gruntTime = 1;
    final startTime = (_netArea / 15 * _startLayers).ceil();
    final finishTime = (_netArea / 20 * _finishLayers).ceil();
    final sandingTime = (_netArea / 25 * 2).ceil();

    return gruntTime + startTime + finishTime + sandingTime;
  }

  int _calculateTotalDays() {
    int days = 1;
    days += _startLayers - 1;
    days += 1;
    if (_finishLayers > 1) {
      days += 1;
    }
    days += 1;

    return days;
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final result = _result;
    final targetLabel = _isPainting ? 'Под покраску' : 'Под обои';

    final buffer = StringBuffer();
    buffer.writeln('🏠 РАСЧЁТ ШПАКЛЁВКИ');
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln('Цель: $targetLabel');
    buffer.writeln('Площадь: ${result.netArea.toStringAsFixed(1)} м²');
    buffer.writeln('Состояние стен: ${_wallCondition.name}');
    buffer.writeln('Класс материалов: ${_materialTier.name}');
    buffer.writeln();
    buffer.writeln('🛒 МАТЕРИАЛЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln(
        '• ${result.startMaterial.fullName}: ${result.startPackages} шт (${result.startMaterial.packageSize.toInt()} ${result.startMaterial.packageUnit}) или аналог');
    buffer.writeln(
        '• ${result.finishMaterial.fullName}: ${result.finishPackages} шт (${result.finishMaterial.packageSize.toInt()} ${result.finishMaterial.packageUnit}) или аналог');
    buffer.writeln('• Грунтовка: ${result.primerCanisters} канистр (10 л)');
    buffer.writeln('• Абразив: ${result.sandingSheets} листов');
    buffer.writeln();
    buffer.writeln('⏱️ ВРЕМЯ РАБОТЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln('• Работа: ~${result.workTimeHours} часов');
    buffer.writeln('• С учётом сушки: ${result.totalDays} дней');
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln('Создано в Прораб AI');

    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(
      ShareParams(text: text, subject: 'Расчёт шпаклёвки'),
    );
  }

  void _copyToClipboard() {
    final text = _generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('putty.title'),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copyToClipboard,
          tooltip: _loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareCalculation,
          tooltip: _loc.translate('common.share'),
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: 'ПЛОЩАДЬ',
            value: '${_result.netArea.toStringAsFixed(0)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: 'СТАРТ',
            value: '${_result.startPackages} шт',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: 'ФИНИШ',
            value: '${_result.finishPackages} шт',
            icon: Icons.format_paint,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea ? _buildAreaCard() : _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildTargetSelector(),
        const SizedBox(height: 16),
        _buildWallConditionSelector(),
        const SizedBox(height: 16),
        _buildMaterialTierSelector(),
        const SizedBox(height: 16),
        _buildOpeningsToggle(),
        if (_showOpenings) ...[
          const SizedBox(height: 16),
          _buildOpeningsSection(),
        ],
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildWorkTimeCard(),
        const SizedBox(height: 24),
        _buildTipsSection(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Режим ввода',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: const ['По площади', 'По размерам'],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = InputMode.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Площадь стен',
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_area.toStringAsFixed(1)} м²',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _area,
            min: 5,
            max: 200,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _area = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Размеры комнаты',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: 'Длина',
            value: _length,
            min: 1.0,
            max: 20.0,
            onChanged: (v) {
              setState(() {
                _length = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: 'Ширина',
            value: _width,
            min: 1.0,
            max: 20.0,
            onChanged: (v) {
              setState(() {
                _width = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: 'Высота потолка',
            value: _height,
            min: 2.0,
            max: 4.0,
            onChanged: (v) {
              setState(() {
                _height = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Площадь стен',
                    style: CalculatorDesignSystem.bodyMedium.copyWith(
                      color: CalculatorColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} м²',
                  style: CalculatorDesignSystem.headlineMedium.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color accentColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${value.toStringAsFixed(1)} м',
              style: CalculatorDesignSystem.titleMedium.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).toInt(),
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildTargetSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('putty.section.finish_goal'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('putty.target.wallpaper.title'),
              _loc.translate('putty.target.painting.title'),
            ],
            selectedIndex: _isPainting ? 1 : 0,
            onSelect: (index) {
              setState(() {
                _isPainting = index == 1;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _isPainting ? '2 слоя старта + 2 слоя финиша' : '1 слой старта + 1 слой финиша',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWallConditionSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('putty.wall_condition_title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Влияет на толщину и расход стартовой шпаклёвки',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...WallCondition.values.asMap().entries.map((entry) {
            final index = entry.key;
            final condition = entry.value;
            final isSelected = _wallCondition == condition;

            return Padding(
              padding: EdgeInsets.only(bottom: index < WallCondition.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _wallCondition = condition;
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.textSecondary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _loc.translate(condition.labelKey),
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected ? accentColor : CalculatorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loc.translate(condition.descriptionKey),
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMaterialTierSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Класс материалов',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Автоматически подберём материалы указанного класса',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          ...MaterialTier.values.asMap().entries.map((entry) {
            final index = entry.key;
            final tier = entry.value;
            final isSelected = _materialTier == tier;

            return Padding(
              padding: EdgeInsets.only(bottom: index < MaterialTier.values.length - 1 ? 8.0 : 0),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _materialTier = tier;
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? accentColor
                          : CalculatorColors.textSecondary.withValues(alpha: 0.2),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? accentColor.withValues(alpha: 0.15)
                              : CalculatorColors.textSecondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          tier.icon,
                          color: isSelected ? accentColor : CalculatorColors.textSecondary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier.name,
                              style: CalculatorDesignSystem.titleSmall.copyWith(
                                color: isSelected ? accentColor : CalculatorColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tier.description,
                              style: CalculatorDesignSystem.bodySmall.copyWith(
                                color: CalculatorColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle, color: accentColor, size: 24),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOpeningsToggle() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: InkWell(
        onTap: () {
          setState(() {
            _showOpenings = !_showOpenings;
            _update();
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Icon(
                _showOpenings ? Icons.expand_less : Icons.expand_more,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Учесть окна и двери',
                      style: CalculatorDesignSystem.titleMedium.copyWith(
                        color: CalculatorColors.textPrimary,
                      ),
                    ),
                    if (!_showOpenings)
                      Text(
                        'Вычтем из площади',
                        style: CalculatorDesignSystem.bodySmall.copyWith(
                          color: CalculatorColors.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpeningsSection() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Проёмы (${_openings.length})',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() {
                  _openings.add(_Opening());
                  _update();
                }),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Добавить'),
                style: TextButton.styleFrom(foregroundColor: accentColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._openings.asMap().entries.map((entry) {
            final index = entry.key;
            final opening = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSmallSlider(
                      label: 'Ш',
                      value: opening.width,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (v) {
                        setState(() {
                          opening.width = v;
                          _update();
                        });
                      },
                      accentColor: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallSlider(
                      label: 'В',
                      value: opening.height,
                      min: 0.5,
                      max: 3.0,
                      onChanged: (v) {
                        setState(() {
                          opening.height = v;
                          _update();
                        });
                      },
                      accentColor: accentColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSmallSlider(
                      label: 'Шт',
                      value: opening.count.toDouble(),
                      min: 1,
                      max: 10,
                      onChanged: (v) {
                        setState(() {
                          opening.count = v.toInt();
                          _update();
                        });
                      },
                      accentColor: accentColor,
                      isInteger: true,
                    ),
                  ),
                  if (_openings.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      onPressed: () => setState(() {
                        _openings.removeAt(index);
                        _update();
                      }),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSmallSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required Color accentColor,
    bool isInteger = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: CalculatorDesignSystem.bodySmall.copyWith(
            color: CalculatorColors.textSecondary,
          ),
        ),
        Text(
          isInteger ? value.toInt().toString() : value.toStringAsFixed(1),
          style: CalculatorDesignSystem.titleSmall.copyWith(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: isInteger ? (max - min).toInt() : ((max - min) * 10).toInt(),
          activeColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;
    final result = _result;

    final materials = <MaterialItem>[
      MaterialItem(
        name: '${result.startMaterial.fullName} или аналог',
        value: '${result.startPackages} шт',
        subtitle: '${result.startWeight.toStringAsFixed(1)} кг',
        icon: Icons.inventory_2,
      ),
      MaterialItem(
        name: '${result.finishMaterial.fullName} или аналог',
        value: '${result.finishPackages} шт',
        subtitle:
            '${result.finishWeight.toStringAsFixed(1)} ${result.finishMaterial.packageUnit}',
        icon: Icons.format_paint,
      ),
      MaterialItem(
        name: 'Грунтовка',
        value: '${result.primerCanisters} шт',
        subtitle: '${result.primerVolume.toStringAsFixed(1)} л • 10 л/канистра',
        icon: Icons.water_drop,
      ),
      MaterialItem(
        name: 'Абразив (сетки)',
        value: '${result.sandingSheets} шт',
        subtitle: 'P120 + P180',
        icon: Icons.grid_4x4,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('putty.section.shopping_list'),
      titleIcon: Icons.shopping_cart,
      items: materials,
      accentColor: accentColor,
    );
  }

  Widget _buildWorkTimeCard() {
    const accentColor = CalculatorColors.interior;
    final result = _result;

    final items = <MaterialItem>[
      MaterialItem(
        name: 'Время работы',
        value: '~${result.workTimeHours} часов',
        subtitle: 'Чистое рабочее время',
        icon: Icons.handyman,
      ),
      MaterialItem(
        name: 'С учётом сушки',
        value: '${result.totalDays} дней',
        subtitle: 'Включая высыхание слоёв',
        icon: Icons.calendar_today,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('putty.work_time_title'),
      titleIcon: Icons.schedule,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    final hints = <CalculatorHint>[
      if (_isPainting)
        const CalculatorHint(
          type: HintType.important,
          message: 'Под покраску нужна идеально ровная поверхность. Используйте яркий свет для проверки.',
        ),
      if (!_isPainting)
        const CalculatorHint(
          type: HintType.tip,
          message: 'Под обои достаточно одного слоя старта и финиша. Обои скроют мелкие неровности.',
        ),
      const CalculatorHint(
        type: HintType.important,
        message: 'Каждый слой должен полностью высохнуть перед нанесением следующего (обычно 24 часа).',
      ),
      const CalculatorHint(
        type: HintType.tip,
        message: 'Грунтуйте поверхность перед каждым слоем для лучшей адгезии и снижения расхода.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _loc.translate('common.tips'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
        ),
        HintsList(hints: hints),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}

// === ВСПОМОГАТЕЛЬНЫЕ КЛАССЫ ===

class _Opening {
  double width = 0.9;
  double height = 2.1;
  int count = 1;
}

class _CalculationResult {
  final double netArea;
  final PuttyMaterial startMaterial;
  final int startPackages;
  final double startWeight;
  final PuttyMaterial finishMaterial;
  final int finishPackages;
  final double finishWeight;
  final double primerVolume;
  final int primerCanisters;
  final int sandingSheets;
  final int workTimeHours;
  final int totalDays;

  _CalculationResult({
    required this.netArea,
    required this.startMaterial,
    required this.startPackages,
    required this.startWeight,
    required this.finishMaterial,
    required this.finishPackages,
    required this.finishWeight,
    required this.primerVolume,
    required this.primerCanisters,
    required this.sandingSheets,
    required this.workTimeHours,
    required this.totalDays,
  });
}
