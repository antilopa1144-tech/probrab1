import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип реечного потолка
enum RailCeilingType {
  aluminum('rail_ceiling_calc.type.aluminum', 'rail_ceiling_calc.type.aluminum_desc', Icons.view_column),
  steel('rail_ceiling_calc.type.steel', 'rail_ceiling_calc.type.steel_desc', Icons.iron),
  plastic('rail_ceiling_calc.type.plastic', 'rail_ceiling_calc.type.plastic_desc', Icons.layers);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const RailCeilingType(this.nameKey, this.descKey, this.icon);
}

/// Ширина рейки
enum RailWidth {
  width84('84', 0.084),
  width100('100', 0.100),
  width150('150', 0.150);

  final String label;
  final double meters;
  const RailWidth(this.label, this.meters);
}

enum RailCeilingInputMode { manual, room }

class _RailCeilingResult {
  final double area;
  final int railsCount;
  final double railLength;
  final double stringerLength;
  final double wallProfileLength;
  final int hangersCount;

  const _RailCeilingResult({
    required this.area,
    required this.railsCount,
    required this.railLength,
    required this.stringerLength,
    required this.wallProfileLength,
    required this.hangersCount,
  });
}

class RailCeilingCalculatorScreen extends StatefulWidget {
  const RailCeilingCalculatorScreen({super.key});

  @override
  State<RailCeilingCalculatorScreen> createState() => _RailCeilingCalculatorScreenState();
}

class _RailCeilingCalculatorScreenState extends State<RailCeilingCalculatorScreen> {
  double _area = 12.0;
  double _roomWidth = 3.0;
  double _roomLength = 4.0;

  RailCeilingType _ceilingType = RailCeilingType.aluminum;
  RailWidth _railWidth = RailWidth.width100;
  RailCeilingInputMode _inputMode = RailCeilingInputMode.room;

  late _RailCeilingResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _RailCeilingResult _calculate() {
    double area = _area;
    double roomWidth = _roomWidth;
    double roomLength = _roomLength;

    if (_inputMode == RailCeilingInputMode.room) {
      area = roomWidth * roomLength;
    } else {
      final side = math.sqrt(area);
      roomWidth = side;
      roomLength = side;
    }

    final perimeter = 2 * (roomWidth + roomLength);

    // Количество реек (ширина комнаты / ширина рейки + зазор 16мм)
    final railStep = _railWidth.meters + 0.016;
    final railsCount = (roomWidth / railStep).ceil();

    // Длина реек = количество * длина комнаты + 5% запас
    final railLength = railsCount * roomLength * 1.05;

    // Стрингеры (несущие шины): через каждые 1.2 м
    final stringerRows = (roomWidth / 1.2).ceil();
    final stringerLength = stringerRows * roomLength * 1.1;

    // Пристенный профиль = периметр + 10%
    final wallProfileLength = perimeter * 1.1;

    // Подвесы: через каждые 1.2 м по длине стрингера
    final hangersCount = stringerRows * (roomLength / 1.2).ceil();

    return _RailCeilingResult(
      area: area,
      railsCount: railsCount,
      railLength: railLength,
      stringerLength: stringerLength,
      wallProfileLength: wallProfileLength,
      hangersCount: hangersCount,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_ceilingType.nameKey)));
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.rail_width')
        .replaceFirst('{value}', _railWidth.label));
    buffer.writeln();
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.rails')
        .replaceFirst('{value}', _result.railsCount.toString()));
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.rail_length')
        .replaceFirst('{value}', _result.railLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.stringers')
        .replaceFirst('{value}', _result.stringerLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.wall_profile')
        .replaceFirst('{value}', _result.wallProfileLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.hangers')
        .replaceFirst('{value}', _result.hangersCount.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('rail_ceiling_calc.export.footer'));
    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('rail_ceiling_calc.title')));
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
      title: _loc.translate('rail_ceiling_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('rail_ceiling_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('rail_ceiling_calc.result.rails').toUpperCase(),
            value: '${_result.railsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.view_column,
          ),
          ResultItem(
            label: _loc.translate('rail_ceiling_calc.result.hangers').toUpperCase(),
            value: '${_result.hangersCount} ${_loc.translate('common.pcs')}',
            icon: Icons.hardware,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildWidthSelector(),
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
      options: RailCeilingType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _ceilingType.index,
      onSelect: (index) {
        setState(() {
          _ceilingType = RailCeilingType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildWidthSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('rail_ceiling_calc.label.rail_width'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: RailWidth.values.map((width) {
              final isSelected = _railWidth == width;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: width != RailWidth.values.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _railWidth = width;
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
                          '${width.label} ${_loc.translate('common.mm')}',
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
              _loc.translate('rail_ceiling_calc.mode.manual'),
              _loc.translate('rail_ceiling_calc.mode.room'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = RailCeilingInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == RailCeilingInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
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
            Text(_loc.translate('rail_ceiling_calc.label.area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
            Text('${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(value: _area, min: 2, max: 100, activeColor: _accentColor, onChanged: (v) { setState(() { _area = v; _update(); }); }),
      ],
    );
  }

  Widget _buildRoomInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('rail_ceiling_calc.label.width'), value: _roomWidth, onChanged: (v) { setState(() { _roomWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 15)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('rail_ceiling_calc.label.length'), value: _roomLength, onChanged: (v) { setState(() { _roomLength = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 15)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('rail_ceiling_calc.label.ceiling_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
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
        name: _loc.translate('rail_ceiling_calc.materials.rails'),
        value: '${_result.railsCount} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.railLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        icon: Icons.view_column,
      ),
      MaterialItem(
        name: _loc.translate('rail_ceiling_calc.materials.stringers'),
        value: '${_result.stringerLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('rail_ceiling_calc.materials.stringers_desc'),
        icon: Icons.straighten,
      ),
      MaterialItem(
        name: _loc.translate('rail_ceiling_calc.materials.wall_profile'),
        value: '${_result.wallProfileLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('rail_ceiling_calc.materials.wall_profile_desc'),
        icon: Icons.crop_square,
      ),
      MaterialItem(
        name: _loc.translate('rail_ceiling_calc.materials.hangers'),
        value: '${_result.hangersCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('rail_ceiling_calc.materials.hangers_desc'),
        icon: Icons.hardware,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('rail_ceiling_calc.section.materials'),
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
