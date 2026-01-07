import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
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

  const _VentilationResult({
    required this.roomVolume,
    required this.airflowRequired,
    required this.ductLength,
    required this.grillsCount,
    required this.fittingsCount,
  });
}

class VentilationCalculatorScreen extends StatefulWidget {
  const VentilationCalculatorScreen({super.key});

  @override
  State<VentilationCalculatorScreen> createState() => _VentilationCalculatorScreenState();
}

class _VentilationCalculatorScreenState extends State<VentilationCalculatorScreen> {
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

  _VentilationResult _calculate() {
    final roomVolume = _roomArea * _ceilingHeight;

    // Кратность воздухообмена зависит от типа
    double exchangeRate;
    switch (_ventilationType) {
      case VentilationType.natural:
        exchangeRate = 1.0;
      case VentilationType.supply:
        exchangeRate = 2.0;
      case VentilationType.exhaust:
        exchangeRate = 1.5;
    }

    final airflowRequired = roomVolume * exchangeRate;

    // Воздуховоды: примерно 3м на комнату + магистраль
    final ductLength = _roomsCount * 3 + (_roomArea / 10) * 1.15;

    // Решётки: по 2 на комнату (приток + вытяжка)
    final grillsCount = _roomsCount * 2;

    // Фитинги: колена, тройники, переходники
    final fittingsCount = _roomsCount * 3 + 4;

    return _VentilationResult(
      roomVolume: roomVolume,
      airflowRequired: airflowRequired,
      ductLength: ductLength,
      grillsCount: grillsCount,
      fittingsCount: fittingsCount,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
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

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('ventilation_calc.title')));
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
      title: _loc.translate('ventilation_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
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
        const SizedBox(height: 20),
      ],
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
        activeColor: _accentColor,
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
