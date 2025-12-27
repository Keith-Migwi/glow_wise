import 'package:flutter/material.dart';
import 'dart:math';

/// ====================
/// HSV MODEL
/// ====================
class HSV {
  double h; // 0–360
  double s; // 0–100
  double v; // 0–100

  HSV({required this.h, required this.s, required this.v});
}

/// ====================
/// COLOR PICKER
/// ====================
class ColorPicker extends StatefulWidget {
  final String selectedColor;
  final ValueChanged<String> onColorChange;
  final List<String> presetColors;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChange,
    required this.presetColors,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSV hsv;

  @override
  void initState() {
    super.initState();
    hsv = rgbToHsv(widget.selectedColor);
  }

  @override
  void didUpdateWidget(covariant ColorPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedColor != widget.selectedColor) {
      hsv = rgbToHsv(widget.selectedColor);
    }
  }

  /// ====================
  /// HUE UPDATE
  /// ====================
  void _updateHue(Offset localPos, Size size) {
    final center = size.center(Offset.zero);
    final dx = localPos.dx - center.dx;
    final dy = localPos.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final radius = size.width / 2;

    if (distance >= radius * 0.65 && distance <= radius) {
      final angle = atan2(dy, dx);
      final hue = ((angle * 180 / pi) + 90 + 360) % 360;

      setState(() => hsv.h = hue);
      widget.onColorChange(hsvToRgb(hsv));
    }
  }

  /// ====================
  /// SV UPDATE
  /// ====================
  void _updateSV(Offset localPos, Size size) {
    final width = size.width;
    final height = size.height;

    final dx = localPos.dx.clamp(0.0, width);
    final dy = localPos.dy.clamp(0.0, height);

    final s = (dx / width) * 100;
    final v = (1 - dy / height) * 100;

    setState(() {
      hsv.s = s;
      hsv.v = v;
    });

    widget.onColorChange(hsvToRgb(hsv));
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = HSVColor.fromAHSV(
      1,
      hsv.h,
      hsv.s / 100,
      hsv.v / 100,
    ).toColor();

    final hueAngle = (hsv.h - 90) * pi / 180;
    final svRadius = 112 / 2;
    final thumbLeft = (hsv.s / 100) * 112;
    final thumbTop = (1 - hsv.v / 100) * 112;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ====================
        // Preview Circle
        // ====================
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: selectedColor,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF242424), width: 4),
            boxShadow: [
              BoxShadow(color: selectedColor.withOpacity(0.3), blurRadius: 30),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ====================
        // Wheels
        // ====================
        SizedBox(
          width: 192,
          height: 192,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Hue Wheel
              GestureDetector(
                onPanDown: (d) =>
                    _updateHue(d.localPosition, const Size(192, 192)),
                onPanUpdate: (d) =>
                    _updateHue(d.localPosition, const Size(192, 192)),
                child: CustomPaint(
                  size: const Size(192, 192),
                  painter: HueWheelPainter(),
                ),
              ),
              // Hue Thumb
              Transform.translate(
                offset: Offset(cos(hueAngle) * 88, sin(hueAngle) * 88),
                child: _Thumb(
                  color: HSVColor.fromAHSV(1, hsv.h, 1, 1).toColor(),
                ),
              ),

              // SV Wheel
              SizedBox(
                width: 112,
                height: 112,
                child: GestureDetector(
                  onPanDown: (d) =>
                      _updateSV(d.localPosition, const Size(112, 112)),
                  onPanUpdate: (d) =>
                      _updateSV(d.localPosition, const Size(112, 112)),
                  child: ClipOval(
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: const Size(112, 112),
                          painter: SVWheelPainter(hsv.h),
                        ),
                        // SV Thumb
                        Positioned(
                          left: thumbLeft.clamp(0.0, 112) - 8,
                          top: thumbTop.clamp(0.0, 112) - 8,
                          child: _Thumb(color: selectedColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Sliders
        _slider(
          label: 'Hue',
          value: hsv.h,
          max: 360,
          gradient: const LinearGradient(
            colors: [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
          ),
          onChanged: (v) {
            setState(() => hsv.h = v);
            widget.onColorChange(hsvToRgb(hsv));
          },
        ),
        _slider(
          label: 'Saturation',
          value: hsv.s,
          max: 100,
          gradient: LinearGradient(
            colors: [
              HSVColor.fromAHSV(1, hsv.h, 0, hsv.v / 100).toColor(),
              HSVColor.fromAHSV(1, hsv.h, 1, hsv.v / 100).toColor(),
            ],
          ),
          onChanged: (v) {
            setState(() => hsv.s = v);
            widget.onColorChange(hsvToRgb(hsv));
          },
        ),
        _slider(
          label: 'Brightness',
          value: hsv.v,
          max: 100,
          gradient: LinearGradient(
            colors: [
              HSVColor.fromAHSV(1, hsv.h, hsv.s / 100, 0).toColor(),
              HSVColor.fromAHSV(1, hsv.h, hsv.s / 100, 1).toColor(),
            ],
          ),
          onChanged: (v) {
            setState(() => hsv.v = v);
            widget.onColorChange(hsvToRgb(hsv));
          },
        ),
        const SizedBox(height: 16),

        // Presets
        GridView.count(
          shrinkWrap: true,
          crossAxisCount: 6,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          physics: const NeverScrollableScrollPhysics(),
          children: widget.presetColors.map((c) {
            final isActive =
                widget.selectedColor.toLowerCase() == c.toLowerCase();
            return GestureDetector(
              onTap: () {
                setState(() => hsv = rgbToHsv(c));
                widget.onColorChange(c);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Color(int.parse(c.replaceFirst('#', '0xff'))),
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? Border.all(color: Colors.cyan, width: 2)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double max,
    required Gradient gradient,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(
              value.round().toString(),
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbColor: Colors.white,
            trackShape: GradientSliderTrackShape(gradient),
          ),
          child: Slider(min: 0, max: max, value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}

/// ====================
/// THUMB
/// ====================
class _Thumb extends StatelessWidget {
  final Color color;

  const _Thumb({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black45)],
      ),
    );
  }
}

/// ====================
/// HUE WHEEL
/// ====================
class HueWheelPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3;

    final ringRadius = radius - paint.strokeWidth / 2;

    for (int i = 0; i < 360; i++) {
      paint.color = HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor();
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        (i - 90) * pi / 180,
        pi / 180,
        false,
        paint,
      );
    }

    canvas.drawCircle(
      center,
      radius * 0.33,
      Paint()..color = const Color(0xFF1E1E1E),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}

/// ====================
/// SV WHEEL
/// ====================
class SVWheelPainter extends CustomPainter {
  final double hue;

  const SVWheelPainter(this.hue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Saturation gradient: left to right
    paint.shader = LinearGradient(
      colors: [Colors.white, HSVColor.fromAHSV(1, hue, 1, 1).toColor()],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    // Value gradient: bottom to top, multiply to darken properly
    paint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Colors.black, Colors.transparent],
    ).createShader(Offset.zero & size);
    paint.blendMode = BlendMode.multiply;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant SVWheelPainter old) => old.hue != hue;
}

/// ====================
/// SLIDER TRACK
/// ====================
class GradientSliderTrackShape extends RoundedRectSliderTrackShape {
  final Gradient gradient;

  GradientSliderTrackShape(this.gradient);

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    double additionalActiveTrackHeight = 2,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required Offset thumbCenter,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    ).shift(offset);

    final paint = Paint()..shader = gradient.createShader(rect);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
      paint,
    );
  }
}

/// ====================
/// COLOR UTILS
/// ====================
HSV rgbToHsv(String hex) {
  final c = Color(int.parse(hex.replaceFirst('#', '0xff')));
  final hsv = HSVColor.fromColor(c);
  return HSV(h: hsv.hue, s: hsv.saturation * 100, v: hsv.value * 100);
}

String hsvToRgb(HSV hsv) {
  final color = HSVColor.fromAHSV(1, hsv.h, hsv.s / 100, hsv.v / 100).toColor();
  return '#${color.value.toRadixString(16).substring(2)}';
}
