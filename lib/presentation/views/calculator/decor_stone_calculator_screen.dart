import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_decor_stone_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип декоративного камня
enum DecorStoneType {
  gypsum('decor_stone_calc.type.gypsum', 'decor_stone_calc.type.gypsum_desc', Icons.view_module),
  concrete('decor_stone_calc.type.concrete', 'decor_stone_calc.type.concrete_desc', Icons.grid_view),
  natural('decor_stone_calc.type.natural', 'decor_stone_calc.type.natural_desc', Icons.landscape);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const DecorStoneType(this.nameKey, this.descKey, this.icon);
}

enum DecorStoneInputMode { manual, wall }

class _DecorStoneResult {
  final double area;
  final double stoneArea;
  final double glueKg;
  final int glueBags;
  final double groutKg;
  final double primerLiters;

  const _DecorStoneResult({
    required this.area,
    required this.stoneArea,
    required this.glueKg,
    required this.glueBags,
    required this.groutKg,
    required this.primerLiters,
  });

  factory _DecorStoneResult.fromCalculatorResult(Map<String, double> values) {
    return _DecorStoneResult(
      area: values['area'] ?? 0,
      stoneArea: values['stoneArea'] ?? 0,
      glueKg: values['glueKg'] ?? 0,
      glueBags: (values['glueBags'] ?? 0).toInt(),
      groutKg: values['groutKg'] ?? 0,
      primerLiters: values['primerLiters'] ?? 0,
    );
  }
}

class DecorStoneCalculatorScreen extends ConsumerStatefulWidget {
  const DecorStoneCalculatorScreen({super.key});

  @override
  ConsumerState<DecorStoneCalculatorScreen> createState() => _DecorStoneCalculatorScreenState();
}

class _DecorStoneCalculatorScreenState extends ConsumerState<DecorStoneCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('decor_stone_calc.title');

  // Domain layer calculator
  final _calculator = CalculateDecorStoneV2();

  double _area = 15.0;
  double _wallWidth = 4.0;
  double _wallHeight = 2.7;
  double _jointWidth = 10.0; // мм

  DecorStoneType _stoneType = DecorStoneType.gypsum;
  DecorStoneInputMode _inputMode = DecorStoneInputMode.manual;
  bool _needGrout = true;
  bool _needPrimer = true;

  late _DecorStoneResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _DecorStoneResult _calculate() {
    final inputs = <String, double>{
      'area': _area,
      'wallWidth': _wallWidth,
      'wallHeight': _wallHeight,
      'stoneType': _stoneType.index.toDouble(),
      'jointWidth': _jointWidth,
      'inputMode': _inputMode.index.toDouble(),
      'needGrout': _needGrout ? 1.0 : 0.0,
      'needPrimer': _needPrimer ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _DecorStoneResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('decor_stone_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('decor_stone_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('decor_stone_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_stoneType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('decor_stone_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('decor_stone_calc.export.stone')
        .replaceFirst('{value}', _result.stoneArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('decor_stone_calc.export.glue')
        .replaceFirst('{value}', _result.glueBags.toString()));
    if (_needGrout) {
      buffer.writeln(_loc.translate('decor_stone_calc.export.grout')
          .replaceFirst('{value}', _result.groutKg.toStringAsFixed(1)));
    }
    if (_needPrimer) {
      buffer.writeln(_loc.translate('decor_stone_calc.export.primer')
          .replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('decor_stone_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('decor_stone_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('decor_stone_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('decor_stone_calc.result.stone').toUpperCase(),
            value: '${_result.stoneArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.view_module,
          ),
          ResultItem(
            label: _loc.translate('decor_stone_calc.result.glue').toUpperCase(),
            value: '${_result.glueBags} ${_loc.translate('common.pcs')}',
            icon: Icons.inventory_2,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildJointCard(),
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

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: DecorStoneType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _stoneType.index,
      onSelect: (index) {
        setState(() {
          _stoneType = DecorStoneType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('decor_stone_calc.mode.manual'),
              _loc.translate('decor_stone_calc.mode.wall'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = DecorStoneInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == DecorStoneInputMode.manual ? _buildManualInputs() : _buildWallInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('decor_stone_calc.label.area'),
      value: _area,
      min: 1,
      max: 100,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) { setState(() { _area = v; _update(); }); },
    );
  }

  Widget _buildWallInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('decor_stone_calc.label.width'), value: _wallWidth, onChanged: (v) { setState(() { _wallWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.5, maxValue: 15)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('decor_stone_calc.label.height'), value: _wallHeight, onChanged: (v) { setState(() { _wallHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 0.5, maxValue: 5)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('decor_stone_calc.label.wall_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w600)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJointCard() {
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('decor_stone_calc.label.joint_width'),
            value: _jointWidth,
            min: 0,
            max: 20,
            divisions: 20,
            suffix: _loc.translate('common.mm'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _jointWidth = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('decor_stone_calc.joint_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500),
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
            title: Text(_loc.translate('decor_stone_calc.option.grout'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('decor_stone_calc.option.grout_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needGrout,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needGrout = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('decor_stone_calc.option.primer'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('decor_stone_calc.option.primer_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needPrimer,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needPrimer = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('decor_stone_calc.materials.stone'),
        value: '${_result.stoneArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate(_stoneType.nameKey),
        icon: Icons.view_module,
      ),
      MaterialItem(
        name: _loc.translate('decor_stone_calc.materials.glue'),
        value: '${_result.glueBags} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.glueKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.inventory_2,
      ),
    ];

    if (_needGrout && _result.groutKg > 0) {
      items.add(MaterialItem(
        name: _loc.translate('decor_stone_calc.materials.grout'),
        value: '${_result.groutKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('decor_stone_calc.materials.grout_desc'),
        icon: Icons.format_color_fill,
      ));
    }

    if (_needPrimer && _result.primerLiters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('decor_stone_calc.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('decor_stone_calc.materials.primer_desc'),
        icon: Icons.format_paint,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('decor_stone_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_stoneType) {
      case DecorStoneType.gypsum:
        tips.addAll([
          _loc.translate('decor_stone_calc.tip.gypsum_1'),
          _loc.translate('decor_stone_calc.tip.gypsum_2'),
        ]);
        break;
      case DecorStoneType.concrete:
        tips.addAll([
          _loc.translate('decor_stone_calc.tip.concrete_1'),
          _loc.translate('decor_stone_calc.tip.concrete_2'),
        ]);
        break;
      case DecorStoneType.natural:
        tips.addAll([
          _loc.translate('decor_stone_calc.tip.natural_1'),
          _loc.translate('decor_stone_calc.tip.natural_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('decor_stone_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
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
