import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/validation/input_sanitizer.dart';
import '../../../domain/models/calculator_definition_v2.dart';

enum CalculationMode { room, walls }
enum WallMaterial { absorbent, concrete }
enum MixType { gypsum, cement }

class _WallFields {
  final String id;
  final TextEditingController length;
  final TextEditingController height;

  _WallFields({
    required this.id,
    double initialLength = 3.0,
    double initialHeight = 2.7,
  })  : length = TextEditingController(
          text: InputSanitizer.formatNumber(initialLength, decimals: 2),
        ),
        height = TextEditingController(
          text: InputSanitizer.formatNumber(initialHeight, decimals: 2),
        );

  void dispose() {
    length.dispose();
    height.dispose();
  }
}

class _OpeningFields {
  final String id;
  final TextEditingController width;
  final TextEditingController height;
  final TextEditingController count;

  _OpeningFields({
    required this.id,
    double initialWidth = 0.9,
    double initialHeight = 2.1,
    int initialCount = 1,
  })  : width = TextEditingController(
          text: InputSanitizer.formatNumber(initialWidth, decimals: 2),
        ),
        height = TextEditingController(
          text: InputSanitizer.formatNumber(initialHeight, decimals: 2),
        ),
        count = TextEditingController(text: initialCount.toString());

  void dispose() {
    width.dispose();
    height.dispose();
    count.dispose();
  }
}

class CalculationResult {
  final double netArea;
  final double totalWeight;
  final int bagsCount;
  final int bagsStock;
  final double primerVolume;
  final int primerPacks;
  final String primerName;
  final String primerUnit;
  final int primerPackSize;
  final int totalBeacons;
  final double perimeter;

  const CalculationResult({
    required this.netArea,
    required this.totalWeight,
    required this.bagsCount,
    required this.bagsStock,
    required this.primerVolume,
    required this.primerPacks,
    required this.primerName,
    required this.primerUnit,
    required this.primerPackSize,
    required this.totalBeacons,
    required this.perimeter,
  });
}

class PlasterCalculatorScreen extends StatefulWidget {
  final CalculatorDefinitionV2 definition;
  final Map<String, double>? initialInputs;

  const PlasterCalculatorScreen({
    super.key,
    required this.definition,
    this.initialInputs,
  });

  @override
  State<PlasterCalculatorScreen> createState() =>
      _PlasterCalculatorScreenState();
}

class _PlasterCalculatorScreenState extends State<PlasterCalculatorScreen> {
  CalculationMode _mode = CalculationMode.room;
  WallMaterial _wallMaterial = WallMaterial.absorbent;
  MixType _mixType = MixType.gypsum;

  final TextEditingController _roomLength = TextEditingController(text: '4');
  final TextEditingController _roomWidth = TextEditingController(text: '3');
  final TextEditingController _roomHeight = TextEditingController(text: '2.7');

  final List<_WallFields> _walls = [];
  final List<_OpeningFields> _openings = [];

  double _layerThickness = 20.0;
  int _bagWeight = 30;

  CalculationResult? _result;

  @override
  void initState() {
    super.initState();

    _walls.add(_WallFields(id: _newId(), initialLength: 5.0, initialHeight: 2.7));
    _openings.add(_OpeningFields(id: _newId()));

    final initial = widget.initialInputs;
    if (initial != null) {
      final thickness = initial['thickness'];
      if (thickness != null && thickness.isFinite) {
        _layerThickness = thickness.clamp(6.0, 50.0);
      }
      final type = initial['type'];
      if (type != null) {
        _mixType = type.round() == 2 ? MixType.cement : MixType.gypsum;
      }
      final area = initial['area'];
      if (area != null && area.isFinite && area > 0) {
        _mode = CalculationMode.walls;
        final approxHeight = 2.7;
        _walls
          ..forEach((w) => w.dispose())
          ..clear();
        _walls.add(
          _WallFields(
            id: _newId(),
            initialLength: math.max(0.1, area / approxHeight),
            initialHeight: approxHeight,
          ),
        );
      }
    }

    _result = _compute();
  }

  @override
  void dispose() {
    _roomLength.dispose();
    _roomWidth.dispose();
    _roomHeight.dispose();
    for (final w in _walls) {
      w.dispose();
    }
    for (final o in _openings) {
      o.dispose();
    }
    super.dispose();
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  double _readDouble(TextEditingController controller) {
    final parsed = InputSanitizer.parseDouble(controller.text);
    return parsed ?? 0.0;
  }

  int _readInt(TextEditingController controller) {
    final parsed = InputSanitizer.parseDouble(controller.text);
    if (parsed == null) return 0;
    return parsed.toInt();
  }

  void _recalculate() {
    setState(() => _result = _compute());
  }

  CalculationResult _compute() {
    double totalWallArea = 0;
    double perimeter = 0;
    int totalBeacons = 0;

    if (_mode == CalculationMode.room) {
      final roomLength = math.max(0.0, _readDouble(_roomLength));
      final roomWidth = math.max(0.0, _readDouble(_roomWidth));
      final roomHeight = math.max(0.0, _readDouble(_roomHeight));

      perimeter = (roomLength + roomWidth) * 2;
      totalWallArea = perimeter * roomHeight;
      totalBeacons = (perimeter / 1.5).ceil();
    } else {
      for (final wall in _walls) {
        final length = math.max(0.0, _readDouble(wall.length));
        final height = math.max(0.0, _readDouble(wall.height));
        totalWallArea += length * height;
        perimeter += length;

        if (length > 0.5) {
          final count = ((length - 0.2) / 1.5).ceil();
          totalBeacons += count < 2 ? 2 : count;
        }
      }
    }

    double totalOpeningArea = 0;
    for (final op in _openings) {
      final width = math.max(0.0, _readDouble(op.width));
      final height = math.max(0.0, _readDouble(op.height));
      final count = math.max(0, _readInt(op.count));
      totalOpeningArea += width * height * count;
    }

    final netArea = math.max(0.0, totalWallArea - totalOpeningArea);

    final consumptionPer10mm = _mixType == MixType.gypsum ? 8.5 : 14.0;
    final thickness = _layerThickness;
    final totalWeight = netArea * (thickness / 10.0) * consumptionPer10mm;

    final bagWeight = math.max(1, _bagWeight);
    final bagsCount = (totalWeight / bagWeight).ceil();
    final bagsStock = (bagsCount * 1.05).ceil();

    final primerConsumption = _wallMaterial == WallMaterial.absorbent ? 0.2 : 0.35;
    final primerTotalAmount = netArea * primerConsumption;
    final primerPackSize = _wallMaterial == WallMaterial.absorbent ? 10 : 20;
    final primerPacks = (primerTotalAmount / primerPackSize).ceil();
    final primerName = _wallMaterial == WallMaterial.absorbent
        ? 'Грунт глуб. прон.'
        : 'Бетоноконтакт';
    final primerUnit = _wallMaterial == WallMaterial.absorbent ? 'л' : 'кг';

    return CalculationResult(
      netArea: netArea,
      totalWeight: totalWeight,
      bagsCount: bagsCount,
      bagsStock: bagsStock,
      primerVolume: primerTotalAmount,
      primerPacks: primerPacks,
      primerName: primerName,
      primerUnit: primerUnit,
      primerPackSize: primerPackSize,
      totalBeacons: totalBeacons,
      perimeter: perimeter,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final result = _result;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(loc.translate(widget.definition.titleKey)),
        backgroundColor: Colors.blue[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(result),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMaterialSelector(),
                    const SizedBox(height: 16),
                    _buildModeSelector(),
                    const SizedBox(height: 16),
                    _buildGeometrySection(),
                    const SizedBox(height: 16),
                    _buildOpeningsSection(),
                    const SizedBox(height: 16),
                    _buildMixSettingsSection(),
                    const SizedBox(height: 24),
                    _buildResultCard(result),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(CalculationResult? result) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: Colors.blue[700],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildHeaderItem(
              'Площадь',
              '${(result?.netArea ?? 0).toStringAsFixed(1)} м²',
            ),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildHeaderItem('Слой', '${_layerThickness.toInt()} мм'),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildHeaderItem(
              'Вес',
              '${(result?.totalWeight ?? 0).toInt()} кг',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: Colors.blue[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[100]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_view, size: 18, color: Colors.brown),
              SizedBox(width: 8),
              Text(
                'Материал основания',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildSelectButton(
                  '🧱 Блок/Кирпич',
                  _wallMaterial == WallMaterial.absorbent,
                  () => setState(() {
                    _wallMaterial = WallMaterial.absorbent;
                    _result = _compute();
                  }),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSelectButton(
                  '🏗 Бетон',
                  _wallMaterial == WallMaterial.concrete,
                  () => setState(() {
                    _wallMaterial = WallMaterial.concrete;
                    _result = _compute();
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _wallMaterial == WallMaterial.absorbent
                ? 'Для впитывающих стен: грунтовка глуб. проникновения'
                : 'Для гладкого бетона: бетоноконтакт',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _buildSelectButton(
              'По комнате',
              _mode == CalculationMode.room,
              () => setState(() {
                _mode = CalculationMode.room;
                _result = _compute();
              }),
              isTab: true,
            ),
          ),
          Expanded(
            child: _buildSelectButton(
              'По стенам',
              _mode == CalculationMode.walls,
              () => setState(() {
                _mode = CalculationMode.walls;
                _result = _compute();
              }),
              isTab: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectButton(
    String text,
    bool isSelected,
    VoidCallback onTap, {
    bool isTab = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: (!isTab && isSelected)
              ? Border.all(color: Colors.orange)
              : null,
          boxShadow: (isSelected && isTab)
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.blue[800] : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildGeometrySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Геометрия',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_mode == CalculationMode.walls)
              TextButton.icon(
                onPressed: () => setState(() {
                  _walls.add(_WallFields(id: _newId()));
                  _result = _compute();
                }),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Добавить'),
                style: TextButton.styleFrom(backgroundColor: Colors.blue[50]),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_mode == CalculationMode.room) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        'Длина пола (м)',
                        _roomLength,
                        onChanged: _recalculate,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInput(
                        'Ширина пола (м)',
                        _roomWidth,
                        onChanged: _recalculate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInput(
                  'Высота потолка (м)',
                  _roomHeight,
                  onChanged: _recalculate,
                ),
                const Divider(),
                Text(
                  'Периметр стен: ${((_readDouble(_roomLength) + _readDouble(_roomWidth)) * 2).toStringAsFixed(1)} м',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _walls.length,
            itemBuilder: (context, index) {
              final wall = _walls[index];
              return Card(
                elevation: 0,
                color: Colors.grey[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.white,
                        child: Text(
                          '${index + 1}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInput(
                          'Длина',
                          wall.length,
                          onChanged: _recalculate,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildInput(
                          'Высота',
                          wall.height,
                          onChanged: _recalculate,
                        ),
                      ),
                      if (_walls.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => setState(() {
                            final removed = _walls.removeAt(index);
                            removed.dispose();
                            _result = _compute();
                          }),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildOpeningsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Исключения (Окна/Двери)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () => setState(() {
                _openings.add(_OpeningFields(id: _newId()));
                _result = _compute();
              }),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Добавить'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange[50],
                foregroundColor: Colors.deepOrange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _openings.length,
          itemBuilder: (context, index) {
            final op = _openings[index];
            return Card(
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInput(
                        'Ширина',
                        op.width,
                        onChanged: _recalculate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInput(
                        'Высота',
                        op.height,
                        onChanged: _recalculate,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInput(
                        'Кол-во',
                        op.count,
                        onChanged: _recalculate,
                        isInt: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      onPressed: () => setState(() {
                        final removed = _openings.removeAt(index);
                        removed.dispose();
                        _result = _compute();
                      }),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMixSettingsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Материал',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSelectButton(
                    'Гипсовая',
                    _mixType == MixType.gypsum,
                    () => setState(() {
                      _mixType = MixType.gypsum;
                      _result = _compute();
                    }),
                    isTab: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSelectButton(
                    'Цементная',
                    _mixType == MixType.cement,
                    () => setState(() {
                      _mixType = MixType.cement;
                      _result = _compute();
                    }),
                    isTab: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Средний слой',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_layerThickness.toInt()} мм',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Slider(
              value: _layerThickness,
              min: 6,
              max: 50,
              divisions: 44,
              activeColor: Colors.blue[600],
              onChanged: (v) => setState(() {
                _layerThickness = v;
                _result = _compute();
              }),
            ),
            const SizedBox(height: 8),
            const Text(
              'Вес мешка',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [25, 30, 50]
                  .map(
                    (w) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text('$w кг'),
                        selected: _bagWeight == w,
                        onSelected: (selected) {
                          if (!selected) return;
                          setState(() {
                            _bagWeight = w;
                            _result = _compute();
                          });
                        },
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(CalculationResult? result) {
    final r = result;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.calculate, color: Colors.greenAccent),
              SizedBox(width: 8),
              Text(
                'Смета работ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),
          _buildResultRow(
            'Штукатурка',
            r == null ? '' : '${r.bagsCount} мешков',
            r == null ? '—' : '${r.bagsStock} шт',
            'с запасом',
          ),
          const SizedBox(height: 16),
          _buildResultRow(
            r?.primerName ?? 'Грунтовка',
            r == null
                ? ''
                : '~${r.primerVolume.toStringAsFixed(1)} ${r.primerUnit}',
            r == null ? '—' : '${r.primerPacks} шт',
            r == null ? '' : 'упак ${r.primerPackSize}${r.primerUnit}',
          ),
          const SizedBox(height: 16),
          _buildResultRow(
            'Маяки (шаг 1.5)',
            '',
            r == null ? '—' : '${r.totalBeacons} шт',
            'по 3м',
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String title,
    String subtitle,
    String mainValue,
    String subValue,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mainValue,
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(subValue, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildInput(
    String label,
    TextEditingController controller, {
    required VoidCallback onChanged,
    bool isInt = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: !isInt),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: (_) => onChanged(),
        ),
      ],
    );
  }
}
