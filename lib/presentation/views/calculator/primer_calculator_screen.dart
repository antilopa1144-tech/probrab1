import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_primer_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип поверхности для грунтовки
enum PrimerSurfaceType {
  concrete('primer_calc.surface.concrete', 'primer_calc.surface.concrete_desc', Icons.foundation),
  plaster('primer_calc.surface.plaster', 'primer_calc.surface.plaster_desc', Icons.format_paint),
  drywall('primer_calc.surface.drywall', 'primer_calc.surface.drywall_desc', Icons.grid_view);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const PrimerSurfaceType(this.nameKey, this.descKey, this.icon);
}

/// Тип грунтовки
enum PrimerType {
  deep('primer_calc.type.deep', 'primer_calc.type.deep_desc'),
  contact('primer_calc.type.contact', 'primer_calc.type.contact_desc'),
  universal('primer_calc.type.universal', 'primer_calc.type.universal_desc');

  final String nameKey;
  final String descKey;
  const PrimerType(this.nameKey, this.descKey);
}

enum PrimerInputMode { manual, room }

/// Результат расчёта грунтовки
class _PrimerResult {
  final double area;
  final double litersNeeded;
  final int cansNeeded;
  final double canSize;
  final double totalLiters;
  final double excess;
  final int cans5l;
  final int cans10l;
  final int cans20l;

  const _PrimerResult({
    required this.area,
    required this.litersNeeded,
    required this.cansNeeded,
    required this.canSize,
    required this.totalLiters,
    required this.excess,
    required this.cans5l,
    required this.cans10l,
    required this.cans20l,
  });

  factory _PrimerResult.fromCalculatorResult(Map<String, double> values) {
    return _PrimerResult(
      area: values['area'] ?? 0,
      litersNeeded: values['litersNeeded'] ?? 0,
      cansNeeded: (values['cansNeeded'] ?? 0).toInt(),
      canSize: values['canSize'] ?? 10,
      totalLiters: values['totalLiters'] ?? 0,
      excess: values['excess'] ?? 0,
      cans5l: (values['cans_5l'] ?? 0).toInt(),
      cans10l: (values['cans_10l'] ?? 0).toInt(),
      cans20l: (values['cans_20l'] ?? 0).toInt(),
    );
  }
}

class PrimerCalculatorScreen extends ConsumerStatefulWidget {
  const PrimerCalculatorScreen({super.key});

  @override
  ConsumerState<PrimerCalculatorScreen> createState() => _PrimerCalculatorScreenState();
}

class _PrimerCalculatorScreenState extends ConsumerState<PrimerCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('primer_calc.title');

  // Domain layer calculator
  final _calculator = CalculatePrimerV2();

  // Состояние
  double _area = 30.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  int _layers = 2;
  double _canSize = 10.0; // литров

  PrimerSurfaceType _surfaceType = PrimerSurfaceType.concrete;
  PrimerType _primerType = PrimerType.deep;
  PrimerInputMode _inputMode = PrimerInputMode.manual;

  late _PrimerResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _PrimerResult _calculate() {
    final inputs = <String, double>{
      'surfaceType': _surfaceType.index.toDouble(),
      'primerType': _primerType.index.toDouble(),
      'layers': _layers.toDouble(),
      'canSize': _canSize,
    };

    // Передаём либо площадь, либо размеры комнаты
    if (_inputMode == PrimerInputMode.manual) {
      inputs['area'] = _area;
    } else {
      inputs['roomWidth'] = _roomWidth;
      inputs['roomLength'] = _roomLength;
      inputs['roomHeight'] = _roomHeight;
    }

    final result = _calculator(inputs, []);
    return _PrimerResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('primer_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('primer_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('primer_calc.export.surface')
        .replaceFirst('{value}', _loc.translate(_surfaceType.nameKey)));
    buffer.writeln(_loc.translate('primer_calc.export.primer_type')
        .replaceFirst('{value}', _loc.translate(_primerType.nameKey)));
    buffer.writeln(_loc.translate('primer_calc.export.layers')
        .replaceFirst('{value}', _layers.toString()));
    buffer.writeln();
    buffer.writeln(_loc.translate('primer_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('primer_calc.export.liters')
        .replaceFirst('{value}', _result.litersNeeded.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('primer_calc.export.cans')
        .replaceFirst('{value}', _result.cansNeeded.toString())
        .replaceFirst('{size}', _result.canSize.toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('primer_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('primer_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('primer_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('primer_calc.result.liters').toUpperCase(),
            value: '${_result.litersNeeded.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
            icon: Icons.water_drop,
          ),
          ResultItem(
            label: _loc.translate('primer_calc.result.cans').toUpperCase(),
            value: '${_result.cansNeeded}',
            icon: Icons.inventory_2,
          ),
        ],
      ),
      children: [
        _buildSurfaceSelector(),
        const SizedBox(height: 16),
        _buildPrimerTypeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
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

  Widget _buildSurfaceSelector() {
    return TypeSelectorGroup(
      options: PrimerSurfaceType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _surfaceType.index,
      onSelect: (index) {
        setState(() {
          _surfaceType = PrimerSurfaceType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildPrimerTypeSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('primer_calc.section.primer_type'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark)),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: PrimerType.values.map((t) => _loc.translate(t.nameKey)).toList(),
            selectedIndex: _primerType.index,
            onSelect: (index) {
              setState(() {
                _primerType = PrimerType.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_primerType.descKey),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('primer_calc.mode.manual'),
              _loc.translate('primer_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = PrimerInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == PrimerInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('primer_calc.label.area'),
      value: _area,
      min: 5,
      max: 500,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) { setState(() { _area = v; _update(); }); },
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('primer_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('primer_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        CalculatorTextField(label: _loc.translate('primer_calc.label.height'), value: _roomHeight, onChanged: (v) { setState(() { _roomHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 2, maxValue: 5),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('primer_calc.label.walls_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w600)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('primer_calc.label.layers'),
            value: _layers.toDouble(),
            min: 1,
            max: 3,
            divisions: 2,
            suffix: '',
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _layers = v.toInt(); _update(); }); },
          ),
          const SizedBox(height: 16),
          CalculatorSliderField(
            label: _loc.translate('primer_calc.label.can_size'),
            value: _canSize,
            min: 5,
            max: 20,
            divisions: 3,
            suffix: _loc.translate('common.liters'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _canSize = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('primer_calc.materials.primer'),
        value: '${_result.litersNeeded.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate(_primerType.nameKey),
        icon: Icons.water_drop,
      ),
    ];

    // Показываем оптимальный подбор канистр
    final cansInfo = <String>[];
    if (_result.cans5l > 0) cansInfo.add('${_result.cans5l}×5л');
    if (_result.cans10l > 0) cansInfo.add('${_result.cans10l}×10л');
    if (_result.cans20l > 0) cansInfo.add('${_result.cans20l}×20л');

    items.add(MaterialItem(
      name: _loc.translate('primer_calc.materials.cans'),
      value: cansInfo.isNotEmpty ? cansInfo.join(' + ') : '${_result.cansNeeded} ${_loc.translate('common.pcs')}',
      subtitle: '${_loc.translate('primer_calc.materials.total')}: ${_result.totalLiters.toStringAsFixed(0)} ${_loc.translate('common.liters')}',
      icon: Icons.inventory_2,
    ));

    // Показываем излишек если есть
    if (_result.excess > 0.5) {
      items.add(MaterialItem(
        name: _loc.translate('primer_calc.materials.excess'),
        value: '${_result.excess.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('primer_calc.materials.excess_desc'),
        icon: Icons.warning_amber,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('primer_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_surfaceType) {
      case PrimerSurfaceType.concrete:
        tips.addAll([
          _loc.translate('primer_calc.tip.concrete_1'),
          _loc.translate('primer_calc.tip.concrete_2'),
        ]);
        break;
      case PrimerSurfaceType.plaster:
        tips.addAll([
          _loc.translate('primer_calc.tip.plaster_1'),
          _loc.translate('primer_calc.tip.plaster_2'),
        ]);
        break;
      case PrimerSurfaceType.drywall:
        tips.addAll([
          _loc.translate('primer_calc.tip.drywall_1'),
          _loc.translate('primer_calc.tip.drywall_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('primer_calc.tip.common'));

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
