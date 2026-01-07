import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
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

class _BrickResult {
  final double area;
  final int bricksNeeded;
  final double mortarVolume;    // м³
  final int mortarBags;         // мешки по 25 кг

  const _BrickResult({
    required this.area,
    required this.bricksNeeded,
    required this.mortarVolume,
    required this.mortarBags,
  });
}

class BrickCalculatorScreen extends StatefulWidget {
  const BrickCalculatorScreen({super.key});

  @override
  State<BrickCalculatorScreen> createState() => _BrickCalculatorScreenState();
}

class _BrickCalculatorScreenState extends State<BrickCalculatorScreen> {
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

  // Размеры кирпича (мм): длина x ширина x высота
  static const _brickSizes = {
    BrickType.single: (250, 120, 65),
    BrickType.oneAndHalf: (250, 120, 88),
    BrickType.double: (250, 120, 138),
  };

  // Количество кирпичей на 1 м² кладки (с учётом швов)
  Map<BrickType, Map<WallThickness, int>> get _bricksPerSqm => {
    BrickType.single: {
      WallThickness.half: 51,
      WallThickness.one: 102,
      WallThickness.oneAndHalf: 153,
      WallThickness.two: 204,
    },
    BrickType.oneAndHalf: {
      WallThickness.half: 39,
      WallThickness.one: 78,
      WallThickness.oneAndHalf: 117,
      WallThickness.two: 156,
    },
    BrickType.double: {
      WallThickness.half: 26,
      WallThickness.one: 52,
      WallThickness.oneAndHalf: 78,
      WallThickness.two: 104,
    },
  };

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _BrickResult _calculate() {
    double area = _area;
    if (_inputMode == BrickInputMode.wall) {
      area = _wallWidth * _wallHeight;
    }

    // Количество кирпичей
    final bricksPerSqm = _bricksPerSqm[_brickType]![_wallThickness]!;
    final bricksNeeded = (area * bricksPerSqm * 1.05).ceil(); // +5% запас

    // Расход раствора (примерно 0.2-0.25 м³ на 1000 кирпичей для толщины 1 кирпич)
    final mortarPerBrick = 0.00025; // м³ на кирпич
    final thicknessMultiplier = switch (_wallThickness) {
      WallThickness.half => 0.6,
      WallThickness.one => 1.0,
      WallThickness.oneAndHalf => 1.4,
      WallThickness.two => 1.8,
    };
    final mortarVolume = bricksNeeded * mortarPerBrick * thicknessMultiplier;

    // Мешки (1 мешок 25 кг ≈ 0.015 м³ раствора)
    final mortarBags = (mortarVolume / 0.015).ceil();

    return _BrickResult(
      area: area,
      bricksNeeded: bricksNeeded,
      mortarVolume: mortarVolume,
      mortarBags: mortarBags,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
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

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('brick_calc.title')));
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
      title: _loc.translate('brick_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
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
            style: CalculatorDesignSystem.titleMedium.copyWith(color: CalculatorColors.textPrimary),
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
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_loc.translate('brick_calc.label.area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
            Text('${_area.toStringAsFixed(0)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(value: _area, min: 5, max: 200, activeColor: _accentColor, onChanged: (v) { setState(() { _area = v; _update(); }); }),
      ],
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
              Text(_loc.translate('brick_calc.label.wall_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_result.area.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsCard() {
    final brickSize = _brickSizes[_brickType]!;
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('brick_calc.materials.bricks'),
        value: '${_result.bricksNeeded} ${_loc.translate('common.pcs')}',
        subtitle: '${brickSize.$1}×${brickSize.$2}×${brickSize.$3} ${_loc.translate('common.mm')}',
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

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: CalculatorDesignSystem.cardDecoration(),
      child: child,
    );
  }
}
