import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_constant.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Вспомогательный класс для работы с константами калькулятора обоев
class _WallpaperConstants {
  final CalculatorConstants? _data;

  const _WallpaperConstants([this._data]);

  double _getDouble(String constantKey, String valueKey, double defaultValue) {
    if (_data == null) return defaultValue;
    final constant = _data.constants[constantKey];
    if (constant == null) return defaultValue;
    final value = constant.values[valueKey];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return defaultValue;
  }

  // Roll sizes
  double getRollWidth(String sizeKey) {
    final defaults = {'s053x10': 0.53, 's106x10': 1.06, 's106x25': 1.06};
    return _getDouble('roll_sizes', '${sizeKey}_width', defaults[sizeKey] ?? 0.53);
  }

  double getRollLength(String sizeKey) {
    final defaults = {'s053x10': 10.0, 's106x10': 10.0, 's106x25': 25.0};
    return _getDouble('roll_sizes', '${sizeKey}_length', defaults[sizeKey] ?? 10.0);
  }

  // Materials consumption
  // Клей обойный - СУХАЯ СМЕСЬ (разводится водой): ~8 г/м² = 0.008 кг/м²
  double get gluePerM2 => _getDouble('materials_consumption', 'glue_per_m2', 0.008);
  double get primerPerM2 => _getDouble('materials_consumption', 'primer_per_m2', 0.15);
}

enum InputMode { byArea, byRoom }
enum WallpaperRollSize { s053x10, s106x10, s106x25, custom }

class _WallpaperResult {
  final double area;
  final double wallsArea;
  final double deductedArea;
  final int rollsNeeded;
  final int stripsNeeded;
  final double rollArea;
  final String rollSizeName;
  final double glueNeededKg;
  final double primerLiters;
  final double rollWidth;
  final double rollLength;

  const _WallpaperResult({
    required this.area,
    required this.wallsArea,
    required this.deductedArea,
    required this.rollsNeeded,
    required this.stripsNeeded,
    required this.rollArea,
    required this.rollSizeName,
    required this.glueNeededKg,
    required this.primerLiters,
    required this.rollWidth,
    required this.rollLength,
  });
}

class WallpaperCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const WallpaperCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<WallpaperCalculatorScreen> createState() => _WallpaperCalculatorScreenState();
}

class _WallpaperCalculatorScreenState extends State<WallpaperCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('wallpaper.export.subject');

  bool _isDark = false;
  InputMode _inputMode = InputMode.byRoom;
  double _area = 30.0;
  double _length = 4.0;
  double _width = 3.0;
  double _height = 2.7;
  double _windowsDoors = 3.0;
  double _reserve = 5.0;
  int _rapport = 0;
  WallpaperRollSize _rollSize = WallpaperRollSize.s053x10;
  double _customWidth = 1.06;
  double _customLength = 10.0;
  late _WallpaperResult _result;
  late AppLocalizations _loc;

  // Константы калькулятора (null = используются hardcoded defaults)
  late final _WallpaperConstants _constants;

  @override
  void initState() {
    super.initState();
    _constants = const _WallpaperConstants(null);
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 1000.0);
    if (initial['length'] != null) _length = initial['length']!.clamp(1.0, 20.0);
    if (initial['width'] != null) _width = initial['width']!.clamp(1.0, 20.0);
    if (initial['height'] != null) _height = initial['height']!.clamp(2.0, 5.0);
  }

  double _getCalculatedArea() {
    if (_inputMode == InputMode.byArea) {
      return _area;
    }
    // Площадь стен: периметр × высота
    return (_length + _width) * 2 * _height;
  }

  _WallpaperResult _calculate() {
    final wallsArea = _getCalculatedArea();
    final deductedArea = wallsArea - _windowsDoors;
    final effectiveArea = deductedArea > 0 ? deductedArea : wallsArea;

    // Размер рулона из констант
    double rollWidth;
    double rollLength;
    String rollSizeName;

    switch (_rollSize) {
      case WallpaperRollSize.s053x10:
        rollWidth = _constants.getRollWidth('s053x10');
        rollLength = _constants.getRollLength('s053x10');
        rollSizeName = '${rollWidth.toStringAsFixed(2)}×${rollLength.toInt()}';
        break;
      case WallpaperRollSize.s106x10:
        rollWidth = _constants.getRollWidth('s106x10');
        rollLength = _constants.getRollLength('s106x10');
        rollSizeName = '${rollWidth.toStringAsFixed(2)}×${rollLength.toInt()}';
        break;
      case WallpaperRollSize.s106x25:
        rollWidth = _constants.getRollWidth('s106x25');
        rollLength = _constants.getRollLength('s106x25');
        rollSizeName = '${rollWidth.toStringAsFixed(2)}×${rollLength.toInt()}';
        break;
      case WallpaperRollSize.custom:
        rollWidth = _customWidth;
        rollLength = _customLength;
        rollSizeName = '${_customWidth.toStringAsFixed(2)}×${_customLength.toStringAsFixed(1)}';
        break;
    }

    final rollArea = rollWidth * rollLength;

    // Высота полотна с учётом раппорта
    double stripHeight = _height;
    if (_rapport > 0) {
      // Округляем высоту до ближайшего кратного раппорту
      final rapportMeters = _rapport / 100.0;
      stripHeight = ((_height / rapportMeters).ceil()) * rapportMeters;
    }

    // Количество полос из одного рулона
    final stripsPerRoll = (rollLength / stripHeight).floor();

    // Общее количество полос
    final perimeter = (_inputMode == InputMode.byRoom)
        ? (_length + _width) * 2
        : (effectiveArea / _height); // Приблизительный периметр для режима "по площади"

    final totalStrips = (perimeter / rollWidth).ceil();

    // Количество рулонов
    int rollsNeeded;
    if (stripsPerRoll > 0) {
      rollsNeeded = (totalStrips / stripsPerRoll).ceil();
    } else {
      // Если полоса выше рулона, считаем по площади
      rollsNeeded = (effectiveArea / rollArea).ceil();
    }

    // Добавляем запас
    rollsNeeded = (rollsNeeded * (1 + _reserve / 100)).ceil();

    // Расчёт материалов из констант
    // Клей - сухая смесь, показываем точное значение без округления вверх
    final glueNeededKg = effectiveArea * _constants.gluePerM2;
    // Грунтовка: 0.1 л/м² (стандартный расход)
    final primerLiters = effectiveArea * 0.1;

    return _WallpaperResult(
      area: effectiveArea,
      wallsArea: wallsArea,
      deductedArea: deductedArea,
      rollsNeeded: rollsNeeded,
      stripsNeeded: totalStrips,
      rollArea: rollArea,
      rollSizeName: rollSizeName,
      glueNeededKg: glueNeededKg,
      primerLiters: primerLiters,
      rollWidth: rollWidth,
      rollLength: rollLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('wallpaper.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln(_loc.translate('wallpaper.export.walls_area')
        .replaceFirst('{value}', _result.wallsArea.toStringAsFixed(1)));
    if (_windowsDoors > 0) {
      buffer.writeln(_loc.translate('wallpaper.export.deduction')
          .replaceFirst('{value}', _windowsDoors.toStringAsFixed(1)));
      buffer.writeln(_loc.translate('wallpaper.export.gluing_area')
          .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    }
    if (_rapport > 0) {
      buffer.writeln(_loc.translate('wallpaper.export.rapport')
          .replaceFirst('{value}', _rapport.toString()));
    }
    buffer.writeln();

    buffer.writeln(_loc.translate('wallpaper.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('wallpaper.export.rolls_line')
        .replaceFirst('{size}', _result.rollSizeName)
        .replaceFirst('{value}', _result.rollsNeeded.toString()));
    buffer.writeln(_loc.translate('wallpaper.export.strips_line')
        .replaceFirst('{value}', _result.stripsNeeded.toString()));
    buffer.writeln(_loc.translate('wallpaper.export.glue_line')
        .replaceFirst('{value}', _result.glueNeededKg.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('wallpaper.export.primer_line')
        .replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1)));
    buffer.writeln();

    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('wallpaper.export.footer'));

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('wallpaper.title'),
      accentColor: accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('wallpaper.label.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('wallpaper.summary.rolls').toUpperCase(),
            value: '${_result.rollsNeeded}',
            icon: Icons.ballot,
          ),
          ResultItem(
            label: _loc.translate('wallpaper.summary.strips').toUpperCase(),
            value: '${_result.stripsNeeded}',
            icon: Icons.view_week,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == InputMode.byArea ? _buildAreaCard() : _buildRoomDimensionsCard(),
        const SizedBox(height: 16),
        _buildRollSizeSelector(),
        if (_rollSize == WallpaperRollSize.custom) ...[
          const SizedBox(height: 16),
          _buildCustomSizeCard(),
        ],
        const SizedBox(height: 16),
        _buildRapportCard(),
        const SizedBox(height: 16),
        _buildDeductionsCard(),
        const SizedBox(height: 16),
        _buildReserveCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 24),
        _buildTipsCard(),
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
            _loc.translate('wallpaper.input_mode.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('wallpaper.input_mode.by_room'),
              _loc.translate('wallpaper.input_mode.by_area'),
            ],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('wallpaper.label.area'),
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: CalculatorColors.getTextSecondary(_isDark),
                ),
              ),
              Text(
                '${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _area,
            min: 1,
            max: 500,
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

  Widget _buildRoomDimensionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.room.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('wallpaper.room.length'),
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
            label: _loc.translate('wallpaper.room.width'),
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
            label: _loc.translate('wallpaper.room.height'),
            value: _height,
            min: 2.0,
            max: 5.0,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _loc.translate('wallpaper.room.calculated_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
                Text(
                  '${_getCalculatedArea().toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.getTextSecondary(_isDark),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
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

  Widget _buildRollSizeSelector() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.roll_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelectorVertical(
            options: [
              _loc.translate('wallpaper.roll_size.s053x10'),
              _loc.translate('wallpaper.roll_size.s106x10'),
              _loc.translate('wallpaper.roll_size.s106x25'),
              _loc.translate('wallpaper.roll_size.custom'),
            ],
            selectedIndex: _rollSize.index,
            onSelect: (index) {
              setState(() {
                _rollSize = WallpaperRollSize.values[index];
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCustomSizeCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('wallpaper.custom_size.title'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('wallpaper.custom_size.width'),
            value: _customWidth,
            min: 0.5,
            max: 2.0,
            onChanged: (v) {
              setState(() {
                _customWidth = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: _loc.translate('wallpaper.custom_size.length'),
            value: _customLength,
            min: 5.0,
            max: 50.0,
            onChanged: (v) {
              setState(() {
                _customLength = v;
                _update();
              });
            },
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildRapportCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _loc.translate('wallpaper.rapport.title'),
                      style: CalculatorDesignSystem.titleMedium.copyWith(
                        color: CalculatorColors.getTextPrimary(_isDark),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _loc.translate('wallpaper.rapport.subtitle'),
                      style: CalculatorDesignSystem.bodySmall.copyWith(
                        color: CalculatorColors.getTextSecondary(_isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _rapport == 0
                    ? _loc.translate('wallpaper.rapport.none')
                    : '$_rapport ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _rapport.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _rapport = v.toInt();
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeductionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _loc.translate('wallpaper.deductions.title'),
                    style: CalculatorDesignSystem.titleMedium.copyWith(
                      color: CalculatorColors.getTextPrimary(_isDark),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loc.translate('wallpaper.deductions.subtitle'),
                    style: CalculatorDesignSystem.bodySmall.copyWith(
                      color: CalculatorColors.getTextSecondary(_isDark),
                    ),
                  ),
                ],
              ),
              Text(
                '${_windowsDoors.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _windowsDoors,
            min: 0,
            max: 50,
            divisions: 100,
            activeColor: accentColor,
            onChanged: (v) {
              setState(() {
                _windowsDoors = v;
                _update();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReserveCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('wallpaper.reserve.title'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                ),
              ),
              Text(
                '${_reserve.toStringAsFixed(0)} %',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _reserve,
            min: 0,
            max: 20,
            divisions: 20,
            activeColor: accentColor,
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

  Widget _buildMaterialsCard() {
    const accentColor = CalculatorColors.interior;

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('wallpaper.materials.rolls'),
        value: '${_result.rollsNeeded} ${_loc.translate('wallpaper.materials.rolls_unit')}',
        subtitle: _result.rollSizeName,
        icon: Icons.ballot,
      ),
      MaterialItem(
        name: _loc.translate('wallpaper.materials.strips'),
        value: '${_result.stripsNeeded} ${_loc.translate('wallpaper.materials.strips_unit')}',
        icon: Icons.view_week,
      ),
      MaterialItem(
        name: _loc.translate('wallpaper.materials.glue'),
        // Показываем в граммах если меньше 1 кг
        value: _result.glueNeededKg < 1
            ? '${(_result.glueNeededKg * 1000).toStringAsFixed(0)} г'
            : '${_result.glueNeededKg.toStringAsFixed(1)} ${_loc.translate('wallpaper.materials.kg')}',
        icon: Icons.colorize,
      ),
      MaterialItem(
        name: _loc.translate('wallpaper.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('wallpaper.materials.liters')}',
        icon: Icons.water_drop,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('wallpaper.materials.title'),
      titleIcon: Icons.construction,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsCard() {
    const accentColor = CalculatorColors.interior;
    final tips = <String>[
      _loc.translate('hint.wallpaper.check_batch_number'),
      _loc.translate('hint.wallpaper.start_from_window'),
      _loc.translate('hint.wallpaper.temperature_humidity'),
    ];

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
      title: _loc.translate('common.tips'),
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
