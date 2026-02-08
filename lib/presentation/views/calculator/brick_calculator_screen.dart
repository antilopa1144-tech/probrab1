import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_brick.dart';
import '../../mixins/exportable_consumer_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип кирпича
enum BrickType {
  single('brick_calc.type.single', 'brick_calc.type.single_desc', Icons.crop_square),
  oneAndHalf('brick_calc.type.one_and_half', 'brick_calc.type.one_and_half_desc', Icons.view_agenda),
  double('brick_calc.type.double', 'brick_calc.type.double_desc', Icons.view_stream);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const BrickType(this.nameKey, this.descKey, this.icon);
}

/// Толщина кладки (в кирпичах)
enum WallThickness {
  half('brick_calc.thickness.half', '120'),        // 0.5 кирпича = 120 мм
  one('brick_calc.thickness.one', '250'),           // 1 кирпич = 250 мм
  oneAndHalf('brick_calc.thickness.one_half', '380'), // 1.5 кирпича = 380 мм
  two('brick_calc.thickness.two', '510');           // 2 кирпича = 510 мм

  final String nameKey;
  final String thicknessMm;
  const WallThickness(this.nameKey, this.thicknessMm);
}

enum BrickInputMode { manual, wall }

/// Результат расчёта кирпичной кладки
class _BrickResult {
  final double area;
  final int bricksNeeded;
  final double mortarVolume;    // м³
  final int mortarBags;         // мешки по 25 кг
  final int brickLength;
  final int brickWidth;
  final int brickHeight;

  const _BrickResult({
    required this.area,
    required this.bricksNeeded,
    required this.mortarVolume,
    required this.mortarBags,
    required this.brickLength,
    required this.brickWidth,
    required this.brickHeight,
  });

  factory _BrickResult.fromCalculatorResult(Map<String, double> values) {
    return _BrickResult(
      area: values['area'] ?? 0,
      bricksNeeded: (values['bricksNeeded'] ?? 0).toInt(),
      mortarVolume: values['mortarVolume'] ?? 0,
      mortarBags: (values['mortarBags'] ?? 0).toInt(),
      brickLength: (values['brickLength'] ?? 250).toInt(),
      brickWidth: (values['brickWidth'] ?? 120).toInt(),
      brickHeight: (values['brickHeight'] ?? 65).toInt(),
    );
  }
}

class BrickCalculatorScreen extends ConsumerStatefulWidget {
  final Map<String, double>? initialInputs;

  const BrickCalculatorScreen({
    super.key,
    this.initialInputs,
  });

  @override
  ConsumerState<BrickCalculatorScreen> createState() => _BrickCalculatorScreenState();
}

class _BrickCalculatorScreenState extends ConsumerState<BrickCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('brick_calc.title');

  // Domain layer calculator
  final _calculator = CalculateBrick();

  // Состояние
  double _area = 20.0;
  double _wallWidth = 5.0;
  double _wallHeight = 2.7;

  BrickType _brickType = BrickType.single;
  WallThickness _wallThickness = WallThickness.one;
  BrickInputMode _inputMode = BrickInputMode.manual;

  late _BrickResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.walls;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;

    if (initial['area'] != null) _area = initial['area']!.clamp(1.0, 10000.0);
    if (initial['wallWidth'] != null) _wallWidth = initial['wallWidth']!.clamp(0.1, 100.0);
    if (initial['wallHeight'] != null) _wallHeight = initial['wallHeight']!.clamp(0.1, 50.0);

    if (initial['brickType'] != null) {
      final type = initial['brickType']!.toInt();
      if (type >= 0 && type < BrickType.values.length) {
        _brickType = BrickType.values[type];
      }
    }

    if (initial['wallThickness'] != null) {
      final thickness = initial['wallThickness']!.toInt();
      if (thickness >= 0 && thickness < WallThickness.values.length) {
        _wallThickness = WallThickness.values[thickness];
      }
    }

    if (initial['inputMode'] != null) {
      final mode = initial['inputMode']!.toInt();
      _inputMode = mode == 0 ? BrickInputMode.manual : BrickInputMode.wall;
    }
  }

  /// Использует domain layer для расчёта
  _BrickResult _calculate() {
    final inputs = <String, double>{
      'brickType': _brickType.index.toDouble(),
      'wallThickness': _wallThickness.index.toDouble(),
    };

    // Передаём либо площадь, либо размеры стены
    if (_inputMode == BrickInputMode.manual) {
      inputs['area'] = _area;
    } else {
      inputs['wallWidth'] = _wallWidth;
      inputs['wallHeight'] = _wallHeight;
    }

    final result = _calculator(inputs, []);
    return _BrickResult.fromCalculatorResult(result.values);
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String? get calculatorId => 'brick';

  @override
  Map<String, dynamic>? getCurrentInputs() {
    return {
      'area': _area,
      'wallWidth': _wallWidth,
      'wallHeight': _wallHeight,
      'brickType': _brickType.index.toDouble(),
      'wallThickness': _wallThickness.index.toDouble(),
      'inputMode': (_inputMode == BrickInputMode.manual ? 0 : 1).toDouble(),
    };
  }

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('brick_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('brick_calc.export.area')
        .replaceFirst('{value}', _result.area.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('brick_calc.export.brick_type')
        .replaceFirst('{value}', _loc.translate(_brickType.nameKey)));
    buffer.writeln(_loc.translate('brick_calc.export.wall_thickness')
        .replaceFirst('{value}', _loc.translate(_wallThickness.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('brick_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('brick_calc.export.bricks')
        .replaceFirst('{value}', _result.bricksNeeded.toString()));
    buffer.writeln(_loc.translate('brick_calc.export.mortar')
        .replaceFirst('{value}', _result.mortarVolume.toStringAsFixed(2)));
    buffer.writeln(_loc.translate('brick_calc.export.mortar_bags')
        .replaceFirst('{value}', _result.mortarBags.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('brick_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    _isDark = Theme.of(context).brightness == Brightness.dark;

    return CalculatorScaffold(
      title: _loc.translate('brick_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('brick_calc.result.area').toUpperCase(),
            value: '${_result.area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('brick_calc.result.bricks').toUpperCase(),
            value: '${_result.bricksNeeded}',
            icon: Icons.grid_view,
          ),
          ResultItem(
            label: _loc.translate('brick_calc.result.mortar').toUpperCase(),
            value: '${_result.mortarBags} ${_loc.translate('common.pcs')}',
            icon: Icons.inventory_2,
          ),
        ],
      ),
      children: [
        _buildBrickTypeSelector(),
        const SizedBox(height: 16),
        _buildThicknessSelector(),
        const SizedBox(height: 16),
        _buildAreaCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBrickTypeSelector() {
    return TypeSelectorGroup(
      options: BrickType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _brickType.index,
      onSelect: (index) {
        setState(() {
          _brickType = BrickType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildThicknessSelector() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('brick_calc.section.thickness'),
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark)),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: WallThickness.values.map((t) => _loc.translate(t.nameKey)).toList(),
            selectedIndex: _wallThickness.index,
            onSelect: (index) {
              setState(() {
                _wallThickness = WallThickness.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 8),
          Text(
            _loc.translate('brick_calc.thickness_info')
                .replaceFirst('{value}', _wallThickness.thicknessMm),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500),
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
              _loc.translate('brick_calc.mode.manual'),
              _loc.translate('brick_calc.mode.wall'),
            ],
            selectedIndex: _inputMode.index,
            onSelect: (index) {
              setState(() {
                _inputMode = BrickInputMode.values[index];
                _update();
              });
            },
            accentColor: _accentColor,
          ),
          const SizedBox(height: 20),
          _inputMode == BrickInputMode.manual ? _buildManualInputs() : _buildWallInputs(),
        ],
      ),
    );
  }

  Widget _buildManualInputs() {
    return CalculatorSliderField(
      label: _loc.translate('brick_calc.label.area'),
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

  Widget _buildWallInputs() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: CalculatorTextField(label: _loc.translate('brick_calc.label.wall_width'), value: _wallWidth, onChanged: (v) { setState(() { _wallWidth = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 50)),
            const SizedBox(width: 12),
            Expanded(child: CalculatorTextField(label: _loc.translate('brick_calc.label.wall_height'), value: _wallHeight, onChanged: (v) { setState(() { _wallHeight = v; _update(); }); }, suffix: _loc.translate('common.meters'), accentColor: _accentColor, minValue: 1, maxValue: 10)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('brick_calc.label.wall_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w600)),
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
        name: _loc.translate('brick_calc.materials.bricks'),
        value: '${_result.bricksNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '${_result.brickLength}×${_result.brickWidth}×${_result.brickHeight} ${_loc.translate('common.mm')}',
        icon: Icons.grid_view,
      ),
      MaterialItem(
        name: _loc.translate('brick_calc.materials.mortar'),
        value: '${_result.mortarVolume.toStringAsFixed(2)} ${_loc.translate('common.cbm')}',
        subtitle: '${_result.mortarBags} ${_loc.translate('brick_calc.materials.bags')}',
        icon: Icons.inventory_2,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('brick_calc.section.materials'),
      titleIcon: Icons.receipt_long,
      items: items,
      accentColor: _accentColor,
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];

    switch (_brickType) {
      case BrickType.single:
        tips.addAll([
          _loc.translate('brick_calc.tip.single_1'),
          _loc.translate('brick_calc.tip.single_2'),
        ]);
        break;
      case BrickType.oneAndHalf:
        tips.addAll([
          _loc.translate('brick_calc.tip.one_half_1'),
          _loc.translate('brick_calc.tip.one_half_2'),
        ]);
        break;
      case BrickType.double:
        tips.addAll([
          _loc.translate('brick_calc.tip.double_1'),
          _loc.translate('brick_calc.tip.double_2'),
        ]);
        break;
    }

    tips.add(_loc.translate('brick_calc.tip.common'));

    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
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
