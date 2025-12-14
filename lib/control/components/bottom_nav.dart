import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BottomNav extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChange;

  const BottomNav({
    super.key,
    required this.activeTab,
    required this.onTabChange,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      {'id': 'dashboard', 'icon': LucideIcons.home, 'label': 'Control'},
      {'id': 'scenes', 'icon': LucideIcons.palette, 'label': 'Scenes'},
      {'id': 'schedules', 'icon': LucideIcons.clock, 'label': 'Schedule'},
      {'id': 'settings', 'icon': LucideIcons.settings, 'label': 'Settings'},
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: tabs.map((tab) {
            final isActive = activeTab == tab['id'];

            return GestureDetector(
              onTap: () => onTabChange(tab['id'] as String),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: isActive
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF22D3EE), // cyan-500
                                Color(0xFF9333EA), // purple-600
                              ],
                            )
                          : null,
                    ),
                    child: Icon(
                      tab['icon'] as IconData,
                      size: 22,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF6B7280), // gray-500
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive
                          ? const Color(0xFFE5E7EB) // gray-200
                          : const Color(0xFF4B5563), // gray-600
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
