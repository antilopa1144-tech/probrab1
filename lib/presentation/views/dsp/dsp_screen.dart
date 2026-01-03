import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/models/calculator_hint.dart';
import '../../widgets/calculator/calculator_widgets.dart';
import '../../widgets/existing/hint_card.dart';

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
  int _applicationIndex = 0;

  // 0: М300 (Пескобетон), 1: М150 (Универсальная)
  int _mixIndex = 0;

  double _thickness = 40.0; // мм (стандарт для стяжки)
  double _bagWeight = 40.0; // Пескобетон часто идет по 40кг или 50кг

  // Данные смесей
  final List<Map<String, dynamic>> _mixes = [
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
    if (_applicationIndex == 0) {
      // Пол - площадь пола
      return _roomWidth * _roomLength;
    } else {
      // Стены - площадь стен за вычетом проемов
      return (_roomWidth + _roomLength) * 2 * _roomHeight - _openingsArea;
    }
  }

  String _generateExportText() {
    final area = _getArea();
    final mix = _mixes[_mixIndex];
    final double consumptionPerMm = mix['consumption'];
    final double totalWeightKg = area * _thickness * consumptionPerMm;
    final int bags = (totalWeightKg / _bagWeight).ceil();
    final double totalWeightTons = totalWeightKg / 1000;
    final double meshArea = _applicationIndex == 0 ? area * 1.1 : 0;
    final double tapeMeters = _applicationIndex == 0 ? (_roomWidth + _roomLength) * 2 : 0;

    final buffer = StringBuffer();
    buffer.writeln('🧱 РАСЧЁТ ЦПС (${_applicationIndex == 0 ? "Стяжка" : "Штукатурка"})');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('Смесь: ${mix['name']}');
    buffer.writeln('Площадь: ${area.toStringAsFixed(1)} м²');
    buffer.writeln('Толщина: ${_thickness.toInt()} мм');
    buffer.writeln();

    buffer.writeln('🧱 МАТЕРИАЛЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln('• Сухая смесь: ${totalWeightKg.toInt()} кг ($bags мешков по ${_bagWeight.toInt()} кг)');
    buffer.writeln('• Вес: ${totalWeightTons.toStringAsFixed(2)} т');

    if (_applicationIndex == 0) {
      buffer.writeln('• Сетка армирующая: ${meshArea.ceil()} м²');
      buffer.writeln('• Демпферная лента: ${tapeMeters.toStringAsFixed(1)} м');
      buffer.writeln('• Маяки: ${(area / 1.5).ceil()} шт');
    } else {
      buffer.writeln('• Грунтовка: ${(area * 0.2 / 10).ceil()} канистр (10л)');
    }

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln('Создано в ПроРаб');

    return buffer.toString();
  }

  Future<void> _shareCalculation() async {
    final text = _generateExportText();
    await SharePlus.instance.share(ShareParams(text: text, subject: 'Расчёт ЦПС'));
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
    _loc = AppLocalizations.of(context);
    // Пол = flooring, Стены = walls
    final accentColor = _applicationIndex == 0 ? CalculatorColors.flooring : CalculatorColors.walls;

    final area = _getArea();
    final mix = _mixes[_mixIndex];
    final double consumptionPerMm = mix['consumption'];
    final double totalWeightKg = area * _thickness * consumptionPerMm;
    final int bags = (totalWeightKg / _bagWeight).ceil();
    final double totalWeightTons = totalWeightKg / 1000;

    // Доп. материалы (Армирование и Лента)
    final double meshArea = _applicationIndex == 0 ? area * 1.1 : 0;
    final double tapeMeters = _applicationIndex == 0 ? (_roomWidth + _roomLength) * 2 : 0;

    // Валидация
    final bool thicknessWarning = _applicationIndex == 0 && _thickness < 30;

    return CalculatorScaffold(
      title: _loc.translate('dsp.title'),
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
            value: '${_thickness.toInt()} мм',
            icon: Icons.layers,
          ),
        ],
      ),
      children: [
        // Выбор типа работ (Пол/Стены)
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loc.translate('dsp.work_type'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ModeSelector(
                options: [
                  _loc.translate('dsp.screed_floor'),
                  _loc.translate('dsp.plaster_walls'),
                ],
                selectedIndex: _applicationIndex,
                onSelect: (i) => setState(() {
                  _applicationIndex = i;
                  _mixIndex = i == 0 ? 0 : 1;
                  _thickness = i == 0 ? 40.0 : 20.0;
                }),
                accentColor: accentColor,
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Выбор смеси
        TypeSelectorGroup(
          options: _mixes.map((m) => TypeSelectorOption(
            icon: Icons.grain,
            title: m['name'] as String,
            subtitle: m['desc'] as String,
          )).toList(),
          selectedIndex: _mixIndex,
          onSelect: (index) => setState(() => _mixIndex = index),
          accentColor: accentColor,
        ),

        const SizedBox(height: 16),

        // Геометрия
        _buildGeometryCard(accentColor),

        // Подсказка для пола
        if (_applicationIndex == 0 && _inputMode == 0)
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

        // Параметры (Толщина и Вес мешка)
        _card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _loc.translate('dsp.parameters'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('dsp.layer_thickness'),
                      value: _thickness,
                      onChanged: (v) => setState(() => _thickness = v),
                      suffix: 'мм',
                      accentColor: accentColor,
                      minValue: 10,
                      maxValue: 150,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('dsp.bag_weight'),
                      value: _bagWeight,
                      onChanged: (v) => setState(() => _bagWeight = v),
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
        MaterialsCardModern(
          title: _loc.translate('dsp.results_title'),
          titleIcon: Icons.receipt_long,
          items: [
            MaterialItem(
              name: _loc.translate('dsp.area'),
              value: '${area.toStringAsFixed(1)} м²',
              icon: Icons.straighten,
            ),
            MaterialItem(
              name: _loc.translate('dsp.dry_mix'),
              value: '${totalWeightKg.toInt()} ${_loc.translate('dsp.kg')}',
              icon: Icons.shopping_bag,
              subtitle: '${bags}x${_bagWeight.toInt()} кг = ${totalWeightTons.toStringAsFixed(2)} ${_loc.translate('dsp.tons')}',
            ),
            if (_applicationIndex == 0) ...[
              MaterialItem(
                name: _loc.translate('dsp.mesh'),
                value: '${meshArea.ceil()} м²',
                icon: Icons.grid_on,
                subtitle: _loc.translate('dsp.mesh_size'),
              ),
              MaterialItem(
                name: _loc.translate('dsp.damper_tape'),
                value: '${tapeMeters.toStringAsFixed(1)} м',
                icon: Icons.linear_scale,
                subtitle: _loc.translate('dsp.perimeter'),
              ),
              MaterialItem(
                name: _loc.translate('dsp.beacons'),
                value: '${(area / 1.5).ceil()} ${_loc.translate('dsp.packs')}',
                icon: Icons.architecture,
                subtitle: _loc.translate('dsp.beacon_step'),
              ),
            ],
            if (_applicationIndex == 1)
              MaterialItem(
                name: _loc.translate('dsp.primer'),
                value: '${(area * 0.2 / 10).ceil()} ${_loc.translate('dsp.packs')}',
                icon: Icons.water_drop,
                subtitle: _loc.translate('dsp.canisters_10l'),
              ),
          ],
          accentColor: accentColor,
        ),

        const SizedBox(height: 24),

        // Подсказки
        _buildTipsSection(),

        const SizedBox(height: 20),
      ],
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
              color: CalculatorColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
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
          if (_inputMode == 0) ..._buildRoomInputs(accentColor) else ..._buildManualInputs(accentColor),
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
      if (_applicationIndex == 1) ...[
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

  List<Widget> _buildManualInputs(Color accentColor) {
    return [
      CalculatorTextField(
        label: _applicationIndex == 0
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

  Widget _buildTipsSection() {
    const hints = [
      CalculatorHint(
        type: HintType.important,
        messageKey: 'hint.dsp.min_thickness',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.dsp.reinforcement',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.dsp.damper_tape',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _loc.translate('common.tips'),
            style: CalculatorDesignSystem.titleMedium.copyWith(
              color: CalculatorColors.textPrimary,
            ),
          ),
        ),
        const HintsList(hints: hints),
      ],
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
