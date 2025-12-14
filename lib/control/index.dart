import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:led/control/components/bottom_nav.dart';

class ControlIndex extends StatefulWidget {
  final DiscoveredDevice device;
  const ControlIndex({super.key, required this.device});

  @override
  State<ControlIndex> createState() => _ControlIndexState();
}

class _ControlIndexState extends State<ControlIndex> {
  String _activeTab = 'dashboard';

  Widget _renderContent() {
    switch (_activeTab) {
      // case 'dashboard':
      //   return const Dashboard();
      // case 'scenes':
      //   return const ScenesPageEnhanced();
      // case 'schedules':
      //   return const SchedulesPage();
      // case 'settings':
      //   return SettingsPage(
      //     deviceName: widget.deviceName,
      //     onDisconnect: widget.onBack,
      //   );
      default:
        return const Scaffold();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            /// Header
            Container(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
              ),
              child: Row(
                children: [
                  /// Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Colors.grey,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  /// Device Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.device.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFE5E5E5),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: const [
                            SizedBox(
                              width: 8,
                              height: 8,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Connected',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4ADE80),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            /// Content
            Expanded(child: _renderContent()),

            /// Bottom Navigation
            BottomNav(
              activeTab: _activeTab,
              onTabChange: (tab) {
                setState(() {
                  _activeTab = tab;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
