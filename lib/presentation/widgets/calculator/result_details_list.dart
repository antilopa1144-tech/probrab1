import 'package:flutter/material.dart';
import 'result_row.dart';

class ResultDetailsList extends StatelessWidget {
  final List<ResultRowData> items;
  final EdgeInsetsGeometry? padding;

  const ResultDetailsList({
    super.key,
    required this.items,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      children.add(ResultRow(data: items[i]));
      if (i < items.length - 1) {
        children.add(const SizedBox(height: 12));
      }
    }

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}
