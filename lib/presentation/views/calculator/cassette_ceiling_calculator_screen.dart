import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_cassette_ceiling_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип кассетного потолка
enum CassetteCeilingType {
  metal('cassette_ceiling_calc.type.metal', 'cassette_ceiling_calc.type.metal_desc', Icons.grid_view),
  mirror('cassette_ceiling_calc.type.mirror', 'cassette_ceiling_calc.type.mirror_desc', Icons.blur_on),
  perforated('cassette_ceiling_calc.type.perforated', 'cassette_ceiling_calc.type.perforated_desc', Icons.grain);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const CassetteCeilingType(this.nameKey, this.descKey, this.icon);
}

/// Размер кассеты
enum CassetteSize {
  size600x600('600x600', 0.36),
  size600x1200('600x1200', 0.72),
  size300x300('300x300', 0.09);

  final String label;
  final double area; // м²
  const CassetteSize(this.label, this.area);
}

enum CassetteCeilingInputMode { manual, room }

class _CassetteCeilingResult {
  final double area;
  final int cassettesCount;
  final double mainProfileLength;
  final double crossProfileLength;
  final double wallProfileLength;
  final int hangersCount;

  const _CassetteCeilingResult({
    required this.area,
    required this.cassettesCount,
    required this.mainProfileLength,
    required this.crossProfileLength,
    required this.wallProfileLength,
    required this.hangersCount,
  });

  factory _CassetteCeilingResult.fromCalculatorResult(Map<String, double> values) {
    return _CassetteCeilingResult(
      area: values['area'] ?? 0,
      cassettesCount: (values['cassettesCount'] ?? 0).toInt(),
      mainProfileLength: values['mainProfileLength'] ?? 0,
      crossProfileLength: values['crossProfileLength'] ?? 0,
      wallProfileLength: values['wallProfileLength'] ?? 0,
      hangersCount: (values['hangersCount'] ?? 0).toInt(),
    );
  }
}

class CassetteCeilingCalculatorScreen extends ConsumerStatefulWidget {
  const CassetteCeilingCalculatorScreen({super.key});

  @override
  ConsumerState<CassetteCeilingCalculatorScreen> createState() => _CassetteCeilingCalculatorScreenState();
}

class _CassetteCeilingCalculatorScreenState extends ConsumerState<CassetteCeilingCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('cassette_ceiling_calc.title');

  // Domain layer calculator
  final _calculator = CalculateCassetteCeilingV2();

  double _area = 20.0;
  double _roomWidth = 4.0;
  double _roomLength = 5.0;

  CassetteCeilingType _ceilingType = CassetteCeilingType.metal;
  CassetteSize _cassetteSize = CassetteSize.size600x600;
  CassetteCeilingInputMode _inputMode = CassetteCeilingInputMode.room;

  late _CassetteCeilingResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _CassetteCeilingResult _calculate() {
    final inputs = <String, double>{
      'area': _area,
      'roomWidth': _roomWidth,
      'roomLength': _roomLength,
      'ceilingType': _ceilingType.index.toDouble(),
      'cassetteSize': _cassetteSize.index.toDouble(),
      'inputMode': _inputMode.index.toDouble(),
    };

    final result = _calculator(inputs, []);
    return _CassetteCeilingResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_ceilingType.nameKey)));
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.size')
        .replaceFirst('{value}', _cassetteSize.label));
    buffer.writeln();
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.cassettes')
        .replaceFirst('{value}', _result.cassettesCount.toString()));
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.main_profile')
        .replaceFirst('{value}', _result.mainProfileLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.cross_profile')
        .replaceFirst('{value}', _result.crossProfileLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.wall_profile')
        .replaceFirst('{value}', _result.wallProfileLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.hangers')
        .replaceFirst('{value}', _result.hangersCount.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('cassette_ceiling_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('cassette_ceiling_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('cassette_ceiling_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('cassette_ceiling_calc.result.cassettes').toUpperCase(),
            value: '${_result.cassettesCount} ${_loc.translate('common.pcs')}',
            icon: Icons.grid_view,
          ),
          ResultItem(
            label: _loc.translate('cassette_ceiling_calc.result.hangers').toUpperCase(),
            value: '${_result.hangersCount} ${_loc.translate('common.pcs')}',
            icon: Icons.hardware,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildSizeSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: CassetteCeilingType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _ceilingType.index,
      onSelect: (index) {
        setState(() {
          _ceilingType = CassetteCeilingType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildSizeSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('cassette_ceiling_calc.label.cassette_size'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: CassetteSize.values.map((size) {
              final isSelected = _cassetteSize == size;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: size != CassetteSize.values.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _cassetteSize = size;
                        _update();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _accentColor : CalculatorColors.cardBackground,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? _accentColor : CalculatorColors.divider,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${size.label} ${_loc.translate('common.mm')}',
                          style: CalculatorDesignSystem.bodySmall.copyWith(
                            color: isSelected ? Colors.white : CalculatorColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
              _loc.translate('cassette_ceiling_calc.mode.manual'),
              _loc.translate('cassette_ceiling_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = CassetteCeilingInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == CassetteCeilingInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('cassette_ceiling_calc.label.area'),
      value: _area,
      min: 5,
      max: 200,
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
            Expanded(child: CalculatorTextField(label: _loc.translate('cassette_ceiling_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('cassette_ceiling_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 20)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('cassette_ceiling_calc.label.ceiling_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('cassette_ceiling_calc.materials.cassettes'),
        value: '${_result.cassettesCount} ${_loc.translate('common.pcs')}',
        subtitle: '${_cassetteSize.label} ${_loc.translate('common.mm')}',
        icon: Icons.grid_view,
      ),
      MaterialItem(
        name: _loc.translate('cassette_ceiling_calc.materials.main_profile'),
        value: '${_result.mainProfileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('cassette_ceiling_calc.materials.main_profile_desc'),
        icon: Icons.straighten,
      ),
      MaterialItem(
        name: _loc.translate('cassette_ceiling_calc.materials.cross_profile'),
        value: '${_result.crossProfileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('cassette_ceiling_calc.materials.cross_profile_desc'),
        icon: Icons.straighten,
      ),
      MaterialItem(
        name: _loc.translate('cassette_ceiling_calc.materials.wall_profile'),
        value: '${_result.wallProfileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('cassette_ceiling_calc.materials.wall_profile_desc'),
        icon: Icons.crop_square,
      ),
      MaterialItem(
        name: _loc.translate('cassette_ceiling_calc.materials.hangers'),
        value: '${_result.hangersCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('cassette_ceiling_calc.materials.hangers_desc'),
        icon: Icons.hardware,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('cassette_ceiling_calc.section.materials'),
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
