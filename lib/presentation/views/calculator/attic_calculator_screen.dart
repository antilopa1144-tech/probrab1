import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_attic_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип мансарды
enum AtticType {
  cold('attic_calc.type.cold', 'attic_calc.type.cold_desc', Icons.ac_unit),
  warm('attic_calc.type.warm', 'attic_calc.type.warm_desc', Icons.whatshot),
  living('attic_calc.type.living', 'attic_calc.type.living_desc', Icons.home);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const AtticType(this.nameKey, this.descKey, this.icon);
}

class _AtticResult {
  final double floorArea;
  final double roofArea;
  final double insulationArea;
  final double vaporBarrierArea;
  final double membraneArea;
  final double gypsumArea;

  const _AtticResult({
    required this.floorArea,
    required this.roofArea,
    required this.insulationArea,
    required this.vaporBarrierArea,
    required this.membraneArea,
    required this.gypsumArea,
  });

  factory _AtticResult.fromCalculatorResult(Map<String, double> values) {
    return _AtticResult(
      floorArea: values['floorArea'] ?? 0,
      roofArea: values['roofArea'] ?? 0,
      insulationArea: values['insulationArea'] ?? 0,
      vaporBarrierArea: values['vaporBarrierArea'] ?? 0,
      membraneArea: values['membraneArea'] ?? 0,
      gypsumArea: values['gypsumArea'] ?? 0,
    );
  }
}

class AtticCalculatorScreen extends ConsumerStatefulWidget {
  const AtticCalculatorScreen({super.key});

  @override
  ConsumerState<AtticCalculatorScreen> createState() => _AtticCalculatorScreenState();
}

class _AtticCalculatorScreenState extends ConsumerState<AtticCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('attic_calc.title');

  // Domain layer calculator
  final _calculator = CalculateAtticV2();

  double _floorLength = 8.0;
  double _floorWidth = 6.0;
  double _roofHeight = 2.5;
  double _insulationThickness = 150.0; // мм

  AtticType _atticType = AtticType.warm;
  bool _needVaporBarrier = true;
  bool _needMembrane = true;
  bool _needGypsum = true;

  late _AtticResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _AtticResult _calculate() {
    final inputs = <String, double>{
      'floorLength': _floorLength,
      'floorWidth': _floorWidth,
      'roofHeight': _roofHeight,
      'insulationThickness': _insulationThickness,
      'atticType': _atticType.index.toDouble(),
      'needVaporBarrier': _needVaporBarrier ? 1.0 : 0.0,
      'needMembrane': _needMembrane ? 1.0 : 0.0,
      'needGypsum': _needGypsum ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _AtticResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('attic_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('attic_calc.export.floor_area')
        .replaceFirst('{value}', _result.floorArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('attic_calc.export.roof_area')
        .replaceFirst('{value}', _result.roofArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('attic_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_atticType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('attic_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    if (_result.insulationArea > 0) {
      buffer.writeln(_loc.translate('attic_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    if (_result.vaporBarrierArea > 0) {
      buffer.writeln(_loc.translate('attic_calc.export.vapor_barrier')
          .replaceFirst('{value}', _result.vaporBarrierArea.toStringAsFixed(1)));
    }
    if (_result.membraneArea > 0) {
      buffer.writeln(_loc.translate('attic_calc.export.membrane')
          .replaceFirst('{value}', _result.membraneArea.toStringAsFixed(1)));
    }
    if (_result.gypsumArea > 0) {
      buffer.writeln(_loc.translate('attic_calc.export.gypsum')
          .replaceFirst('{value}', _result.gypsumArea.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('attic_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('attic_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('attic_calc.result.floor_area').toUpperCase(),
            value: '${_result.floorArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('attic_calc.result.roof_area').toUpperCase(),
            value: '${_result.roofArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.roofing,
          ),
          ResultItem(
            label: _loc.translate('attic_calc.result.insulation').toUpperCase(),
            value: '${_result.insulationArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        if (_atticType != AtticType.cold) ...[
          _buildInsulationCard(),
          const SizedBox(height: 16),
        ],
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

    switch (_atticType) {
      case AtticType.cold:
        tips.addAll([
          _loc.translate('attic_calc.tip.cold_1'),
          _loc.translate('attic_calc.tip.cold_2'),
        ]);
        break;
      case AtticType.warm:
        tips.addAll([
          _loc.translate('attic_calc.tip.warm_1'),
          _loc.translate('attic_calc.tip.warm_2'),
        ]);
        break;
      case AtticType.living:
        tips.addAll([
          _loc.translate('attic_calc.tip.living_1'),
          _loc.translate('attic_calc.tip.living_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('attic_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: AtticType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _atticType.index,
      onSelect: (index) {
        setState(() {
          _atticType = AtticType.values[index];
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
              Expanded(child: CalculatorTextField(label: _loc.translate('attic_calc.label.length'), value: _floorLength, onChanged: (v) { setState(() { _floorLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 20)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('attic_calc.label.width'), value: _floorWidth, onChanged: (v) { setState(() { _floorWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 3, maxValue: 15)),
            ],
          ),
          const SizedBox(height: 12),
          CalculatorTextField(label: _loc.translate('attic_calc.label.roof_height'), value: _roofHeight, onChanged: (v) { setState(() { _roofHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1.5, maxValue: 5),
        ],
      ),
    );
  }

  Widget _buildInsulationCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('attic_calc.label.insulation_thickness'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
              Text('${_insulationThickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _insulationThickness,
            min: 50,
            max: 300,
            divisions: 10,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _insulationThickness = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          if (_atticType != AtticType.cold) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_loc.translate('attic_calc.option.vapor_barrier'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
              subtitle: Text(_loc.translate('attic_calc.option.vapor_barrier_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
              value: _needVaporBarrier,
              activeTrackColor: _accentColor,
              onChanged: (v) { setState(() { _needVaporBarrier = v; _update(); }); },
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('attic_calc.option.membrane'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('attic_calc.option.membrane_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
            value: _needMembrane,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needMembrane = v; _update(); }); },
          ),
          if (_atticType == AtticType.living)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_loc.translate('attic_calc.option.gypsum'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
              subtitle: Text(_loc.translate('attic_calc.option.gypsum_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
              value: _needGypsum,
              activeTrackColor: _accentColor,
              onChanged: (v) { setState(() { _needGypsum = v; _update(); }); },
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[];

    if (_result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('attic_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: '${_insulationThickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}',
        icon: Icons.layers,
      ));
    }

    if (_result.vaporBarrierArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('attic_calc.materials.vapor_barrier'),
        value: '${_result.vaporBarrierArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('attic_calc.materials.vapor_barrier_desc'),
        icon: Icons.water_drop,
      ));
    }

    if (_result.membraneArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('attic_calc.materials.membrane'),
        value: '${_result.membraneArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('attic_calc.materials.membrane_desc'),
        icon: Icons.filter_alt,
      ));
    }

    if (_result.gypsumArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('attic_calc.materials.gypsum'),
        value: '${_result.gypsumArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('attic_calc.materials.gypsum_desc'),
        icon: Icons.grid_view,
      ));
    }

    if (items.isEmpty) {
      items.add(MaterialItem(
        name: _loc.translate('attic_calc.materials.roof_only'),
        value: '${_result.roofArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.roofing,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('attic_calc.section.materials'),
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
