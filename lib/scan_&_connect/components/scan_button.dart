import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

class ScanButton extends StatefulWidget {
  final bool isScanning;
  final VoidCallback onClick;

  const ScanButton({
    super.key,
    required this.isScanning,
    required this.onClick,
  });

  @override
  State<ScanButton> createState() => _ScanButtonState();
}

class _ScanButtonState extends State<ScanButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinnerController;
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = 1.0;

    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.isScanning) {
      _spinnerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ScanButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isScanning && !_spinnerController.isAnimating) {
      _spinnerController.repeat();
    } else if (!widget.isScanning && _spinnerController.isAnimating) {
      _spinnerController.stop();
    }
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isScanning = widget.isScanning;

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.98),
      onTapUp: (_) => setState(() => _scale = 1.0),
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: widget.onClick,
      child: MouseRegion(
        onEnter: (_) => setState(() => _scale = 1.02),
        onExit: (_) => setState(() => _scale = 1.0),
        child: Transform.scale(
          scale: _scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isScanning ? Color(0xFF242424) : null,
              gradient: isScanning
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFF06B6D4), Color(0xFF8B5CF6)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
              boxShadow: isScanning
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0x8022D3EE),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isScanning)
                    SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 1,
                        color: Colors.grey.shade300,
                      ),
                    )
                  else
                    Icon(LucideIcons.search, size: 22, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    isScanning ? "Stop Scan" : "Start Scan",
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: isScanning ? Colors.grey.shade300 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
