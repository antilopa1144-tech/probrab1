import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations.dart';
import '../../mixins/exportable_mixin.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип забора
enum FenceType {
  profiled('fence_calc.type.profiled', 'fence_calc.type.profiled_desc', Icons.view_column),
  picket('fence_calc.type.picket', 'fence_calc.type.picket_desc', Icons.fence),
  chain('fence_calc.type.chain', 'fence_calc.type.chain_desc', Icons.grid_on);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const FenceType(this.nameKey, this.descKey, this.icon);
}

class _FenceResult {
  final double fenceLength;
  final double fenceArea;
  final int postsCount;
  final double lagsLength;
  final int sheetsCount;
  final int fastenersBags;

  const _FenceResult({
    required this.fenceLength,
    required this.fenceArea,
    required this.postsCount,
    required this.lagsLength,
    required this.sheetsCount,
    required this.fastenersBags,
  });
}

class FenceCalculatorScreen extends StatefulWidget {
  const FenceCalculatorScreen({super.key});

  @override
  State<FenceCalculatorScreen> createState() => _FenceCalculatorScreenState();
}

class _FenceCalculatorScreenState extends State<FenceCalculatorScreen>
    with ExportableMixin {
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('fence_calc.title');

  double _fenceLength = 50.0;
  double _fenceHeight = 2.0;
  double _postSpacing = 2.5;

  FenceType _fenceType = FenceType.profiled;

  late _FenceResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _FenceResult _calculate() {
    final fenceLength = _fenceLength;
    final fenceArea = fenceLength * _fenceHeight;

    // Столбы
    final postsCount = (fenceLength / _postSpacing).ceil() + 1;

    // Лаги (поперечины): 2-3 ряда в зависимости от высоты
    final lagsRows = _fenceHeight > 1.8 ? 3 : 2;
    final lagsLength = fenceLength * lagsRows * 1.05;

    // Листы/штакетник
    int sheetsCount;
    switch (_fenceType) {
      case FenceType.profiled:
        // Профлист 1.15м шириной
        sheetsCount = (fenceLength / 1.1).ceil();
      case FenceType.picket:
        // Штакетник 10 см шириной с зазором 5 см
        sheetsCount = (fenceLength / 0.15).ceil();
      case FenceType.chain:
        // Сетка в рулонах по 10м
        sheetsCount = (fenceLength / 10).ceil();
    }

    // Крепёж: примерно 8 саморезов на м²
    final fastenersBags = ((fenceArea * 8) / 200).ceil(); // 200 шт в упаковке

    return _FenceResult(
      fenceLength: fenceLength,
      fenceArea: fenceArea,
      postsCount: postsCount,
      lagsLength: lagsLength,
      sheetsCount: sheetsCount,
      fastenersBags: fastenersBags,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  String generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('fence_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('fence_calc.export.length')
        .replaceFirst('{value}', _result.fenceLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('fence_calc.export.area')
        .replaceFirst('{value}', _result.fenceArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('fence_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_fenceType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('fence_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('fence_calc.export.posts')
        .replaceFirst('{value}', _result.postsCount.toString()));
    buffer.writeln(_loc.translate('fence_calc.export.lags')
        .replaceFirst('{value}', _result.lagsLength.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('fence_calc.export.sheets')
        .replaceFirst('{value}', _result.sheetsCount.toString()));
    buffer.writeln(_loc.translate('fence_calc.export.fasteners')
        .replaceFirst('{value}', _result.fastenersBags.toString()));
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('fence_calc.export.footer'));
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);

    return CalculatorScaffold(
      title: _loc.translate('fence_calc.title'),
      accentColor: _accentColor,
      actions: exportActions,
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('fence_calc.result.length').toUpperCase(),
            value: '${_result.fenceLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('fence_calc.result.posts').toUpperCase(),
            value: '${_result.postsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.view_column,
          ),
          ResultItem(
            label: _loc.translate('fence_calc.result.sheets').toUpperCase(),
            value: '${_result.sheetsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildSpacingCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: FenceType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _fenceType.index,
      onSelect: (index) {
        setState(() {
          _fenceType = FenceType.values[index];
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('fence_calc.label.length'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_fenceLength.toStringAsFixed(0)} ${_loc.translate('common.meters')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _fenceLength, min: 10, max: 500, activeColor: _accentColor, onChanged: (v) { setState(() { _fenceLength = v; _update(); }); }),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('fence_calc.label.height'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_fenceHeight.toStringAsFixed(1)} ${_loc.translate('common.meters')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(value: _fenceHeight, min: 1.0, max: 3.0, divisions: 8, activeColor: _accentColor, onChanged: (v) { setState(() { _fenceHeight = v; _update(); }); }),
        ],
      ),
    );
  }

  Widget _buildSpacingCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('fence_calc.label.post_spacing'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('${_postSpacing.toStringAsFixed(1)} ${_loc.translate('common.meters')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _postSpacing,
            min: 2.0,
            max: 3.5,
            divisions: 6,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _postSpacing = v; _update(); }); },
          ),
          Text(
            _loc.translate('fence_calc.spacing_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    String sheetName;
    switch (_fenceType) {
      case FenceType.profiled:
        sheetName = _loc.translate('fence_calc.materials.profiled_sheets');
      case FenceType.picket:
        sheetName = _loc.translate('fence_calc.materials.pickets');
      case FenceType.chain:
        sheetName = _loc.translate('fence_calc.materials.chain_rolls');
    }

    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('fence_calc.materials.posts'),
        value: '${_result.postsCount} ${_loc.translate('common.pcs')}',
        subtitle: '${_fenceHeight.toStringAsFixed(1)} + 0.8 ${_loc.translate('common.meters')}',
        icon: Icons.view_column,
      ),
      MaterialItem(
        name: _loc.translate('fence_calc.materials.lags'),
        value: '${_result.lagsLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('fence_calc.materials.lags_desc'),
        icon: Icons.straighten,
      ),
      MaterialItem(
        name: sheetName,
        value: '${_result.sheetsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate(_fenceType.nameKey),
        icon: Icons.layers,
      ),
      MaterialItem(
        name: _loc.translate('fence_calc.materials.fasteners'),
        value: '${_result.fastenersBags} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('fence_calc.materials.fasteners_desc'),
        icon: Icons.hardware,
      ),
    ];

    return MaterialsCardModern(
      title: _loc.translate('fence_calc.section.materials'),
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
