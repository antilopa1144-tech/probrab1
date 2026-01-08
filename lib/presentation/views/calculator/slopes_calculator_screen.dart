import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_slopes_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип откосов
enum SlopesType {
  plaster('slopes_calc.type.plaster', 'slopes_calc.type.plaster_desc', Icons.foundation),
  gypsum('slopes_calc.type.gypsum', 'slopes_calc.type.gypsum_desc', Icons.grid_view),
  sandwich('slopes_calc.type.sandwich', 'slopes_calc.type.sandwich_desc', Icons.layers);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const SlopesType(this.nameKey, this.descKey, this.icon);
}

class _SlopesResult {
  final double totalArea;
  final double materialArea;
  final double cornerLength;
  final double primerLiters;
  final double sealantTubes;

  const _SlopesResult({
    required this.totalArea,
    required this.materialArea,
    required this.cornerLength,
    required this.primerLiters,
    required this.sealantTubes,
  });

  factory _SlopesResult.fromCalculatorResult(Map<String, double> values) {
    return _SlopesResult(
      totalArea: values['totalArea'] ?? 0,
      materialArea: values['materialArea'] ?? 0,
      cornerLength: values['cornerLength'] ?? 0,
      primerLiters: values['primerLiters'] ?? 0,
      sealantTubes: values['sealantTubes'] ?? 0,
    );
  }
}

class SlopesCalculatorScreen extends ConsumerStatefulWidget {
  const SlopesCalculatorScreen({super.key});

  @override
  ConsumerState<SlopesCalculatorScreen> createState() => _SlopesCalculatorScreenState();
}

class _SlopesCalculatorScreenState extends ConsumerState<SlopesCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('slopes_calc.title');

  // Domain layer calculator
  final _calculator = CalculateSlopesV2();

  int _windowsCount = 3;
  double _windowWidth = 1.4;
  double _windowHeight = 1.5;
  double _slopeDepth = 0.25;

  SlopesType _slopesType = SlopesType.gypsum;
  bool _needCorners = true;
  bool _needPrimer = true;

  late _SlopesResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _SlopesResult _calculate() {
    final inputs = <String, double>{
      'windowsCount': _windowsCount.toDouble(),
      'windowWidth': _windowWidth,
      'windowHeight': _windowHeight,
      'slopeDepth': _slopeDepth,
      'slopesType': _slopesType.index.toDouble(),
      'needCorners': _needCorners ? 1.0 : 0.0,
      'needPrimer': _needPrimer ? 1.0 : 0.0,
    };

    final result = _calculator(inputs, []);
    return _SlopesResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('slopes_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('slopes_calc.export.windows_count')
        .replaceFirst('{value}', _windowsCount.toString()));
    buffer.writeln(_loc.translate('slopes_calc.export.total_area')
        .replaceFirst('{value}', _result.totalArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('slopes_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_slopesType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('slopes_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('slopes_calc.export.material')
        .replaceFirst('{value}', _result.materialArea.toStringAsFixed(1)));
    if (_needCorners) {
      buffer.writeln(_loc.translate('slopes_calc.export.corners')
          .replaceFirst('{value}', _result.cornerLength.toStringAsFixed(1)));
    }
    buffer.writeln(_loc.translate('slopes_calc.export.sealant')
        .replaceFirst('{value}', _result.sealantTubes.toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('slopes_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('slopes_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('slopes_calc.result.windows').toUpperCase(),
            value: '$_windowsCount ${_loc.translate('common.pcs')}',
            icon: Icons.window,
          ),
          ResultItem(
            label: _loc.translate('slopes_calc.result.area').toUpperCase(),
            value: '${_result.totalArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('slopes_calc.result.material').toUpperCase(),
            value: '${_result.materialArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildCountCard(),
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
      options: SlopesType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _slopesType.index,
      onSelect: (index) {
        setState(() {
          _slopesType = SlopesType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildCountCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('slopes_calc.label.windows_count'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('$_windowsCount ${_loc.translate('common.pcs')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _windowsCount.toDouble(),
            min: 1,
            max: 15,
            divisions: 14,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _windowsCount = v.toInt(); _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('slopes_calc.label.window_size'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('slopes_calc.label.width'), value: _windowWidth * 100, onChanged: (v) { setState(() { _windowWidth = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 40, maxValue: 300)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('slopes_calc.label.height'), value: _windowHeight * 100, onChanged: (v) { setState(() { _windowHeight = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 40, maxValue: 250)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('slopes_calc.label.slope_depth'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${(_slopeDepth * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _slopeDepth * 100,
            min: 10,
            max: 50,
            divisions: 8,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _slopeDepth = v / 100; _update(); }); },
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
            title: Text(_loc.translate('slopes_calc.option.corners'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('slopes_calc.option.corners_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needCorners,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needCorners = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('slopes_calc.option.primer'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('slopes_calc.option.primer_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needPrimer,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needPrimer = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('slopes_calc.materials.material'),
        value: '${_result.materialArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate(_slopesType.nameKey),
        icon: Icons.layers,
      ),
    ];

    if (_needCorners && _result.cornerLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('slopes_calc.materials.corners'),
        value: '${_result.cornerLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('slopes_calc.materials.corners_desc'),
        icon: Icons.rounded_corner,
      ));
    }

    if (_needPrimer && _result.primerLiters > 0) {
      items.add(MaterialItem(
        name: _loc.translate('slopes_calc.materials.primer'),
        value: '${_result.primerLiters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
        subtitle: _loc.translate('slopes_calc.materials.primer_desc'),
        icon: Icons.format_paint,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('slopes_calc.materials.sealant'),
      value: '${_result.sealantTubes.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
      subtitle: _loc.translate('slopes_calc.materials.sealant_desc'),
      icon: Icons.water_drop,
    ));

    return MaterialsCardModern(
      title: _loc.translate('slopes_calc.section.materials'),
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
