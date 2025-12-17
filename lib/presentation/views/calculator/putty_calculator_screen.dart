import 'package:flutter/material.dart';

// --- Модели данных ---

enum CalculationMode { room, walls }
enum FinishTarget { wallpaper, painting } // Обои или Покраска
enum FinishMaterialType { dryBag, readyBucket } // Сухая смесь или Готовая паста

class Wall {
  String id;
  double length;
  double height;

  Wall({required this.id, this.length = 3.0, this.height = 2.7});
}

class Opening {
  String id;
  double width;
  double height;
  int count;

  Opening({required this.id, this.width = 0.9, this.height = 2.1, this.count = 1});
}

class PuttyResult {
  final double netArea;

  // Стартовая (Базовая) шпатлевка
  final double startWeight;
  final int startBags;

  // Финишная шпатлевка
  final double finishWeight; // или литры
  final int finishPacks;
  final String finishPackName; // "мешков" или "ведер"

  // Грунтовка
  final double primerVolume;
  final int primerCanisters;

  // Расходники
  final int sandingSheets; // Шлифлисты/Сетки

  PuttyResult({
    required this.netArea,
    required this.startWeight,
    required this.startBags,
    required this.finishWeight,
    required this.finishPacks,
    required this.finishPackName,
    required this.primerVolume,
    required this.primerCanisters,
    required this.sandingSheets,
  });
}

// --- Основной Виджет ---

class PuttyCalculatorScreen extends StatefulWidget {
  const PuttyCalculatorScreen({super.key});

  @override
  PuttyCalculatorScreenState createState() => PuttyCalculatorScreenState();
}

class PuttyCalculatorScreenState extends State<PuttyCalculatorScreen> {
  // Состояние
  CalculationMode _mode = CalculationMode.room;
  FinishTarget _target = FinishTarget.wallpaper;
  FinishMaterialType _finishType = FinishMaterialType.dryBag;

  // Размеры комнаты
  double _roomLength = 4.0;
  double _roomWidth = 3.0;
  double _roomHeight = 2.7;

  // Списки
  final List<Wall> _walls = [Wall(id: DateTime.now().toString(), length: 5.0, height: 2.7)];
  final List<Opening> _openings = [Opening(id: DateTime.now().toString())];

  // Результат
  PuttyResult? _result;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  // --- Логика ---

  void _calculate() {
    // 1. Площадь
    double totalWallArea = 0;
    if (_mode == CalculationMode.room) {
      final double perimeter = (_roomLength + _roomWidth) * 2;
      totalWallArea = perimeter * _roomHeight;
    } else {
      for (final wall in _walls) {
        totalWallArea += (wall.length * wall.height);
      }
    }

    double totalOpeningArea = 0;
    for (final op in _openings) {
      totalOpeningArea += (op.width * op.height * op.count);
    }

    final double netArea = (totalWallArea - totalOpeningArea).clamp(0, double.infinity);

    // 2. Технология нанесения
    // Под обои: 1 слой старта + 1 слой финиша (или 2 старта)
    // Под покраску: 2 слоя старта + 2 слоя финиша (стандарт)

    final int startLayers = _target == FinishTarget.painting ? 2 : 1;
    final int finishLayers = _target == FinishTarget.painting ? 2 : 1;

    // 3. Расход материалов

    // СТАРТ (База): Обычно сухая смесь (Волма, Фуген). Расход ~1.0 кг/м2 на слой 1мм.
    final double startConsumption = 1.0 * startLayers;
    final double startTotalWeight = netArea * startConsumption;
    final int startBags = (startTotalWeight / 25).ceil(); // Стандарт мешок 25кг

    // ФИНИШ:
    // Сухая (Vetonit LR+): ~1.2 кг/м2/слой. Мешок 20кг.
    // Паста (Danogips/Sheetrock): ~1.0 л/м2/слой (или ~1.6 кг). Ведро обычно 15-17л.

    double finishTotalAmount = 0;
    int finishPacks = 0;
    String packName = '';

    if (_finishType == FinishMaterialType.dryBag) {
      // Сухая
      final double cons = 1.2 * finishLayers;
      finishTotalAmount = netArea * cons;
      finishPacks = (finishTotalAmount / 20).ceil(); // Мешок 20кг
      packName = 'мешков (20кг)';
    } else {
      // Готовая паста (считаем в литрах для простоты, т.к. ведра часто в литрах или кг)
      // Danogips SuperFinish ~ 1л/м2 на слой
      final double cons = 1.0 * finishLayers;
      finishTotalAmount = netArea * cons;
      finishPacks = (finishTotalAmount / 15).ceil(); // Ведро ~15-17л
      packName = 'ведер (15л)';
    }

    // 4. Грунтовка (межслойная + перед финишем)
    // Считаем 0.15л на м2. Кол-во слоев грунта = слои шпатлевки + 1
    final double primerVolume = netArea * 0.15 * (startLayers + finishLayers);
    final int primerCanisters = (primerVolume / 10).ceil();

    // 5. Абразив (Сетки/Наждачка)
    // Примерно 1 лист на 10-15 м2 поверхности на каждый этап шлифовки
    const int sandingStages = 2; // Шлифовка базы + Шлифовка финиша
    final int sandingSheets = ((netArea / 10) * sandingStages).ceil();

    setState(() {
      _result = PuttyResult(
        netArea: netArea,
        startWeight: startTotalWeight,
        startBags: startBags,
        finishWeight: finishTotalAmount,
        finishPacks: finishPacks,
        finishPackName: packName,
        primerVolume: primerVolume,
        primerCanisters: primerCanisters,
        sandingSheets: sandingSheets,
      );
    });
  }

  // --- Хелперы ---
  void _updateValue(String value, Function(double) onUpdate) {
    if (value.isEmpty) {
      onUpdate(0.0);
    } else {
      final parsed = double.tryParse(value);
      if (parsed != null) onUpdate(parsed);
    }
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    // Используем Teal цвет для шпатлевки, чтобы отличаться от синей штукатурки
    final themeColor = Colors.teal[600];
    final lightColor = Colors.teal[50];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Шпатлевка & Финиш'),
        backgroundColor: themeColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryHeader(themeColor!),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildTargetSelector(lightColor!),
                  const SizedBox(height: 16),
                  _buildModeSelector(),
                  const SizedBox(height: 16),
                  _buildGeometrySection(lightColor),
                  const SizedBox(height: 16),
                  _buildOpeningsSection(),
                  const SizedBox(height: 16),
                  _buildMaterialTypeSection(),
                  const SizedBox(height: 24),
                  _buildResultCard(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(Color color) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      decoration: BoxDecoration(
        color: color,
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
          boxShadow: const [
            BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.1), blurRadius: 10, offset: Offset(0, 5))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildHeaderItem('Площадь', '${_result?.netArea.toStringAsFixed(1) ?? 0} м²', color),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildHeaderItem('Старт', '${_result?.startBags ?? 0} меш.', color),
            Container(width: 1, height: 30, color: Colors.grey[200]),
            _buildHeaderItem('Финиш', '${_result?.finishPacks ?? 0} шт.', color),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(fontSize: 18, color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTargetSelector(Color bgColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 5)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Цель отделки', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildSelectCard(
                icon: Icons.wallpaper,
                title: 'Под Обои',
                subtitle: 'База + Финиш',
                isSelected: _target == FinishTarget.wallpaper,
                onTap: () { setState(() => _target = FinishTarget.wallpaper); _calculate(); }
              )),
              const SizedBox(width: 12),
              Expanded(child: _buildSelectCard(
                icon: Icons.format_paint,
                title: 'Под Покраску',
                subtitle: '2 Базы + 2 Финиша',
                isSelected: _target == FinishTarget.painting,
                onTap: () { setState(() => _target = FinishTarget.painting); _calculate(); }
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectCard({required IconData icon, required String title, required String subtitle, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal[50] : Colors.grey[50],
          border: Border.all(color: isSelected ? Colors.teal : Colors.grey[200]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.teal[700] : Colors.grey[400], size: 28),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.teal[900] : Colors.grey[700], fontSize: 13)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 10, color: isSelected ? Colors.teal[600] : Colors.grey[500]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _buildSelectButton('По комнате', _mode == CalculationMode.room, () {
             setState(() => _mode = CalculationMode.room); _calculate();
          })),
          Expanded(child: _buildSelectButton('По стенам', _mode == CalculationMode.walls, () {
             setState(() => _mode = CalculationMode.walls); _calculate();
          })),
        ],
      ),
    );
  }

  Widget _buildSelectButton(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [const BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.05), blurRadius: 4)] : null,
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(color: isSelected ? Colors.teal[800] : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildGeometrySection(Color lightColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Геометрия', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (_mode == CalculationMode.walls)
              TextButton.icon(
                onPressed: () { setState(() => _walls.add(Wall(id: DateTime.now().toString()))); _calculate(); },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Стена'),
                style: TextButton.styleFrom(backgroundColor: lightColor, foregroundColor: Colors.teal),
              )
          ],
        ),
        const SizedBox(height: 8),
        if (_mode == CalculationMode.room)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: lightColor, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(children: [
                    Expanded(child: _buildInput('Длина пола (м)', _roomLength, (v) => _roomLength = v)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInput('Ширина пола (м)', _roomWidth, (v) => _roomWidth = v)),
                ]),
                const SizedBox(height: 12),
                _buildInput('Высота потолка (м)', _roomHeight, (v) => _roomHeight = v),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _walls.length,
            itemBuilder: (context, index) {
              final wall = _walls[index];
              return Card(
                elevation: 0, color: Colors.grey[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                      CircleAvatar(radius: 10, backgroundColor: Colors.white, child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: Colors.grey))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInput('Длина', wall.length, (v) => wall.length = v)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildInput('Высота', wall.height, (v) => wall.height = v)),
                      if (_walls.length > 1) IconButton(icon: const Icon(Icons.close, color: Colors.red, size: 18), onPressed: () { setState(() => _walls.removeAt(index)); _calculate(); })
                  ]),
                ),
              );
            },
          )
      ],
    );
  }

  Widget _buildOpeningsSection() {
    return ExpansionTile(
      title: Text('Проемы (Окна/Двери): ${_openings.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      tilePadding: EdgeInsets.zero,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _openings.length,
          itemBuilder: (context, index) {
            final op = _openings[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(children: [
                  Expanded(child: _buildInput('Ширина', op.width, (v) => op.width = v)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput('Высота', op.height, (v) => op.height = v)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput('Шт', op.count.toDouble(), (v) => op.count = v.toInt(), isInt: true)),
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () {
                    if (_openings.length > 1) { setState(() => _openings.removeAt(index)); _calculate(); }
                  })
              ]),
            );
          },
        ),
        TextButton(onPressed: () { setState(() => _openings.add(Opening(id: DateTime.now().toString()))); _calculate(); }, child: const Text('Добавить проем'))
      ],
    );
  }

  Widget _buildMaterialTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Тип финишного материала', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildRadioTile('Сухая смесь', 'В мешках (Vetonit)', FinishMaterialType.dryBag)),
            const SizedBox(width: 8),
            Expanded(child: _buildRadioTile('Готовая паста', 'В ведрах (Danogips)', FinishMaterialType.readyBucket)),
          ],
        )
      ],
    );
  }

  Widget _buildRadioTile(String title, String subtitle, FinishMaterialType type) {
    final bool selected = _finishType == type;
    return GestureDetector(
      onTap: () { setState(() => _finishType = type); _calculate(); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.teal[600] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? Colors.teal : Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(subtitle, style: TextStyle(color: selected ? Colors.teal[100] : Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2D3748), // Dark Gray
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.3), blurRadius: 15, offset: Offset(0, 5))]
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.tealAccent),
              SizedBox(width: 8),
              Text('Список покупок', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(color: Colors.grey),
          const SizedBox(height: 8),

          _buildResultRow(
            'Старт (База)',
            'Слой 1-2 мм',
            '${_result?.startBags} шт',
            'мешков 25кг'
          ),
          const SizedBox(height: 16),

          _buildResultRow(
            "Финиш (${_finishType == FinishMaterialType.dryBag ? 'Сухой' : 'Паста'})",
            _target == FinishTarget.painting ? 'Под покраску (2 слоя)' : 'Под обои (1 слой)',
            '${_result?.finishPacks} шт',
            _result?.finishPackName ?? ''
          ),
          const SizedBox(height: 16),

          _buildResultRow(
            'Грунтовка',
            'Межслойная',
            '${_result?.primerCanisters} шт',
            'канистр 10л'
          ),

          const Divider(color: Colors.grey, height: 32),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Абразив (сетки/шкурка)', style: TextStyle(color: Colors.white70, fontSize: 14)),
              Text('${_result?.sandingSheets} шт', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildResultRow(String title, String subtitle, String mainValue, String subValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(mainValue, style: const TextStyle(color: Colors.tealAccent, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(subValue, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildInput(String label, double value, Function(double) onChanged, {bool isInt = false}) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: Colors.grey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      controller: TextEditingController(text: isInt ? value.toInt().toString() : value.toStringAsFixed(1)),
      onChanged: (val) => _updateValue(val, onChanged),
    );
  }
}
