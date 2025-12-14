import 'package:flutter/material.dart';

class ScanningIndicator extends StatefulWidget {
  final bool isScanning;

  const ScanningIndicator({super.key, required this.isScanning});

  @override
  State<ScanningIndicator> createState() => _ScanningIndicatorState();
}

class _ScanningIndicatorState extends State<ScanningIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _ripple1Controller;
  late final AnimationController _ripple2Controller;
  late final AnimationController _ripple3Controller;
  late final AnimationController _centerPulseController;

  @override
  void initState() {
    super.initState();

    _ripple1Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ripple2Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _ripple3Controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _centerPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    if (widget.isScanning) _startAnimations();
  }

  void _startAnimations() {
    _ripple1Controller.repeat();
    Future.delayed(const Duration(milliseconds: 400), () {
      _ripple2Controller.repeat();
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      _ripple3Controller.repeat();
    });

    _centerPulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant ScanningIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !oldWidget.isScanning) {
      _startAnimations();
    } else if (!widget.isScanning && oldWidget.isScanning) {
      _ripple1Controller.stop();
      _ripple2Controller.stop();
      _ripple3Controller.stop();
      _centerPulseController.stop();
    }
  }

  @override
  void dispose() {
    _ripple1Controller.dispose();
    _ripple2Controller.dispose();
    _ripple3Controller.dispose();
    _centerPulseController.dispose();
    super.dispose();
  }

  Widget _buildRipple(AnimationController controller, Color color) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final scale = 0.8 + (1.2 * controller.value); // 0.8 → 2.0
        final opacity = 0.8 * (1 - controller.value);
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterIcon() {
    final bool scanning = widget.isScanning;

    final scale = scanning
        ? Tween(begin: 1.0, end: 1.05).animate(
            CurvedAnimation(
              parent: _centerPulseController,
              curve: Curves.easeInOut,
            ),
          )
        : const AlwaysStoppedAnimation(1.0);

    final bgColor = scanning ? null : Color(0xFF242424);
    final gradient = scanning
        ? const LinearGradient(
            colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final ringColor = scanning ? Colors.white : Color(0xFF6B7280);

    return ScaleTransition(
      scale: scale,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: bgColor,
          gradient: gradient,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ring 1
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2),
                ),
              ),
              // Outer ring 2
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ringColor, width: 2),
                ),
              ),
              // Inner solid circle
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ringColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulsing rings only if scanning
          if (widget.isScanning) ...[
            _buildRipple(_ripple1Controller, Colors.cyan[400]!),
            _buildRipple(_ripple2Controller, Colors.purple[400]!),
            _buildRipple(_ripple3Controller, Colors.cyan[400]!),
          ],
          // Center icon always visible, color changes based on scanning state
          _buildCenterIcon(),
        ],
      ),
    );
  }
}
