import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_stretch_ceiling_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип полотна
enum StretchCeilingType {
  matte('stretch_ceiling_calc.type.matte', 'stretch_ceiling_calc.type.matte_desc', Icons.blur_off),
  glossy('stretch_ceiling_calc.type.glossy', 'stretch_ceiling_calc.type.glossy_desc', Icons.blur_on),
  satin('stretch_ceiling_calc.type.satin', 'stretch_ceiling_calc.type.satin_desc', Icons.gradient),
  fabric('stretch_ceiling_calc.type.fabric', 'stretch_ceiling_calc.type.fabric_desc', Icons.texture);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const StretchCeilingType(this.nameKey, this.descKey, this.icon);
}

enum StretchCeilingInputMode { manual, room }

class _StretchCeilingResult {
  final double area;
  final double perimeter;
  final double profileLength;
  final int lightsCount;
  final int cornersCount;

  const _StretchCeilingResult({
    required this.area,
    required this.perimeter,
    required this.profileLength,
    required this.lightsCount,
    required this.cornersCount,
  });

  factory _StretchCeilingResult.fromCalculatorResult(Map<String, double> values) {
    return _StretchCeilingResult(
      area: values['area'] ?? 0,
      perimeter: values['perimeter'] ?? 0,
      profileLength: values['profileLength'] ?? 0,
      lightsCount: (values['lightsCount'] ?? 0).toInt(),
      cornersCount: (values['cornersCount'] ?? 4).toInt(),
    );
  }
}

class StretchCeilingCalculatorScreen extends ConsumerStatefulWidget {
  const StretchCeilingCalculatorScreen({super.key});

  @override
  ConsumerState<StretchCeilingCalculatorScreen> createState() => _StretchCeilingCalculatorScreenState();
}

class _StretchCeilingCalculatorScreenState extends ConsumerState<StretchCeilingCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('stretch_ceiling_calc.title');

  // Domain layer calculator
  final _calculator = CalculateStretchCeilingV2();

  double _area = 16.0;
  double _roomWidth = 4.0;
  double _roomLength = 4.0;
  int _lightsCount = 4;

  StretchCeilingType _ceilingType = StretchCeilingType.matte;
  StretchCeilingInputMode _inputMode = StretchCeilingInputMode.room;

  late _StretchCeilingResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _StretchCeilingResult _calculate() {
    final inputs = <String, double>{
      'area': _area,
      'roomWidth': _roomWidth,
      'roomLength': _roomLength,
      'lightsCount': _lightsCount.toDouble(),
      'ceilingType': _ceilingType.index.toDouble(),
      'inputMode': _inputMode.index.toDouble(),
    };

    final result = _calculator(inputs, []);
    return _StretchCeilingResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_ceilingType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.canvas')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.profile')
        .replaceFirst('{value}', _result.profileLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.lights')
        .replaceFirst('{value}', _result.lightsCount.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('stretch_ceiling_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('stretch_ceiling_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('stretch_ceiling_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('stretch_ceiling_calc.result.perimeter').toUpperCase(),
            value: '${_result.perimeter.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
            icon: Icons.crop_square,
          ),
          ResultItem(
            label: _loc.translate('stretch_ceiling_calc.result.lights').toUpperCase(),
            value: '${_result.lightsCount}',
            icon: Icons.lightbulb,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
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

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_ceilingType) {
      case StretchCeilingType.matte:
        tips.addAll([
          _loc.translate('stretch_ceiling_calc.tip.matte_1'),
          _loc.translate('stretch_ceiling_calc.tip.matte_2'),
        ]);
        break;
      case StretchCeilingType.glossy:
        tips.addAll([
          _loc.translate('stretch_ceiling_calc.tip.glossy_1'),
          _loc.translate('stretch_ceiling_calc.tip.glossy_2'),
        ]);
        break;
      case StretchCeilingType.satin:
        tips.addAll([
          _loc.translate('stretch_ceiling_calc.tip.satin_1'),
          _loc.translate('stretch_ceiling_calc.tip.satin_2'),
        ]);
        break;
      case StretchCeilingType.fabric:
        tips.addAll([
          _loc.translate('stretch_ceiling_calc.tip.fabric_1'),
          _loc.translate('stretch_ceiling_calc.tip.fabric_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('stretch_ceiling_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: StretchCeilingType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _ceilingType.index,
      onSelect: (index) {
        setState(() {
          _ceilingType = StretchCeilingType.values[index];
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
              _loc.translate('stretch_ceiling_calc.mode.manual'),
              _loc.translate('stretch_ceiling_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = StretchCeilingInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == StretchCeilingInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('stretch_ceiling_calc.label.area'),
      value: _area,
      min: 5,
      max: 100,
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
            Expanded(child: CalculatorTextField(label: _loc.translate('stretch_ceiling_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 15)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('stretch_ceiling_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 15)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('stretch_ceiling_calc.label.ceiling_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
            label: _loc.translate('stretch_ceiling_calc.label.lights_count'),
            value: _lightsCount.toDouble(),
            min: 0,
            max: 20,
            divisions: 20,
            suffix: _loc.translate('common.pcs'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _lightsCount = v.toInt(); _update(); }); },
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('stretch_ceiling_calc.lights_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('stretch_ceiling_calc.materials.canvas'),
        value: '${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        subtitle: _loc.translate(_ceilingType.nameKey),
        icon: Icons.crop_square,
      ),
      MaterialItem(
        name: _loc.translate('stretch_ceiling_calc.materials.profile'),
        value: '${_result.profileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('stretch_ceiling_calc.materials.profile_desc'),
        icon: Icons.straighten,
      ),
    ];

    if (_lightsCount > 0) {
      items.add(MaterialItem(
        name: _loc.translate('stretch_ceiling_calc.materials.lights'),
        value: '$_lightsCount ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('stretch_ceiling_calc.materials.lights_desc'),
        icon: Icons.lightbulb,
      ));
    }

    items.add(MaterialItem(
      name: _loc.translate('stretch_ceiling_calc.materials.corners'),
      value: '${_result.cornersCount} ${_loc.translate('common.pcs')}',
      icon: Icons.rounded_corner,
    ));

    return MaterialsCardModern(
      title: _loc.translate('stretch_ceiling_calc.section.materials'),
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
