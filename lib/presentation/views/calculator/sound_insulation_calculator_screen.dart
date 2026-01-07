import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип шумоизоляции
enum SoundInsulationType {
  mineralWool('sound_insulation_calc.type.mineral_wool', 'sound_insulation_calc.type.mineral_wool_desc', Icons.layers),
  membrane('sound_insulation_calc.type.membrane', 'sound_insulation_calc.type.membrane_desc', Icons.filter_alt),
  combined('sound_insulation_calc.type.combined', 'sound_insulation_calc.type.combined_desc', Icons.stacked_line_chart);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const SoundInsulationType(this.nameKey, this.descKey, this.icon);
}

/// Тип поверхности
enum SurfaceType { wall, ceiling, floor }

class _SoundInsulationResult {
  final double area;
  final double insulationArea;
  final double membraneArea;
  final double gypsumArea;
  final double profileLength;
  final int hangersCount;

  const _SoundInsulationResult({
    required this.area,
    required this.insulationArea,
    required this.membraneArea,
    required this.gypsumArea,
    required this.profileLength,
    required this.hangersCount,
  });
}

class SoundInsulationCalculatorScreen extends StatefulWidget {
  const SoundInsulationCalculatorScreen({super.key});

  @override
  State<SoundInsulationCalculatorScreen> createState() => _SoundInsulationCalculatorScreenState();
}

class _SoundInsulationCalculatorScreenState extends State<SoundInsulationCalculatorScreen> {
  double _area = 20.0;
  double _thickness = 50.0; // мм

  SoundInsulationType _insulationType = SoundInsulationType.mineralWool;
  SurfaceType _surfaceType = SurfaceType.wall;
  bool _needGypsum = true;
  bool _needProfile = true;

  late _SoundInsulationResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _SoundInsulationResult _calculate() {
    final area = _area;

    // Утеплитель +10%
    double insulationArea = 0;
    if (_insulationType != SoundInsulationType.membrane) {
      insulationArea = area * 1.1;
    }

    // Мембрана +15%
    double membraneArea = 0;
    if (_insulationType != SoundInsulationType.mineralWool) {
      membraneArea = area * 1.15;
    }

    // Гипсокартон +10%
    final gypsumArea = _needGypsum ? area * 1.1 : 0.0;

    // Профиль
    double profileLength = 0;
    if (_needProfile) {
      // Для стен: через каждые 0.6м
      // Для потолка: через каждые 0.4м
      final spacing = _surfaceType == SurfaceType.ceiling ? 0.4 : 0.6;
      final rows = (area.toDouble() / spacing).ceil();
      profileLength = rows * 3 * 1.1; // стандартные профили 3м
    }

    // Подвесы: 1 на каждые 1.2 м²
    final hangersCount = _needProfile && _surfaceType == SurfaceType.ceiling
        ? (area / 1.2).ceil()
        : 0;

    return _SoundInsulationResult(
      area: area,
      insulationArea: insulationArea,
      membraneArea: membraneArea,
      gypsumArea: gypsumArea,
      profileLength: profileLength,
      hangersCount: hangersCount,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('sound_insulation_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('sound_insulation_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('sound_insulation_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_insulationType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('sound_insulation_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    if (_result.insulationArea > 0) {
      buffer.writeln(_loc.translate('sound_insulation_calc.export.insulation')
          .replaceFirst('{value}', _result.insulationArea.toStringAsFixed(1)));
    }
    if (_result.membraneArea > 0) {
      buffer.writeln(_loc.translate('sound_insulation_calc.export.membrane')
          .replaceFirst('{value}', _result.membraneArea.toStringAsFixed(1)));
    }
    if (_result.gypsumArea > 0) {
      buffer.writeln(_loc.translate('sound_insulation_calc.export.gypsum')
          .replaceFirst('{value}', _result.gypsumArea.toStringAsFixed(1)));
    }
    if (_result.profileLength > 0) {
      buffer.writeln(_loc.translate('sound_insulation_calc.export.profile')
          .replaceFirst('{value}', _result.profileLength.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('sound_insulation_calc.export.footer'));
    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('sound_insulation_calc.title')));
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
      title: _loc.translate('sound_insulation_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('sound_insulation_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('sound_insulation_calc.result.insulation').toUpperCase(),
            value: '${_result.insulationArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.layers,
          ),
          ResultItem(
            label: _loc.translate('sound_insulation_calc.result.gypsum').toUpperCase(),
            value: '${_result.gypsumArea.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.grid_view,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildSurfaceSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildThicknessCard(),
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
      options: SoundInsulationType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _insulationType.index,
      onSelect: (index) {
        setState(() {
          _insulationType = SoundInsulationType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildSurfaceSelector() {
    final surfaces = [
      _loc.translate('sound_insulation_calc.surface.wall'),
      _loc.translate('sound_insulation_calc.surface.ceiling'),
      _loc.translate('sound_insulation_calc.surface.floor'),
    ];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('sound_insulation_calc.label.surface'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: surfaces,
            selectedIndex: _surfaceType.index,
            onSelect: (index) {
              setState(() {
                _surfaceType = SurfaceType.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('sound_insulation_calc.label.area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _area, min: 5, max: 100, activeColor: _accentColor, onChanged: (v) { setState(() { _area = v; _update(); }); }),
        ],
      ),
    );
  }

  Widget _buildThicknessCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('sound_insulation_calc.label.thickness'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_thickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _thickness,
            min: 20,
            max: 100,
            divisions: 8,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _thickness = v; _update(); }); },
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
            title: Text(_loc.translate('sound_insulation_calc.option.gypsum'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('sound_insulation_calc.option.gypsum_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needGypsum,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needGypsum = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('sound_insulation_calc.option.profile'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('sound_insulation_calc.option.profile_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needProfile,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needProfile = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[];

    if (_result.insulationArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('sound_insulation_calc.materials.insulation'),
        value: '${_result.insulationArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: '${_thickness.toStringAsFixed(0)} ${_loc.translate('common.mm')}',
        icon: Icons.layers,
      ));
    }

    if (_result.membraneArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('sound_insulation_calc.materials.membrane'),
        value: '${_result.membraneArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('sound_insulation_calc.materials.membrane_desc'),
        icon: Icons.filter_alt,
      ));
    }

    if (_result.gypsumArea > 0) {
      items.add(MaterialItem(
        name: _loc.translate('sound_insulation_calc.materials.gypsum'),
        value: '${_result.gypsumArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('sound_insulation_calc.materials.gypsum_desc'),
        icon: Icons.grid_view,
      ));
    }

    if (_result.profileLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('sound_insulation_calc.materials.profile'),
        value: '${_result.profileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('sound_insulation_calc.materials.profile_desc'),
        icon: Icons.straighten,
      ));
    }

    if (_result.hangersCount > 0) {
      items.add(MaterialItem(
        name: _loc.translate('sound_insulation_calc.materials.hangers'),
        value: '${_result.hangersCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('sound_insulation_calc.materials.hangers_desc'),
        icon: Icons.hardware,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('sound_insulation_calc.section.materials'),
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
