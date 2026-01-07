import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
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

class _PrimerResult {
  final double area;
  final double litersNeeded;
  final int cansNeeded;
  final double canSize;

  const _PrimerResult({
    required this.area,
    required this.litersNeeded,
    required this.cansNeeded,
    required this.canSize,
  });
}

class PrimerCalculatorScreen extends StatefulWidget {
  const PrimerCalculatorScreen({super.key});

  @override
  State<PrimerCalculatorScreen> createState() => _PrimerCalculatorScreenState();
}

class _PrimerCalculatorScreenState extends State<PrimerCalculatorScreen> {
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

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Расход грунтовки л/м² в зависимости от поверхности и типа
  double _getConsumptionRate() {
    // Базовый расход по типу грунтовки
    double baseRate = switch (_primerType) {
      PrimerType.deep => 0.1,
      PrimerType.contact => 0.3,
      PrimerType.universal => 0.15,
    };

    // Коэффициент по поверхности
    double surfaceMultiplier = switch (_surfaceType) {
      PrimerSurfaceType.concrete => 1.3,    // пористый бетон
      PrimerSurfaceType.plaster => 1.0,     // штукатурка стандартно
      PrimerSurfaceType.drywall => 0.8,     // гипсокартон меньше впитывает
    };

    return baseRate * surfaceMultiplier;
  }

  _PrimerResult _calculate() {
    double area = _area;
    if (_inputMode == PrimerInputMode.room) {
      // Площадь стен = периметр × высота
      area = 2 * (_roomWidth + _roomLength) * _roomHeight;
    }

    final consumptionRate = _getConsumptionRate();
    final litersNeeded = area * consumptionRate * _layers * 1.1; // +10% запас
    final cansNeeded = (litersNeeded / _canSize).ceil();

    return _PrimerResult(
      area: area,
      litersNeeded: litersNeeded,
      cansNeeded: cansNeeded,
      canSize: _canSize,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
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

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('primer_calc.title')));
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
      title: _loc.translate('primer_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
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
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
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
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_loc.translate('primer_calc.label.area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
            Text('${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(value: _area, min: 5, max: 500, activeColor: _accentColor, onChanged: (v) { setState(() { _area = v; _update(); }); }),
      ],
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
              Text(_loc.translate('primer_calc.label.walls_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('primer_calc.label.layers'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('$_layers', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _layers.toDouble(), min: 1, max: 3, divisions: 2, activeColor: _accentColor, onChanged: (v) { setState(() { _layers = v.toInt(); _update(); }); }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('primer_calc.label.can_size'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_canSize.toStringAsFixed(0)} ${_loc.translate('common.liters')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _canSize, min: 5, max: 20, divisions: 3, activeColor: _accentColor, onChanged: (v) { setState(() { _canSize = v; _update(); }); }),
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
      MaterialItem(
        name: _loc.translate('primer_calc.materials.cans'),
        value: '${_result.cansNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.canSize.toStringAsFixed(0)} ${_loc.translate('common.liters')}',
        icon: Icons.inventory_2,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('primer_calc.section.materials'),
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
