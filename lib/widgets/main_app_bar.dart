import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      elevation: 0,
       leading: IconButton(
         icon: const Icon(Icons.menu, size: 28, color: Color(0xFF0F172A)), // Slate 900
         onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: RichText(
        text: const TextSpan(
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          children: [
            TextSpan(text: 'Test App Controller', style: TextStyle(color: Color(0xFF0F172A))), // Slate 900
          ],
        ),
      ),
      centerTitle: true,
      actions: [
        ValueListenableBuilder<BleConnectionStatus>(
          valueListenable: BleService.instance.connectionStatus,
          builder: (_, status, __) {
            final isConnected = status == BleConnectionStatus.connected;
            return Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFFD1FAE5) : const Color(0xFFF1F5F9), // Light Green / Slate 100
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isConnected ? const Color(0xFF34D399).withValues(alpha: 0.5) : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isConnected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                        shape: BoxShape.circle,
                        boxShadow: isConnected ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ] : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isConnected ? 'Live' : 'Offline',
                      style: TextStyle(
                        color: isConnected ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
