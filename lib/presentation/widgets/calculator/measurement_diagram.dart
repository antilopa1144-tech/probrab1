import 'dart:math' as math;
import 'package:flutter/material.dart';

enum DiagramType {
  room,
  wall,
  floor,
  roof,
}

typedef DiagramLabelFormatter = String Function(String key, double value);

class MeasurementDiagram extends StatelessWidget {
  final DiagramType type;
  final Map<String, double> values;
  final Set<String>? highlights;
  final DiagramLabelFormatter? labelFormatter;
  final double height;

  const MeasurementDiagram({
    super.key,
    required this.type,
    required this.values,
    this.highlights,
    this.labelFormatter,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strokeColor = theme.colorScheme.onSurface.withValues(alpha: 0.4);
    final highlightColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onSurface.withValues(alpha: 0.8);

    final painter = switch (type) {
      DiagramType.room => _RoomPainter(
          values: values,
          highlights: highlights,
          labelFormatter: labelFormatter,
          strokeColor: strokeColor,
          highlightColor: highlightColor,
          textColor: textColor,
        ),
      DiagramType.wall => _WallPainter(
          values: values,
          highlights: highlights,
          labelFormatter: labelFormatter,
          strokeColor: strokeColor,
          highlightColor: highlightColor,
          textColor: textColor,
        ),
      DiagramType.floor => _FloorPainter(
          values: values,
          highlights: highlights,
          labelFormatter: labelFormatter,
          strokeColor: strokeColor,
          highlightColor: highlightColor,
          textColor: textColor,
        ),
      DiagramType.roof => _RoofPainter(
          values: values,
          highlights: highlights,
          labelFormatter: labelFormatter,
          strokeColor: strokeColor,
          highlightColor: highlightColor,
          textColor: textColor,
        ),
    };

    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: painter),
    );
  }
}

abstract class _BaseDiagramPainter extends CustomPainter {
  final Map<String, double> values;
  final Set<String>? highlights;
  final DiagramLabelFormatter? labelFormatter;
  final Color strokeColor;
  final Color highlightColor;
  final Color textColor;

  _BaseDiagramPainter({
    required this.values,
    required this.strokeColor,
    required this.highlightColor,
    required this.textColor,
    this.highlights,
    this.labelFormatter,
  });

  bool isHighlighted(String key) => highlights?.contains(key) ?? false;

  String formatLabel(String key, double value) {
    final formatter = labelFormatter;
    if (formatter != null) return formatter(key, value);
    if (value % 1 == 0) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  void drawLabel(Canvas canvas, Offset position, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(position.dx - painter.width / 2, position.dy - painter.height / 2),
    );
  }

  Paint paintFor(String key) {
    return Paint()
      ..color = isHighlighted(key) ? highlightColor : strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHighlighted(key) ? 3 : 2;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RoomPainter extends _BaseDiagramPainter {
  _RoomPainter({
    required super.values,
    required super.strokeColor,
    required super.highlightColor,
    required super.textColor,
    super.highlights,
    super.labelFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final length = values['length'] ?? 4;
    final width = values['width'] ?? 3;
    final height = values['height'] ?? 2.7;

    final scale = math.min(size.width, size.height) * 0.12;
    final rectWidth = length * scale;
    final rectHeight = width * scale;
    final left = (size.width - rectWidth) / 2;
    final top = (size.height - rectHeight) / 2;

    final rect = Rect.fromLTWH(left, top, rectWidth, rectHeight);
    canvas.drawRect(rect, paintFor('length'));

    final right = rect.topRight + Offset(0, rectHeight);
    canvas.drawLine(
      rect.topRight,
      rect.topRight.translate(0, rectHeight),
      paintFor('height'),
    );

    drawLabel(
      canvas,
      Offset(rect.center.dx, rect.bottom + 12),
      formatLabel('length', length),
    );
    drawLabel(
      canvas,
      Offset(rect.left - 12, rect.center.dy),
      formatLabel('width', width),
    );
    drawLabel(
      canvas,
      Offset(rect.right + 12, rect.center.dy),
      formatLabel('height', height),
    );

    canvas.drawLine(rect.bottomLeft, right, paintFor('width'));
  }
}

class _WallPainter extends _BaseDiagramPainter {
  _WallPainter({
    required super.values,
    required super.strokeColor,
    required super.highlightColor,
    required super.textColor,
    super.highlights,
    super.labelFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = values['width'] ?? values['length'] ?? 4;
    final height = values['height'] ?? 2.7;

    final scale = math.min(size.width, size.height) * 0.2;
    final rectWidth = width * scale;
    final rectHeight = height * scale;
    final left = (size.width - rectWidth) / 2;
    final top = (size.height - rectHeight) / 2;

    final rect = Rect.fromLTWH(left, top, rectWidth, rectHeight);
    canvas.drawRect(rect, paintFor('width'));

    drawLabel(
      canvas,
      Offset(rect.center.dx, rect.bottom + 12),
      formatLabel('width', width),
    );
    drawLabel(
      canvas,
      Offset(rect.right + 12, rect.center.dy),
      formatLabel('height', height),
    );
  }
}

class _FloorPainter extends _BaseDiagramPainter {
  _FloorPainter({
    required super.values,
    required super.strokeColor,
    required super.highlightColor,
    required super.textColor,
    super.highlights,
    super.labelFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final length = values['length'] ?? 4;
    final width = values['width'] ?? 3;

    final scale = math.min(size.width, size.height) * 0.14;
    final rectWidth = length * scale;
    final rectHeight = width * scale;
    final left = (size.width - rectWidth) / 2;
    final top = (size.height - rectHeight) / 2;

    final rect = Rect.fromLTWH(left, top, rectWidth, rectHeight);
    canvas.drawRect(rect, paintFor('length'));

    drawLabel(
      canvas,
      Offset(rect.center.dx, rect.bottom + 12),
      formatLabel('length', length),
    );
    drawLabel(
      canvas,
      Offset(rect.left - 12, rect.center.dy),
      formatLabel('width', width),
    );
  }
}

class _RoofPainter extends _BaseDiagramPainter {
  _RoofPainter({
    required super.values,
    required super.strokeColor,
    required super.highlightColor,
    required super.textColor,
    super.highlights,
    super.labelFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final span = values['span'] ?? values['width'] ?? 6;
    final rise = values['rise'] ?? values['height'] ?? 2;

    final scale = math.min(size.width, size.height) * 0.12;
    final halfSpan = span * scale / 2;
    final roofHeight = rise * scale;
    final centerX = size.width / 2;
    final baseY = size.height * 0.65;

    final left = Offset(centerX - halfSpan, baseY);
    final right = Offset(centerX + halfSpan, baseY);
    final peak = Offset(centerX, baseY - roofHeight);

    final paint = paintFor('span');
    canvas.drawLine(left, right, paint);
    canvas.drawLine(left, peak, paintFor('rise'));
    canvas.drawLine(right, peak, paintFor('rise'));

    drawLabel(
      canvas,
      Offset(centerX, baseY + 12),
      formatLabel('span', span),
    );
    drawLabel(
      canvas,
      Offset(centerX + halfSpan + 12, baseY - roofHeight / 2),
      formatLabel('rise', rise),
    );
  }
}
