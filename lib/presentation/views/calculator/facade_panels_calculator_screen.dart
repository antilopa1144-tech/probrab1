import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип фасадных панелей
enum FacadePanelType {
  vinyl('facade_panels_calc.type.vinyl', 'facade_panels_calc.type.vinyl_desc', Icons.view_module),
  metal('facade_panels_calc.type.metal', 'facade_panels_calc.type.metal_desc', Icons.grid_view),
  fiber('facade_panels_calc.type.fiber', 'facade_panels_calc.type.fiber_desc', Icons.layers);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const FacadePanelType(this.nameKey, this.descKey, this.icon);
}

class _FacadePanelsResult {
  final double wallArea;
  final double panelsArea;
  final double profileLength;
  final double insulationArea;
  final int cornersCount;
  final int startersCount;

  const _FacadePanelsResult({
    required this.wallArea,
    required this.panelsArea,
    required this.profileLength,
    required this.insulationArea,
    required this.cornersCount,
    required this.startersCount,
  });
}

class FacadePanelsCalculatorScreen extends StatefulWidget {
  const FacadePanelsCalculatorScreen({super.key});

  @override
  State<FacadePanelsCalculatorScreen> createState() => _FacadePanelsCalculatorScreenState();
}

class _FacadePanelsCalculatorScreenState extends State<FacadePanelsCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('facade_panels_calc.title');

  double _wallLength = 40.0; // периметр дома
  double _wallHeight = 3.0;
  double _openingsArea = 10.0; // окна и двери

  FacadePanelType _panelType = FacadePanelType.vinyl;
  bool _needInsulation = true;
  bool _needProfile = true;

  late _FacadePanelsResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _FacadePanelsResult _calculate() {
    final grossArea = _wallLength * _wallHeight;
    final wallArea = grossArea - _openingsArea;

    // Панели +10% запас
    final panelsArea = wallArea * 1.1;

    // Профиль для обрешётки
    double profileLength = 0;
    if (_needProfile) {
      // Вертикальные направляющие через 0.6м
      final verticals = (_wallLength / 0.6).ceil();
      profileLength = verticals * _wallHeight * 1.1;
    }

    // Утеплитель
    final insulationArea = _needInsulation ? wallArea * 1.05 : 0.0;

    // Углы: 4 внешних угла × высота стены
    final cornersCount = (4 * _wallHeight / 3).ceil(); // профили 3м

    // Стартовые планки: периметр
    final startersCount = (_wallLength / 3).ceil();

    return _FacadePanelsResult(
      wallArea: wallArea,
      panelsArea: panelsArea,
      profileLength: profileLength,
      insulationArea: insulationArea,
      cornersCount: cornersCount,
      startersCount: startersCount,
    );
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
            label: _loc.translate('facade_panels_calc.result.panels').toUpperCase(),
            value: '${_result.panelsArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
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
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: FacadePanelType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _panelType.index,
      onSelect: (index) {
        setState(() {
          _panelType = FacadePanelType.values[index];
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
              Expanded(child: CalculatorTextField(label: _loc.translate('facade_panels_calc.label.perimeter'), value: _wallLength, onChanged: (v) { setState(() { _wallLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 10, maxValue: 200)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('facade_panels_calc.label.height'), value: _wallHeight, onChanged: (v) { setState(() { _wallHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 2, maxValue: 10)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('facade_panels_calc.label.openings'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_openingsArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _openingsArea,
            min: 0,
            max: 50,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _openingsArea = v; _update(); }); },
          ),
          Text(
            _loc.translate('facade_panels_calc.openings_hint'),
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
            title: Text(_loc.translate('facade_panels_calc.option.insulation'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('facade_panels_calc.option.insulation_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needInsulation,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needInsulation = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('facade_panels_calc.option.profile'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('facade_panels_calc.option.profile_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needProfile,
            activeColor: _accentColor,
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
        value: '${_result.panelsArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate(_panelType.nameKey),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
