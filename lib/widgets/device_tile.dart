import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

// ── BLE scan result tile ─────────────────────────────────────────────────────

/// Tile for a BLE device discovered during scan.
/// Shows name, MAC address, and colour-coded RSSI.
class DeviceTile extends StatelessWidget {
  const DeviceTile({
    super.key,
    required this.result,
    required this.onTap,
    this.isConnecting = false,
  });

  final fbp.ScanResult result;
  final VoidCallback onTap;
  final bool isConnecting;

  String get _name {
    final n = result.device.platformName;
    return n.isNotEmpty ? n : 'Unknown Device';
  }

  String get _address => result.device.remoteId.str;
  int get _rssi => result.rssi;

  Color _rssiColor() {
    if (_rssi >= -60) return Colors.green.shade600;
    if (_rssi >= -75) return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  IconData _rssiIcon() {
    if (_rssi >= -60) return Icons.signal_wifi_4_bar;
    if (_rssi >= -75) return Icons.network_wifi_3_bar;
    return Icons.network_wifi_2_bar;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Icon(Icons.bluetooth, color: theme.colorScheme.primary),
        ),
        title: Text(_name,
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(_address, style: theme.textTheme.bodySmall),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_rssiIcon(), size: 16, color: _rssiColor()),
                  const SizedBox(height: 2),
                  Text('$_rssi dBm',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: _rssiColor(),
                          fontWeight: FontWeight.w600)),
                ],
              ),
        onTap: isConnecting ? null : onTap,
      ),
    );
  }
}

// ── Classic BT discovery result tile ────────────────────────────────────────

/// Tile for a Classic Bluetooth device found during discovery.
class ClassicDeviceTile extends StatelessWidget {
  const ClassicDeviceTile({
    super.key,
    required this.result,
    required this.onTap,
    this.isConnecting = false,
  });

  final fbs.BluetoothDiscoveryResult result;
  final VoidCallback onTap;
  final bool isConnecting;

  String get _name {
    final n = result.device.name;
    return (n != null && n.isNotEmpty) ? n : 'Unknown Device';
  }

  String get _address => result.device.address;
  int get _rssi => result.rssi;

  Color _rssiColor() {
    if (_rssi >= -60) return Colors.green.shade600;
    if (_rssi >= -75) return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepOrange.shade50,
          child: Icon(Icons.bluetooth,
              color: Colors.deepOrange.shade700),
        ),
        title: Text(_name,
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(_address, style: theme.textTheme.bodySmall),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.signal_cellular_alt,
                      size: 16, color: _rssiColor()),
                  const SizedBox(height: 2),
                  Text('$_rssi dBm',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: _rssiColor(),
                          fontWeight: FontWeight.w600)),
                ],
              ),
        onTap: isConnecting ? null : onTap,
      ),
    );
  }
}

// ── Paired device tile ────────────────────────────────────────────────────────

/// Tile for an already-paired Bluetooth device (Classic or BLE).
class PairedDeviceTile extends StatelessWidget {
  const PairedDeviceTile({
    super.key,
    required this.device,
    required this.onTap,
    this.isConnecting = false,
  });

  final fbs.BluetoothDevice device;
  final VoidCallback onTap;
  final bool isConnecting;

  String get _name {
    final n = device.name;
    return (n != null && n.isNotEmpty) ? n : 'Unknown Device';
  }

  String get _address => device.address;

  bool get _isClassic =>
      device.type != fbs.BluetoothDeviceType.le;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade50,
          child: Icon(Icons.bluetooth_connected,
              color: Colors.green.shade700),
        ),
        title: Text(_name,
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(_address, style: theme.textTheme.bodySmall),
        trailing: isConnecting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Chip(
                    label: Text(_isClassic ? 'Classic' : 'BLE',
                        style: const TextStyle(fontSize: 11)),
                    backgroundColor: _isClassic
                        ? Colors.deepOrange.shade50
                        : theme.colorScheme.primaryContainer,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 4),
                  Chip(
                    label: const Text('Paired',
                        style: TextStyle(fontSize: 11)),
                    backgroundColor: Colors.green.shade100,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
        onTap: isConnecting ? null : onTap,
      ),
    );
  }
}


