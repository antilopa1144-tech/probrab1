import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const LoadingIndicator({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      strokeWidth: strokeWidth,
      valueColor: color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Center(child: indicator),
    );
  }
}
