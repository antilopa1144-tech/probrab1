import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_balcony_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип балкона
enum BalconyType {
  open('balcony_calc.type.open', 'balcony_calc.type.open_desc', Icons.balcony),
  glazed('balcony_calc.type.glazed', 'balcony_calc.type.glazed_desc', Icons.window),
  warm('balcony_calc.type.warm', 'balcony_calc.type.warm_desc', Icons.whatshot);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const BalconyType(this.nameKey, this.descKey, this.icon);
}

class _BalconyResult {
  final double floorArea;
  final double wallArea;
  final double ceilingArea;
  final double insulationArea;
  final double finishingArea;
  final double glazingLength;

  const _BalconyResult({
    required this.floorArea,
    required this.wallArea,
    required this.ceilingArea,
    required this.insulationArea,
    required this.finishingArea,
    required this.glazingLength,
  });

  factory _BalconyResult.fromCalculatorResult(Map<String, double> values) {
    return _BalconyResult(
      floorArea: values['floorArea'] ?? 0,
      wallArea: values['wallArea'] ?? 0,
      ceilingArea: values['ceilingArea'] ?? 0,
      insulationArea: values['insulationArea'] ?? 0,
      finishingArea: values['finishingArea'] ?? 0,
      glazingLength: values['glazingLength'] ?? 0,
    );
  }
}

class BalconyCalculatorScreen extends ConsumerStatefulWidget {
  const BalconyCalculatorScreen({super.key});

  @override
  ConsumerState<BalconyCalculatorScreen> createState() => _BalconyCalculatorScreenState();
}

class _BalconyCalculatorScreenState extends ConsumerState<BalconyCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('balcony_calc.title');

  // Domain layer calculator
  final _calculator = CalculateBalconyV2();

  double _length = 3.0;
  double _width = 1.2;
  double _height = 2.5;

  BalconyType _balconyType = BalconyType.glazed;
  bool _needInsulation = true;
  bool _needFloorFinishing = true;
  bool _needWallFinishing = true;

  late _BalconyResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _BalconyResult _calculate() {
    final inputs = <String, double>{
      'length': _length,
      'width': _width,
      'height': _height,
      'balconyType': _balconyType.index.toDouble(),
      'needInsulation': _needInsulation ? 1.0 : 0.0,
      'needFloorFinishing': _needFloorFinishing ? 1.0 : 0.0,
      'needWallFinishing': _needWallFinishing ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _BalconyResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('balcony_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('balcony_calc.export.floor_area')
        .replaceFirst('{value}', _result.floorArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('balcony_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_balconyType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('balcony_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    if (_result.glazingLength > 0) {
      buffer.writeln(_loc.translate('balcony_calc.export.glazing')
          .replaceFirst('{value}', _result.glazingLength.toStringAsFixed(1)));
    }
    if (_result.insulationArea > 0) {
      buffer.writeln(_loc.translate('balcony_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('balcony_calc.export.finishing')
        .replaceFirst('{value}', _result.finishingArea.toStringAsFixed(1)));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('balcony_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('balcony_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('balcony_calc.result.floor_area').toUpperCase(),
            value: '${_result.floorArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('balcony_calc.result.wall_area').toUpperCase(),
            value: '${_result.wallArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
          ResultItem(
            label: _loc.translate('balcony_calc.result.finishing').toUpperCase(),
            value: '${_result.finishingArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.format_paint,
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
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_balconyType) {
      case BalconyType.open:
        tips.addAll([
          _loc.translate('balcony_calc.tip.open_1'),
          _loc.translate('balcony_calc.tip.open_2'),
        ]);
        break;
      case BalconyType.glazed:
        tips.addAll([
          _loc.translate('balcony_calc.tip.glazed_1'),
          _loc.translate('balcony_calc.tip.glazed_2'),
        ]);
        break;
      case BalconyType.warm:
        tips.addAll([
          _loc.translate('balcony_calc.tip.warm_1'),
          _loc.translate('balcony_calc.tip.warm_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('balcony_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: BalconyType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _balconyType.index,
      onSelect: (index) {
        setState(() {
          _balconyType = BalconyType.values[index];
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
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('balcony_calc.label.length'), value: _length, onChanged: (v) { setState(() { _length = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 10)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('balcony_calc.label.width'), value: _width, onChanged: (v) { setState(() { _width = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.5, maxValue: 3)),
            ],
          ),
          const SizedBox(height: 12),
          CalculatorTextField(label: _loc.translate('balcony_calc.label.height'), value: _height, onChanged: (v) { setState(() { _height = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 2, maxValue: 3.5),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          if (_balconyType == BalconyType.warm)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_loc.translate('balcony_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
              subtitle: Text(_loc.translate('balcony_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
              value: _needInsulation,
              activeTrackColor: _accentColor,
              onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('balcony_calc.option.floor_finishing'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('balcony_calc.option.floor_finishing_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needFloorFinishing,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needFloorFinishing = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('balcony_calc.option.wall_finishing'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('balcony_calc.option.wall_finishing_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needWallFinishing,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needWallFinishing = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[];

    if (_result.glazingLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('balcony_calc.materials.glazing'),
        value: '${_result.glazingLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('balcony_calc.materials.glazing_desc'),
        icon: Icons.window,
      ));
    }

    if (_result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('balcony_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('balcony_calc.materials.insulation_desc'),
        icon: Icons.layers,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('balcony_calc.materials.finishing'),
      value: '${_result.finishingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
      subtitle: _loc.translate('balcony_calc.materials.finishing_desc'),
      icon: Icons.format_paint,
    ));

    return MaterialsCardModern(
      title: _loc.translate('balcony_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
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
