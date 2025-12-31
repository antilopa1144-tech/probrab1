import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/calculator_colors.dart';
import '../../../core/constants/calculator_design_system.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_definition_v2.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_result_header.dart';
import '../../widgets/calculator/calculator_scaffold.dart';
import '../../widgets/calculator/calculator_text_field.dart';
import '../../widgets/calculator/mode_selector.dart';
import '../../widgets/calculator/result_card.dart';
import '../../widgets/existing/hint_card.dart';

enum PanelsInputMode { byArea, byDimensions }

class _PanelsResult {
  final double area;
  final int panelsCount;
  final double panelSizeCm;
  final double panelArea;
  final double glueKg;
  final double primerLiters;
  final double puttyKg;
  final double paintLiters;
  final double varnishLiters;
  final double moldingLength;

  const _PanelsResult({
    required this.area,
    required this.panelsCount,
    required this.panelSizeCm,
    required this.panelArea,
    required this.glueKg,
    required this.primerLiters,
    required this.puttyKg,
    required this.paintLiters,
    required this.varnishLiters,
    required this.moldingLength,
  });
}

class ThreeDPanelsCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const ThreeDPanelsCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<ThreeDPanelsCalculatorScreen> createState() =>
      _ThreeDPanelsCalculatorScreenState();
}

class _ThreeDPanelsCalculatorScreenState
    extends State<ThreeDPanelsCalculatorScreen> {
  PanelsInputMode _inputMode = PanelsInputMode.byArea;
  double _area = 12.0;
  double _length = 4.0;
  double _height = 2.7;
  double _panelSize = 50.0;
  bool _paintable = false;
  bool _withVarnish = true;

  late _PanelsResult _result;
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

    if (initial['area'] != null) {
      _area = initial['area']!.clamp(3.0, 150.0);
    }
    if (initial['length'] != null) {
      _length = initial['length']!.clamp(1.0, 12.0);
    }
    if (initial['height'] != null) {
      _height = initial['height']!.clamp(2.0, 4.0);
    }
    if (initial['panelSize'] != null) {
      final raw = initial['panelSize']!;
      _panelSize = (raw < 5 ? raw * 100 : raw).clamp(30.0, 100.0);
    }
    if (initial['paintable'] != null) {
      _paintable = initial['paintable']!.round() == 1;
    }
  }

  double _getCalculatedArea() {
    if (_inputMode == PanelsInputMode.byArea) return _area;
    return _length * _height;
  }

  _PanelsResult _calculate() {
    final area = _getCalculatedArea();

    // Размер панели в м²
    final panelArea = (_panelSize / 100) * (_panelSize / 100);

    // Количество панелей с запасом 10%
    final panelsCount = (area / panelArea * 1.1).ceil();

    // Материалы по нормативам из usecase
    final glueKg = area * 5.0; // 4-6 кг/м²
    final primerLiters = area * 0.18;
    final puttyKg = area * 1.0;
    final paintLiters = _paintable ? area * 0.24 : 0.0; // 2 слоя по 0.12 л
    final varnishLiters = _withVarnish ? area * 0.08 : 0.0;

    // Периметр для молдингов
    final perimeter = _inputMode == PanelsInputMode.byDimensions
        ? (_length + _height) * 2
        : 4 * sqrt(area);

    return _PanelsResult(
      area: area,
      panelsCount: panelsCount,
      panelSizeCm: _panelSize,
      panelArea: panelArea,
      glueKg: glueKg,
      primerLiters: primerLiters,
      puttyKg: puttyKg,
      paintLiters: paintLiters,
      varnishLiters: varnishLiters,
      moldingLength: perimeter,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _exportText() {
    final buffer = StringBuffer();
    buffer.writeln('📐 3D панели — расчёт');
    buffer.writeln('Площадь: ${_result.area.toStringAsFixed(1)} м²');
    buffer.writeln('Размер панели: ${_result.panelSizeCm.toStringAsFixed(0)}×${_result.panelSizeCm.toStringAsFixed(0)} см (${_result.panelArea.toStringAsFixed(3)} м²)');
    buffer.writeln('Панелей: ${_result.panelsCount} шт');
    buffer.writeln('Клей: ${_result.glueKg.toStringAsFixed(1)} кг');
    buffer.writeln('Грунтовка: ${_result.primerLiters.toStringAsFixed(1)} л');
    buffer.writeln('Шпаклёвка: ${_result.puttyKg.toStringAsFixed(1)} кг');
    if (_result.paintLiters > 0) {
      buffer.writeln('Краска: ${_result.paintLiters.toStringAsFixed(1)} л');
    }
    if (_result.varnishLiters > 0) {
      buffer.writeln('Лак: ${_result.varnishLiters.toStringAsFixed(1)} л');
    }
    buffer.writeln('Молдинги: ${_result.moldingLength.toStringAsFixed(1)} м (периметр)');
    return buffer.toString();
  }

  void _share() {
    SharePlus.instance
        .share(ShareParams(text: _exportText(), subject: 'Расчёт 3D панелей'));
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: _exportText()));
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
      title: '3D панели',
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          tooltip: _loc.translate('common.copy'),
          onPressed: _copy,
        ),
        IconButton(
          icon: const Icon(Icons.share),
          tooltip: _loc.translate('common.share'),
          onPressed: _share,
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: 'ПЛОЩАДЬ',
            value: '${_result.area.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: 'ПАНЕЛЕЙ',
            value: _result.panelsCount.toString(),
            icon: Icons.apps,
          ),
          ResultItem(
            label: 'КЛЕЙ',
            value: '${_result.glueKg.toStringAsFixed(1)} кг',
            icon: Icons.construction,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _inputMode == PanelsInputMode.byArea
            ? _buildAreaCard()
            : _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildPanelSizeCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
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
                _inputMode = PanelsInputMode.values[index];
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
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.2),
              thumbColor: accentColor,
            ),
            child: Slider(
              value: _area,
              min: 3,
              max: 150,
              divisions: ((150 - 3) * 10).round(),
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: 'Площадь',
            value: _area,
            suffix: 'м²',
            minValue: 3,
            maxValue: 150,
            decimalPlaces: 1,
            accentColor: accentColor,
            onChanged: (value) {
              setState(() {
                _area = value;
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
            'Размер стены',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDimensionSlider(
            label: 'Длина',
            value: _length,
            min: 1.0,
            max: 12.0,
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
            label: 'Высота',
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
              color: accentColor.withValues(alpha: 0.08),
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
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: accentColor,
            inactiveTrackColor: accentColor.withValues(alpha: 0.2),
            thumbColor: accentColor,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: ((max - min) * 10).round(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(height: 12),
        CalculatorTextField(
          label: label,
          value: value,
          suffix: 'м',
          minValue: min,
          maxValue: max,
          decimalPlaces: 1,
          accentColor: accentColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildPanelSizeCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Размер панели',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Частые размеры: 50×50 см, 60×60 см, 60×30 см',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Сторона панели',
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_panelSize.toStringAsFixed(0)} см',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.2),
              thumbColor: accentColor,
            ),
            child: Slider(
              value: _panelSize,
              min: 30,
              max: 100,
              divisions: 70,
              onChanged: (v) {
                setState(() {
                  _panelSize = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            label: 'Сторона панели',
            value: _panelSize,
            suffix: 'см',
            minValue: 30,
            maxValue: 100,
            isInteger: true,
            accentColor: accentColor,
            onChanged: (value) {
              setState(() {
                _panelSize = value;
                _update();
              });
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Площадь панели: ${_result.panelArea.toStringAsFixed(3)} м² · Запас 10%',
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Отделка',
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              'Панели под покраску',
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Добавим расход краски (2 слоя)',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _paintable,
            onChanged: (value) {
              setState(() {
                _paintable = value;
                _update();
              });
            },
          ),
          const SizedBox(height: 4),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor.withValues(alpha: 0.4)
                  : CalculatorColors.textSecondary.withValues(alpha: 0.2),
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? accentColor
                  : CalculatorColors.textSecondary,
            ),
            title: Text(
              'Финишный лак/защита',
              style: CalculatorDesignSystem.bodyMedium.copyWith(
                color: CalculatorColors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Рекомендуем для гипсовых и МДФ панелей',
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
            value: _withVarnish,
            onChanged: (value) {
              setState(() {
                _withVarnish = value;
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
    final results = <ResultRowItem>[
      ResultRowItem(
        label: 'Панели 3D',
        value:
            '${_result.panelsCount} шт · ${_result.panelSizeCm.toStringAsFixed(0)}×${_result.panelSizeCm.toStringAsFixed(0)} см',
        icon: Icons.apps,
      ),
      ResultRowItem(
        label: 'Клей для панелей',
        value: '${_result.glueKg.toStringAsFixed(1)} кг',
        icon: Icons.construction,
      ),
      ResultRowItem(
        label: 'Грунтовка',
        value: '${_result.primerLiters.toStringAsFixed(1)} л',
        icon: Icons.water_drop,
      ),
      ResultRowItem(
        label: 'Шпаклёвка под основание',
        value: '${_result.puttyKg.toStringAsFixed(1)} кг',
        icon: Icons.format_paint,
      ),
      if (_result.paintLiters > 0)
        ResultRowItem(
          label: 'Краска (2 слоя)',
          value: '${_result.paintLiters.toStringAsFixed(1)} л',
          icon: Icons.brush,
        ),
      if (_result.varnishLiters > 0)
        ResultRowItem(
          label: 'Лак / защитный слой',
          value: '${_result.varnishLiters.toStringAsFixed(1)} л',
          icon: Icons.shield,
        ),
      ResultRowItem(
        label: 'Молдинги / плинты',
        value: '${_result.moldingLength.toStringAsFixed(1)} м',
        icon: Icons.straighten,
      ),
    ];

    return ResultCardLight(
      title: 'Материалы',
      titleIcon: Icons.inventory_2,
      results: results,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    final hints = <CalculatorHint>[
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.walls.proverte_rovnost_sten_pered',
      ),
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.walls.ispolzuyte_spetsialnyy_kley_dlya_2',
      ),
      const CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.walls.nachinayte_montazh_ot_tsentra',
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
