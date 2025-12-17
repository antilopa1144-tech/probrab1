import 'package:flutter/material.dart';

class ResultsSheet extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const ResultsSheet({
    super.key,
    required this.title,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final String? subLabel;

  const ResultRow(
    this.label,
    this.value, {
    super.key,
    this.subValue,
    this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
                if (subLabel != null)
                  Text(
                    subLabel!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
              if (subValue != null)
                Text(
                  subValue!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
