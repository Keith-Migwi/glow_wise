import 'package:flutter/material.dart';
import 'package:led/control/components/slider_thumb.dart';

class BrightnessControl extends StatefulWidget {
  final double initialBrightness;
  final ValueChanged<double>? onChanged;

  const BrightnessControl({
    super.key,
    this.initialBrightness = 50,
    this.onChanged,
  });

  @override
  State<BrightnessControl> createState() => _BrightnessControlState();
}

class _BrightnessControlState extends State<BrightnessControl> {
  late double _brightness;

  @override
  void initState() {
    super.initState();
    _brightness = widget.initialBrightness;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text(
            'Brightness',
            style: TextStyle(
              color: Colors.grey.shade300,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Slider Container
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              // Label + Value
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.wb_sunny_outlined,
                        size: 18,
                        color: Colors.grey.shade500,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Brightness',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_brightness.toInt()}%',
                    style: TextStyle(
                      color: Colors.grey.shade200,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 12,
                  thumbShape: GradientSliderThumbShape(
                    radius: 10,
                    gradientColors: [Color(0xFF06B6D4), Color(0xFF9333EA)],
                    shadows: [
                      BoxShadow(
                        color: Color(0xFF9333EA).withValues(alpha: 0.1),
                        blurRadius: 5,
                        spreadRadius: -1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),
                  activeTrackColor: const Color(0xFF22D3EE),
                  inactiveTrackColor: const Color(0xFF242424),
                  padding: EdgeInsets.zero,
                ),
                child: Slider(
                  min: 1,
                  max: 100,
                  value: _brightness,
                  onChanged: (value) {
                    setState(() {
                      _brightness = value;
                    });
                    if (widget.onChanged != null) {
                      widget.onChanged!(value);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
