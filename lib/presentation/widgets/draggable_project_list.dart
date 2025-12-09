import 'package:flutter/material.dart';
import '../../../core/services/haptic_feedback_service.dart';

/// Список проектов с поддержкой drag & drop для сортировки.
class DraggableProjectList extends StatefulWidget {
  final List<ProjectItem> items;
  final Function(List<ProjectItem>) onReorder;

  const DraggableProjectList({
    super.key,
    required this.items,
    required this.onReorder,
  });

  @override
  State<DraggableProjectList> createState() => _DraggableProjectListState();
}

class _DraggableProjectListState extends State<DraggableProjectList> {
  late List<ProjectItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  @override
  void didUpdateWidget(DraggableProjectList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _items = List.from(widget.items);
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
    });

    HapticFeedbackService.medium();
    widget.onReorder(_items);
  }

  @override
  Widget build(BuildContext context) {
    return ReorderableListView(
      onReorder: _onReorder,
      children: _items.map((item) {
        return _DraggableProjectItem(key: ValueKey(item.id), item: item);
      }).toList(),
    );
  }
}

/// Элемент проекта с поддержкой drag & drop.
class _DraggableProjectItem extends StatelessWidget {
  final ProjectItem item;

  const _DraggableProjectItem({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          Icons.drag_handle,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
        title: Text(item.name),
        subtitle: Text(item.description),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }
}

/// Модель элемента проекта.
class ProjectItem {
  final String id;
  final String name;
  final String description;

  ProjectItem({
    required this.id,
    required this.name,
    required this.description,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
