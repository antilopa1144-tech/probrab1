import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_ventilation_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип вентиляции
enum VentilationType {
  natural('ventilation_calc.type.natural', 'ventilation_calc.type.natural_desc', Icons.air),
  supply('ventilation_calc.type.supply', 'ventilation_calc.type.supply_desc', Icons.wind_power),
  exhaust('ventilation_calc.type.exhaust', 'ventilation_calc.type.exhaust_desc', Icons.hvac);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const VentilationType(this.nameKey, this.descKey, this.icon);
}

class _VentilationResult {
  final double roomVolume;
  final double airflowRequired;
  final double ductLength;
  final int grillsCount;
  final int fittingsCount;
  final int recuperatorCount;

  const _VentilationResult({
    required this.roomVolume,
    required this.airflowRequired,
    required this.ductLength,
    required this.grillsCount,
    required this.fittingsCount,
    required this.recuperatorCount,
  });

  factory _VentilationResult.fromCalculatorResult(Map<String, double> values) {
    return _VentilationResult(
      roomVolume: values['roomVolume'] ?? 0,
      airflowRequired: values['airflowRequired'] ?? 0,
      ductLength: values['ductLength'] ?? 0,
      grillsCount: (values['grillsCount'] ?? 0).toInt(),
      fittingsCount: (values['fittingsCount'] ?? 0).toInt(),
      recuperatorCount: (values['recuperatorCount'] ?? 0).toInt(),
    );
  }
}

class VentilationCalculatorScreen extends ConsumerStatefulWidget {
  const VentilationCalculatorScreen({super.key});

  @override
  ConsumerState<VentilationCalculatorScreen> createState() => _VentilationCalculatorScreenState();
}

class _VentilationCalculatorScreenState extends ConsumerState<VentilationCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('ventilation_calc.title');

  // Domain layer calculator
  final _calculator = CalculateVentilationV2();

  double _roomArea = 50.0;
  double _ceilingHeight = 2.7;
  int _roomsCount = 4;

  VentilationType _ventilationType = VentilationType.supply;
  bool _needRecovery = false;

  late _VentilationResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _VentilationResult _calculate() {
    final inputs = <String, double>{
      'roomArea': _roomArea,
      'ceilingHeight': _ceilingHeight,
      'roomsCount': _roomsCount.toDouble(),
      'ventilationType': _ventilationType.index.toDouble(),
      'needRecovery': _needRecovery ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _VentilationResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('ventilation_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('ventilation_calc.export.volume')
        .replaceFirst('{value}', _result.roomVolume.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('ventilation_calc.export.airflow')
        .replaceFirst('{value}', _result.airflowRequired.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('ventilation_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_ventilationType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('ventilation_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('ventilation_calc.export.ducts')
        .replaceFirst('{value}', _result.ductLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('ventilation_calc.export.grills')
        .replaceFirst('{value}', _result.grillsCount.toString()));
    buffer.writeln(_loc.translate('ventilation_calc.export.fittings')
        .replaceFirst('{value}', _result.fittingsCount.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('ventilation_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('ventilation_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('ventilation_calc.result.volume').toUpperCase(),
            value: '${_result.roomVolume.toStringAsFixed(0)} ${_loc.translate('common.cbm')}',
            icon: Icons.square_foot,
          ),
          ResultItem(
            label: _loc.translate('ventilation_calc.result.airflow').toUpperCase(),
            value: '${_result.airflowRequired.toStringAsFixed(0)} ${_loc.translate('common.cbm_h')}',
            icon: Icons.air,
          ),
          ResultItem(
            label: _loc.translate('ventilation_calc.result.ducts').toUpperCase(),
            value: '${_result.ductLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
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
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_ventilationType) {
      case VentilationType.natural:
        tips.addAll([
          _loc.translate('ventilation_calc.tip.natural_1'),
          _loc.translate('ventilation_calc.tip.natural_2'),
        ]);
        break;
      case VentilationType.supply:
        tips.addAll([
          _loc.translate('ventilation_calc.tip.supply_1'),
          _loc.translate('ventilation_calc.tip.supply_2'),
        ]);
        break;
      case VentilationType.exhaust:
        tips.addAll([
          _loc.translate('ventilation_calc.tip.exhaust_1'),
          _loc.translate('ventilation_calc.tip.exhaust_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('ventilation_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: VentilationType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _ventilationType.index,
      onSelect: (index) {
        setState(() {
          _ventilationType = VentilationType.values[index];
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('ventilation_calc.label.area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_roomArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _roomArea, min: 20, max: 300, activeColor: _accentColor, onChanged: (v) { setState(() { _roomArea = v; _update(); }); }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('ventilation_calc.label.ceiling_height'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_ceilingHeight.toStringAsFixed(1)} ${_loc.translate('common.meters')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _ceilingHeight, min: 2.2, max: 4.0, divisions: 9, activeColor: _accentColor, onChanged: (v) { setState(() { _ceilingHeight = v; _update(); }); }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('ventilation_calc.label.rooms'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('$_roomsCount ${_loc.translate('common.pcs')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _roomsCount.toDouble(), min: 1, max: 15, divisions: 14, activeColor: _accentColor, onChanged: (v) { setState(() { _roomsCount = v.toInt(); _update(); }); }),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_loc.translate('ventilation_calc.option.recovery'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
        subtitle: Text(_loc.translate('ventilation_calc.option.recovery_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
        value: _needRecovery,
        activeTrackColor: _accentColor,
        onChanged: (v) { setState(() { _needRecovery = v; _update(); }); },
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('ventilation_calc.materials.ducts'),
        value: '${_result.ductLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('ventilation_calc.materials.ducts_desc'),
        icon: Icons.straighten,
      ),
      MaterialItem(
        name: _loc.translate('ventilation_calc.materials.grills'),
        value: '${_result.grillsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('ventilation_calc.materials.grills_desc'),
        icon: Icons.grid_view,
      ),
      MaterialItem(
        name: _loc.translate('ventilation_calc.materials.fittings'),
        value: '${_result.fittingsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('ventilation_calc.materials.fittings_desc'),
        icon: Icons.settings,
      ),
    ];

    if (_needRecovery) {
      items.add(MaterialItem(
        name: _loc.translate('ventilation_calc.materials.recuperator'),
        value: '1 ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('ventilation_calc.materials.recuperator_desc'),
        icon: Icons.swap_horiz,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('ventilation_calc.section.materials'),
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
