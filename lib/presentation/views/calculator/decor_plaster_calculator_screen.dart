import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
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
}

class DecorPlasterCalculatorScreen extends StatefulWidget {
  const DecorPlasterCalculatorScreen({super.key});

  @override
  State<DecorPlasterCalculatorScreen> createState() => _DecorPlasterCalculatorScreenState();
}

class _DecorPlasterCalculatorScreenState extends State<DecorPlasterCalculatorScreen> {
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

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _DecorPlasterResult _calculate() {
    double area = _area;
    if (_inputMode == DecorPlasterInputMode.room) {
      area = _wallWidth * _wallHeight;
    }

    // Расход зависит от типа штукатурки
    double consumptionPerSqm;
    switch (_plasterType) {
      case DecorPlasterType.venetian:
        consumptionPerSqm = 0.4; // кг/м² на слой
      case DecorPlasterType.bark:
        consumptionPerSqm = 2.5; // кг/м² на слой
      case DecorPlasterType.silk:
        consumptionPerSqm = 0.3; // кг/м² на слой
    }

    final plasterKg = area * consumptionPerSqm * _layers * 1.1; // +10% запас
    final plasterBuckets = (plasterKg / 25).ceil(); // ведро 25 кг

    // Грунтовка: 0.15 л/м²
    final primerLiters = _needPrimer ? area * 0.15 * 1.1 : 0.0;

    // Воск/лак: 0.05 кг/м² для венецианской
    final waxKg = _needWax && _plasterType == DecorPlasterType.venetian
        ? area * 0.05 * 1.1
        : 0.0;

    return _DecorPlasterResult(
      area: area,
      plasterKg: plasterKg,
      plasterBuckets: plasterBuckets,
      primerLiters: primerLiters,
      waxKg: waxKg,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
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

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('decor_plaster_calc.title')));
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
      title: _loc.translate('decor_plaster_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_loc.translate('decor_plaster_calc.label.area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
            Text('${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(value: _area, min: 5, max: 200, activeColor: _accentColor, onChanged: (v) { setState(() { _area = v; _update(); }); }),
      ],
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
              Text(_loc.translate('decor_plaster_calc.label.wall_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('decor_plaster_calc.label.layers'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('$_layers', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _layers.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _layers = v.toInt(); _update(); }); },
          ),
          Text(
            _loc.translate('decor_plaster_calc.layers_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
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
            title: Text(_loc.translate('decor_plaster_calc.option.primer'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('decor_plaster_calc.option.primer_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needPrimer,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needPrimer = v; _update(); }); },
          ),
          if (_plasterType == DecorPlasterType.venetian)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_loc.translate('decor_plaster_calc.option.wax'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
              subtitle: Text(_loc.translate('decor_plaster_calc.option.wax_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
              value: _needWax,
              activeColor: _accentColor,
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
