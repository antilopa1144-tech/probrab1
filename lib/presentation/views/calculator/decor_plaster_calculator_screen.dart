import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_decor_plaster_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип декоративной штукатурки
enum DecorPlasterType {
  venetian('decor_plaster_calc.type.venetian', 'decor_plaster_calc.type.venetian_desc', Icons.gradient),
  bark('decor_plaster_calc.type.bark', 'decor_plaster_calc.type.bark_desc', Icons.texture),
  silk('decor_plaster_calc.type.silk', 'decor_plaster_calc.type.silk_desc', Icons.blur_on);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const DecorPlasterType(this.nameKey, this.descKey, this.icon);
}

enum DecorPlasterInputMode { manual, room }

class _DecorPlasterResult {
  final double area;
  final double plasterKg;
  final int plasterBuckets;
  final double primerLiters;
  final double waxKg;

  const _DecorPlasterResult({
    required this.area,
    required this.plasterKg,
    required this.plasterBuckets,
    required this.primerLiters,
    required this.waxKg,
  });

  factory _DecorPlasterResult.fromCalculatorResult(Map<String, double> values) {
    return _DecorPlasterResult(
      area: values['area'] ?? 0,
      plasterKg: values['plasterKg'] ?? 0,
      plasterBuckets: (values['plasterBuckets'] ?? 0).toInt(),
      primerLiters: values['primerLiters'] ?? 0,
      waxKg: values['waxKg'] ?? 0,
    );
  }
}

class DecorPlasterCalculatorScreen extends ConsumerStatefulWidget {
  const DecorPlasterCalculatorScreen({super.key});

  @override
  ConsumerState<DecorPlasterCalculatorScreen> createState() => _DecorPlasterCalculatorScreenState();
}

class _DecorPlasterCalculatorScreenState extends ConsumerState<DecorPlasterCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('decor_plaster_calc.title');

  // Domain layer calculator
  final _calculator = CalculateDecorPlasterV2();

  double _area = 30.0;
  double _wallWidth = 5.0;
  double _wallHeight = 2.7;
  int _layers = 2;

  DecorPlasterType _plasterType = DecorPlasterType.venetian;
  DecorPlasterInputMode _inputMode = DecorPlasterInputMode.manual;
  bool _needPrimer = true;
  bool _needWax = true;

  late _DecorPlasterResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _DecorPlasterResult _calculate() {
    final inputs = <String, double>{
      'area': _area,
      'wallWidth': _wallWidth,
      'wallHeight': _wallHeight,
      'plasterType': _plasterType.index.toDouble(),
      'layers': _layers.toDouble(),
      'inputMode': _inputMode.index.toDouble(),
      'needPrimer': _needPrimer ? 1.0 : 0.0,
      'needWax': _needWax ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _DecorPlasterResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('decor_plaster_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('decor_plaster_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('decor_plaster_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_plasterType.nameKey)));
    buffer.writeln(_loc.translate('decor_plaster_calc.export.layers')
        .replaceFirst('{value}', _layers.toString()));
    buffer.writeln();
    buffer.writeln(_loc.translate('decor_plaster_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('decor_plaster_calc.export.plaster')
        .replaceFirst('{value}', _result.plasterBuckets.toString()));
    if (_needPrimer) {
      buffer.writeln(_loc.translate('decor_plaster_calc.export.primer')
          .replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1)));
    }
    if (_needWax && _result.waxKg > 0) {
      buffer.writeln(_loc.translate('decor_plaster_calc.export.wax')
          .replaceFirst('{value}', _result.waxKg.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('decor_plaster_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('decor_plaster_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('decor_plaster_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('decor_plaster_calc.result.plaster').toUpperCase(),
            value: '${_result.plasterBuckets} ${_loc.translate('common.pcs')}',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: _loc.translate('decor_plaster_calc.result.layers').toUpperCase(),
            value: '$_layers',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildLayersCard(),
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
      options: DecorPlasterType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _plasterType.index,
      onSelect: (index) {
        setState(() {
          _plasterType = DecorPlasterType.values[index];
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
              _loc.translate('decor_plaster_calc.mode.manual'),
              _loc.translate('decor_plaster_calc.mode.wall'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = DecorPlasterInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == DecorPlasterInputMode.manual ? _buildManualInputs() : _buildWallInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('decor_plaster_calc.label.area'),
      value: _area,
      min: 5,
      max: 200,
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
            Expanded(child: CalculatorTextField(label: _loc.translate('decor_plaster_calc.label.width'), value: _wallWidth, onChanged: (v) { setState(() { _wallWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('decor_plaster_calc.label.height'), value: _wallHeight, onChanged: (v) { setState(() { _wallHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 5)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('decor_plaster_calc.label.wall_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLayersCard() {
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('decor_plaster_calc.label.layers'),
            value: _layers.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            suffix: '',
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _layers = v.toInt(); _update(); }); },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('decor_plaster_calc.layers_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark)),
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
            title: Text(_loc.translate('decor_plaster_calc.option.primer'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('decor_plaster_calc.option.primer_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
            value: _needPrimer,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needPrimer = v; _update(); }); },
          ),
          if (_plasterType == DecorPlasterType.venetian)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_loc.translate('decor_plaster_calc.option.wax'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
              subtitle: Text(_loc.translate('decor_plaster_calc.option.wax_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextSecondary(_isDark))),
              value: _needWax,
              activeTrackColor: _accentColor,
              onChanged: (v) { setState(() { _needWax = v; _update(); }); },
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('decor_plaster_calc.materials.plaster'),
        value: '${_result.plasterBuckets} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plasterKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        icon: Icons.inventory_2,
      ),
    ];

    if (_needPrimer && _result.primerLiters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('decor_plaster_calc.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('decor_plaster_calc.materials.primer_desc'),
        icon: Icons.format_paint,
      ));
    }

    if (_needWax && _result.waxKg > 0) {
      items.add(MaterialItem(
        name: _loc.translate('decor_plaster_calc.materials.wax'),
        value: '${_result.waxKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('decor_plaster_calc.materials.wax_desc'),
        icon: Icons.opacity,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('decor_plaster_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_plasterType) {
      case DecorPlasterType.venetian:
        tips.addAll([
          _loc.translate('decor_plaster_calc.tip.venetian_1'),
          _loc.translate('decor_plaster_calc.tip.venetian_2'),
        ]);
        break;
      case DecorPlasterType.bark:
        tips.addAll([
          _loc.translate('decor_plaster_calc.tip.bark_1'),
          _loc.translate('decor_plaster_calc.tip.bark_2'),
        ]);
        break;
      case DecorPlasterType.silk:
        tips.addAll([
          _loc.translate('decor_plaster_calc.tip.silk_1'),
          _loc.translate('decor_plaster_calc.tip.silk_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('decor_plaster_calc.tip.common'));

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
