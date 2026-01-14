import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_strip_foundation.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Режим ввода для ленточного фундамента
enum StripInputMode {
  byArea,
  byPerimeter,
}

class _StripResult {
  final double area;
  final double perimeter;
  final double concreteVolume;
  final double rebarWeight;
  final double formworkArea;
  final double waterproofingArea;
  final double sandVolume;
  final double gravelVolume;
  final double cementBags;

  const _StripResult({
    required this.area,
    required this.perimeter,
    required this.concreteVolume,
    required this.rebarWeight,
    required this.formworkArea,
    required this.waterproofingArea,
    required this.sandVolume,
    required this.gravelVolume,
    required this.cementBags,
  });

  factory _StripResult.fromCalculatorResult(Map<String, double> values) {
    return _StripResult(
      area: values['area'] ?? 0,
      perimeter: values['perimeter'] ?? 0,
      concreteVolume: values['concreteVolume'] ?? 0,
      rebarWeight: values['rebarWeight'] ?? 0,
      formworkArea: values['formworkArea'] ?? 0,
      waterproofingArea: values['waterproofingArea'] ?? 0,
      sandVolume: values['sandVolume'] ?? 0,
      gravelVolume: values['gravelVolume'] ?? 0,
      cementBags: values['cementBags'] ?? 0,
    );
  }
}

/// Калькулятор ленточного фундамента
class StripFoundationCalculatorScreen extends StatefulWidget {
  const StripFoundationCalculatorScreen({super.key});

  @override
  State<StripFoundationCalculatorScreen> createState() =>
      _StripFoundationCalculatorScreenState();
}

class _StripFoundationCalculatorScreenState
    extends State<StripFoundationCalculatorScreen> with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('strip_calc.title');

  final _calculator = CalculateStripFoundation();

  // Режим ввода
  StripInputMode _inputMode = StripInputMode.byArea;

  // Поля ввода
  double _area = 100.0;
  double _perimeter = 40.0;
  double _width = 0.4;
  double _height = 0.6;

  late _StripResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.foundation;

  static const double _minArea = 10.0;
  static const double _maxArea = 500.0;
  static const double _minPerimeter = 10.0;
  static const double _maxPerimeter = 200.0;
  static const double _minWidth = 0.2;
  static const double _maxWidth = 1.0;
  static const double _minHeight = 0.3;
  static const double _maxHeight = 1.5;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _StripResult _calculate() {
    final inputs = <String, double>{
      if (_inputMode == StripInputMode.byArea) 'area': _area,
      if (_inputMode == StripInputMode.byPerimeter) 'perimeter': _perimeter,
      'width': _width,
      'height': _height,
    };

    final result = _calculator(inputs, []);
    return _StripResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('strip_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(
        '${_loc.translate('strip_calc.perimeter')}: ${_result.perimeter.toStringAsFixed(1)} ${_loc.translate('common.meters')}');
    buffer.writeln(
        '${_loc.translate('strip_calc.strip_width')}: ${(_width * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}');
    buffer.writeln(
        '${_loc.translate('strip_calc.strip_height')}: ${(_height * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}');
    buffer.writeln();
    buffer.writeln(_loc.translate('strip_calc.export.materials'));
    buffer.writeln('─' * 40);
    buffer.writeln(
        '${_loc.translate('strip_calc.concrete')}: ${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}');
    buffer.writeln(
        '${_loc.translate('strip_calc.rebar')}: ${_result.rebarWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}');
    buffer.writeln(
        '${_loc.translate('strip_calc.formwork')}: ${_result.formworkArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln(
        '${_loc.translate('strip_calc.waterproofing')}: ${_result.waterproofingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln(
        '${_loc.translate('strip_calc.sand')}: ${_result.sandVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}');
    buffer.writeln(
        '${_loc.translate('strip_calc.gravel')}: ${_result.gravelVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}');
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('strip_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('strip_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('strip_calc.result.perimeter'),
            value:
                '${_result.perimeter.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
            icon: Icons.crop_square,
          ),
          ResultItem(
            label: _loc.translate('strip_calc.result.concrete'),
            value:
                '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
            icon: Icons.view_in_ar,
          ),
          ResultItem(
            label: _loc.translate('strip_calc.result.rebar'),
            value:
                '${_result.rebarWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
            icon: Icons.grid_4x4,
          ),
        ],
      ),
      children: [
        _buildInputModeSelector(),
        const SizedBox(height: 16),
        _buildMainInputCard(),
        const SizedBox(height: 16),
        _buildStripDimensionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInputModeSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('strip_calc.input_mode'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModeOption(
                  icon: Icons.square_foot,
                  label: _loc.translate('strip_calc.mode.by_area'),
                  isSelected: _inputMode == StripInputMode.byArea,
                  onTap: () {
                    setState(() {
                      _inputMode = StripInputMode.byArea;
                      _update();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeOption(
                  icon: Icons.straighten,
                  label: _loc.translate('strip_calc.mode.by_perimeter'),
                  isSelected: _inputMode == StripInputMode.byPerimeter,
                  onTap: () {
                    setState(() {
                      _inputMode = StripInputMode.byPerimeter;
                      _update();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? _accentColor.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? _accentColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? _accentColor : CalculatorColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: CalculatorDesignSystem.bodyMedium.copyWith(
                  color: isSelected
                      ? _accentColor
                      : CalculatorColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainInputCard() {
    if (_inputMode == StripInputMode.byArea) {
      return _buildAreaInput();
    } else {
      return _buildPerimeterInput();
    }
  }

  Widget _buildAreaInput() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('strip_calc.building_area'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _accentColor,
              inactiveTrackColor: _accentColor.withValues(alpha: 0.2),
              thumbColor: _accentColor,
            ),
            child: Slider(
              value: _area,
              min: _minArea,
              max: _maxArea,
              divisions: ((_maxArea - _minArea) / 5).round(),
              onChanged: (v) {
                setState(() {
                  _area = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          CalculatorTextField(
            label: _loc.translate('strip_calc.building_area'),
            value: _area,
            suffix: _loc.translate('common.sqm'),
            minValue: _minArea,
            maxValue: _maxArea,
            decimalPlaces: 0,
            accentColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _area = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('strip_calc.area_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerimeterInput() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('strip_calc.perimeter'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${_perimeter.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _accentColor,
              inactiveTrackColor: _accentColor.withValues(alpha: 0.2),
              thumbColor: _accentColor,
            ),
            child: Slider(
              value: _perimeter,
              min: _minPerimeter,
              max: _maxPerimeter,
              divisions: ((_maxPerimeter - _minPerimeter) / 2).round(),
              onChanged: (v) {
                setState(() {
                  _perimeter = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          CalculatorTextField(
            label: _loc.translate('strip_calc.perimeter'),
            value: _perimeter,
            suffix: _loc.translate('common.meters'),
            minValue: _minPerimeter,
            maxValue: _maxPerimeter,
            decimalPlaces: 0,
            accentColor: _accentColor,
            onChanged: (v) {
              setState(() {
                _perimeter = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('strip_calc.perimeter_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripDimensionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('strip_calc.strip_dimensions'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          // Ширина ленты
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('strip_calc.strip_width'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${(_width * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _accentColor,
              inactiveTrackColor: _accentColor.withValues(alpha: 0.2),
              thumbColor: _accentColor,
            ),
            child: Slider(
              value: _width,
              min: _minWidth,
              max: _maxWidth,
              divisions: ((_maxWidth - _minWidth) * 20).round(),
              onChanged: (v) {
                setState(() {
                  _width = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Высота ленты
          Row(
            children: [
              Expanded(
                child: Text(
                  _loc.translate('strip_calc.strip_height'),
                  style: CalculatorDesignSystem.bodyMedium.copyWith(
                    color: CalculatorColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '${(_height * 100).toStringAsFixed(0)} ${_loc.translate('common.cm')}',
                style: CalculatorDesignSystem.headlineMedium.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: _accentColor,
              inactiveTrackColor: _accentColor.withValues(alpha: 0.2),
              thumbColor: _accentColor,
            ),
            child: Slider(
              value: _height,
              min: _minHeight,
              max: _maxHeight,
              divisions: ((_maxHeight - _minHeight) * 10).round(),
              onChanged: (v) {
                setState(() {
                  _height = v;
                  _update();
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('strip_calc.dimensions_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(
              color: CalculatorColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('strip_calc.concrete'),
        value:
            '${_result.concreteVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('strip_calc.concrete_desc'),
        icon: Icons.view_in_ar,
      ),
      MaterialItem(
        name: _loc.translate('strip_calc.rebar'),
        value:
            '${_result.rebarWeight.toStringAsFixed(0)} ${_loc.translate('common.kg')}',
        subtitle: _loc.translate('strip_calc.rebar_desc'),
        icon: Icons.grid_4x4,
      ),
      MaterialItem(
        name: _loc.translate('strip_calc.formwork'),
        value:
            '${_result.formworkArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('strip_calc.formwork_desc'),
        icon: Icons.view_sidebar,
      ),
      MaterialItem(
        name: _loc.translate('strip_calc.waterproofing'),
        value:
            '${_result.waterproofingArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate('strip_calc.waterproofing_desc'),
        icon: Icons.water_drop,
      ),
      MaterialItem(
        name: _loc.translate('strip_calc.sand'),
        value:
            '${_result.sandVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('strip_calc.sand_desc'),
        icon: Icons.grain,
      ),
      MaterialItem(
        name: _loc.translate('strip_calc.gravel'),
        value:
            '${_result.gravelVolume.toStringAsFixed(1)} ${_loc.translate('common.cbm')}',
        subtitle: _loc.translate('strip_calc.gravel_desc'),
        icon: Icons.circle,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('group.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 20, color: CalculatorColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                _loc.translate('common.tips'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem(_loc.translate('strip_calc.tip.depth')),
          _buildTipItem(_loc.translate('strip_calc.tip.cushion')),
          _buildTipItem(_loc.translate('strip_calc.tip.curing')),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: _accentColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: CalculatorDesignSystem.bodySmall.copyWith(
                color: CalculatorColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
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
