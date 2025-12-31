import 'package:flutter/material.dart';
import 'package:led/control/components/slider_thumb.dart';

class BrightnessControl extends StatefulWidget {
  final double initialBrightness;
  final ValueChanged<double>? onChanged;
  final bool isOn;

  const BrightnessControl({
    super.key,
    this.initialBrightness = 50,
    this.onChanged,
    required this.isOn,
  });

  @override
  State<BrightnessControl> createState() => _BrightnessControlState();
}

class _BrightnessControlState extends State<BrightnessControl> {
  late double _brightness;

  bool get enabled => widget.isOn;

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
          padding: const EdgeInsets.only(bottom: 10),
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
                        color: enabled
                            ? Colors.grey.shade500
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Brightness',
                        style: TextStyle(
                          color: enabled
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${_brightness.toInt()}%',
                    style: TextStyle(
                      color: enabled
                          ? Colors.grey.shade200
                          : Colors.grey.shade600,
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
                              color: const Color(
                                0xFF9333EA,
                              ).withValues(alpha: 0.1),
                              blurRadius: 5,
                              spreadRadius: -1,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),

                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 20,
                  ),

                  disabledActiveTrackColor: Colors.grey.shade600,
                  disabledInactiveTrackColor: Colors.grey.shade900,

                  // 🔑 KEY FIX
                  activeTrackColor: const Color(0xFF22D3EE),
                  inactiveTrackColor: const Color(0xFF242424),

                  padding: EdgeInsets.zero,
                ),
                child: Slider(
                  min: 1,
                  max: 100,
                  value: _brightness,
                  onChanged: enabled
                      ? (value) {
                          setState(() {
                            _brightness = value;
                          });
                          if (widget.onChanged != null) {
                            widget.onChanged!(value);
                          }
                        }
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
