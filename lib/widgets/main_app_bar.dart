import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const MainAppBar({super.key, this.title = 'Nuetech Controller'});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      elevation: 0,
       leading: IconButton(
         icon: const Icon(Icons.menu, size: 28, color: Color(0xFF0F172A)), // Slate 900
         onPressed: () => Scaffold.of(context).openDrawer(),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: Color(0xFF0F172A), // Slate 900
        ),
      ),
      centerTitle: true,
      actions: [
        ValueListenableBuilder<BleConnectionState>(
          valueListenable: BleService.instance.connectionStatus,
          builder: (_, connStatus, __) {
            return ValueListenableBuilder<SyncStatus>(
              valueListenable: BleService.instance.syncStatus,
              builder: (_, syncStatus, __) {
                final isOffline = connStatus == BleConnectionState.DISCONNECTED;
                final isSyncing = syncStatus == SyncStatus.SYNCING;
                final isUpdated = syncStatus == SyncStatus.SUCCESS;

                String statusText;
                Color statusColor;
                Color bubbleColor;

                if (isOffline) {
                  statusText = 'Device Offline';
                  statusColor = const Color(0xFF6B7280);
                  bubbleColor = const Color(0xFFF1F5F9);
                } else if (isSyncing) {
                  statusText = 'Syncing';
                  statusColor = const Color(0xFF3B82F6);
                  bubbleColor = const Color(0xFFDBEAFE);
                } else if (isUpdated) {
                  statusText = 'Updated';
                  statusColor = const Color(0xFF10B981);
                  bubbleColor = const Color(0xFFD1FAE5);
                } else {
                  statusText = 'Device Online';
                  statusColor = const Color(0xFF10B981);
                  bubbleColor = const Color(0xFFD1FAE5);
                }

                return Center(
                  child: Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                            boxShadow: !isOffline ? [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ] : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}


