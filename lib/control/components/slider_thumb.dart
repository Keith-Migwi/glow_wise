import 'package:flutter/material.dart';

class GradientSliderThumbShape extends SliderComponentShape {
  final double radius;
  final List<Color> gradientColors;
  final List<double>? stops;
  final List<BoxShadow> shadows;

  const GradientSliderThumbShape({
    this.radius = 10,
    required this.gradientColors,
    this.stops,
    this.shadows = const [
      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
    ],
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(radius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // ---- Shadow ----
    for (final shadow in shadows) {
      final Paint shadowPaint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      canvas.drawCircle(center + shadow.offset, radius, shadowPaint);
    }

    // ---- Gradient fill ----
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    final Paint paint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        stops: stops,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);

    canvas.drawCircle(center, radius, paint);
  }
}
