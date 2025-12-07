import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Виджет для отображения круговой диаграммы материалов.
class MaterialPieChart extends StatelessWidget {
  final Map<String, double> materials;
  final Map<String, Color>? colorMap;

  const MaterialPieChart({super.key, required this.materials, this.colorMap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = materials.values.fold(0.0, (sum, value) => sum + value);

    if (total == 0) {
      return Center(
        child: Text(
          'Нет данных',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    final colors = _generateColors(materials.keys.length, theme);
    double startAngle = -math.pi / 2;

    return CustomPaint(
      size: const Size(200, 200),
      painter: _PieChartPainter(
        materials: materials,
        total: total,
        colors: colors,
        startAngle: startAngle,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Материалы', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...materials.entries.asMap().entries.map((entry) {
              final index = entry.key;
              final material = entry.value;
              final percentage = (material.value / total * 100).toStringAsFixed(
                1,
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${material.key}: $percentage%',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Color> _generateColors(int count, ThemeData theme) {
    final defaultColors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final colors = <Color>[];
    for (int i = 0; i < count; i++) {
      if (colorMap != null &&
          colorMap!.containsKey(materials.keys.elementAt(i))) {
        colors.add(colorMap![materials.keys.elementAt(i)]!);
      } else {
        colors.add(defaultColors[i % defaultColors.length]);
      }
    }
    return colors;
  }
}

/// Художник для рисования круговой диаграммы.
class _PieChartPainter extends CustomPainter {
  final Map<String, double> materials;
  final double total;
  final List<Color> colors;
  final double startAngle;

  _PieChartPainter({
    required this.materials,
    required this.total,
    required this.colors,
    required this.startAngle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    double currentAngle = startAngle;
    int colorIndex = 0;

    for (final entry in materials.entries) {
      final sweepAngle = 2 * math.pi * (entry.value / total);
      final paint = Paint()
        ..color = colors[colorIndex % colors.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        true,
        paint,
      );

      currentAngle += sweepAngle;
      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) {
    return oldDelegate.materials != materials || oldDelegate.total != total;
  }
}

/// Виджет для отображения столбчатой диаграммы стоимости.
class CostBarChart extends StatelessWidget {
  final Map<String, double> costs;
  final String? title;

  const CostBarChart({super.key, required this.costs, this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxCost = costs.values.isEmpty ? 1.0 : costs.values.reduce(math.max);

    if (maxCost == 0) {
      return Center(
        child: Text(
          'Нет данных',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(title!, style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
            ],
            ...costs.entries.map((entry) {
              final percentage = entry.value / maxCost;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${entry.value.toStringAsFixed(0)} ₽',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
