import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип лестницы
enum StairsType {
  straight('stairs_calc.type.straight', 'stairs_calc.type.straight_desc', Icons.stairs),
  lShaped('stairs_calc.type.l_shaped', 'stairs_calc.type.l_shaped_desc', Icons.turn_right),
  uShaped('stairs_calc.type.u_shaped', 'stairs_calc.type.u_shaped_desc', Icons.u_turn_right);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const StairsType(this.nameKey, this.descKey, this.icon);
}

class _StairsResult {
  final int stepsCount;
  final double stepHeight;
  final double stepDepth;
  final double stairsLength;
  final double stringerLength;
  final double railingLength;

  const _StairsResult({
    required this.stepsCount,
    required this.stepHeight,
    required this.stepDepth,
    required this.stairsLength,
    required this.stringerLength,
    required this.railingLength,
  });
}

class StairsCalculatorScreen extends StatefulWidget {
  const StairsCalculatorScreen({super.key});

  @override
  State<StairsCalculatorScreen> createState() => _StairsCalculatorScreenState();
}

class _StairsCalculatorScreenState extends State<StairsCalculatorScreen> {
  double _floorHeight = 2.8;
  double _openingLength = 4.0;
  double _stairsWidth = 0.9;

  StairsType _stairsType = StairsType.straight;
  bool _needRailing = true;
  bool _needBothSides = false;

  late _StairsResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _StairsResult _calculate() {
    // Оптимальная высота ступени 15-20 см
    final optimalStepHeight = 0.17; // 17 см
    final stepsCount = (_floorHeight / optimalStepHeight).ceil();
    final stepHeight = _floorHeight / stepsCount;

    // Глубина ступени: формула 2h + d = 60-64 см
    final stepDepth = 0.62 - 2 * stepHeight;
    final clampedDepth = stepDepth.clamp(0.25, 0.35);

    // Длина лестницы
    double stairsLength;
    switch (_stairsType) {
      case StairsType.straight:
        stairsLength = stepsCount * clampedDepth;
      case StairsType.lShaped:
        stairsLength = stepsCount * clampedDepth * 0.75; // с площадкой
      case StairsType.uShaped:
        stairsLength = stepsCount * clampedDepth * 0.55; // компактнее
    }

    // Длина косоура (по теореме Пифагора)
    final stringerLength = math.sqrt(_floorHeight * _floorHeight + stairsLength * stairsLength) * 1.1;

    // Перила
    double railingLength = 0;
    if (_needRailing) {
      railingLength = stairsLength + 0.5; // + 0.5м на верхнюю площадку
      if (_needBothSides) railingLength *= 2;
    }

    return _StairsResult(
      stepsCount: stepsCount,
      stepHeight: stepHeight,
      stepDepth: clampedDepth,
      stairsLength: stairsLength,
      stringerLength: stringerLength,
      railingLength: railingLength,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('stairs_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('stairs_calc.export.floor_height')
        .replaceFirst('{value}', _floorHeight.toStringAsFixed(2)));
    buffer.writeln(_loc.translate('stairs_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_stairsType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('stairs_calc.export.parameters_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('stairs_calc.export.steps')
        .replaceFirst('{value}', _result.stepsCount.toString()));
    buffer.writeln(_loc.translate('stairs_calc.export.step_height')
        .replaceFirst('{value}', (_result.stepHeight * 100).toStringAsFixed(1)));
    buffer.writeln(_loc.translate('stairs_calc.export.step_depth')
        .replaceFirst('{value}', (_result.stepDepth * 100).toStringAsFixed(1)));
    buffer.writeln();
    buffer.writeln(_loc.translate('stairs_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('stairs_calc.export.stringer')
        .replaceFirst('{value}', _result.stringerLength.toStringAsFixed(1)));
    if (_needRailing) {
      buffer.writeln(_loc.translate('stairs_calc.export.railing')
          .replaceFirst('{value}', _result.railingLength.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('stairs_calc.export.footer'));
    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('stairs_calc.title')));
  }

  void _copyToClipboard() {
    final text = _generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_loc.translate('common.copied_to_clipboard')), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('stairs_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('stairs_calc.result.steps').toUpperCase(),
            value: '${_result.stepsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.stairs,
          ),
          ResultItem(
            label: _loc.translate('stairs_calc.result.step_height').toUpperCase(),
            value: '${(_result.stepHeight * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}',
            icon: Icons.height,
          ),
          ResultItem(
            label: _loc.translate('stairs_calc.result.length').toUpperCase(),
            value: '${_result.stairsLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
            icon: Icons.straighten,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildParametersCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: StairsType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _stairsType.index,
      onSelect: (index) {
        setState(() {
          _stairsType = StairsType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildDimensionsCard() {
    return _card(
      child: Column(
        children: [
          CalculatorTextField(label: _loc.translate('stairs_calc.label.floor_height'), value: _floorHeight, onChanged: (v) { setState(() { _floorHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 2.0, maxValue: 5.0),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('stairs_calc.label.opening_length'), value: _openingLength, onChanged: (v) { setState(() { _openingLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 2, maxValue: 8)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('stairs_calc.label.width'), value: _stairsWidth, onChanged: (v) { setState(() { _stairsWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.7, maxValue: 1.5)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('stairs_calc.option.railing'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('stairs_calc.option.railing_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needRailing,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needRailing = v; _update(); }); },
          ),
          if (_needRailing)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_loc.translate('stairs_calc.option.both_sides'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
              subtitle: Text(_loc.translate('stairs_calc.option.both_sides_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
              value: _needBothSides,
              activeColor: _accentColor,
              onChanged: (v) { setState(() { _needBothSides = v; _update(); }); },
            ),
        ],
      ),
    );
  }

  Widget _buildParametersCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('stairs_calc.section.calculated_params'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildParamRow(_loc.translate('stairs_calc.param.steps'), '${_result.stepsCount} ${_loc.translate('common.pcs')}'),
          _buildParamRow(_loc.translate('stairs_calc.param.step_height'), '${(_result.stepHeight * 100).toStringAsFixed(1)} ${_loc.translate('common.cm')}'),
          _buildParamRow(_loc.translate('stairs_calc.param.step_depth'), '${(_result.stepDepth * 100).toStringAsFixed(1)} ${_loc.translate('common.cm')}'),
          _buildParamRow(_loc.translate('stairs_calc.param.stairs_length'), '${_result.stairsLength.toStringAsFixed(2)} ${_loc.translate('common.meters')}'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _result.stepHeight >= 0.15 && _result.stepHeight <= 0.20
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _result.stepHeight >= 0.15 && _result.stepHeight <= 0.20
                      ? Icons.check_circle
                      : Icons.warning,
                  color: _result.stepHeight >= 0.15 && _result.stepHeight <= 0.20
                      ? Colors.green
                      : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _result.stepHeight >= 0.15 && _result.stepHeight <= 0.20
                        ? _loc.translate('stairs_calc.hint.optimal')
                        : _loc.translate('stairs_calc.hint.adjust'),
                    style: CalculatorDesignSystem.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
          Text(value, style: CalculatorDesignSystem.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('stairs_calc.materials.steps'),
        value: '${_result.stepsCount} ${_loc.translate('common.pcs')}',
        subtitle: '${_stairsWidth.toStringAsFixed(1)} × ${(_result.stepDepth * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}',
        icon: Icons.stairs,
      ),
      MaterialItem(
        name: _loc.translate('stairs_calc.materials.stringers'),
        value: '${(_result.stringerLength * 2).toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('stairs_calc.materials.stringers_desc'),
        icon: Icons.straighten,
      ),
    ];

    if (_needRailing && _result.railingLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('stairs_calc.materials.railing'),
        value: '${_result.railingLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _needBothSides
            ? _loc.translate('stairs_calc.materials.railing_both')
            : _loc.translate('stairs_calc.materials.railing_one'),
        icon: Icons.fence,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('stairs_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
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
