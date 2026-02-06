import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../domain/services/room_area_service.dart';

/// Bottom sheet для расчёта площади комнаты и стен
class RoomAreaBottomSheet extends StatefulWidget {
  const RoomAreaBottomSheet({super.key});

  /// Показать bottom sheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const RoomAreaBottomSheet(),
    );
  }

  @override
  State<RoomAreaBottomSheet> createState() => _RoomAreaBottomSheetState();
}

class _RoomAreaBottomSheetState extends State<RoomAreaBottomSheet>
    with SingleTickerProviderStateMixin {
  final _service = RoomAreaService();
  late TabController _tabController;

  // Режим «Комната»
  final _lengthController = TextEditingController(text: '5');
  final _widthController = TextEditingController(text: '4');
  final _heightController = TextEditingController(text: '2.5');
  RoomAreaResult? _roomResult;

  // Режим «Стены»
  final List<_WallEntry> _walls = [_WallEntry()];
  MultiWallResult? _wallsResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateRoom();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    for (final wall in _walls) {
      wall.dispose();
    }
    super.dispose();
  }

  void _calculateRoom() {
    final length = double.tryParse(_lengthController.text) ?? 0;
    final width = double.tryParse(_widthController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;

    if (length > 0 && width > 0 && height > 0) {
      setState(() {
        _roomResult = _service.calculateRoom(
          length: length,
          width: width,
          height: height,
        );
      });
    } else {
      setState(() => _roomResult = null);
    }
  }

  void _calculateWalls() {
    final wallInputs = <WallInput>[];
    for (final wall in _walls) {
      final w = double.tryParse(wall.widthController.text) ?? 0;
      final h = double.tryParse(wall.heightController.text) ?? 0;
      if (w <= 0 || h <= 0) continue;

      final openings = <Opening>[];
      for (final opening in wall.openings) {
        final ow = double.tryParse(opening.widthController.text) ?? 0;
        final oh = double.tryParse(opening.heightController.text) ?? 0;
        if (ow > 0 && oh > 0) {
          openings.add(Opening(width: ow, height: oh));
        }
      }
      wallInputs.add(WallInput(width: w, height: h, openings: openings));
    }

    if (wallInputs.isNotEmpty) {
      setState(() {
        _wallsResult = _service.calculateWalls(wallInputs);
      });
    } else {
      setState(() => _wallsResult = null);
    }
  }

  void _addWall() {
    setState(() {
      _walls.add(_WallEntry());
    });
  }

  void _removeWall(int index) {
    if (_walls.length <= 1) return;
    setState(() {
      _walls[index].dispose();
      _walls.removeAt(index);
      _calculateWalls();
    });
  }

  void _addOpening(int wallIndex) {
    setState(() {
      _walls[wallIndex].openings.add(_OpeningEntry());
    });
  }

  void _removeOpening(int wallIndex, int openingIndex) {
    setState(() {
      _walls[wallIndex].openings[openingIndex].dispose();
      _walls[wallIndex].openings.removeAt(openingIndex);
      _calculateWalls();
    });
  }

  void _copyResult(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).translate('common.copied_to_clipboard')),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        loc.translate('tools.room_area.title'),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),

              // Tabs
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: loc.translate('tools.room_area.tab_room')),
                  Tab(text: loc.translate('tools.room_area.tab_walls')),
                ],
              ),

              const SizedBox(height: 16),

              // Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildRoomTab(scrollController, loc, theme, mediaQuery),
                    _buildWallsTab(scrollController, loc, theme, mediaQuery),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─── Вкладка «Комната» ─────────────────────────

  Widget _buildRoomTab(
    ScrollController scrollController,
    AppLocalizations loc,
    ThemeData theme,
    MediaQueryData mediaQuery,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        // Поля ввода
        _buildInputField(
          controller: _lengthController,
          label: loc.translate('input.length'),
          suffix: 'м',
          onChanged: (_) => _calculateRoom(),
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _widthController,
          label: loc.translate('input.width'),
          suffix: 'м',
          onChanged: (_) => _calculateRoom(),
        ),
        const SizedBox(height: 12),
        _buildInputField(
          controller: _heightController,
          label: loc.translate('input.height'),
          suffix: 'м',
          onChanged: (_) => _calculateRoom(),
        ),

        const SizedBox(height: 24),

        // Результаты
        if (_roomResult != null) ...[
          // Итого
          _buildResultCard(
            theme: theme,
            icon: Icons.square_foot_rounded,
            title: loc.translate('tools.room_area.wall_area'),
            value: '${_roomResult!.totalWallArea} м²',
            isPrimary: true,
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  theme: theme,
                  icon: Icons.grid_on_rounded,
                  title: loc.translate('tools.room_area.floor_area'),
                  value: '${_roomResult!.floorArea} м²',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  theme: theme,
                  icon: Icons.roofing_rounded,
                  title: loc.translate('tools.room_area.ceiling_area'),
                  value: '${_roomResult!.ceilingArea} м²',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildResultCard(
            theme: theme,
            icon: Icons.straighten_rounded,
            title: loc.translate('tools.room_area.perimeter'),
            value: '${_roomResult!.perimeter} м',
          ),

          const SizedBox(height: 16),

          // Разбивка по стенам
          Text(
            loc.translate('tools.room_area.wall_details'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(_roomResult!.walls.length, (i) {
            final wall = _roomResult!.walls[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      theme.colorScheme.secondaryContainer,
                  child: Text(
                    wall.name,
                    style: TextStyle(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  '${wall.width} × ${wall.height} м',
                ),
                trailing: Text(
                  '${wall.grossArea} м²',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          // Кнопка копировать
          FilledButton.tonalIcon(
            onPressed: () => _copyResult(_formatRoomResult(loc)),
            icon: const Icon(Icons.copy_rounded),
            label: Text(loc.translate('common.copy')),
          ),
        ],

        SizedBox(height: mediaQuery.padding.bottom + 16),
      ],
    );
  }

  // ─── Вкладка «Стены» ──────────────────────────

  Widget _buildWallsTab(
    ScrollController scrollController,
    AppLocalizations loc,
    ThemeData theme,
    MediaQueryData mediaQuery,
  ) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        ...List.generate(_walls.length, (wallIndex) {
          final wall = _walls[wallIndex];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок стены
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            theme.colorScheme.secondaryContainer,
                        child: Text(
                          '${wallIndex + 1}',
                          style: TextStyle(
                            color:
                                theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        loc.translate('tools.room_area.wall_n')
                            .replaceAll('{n}', '${wallIndex + 1}'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_walls.length > 1)
                        IconButton(
                          onPressed: () => _removeWall(wallIndex),
                          icon: const Icon(Icons.delete_outline_rounded),
                          iconSize: 20,
                          color: theme.colorScheme.error,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Поля стены
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: wall.widthController,
                          label: loc.translate('input.width'),
                          suffix: 'м',
                          onChanged: (_) => _calculateWalls(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          controller: wall.heightController,
                          label: loc.translate('input.height'),
                          suffix: 'м',
                          onChanged: (_) => _calculateWalls(),
                        ),
                      ),
                    ],
                  ),

                  // Проёмы
                  ...List.generate(wall.openings.length, (oIndex) {
                    final opening = wall.openings[oIndex];
                    return Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.door_front_door_outlined,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              controller: opening.widthController,
                              label: loc.translate('input.width'),
                              suffix: 'м',
                              onChanged: (_) => _calculateWalls(),
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildInputField(
                              controller: opening.heightController,
                              label: loc.translate('input.height'),
                              suffix: 'м',
                              onChanged: (_) => _calculateWalls(),
                              compact: true,
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                _removeOpening(wallIndex, oIndex),
                            icon: const Icon(Icons.close_rounded),
                            iconSize: 18,
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => _addOpening(wallIndex),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(
                      loc.translate('tools.room_area.add_opening'),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        // Кнопка «Добавить стену»
        OutlinedButton.icon(
          onPressed: _addWall,
          icon: const Icon(Icons.add_rounded),
          label: Text(loc.translate('tools.room_area.add_wall')),
        ),

        const SizedBox(height: 24),

        // Результаты
        if (_wallsResult != null && _wallsResult!.walls.isNotEmpty) ...[
          _buildResultCard(
            theme: theme,
            icon: Icons.square_foot_rounded,
            title: loc.translate('tools.room_area.net_area'),
            value: '${_wallsResult!.totalNetArea} м²',
            isPrimary: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildResultCard(
                  theme: theme,
                  icon: Icons.crop_square_rounded,
                  title: loc.translate('tools.room_area.gross_area'),
                  value: '${_wallsResult!.totalGrossArea} м²',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildResultCard(
                  theme: theme,
                  icon: Icons.door_front_door_outlined,
                  title: loc.translate('tools.room_area.openings_area'),
                  value: '${_wallsResult!.totalOpeningsArea} м²',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => _copyResult(_formatWallsResult(loc)),
            icon: const Icon(Icons.copy_rounded),
            label: Text(loc.translate('common.copy')),
          ),
        ],

        SizedBox(height: mediaQuery.padding.bottom + 16),
      ],
    );
  }

  // ─── Виджеты ──────────────────────────────

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required ValueChanged<String> onChanged,
    bool compact = false,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: compact ? 10 : 16,
        ),
        isDense: compact,
      ),
      onChanged: onChanged,
    );
  }

  Widget _buildResultCard({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String value,
    bool isPrimary = false,
  }) {
    return Card(
      color: isPrimary
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isPrimary
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isPrimary
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isPrimary
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Форматирование для копирования ────────────

  String _formatRoomResult(AppLocalizations loc) {
    if (_roomResult == null) return '';
    final r = _roomResult!;
    final buf = StringBuffer();
    buf.writeln(loc.translate('tools.room_area.title'));
    buf.writeln('─────────────────');
    buf.writeln(
        '${loc.translate('input.length')}: ${_lengthController.text} м');
    buf.writeln(
        '${loc.translate('input.width')}: ${_widthController.text} м');
    buf.writeln(
        '${loc.translate('input.height')}: ${_heightController.text} м');
    buf.writeln('');
    buf.writeln(
        '${loc.translate('tools.room_area.floor_area')}: ${r.floorArea} м²');
    buf.writeln(
        '${loc.translate('tools.room_area.ceiling_area')}: ${r.ceilingArea} м²');
    buf.writeln(
        '${loc.translate('tools.room_area.wall_area')}: ${r.totalWallArea} м²');
    buf.writeln(
        '${loc.translate('tools.room_area.perimeter')}: ${r.perimeter} м');
    buf.writeln('');
    for (final wall in r.walls) {
      buf.writeln(
          '${loc.translate('tools.room_area.wall_n').replaceAll('{n}', wall.name)}: ${wall.width}×${wall.height} = ${wall.grossArea} м²');
    }
    return buf.toString();
  }

  String _formatWallsResult(AppLocalizations loc) {
    if (_wallsResult == null) return '';
    final r = _wallsResult!;
    final buf = StringBuffer();
    buf.writeln('${loc.translate('tools.room_area.title')} — ${loc.translate('tools.room_area.tab_walls')}');
    buf.writeln('─────────────────');
    buf.writeln(
        '${loc.translate('tools.room_area.gross_area')}: ${r.totalGrossArea} м²');
    buf.writeln(
        '${loc.translate('tools.room_area.openings_area')}: ${r.totalOpeningsArea} м²');
    buf.writeln(
        '${loc.translate('tools.room_area.net_area')}: ${r.totalNetArea} м²');
    return buf.toString();
  }
}

/// Внутренняя модель одной стены в UI
class _WallEntry {
  final widthController = TextEditingController(text: '4');
  final heightController = TextEditingController(text: '2.5');
  final openings = <_OpeningEntry>[];

  void dispose() {
    widthController.dispose();
    heightController.dispose();
    for (final o in openings) {
      o.dispose();
    }
  }
}

/// Внутренняя модель одного проёма в UI
class _OpeningEntry {
  final widthController = TextEditingController(text: '0.9');
  final heightController = TextEditingController(text: '2.1');

  void dispose() {
    widthController.dispose();
    heightController.dispose();
  }
}
