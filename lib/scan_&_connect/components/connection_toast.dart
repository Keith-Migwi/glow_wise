import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

OverlayEntry? _connectionToastEntry;

/// Call this function to show a toast message
/// Example messages:
/// - "Connecting..."
/// - "Connected"
/// - "Connection Failed"
/// - "Device not supported yet, disconnected"
void showConnectionToast(BuildContext context, String message) {
  // Remove previous toast if shown
  _connectionToastEntry?.remove();
  _connectionToastEntry = null;

  final overlay = Overlay.of(context);

  _connectionToastEntry = OverlayEntry(
    builder: (context) => _ConnectionToastOverlay(message: message),
  );

  overlay.insert(_connectionToastEntry!);

  // Auto dismiss for Connected, Failed, or Unsupported
  if (message.contains("Connected") ||
      message.contains("Failed") ||
      message.contains("Device not supported")) {
    Future.delayed(const Duration(seconds: 2), () {
      _connectionToastEntry?.remove();
      _connectionToastEntry = null;
    });
  }
}

class _ConnectionToastOverlay extends StatefulWidget {
  final String message;

  const _ConnectionToastOverlay({required this.message});

  @override
  State<_ConnectionToastOverlay> createState() =>
      _ConnectionToastOverlayState();
}

class _ConnectionToastOverlayState extends State<_ConnectionToastOverlay>
    with TickerProviderStateMixin {
  late AnimationController fadeSlideController;
  late AnimationController loaderController;
  late AnimationController checkController;

  @override
  void initState() {
    super.initState();

    fadeSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();

    loaderController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Handle animation based on message
    if (widget.message.contains("Connecting")) {
      loaderController.repeat();
    } else if (widget.message.contains("Connected")) {
      checkController.forward();
    }
  }

  @override
  void dispose() {
    fadeSlideController.dispose();
    loaderController.dispose();
    checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnecting = widget.message.contains("Connecting");
    final isConnected = widget.message.contains("Connected");
    final isFailed = widget.message.contains("Failed");
    final isUnsupported = widget.message.contains("Device not supported");

    final screenWidth = MediaQuery.of(context).size.width;

    // Determine the icon for the state
    Widget? stateIcon;

    if (isConnecting) {
      stateIcon = RotationTransition(
        turns: loaderController,
        child: Icon(LucideIcons.loader2, size: 24, color: Colors.cyan[400]),
      );
    } else if (isConnected) {
      stateIcon = ScaleTransition(
        scale: checkController.drive(
          Tween(
            begin: 0.0,
            end: 1.0,
          ).chain(CurveTween(curve: Curves.elasticOut)),
        ),
        child: Icon(
          LucideIcons.checkCircle,
          size: 24,
          color: Colors.green[400],
        ),
      );
    } else if (isFailed) {
      stateIcon = Icon(LucideIcons.xCircle, size: 24, color: Colors.red[400]);
    } else if (isUnsupported) {
      stateIcon = Icon(
        LucideIcons.alertCircle,
        size: 24,
        color: Colors.orange[400],
      );
    }

    // Text color
    Color textColor = Colors.white;
    if (isFailed) textColor = Colors.red[400]!;
    if (isUnsupported) textColor = Colors.orange[400]!;

    return Positioned(
      bottom: 32,
      left: 24,
      right: 24,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: fadeSlideController,
                curve: Curves.easeOut,
              ),
            ),
        child: FadeTransition(
          opacity: fadeSlideController,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: screenWidth * 0.9,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (stateIcon != null) stateIcon,
                  if (stateIcon != null) const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: textColor),
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
