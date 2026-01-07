import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип сантехники
enum PlumbingType {
  standard('plumbing_calc.type.standard', 'plumbing_calc.type.standard_desc', Icons.water_drop),
  premium('plumbing_calc.type.premium', 'plumbing_calc.type.premium_desc', Icons.spa),
  economy('plumbing_calc.type.economy', 'plumbing_calc.type.economy_desc', Icons.savings);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const PlumbingType(this.nameKey, this.descKey, this.icon);
}

class _PlumbingResult {
  final int pointsCount;
  final double coldWaterPipes;
  final double hotWaterPipes;
  final double sewagePipes;
  final int fittingsCount;
  final int valvesCount;

  const _PlumbingResult({
    required this.pointsCount,
    required this.coldWaterPipes,
    required this.hotWaterPipes,
    required this.sewagePipes,
    required this.fittingsCount,
    required this.valvesCount,
  });
}

class PlumbingCalculatorScreen extends StatefulWidget {
  const PlumbingCalculatorScreen({super.key});

  @override
  State<PlumbingCalculatorScreen> createState() => _PlumbingCalculatorScreenState();
}

class _PlumbingCalculatorScreenState extends State<PlumbingCalculatorScreen> {
  int _bathroomsCount = 1;
  int _toiletsCount = 1;
  int _kitchensCount = 1;
  double _avgPipeLength = 5.0;

  PlumbingType _plumbingType = PlumbingType.standard;
  bool _needHotWater = true;

  late _PlumbingResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _PlumbingResult _calculate() {
    // Точки подключения
    final bathroomPoints = _bathroomsCount * 4; // раковина, ванна/душ, унитаз, стиралка
    final toiletPoints = _toiletsCount * 2; // унитаз, раковина
    final kitchenPoints = _kitchensCount * 3; // мойка, посудомойка, фильтр
    final pointsCount = bathroomPoints + toiletPoints + kitchenPoints;

    // Трубы холодной воды
    final coldWaterPipes = pointsCount * _avgPipeLength * 1.15;

    // Трубы горячей воды
    final hotWaterPipes = _needHotWater ? pointsCount * _avgPipeLength * 0.8 * 1.15 : 0.0;

    // Канализация
    final sewagePipes = pointsCount * (_avgPipeLength * 0.7) * 1.1;

    // Фитинги: примерно 4 на каждую точку
    final fittingsCount = pointsCount * 4;

    // Краны/вентили: по 2 на каждую точку с горячей водой
    final valvesCount = _needHotWater ? pointsCount * 2 : pointsCount;

    return _PlumbingResult(
      pointsCount: pointsCount,
      coldWaterPipes: coldWaterPipes,
      hotWaterPipes: hotWaterPipes,
      sewagePipes: sewagePipes,
      fittingsCount: fittingsCount,
      valvesCount: valvesCount,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('plumbing_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('plumbing_calc.export.points')
        .replaceFirst('{value}', _result.pointsCount.toString()));
    buffer.writeln(_loc.translate('plumbing_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_plumbingType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('plumbing_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('plumbing_calc.export.cold_water')
        .replaceFirst('{value}', _result.coldWaterPipes.toStringAsFixed(1)));
    if (_needHotWater) {
      buffer.writeln(_loc.translate('plumbing_calc.export.hot_water')
          .replaceFirst('{value}', _result.hotWaterPipes.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('plumbing_calc.export.sewage')
        .replaceFirst('{value}', _result.sewagePipes.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('plumbing_calc.export.fittings')
        .replaceFirst('{value}', _result.fittingsCount.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('plumbing_calc.export.footer'));
    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('plumbing_calc.title')));
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
      title: _loc.translate('plumbing_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('plumbing_calc.result.points').toUpperCase(),
            value: '${_result.pointsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.water_drop,
          ),
          ResultItem(
            label: _loc.translate('plumbing_calc.result.pipes').toUpperCase(),
            value: '${(_result.coldWaterPipes + _result.hotWaterPipes).toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.plumbing,
          ),
          ResultItem(
            label: _loc.translate('plumbing_calc.result.fittings').toUpperCase(),
            value: '${_result.fittingsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.settings,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildRoomsCard(),
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
      options: PlumbingType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _plumbingType.index,
      onSelect: (index) {
        setState(() {
          _plumbingType = PlumbingType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildRoomsCard() {
    return _card(
      child: Column(
        children: [
          _buildCounterRow(_loc.translate('plumbing_calc.label.bathrooms'), _bathroomsCount, (v) { setState(() { _bathroomsCount = v; _update(); }); }),
          const Divider(),
          _buildCounterRow(_loc.translate('plumbing_calc.label.toilets'), _toiletsCount, (v) { setState(() { _toiletsCount = v; _update(); }); }),
          const Divider(),
          _buildCounterRow(_loc.translate('plumbing_calc.label.kitchens'), _kitchensCount, (v) { setState(() { _kitchensCount = v; _update(); }); }),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('plumbing_calc.label.avg_pipe_length'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_avgPipeLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _avgPipeLength, min: 2, max: 15, activeColor: _accentColor, onChanged: (v) { setState(() { _avgPipeLength = v; _update(); }); }),
        ],
      ),
    );
  }

  Widget _buildCounterRow(String label, int value, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: CalculatorDesignSystem.bodyMedium),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                color: _accentColor,
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: CalculatorDesignSystem.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: _accentColor,
                onPressed: value < 10 ? () => onChanged(value + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(_loc.translate('plumbing_calc.option.hot_water'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
        subtitle: Text(_loc.translate('plumbing_calc.option.hot_water_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
        value: _needHotWater,
        activeColor: _accentColor,
        onChanged: (v) { setState(() { _needHotWater = v; _update(); }); },
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('plumbing_calc.materials.cold_water'),
        value: '${_result.coldWaterPipes.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('plumbing_calc.materials.cold_water_desc'),
        icon: Icons.water,
      ),
    ];

    if (_needHotWater && _result.hotWaterPipes > 0) {
      items.add(MaterialItem(
        name: _loc.translate('plumbing_calc.materials.hot_water'),
        value: '${_result.hotWaterPipes.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('plumbing_calc.materials.hot_water_desc'),
        icon: Icons.whatshot,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('plumbing_calc.materials.sewage'),
      value: '${_result.sewagePipes.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
      subtitle: _loc.translate('plumbing_calc.materials.sewage_desc'),
      icon: Icons.plumbing,
    ));

    items.add(MaterialItem(
      name: _loc.translate('plumbing_calc.materials.fittings'),
      value: '${_result.fittingsCount} ${_loc.translate('common.pcs')}',
      subtitle: _loc.translate('plumbing_calc.materials.fittings_desc'),
      icon: Icons.settings,
    ));

    items.add(MaterialItem(
      name: _loc.translate('plumbing_calc.materials.valves'),
      value: '${_result.valvesCount} ${_loc.translate('common.pcs')}',
      subtitle: _loc.translate('plumbing_calc.materials.valves_desc'),
      icon: Icons.toggle_on,
    ));

    return MaterialsCardModern(
      title: _loc.translate('plumbing_calc.section.materials'),
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
