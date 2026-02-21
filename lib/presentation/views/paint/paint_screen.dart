import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Экран расчета краски (Интерьер/Фасад)
class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  bool _isDark = false;
  late AppLocalizations _loc;

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

  // Подготовка поверхности: 0=загрунтованная (1.0), 1=новая необработанная (1.2), 2=ранее окрашенная (0.95)
  int _surfacePrep = 0;
  static const _surfacePrepMultipliers = [1.0, 1.2, 0.95];

  // Интенсивность цвета: 0=светлый (1.0), 1=яркий (1.15), 2=тёмный (1.3)
  int _colorIntensity = 0;
  static const _colorIntensityMultipliers = [1.0, 1.15, 1.3];

  // Параметры
  double _coverage = 10.0; // м²/л (по умолчанию для интерьера)
  int _layers = 2;

  // Данные типов поверхностей (геттер — использует _loc, доступен после build)
  List<List<Map<String, dynamic>>> get _surfaces => [
    // Интерьер
    [
      {'name': _loc.translate('paint.surface.smooth'), 'subtitle': 'х1.0', 'factor': 1.0},
      {'name': _loc.translate('paint.surface.wallpaper'), 'subtitle': 'х1.2', 'factor': 1.2},
      {'name': _loc.translate('paint.surface.relief'), 'subtitle': 'х1.4', 'factor': 1.4},
    ],
    // Фасад
    [
      {'name': _loc.translate('paint.surface.concrete'), 'subtitle': 'х1.0', 'factor': 1.0},
      {'name': _loc.translate('paint.surface.brick'), 'subtitle': 'х1.15', 'factor': 1.15},
      {'name': _loc.translate('paint.surface.bark_beetle'), 'subtitle': 'х1.4', 'factor': 1.4},
    ],
  ];

  double _getArea() {
    if (_inputMode == 0) return _manualArea;
    return (_roomWidth + _roomLength) * 2 * _roomHeight - _openingsArea;
  }

  // Обновление параметров при переключении типа краски
  void _onPaintTypeChanged(int newType) {
    setState(() {
      _paintType = newType;
      _surfaceIndex = 0;
      // Меняем стандартный расход: интерьер = 10, фасад = 7
      _coverage = newType == 0 ? 10.0 : 7.0;
    });
  }

  String _generateExportText() {
    final netArea = _getArea();
    final surface = _surfaces[_paintType][_surfaceIndex];
    final factor = surface['factor'] as double;
    final prepMul = _surfacePrepMultipliers[_surfacePrep];
    final colorMul = _colorIntensityMultipliers[_colorIntensity];
    final liters = (netArea * _layers * factor * prepMul * colorMul) / _coverage;
    final canSize = _paintType == 0 ? 9 : 10;
    final cans = (liters / canSize).ceil();
    final perimeter = (_roomWidth + _roomLength) * 2;
    final tape = ((perimeter * 2) / 50).ceil();

    final buffer = StringBuffer();
    buffer.writeln('🎨 РАСЧЁТ КРАСКИ');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('Тип: ${_paintType == 0 ? "Интерьер" : "Фасад"}');
    buffer.writeln('Поверхность: ${surface['name']} (${surface['subtitle']})');
    buffer.writeln('Площадь: ${netArea.toStringAsFixed(1)} м²');
    buffer.writeln();

    buffer.writeln('🎨 МАТЕРИАЛЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln('• Краска: ${liters.toStringAsFixed(1)} л ($_layers слоя)');
    buffer.writeln('• Банки: $cans шт (по $canSize л)');
    buffer.writeln('• Малярный скотч: $tape рул. (50м)');

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln('Создано в ПроРаб');

    return buffer.toString();
  }

  Future<void> _shareCalculation() async {
    final text = _generateExportText();
    await SharePlus.instance.share(ShareParams(text: text, subject: 'Расчёт краски'));
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
    // Цвет зависит от типа: интерьер = interior, фасад = facade
    final accentColor = _paintType == 0 ? CalculatorColors.interior : CalculatorColors.facade;

    final netArea = _getArea();
    final perimeter = (_roomWidth + _roomLength) * 2;

    final surface = _surfaces[_paintType][_surfaceIndex];
    final factor = surface['factor'] as double;

    // Расчет краски с учётом подготовки и интенсивности цвета
    final prepMultiplier = _surfacePrepMultipliers[_surfacePrep];
    final colorMultiplier = _colorIntensityMultipliers[_colorIntensity];
    final liters = (netArea * _layers * factor * prepMultiplier * colorMultiplier) / _coverage;

    // Размер банок: интерьер = 9л, фасад = 10л
    final canSize = _paintType == 0 ? 9 : 10;
    final cans = (liters / canSize).ceil();

    // Малярный скотч: периметр х 2 (обвод плинтуса и потолка) / 50м рулон
    final tape = ((perimeter * 2) / 50).ceil();

    // Предупреждение для короеда на фасаде
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
            value: '${netArea.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('paint.paint').toUpperCase(),
            value: '$cans ${_loc.translate('paint.packs')}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: '${liters.toStringAsFixed(1)} л',
            value: '$_layers ${_loc.translate('paint.layers_label')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        // Тип краски (Интерьер/Фасад)
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

        // Выбор поверхности
        TypeSelectorGroup(
          options: _surfaces[_paintType].map((s) => TypeSelectorOption(
            icon: Icons.texture,
            title: s['name'] as String,
            subtitle: s['subtitle'] as String,
          )).toList(),
          selectedIndex: _surfaceIndex,
          onSelect: (index) => setState(() => _surfaceIndex = index),
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        // Подготовка поверхности
        _buildSurfacePrepSelector(accentColor),

        const SizedBox(height: 16),

        // Интенсивность цвета
        _buildColorIntensitySelector(accentColor),

        const SizedBox(height: 16),

        // Геометрия
        _buildGeometryCard(accentColor),

        const SizedBox(height: 16),

        // Параметры (Расход и Слои)
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
                      suffix: 'м²/л',
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
              // Предупреждение для Короеда
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

        // Результаты
        MaterialsCardModern(
          title: _loc.translate('paint.results_title'),
          titleIcon: Icons.receipt_long,
          items: [
            MaterialItem(
              name: _loc.translate('paint.area'),
              value: '${netArea.toStringAsFixed(1)} м²',
              icon: Icons.straighten,
            ),
            MaterialItem(
              name: _loc.translate('paint.paint'),
              value: '${liters.toStringAsFixed(1)} л',
              icon: Icons.format_paint,
              subtitle: '$_layers ${_loc.translate('paint.layers_label')}, ${factor}x',
            ),
            MaterialItem(
              name: _loc.translate('paint.cans'),
              value: '$cans ${_loc.translate('paint.packs')}',
              icon: Icons.shopping_bag,
              subtitle: '${_loc.translate('paint.per')} $canSize л',
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

        // Подсказки
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
              suffix: 'м',
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
              suffix: 'м',
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
        suffix: 'м',
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
        suffix: 'м²',
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
        suffix: 'м²',
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
