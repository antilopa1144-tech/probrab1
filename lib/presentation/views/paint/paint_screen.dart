import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/canonical_calculator_contract.dart';
import '../../../domain/usecases/calculate_paint.dart';
import '../../widgets/calculator/calculator_widgets.dart';

const _paintMaterialCategoryConsumables = 'Расходники';

/// Экран расчета краски (Интерьер/Фасад)
class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  bool _isDark = false;
  late AppLocalizations _loc;
  final CalculatePaint _calculator = CalculatePaint();

  // Геометрия
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  double _openingsArea = 4.0;

  int _inputMode = 0; // 0: площадь вручную, 1: комната
  double _manualArea = 30.0;

  // 0: Интерьер, 1: Фасад
  int _paintType = 0;

  // Индекс типа поверхности
  int _surfaceIndex = 0;

  // Подготовка поверхности: 0=загрунтованная, 1=новая необработанная, 2=ранее окрашенная
  int _surfacePrep = 0;

  // Интенсивность цвета: 0=светлый, 1=яркий, 2=тёмный
  int _colorIntensity = 0;

  // Параметры
  double _coverage = 10.0; // м²/л (по умолчанию для интерьера)
  int _layers = 2;

  // Данные типов поверхностей (геттер — использует _loc, доступен после build)
  List<List<Map<String, dynamic>>> get _surfaces => [
    [
      {'name': _loc.translate('paint.surface.smooth'), 'subtitle': 'х1.0', 'factor': 1.0},
      {'name': _loc.translate('paint.surface.wallpaper'), 'subtitle': 'х1.2', 'factor': 1.2},
      {'name': _loc.translate('paint.surface.relief'), 'subtitle': 'х1.4', 'factor': 1.4},
    ],
    [
      {'name': _loc.translate('paint.surface.concrete'), 'subtitle': 'х1.0', 'factor': 1.0},
      {'name': _loc.translate('paint.surface.brick'), 'subtitle': 'х1.15', 'factor': 1.15},
      {'name': _loc.translate('paint.surface.bark_beetle'), 'subtitle': 'х1.4', 'factor': 1.4},
    ],
  ];


  void _onPaintTypeChanged(int newType) {
    setState(() {
      _paintType = newType;
      _surfaceIndex = 0;
      _coverage = newType == 0 ? 10.0 : 7.0;
    });
  }

  int _surfaceTypeId() {
    if (_paintType == 0) {
      const interiorMapping = [0, 4, 5];
      return interiorMapping[_surfaceIndex.clamp(0, interiorMapping.length - 1)];
    }
    const facadeMapping = [6, 7, 8];
    return facadeMapping[_surfaceIndex.clamp(0, facadeMapping.length - 1)];
  }

  double get _canonicalCanSize => _paintType == 0 ? 9.0 : 10.0;

  Map<String, double> _buildCanonicalInputs() {
    final inputs = <String, double>{
      'inputMode': _inputMode == 1 ? 0.0 : 1.0,
      'paintType': _paintType.toDouble(),
      'surfaceType': _surfaceTypeId().toDouble(),
      'surfacePrep': _surfacePrep.toDouble(),
      'colorIntensity': _colorIntensity.toDouble(),
      'coats': _layers.toDouble(),
      'coverage': _coverage,
      'canSize': _canonicalCanSize,
    };

    if (_inputMode == 0) {
      inputs['area'] = _manualArea;
    } else {
      inputs['roomWidth'] = _roomWidth;
      inputs['roomLength'] = _roomLength;
      inputs['roomHeight'] = _roomHeight;
      inputs['openingsArea'] = _openingsArea;
    }

    return inputs;
  }

  CanonicalCalculatorContractResult _calculateResult() {
    return _calculator.calculateCanonical(_buildCanonicalInputs());
  }

  int _findMaterialPurchaseQty(
    CanonicalCalculatorContractResult contract, {
    required String category,
    required String fallbackNamePart,
  }) {
    for (final material in contract.materials) {
      if (material.category == category && material.name.contains(fallbackNamePart)) {
        return material.purchaseQty ?? 0;
      }
    }
    for (final material in contract.materials) {
      if (material.name.contains(fallbackNamePart)) {
        return material.purchaseQty ?? 0;
      }
    }
    return 0;
  }

  String _generateExportText() {
    final result = _calculateResult();
    final recScenario = result.scenarios['REC'];
    final netArea = result.totals['area'] ?? 0;
    final liters = recScenario?.exactNeed ?? (result.totals['recExactNeedL'] ?? 0);
    final cans = recScenario?.buyPlan.packagesCount ?? 0;
    final canSize = recScenario?.buyPlan.packageSize ?? (result.totals['canSize'] ?? _canonicalCanSize);
    final tape = _findMaterialPurchaseQty(
      result,
      category: _paintMaterialCategoryConsumables,
      fallbackNamePart: 'Малярная лента',
    );
    final surface = _surfaces[_paintType][_surfaceIndex];

    final buffer = StringBuffer();
    buffer.writeln('🎨 ${_loc.translate('paint.export.title').toUpperCase()}');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('${_loc.translate('paint.export.type')}: ${_paintType == 0 ? _loc.translate('paint.export.type_interior') : _loc.translate('paint.export.type_facade')}');
    buffer.writeln('${_loc.translate('paint.export.surface')}: ${surface['name']} (${surface['subtitle']})');
    buffer.writeln('${_loc.translate('paint.export.area')}: ${netArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}');
    buffer.writeln();

    buffer.writeln('🎨 ${_loc.translate('paint.export.materials_title').toUpperCase()}:');
    buffer.writeln('─' * 40);
    buffer.writeln('• ${_loc.translate('paint.export.paint')}: ${liters.toStringAsFixed(1)} ${_loc.translate('common.liters')} ($_layers ${_loc.translate('paint.layers_label')})');
    buffer.writeln('• ${_loc.translate('paint.export.cans')}: $cans ${_loc.translate('common.pcs')} (${_loc.translate('paint.per')} ${canSize.toStringAsFixed(0)} ${_loc.translate('common.liters')})');
    buffer.writeln('• ${_loc.translate('paint.export.tape')}: $tape ${_loc.translate('paint.packs')} (50 ${_loc.translate('common.meters')})');

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('paint.export.footer'));

    return buffer.toString();
  }

  Future<void> _shareCalculation() async {
    final text = _generateExportText();
    await SharePlus.instance.share(
      ShareParams(text: text, subject: _loc.translate('paint.share_subject')),
    );
  }

  void _copyToClipboard() {
    final text = _generateExportText();
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_loc.translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Theme.of(context).brightness == Brightness.dark;
    _loc = AppLocalizations.of(context);
    final accentColor = _paintType == 0 ? CalculatorColors.interior : CalculatorColors.facade;

    final calculation = _calculateResult();
    final recScenario = calculation.scenarios['REC'];
    final netArea = calculation.totals['area'] ?? 0;
    final surface = _surfaces[_paintType][_surfaceIndex];
    final factor = surface['factor'] as double;
    final liters = recScenario?.exactNeed ?? (calculation.totals['recExactNeedL'] ?? 0);
    final canSize = recScenario?.buyPlan.packageSize ?? (calculation.totals['canSize'] ?? _canonicalCanSize);
    final cans = recScenario?.buyPlan.packagesCount ?? 0;
    final tape = _findMaterialPurchaseQty(
      calculation,
      category: _paintMaterialCategoryConsumables,
      fallbackNamePart: 'Малярная лента',
    );
    final showWarning = _paintType == 1 && _surfaceIndex == 2;

    return CalculatorScaffold(
      title: _loc.translate('paint.title'),
      accentColor: accentColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: _copyToClipboard,
          tooltip: _loc.translate('common.copy'),
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareCalculation,
          tooltip: _loc.translate('common.share'),
        ),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('paint.area').toUpperCase(),
            value: '${netArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('paint.paint').toUpperCase(),
            value: '$cans ${_loc.translate('paint.packs')}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: '${liters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
            value: '$_layers ${_loc.translate('paint.layers_label')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loc.translate('paint.paint_type'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                ),
              ),
              const SizedBox(height: 12),
              ModeSelector(
                options: [
                  _loc.translate('paint.interior'),
                  _loc.translate('paint.facade'),
                ],
                selectedIndex: _paintType,
                onSelect: _onPaintTypeChanged,
                accentColor: accentColor,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TypeSelectorGroup(
          options: _surfaces[_paintType]
              .map(
                (s) => TypeSelectorOption(
                  icon: Icons.texture,
                  title: s['name'] as String,
                  subtitle: s['subtitle'] as String,
                ),
              )
              .toList(),
          selectedIndex: _surfaceIndex,
          onSelect: (index) => setState(() => _surfaceIndex = index),
          accentColor: accentColor,
        ),
        const SizedBox(height: 16),
        _buildSurfacePrepSelector(accentColor),
        const SizedBox(height: 16),
        _buildColorIntensitySelector(accentColor),
        const SizedBox(height: 16),
        _buildGeometryCard(accentColor),
        const SizedBox(height: 16),
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loc.translate('paint.parameters'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.getTextPrimary(_isDark),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('paint.coverage'),
                      value: _coverage,
                      onChanged: (v) => setState(() => _coverage = v),
                      suffix: _loc.translate('common.sqm_per_liter'),
                      accentColor: accentColor,
                      minValue: 4,
                      maxValue: 15,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('paint.layers'),
                      value: _layers.toDouble(),
                      onChanged: (v) => setState(() => _layers = v.toInt().clamp(1, 5)),
                      suffix: '',
                      accentColor: accentColor,
                      minValue: 1,
                      maxValue: 5,
                    ),
                  ),
                ],
              ),
              if (showWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_rounded, size: 20, color: Colors.orange[800]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loc.translate('paint.increased_warning'),
                            style: TextStyle(fontSize: 12, color: Colors.orange[900], fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        MaterialsCardModern(
          title: _loc.translate('paint.results_title'),
          titleIcon: Icons.receipt_long,
          items: [
            MaterialItem(
              name: _loc.translate('paint.area'),
              value: '${netArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
              icon: Icons.straighten,
            ),
            MaterialItem(
              name: _loc.translate('paint.paint'),
              value: '${liters.toStringAsFixed(1)} ${_loc.translate('common.liters')}',
              icon: Icons.format_paint,
              subtitle: '$_layers ${_loc.translate('paint.layers_label')}, ×$factor',
            ),
            MaterialItem(
              name: _loc.translate('paint.cans'),
              value: '$cans ${_loc.translate('paint.packs')}',
              icon: Icons.shopping_bag,
              subtitle: '${_loc.translate('paint.per')} ${canSize.toStringAsFixed(0)} ${_loc.translate('common.liters')}',
            ),
            MaterialItem(
              name: _loc.translate('paint.tape'),
              value: '$tape ${_loc.translate('paint.packs')}',
              icon: Icons.cleaning_services,
              subtitle: _loc.translate('paint.rolls_50m'),
            ),
          ],
          accentColor: accentColor,
        ),
        const SizedBox(height: 24),
        _buildTipsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSurfacePrepSelector(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('paint.surfacePrep'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('paint.surfacePrep.primed'),
              _loc.translate('paint.surfacePrep.raw'),
              _loc.translate('paint.surfacePrep.repainted'),
            ],
            selectedIndex: _surfacePrep,
            onSelect: (index) => setState(() => _surfacePrep = index),
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildColorIntensitySelector(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('paint.colorIntensity'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('paint.colorIntensity.light'),
              _loc.translate('paint.colorIntensity.bright'),
              _loc.translate('paint.colorIntensity.dark'),
            ],
            selectedIndex: _colorIntensity,
            onSelect: (index) => setState(() => _colorIntensity = index),
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGeometryCard(Color accentColor) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('common.dimensions'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.getTextPrimary(_isDark),
            ),
          ),
          const SizedBox(height: 12),
          ModeSelector(
            options: [
              _loc.translate('plaster_pro.mode.manual'),
              _loc.translate('plaster_pro.mode.room'),
            ],
            selectedIndex: _inputMode,
            onSelect: (index) => setState(() => _inputMode = index),
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          if (_inputMode == 0) ..._buildManualInputs(accentColor) else ..._buildRoomInputs(accentColor),
        ],
      ),
    );
  }

  List<Widget> _buildRoomInputs(Color accentColor) {
    return [
      Row(
        children: [
          Expanded(
            child: CalculatorTextField(
              label: _loc.translate('input.room_width'),
              value: _roomWidth,
              onChanged: (v) => setState(() => _roomWidth = v),
              suffix: _loc.translate('common.meters'),
              accentColor: accentColor,
              minValue: 0.1,
              maxValue: 100,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CalculatorTextField(
              label: _loc.translate('input.room_length'),
              value: _roomLength,
              onChanged: (v) => setState(() => _roomLength = v),
              suffix: _loc.translate('common.meters'),
              accentColor: accentColor,
              minValue: 0.1,
              maxValue: 100,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),
      CalculatorTextField(
        label: _loc.translate('input.room_height'),
        value: _roomHeight,
        onChanged: (v) => setState(() => _roomHeight = v),
        suffix: _loc.translate('common.meters'),
        accentColor: accentColor,
        minValue: 1.5,
        maxValue: 10,
      ),
      const SizedBox(height: 12),
      CalculatorTextField(
        key: const ValueKey('openings_area_field'),
        label: _loc.translate('input.paint.doors_windows'),
        value: _openingsArea,
        onChanged: (v) => setState(() => _openingsArea = v),
        suffix: _loc.translate('common.sqm'),
        accentColor: accentColor,
        minValue: 0,
        maxValue: 100,
      ),
    ];
  }

  List<Widget> _buildManualInputs(Color accentColor) {
    return [
      CalculatorTextField(
        key: const ValueKey('manual_area_field'),
        label: _loc.translate('input.paint.wall_area'),
        value: _manualArea,
        onChanged: (v) => setState(() => _manualArea = v),
        suffix: _loc.translate('common.sqm'),
        accentColor: accentColor,
        minValue: 1,
        maxValue: 500,
      ),
    ];
  }

  Widget _buildTipsCard() {
    final accentColor = _paintType == 0 ? CalculatorColors.interior : CalculatorColors.facade;
    final tips = <String>[
      _loc.translate('hint.paint.primer_first'),
      _loc.translate('hint.paint.dry_between_layers'),
      _loc.translate('hint.paint.temperature'),
    ];

    return TipsCard(
      tips: tips,
      accentColor: accentColor,
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





