import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart'
    show DiscoveredDevice;
import 'package:lucide_icons/lucide_icons.dart'; // For Bluetooth icon

// ------------------------ DeviceListItem ------------------------
class DeviceListItem extends StatelessWidget {
  final DiscoveredDevice device;
  final bool isSelected;
  final VoidCallback onClick;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.isSelected,
    required this.onClick,
  });

  String getSignalStrength(int? rssi) {
    if (rssi == null) return 'Unknown';
    if (rssi > -50) return 'Excellent';
    if (rssi > -70) return 'Good';
    return 'Fair';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClick,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(horizontal: 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Color(0xFF1E1E1E),
          border: Border.all(
            color: isSelected ? const Color(0xFF67E8F9) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (isSelected)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              )
            else
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
          ],
        ),
        child: Row(
          children: [
            // Bluetooth icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? const LinearGradient(
                                colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                // ignore: unnecessary_null_comparison
                              ).createShader(Rect.fromLTWH(0, 0, 48, 48)) !=
                              null // trick for gradient
                          ? null
                          : Colors.transparent
                    : Color(0xFF242424),
              ),
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      )
                    : null,
                child: Center(
                  child: Icon(
                    LucideIcons.bluetooth,
                    color: isSelected ? Colors.white : Colors.grey[500],
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Device Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade200,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    device.id,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Signal: ${getSignalStrength(device.rssi)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF22D3EE), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
