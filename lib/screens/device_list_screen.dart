import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;
import '../services/bluetooth_service.dart';
import '../widgets/device_tile.dart';
import 'temperature_control_screen.dart';

/// Device list screen with three sections:
/// 1. Paired Devices (Classic bonded)
/// 2. Nearby Classic Devices (discovered via Classic BT)
/// 3. Nearby BLE Devices (discovered via BLE scan)
class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  final BleService _ble = BleService.instance;

  List<fbs.BluetoothDevice> _pairedDevices = [];
  String? _connectingId;

  @override
  void initState() {
    super.initState();
    _ble.connectionStatus.addListener(_onConnectionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  @override
  void dispose() {
    _ble.connectionStatus.removeListener(_onConnectionChanged);
    _ble.stopScan();
    super.dispose();
  }

  Future<void> _init() async {
    final paired = await _ble.getClassicPairedDevices();
    if (mounted) setState(() => _pairedDevices = paired);
    await _startScan();
  }

  Future<void> _startScan() async {
    final error = await _ble.startScan();
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠ $error'),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  void _onConnectionChanged() {
    final s = _ble.connectionStatus.value;
    if (s == BleConnectionState.CONNECTED) {
      _ble.stopScan();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const TemperatureControlScreen(),
          ),
        );
      }
    } else if (s == BleConnectionState.DISCONNECTED) {
      if (mounted) {
        setState(() => _connectingId = null);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('✗ Connection failed. Please try again.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  // ── Pair dialogs ──────────────────────────────────────────────────────────

  Future<void> _onPairedDeviceTapped(fbs.BluetoothDevice device) async {
    final name =
        (device.name != null && device.name!.isNotEmpty)
            ? device.name!
            : 'Unknown Device';
    final isClassic = device.type != fbs.BluetoothDeviceType.le;
    final confirmed = await _showConnectDialog(name, device.address);
    if (confirmed == true && mounted) {
      setState(() => _connectingId = device.address);
      await _ble.stopScan();
      if (isClassic) {
        await _ble.connectClassicDevice(device.address, name);
      } else {
        final bleDevice = fbp.BluetoothDevice.fromId(device.address);
        await _ble.connectToDevice(bleDevice);
      }
    }
  }

  Future<void> _onClassicDeviceTapped(
      fbs.BluetoothDiscoveryResult result) async {
    final name = (result.device.name != null &&
            result.device.name!.isNotEmpty)
        ? result.device.name!
        : 'Unknown Device';
    final confirmed =
        await _showConnectDialog(name, result.device.address);
    if (confirmed == true && mounted) {
      setState(() => _connectingId = result.device.address);
      await _ble.stopScan();
      await _ble.connectClassicDevice(result.device.address, name);
    }
  }

  // Handle tapping on a BLE device to initiate connection process
  Future<void> _onBleDeviceTapped(fbp.ScanResult result) async {
    final device = result.device;
    final name = device.platformName.isNotEmpty
        ? device.platformName
        : 'Nuetech Device'; // Default for nameless devices that passed filter
    
    // Confirm connection with user before proceeding
    final confirmed =
        await _showConnectDialog(name, device.remoteId.str);
    
    if (confirmed == true && mounted) {
      setState(() => _connectingId = device.remoteId.str);
      // Ensure scanning is stopped to save battery and stabilize connection
      await _ble.stopScan();
      // Execute the device-specific connection logic in the service
      await _ble.connectToDevice(device);
    }
  }

  Future<bool?> _showConnectDialog(String name, String address) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Connect to Device?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bluetooth, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(address,
                style:
                    const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Devices'),
        actions: [
          // Rescan button — restarts both scans
          _ScanToggleButton(ble: _ble, onStartScan: _startScan),
        ],
      ),
      body: ListView(
        children: [
          // ── Connecting banner ─────────────────────────────────────────
          if (_connectingId != null)
            _InfoBanner(
              color: Colors.blue.shade50,
              icon: null,
              scanning: true,
              message: 'Connecting… Please wait.',
            ),

          // ── Scan status banners ───────────────────────────────────────
          ValueListenableBuilder<bool>(
            valueListenable: _ble.isScanning,
            builder: (_, bleScan, __) =>
                ValueListenableBuilder<bool>(
              valueListenable: _ble.isClassicDiscovering,
              builder: (_, classicScan, __) {
                final scanning = bleScan || classicScan;
                return _InfoBanner(
                  color: scanning
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  icon: scanning
                      ? null
                      : Icons.bluetooth_disabled,
                  scanning: scanning,
                  message: scanning
                      ? 'Scanning (BLE + Classic) for 10 seconds…'
                      : 'Scan complete. Tap Rescan to search again.',
                  textColor: scanning
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                );
              },
            ),
          ),

          // ── Section: Paired Devices ───────────────────────────────────
          _SectionHeader(
              title: 'Paired Devices', count: _pairedDevices.length),
          if (_pairedDevices.isEmpty)
            _EmptyHint('No Nuetech devices found in paired list.\nMake sure your Nuetech device is powered on.')
          else
            ..._pairedDevices.map((d) => PairedDeviceTile(
                  device: d,
                  isConnecting: _connectingId == d.address,
                  onTap: _connectingId == null
                      ? () => _onPairedDeviceTapped(d)
                      : () {},
                )),

          const Divider(indent: 16, endIndent: 16),

          // ── Section: Nearby Classic Devices ───────────────────────────
          ValueListenableBuilder<List<fbs.BluetoothDiscoveryResult>>(
            valueListenable: _ble.classicResults,
            builder: (_, classicList, __) {
              final pairedAddrs =
                  _pairedDevices.map((d) => d.address).toSet();
              final nearby = classicList
                  .where((r) =>
                      !pairedAddrs.contains(r.device.address))
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                      title: 'Nearby Classic Devices',
                      count: nearby.length),
                  if (nearby.isEmpty)
                    ValueListenableBuilder<bool>(
                      valueListenable: _ble.isClassicDiscovering,
                      builder: (_, scanning, __) => _EmptyHint(
                          scanning
                              ? 'Discovering Nuetech devices…'
                              : 'No Nuetech devices found nearby.\nMake sure your device is powered on.'),
                    )
                  else
                    ...nearby.map((r) => ClassicDeviceTile(
                          result: r,
                          isConnecting:
                              _connectingId == r.device.address,
                          onTap: _connectingId == null
                              ? () => _onClassicDeviceTapped(r)
                              : () {},
                        )),
                ],
              );
            },
          ),

          const Divider(indent: 16, endIndent: 16),

          // ── Section: Nearby BLE Devices ───────────────────────────────
          ValueListenableBuilder<List<fbp.ScanResult>>(
            valueListenable: _ble.scanResults,
            builder: (_, bleList, __) {
              final pairedAddrs =
                  _pairedDevices.map((d) => d.address).toSet();
              final nearby = bleList
                  .where((r) =>
                      !pairedAddrs.contains(r.device.remoteId.str))
                  .toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(
                      title: 'Nearby BLE Devices',
                      count: nearby.length),
                  if (nearby.isEmpty)
                    ValueListenableBuilder<bool>(
                      valueListenable: _ble.isScanning,
                      builder: (_, scanning, __) => _EmptyHint(
                          scanning
                              ? 'Scanning for Nuetech BLE devices…'
                              : 'No Nuetech devices found in range.\nPower on your device and keep it nearby.'),
                    )
                  else
                    ...nearby.map((r) => DeviceTile(
                          result: r,
                          isConnecting:
                              _connectingId == r.device.remoteId.str,
                          onTap: _connectingId == null
                              ? () => _onBleDeviceTapped(r)
                              : () {},
                        )),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Helper widgets ────────────────────────────────────────────────────────────

class _ScanToggleButton extends StatelessWidget {
  const _ScanToggleButton(
      {required this.ble, required this.onStartScan});
  final BleService ble;
  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ble.isScanning,
      builder: (_, bleScan, __) =>
          ValueListenableBuilder<bool>(
        valueListenable: ble.isClassicDiscovering,
        builder: (_, classicScan, __) {
          final scanning = bleScan || classicScan;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: scanning ? ble.stopScan : onStartScan,
              icon: Icon(
                  scanning
                      ? Icons.stop_circle_outlined
                      : Icons.refresh,
                  color: Colors.blue.shade700,
                  size: 20),
              label: Text(scanning ? 'Stop' : 'Rescan',
                  style: TextStyle(
                      color: Colors.blue.shade700, 
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          );
        },
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.color,
    required this.scanning,
    required this.message,
    this.icon,
    this.textColor,
  });
  final Color color;
  final bool scanning;
  final String message;
  final IconData? icon;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          if (scanning)
            SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: theme.colorScheme.primary))
          else if (icon != null)
            Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: textColor, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});
  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Text(title,
              style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold)),
          if (count != null) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12)),
              child: Text('$count',
                  style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Text(message,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.outline)),
    );
  }
}


