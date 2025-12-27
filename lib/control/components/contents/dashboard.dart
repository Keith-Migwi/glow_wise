import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:led/control/components/brightness_control.dart';
import 'package:led/control/components/color_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:led/control/components/power_button.dart';

class Dashboard extends StatefulWidget {
  final DiscoveredDevice device;
  final FlutterReactiveBle ble;
  final bool sandbox;
  const Dashboard({
    super.key,
    required this.device,
    required this.ble,
    required this.sandbox,
  });

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _glowFadeController;
  late Animation<double> _glowOpacity;

  bool _isPoweredOn = false;
  final Color _selectedColor = const Color(0xFF22D3EE);

  late QualifiedCharacteristic controlChar;

  Timer? _debounce;

  void onSliderChanged(double value) {
    // Cancel previous timer
    _debounce?.cancel();

    // Send brightness after short delay (50–100ms)
    _debounce = Timer(const Duration(milliseconds: 80), () {
      setBrightness(value.toInt());
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

  void _togglePower() {
    setState(() {
      _isPoweredOn = !_isPoweredOn;

      if (_isPoweredOn) {
        _glowFadeController.forward(from: 0);
      } else {
        _glowFadeController.reverse(from: 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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

                    if (!_isPoweredOn) {
                      scale = 1.0;
                    }

                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        height: 96,
                        width: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isPoweredOn
                              ? _selectedColor
                              : const Color(0xFF1E1E1E),
                          boxShadow: [
                            if (_glowOpacity.value > 0)
                              BoxShadow(
                                color: _selectedColor.withValues(
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
                          color: _isPoweredOn
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ),

              PowerButton(
                isPoweredOn: _isPoweredOn,
                onClick: () {
                  if (_isPoweredOn) {
                    powerOff();
                  } else {
                    powerOn();
                  }

                  _togglePower();
                },
              ),

              BrightnessControl(
                initialBrightness: 50,
                onChanged: onSliderChanged,
              ),

              ColorPicker(
                selectedColor: "#22D3EE",
                onColorChange: (String value) {},
                presetColors: [
                  "#FFFFFF",
                  "#000000",
                  "#FF0000",
                  "#22D3EE",
                  "#10B981",
                  "#6366F1",
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> powerOn() async {
    if (widget.sandbox) return;

    await widget.ble.writeCharacteristicWithResponse(
      controlChar,
      value: Uint8List.fromList([
        0x7B,
        0xFF,
        0x04,
        0x01,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xBF,
      ]),
    );
  }

  Future<void> powerOff() async {
    if (widget.sandbox) return;

    await widget.ble.writeCharacteristicWithResponse(
      controlChar,
      value: Uint8List.fromList([
        0x7B,
        0xFF,
        0x04,
        0x00,
        0xFF,
        0xFF,
        0xFF,
        0xFF,
        0xBF,
      ]),
    );
  }

  Future<void> setBrightness(int value) async {
    if (widget.sandbox) return;

    // Clamp to 1-100
    if (value < 1) value = 1;
    if (value > 100) value = 100;

    // Map 1-100% linearly to second byte (0x05 to 0x5f as example)
    final minByte = 0x05;
    final maxByte = 0x5F;
    final brightnessByte = (minByte + ((value - 1) / 99 * (maxByte - minByte)))
        .round();

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

    await widget.ble.writeCharacteristicWithResponse(controlChar, value: data);
  }
}
