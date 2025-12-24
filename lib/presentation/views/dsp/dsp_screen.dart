import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../widgets/calculator/calculator_widgets.dart';

class DspScreen extends StatefulWidget {
  const DspScreen({super.key});

  @override
  State<DspScreen> createState() => _DspScreenState();
}

class _DspScreenState extends State<DspScreen> {
  late AppLocalizations _loc;

  // Геометрия
  double _roomWidth = 4.0;
  double _roomLength = 5.0;
  double _roomHeight = 2.7;
  double _openingsArea = 4.0;

  int _inputMode = 0; // 0: комната, 1: площадь вручную
  double _manualArea = 30.0;

  // 0: Пол (Стяжка), 1: Стены (Штукатурка)
  int applicationIndex = 0;

  // 0: М300 (Пескобетон), 1: М150 (Универсальная)
  int mixIndex = 0;

  double thickness = 40.0; // мм (стандарт для стяжки)
  double bagWeight = 40.0; // Пескобетон часто идет по 40кг или 50кг

  // Данные смесей
  final List<Map<String, dynamic>> mixes = [
    {
      'name': 'М300 (Пескобетон)',
      'desc': 'Крупная фракция. Для прочной стяжки пола.',
      'consumption': 2.0, // кг/м²/1мм (Около 20-22 кг на 1см)
    },
    {
      'name': 'М150 (Универсальная)',
      'desc': 'Мелкая фракция. Для штукатурки и кладки.',
      'consumption': 1.8, // кг/м²/1мм (Около 18 кг на 1см)
    },
  ];

  double _getArea() {
    if (_inputMode == 1) return _manualArea;
    if (applicationIndex == 0) {
      // Пол - площадь пола
      return _roomWidth * _roomLength;
    } else {
      // Стены - площадь стен за вычетом проемов
      return (_roomWidth + _roomLength) * 2 * _roomHeight - _openingsArea;
    }
  }

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    const accentColor = CalculatorColors.interior;

    final area = _getArea();
    final mix = mixes[mixIndex];
    final double consumptionPerMm = mix['consumption'];
    final double totalWeightKg = area * thickness * consumptionPerMm;
    final int bags = (totalWeightKg / bagWeight).ceil();
    final double totalWeightTons = totalWeightKg / 1000;

    // Доп. материалы (Армирование и Лента)
    // Сетка: только для пола, с запасом 10% на нахлест
    final double meshArea = applicationIndex == 0 ? area * 1.1 : 0;
    // Лента: периметр комнаты
    final double tapeMeters = applicationIndex == 0 ? (_roomWidth + _roomLength) * 2 : 0;

    // Валидация (Предупреждение)
    // Стяжка тоньше 30мм из ЦПС часто трескается без спец добавок
    final bool thicknessWarning = applicationIndex == 0 && thickness < 30;

    return CalculatorScaffold(
      title: _loc.translate('dsp.title'),
      accentColor: accentColor,
      resultHeader: CalculatorResultHeader(
        accentColor: accentColor,
        results: [
          ResultItem(
            label: _loc.translate('dsp.area').toUpperCase(),
            value: '${area.toStringAsFixed(1)} м²',
            icon: Icons.straighten,
          ),
          ResultItem(
            label: _loc.translate('dsp.dry_mix').toUpperCase(),
            value: '$bags ${_loc.translate('dsp.packs')}',
            icon: Icons.shopping_bag,
          ),
          ResultItem(
            label: '${totalWeightTons.toStringAsFixed(2)} ${_loc.translate('dsp.tons')}',
            value: '${thickness.toInt()} мм',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        // Выбор типа работ (Пол/Стены)
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
                _loc.translate('dsp.work_type'),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ModeSelector(
                options: [
                  _loc.translate('dsp.screed_floor'),
                  _loc.translate('dsp.plaster_walls'),
                ],
                selectedIndex: applicationIndex,
                onSelect: (i) => setState(() {
                  applicationIndex = i;
                  // Умное переключение: Пол -> М300 (40мм), Стены -> М150 (20мм)
                  mixIndex = i == 0 ? 0 : 1;
                  thickness = i == 0 ? 40.0 : 20.0;
                }),
                accentColor: accentColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Геометрия
        _buildGeometryCard(),

        // Подсказка для пола в режиме стен
        if (applicationIndex == 0 && _inputMode == 0)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _loc.translate('dsp.floor_dimensions_hint'),
                      style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Выбор смеси
        TypeSelectorGroup(
          options: mixes.map((m) => TypeSelectorOption(
            icon: Icons.grain,
            title: m['name'] as String,
            subtitle: m['desc'] as String,
          )).toList(),
          selectedIndex: mixIndex,
          onSelect: (index) => setState(() => mixIndex = index),
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        // Параметры (Толщина и Вес мешка)
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
                      label: 'Слой (мм)',
                      value: thickness,
                      onChanged: (v) => setState(() => thickness = v),
                      suffix: 'мм',
                      accentColor: accentColor,
                      minValue: 10,
                      maxValue: 150,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CalculatorTextField(
                      label: 'Мешок (кг)',
                      value: bagWeight,
                      onChanged: (v) => setState(() => bagWeight = v),
                      suffix: 'кг',
                      accentColor: accentColor,
                      minValue: 25,
                      maxValue: 50,
                    ),
                  ),
                ],
              ),
              // Предупреждение о толщине
              if (thicknessWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loc.translate('dsp.thickness_warning'),
                            style: TextStyle(fontSize: 11, color: Colors.red[900], fontWeight: FontWeight.bold),
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
          title: _loc.translate('dsp.results_title'),
          titleIcon: Icons.receipt_long,
          results: [
            ResultRowItem(
              label: _loc.translate('dsp.area'),
              value: '${area.toStringAsFixed(1)} м²',
              icon: Icons.straighten,
            ),
            ResultRowItem(
              label: _loc.translate('dsp.dry_mix'),
              value: '${totalWeightKg.toInt()} ${_loc.translate('dsp.kg')} (${bags}x${bagWeight.toInt()})',
              icon: Icons.shopping_bag,
              subtitle: '${totalWeightTons.toStringAsFixed(2)} ${_loc.translate('dsp.tons')}',
            ),
            if (applicationIndex == 0) ...[
              ResultRowItem(
                label: _loc.translate('dsp.mesh'),
                value: '${meshArea.ceil()} м²',
                icon: Icons.grid_on,
                subtitle: _loc.translate('dsp.mesh_size'),
              ),
              ResultRowItem(
                label: _loc.translate('dsp.damper_tape'),
                value: '${tapeMeters.toStringAsFixed(1)} м',
                icon: Icons.linear_scale,
                subtitle: _loc.translate('dsp.perimeter'),
              ),
              ResultRowItem(
                label: _loc.translate('dsp.beacons'),
                value: '${(area / 1.5).ceil()} ${_loc.translate('dsp.packs')}',
                icon: Icons.architecture,
                subtitle: _loc.translate('dsp.beacon_step'),
              ),
            ],
            if (applicationIndex == 1)
              ResultRowItem(
                label: _loc.translate('dsp.primer'),
                value: '${(area * 0.2 / 10).ceil()} ${_loc.translate('dsp.packs')}',
                icon: Icons.water_drop,
                subtitle: _loc.translate('dsp.canisters_10l'),
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
      if (applicationIndex == 1) ...[
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
      ],
    ];
  }

  List<Widget> _buildManualInputs() {
    const accentColor = CalculatorColors.interior;
    return [
      CalculatorTextField(
        label: applicationIndex == 0
            ? _loc.translate('dsp.floor_area')
            : _loc.translate('plaster_pro.label.wall_area'),
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
