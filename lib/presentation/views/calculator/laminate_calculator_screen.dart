import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_laminate_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Способ укладки ламината
enum LaminatePattern {
  straight('laminate_calc.pattern.straight', 'laminate_calc.pattern.straight_desc', Icons.view_stream),
  diagonal('laminate_calc.pattern.diagonal', 'laminate_calc.pattern.diagonal_desc', Icons.rotate_right);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const LaminatePattern(this.nameKey, this.descKey, this.icon);
}

/// Класс ламината
enum LaminateClass {
  class31('laminate_calc.class.31', 'laminate_calc.class.31_desc'),
  class32('laminate_calc.class.32', 'laminate_calc.class.32_desc'),
  class33('laminate_calc.class.33', 'laminate_calc.class.33_desc');

  final String nameKey;
  final String descKey;
  const LaminateClass(this.nameKey, this.descKey);
}

enum LaminateInputMode { manual, room }

/// Результат расчёта ламината
class _LaminateResult {
  final double area;
  final double areaWithWaste;
  final int packsNeeded;
  final double packArea;
  final double underlayArea;
  final int underlayRolls;
  final double plinthLength;
  final int plinthPieces;

  const _LaminateResult({
    required this.area,
    required this.areaWithWaste,
    required this.packsNeeded,
    required this.packArea,
    required this.underlayArea,
    required this.underlayRolls,
    required this.plinthLength,
    required this.plinthPieces,
  });

  factory _LaminateResult.fromCalculatorResult(Map<String, double> values) {
    return _LaminateResult(
      area: values['area'] ?? 0,
      areaWithWaste: values['areaWithWaste'] ?? 0,
      packsNeeded: (values['packsNeeded'] ?? 0).toInt(),
      packArea: values['packArea'] ?? 2.4,
      underlayArea: values['underlayArea'] ?? 0,
      underlayRolls: (values['underlayRolls'] ?? 0).toInt(),
      plinthLength: values['plinthLength'] ?? 0,
      plinthPieces: (values['plinthPieces'] ?? 0).toInt(),
    );
  }
}

class LaminateCalculatorScreen extends ConsumerStatefulWidget {
  const LaminateCalculatorScreen({super.key});

  @override
  ConsumerState<LaminateCalculatorScreen> createState() => _LaminateCalculatorScreenState();
}

class _LaminateCalculatorScreenState extends ConsumerState<LaminateCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('laminate_calc.title');

  // Domain layer calculator
  final _calculator = CalculateLaminateV2();

  // Состояние
  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _packArea = 2.4; // м² в упаковке

  LaminatePattern _pattern = LaminatePattern.straight;
  LaminateClass _laminateClass = LaminateClass.class32;
  LaminateInputMode _inputMode = LaminateInputMode.manual;
  bool _needUnderlay = true;
  bool _needPlinth = true;

  late _LaminateResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _LaminateResult _calculate() {
    final inputs = <String, double>{
      'pattern': _pattern.index.toDouble(),
      'packArea': _packArea,
      'needUnderlay': _needUnderlay ? 1.0 : 0.0,
      'needPlinth': _needPlinth ? 1.0 : 0.0,
    };

    // Передаём либо площадь, либо размеры комнаты
    if (_inputMode == LaminateInputMode.manual) {
      inputs['area'] = _area;
    } else {
      inputs['roomWidth'] = _roomWidth;
      inputs['roomLength'] = _roomLength;
    }

    final result = _calculator(inputs, []);
    return _LaminateResult.fromCalculatorResult(result.values);
  }

  /// Процент отходов для экспорта
  double _getWastePercent() {
    return _pattern == LaminatePattern.straight ? 0.05 : 0.15;
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('laminate_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('laminate_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('laminate_calc.export.pattern')
        .replaceFirst('{value}', _loc.translate(_pattern.nameKey)));
    buffer.writeln(_loc.translate('laminate_calc.export.waste')
        .replaceFirst('{value}', (_getWastePercent() * 100).toStringAsFixed(0)));
    buffer.writeln();
    buffer.writeln(_loc.translate('laminate_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('laminate_calc.export.packs')
        .replaceFirst('{value}', _result.packsNeeded.toString())
        .replaceFirst('{area}', _result.packArea.toStringAsFixed(1)));
    if (_needUnderlay) {
      buffer.writeln(_loc.translate('laminate_calc.export.underlay')
          .replaceFirst('{value}', _result.underlayRolls.toString()));
    }
    if (_needPlinth) {
      buffer.writeln(_loc.translate('laminate_calc.export.plinth')
          .replaceFirst('{value}', _result.plinthPieces.toString()));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('laminate_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('laminate_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('laminate_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('laminate_calc.result.packs').toUpperCase(),
            value: '${_result.packsNeeded}',
            icon: Icons.inventory_2,
          ),
          ResultItem(
            label: _loc.translate('laminate_calc.result.total_area').toUpperCase(),
            value: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.crop_square,
          ),
        ],
      ),
      children: [
        _buildPatternSelector(),
        const SizedBox(height: 16),
        _buildClassSelector(),
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

    switch (_pattern) {
      case LaminatePattern.straight:
        tips.addAll([
          _loc.translate('laminate_calc.tip.straight_1'),
          _loc.translate('laminate_calc.tip.straight_2'),
        ]);
        break;
      case LaminatePattern.diagonal:
        tips.addAll([
          _loc.translate('laminate_calc.tip.diagonal_1'),
          _loc.translate('laminate_calc.tip.diagonal_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('laminate_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
    );
  }

  Widget _buildPatternSelector() {
    return TypeSelectorGroup(
      options: LaminatePattern.values.map((p) => TypeSelectorOption(
        icon: p.icon,
        title: _loc.translate(p.nameKey),
        subtitle: _loc.translate(p.descKey),
      )).toList(),
      selectedIndex: _pattern.index,
      onSelect: (index) {
        setState(() {
          _pattern = LaminatePattern.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildClassSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('laminate_calc.section.class'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: LaminateClass.values.map((c) => _loc.translate(c.nameKey)).toList(),
            selectedIndex: _laminateClass.index,
            onSelect: (index) {
              setState(() {
                _laminateClass = LaminateClass.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate(_laminateClass.descKey),
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
              _loc.translate('laminate_calc.mode.manual'),
              _loc.translate('laminate_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = LaminateInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == LaminateInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('laminate_calc.label.area'),
      value: _area,
      min: 5,
      max: 200,
      suffix: _loc.translate('common.sqm'),
      accentColor: _accentColor,
      onChanged: (v) {
        setState(() {
          _area = v;
          _update();
        });
      },
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('laminate_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('laminate_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('laminate_calc.label.floor_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
            label: _loc.translate('laminate_calc.label.pack_area'),
            value: _packArea,
            min: 1.5,
            max: 4.0,
            divisions: 10,
            suffix: _loc.translate('common.sqm'),
            accentColor: _accentColor,
            decimalPlaces: 1,
            onChanged: (v) {
              setState(() {
                _packArea = v;
                _update();
              });
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('laminate_calc.option.underlay'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('laminate_calc.option.underlay_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needUnderlay,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needUnderlay = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('laminate_calc.option.plinth'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('laminate_calc.option.plinth_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needPlinth,
            activeTrackColor: _accentColor,
            onChanged: (v) { setState(() { _needPlinth = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('laminate_calc.materials.laminate'),
        value: '${_result.packsNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.areaWithWaste.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.layers,
      ),
    ];

    if (_needUnderlay && _result.underlayRolls > 0) {
      items.add(MaterialItem(
        name: _loc.translate('laminate_calc.materials.underlay'),
        value: '${_result.underlayRolls} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.underlayArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
        icon: Icons.view_agenda,
      ));
    }

    if (_needPlinth && _result.plinthPieces > 0) {
      items.add(MaterialItem(
        name: _loc.translate('laminate_calc.materials.plinth'),
        value: '${_result.plinthPieces} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.plinthLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.straighten,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('laminate_calc.section.materials'),
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
