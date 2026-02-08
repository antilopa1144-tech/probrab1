import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_bathroom_waterproof_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип гидроизоляции
enum WaterproofType {
  liquid('waterproof_calc.type.liquid', 'waterproof_calc.type.liquid_desc', Icons.opacity),
  roll('waterproof_calc.type.roll', 'waterproof_calc.type.roll_desc', Icons.receipt_long),
  cement('waterproof_calc.type.cement', 'waterproof_calc.type.cement_desc', Icons.foundation);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const WaterproofType(this.nameKey, this.descKey, this.icon);
}

class _WaterproofResult {
  final double floorArea;
  final double wallArea;
  final double totalArea;
  final double waterproofKg;
  final double primerLiters;
  final double tapeMeters;

  const _WaterproofResult({
    required this.floorArea,
    required this.wallArea,
    required this.totalArea,
    required this.waterproofKg,
    required this.primerLiters,
    required this.tapeMeters,
  });

  factory _WaterproofResult.fromCalculatorResult(Map<String, double> values) {
    return _WaterproofResult(
      floorArea: values['floorArea'] ?? 0,
      wallArea: values['wallArea'] ?? 0,
      totalArea: values['totalArea'] ?? 0,
      waterproofKg: values['waterproofKg'] ?? 0,
      primerLiters: values['primerLiters'] ?? 0,
      tapeMeters: values['tapeMeters'] ?? 0,
    );
  }
}

class BathroomWaterproofCalculatorScreen extends ConsumerStatefulWidget {
  const BathroomWaterproofCalculatorScreen({super.key});

  @override
  ConsumerState<BathroomWaterproofCalculatorScreen> createState() => _BathroomWaterproofCalculatorScreenState();
}

class _BathroomWaterproofCalculatorScreenState extends ConsumerState<BathroomWaterproofCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('waterproof_calc.title');

  // Domain layer calculator
  final _calculator = CalculateBathroomWaterproofV2();

  double _length = 2.5;
  double _width = 1.8;
  double _wallHeight = 0.2; // высота захода на стены

  WaterproofType _waterproofType = WaterproofType.liquid;
  bool _needPrimer = true;
  bool _needTape = true;
  int _layers = 2;

  late _WaterproofResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _WaterproofResult _calculate() {
    final inputs = <String, double>{
      'length': _length,
      'width': _width,
      'wallHeight': _wallHeight,
      'waterproofType': _waterproofType.index.toDouble(),
      'layers': _layers.toDouble(),
      'needPrimer': _needPrimer ? 1.0 : 0.0,
      'needTape': _needTape ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _WaterproofResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('waterproof_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('waterproof_calc.export.floor_area')
        .replaceFirst('{value}', _result.floorArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('waterproof_calc.export.total_area')
        .replaceFirst('{value}', _result.totalArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('waterproof_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_waterproofType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('waterproof_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('waterproof_calc.export.waterproof')
        .replaceFirst('{value}', _result.waterproofKg.toStringAsFixed(1)));
    if (_needPrimer) {
      buffer.writeln(_loc.translate('waterproof_calc.export.primer')
          .replaceFirst('{value}', _result.primerLiters.toStringAsFixed(1)));
    }
    if (_needTape) {
      buffer.writeln(_loc.translate('waterproof_calc.export.tape')
          .replaceFirst('{value}', _result.tapeMeters.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('waterproof_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('waterproof_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('waterproof_calc.result.floor_area').toUpperCase(),
            value: '${_result.floorArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('waterproof_calc.result.total_area').toUpperCase(),
            value: '${_result.totalArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
          ResultItem(
            label: _loc.translate('waterproof_calc.result.waterproof').toUpperCase(),
            value: '${_result.waterproofKg.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
            icon: Icons.opacity,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
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

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_waterproofType) {
      case WaterproofType.liquid:
        tips.addAll([
          _loc.translate('waterproof_calc.tip.liquid_1'),
          _loc.translate('waterproof_calc.tip.liquid_2'),
        ]);
        break;
      case WaterproofType.roll:
        tips.addAll([
          _loc.translate('waterproof_calc.tip.roll_1'),
          _loc.translate('waterproof_calc.tip.roll_2'),
        ]);
        break;
      case WaterproofType.cement:
        tips.addAll([
          _loc.translate('waterproof_calc.tip.cement_1'),
          _loc.translate('waterproof_calc.tip.cement_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('waterproof_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: WaterproofType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _waterproofType.index,
      onSelect: (index) {
        setState(() {
          _waterproofType = WaterproofType.values[index];
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
              Expanded(child: CalculatorTextField(label: _loc.translate('waterproof_calc.label.length'), value: _length, onChanged: (v) { setState(() { _length = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 10)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('waterproof_calc.label.width'), value: _width, onChanged: (v) { setState(() { _width = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('waterproof_calc.label.wall_height'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w600)),
              Text('${(_wallHeight * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _wallHeight * 100,
            min: 10,
            max: 50,
            divisions: 8,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _wallHeight = v / 100; _update(); }); },
          ),
          Text(
            _loc.translate('waterproof_calc.wall_height_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildLayersCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('waterproof_calc.label.layers'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w600)),
              Text('$_layers', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _layers.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _layers = v.toInt(); _update(); }); },
          ),
          Text(
            _loc.translate('waterproof_calc.layers_hint'),
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
            title: Text(_loc.translate('waterproof_calc.option.primer'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('waterproof_calc.option.primer_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needPrimer,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needPrimer = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('waterproof_calc.option.tape'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('waterproof_calc.option.tape_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needTape,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needTape = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('waterproof_calc.materials.waterproof'),
        value: '${_result.waterproofKg.toStringAsFixed(1)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate(_waterproofType.nameKey),
        icon: Icons.opacity,
      ),
    ];

    if (_needPrimer && _result.primerLiters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('waterproof_calc.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('waterproof_calc.materials.primer_desc'),
        icon: Icons.format_paint,
      ));
    }

    if (_needTape && _result.tapeMeters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('waterproof_calc.materials.tape'),
        value: '${_result.tapeMeters.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('waterproof_calc.materials.tape_desc'),
        icon: Icons.content_cut,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('waterproof_calc.section.materials'),
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
