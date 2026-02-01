import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Марки бетона с пропорциями на 1 м³
enum ConcreteGrade {
  m100, // М100 - лёгкие работы
  m150, // М150 - подготовительные работы
  m200, // М200 - фундаменты, стяжки (самый популярный)
  m300, // М300 - несущие конструкции
  m400, // М400 - особо прочные конструкции
}

/// Пропорции для каждой марки (на 1 м³ готового бетона)
class _GradeProportions {
  final double cementKg; // кг цемента
  final double sandKg;   // кг песка
  final double gravelKg; // кг щебня
  final double waterL;   // литры воды

  const _GradeProportions({
    required this.cementKg,
    required this.sandKg,
    required this.gravelKg,
    required this.waterL,
  });

  // Мешков цемента (по 50 кг)
  int cementBags(double volume) => (cementKg * volume / 50).ceil();
  // Объём песка в м³ (плотность ~1500 кг/м³)
  double sandVolume(double volume) => sandKg * volume / 1500;
  // Объём щебня в м³ (плотность ~1400 кг/м³)
  double gravelVolume(double volume) => gravelKg * volume / 1400;
  // Литры воды
  double waterLiters(double volume) => waterL * volume;
}

/// Калькулятор универсального бетона
///
/// Варианты использования:
/// - Готовый бетон: считает только объём
/// - Замес вручную: дополнительно считает цемент/песок/щебень/воду по марке
class ConcreteUniversalCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const ConcreteUniversalCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<ConcreteUniversalCalculatorScreen> createState() =>
      _ConcreteUniversalCalculatorScreenState();
}

class _ConcreteUniversalCalculatorScreenState
    extends State<ConcreteUniversalCalculatorScreen> with ExportableMixin {
  bool _isDark = false;

  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate(widget.definition.titleKey);

  // Пропорции по маркам бетона (на 1 м³)
  static const _proportions = {
    ConcreteGrade.m100: _GradeProportions(cementKg: 170, sandKg: 780, gravelKg: 1080, waterL: 200),
    ConcreteGrade.m150: _GradeProportions(cementKg: 210, sandKg: 735, gravelKg: 1080, waterL: 200),
    ConcreteGrade.m200: _GradeProportions(cementKg: 265, sandKg: 680, gravelKg: 1080, waterL: 195),
    ConcreteGrade.m300: _GradeProportions(cementKg: 340, sandKg: 620, gravelKg: 1080, waterL: 190),
    ConcreteGrade.m400: _GradeProportions(cementKg: 420, sandKg: 540, gravelKg: 1080, waterL: 185),
  };

  // Режим ввода
  bool _inputByArea = false; // false = по объёму, true = по площади

  // Поля ввода (по объёму)
  double _concreteVolume = 1.0;

  // Поля ввода (по площади)
  double _area = 10.0;
  double _thickness = 100.0; // мм

  // Общие настройки
  bool _manualMix = false;
  double _reserve = 5.0;
  ConcreteGrade _grade = ConcreteGrade.m200;
  double _mixerVolume = 150.0; // литры (стандартная бетономешалка)

  // Результаты
  late _ConcreteResult _result;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    if (initial['concreteVolume'] != null) {
      _concreteVolume = initial['concreteVolume']!.clamp(0.01, 1000.0);
    }
    if (initial['manualMix'] != null) {
      _manualMix = initial['manualMix'] == 1.0;
    }
    if (initial['reserve'] != null) {
      _reserve = initial['reserve']!.clamp(0.0, 30.0);
    }
    if (initial['area'] != null) {
      _area = initial['area']!.clamp(0.1, 1000.0);
    }
    if (initial['thickness'] != null) {
      _thickness = initial['thickness']!.clamp(50.0, 500.0);
    }
    if (initial['grade'] != null) {
      final gradeIndex = initial['grade']!.toInt().clamp(0, ConcreteGrade.values.length - 1);
      _grade = ConcreteGrade.values[gradeIndex];
    }
  }

  /// Вычисляет объём бетона в зависимости от режима ввода
  double _getBaseVolume() {
    if (_inputByArea) {
      // Площадь (м²) × толщина (мм→м)
      return _area * (_thickness / 1000);
    }
    return _concreteVolume;
  }

  _ConcreteResult _calculate() {
    final baseVolume = _getBaseVolume();
    final volumeWithReserve = baseVolume * (1 + _reserve / 100);

    // Для готового бетона
    // Стандартный миксер: 7-8 м³, берём 7 для расчёта
    final mixerCount = (volumeWithReserve / 7.0).ceil();
    // Вес бетона: ~2400 кг/м³
    final totalWeight = volumeWithReserve * 2400;

    // Пропорции по выбранной марке бетона
    final props = _proportions[_grade]!;
    final cementBags = _manualMix ? props.cementBags(volumeWithReserve) : 0;
    final sandVolume = _manualMix ? props.sandVolume(volumeWithReserve) : 0.0;
    final gravelVolume = _manualMix ? props.gravelVolume(volumeWithReserve) : 0.0;
    final waterLiters = _manualMix ? props.waterLiters(volumeWithReserve) : 0.0;

    // Количество замесов в бетономешалке
    // Объём готового бетона = 0.65 от объёма барабана (коэффициент выхода)
    final mixerOutputVolume = (_mixerVolume / 1000) * 0.65; // м³ за замес
    final batchCount = _manualMix ? (volumeWithReserve / mixerOutputVolume).ceil() : 0;

    return _ConcreteResult(
      concreteVolume: volumeWithReserve,
      mixerCount: mixerCount,
      totalWeight: totalWeight,
      cementBags: cementBags,
      sandVolume: sandVolume,
      gravelVolume: gravelVolume,
      waterLiters: waterLiters,
      batchCount: batchCount,
      grade: _grade,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('calculator.concrete_universal.title'));
    buffer.writeln('');

    // Исходные данные
    if (_inputByArea) {
      buffer.writeln(
          '${_loc.translate('input.area')}: ${_area.toStringAsFixed(1)} ${_loc.translate('unit.sqm')}');
      buffer.writeln(
          '${_loc.translate('input.thickness')}: ${_thickness.toStringAsFixed(0)} ${_loc.translate('unit.mm')}');
    } else {
      buffer.writeln(
          '${_loc.translate('input.concreteVolume')}: ${_concreteVolume.toStringAsFixed(1)} ${_loc.translate('unit.cubicMeters')}');
    }
    buffer.writeln(
        '${_loc.translate('input.reserve')}: ${_reserve.toStringAsFixed(0)}%');
    buffer.writeln('');
    buffer.writeln(
        '${_loc.translate('concrete.volume_with_reserve')}: ${_result.concreteVolume.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}');

    if (_manualMix) {
      buffer.writeln('');
      buffer.writeln('${_loc.translate('concrete.grade')}: ${_gradeLabel(_grade)}');
      buffer.writeln('${_loc.translate('concrete.batches')}: ${_result.batchCount}');
      buffer.writeln('');
      buffer.writeln(_loc.translate('group.materials'));
      buffer.writeln(
          '${_loc.translate('result.cementBags')}: ${_result.cementBags} ${_loc.translate('common.pcs')}');
      buffer.writeln(
          '${_loc.translate('result.sandVolume')}: ${_result.sandVolume.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}');
      buffer.writeln(
          '${_loc.translate('result.gravelVolume')}: ${_result.gravelVolume.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}');
      buffer.writeln(
          '${_loc.translate('result.waterNeeded')}: ${_result.waterLiters.toStringAsFixed(0)} ${_loc.translate('unit.liter')}');
    } else {
      buffer.writeln('');
      buffer.writeln(_loc.translate('concrete.ready_mix_title'));
      buffer.writeln(
          '${_loc.translate('concrete.mixers')}: ${_result.mixerCount}');
      final weightText = _result.totalWeight >= 1000
          ? '${(_result.totalWeight / 1000).toStringAsFixed(1)} ${_loc.translate('unit.ton')}'
          : '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('unit.kg')}';
      buffer.writeln(
          '${_loc.translate('concrete.total_weight')}: $weightText');
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.foundation;

    return CalculatorScaffold(
      title: _loc.translate(widget.definition.titleKey),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('result.concreteVolume'),
            value:
                '${_result.concreteVolume.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}',
            icon: Icons.view_in_ar,
          ),
          if (!_manualMix)
            ResultItem(
              label: _loc.translate('concrete.mixers'),
              value: '${_result.mixerCount}',
              icon: Icons.local_shipping,
            ),
          if (_manualMix)
            ResultItem(
              label: _loc.translate('concrete.batches'),
              value: '${_result.batchCount}',
              icon: Icons.loop,
            ),
        ],
      ),
      children: [
        // Карточка выбора режима ввода
        _buildInputModeCard(accentColor),
        const SizedBox(height: 16),

        // Карточка ввода объёма или площади
        if (_inputByArea)
          _buildAreaCard(accentColor)
        else
          _buildVolumeCard(accentColor),
        const SizedBox(height: 16),

        // Карточка выбора марки бетона (только для ручного замеса)
        if (_manualMix) ...[
          _buildGradeCard(accentColor),
          const SizedBox(height: 16),
        ],

        // Карточка настроек
        _buildSettingsCard(accentColor),
        const SizedBox(height: 16),

        // Карточка результатов для готового бетона
        if (!_manualMix) ...[
          _buildReadyMixResultsCard(accentColor),
          const SizedBox(height: 16),
        ],

        // Карточка результатов (материалы для ручного замеса)
        if (_manualMix) ...[
          _buildMaterialsCard(accentColor),
          const SizedBox(height: 16),
        ],

        // Советы
        TipsCard(
          tips: _manualMix
              ? [
                  _loc.translate('hint.concrete.after.curing'),
                  _loc.translate('hint.concrete.after.temperature'),
                ]
              : [
                  _loc.translate('hint.concrete.before.reserve'),
                  _loc.translate('hint.concrete.before.grade'),
                ],
          accentColor: accentColor,
          title: _loc.translate('common.tips'),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeCard(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('concrete.input_mode'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _modeButton(
                  label: _loc.translate('concrete.input_by_volume'),
                  icon: Icons.view_in_ar,
                  isSelected: !_inputByArea,
                  accentColor: accentColor,
                  onTap: () {
                    setState(() {
                      _inputByArea = false;
                      _update();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _modeButton(
                  label: _loc.translate('concrete.input_by_area'),
                  icon: Icons.square_foot,
                  isSelected: _inputByArea,
                  accentColor: accentColor,
                  onTap: () {
                    setState(() {
                      _inputByArea = true;
                      _update();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.15) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAreaCard(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('concrete.area_input'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loc.translate('concrete.area_input.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          // Площадь
          CalculatorSliderField(
            label: _loc.translate('input.area'),
            value: _area,
            min: 1.0,
            max: 200.0,
            suffix: _loc.translate('unit.sqm'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _area = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 16),
          // Толщина
          CalculatorSliderField(
            label: _loc.translate('input.thickness'),
            value: _thickness,
            min: 50.0,
            max: 300.0,
            suffix: _loc.translate('unit.mm'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _thickness = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 12),
          // Быстрый выбор толщины
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [50.0, 100.0, 150.0, 200.0].map((t) {
              final isSelected = (_thickness - t).abs() < 5;
              return ChoiceChip(
                label: Text('${t.toInt()} ${_loc.translate('unit.mm')}'),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                ),
                onSelected: (_) {
                  setState(() {
                    _thickness = t;
                    _update();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Показываем вычисленный объём
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.calculate, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_loc.translate('concrete.calculated_volume')}: ${_getBaseVolume().toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _gradeLabel(ConcreteGrade grade) {
    switch (grade) {
      case ConcreteGrade.m100:
        return 'М100';
      case ConcreteGrade.m150:
        return 'М150';
      case ConcreteGrade.m200:
        return 'М200';
      case ConcreteGrade.m300:
        return 'М300';
      case ConcreteGrade.m400:
        return 'М400';
    }
  }

  String _gradeDescription(ConcreteGrade grade) {
    switch (grade) {
      case ConcreteGrade.m100:
        return _loc.translate('concrete.grade.m100.desc');
      case ConcreteGrade.m150:
        return _loc.translate('concrete.grade.m150.desc');
      case ConcreteGrade.m200:
        return _loc.translate('concrete.grade.m200.desc');
      case ConcreteGrade.m300:
        return _loc.translate('concrete.grade.m300.desc');
      case ConcreteGrade.m400:
        return _loc.translate('concrete.grade.m400.desc');
    }
  }

  Widget _buildGradeCard(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('concrete.grade'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loc.translate('concrete.grade.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          // Выбор марки бетона
          ...ConcreteGrade.values.map((grade) {
            final isSelected = _grade == grade;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _grade = grade;
                    _update();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? accentColor.withValues(alpha: 0.1) : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? accentColor : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _gradeLabel(grade),
                            style: TextStyle(
                              color: isSelected ? Colors.white : CalculatorColors.getTextPrimary(_isDark),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _gradeDescription(grade),
                          style: TextStyle(
                            color: isSelected ? accentColor : CalculatorColors.getTextSecondary(_isDark),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle, color: accentColor, size: 24),
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

  Widget _buildVolumeCard(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('input.concreteVolume'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _loc.translate('input.concreteVolume.hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.getTextSecondary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          CalculatorSliderField(
            label: '',
            value: _concreteVolume,
            min: 0.1,
            max: 50.0,
            suffix: _loc.translate('unit.cubicMeters'),
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _concreteVolume = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 12),
          // Быстрый выбор объёма
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [0.5, 1.0, 2.0, 5.0, 10.0].map((vol) {
              final isSelected = (_concreteVolume - vol).abs() < 0.1;
              return ChoiceChip(
                label: Text('$vol ${_loc.translate('unit.cubicMeters')}'),
                selected: isSelected,
                selectedColor: accentColor.withValues(alpha: 0.2),
                labelStyle: TextStyle(
                  color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                side: BorderSide(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                ),
                onSelected: (_) {
                  setState(() {
                    _concreteVolume = vol;
                    _update();
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Переключатель ручного замеса
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loc.translate('input.manualMix'),
                      style: CalculatorDesignSystem.bodyMedium.copyWith(
                        color: CalculatorColors.getTextPrimary(_isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loc.translate('input.manualMix.hint'),
                      style: CalculatorDesignSystem.bodySmall.copyWith(
                        color: CalculatorColors.getTextSecondary(_isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _manualMix,
                activeTrackColor: accentColor.withValues(alpha: 0.5),
                activeThumbColor: accentColor,
                onChanged: (v) {
                  setState(() {
                    _manualMix = v;
                    _update();
                  });
                },
              ),
            ],
          ),
          const Divider(height: 24),

          // Выбор объёма бетономешалки (только для ручного замеса)
          if (_manualMix) ...[
            Text(
              _loc.translate('concrete.mixer_volume'),
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextPrimary(_isDark),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [120.0, 150.0, 180.0, 200.0].map((vol) {
                final isSelected = (_mixerVolume - vol).abs() < 5;
                return ChoiceChip(
                  label: Text('${vol.toInt()} ${_loc.translate('unit.liter')}'),
                  selected: isSelected,
                  selectedColor: accentColor.withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? accentColor : CalculatorColors.getTextPrimary(_isDark),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? accentColor : Colors.grey.shade300,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _mixerVolume = vol;
                      _update();
                    });
                  },
                );
              }).toList(),
            ),
            const Divider(height: 24),
          ],

          // Слайдер запаса
          CalculatorSliderField(
            label: _loc.translate('input.reserve'),
            value: _reserve,
            min: 0,
            max: 30,
            suffix: '%',
            accentColor: accentColor,
            onChanged: (v) {
              setState(() {
                _reserve = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadyMixResultsCard(Color accentColor) {
    // Форматирование веса
    String weightText;
    if (_result.totalWeight >= 1000) {
      weightText = '${(_result.totalWeight / 1000).toStringAsFixed(1)} ${_loc.translate('unit.ton')}';
    } else {
      weightText = '${_result.totalWeight.toStringAsFixed(0)} ${_loc.translate('unit.kg')}';
    }

    final items = [
      MaterialItem(
        name: _loc.translate('concrete.mixers'),
        value: '${_result.mixerCount}',
        subtitle: _loc.translate('concrete.mixer_subtitle'),
        icon: Icons.local_shipping,
      ),
      MaterialItem(
        name: _loc.translate('concrete.total_weight'),
        value: weightText,
        subtitle: _loc.translate('concrete.weight_subtitle'),
        icon: Icons.scale,
      ),
      MaterialItem(
        name: _loc.translate('concrete.volume_with_reserve'),
        value: '${_result.concreteVolume.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}',
        subtitle: '${_loc.translate('input.reserve')}: ${_reserve.toStringAsFixed(0)}%',
        icon: Icons.view_in_ar,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('concrete.ready_mix_title'),
      titleIcon: Icons.local_shipping,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildMaterialsCard(Color accentColor) {
    final materials = [
      // Количество замесов в бетономешалке
      MaterialItem(
        name: _loc.translate('concrete.batches'),
        value: '${_result.batchCount}',
        subtitle: '${_loc.translate('concrete.mixer_volume')}: ${_mixerVolume.toInt()} ${_loc.translate('unit.liter')}',
        icon: Icons.loop,
      ),
      MaterialItem(
        name: _loc.translate('result.cementBags'),
        value: '${_result.cementBags} ${_loc.translate('common.pcs')}',
        subtitle: '${_loc.translate('concrete.cement_subtitle')} (${_gradeLabel(_grade)})',
        icon: Icons.inventory_2,
      ),
      MaterialItem(
        name: _loc.translate('result.sandVolume'),
        value:
            '${_result.sandVolume.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}',
        subtitle: _loc.translate('concrete.sand_subtitle'),
        icon: Icons.grain,
      ),
      MaterialItem(
        name: _loc.translate('result.gravelVolume'),
        value:
            '${_result.gravelVolume.toStringAsFixed(2)} ${_loc.translate('unit.cubicMeters')}',
        subtitle: _loc.translate('concrete.gravel_subtitle'),
        icon: Icons.landscape,
      ),
      MaterialItem(
        name: _loc.translate('result.waterNeeded'),
        value:
            '${_result.waterLiters.toStringAsFixed(0)} ${_loc.translate('unit.liter')}',
        icon: Icons.water_drop,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('group.materials'),
      titleIcon: Icons.category,
      items: materials,
      accentColor: accentColor,
    );
  }

  Widget _card({required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(
        color: CalculatorColors.getCardBackground(isDark),
      ),
      child: child,
    );
  }
}

class _ConcreteResult {
  final double concreteVolume;
  final int mixerCount;
  final double totalWeight;
  final int cementBags;
  final double sandVolume;
  final double gravelVolume;
  final double waterLiters;
  final int batchCount;
  final ConcreteGrade grade;

  const _ConcreteResult({
    required this.concreteVolume,
    required this.mixerCount,
    required this.totalWeight,
    required this.cementBags,
    required this.sandVolume,
    required this.gravelVolume,
    required this.waterLiters,
    required this.batchCount,
    required this.grade,
  });
}
