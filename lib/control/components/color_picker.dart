import 'package:flutter/material.dart';
import 'dart:math';

import 'package:led/control/components/slider_thumb.dart';

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
  final bool isOn;

  const ColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorChange,
    required this.presetColors,
    required this.isOn,
  });

  @override
  State<ColorPicker> createState() => _ColorPickerState();
}

class _ColorPickerState extends State<ColorPicker> {
  late HSV hsv;

  static const double hueSize = 192;
  static const double svSize = 90;

  bool get enabled => widget.isOn;

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
    if (!enabled) return;

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
    if (!enabled) return;

    final dx = localPos.dx.clamp(0.0, size.width);
    final dy = localPos.dy.clamp(0.0, size.height);

    setState(() {
      hsv.s = (dx / size.width) * 100;
      hsv.v = (1 - dy / size.height) * 100;
    });

    widget.onColorChange(hsvToRgb(hsv));
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = enabled
        ? HSVColor.fromAHSV(1, hsv.h, hsv.s / 100, hsv.v / 100).toColor()
        : Colors.grey.shade500;

    final hueAngle = (hsv.h - 90) * pi / 180;

    final thumbLeft = (hsv.s / 100) * svSize;
    final thumbTop = (1 - hsv.v / 100) * svSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Text(
            'Color',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: hueSize,
                height: hueSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    GestureDetector(
                      onPanDown: enabled
                          ? (d) => _updateHue(
                              d.localPosition,
                              const Size(hueSize, hueSize),
                            )
                          : null,
                      onPanUpdate: enabled
                          ? (d) => _updateHue(
                              d.localPosition,
                              const Size(hueSize, hueSize),
                            )
                          : null,
                      child: CustomPaint(
                        size: const Size(hueSize, hueSize),
                        painter: HueWheelPainter(enabled: enabled),
                      ),
                    ),

                    Transform.translate(
                      offset: Offset(cos(hueAngle) * 88, sin(hueAngle) * 88),
                      child: _Thumb(
                        color: enabled
                            ? HSVColor.fromAHSV(1, hsv.h, 1, 1).toColor()
                            : Colors.grey.shade600,
                      ),
                    ),

                    SizedBox(
                      width: svSize,
                      height: svSize,
                      child: GestureDetector(
                        onPanDown: enabled
                            ? (d) => _updateSV(
                                d.localPosition,
                                const Size(svSize, svSize),
                              )
                            : null,
                        onPanUpdate: enabled
                            ? (d) => _updateSV(
                                d.localPosition,
                                const Size(svSize, svSize),
                              )
                            : null,
                        child: Stack(
                          children: [
                            CustomPaint(
                              size: const Size(svSize, svSize),
                              painter: SVSquarePainter(hsv.h, enabled: enabled),
                            ),
                            Positioned(
                              left: thumbLeft.clamp(0.0, svSize) - 8,
                              top: thumbTop.clamp(0.0, svSize) - 8,
                              child: _Thumb(color: selectedColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              _slider(
                label: 'Hue',
                value: hsv.h,
                max: 360,
                enabled: enabled,
                gradient: enabled
                    ? const LinearGradient(
                        colors: [
                          Colors.red,
                          Colors.yellow,
                          Colors.green,
                          Colors.cyan,
                          Colors.blue,
                          Colors.purple,
                          Colors.red,
                        ],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade700, Colors.grey.shade500],
                      ),
                onChanged: enabled
                    ? (v) {
                        setState(() => hsv.h = v);
                        widget.onColorChange(hsvToRgb(hsv));
                      }
                    : null,
              ),

              _slider(
                label: 'Saturation',
                value: hsv.s,
                max: 100,
                enabled: enabled,
                gradient: LinearGradient(
                  colors: enabled
                      ? [
                          HSVColor.fromAHSV(1, hsv.h, 0, hsv.v / 100).toColor(),
                          HSVColor.fromAHSV(1, hsv.h, 1, hsv.v / 100).toColor(),
                        ]
                      : [Colors.grey.shade700, Colors.grey.shade500],
                ),
                onChanged: enabled
                    ? (v) {
                        setState(() => hsv.s = v);
                        widget.onColorChange(hsvToRgb(hsv));
                      }
                    : null,
              ),

              _slider(
                label: 'Brightness',
                value: hsv.v,
                max: 100,
                enabled: enabled,
                gradient: enabled
                    ? LinearGradient(
                        colors: [
                          Colors.black,
                          HSVColor.fromAHSV(1, hsv.h, hsv.s / 100, 1).toColor(),
                        ],
                      )
                    : LinearGradient(
                        colors: [Colors.grey.shade800, Colors.grey.shade500],
                      ),
                onChanged: enabled
                    ? (v) {
                        setState(() => hsv.v = v);
                        widget.onColorChange(hsvToRgb(hsv));
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slider({
    required String label,
    required double value,
    required double max,
    required Gradient gradient,
    required bool enabled,
    required ValueChanged<double>? onChanged,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey.shade400)),
            Text(
              value.round().toString(),
              style: TextStyle(
                color: enabled ? Colors.white : Colors.grey.shade500,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            // Thumb
            thumbShape: GradientSliderThumbShape(
              radius: 10,
              gradientColors: enabled
                  ? const [Color(0xFF06B6D4), Color(0xFF9333EA)]
                  : [Colors.grey.shade400, Colors.grey.shade500],
              shadows: enabled
                  ? [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.1),
                        blurRadius: 5,
                        spreadRadius: -1,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),

            thumbColor: enabled ? Colors.white : Colors.grey.shade600,
            trackShape: GradientSliderTrackShape(gradient),
            padding: EdgeInsets.symmetric(vertical: 5),
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
  final bool enabled;

  HueWheelPainter({required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.3;

    final ringRadius = radius - paint.strokeWidth / 2;

    for (int i = 0; i < 360; i++) {
      paint.color = enabled
          ? HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor()
          : Colors.grey.shade600;
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
/// SV SQUARE
/// ====================
class SVSquarePainter extends CustomPainter {
  final double hue;
  final bool enabled;

  const SVSquarePainter(this.hue, {required this.enabled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    paint.shader = LinearGradient(
      colors: enabled
          ? [Colors.white, HSVColor.fromAHSV(1, hue, 1, 1).toColor()]
          : [Colors.grey.shade700, Colors.grey.shade500],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, paint);

    paint.shader = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: enabled
          ? [Colors.black, Colors.transparent]
          : [Colors.black54, Colors.transparent],
    ).createShader(Offset.zero & size);
    paint.blendMode = BlendMode.multiply;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant SVSquarePainter old) =>
      old.hue != hue || old.enabled != enabled;
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
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    required RenderBox parentBox,
    Offset? secondaryOffset,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required Offset thumbCenter,
    double additionalActiveTrackHeight = 2,
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
