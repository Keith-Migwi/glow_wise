import 'package:flutter/material.dart';

class PowerButton extends StatefulWidget {
  final bool isPoweredOn;
  final VoidCallback onClick;

  const PowerButton({
    super.key,
    required this.isPoweredOn,
    required this.onClick,
  });

  @override
  State<PowerButton> createState() => _PowerButtonState();
}

class _PowerButtonState extends State<PowerButton>
    with SingleTickerProviderStateMixin {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = 1.0;
  }

  @override
  Widget build(BuildContext context) {
    final isPoweredOn = widget.isPoweredOn;

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
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: !isPoweredOn ? Color(0xFF1E1E1E) : null,
              gradient: !isPoweredOn
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF06B6D4), // cyan-500
                        Color(0xFF9333EA), // purple-600
                      ],
                    ),
              boxShadow: !isPoweredOn
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF9333EA).withValues(alpha: 0.4),
                        blurRadius: 20,
                        spreadRadius: -1,
                        offset: const Offset(2, 5),
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left section
                  Row(
                    children: [
                      Container(
                        height: 56,
                        width: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isPoweredOn
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFF242424),
                        ),
                        child: Icon(
                          Icons.power_settings_new,
                          size: 28,
                          color: isPoweredOn
                              ? Colors.white
                              : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        isPoweredOn ? 'Power On' : 'Power Off',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Right status pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isPoweredOn
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFF242424),
                    ),
                    child: Text(
                      isPoweredOn ? 'ON' : 'OFF',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
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
