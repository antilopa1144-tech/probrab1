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

  // TODO: Подключить к calculatorConstantsProvider для получения Remote Config
  final _constants = _PuttyConstants(null);

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

    // СТАРТ (База): Обычно сухая смесь (Волма, Фуген)
    final double startConsumption = _constants.startConsumptionPerLayer * startLayers;
    final double startTotalWeight = netArea * startConsumption;
    final int startBags = (startTotalWeight / _constants.startBagWeight).ceil();

    // ФИНИШ:
    // Сухая (Vetonit LR+) или Паста (Danogips/Sheetrock)

    double finishTotalAmount = 0;
    int finishPacks = 0;
    String packNameKey = '';

    if (_finishType == FinishMaterialType.dryBag) {
      // Сухая
      final double cons = _constants.dryConsumption * finishLayers;
      finishTotalAmount = netArea * cons;
      finishPacks = (finishTotalAmount / _constants.dryBagWeight).ceil();
      packNameKey = 'unit.bags';
    } else {
      // Готовая паста
      final double cons = _constants.pasteConsumption * finishLayers;
      finishTotalAmount = netArea * cons;
      finishPacks = (finishTotalAmount / _constants.pasteBucketVolume).ceil();
      packNameKey = 'unit.buckets';
    }

    // 4. Грунтовка (межслойная + перед финишем)
    final double primerVolume = netArea * _constants.primerConsumptionPerM2 * (startLayers + finishLayers);
    final int primerCanisters = (primerVolume / _constants.primerCanisterVolume).ceil();

    // 5. Абразив (Сетки/Наждачка)
    const int sandingStages = 2; // Шлифовка базы + Шлифовка финиша
    final int sandingSheets = ((netArea / _constants.areaPerSheet) * sandingStages).ceil();

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

  String _generateExportText() {
    final r = _result;
    if (r == null) return '';

    final targetLabel = _target == FinishTarget.painting ? 'Под покраску' : 'Под обои';
    final finishTypeLabel = _finishType == FinishMaterialType.dryBag ? 'сухая смесь' : 'готовая паста';

    final buffer = StringBuffer();
    buffer.writeln('РАСЧЁТ ШПАКЛЁВКИ');
    buffer.writeln('═' * 40);
    buffer.writeln();

    buffer.writeln('Цель: $targetLabel');
    buffer.writeln('Финиш: $finishTypeLabel');
    buffer.writeln('Площадь: ${r.netArea.toStringAsFixed(1)} м²');
    buffer.writeln();

    buffer.writeln('МАТЕРИАЛЫ:');
    buffer.writeln('─' * 40);
    buffer.writeln('- Стартовая шпатлёвка: ${r.startBags} мешков (25 кг)');
    buffer.writeln('- Финишная шпатлёвка: ${r.finishPacks} ${_finishType == FinishMaterialType.dryBag ? "мешков (20 кг)" : "вёдер (15 л)"}');
    buffer.writeln('- Грунтовка: ${r.primerCanisters} канистр (10 л)');
    buffer.writeln('- Абразив: ${r.sandingSheets} листов');

    buffer.writeln();
    buffer.writeln('═' * 40);
    buffer.writeln('Создано в ПроРаб');

    return buffer.toString();
  }

  Future<void> _shareCalculation() async {
    final text = _generateExportText();
    await SharePlus.instance.share(ShareParams(text: text, subject: 'Расчёт шпаклёвки'));
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
    const accentColor = CalculatorColors.interior;

    return CalculatorScaffold(
      title: _loc.translate('putty.title'),
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
      resultHeader: _buildSummaryHeader(),
      children: [
        _buildTargetSelector(),
        const SizedBox(height: 16),
        _buildModeSelector(),
        const SizedBox(height: 16),
        _buildGeometrySection(),
        const SizedBox(height: 16),
        _buildOpeningsSection(),
        const SizedBox(height: 16),
        _buildMaterialTypeSection(),
        const SizedBox(height: 24),
        _buildResultCard(),
        const SizedBox(height: 24),
        _buildTipsSection(),
        const SizedBox(height: 20),
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

  Widget _buildTargetSelector() {
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

  Widget _buildGeometrySection() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('putty.section.geometry'),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
              if (_mode == CalculationMode.walls)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _walls.add(Wall(id: DateTime.now().toString())));
                    _calculate();
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: Text(_loc.translate('putty.input.wall')),
                  style: TextButton.styleFrom(
                    backgroundColor: accentColor.withValues(alpha: 0.1),
                    foregroundColor: accentColor,
                  ),
                )
            ],
          ),
          const SizedBox(height: 12),
          if (_mode == CalculationMode.room)
            Column(
              children: [
                Row(children: [
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('putty.input.floor_length'),
                      value: _roomLength,
                      onChanged: (v) {
                        _roomLength = v;
                        _calculate();
                      },
                      suffix: 'м',
                      accentColor: accentColor,
                      minValue: 0.1,
                      maxValue: 50,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('putty.input.floor_width'),
                      value: _roomWidth,
                      onChanged: (v) {
                        _roomWidth = v;
                        _calculate();
                      },
                      suffix: 'м',
                      accentColor: accentColor,
                      minValue: 0.1,
                      maxValue: 50,
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                CalculatorTextField(
                  label: _loc.translate('putty.input.ceiling_height'),
                  value: _roomHeight,
                  onChanged: (v) {
                    _roomHeight = v;
                    _calculate();
                  },
                  suffix: 'м',
                  accentColor: accentColor,
                  minValue: 1.5,
                  maxValue: 10,
                ),
              ],
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _walls.length,
              itemBuilder: (context, index) {
                final wall = _walls[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: accentColor.withValues(alpha: 0.1),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 10, color: accentColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CalculatorTextField(
                        label: _loc.translate('putty.input.length'),
                        value: wall.length,
                        onChanged: (v) {
                          wall.length = v;
                          _calculate();
                        },
                        suffix: 'м',
                        accentColor: accentColor,
                        minValue: 0.1,
                        maxValue: 50,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CalculatorTextField(
                        label: _loc.translate('putty.input.height'),
                        value: wall.height,
                        onChanged: (v) {
                          wall.height = v;
                          _calculate();
                        },
                        suffix: 'м',
                        accentColor: accentColor,
                        minValue: 1.5,
                        maxValue: 10,
                      ),
                    ),
                    if (_walls.length > 1)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 18),
                        onPressed: () {
                          setState(() => _walls.removeAt(index));
                          _calculate();
                        },
                      )
                  ]),
                );
              },
            )
        ],
      ),
    );
  }

  Widget _buildOpeningsSection() {
    const accentColor = CalculatorColors.interior;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _loc.translate('putty.section.openings', {'count': _openings.length.toString()}),
                style: CalculatorDesignSystem.titleMedium.copyWith(
                  color: CalculatorColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  setState(() => _openings.add(Opening(id: DateTime.now().toString())));
                  _calculate();
                },
                icon: const Icon(Icons.add, size: 16),
                label: Text(_loc.translate('putty.action.add_opening')),
                style: TextButton.styleFrom(
                  backgroundColor: accentColor.withValues(alpha: 0.1),
                  foregroundColor: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _openings.length,
            itemBuilder: (context, index) {
              final op = _openings[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(children: [
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('putty.input.width'),
                      value: op.width,
                      onChanged: (v) {
                        op.width = v;
                        _calculate();
                      },
                      suffix: 'м',
                      accentColor: accentColor,
                      minValue: 0.1,
                      maxValue: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('putty.input.height'),
                      value: op.height,
                      onChanged: (v) {
                        op.height = v;
                        _calculate();
                      },
                      suffix: 'м',
                      accentColor: accentColor,
                      minValue: 0.1,
                      maxValue: 10,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CalculatorTextField(
                      label: _loc.translate('putty.input.count'),
                      value: op.count.toDouble(),
                      onChanged: (v) {
                        op.count = v.toInt();
                        _calculate();
                      },
                      isInteger: true,
                      suffix: 'шт',
                      accentColor: accentColor,
                      minValue: 1,
                      maxValue: 20,
                    ),
                  ),
                  if (_openings.length > 1)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                      onPressed: () {
                        setState(() => _openings.removeAt(index));
                        _calculate();
                      },
                    )
                ]),
              );
            },
          ),
        ],
      ),
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

    final items = <MaterialItem>[
      MaterialItem(
        name: loc.translate('putty.shopping.start_title'),
        value: '${_result?.startBags} $piecesLabel',
        subtitle: loc.translate('putty.shopping.start_subtitle'),
        icon: Icons.shopping_bag,
      ),
      MaterialItem(
        name: finishTypeLabel,
        value: '${_result?.finishPacks} $piecesLabel',
        subtitle: loc.translate(
          _target == FinishTarget.painting
              ? 'putty.shopping.finish_painting'
              : 'putty.shopping.finish_wallpaper',
        ),
        icon: Icons.inventory_2,
      ),
      MaterialItem(
        name: loc.translate('putty.shopping.primer_title'),
        value: '${_result?.primerCanisters} $piecesLabel',
        subtitle: loc.translate('putty.shopping.primer_subtitle'),
        icon: Icons.water_drop,
      ),
      MaterialItem(
        name: loc.translate('putty.section.abrasive'),
        value: '${_result?.sandingSheets} $piecesLabel',
        icon: Icons.build,
      ),
    ];

    return MaterialsCardModern(
      title: loc.translate('putty.section.shopping_list'),
      titleIcon: Icons.check_circle,
      items: items,
      accentColor: accentColor,
    );
  }

  Widget _buildTipsSection() {
    const hints = [
      CalculatorHint(
        type: HintType.important,
        messageKey: 'hint.putty.layer_thickness',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.putty.sanding',
      ),
      CalculatorHint(
        type: HintType.tip,
        messageKey: 'hint.putty.primer_between',
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
