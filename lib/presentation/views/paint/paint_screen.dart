import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

/// Экран расчета краски (Интерьер/Фасад) по образцу HTML-калькулятора
class PaintScreen extends StatefulWidget {
  const PaintScreen({super.key});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  late AppLocalizations _loc;

  // Геометрия
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  double _openingsArea = 4.0;

  int _inputMode = 0; // 0: комната, 1: площадь вручную
  double _manualArea = 30.0;

  // 0: Интерьер, 1: Фасад
  int paintType = 0;

  // Индекс типа поверхности
  int surfaceIndex = 0;

  // Параметры
  double coverage = 10.0; // м²/л (по умолчанию для интерьера)
  int layers = 2;

  // Данные типов поверхностей
  final List<List<Map<String, dynamic>>> surfaces = [
    // Интерьер
    [
      {'name': 'Гладкая (х1.0)', 'factor': 1.0},
      {'name': 'Обои (х1.2)', 'factor': 1.2},
      {'name': 'Фактурная (х1.4)', 'factor': 1.4},
    ],
    // Фасад
    [
      {'name': 'Бетон (х1.0)', 'factor': 1.0},
      {'name': 'Кирпич (х1.15)', 'factor': 1.15},
      {'name': 'Короед (х1.4)', 'factor': 1.4},
    ],
  ];

  double _getArea() {
    if (_inputMode == 1) return _manualArea;
    return (_roomWidth + _roomLength) * 2 * _roomHeight - _openingsArea;
  }

  // Обновление параметров при переключении типа краски
  void _onPaintTypeChanged(int newType) {
    setState(() {
      paintType = newType;
      surfaceIndex = 0;
      // Меняем стандартный расход: интерьер = 10, фасад = 7
      coverage = newType == 0 ? 10.0 : 7.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    final netArea = _getArea();
    final perimeter = (_roomWidth + _roomLength) * 2;

    final surface = surfaces[paintType][surfaceIndex];
    final factor = surface['factor'] as double;

    // Расчет краски
    final liters = (netArea * layers * factor) / coverage;

    // Размер банок: интерьер = 9л, фасад = 10л
    final canSize = paintType == 0 ? 9 : 10;
    final cans = (liters / canSize).ceil();

    // Малярный скотч: периметр х 2 (обвод плинтуса и потолка) / 50м рулон
    final tape = ((perimeter * 2) / 50).ceil();

    // Предупреждение для короеда на фасаде
    final showWarning = paintType == 1 && surfaceIndex == 2;

    return CalculatorScaffold(
      title: _loc.translate('paint.title'),
      accentColor: accentColor,
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
            value: '$layers ${_loc.translate('paint.layers_label')}',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        // Геометрия
        _buildGeometryCard(),

        const SizedBox(height: 16),

        // Тип краски (Интерьер/Фасад)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loc.translate('paint.paint_type'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ModeSelector(
                options: [
                  _loc.translate('paint.interior'),
                  _loc.translate('paint.facade'),
                ],
                selectedIndex: paintType,
                onSelect: _onPaintTypeChanged,
                accentColor: accentColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Выбор поверхности
        TypeSelectorGroup(
          options: surfaces[paintType].map((s) => TypeSelectorOption(
            icon: Icons.texture,
            title: s['name'] as String,
            subtitle: '',
          )).toList(),
          selectedIndex: surfaceIndex,
          onSelect: (index) => setState(() => surfaceIndex = index),
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        // Параметры (Расход и Слои)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('paint.coverage'),
                      value: coverage,
                      onChanged: (v) => setState(() => coverage = v),
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
                      value: layers.toDouble(),
                      onChanged: (v) => setState(() => layers = v.toInt().clamp(1, 5)),
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
        ResultCardLight(
          title: _loc.translate('paint.results_title'),
          titleIcon: Icons.receipt_long,
          results: [
            ResultRowItem(
              label: _loc.translate('paint.area'),
              value: '${netArea.toStringAsFixed(1)} м²',
              icon: Icons.straighten,
            ),
            ResultRowItem(
              label: _loc.translate('paint.paint'),
              value: '${liters.toStringAsFixed(1)} л',
              icon: Icons.format_paint,
              subtitle: '$layers ${_loc.translate('paint.layers_label')}, ${factor}x',
            ),
            ResultRowItem(
              label: _loc.translate('paint.cans'),
              value: '$cans ${_loc.translate('paint.packs')}',
              icon: Icons.shopping_bag,
              subtitle: '${_loc.translate('paint.per')} $canSize л',
            ),
            ResultRowItem(
              label: _loc.translate('paint.tape'),
              value: '$tape ${_loc.translate('paint.packs')}',
              icon: Icons.cleaning_services,
              subtitle: _loc.translate('paint.rolls_50m'),
            ),
          ],
          accentColor: accentColor,
        ),

        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildGeometryCard() {
    const accentColor = CalculatorColors.interior;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ModeSelector(
            options: [
              _loc.translate('plaster_pro.mode.room'),
              _loc.translate('plaster_pro.mode.manual'),
            ],
            selectedIndex: _inputMode,
            onSelect: (index) => setState(() => _inputMode = index),
            accentColor: accentColor,
          ),
          const SizedBox(height: 16),
          if (_inputMode == 0) ..._buildRoomInputs() else ..._buildManualInputs(),
        ],
      ),
    );
  }

  List<Widget> _buildRoomInputs() {
    const accentColor = CalculatorColors.interior;
    return [
      Row(
        children: [
          Expanded(
            child: CalculatorTextField(
              label: _loc.translate('plaster_pro.label.width'),
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
              label: _loc.translate('plaster_pro.label.length'),
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
        label: _loc.translate('plaster_pro.label.height'),
        value: _roomHeight,
        onChanged: (v) => setState(() => _roomHeight = v),
        suffix: 'м',
        accentColor: accentColor,
        minValue: 1.5,
        maxValue: 10,
      ),
      const SizedBox(height: 12),
      CalculatorTextField(
        label: _loc.translate('plaster_pro.label.openings_hint'),
        value: _openingsArea,
        onChanged: (v) => setState(() => _openingsArea = v),
        suffix: 'м²',
        accentColor: accentColor,
        minValue: 0,
        maxValue: 100,
      ),
    ];
  }

  List<Widget> _buildManualInputs() {
    const accentColor = CalculatorColors.interior;
    return [
      CalculatorTextField(
        label: _loc.translate('plaster_pro.label.wall_area'),
        value: _manualArea,
        onChanged: (v) => setState(() => _manualArea = v),
        suffix: 'м²',
        accentColor: accentColor,
        minValue: 1,
        maxValue: 500,
      ),
    ];
  }
}
