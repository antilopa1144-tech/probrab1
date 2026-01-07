import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Тип окна
enum WindowType {
  single('windows_calc.type.single', 'windows_calc.type.single_desc', Icons.crop_portrait),
  double_('windows_calc.type.double', 'windows_calc.type.double_desc', Icons.view_column),
  triple('windows_calc.type.triple', 'windows_calc.type.triple_desc', Icons.view_week);

  final String nameKey;
  final String descKey;
  final IconData icon;
  const WindowType(this.nameKey, this.descKey, this.icon);
}

class _WindowsResult {
  final int windowsCount;
  final double totalArea;
  final double foamCans;
  final double sillLength;
  final double sealantTubes;
  final int anchorsCount;

  const _WindowsResult({
    required this.windowsCount,
    required this.totalArea,
    required this.foamCans,
    required this.sillLength,
    required this.sealantTubes,
    required this.anchorsCount,
  });
}

class WindowsInstallCalculatorScreen extends StatefulWidget {
  const WindowsInstallCalculatorScreen({super.key});

  @override
  State<WindowsInstallCalculatorScreen> createState() => _WindowsInstallCalculatorScreenState();
}

class _WindowsInstallCalculatorScreenState extends State<WindowsInstallCalculatorScreen> {
  int _windowsCount = 5;
  double _windowWidth = 1.4;
  double _windowHeight = 1.5;

  WindowType _windowType = WindowType.double_;
  bool _needSill = true;
  bool _needSlopes = true;

  late _WindowsResult _result;
  late AppLocalizations _loc;

  static const _accentColor = CalculatorColors.interior;

  @override
  void initState() {
    super.initState();
    _result = _calculate();
  }

  _WindowsResult _calculate() {
    final windowsCount = _windowsCount;
    final totalArea = _windowWidth * _windowHeight * windowsCount;

    // Пена: зависит от размера окна и периметра
    final perimeter = 2 * (_windowWidth + _windowHeight);
    final foamCans = (perimeter * windowsCount / 10).ceil().toDouble(); // ~10 п.м. на баллон

    // Подоконник: ширина окна + выступы
    final sillLength = _needSill ? (_windowWidth + 0.1) * windowsCount : 0.0;

    // Герметик: 1 туба на 3-4 п.м.
    final sealantTubes = (perimeter * windowsCount / 4).ceil().toDouble();

    // Анкеры: 6-8 на окно в зависимости от размера
    final anchorsPerWindow = _windowHeight > 1.5 ? 8 : 6;
    final anchorsCount = anchorsPerWindow * windowsCount;

    return _WindowsResult(
      windowsCount: windowsCount,
      totalArea: totalArea,
      foamCans: foamCans,
      sillLength: sillLength,
      sealantTubes: sealantTubes,
      anchorsCount: anchorsCount,
    );
  }

  void _update() => setState(() => _result = _calculate());

  String _generateExportText() {
    final buffer = StringBuffer();
    buffer.writeln(_loc.translate('windows_calc.export.title'));
    buffer.writeln('═' * 40);
    buffer.writeln();
    buffer.writeln(_loc.translate('windows_calc.export.windows_count')
        .replaceFirst('{value}', _result.windowsCount.toString()));
    buffer.writeln(_loc.translate('windows_calc.export.total_area')
        .replaceFirst('{value}', _result.totalArea.toStringAsFixed(1)));
    buffer.writeln(_loc.translate('windows_calc.export.type')
        .replaceFirst('{value}', _loc.translate(_windowType.nameKey)));
    buffer.writeln();
    buffer.writeln(_loc.translate('windows_calc.export.materials_title'));
    buffer.writeln('─' * 40);
    buffer.writeln(_loc.translate('windows_calc.export.foam')
        .replaceFirst('{value}', _result.foamCans.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('windows_calc.export.sealant')
        .replaceFirst('{value}', _result.sealantTubes.toStringAsFixed(0)));
    buffer.writeln(_loc.translate('windows_calc.export.anchors')
        .replaceFirst('{value}', _result.anchorsCount.toString()));
    if (_needSill) {
      buffer.writeln(_loc.translate('windows_calc.export.sill')
          .replaceFirst('{value}', _result.sillLength.toStringAsFixed(1)));
    }
    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln(_loc.translate('windows_calc.export.footer'));
    return buffer.toString();
  }

  void _shareCalculation() {
    final text = _generateExportText();
    SharePlus.instance.share(ShareParams(text: text, subject: _loc.translate('windows_calc.title')));
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
      title: _loc.translate('windows_calc.title'),
      accentColor: _accentColor,
      actions: [
        IconButton(icon: const Icon(Icons.copy), onPressed: _copyToClipboard, tooltip: _loc.translate('common.copy')),
        IconButton(icon: const Icon(Icons.share), onPressed: _shareCalculation, tooltip: _loc.translate('common.share')),
      ],
      resultHeader: CalculatorResultHeader(
        accentColor: _accentColor,
        results: [
          ResultItem(
            label: _loc.translate('windows_calc.result.windows').toUpperCase(),
            value: '${_result.windowsCount} ${_loc.translate('common.pcs')}',
            icon: Icons.window,
          ),
          ResultItem(
            label: _loc.translate('windows_calc.result.area').toUpperCase(),
            value: '${_result.totalArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('windows_calc.result.foam').toUpperCase(),
            value: '${_result.foamCans.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
            icon: Icons.blur_on,
          ),
        ],
      ),
      children: [
        _buildTypeSelector(),
        const SizedBox(height: 16),
        _buildCountCard(),
        const SizedBox(height: 16),
        _buildDimensionsCard(),
        const SizedBox(height: 16),
        _buildOptionsCard(),
        const SizedBox(height: 16),
        _buildMaterialsCard(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return TypeSelectorGroup(
      options: WindowType.values.map((type) => TypeSelectorOption(
        icon: type.icon,
        title: _loc.translate(type.nameKey),
        subtitle: _loc.translate(type.descKey),
      )).toList(),
      selectedIndex: _windowType.index,
      onSelect: (index) {
        setState(() {
          _windowType = WindowType.values[index];
          _update();
        });
      },
      accentColor: _accentColor,
    );
  }

  Widget _buildCountCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('windows_calc.label.windows_count'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
              Text('$_windowsCount ${_loc.translate('common.pcs')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _windowsCount.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _windowsCount = v.toInt(); _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildDimensionsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _loc.translate('windows_calc.label.window_size'),
            style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CalculatorTextField(label: _loc.translate('windows_calc.label.width'), value: _windowWidth * 100, onChanged: (v) { setState(() { _windowWidth = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 40, maxValue: 300)),
              const SizedBox(width: 12),
              Expanded(child: CalculatorTextField(label: _loc.translate('windows_calc.label.height'), value: _windowHeight * 100, onChanged: (v) { setState(() { _windowHeight = v / 100; _update(); }); }, suffix: _loc.translate('common.cm'), accentColor: _accentColor, minValue: 40, maxValue: 250)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: _accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_loc.translate('windows_calc.label.total_area'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textSecondary)),
                Text('${_result.totalArea.toStringAsFixed(1)} ${_loc.translate('common.sqm')}', style: CalculatorDesignSystem.headlineMedium.copyWith(color: _accentColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsCard() {
    return _card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('windows_calc.option.sill'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('windows_calc.option.sill_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needSill,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needSill = v; _update(); }); },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_loc.translate('windows_calc.option.slopes'), style: CalculatorDesignSystem.bodyMedium.copyWith(color: CalculatorColors.textPrimary)),
            subtitle: Text(_loc.translate('windows_calc.option.slopes_desc'), style: CalculatorDesignSystem.bodySmall.copyWith(color: CalculatorColors.textSecondary)),
            value: _needSlopes,
            activeColor: _accentColor,
            onChanged: (v) { setState(() { _needSlopes = v; _update(); }); },
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsCard() {
    final items = <MaterialItem>[
      MaterialItem(
        name: _loc.translate('windows_calc.materials.windows'),
        value: '${_result.windowsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate(_windowType.nameKey),
        icon: Icons.window,
      ),
      MaterialItem(
        name: _loc.translate('windows_calc.materials.foam'),
        value: '${_result.foamCans.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('windows_calc.materials.foam_desc'),
        icon: Icons.blur_on,
      ),
      MaterialItem(
        name: _loc.translate('windows_calc.materials.sealant'),
        value: '${_result.sealantTubes.toStringAsFixed(0)} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('windows_calc.materials.sealant_desc'),
        icon: Icons.water_drop,
      ),
      MaterialItem(
        name: _loc.translate('windows_calc.materials.anchors'),
        value: '${_result.anchorsCount} ${_loc.translate('common.pcs')}',
        subtitle: _loc.translate('windows_calc.materials.anchors_desc'),
        icon: Icons.hardware,
      ),
    ];

    if (_needSill && _result.sillLength > 0) {
      items.add(MaterialItem(
        name: _loc.translate('windows_calc.materials.sill'),
        value: '${_result.sillLength.toStringAsFixed(1)} ${_loc.translate('common.meters')}',
        subtitle: _loc.translate('windows_calc.materials.sill_desc'),
        icon: Icons.border_bottom,
      ));
    }

    return MaterialsCardModern(
      title: _loc.translate('windows_calc.section.materials'),
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
