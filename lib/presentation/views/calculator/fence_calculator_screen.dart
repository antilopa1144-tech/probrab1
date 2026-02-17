import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/usecases/calculate_fence_v2.dart';
import '../../mixins/exportable_consumer_mixin.dart';
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

  factory _FenceResult.fromCalculatorResult(Map<String, double> values) {
    return _FenceResult(
      fenceLength: values['fenceLength'] ?? 0,
      fenceArea: values['fenceArea'] ?? 0,
      postsCount: (values['postsCount'] ?? 0).toInt(),
      lagsLength: values['lagsLength'] ?? 0,
      sheetsCount: (values['sheetsCount'] ?? 0).toInt(),
      fastenersBags: (values['fastenersBags'] ?? 0).toInt(),
    );
  }
}

class FenceCalculatorScreen extends ConsumerStatefulWidget {
  const FenceCalculatorScreen({super.key});

  @override
  ConsumerState<FenceCalculatorScreen> createState() => _FenceCalculatorScreenState();
}

class _FenceCalculatorScreenState extends ConsumerState<FenceCalculatorScreen>
    with ExportableConsumerMixin {
  // ExportableConsumerMixin
  @override
  AppLocalizations get loc => _loc;

  @override
  String get exportSubject => _loc.translate('fence_calc.title');

  // Domain layer calculator
  final _calculator = CalculateFenceV2();

  double _fenceLength = 50.0;
  double _fenceHeight = 2.0;
  double _postSpacing = 2.5;

  FenceType _fenceType = FenceType.profiled;

  late _FenceResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  /// Использует domain layer для расчёта
  _FenceResult _calculate() {
    final inputs = <String, double>{
      'fenceLength': _fenceLength,
      'fenceHeight': _fenceHeight,
      'postSpacing': _postSpacing,
      'fenceType': _fenceType.index.toDouble(),
    };

    final result = _calculator(inputs, []);
    return _FenceResult.fromCalculatorResult(result.values);
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
    _isDark = Theme.of(context).brightness == Brightness.dark;

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
        const SizedBox(height: 16),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTipsCard() {
    final tips = <String>[];
    switch (_fenceType) {
      case FenceType.profiled:
        tips.add(_loc.translate('fence_calc.tip.profiled_1'));
        tips.add(_loc.translate('fence_calc.tip.profiled_2'));
      case FenceType.picket:
        tips.add(_loc.translate('fence_calc.tip.picket_1'));
        tips.add(_loc.translate('fence_calc.tip.picket_2'));
      case FenceType.chain:
        tips.add(_loc.translate('fence_calc.tip.chain_1'));
        tips.add(_loc.translate('fence_calc.tip.chain_2'));
    }
    tips.add(_loc.translate('fence_calc.tip.common'));
    return TipsCard(
      tips: tips,
      accentColor: _accentColor,
      title: _loc.translate('common.tips'),
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
          CalculatorSliderField(
            label: _loc.translate('fence_calc.label.length'),
            value: _fenceLength,
            min: 10,
            max: 500,
            suffix: _loc.translate('common.meters'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _fenceLength = v; _update(); }); },
            decimalPlaces: 0,
          ),
          const SizedBox(height: 12),
          CalculatorSliderField(
            label: _loc.translate('fence_calc.label.height'),
            value: _fenceHeight,
            min: 1.0,
            max: 3.0,
            divisions: 8,
            suffix: _loc.translate('common.meters'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _fenceHeight = v; _update(); }); },
            decimalPlaces: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingCard() {
    return _card(
      child: Column(
        children: [
          CalculatorSliderField(
            label: _loc.translate('fence_calc.label.post_spacing'),
            value: _postSpacing,
            min: 2.0,
            max: 3.5,
            divisions: 6,
            suffix: _loc.translate('common.meters'),
            accentColor: _accentColor,
            onChanged: (v) { setState(() { _postSpacing = v; _update(); }); },
            decimalPlaces: 1,
          ),
          Text(
            _loc.translate('fence_calc.spacing_hint'),
            style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.getTextPrimary(_isDark), fontWeight: FontWeight.w500),
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
