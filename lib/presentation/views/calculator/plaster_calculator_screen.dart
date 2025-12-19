import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/validation/input_sanitizer.dart';
import '../../../domain/models/calculator_definition_v2.dart';

enum PlasterMaterial { gypsum, cement }
enum PlasterInputMode { manual, room }

class _PlasterResult {
  final double area;
  final double totalWeight;
  final int bags;
  final int beacons;
  final int meshArea;
  final double primerLiters;
  final int beaconSize;

  const _PlasterResult({
    required this.area,
    required this.totalWeight,
    required this.bags,
    required this.beacons,
    required this.meshArea,
    required this.primerLiters,
    required this.beaconSize,
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
  State<PlasterCalculatorScreen> createState() => _PlasterCalculatorScreenState();
}

class _PlasterCalculatorScreenState extends State<PlasterCalculatorScreen> {
  static const Map<PlasterMaterial, double> _consumptionRates = {
    PlasterMaterial.gypsum: 8.5,
    PlasterMaterial.cement: 17.0,
  };

  final TextEditingController _roomWidth = TextEditingController(text: '4');
  final TextEditingController _roomLength = TextEditingController(text: '5');
  final TextEditingController _roomHeight = TextEditingController(text: '2.7');
  final TextEditingController _openingsArea = TextEditingController(text: '4');

  double _manualArea = 30;
  double _thickness = 15;
  int _bagWeight = 30;
  bool _useBeacons = true;
  bool _useMesh = false;
  bool _usePrimer = true;
  PlasterMaterial _materialType = PlasterMaterial.gypsum;
  PlasterInputMode _inputMode = PlasterInputMode.manual;
  late _PlasterResult _result;
  late AppLocalizations _loc;

  @override
  void initState() {
    super.initState();
    _applyInitialInputs();
    _result = _calculate();
  }

  void _applyInitialInputs() {
    final initial = widget.initialInputs;
    if (initial == null) return;
    if (initial['thickness'] != null) _thickness = initial['thickness']!.clamp(5.0, 100.0);
    if (initial['type']?.round() == 2) {
      _materialType = PlasterMaterial.cement;
      _bagWeight = 25;
    }
    if (initial['area'] != null && initial['area']! > 0) {
      _manualArea = initial['area']!.clamp(1.0, 1000.0);
      _inputMode = PlasterInputMode.manual;
    }
  }

  _PlasterResult _calculate() {
    double area = _manualArea;
    if (_inputMode == PlasterInputMode.room) {
      final w = InputSanitizer.parseDouble(_roomWidth.text) ?? 0;
      final l = InputSanitizer.parseDouble(_roomLength.text) ?? 0;
      final h = InputSanitizer.parseDouble(_roomHeight.text) ?? 0;
      final o = InputSanitizer.parseDouble(_openingsArea.text) ?? 0;
      area = math.max(0, (2 * (w + l) * h) - o);
    }

    final rate = _consumptionRates[_materialType] ?? 8.5;
    final totalWeight = area * (_thickness / 10.0) * rate * 1.1;
    return _PlasterResult(
      area: area,
      totalWeight: totalWeight,
      bags: (totalWeight / _bagWeight).ceil(),
      beacons: _useBeacons ? (area / 2.5).ceil() : 0,
      meshArea: _useMesh ? (area * 1.1).ceil() : 0,
      primerLiters: double.parse((_usePrimer ? area * 0.1 * 1.1 : 0).toStringAsFixed(1)),
      beaconSize: _thickness < 10 ? 6 : 10,
    );
  }

  void _update() => setState(() => _result = _calculate());

  @override
  Widget build(BuildContext context) {
    _loc = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_loc.translate('plaster_pro.brand'), style: const TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            _buildMaterialSelector(),
            const SizedBox(height: 16),
            _buildAreaCard(),
            const SizedBox(height: 16),
            _buildThicknessCard(),
            const SizedBox(height: 16),
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildSpecCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          _materialBtn(PlasterMaterial.gypsum, _loc.translate('plaster_pro.material.gypsum')),
          _materialBtn(PlasterMaterial.cement, _loc.translate('plaster_pro.material.cement')),
        ],
      ),
    );
  }

  Widget _materialBtn(PlasterMaterial type, String label) {
    final bool active = _materialType == type;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _materialType = type;
            _bagWeight = type == PlasterMaterial.gypsum ? 30 : 25;
            _result = _calculate();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.blueAccent : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(color: active ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildAreaCard() {
    return _card(
      child: Column(
        children: [
          Row(
            children: [
              _modeBtn(PlasterInputMode.manual, _loc.translate('plaster_pro.mode.manual')),
              const SizedBox(width: 8),
              _modeBtn(PlasterInputMode.room, _loc.translate('plaster_pro.mode.room')),
            ],
          ),
          const SizedBox(height: 20),
          _inputMode == PlasterInputMode.manual ? _buildManualInputs() : _buildRoomInputs(),
        ],
      ),
    );
  }

  Widget _modeBtn(PlasterInputMode mode, String label) {
    final bool active = _inputMode == mode;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => setState(() { _inputMode = mode; _update(); }),
        style: OutlinedButton.styleFrom(
          backgroundColor: active ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
          side: BorderSide(color: active ? Colors.blueAccent : Colors.white12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: Text(label, style: TextStyle(color: active ? Colors.blueAccent : Colors.grey, fontSize: 12)),
      ),
    );
  }

  Widget _buildManualInputs() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_loc.translate('plaster_pro.label.wall_area'), style: const TextStyle(color: Colors.white70)),
            Text('${_manualArea.toStringAsFixed(0)} м²', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _manualArea,
          min: 1,
          max: 500,
          onChanged: (v) { setState(() { _manualArea = v; _update(); }); },
        ),
      ],
    );
  }

  Widget _buildRoomInputs() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _miniField(_loc.translate('plaster_pro.label.width'), _roomWidth),
        _miniField(_loc.translate('plaster_pro.label.length'), _roomLength),
        _miniField(_loc.translate('plaster_pro.label.height'), _roomHeight),
        _miniField(_loc.translate('plaster_pro.label.openings_hint'), _openingsArea, isFull: true),
      ],
    );
  }

  Widget _miniField(String label, TextEditingController ctr, {bool isFull = false}) {
    return SizedBox(
      width: isFull ? double.infinity : 90,
      child: TextField(
        controller: ctr,
        keyboardType: TextInputType.number,
        onChanged: (_) => _update(),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey, fontSize: 12),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
        ),
      ),
    );
  }

  Widget _buildThicknessCard() {
    return _card(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_loc.translate('plaster_pro.thickness.title'), style: const TextStyle(color: Colors.white70)),
              Text('${_thickness.toStringAsFixed(0)} мм', style: const TextStyle(color: Colors.blueAccent, fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _thickness,
            min: 5,
            max: 100,
            onChanged: (v) { setState(() { _thickness = v; _update(); }); },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _optIcon(Icons.architecture, _useBeacons, () => setState(() { _useBeacons = !_useBeacons; _update(); })),
              _optIcon(Icons.grid_on, _useMesh, () => setState(() { _useMesh = !_useMesh; _update(); })),
              _optIcon(Icons.water_drop, _usePrimer, () => setState(() { _usePrimer = !_usePrimer; _update(); })),
            ],
          )
        ],
      ),
    );
  }

  Widget _optIcon(IconData icon, bool active, VoidCallback tap) {
    return IconButton(
      icon: Icon(icon, color: active ? Colors.blueAccent : Colors.white24),
      onPressed: tap,
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(_loc.translate('plaster_pro.summary.bags').toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('${_result.bags}', style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900)),
          Text(_loc.translate('plaster_pro.summary.unit_pcs'), style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildSpecCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_loc.translate('plaster_pro.spec.title').toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _specItem(_loc.translate('plaster_pro.summary.weight'), '${_result.totalWeight.toStringAsFixed(0)} кг'),
          if (_useBeacons) _specItem('${_loc.translate('plaster_pro.options.beacons')} ${_result.beaconSize}мм', '${_result.beacons} шт'),
          if (_useMesh) _specItem(_loc.translate('plaster_pro.spec.mesh_title'), '${_result.meshArea} м²'),
          if (_usePrimer) _specItem(_loc.translate('plaster_pro.options.primer'), '${_result.primerLiters} л'),
        ],
      ),
    );
  }

  Widget _specItem(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.white70)), Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(20)),
      child: child,
    );
  }

}
