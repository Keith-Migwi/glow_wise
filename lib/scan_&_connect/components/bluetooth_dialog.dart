import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:led/main.dart' show bodyFont, secondaryFont;
import 'package:lucide_icons/lucide_icons.dart' show LucideIcons;

class BluetoothDialog extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onEnable;
  final VoidCallback enableSandbox;

  const BluetoothDialog({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onEnable,
    required this.enableSandbox,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        /// --- Backdrop ---
        GestureDetector(
          onTap: onClose,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
          ).animate().fade(duration: 300.ms),
        ),

        /// --- Dialog Center ---
        Center(
          child: GestureDetector(
            onTap: () {}, // prevent tap-through
            child:
                Container(
                      width: 340,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 20),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          /// --- Close Button ---
                          Positioned(
                            right: 0,
                            top: 0,
                            child: InkWell(
                              onTap: onClose,
                              borderRadius: BorderRadius.circular(50),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Color(0xFF242424),
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ),
                          ),

                          /// --- Dialog Content ---
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 10),

                              /// Icon with gradient background
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF22D3EE),
                                      Color(0xFF8B5CF6),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    LucideIcons.bluetooth,
                                    size: 40,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              /// Title + Body
                              Text(
                                "Enable Bluetooth",
                                style: TextStyle(
                                  color: Colors.grey.shade100,
                                  fontSize: bodyFont,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Bluetooth is currently disabled. Please enable it to scan for nearby LED devices.",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: secondaryFont,
                                  height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 24),

                              /// Buttons
                              Column(
                                children: [
                                  /// Enable button
                                  GestureDetector(
                                    onTap: onEnable,
                                    child: AnimatedScale(
                                      scale: 1.0,
                                      duration: 100.ms,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF22D3EE),
                                              Color(0xFF8B5CF6),
                                            ],
                                          ),
                                        ),
                                        child: const Text(
                                          "Enable Bluetooth",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: bodyFont,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  /// Cancel button
                                  GestureDetector(
                                    onTap: onClose,
                                    child: AnimatedScale(
                                      scale: 1.0,
                                      duration: 100.ms,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: Color(0xFF242424),
                                        ),
                                        child: Text(
                                          "Cancel",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey.shade300,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  /// SandBox button
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: enableSandbox,
                                    child: AnimatedScale(
                                      scale: 1.0,
                                      duration: 100.ms,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          color: Color(0xFF242424),
                                        ),
                                        child: Text(
                                          "Enable Sandbox",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.grey.shade300,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 250.ms)
                    .scale(
                      begin: const Offset(0.95, 0.95),
                      curve: Curves.easeOutBack,
                    )
                    .slideY(begin: 0.1, curve: Curves.easeOut),
          ),
        ),
      ],
    );
  }
}
