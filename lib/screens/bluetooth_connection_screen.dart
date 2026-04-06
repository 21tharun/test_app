import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';
import '../widgets/main_app_bar.dart';
import 'app_drawer.dart';
import 'device_list_screen.dart';
import 'temperature_control_screen.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  final bool redirectToController;

  const BluetoothConnectionScreen({
    super.key,
    this.redirectToController = false,
  });

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState
    extends State<BluetoothConnectionScreen> {

  @override
  void initState() {
    super.initState();
    BleService.instance.connectionStatus.addListener(_onConnectionChanged);
  }

  @override
  void dispose() {
    BleService.instance.connectionStatus.removeListener(_onConnectionChanged);
    super.dispose();
  }

  void _onConnectionChanged() {
    final status = BleService.instance.connectionStatus.value;

    if (status == BleConnectionState.CONNECTED) {
      BleService.instance.stopScan();

      // Always auto-navigate to controller upon connection
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const TemperatureControlScreen(),
          ),
        );
      }
    } else if (status == BleConnectionState.DISCONNECTED) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Connection failed. Please try again.'),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 3),
        ));
      }
    }
  }

  void _showCenterAlert(BuildContext context, String message, bool isSuccess) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 48,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ble = BleService.instance;

    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: ValueListenableBuilder<BleConnectionState>(
            valueListenable: ble.connectionStatus,
            builder: (_, status, __) {
              final isConnected = status == BleConnectionState.CONNECTED;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Main Status Card ──────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 48, horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFDBEAFE),
                            border: Border.all(
                              color: isConnected
                                  ? const Color(0xFF6EE7B7)
                                  : const Color(0xFF93C5FD),
                              width: 15,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF3B82F6),
                            ),
                            child: Icon(
                              isConnected
                                  ? Icons.bluetooth_connected
                                  : Icons.bluetooth,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          isConnected ? 'Connected' : 'Not Connected',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isConnected
                              ? 'Device is paired and ready to receive commands'
                              : 'Make sure your device is powered\nON and within range',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Disconnect Button ─────────────────────────────────
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (isConnected) {
                          ble.disconnectDevice();
                          _showCenterAlert(
                              context, 'Device Disconnected', true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No device connected to disconnect')),
                          );
                        }
                      },
                      icon: const Icon(Icons.bluetooth_disabled, size: 20),
                      label: const Text('Disconnect',
                          style: TextStyle(fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Enable + Scan Buttons ─────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final error = await ble.enableBluetooth();
                              if (context.mounted) {
                                if (error == 'already_on') {
                                  _showCenterAlert(context,
                                      'Bluetooth is already on', true);
                                } else {
                                  _showCenterAlert(
                                      context,
                                      error ??
                                          'Bluetooth enabled successfully',
                                      error == null);
                                }
                              }
                            },
                            icon: const Icon(Icons.bluetooth, size: 20),
                            label: const Text('Enable',
                                style: TextStyle(fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const DeviceListScreen()),
                              );
                            },
                            icon: const Icon(Icons.search,
                                size: 20, color: Color(0xFF0F172A)),
                            label: const Text('Scan',
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF0F172A))),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF1F5F9),
                              foregroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                    color: Color(0xFFE2E8F0)),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Info Card ─────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFF3B82F6), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 13,
                                  height: 1.5),
                              children: [
                                TextSpan(text: 'Keep the device within '),
                                TextSpan(
                                    text: '5–10 metres',
                                    style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold)),
                                TextSpan(text: '. Ensure '),
                                TextSpan(
                                    text: 'Bluetooth',
                                    style: TextStyle(
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.bold)),
                                TextSpan(
                                    text:
                                        ' is enabled on both devices before scanning.'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

