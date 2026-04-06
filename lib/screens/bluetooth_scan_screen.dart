import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_service.dart';
import '../widgets/device_tile.dart';

class BluetoothScanScreen extends StatefulWidget {
  const BluetoothScanScreen({super.key});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  final BleService _ble = BleService.instance;
  String? _connectingDeviceId;

  @override
  void initState() {
    super.initState();
    _ble.connectionStatus.addListener(_onConnectionStatusChanged);
  }

  @override
  void dispose() {
    _ble.connectionStatus.removeListener(_onConnectionStatusChanged);
    _ble.stopScan();
    super.dispose();
  }

  void _onConnectionStatusChanged() {
    final status = _ble.connectionStatus.value;
    String? message;
    Color? color;

    switch (status) {
      case BleConnectionState.CONNECTING:
        message = 'Connecting…';
        color = Colors.blue.shade700;
        break;
      case BleConnectionState.CONNECTED:
        message = '✓ Connected successfully';
        color = Colors.green.shade700;
        if (mounted) setState(() => _connectingDeviceId = null);
        break;
      case BleConnectionState.DISCONNECTED:
        message = '✗ Connection failed or disconnected';
        color = Colors.red.shade700;
        if (mounted) setState(() => _connectingDeviceId = null);
        break;
    }

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Future<void> _toggleScan() async {
    if (_ble.isScanning.value) {
      await _ble.stopScan();
    } else {
      _showSnackBar('Requesting permissions…', Colors.blueGrey, seconds: 2);
      final error = await _ble.startScan();
      if (error != null && mounted) {
        _showSnackBar('⚠ $error', Colors.red.shade700, seconds: 5);
      }
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() => _connectingDeviceId = device.remoteId.str);
    await _ble.connectToDevice(device);
  }

  void _showSnackBar(String msg, Color bg, {int seconds = 3}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: bg,
      duration: Duration(seconds: seconds),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _ble.isScanning,
            builder: (_, scanning, __) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _toggleScan,
                icon: Icon(
                  scanning ? Icons.stop_circle_outlined : Icons.search,
                  color: Colors.white,
                  size: 20,
                ),
                label: Text(
                  scanning ? 'Stop' : 'Scan',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status banner
          ValueListenableBuilder<bool>(
            valueListenable: _ble.isScanning,
            builder: (_, scanning, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: scanning
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              child: Row(
                children: [
                  if (scanning)
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary),
                    )
                  else
                    Icon(Icons.bluetooth_disabled,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scanning
                          ? 'Scanning for nearby BLE devices…'
                          : 'Tap Scan to search for devices',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scanning
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Scan results or empty state
          Expanded(
            child: ValueListenableBuilder<List<ScanResult>>(
              valueListenable: _ble.scanResults,
              builder: (_, results, __) {
                if (results.isEmpty) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _ble.isScanning,
                    builder: (_, scanning, __) =>
                        _buildEmptyState(theme, scanning),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final result = results[i];
                    final id = result.device.remoteId.str;
                    return DeviceTile(
                      result: result,
                      isConnecting: _connectingDeviceId == id,
                      onTap: () => _connectToDevice(result.device),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _ble.isScanning,
        builder: (_, scanning, __) {
          if (scanning) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: _toggleScan,
            icon: const Icon(Icons.bluetooth_searching),
            label: const Text('Start Scan'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, bool scanning) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bluetooth_searching,
                size: 72, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              scanning ? 'Searching…' : 'No Devices Found',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              scanning
                  ? 'Make sure your Bluetooth device is powered on and nearby.'
                  : 'Tap Start Scan below. Ensure Bluetooth and Location are enabled.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        ),
      ),
    );
  }
}


