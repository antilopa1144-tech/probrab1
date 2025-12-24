part of 'putty_calculator_screen.dart';

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

  AppLocalizations get _loc => AppLocalizations.of(context);

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
    String packNameKey = '';

    if (_finishType == FinishMaterialType.dryBag) {
      // Сухая
      final double cons = 1.2 * finishLayers;
      finishTotalAmount = netArea * cons;
      finishPacks = (finishTotalAmount / 20).ceil(); // Мешок 20кг
      packNameKey = 'unit.bags';
    } else {
      // Готовая паста (считаем в литрах для простоты, т.к. ведра часто в литрах или кг)
      // Danogips SuperFinish ~ 1л/м2 на слой
      final double cons = 1.0 * finishLayers;
      finishTotalAmount = netArea * cons;
      finishPacks = (finishTotalAmount / 15).ceil(); // Ведро ~15-17л
      packNameKey = 'unit.buckets';
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
        finishPackNameKey: packNameKey,
        primerVolume: primerVolume,
        primerCanisters: primerCanisters,
        sandingSheets: sandingSheets,
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    const accentColor = CalculatorColors.interior;
    final lightColor = Colors.teal[50];

    return CalculatorScaffold(
      title: _loc.translate('putty.title'),
      accentColor: accentColor,
      resultHeader: _buildSummaryHeader(),
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
    );
  }

  Widget _buildSummaryHeader() {
    const accentColor = CalculatorColors.interior;
    return CalculatorResultHeader(
      accentColor: accentColor,
      results: [
        ResultItem(
          label: _loc.translate('putty.summary.area').toUpperCase(),
          value: '${_result?.netArea.toStringAsFixed(1) ?? 0} ${_loc.translate('unit.sqm')}',
          icon: Icons.straighten,
        ),
        ResultItem(
          label: _loc.translate('putty.summary.start').toUpperCase(),
          value: '${_result?.startBags ?? 0} ${_loc.translate('unit.bags')}',
          icon: Icons.shopping_bag,
        ),
        ResultItem(
          label: _loc.translate('putty.summary.finish').toUpperCase(),
          value: '${_result?.finishPacks ?? 0} ${_loc.translate('unit.pieces')}',
          icon: Icons.inventory_2,
        ),
      ],
    );
  }

  Widget _buildTargetSelector(Color bgColor) {
    const accentColor = CalculatorColors.interior;
    return InputGroup(
      title: _loc.translate('putty.section.finish_goal'),
      children: [
        TypeSelectorGroup(
          options: [
            TypeSelectorOption(
              icon: Icons.wallpaper,
              title: _loc.translate('putty.target.wallpaper.title'),
              subtitle: _loc.translate('putty.target.wallpaper.subtitle'),
            ),
            TypeSelectorOption(
              icon: Icons.format_paint,
              title: _loc.translate('putty.target.painting.title'),
              subtitle: _loc.translate('putty.target.painting.subtitle'),
            ),
          ],
          selectedIndex: _target == FinishTarget.wallpaper ? 0 : 1,
          onSelect: (index) {
            setState(() {
              _target = index == 0 ? FinishTarget.wallpaper : FinishTarget.painting;
            });
            _calculate();
          },
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildModeSelector() {
    const accentColor = CalculatorColors.interior;
    return ModeSelector(
      options: [
        _loc.translate('putty.mode.room'),
        _loc.translate('putty.mode.walls'),
      ],
      selectedIndex: _mode == CalculationMode.room ? 0 : 1,
      onSelect: (index) {
        setState(() {
          _mode = index == 0 ? CalculationMode.room : CalculationMode.walls;
        });
        _calculate();
      },
      accentColor: accentColor,
    );
  }

  Widget _buildGeometrySection(Color lightColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _loc.translate('putty.section.geometry'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (_mode == CalculationMode.walls)
              TextButton.icon(
                onPressed: () { setState(() => _walls.add(Wall(id: DateTime.now().toString()))); _calculate(); },
                icon: const Icon(Icons.add, size: 16),
                label: Text(_loc.translate('putty.input.wall')),
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
                    Expanded(child: _buildInput(_loc.translate('putty.input.floor_length'), _roomLength, (v) => _roomLength = v, suffix: 'м')),
                    const SizedBox(width: 12),
                    Expanded(child: _buildInput(_loc.translate('putty.input.floor_width'), _roomWidth, (v) => _roomWidth = v, suffix: 'м')),
                ]),
                const SizedBox(height: 12),
                _buildInput(_loc.translate('putty.input.ceiling_height'), _roomHeight, (v) => _roomHeight = v, suffix: 'м'),
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
                      Expanded(child: _buildInput(_loc.translate('putty.input.length'), wall.length, (v) => wall.length = v, suffix: 'м')),
                      const SizedBox(width: 8),
                      Expanded(child: _buildInput(_loc.translate('putty.input.height'), wall.height, (v) => wall.height = v, suffix: 'м')),
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
      title: Text(
        _loc.translate('putty.section.openings', {'count': _openings.length.toString()}),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
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
                  Expanded(child: _buildInput(_loc.translate('putty.input.width'), op.width, (v) => op.width = v, suffix: 'м')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput(_loc.translate('putty.input.height'), op.height, (v) => op.height = v, suffix: 'м')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildInput(_loc.translate('putty.input.count'), op.count.toDouble(), (v) => op.count = v.toInt(), isInt: true, suffix: 'шт')),
                  IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () {
                    if (_openings.length > 1) { setState(() => _openings.removeAt(index)); _calculate(); }
                  })
              ]),
            );
          },
        ),
        TextButton(
          onPressed: () {
            setState(() => _openings.add(Opening(id: DateTime.now().toString())));
            _calculate();
          },
          child: Text(_loc.translate('putty.action.add_opening')),
        )
      ],
    );
  }

  Widget _buildMaterialTypeSection() {
    const accentColor = CalculatorColors.interior;
    return InputGroup(
      title: _loc.translate('putty.section.finish_material_type'),
      children: [
        TypeSelectorGroup(
          options: [
            TypeSelectorOption(
              icon: Icons.inventory,
              title: _loc.translate('putty.finish_material.dry'),
              subtitle: _loc.translate('putty.finish_material.dry_subtitle'),
            ),
            TypeSelectorOption(
              icon: Icons.shopping_basket,
              title: _loc.translate('putty.finish_material.ready'),
              subtitle: _loc.translate('putty.finish_material.ready_subtitle'),
            ),
          ],
          selectedIndex: _finishType == FinishMaterialType.dryBag ? 0 : 1,
          onSelect: (index) {
            setState(() {
              _finishType = index == 0 ? FinishMaterialType.dryBag : FinishMaterialType.readyBucket;
            });
            _calculate();
          },
          accentColor: accentColor,
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    const accentColor = CalculatorColors.interior;
    final loc = AppLocalizations.of(context);
    final finishTypeLabel = loc.translate(
      'putty.finish_type',
      {
        'type': loc.translate(
          _finishType == FinishMaterialType.dryBag
              ? 'material.dry'
              : 'material.paste',
        ),
      },
    );
    final piecesLabel = loc.translate('unit.pieces');

    final results = <ResultRowItem>[
      ResultRowItem(
        label: loc.translate('putty.shopping.start_title'),
        value: '${_result?.startBags} $piecesLabel',
        subtitle: loc.translate('putty.shopping.start_subtitle'),
        icon: Icons.shopping_bag,
      ),
      ResultRowItem(
        label: finishTypeLabel,
        value: '${_result?.finishPacks} $piecesLabel',
        subtitle: loc.translate(
          _target == FinishTarget.painting
              ? 'putty.shopping.finish_painting'
              : 'putty.shopping.finish_wallpaper',
        ),
        icon: Icons.inventory_2,
      ),
      ResultRowItem(
        label: loc.translate('putty.shopping.primer_title'),
        value: '${_result?.primerCanisters} $piecesLabel',
        subtitle: loc.translate('putty.shopping.primer_subtitle'),
        icon: Icons.water_drop,
      ),
      ResultRowItem(
        label: loc.translate('putty.section.abrasive'),
        value: '${_result?.sandingSheets} $piecesLabel',
        subtitle: '',
        icon: Icons.build,
      ),
    ];

    return ResultCard(
      title: loc.translate('putty.section.shopping_list'),
      titleIcon: Icons.check_circle,
      results: results,
      accentColor: accentColor,
    );
  }

  Widget _buildInput(String label, double value, Function(double) onChanged, {bool isInt = false, String? suffix}) {
    const accentColor = CalculatorColors.interior;
    return CalculatorTextField(
      label: label,
      value: value,
      onChanged: (val) {
        onChanged(val);
        _calculate();
      },
      suffix: suffix,
      accentColor: accentColor,
      isInteger: isInt,
      minValue: 0.1,
      maxValue: isInt ? 100 : 50,
    );
  }
}
