import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:led/control/components/brightness_control.dart';
import 'package:led/control/components/color_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:led/control/components/power_button.dart';

class Dashboard extends StatefulWidget {
  final bool isOn;
  final DiscoveredDevice device;
  final FlutterReactiveBle ble;
  final bool sandbox;
  const Dashboard({
    super.key,
    required this.device,
    required this.ble,
    required this.sandbox,
    required this.isOn,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowFadeController;
  late Animation<double> _glowOpacity;

  String _selectedColor = "#FFFFFF";

  late QualifiedCharacteristic controlChar;

  Timer? _debounce;

  void _onColorChanged(String hexColor) {
    // Cancel previous timer
    _debounce?.cancel();

    // Send brightness after short delay (50–100ms)
    _debounce = Timer(const Duration(milliseconds: 80), () {
      _setColor(hexColor);
    });
  }

  void _onSliderChanged(double value) {
    // Cancel previous timer
    _debounce?.cancel();

    // Send brightness after short delay (50–100ms)
    _debounce = Timer(const Duration(milliseconds: 80), () {
      _setBrightness(value.toInt());
    });
  }

  @override
  void initState() {
    super.initState();

    controlChar = QualifiedCharacteristic(
      deviceId: widget.device.id,
      serviceId: Uuid.parse("FFE0"),
      characteristicId: Uuid.parse("FFE1"),
    );

    // Bulb breathing / pulsing animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Glow fade-out when powering off
    _glowFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _glowOpacity = CurvedAnimation(
      parent: _glowFadeController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOn) {
      _glowFadeController.forward(from: 0);
    } else {
      _glowFadeController.reverse(from: 1);
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 10, right: 10, top: 30),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 30,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseController,
                    _glowFadeController,
                  ]),
                  builder: (_, __) {
                    final glow = 100 + (_pulseController.value * 50);
                    double scale = 1.0 + (_pulseController.value * 0.08);

                    if (!widget.isOn) {
                      scale = 1.0;
                    }

                    HSV hsv = rgbToHsv(_selectedColor);

                    final selectedColor = HSVColor.fromAHSV(
                      1,
                      hsv.h,
                      hsv.s / 100,
                      hsv.v / 100,
                    ).toColor();

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        height: 96,
                        width: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.isOn
                              ? selectedColor
                              : const Color(0xFF1E1E1E),
                          boxShadow: [
                            if (_glowOpacity.value > 0)
                              BoxShadow(
                                color: selectedColor.withValues(
                                  alpha: _glowOpacity.value,
                                ),
                                blurRadius: glow,
                                spreadRadius: glow / 15,
                              ),
                          ],
                        ),
                        child: Icon(
                          LucideIcons.lightbulb,
                          size: 48,
                          color: widget.isOn
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),

              ColorPicker(
                selectedColor: _selectedColor,
                isOn: widget.isOn,
                onColorChange: (String value) {
                  setState(() {
                    _selectedColor = value;
                  });
                  _onColorChanged(value);
                },
                presetColors: [
                  "#FFFFFF",
                  "#000000",
                  "#FF0000",
                  "#22D3EE",
                  "#10B981",
                  "#6366F1",
                ],
              ),

              BrightnessControl(
                isOn: widget.isOn,
                initialBrightness: 50,
                onChanged: _onSliderChanged,
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _setBrightness(int value) async {
    if (!widget.sandbox) {
      // Clamp to 1-100
      if (value < 1) value = 1;
      if (value > 100) value = 100;

      // Map 1-100% linearly to second byte (0x05 to 0x5f as example)
      final minByte = 0x05;
      final maxByte = 0x5F;
      final brightnessByte =
          (minByte + ((value - 1) / 99 * (maxByte - minByte))).round();

      final data = Uint8List.fromList([
        0x7B, // start
        0xFF,
        0x01, // brightness command
        0x1E, // fixed first byte
        brightnessByte, // second byte = brightness
        0x00, // third byte
        0xFF,
        0xFF,
        0xBF,
      ]);

      await widget.ble.writeCharacteristicWithResponse(
        controlChar,
        value: data,
      );
    }
  }

  Future<void> _setColor(String hexColor) async {
    if (!widget.sandbox) {
      // Remove leading #
      final hex = hexColor.replaceFirst('#', '');

      if (hex.length != 6) {
        throw ArgumentError('Invalid color format: $hexColor');
      }

      // Parse RGB
      final r = int.parse(hex.substring(0, 2), radix: 16);
      final g = int.parse(hex.substring(2, 4), radix: 16);
      final b = int.parse(hex.substring(4, 6), radix: 16);

      final data = Uint8List.fromList([
        0x7B, // start
        0xFF,
        0x07, // color command
        r, // red
        g, // green
        b, // blue
        0xFF, // reserved
        0xFF, // reserved
        0xBF, // end
      ]);

      await widget.ble.writeCharacteristicWithResponse(
        controlChar,
        value: data,
      );
    }
  }
}
