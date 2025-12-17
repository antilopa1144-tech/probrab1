import 'package:flutter/material.dart';

class CementIcon extends StatelessWidget {
  final double size;
  final Color color;

  const CementIcon({super.key, this.size = 24.0, this.color = Colors.black});

  @override
  Widget build(BuildContext context) {
    // Using a standard Material icon as a substitute for a custom path icon.
    // The 'layers' icon is a good representation for screed/plaster.
    return Icon(
      Icons.layers,
      size: size,
      color: color,
    );
  }
}
