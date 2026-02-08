import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_facade_panels_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип фасадных панелей
enum FacadePanelType {
  vinyl('facade_panels_calc.type.vinyl', 'facade_panels_calc.type.vinyl_desc', Icons.view_module),
  metal('facade_panels_calc.type.metal', 'facade_panels_calc.type.metal_desc', Icons.grid_view),
  fiber('facade_panels_calc.type.fiber', 'facade_panels_calc.type.fiber_desc', Icons.layers),
  blockHouse('facade_panels_calc.type.block_house', 'facade_panels_calc.type.block_house_desc', Icons.forest),
  thermoPanels('facade_panels_calc.type.thermo', 'facade_panels_calc.type.thermo_desc', Icons.thermostat),
  profSheet('facade_panels_calc.type.prof_sheet', 'facade_panels_calc.type.prof_sheet_desc', Icons.view_column),
  hpl('facade_panels_calc.type.hpl', 'facade_panels_calc.type.hpl_desc', Icons.dashboard);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const FacadePanelType(this.nameKey, this.descKey, this.icon);
}

class _FacadePanelsResult {
  final double wallArea;
  final double panelsArea;
  final int panelsCount;
  final double profileLength;
  final double insulationArea;
  final int cornersCount;
  final int startersCount;

  const _FacadePanelsResult({
    required this.wallArea,
    required this.panelsArea,
    required this.panelsCount,
    required this.profileLength,
    required this.insulationArea,
    required this.cornersCount,
    required this.startersCount,
  });

  factory _FacadePanelsResult.fromCalculatorResult(Map<String, double> values) {
    return _FacadePanelsResult(
      wallArea: values['wallArea'] ?? 0,
      panelsArea: values['panelsArea'] ?? 0,
      panelsCount: (values['panelsCount'] ?? 0).toInt(),
      profileLength: values['profileLength'] ?? 0,
      insulationArea: values['insulationArea'] ?? 0,
      cornersCount: (values['cornersCount'] ?? 0).toInt(),
      startersCount: (values['startersCount'] ?? 0).toInt(),
    );
  }
}

class FacadePanelsCalculatorScreen extends ConsumerStatefulWidget {
  const FacadePanelsCalculatorScreen({super.key});

  @override
  ConsumerState<FacadePanelsCalculatorScreen> createState() => _FacadePanelsCalculatorScreenState();
}

class _FacadePanelsCalculatorScreenState extends ConsumerState<FacadePanelsCalculatorScreen>
    with ExportableConsumerMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('facade_panels_calc.title');

  // Domain layer calculator
  final _calculator = CalculateFacadePanelsV2();

  double _houseLength = 10.0; // длина дома
  double _houseWidth = 10.0;  // ширина дома
  double _wallHeight = 3.0;
  double _openingsArea = 10.0; // окна и двери

  double get _perimeter => (_houseLength + _houseWidth) * 2;

  FacadePanelType _panelType = FacadePanelType.vinyl;
  bool _needInsulation = true;
  bool _needProfile = true;

  late _FacadePanelsResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _FacadePanelsResult _calculate() {
    final inputs = <String, double>{
      'wallLength': _perimeter,
      'wallHeight': _wallHeight,
      'openingsArea': _openingsArea,
      'panelType': _panelType.index.toDouble(),
      'needInsulation': _needInsulation ? 1.0 : 0.0,
      'needProfile': _needProfile ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _FacadePanelsResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('facade_panels_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('facade_panels_calc.export.wall_area')
        .replaceFirst('{value}', _result.wallArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('facade_panels_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_panelType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('facade_panels_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('facade_panels_calc.export.panels')
        .replaceFirst('{value}', '${_result.panelsCount}'));
    buffer.writeln(_loc.translate('facade_panels_calc.export.panels_area')
        .replaceFirst('{value}', _result.panelsArea.toStringAsFixed(1)));
    if (_needProfile) {
      buffer.writeln(_loc.translate('facade_panels_calc.export.profile')
          .replaceFirst('{value}', _result.profileLength.toStringAsFixed(1)));
    }
    if (_needInsulation) {
      buffer.writeln(_loc.translate('facade_panels_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('facade_panels_calc.export.corners')
        .replaceFirst('{value}', _result.cornersCount.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('facade_panels_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('facade_panels_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('facade_panels_calc.result.wall_area').toUpperCase(),
            value: '${_result.wallArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
          ResultItem(
            label: _loc.translate('facade_panels_calc.result.panels_count').toUpperCase(),
            value: '${_result.panelsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.view_module,
          ),
          ResultItem(
            label: _loc.translate('facade_panels_calc.result.corners').toUpperCase(),
            value: '${_result.cornersCount} ${_loc.translate('common.pcs')}',
            icon: Icons.rounded_corner,
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
    switch (_panelType) {
      case FacadePanelType.vinyl:
        tips.add(_loc.translate('facade_panels_calc.tip.vinyl_1'));
        tips.add(_loc.translate('facade_panels_calc.tip.vinyl_2'));
      case FacadePanelType.metal:
        tips.add(_loc.translate('facade_panels_calc.tip.metal_1'));
        tips.add(_loc.translate('facade_panels_calc.tip.metal_2'));
      case FacadePanelType.fiber:
        tips.add(_loc.translate('facade_panels_calc.tip.fiber_1'));
        tips.add(_loc.translate('facade_panels_calc.tip.fiber_2'));
      case FacadePanelType.blockHouse:
        tips.add(_loc.translate('facade_panels_calc.tip.block_house_1'));
        tips.add(_loc.translate('facade_panels_calc.tip.block_house_2'));
      case FacadePanelType.thermoPanels:
        tips.add(_loc.translate('facade_panels_calc.tip.thermo_1'));
        tips.add(_loc.translate('facade_panels_calc.tip.thermo_2'));
      case FacadePanelType.profSheet:
        tips.add(_loc.translate('facade_panels_calc.tip.prof_sheet_1'));
        tips.add(_loc.translate('facade_panels_calc.tip.prof_sheet_2'));
      case FacadePanelType.hpl:
        tips.add(_loc.translate('facade_panels_calc.tip.hpl_1'));
        tips.add(_loc.translate('facade_panels_calc.tip.hpl_2'));
    }
    tips.add(_loc.translate('facade_panels_calc.tip.common'));
    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    // 7 типов не помещаются в один Row — используем сетку 2 колонки
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2; // 2 колонки, 12 зазор
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: FacadePanelType.values.map((type) {
            return SizedBox(
              width: cardWidth,
              child: TypeSelectorCard(
                icon: type.icon,
                title: _loc.translate(type.nameKey),
                subtitle: _loc.translate(type.descKey),
                isSelected: _panelType == type,
                accentColor: _accentColor,
                onTap: () {
                  setState(() {
                    _panelType = type;
                    _update();
                  });
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDimensionsCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: CalculatorTextField(
                key: const ValueKey('house_length'),
                label: _loc.translate('facade_panels_calc.label.house_length'),
                value: _houseLength,
                onChanged: (v) { setState(() { _houseLength = v; _update(); }); },
                suffix: _loc.translate('common.meters'),
                accentColor: _accentColor,
                minValue: 3,
                maxValue: 50,
              )),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(
                key: const ValueKey('house_width'),
                label: _loc.translate('facade_panels_calc.label.house_width'),
                value: _houseWidth,
                onChanged: (v) { setState(() { _houseWidth = v; _update(); }); },
                suffix: _loc.translate('common.meters'),
                accentColor: _accentColor,
                minValue: 3,
                maxValue: 50,
              )),
            ],
          ),
          const SizedBox(height: 12),
          CalculatorTextField(
            key: const ValueKey('wall_height'),
            label: _loc.translate('facade_panels_calc.label.height'),
            value: _wallHeight,
            onChanged: (v) { setState(() { _wallHeight = v; _update(); }); },
            suffix: _loc.translate('common.meters'),
            accentColor: _accentColor,
            minValue: 2,
            maxValue: 10,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _loc.translate('facade_panels_calc.label.perimeter'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.getTextSecondary(_isDark),
                  ),
                ),
                Text(
                  '${_perimeter.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
                  style: CalculatorDesignSystem.titleMedium.copyWith(
                    color: _accentColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('facade_panels_calc.label.openings'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w600)),
              Text('${_openingsArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              inactiveTrackColor: _accentColor.withValues(alpha: _isDark ? 0.3 : 0.2),
            ),
            child: Slider(
              value: _openingsArea,
              min: 0,
              max: 50,
              divisions: 500,
              activeColor: _accentColor,
              onChanged: (v) { setState(() { _openingsArea = v; _update(); }); },
            ),
          ),
          const SizedBox(height: 8),
          CalculatorTextField(
            label: _loc.translate('facade_panels_calc.label.openings'),
            value: _openingsArea,
            onChanged: (v) { setState(() { _openingsArea = v; _update(); }); },
            suffix: _loc.translate('common.sqm'),
            accentColor: _accentColor,
            minValue: 0,
            maxValue: 50,
            decimalPlaces: 1,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('facade_panels_calc.openings_hint'),
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
            title: Text(_loc.translate('facade_panels_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('facade_panels_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needInsulation,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('facade_panels_calc.option.profile'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark))),
            subtitle: Text(_loc.translate('facade_panels_calc.option.profile_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500)),
            value: _needProfile,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needProfile = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('facade_panels_calc.materials.panels'),
        value: '${_result.panelsCount} ${_loc.translate('common.pcs')}',
        subtitle: '${_loc.translate(_panelType.nameKey)} (${_result.panelsArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')})',
        icon: Icons.view_module,
      ),
    ];

    if (_needProfile && _result.profileLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('facade_panels_calc.materials.profile'),
        value: '${_result.profileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('facade_panels_calc.materials.profile_desc'),
        icon: Icons.straighten,
      ));
    }

    if (_needInsulation && _result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('facade_panels_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('facade_panels_calc.materials.insulation_desc'),
        icon: Icons.layers,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('facade_panels_calc.materials.corners'),
      value: '${_result.cornersCount} ${_loc.translate('common.pcs')}',
      subtitle: _loc.translate('facade_panels_calc.materials.corners_desc'),
      icon: Icons.rounded_corner,
    ));

    items.add(MaterialItem(
      name: _loc.translate('facade_panels_calc.materials.starters'),
      value: '${_result.startersCount} ${_loc.translate('common.pcs')}',
      subtitle: _loc.translate('facade_panels_calc.materials.starters_desc'),
      icon: Icons.border_bottom,
    ));

    return MaterialsCardModern(
      title: _loc.translate('facade_panels_calc.section.materials'),
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
