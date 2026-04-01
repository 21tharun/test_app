import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_model.dart';
import '../services/database_helper.dart';
import '../widgets/app_drawer.dart';
import 'qr_scanner_screen.dart';
import 'bluetooth_connection_screen.dart';

class MyDeviceScreen extends StatefulWidget {
  const MyDeviceScreen({super.key});

  @override
  State<MyDeviceScreen> createState() => _MyDeviceScreenState();
}

class _MyDeviceScreenState extends State<MyDeviceScreen> {
  DeviceModel? _device;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDevice();
  }

  Future<void> _loadDevice() async {
    setState(() => _isLoading = true);
    final devices = await DatabaseHelper().getAllDevices();
    setState(() {
      _device    = devices.isNotEmpty ? devices.first : null;
      _isLoading = false;
    });
  }

  // ── Scan / Replace ────────────────────────────────────────────────────────

  Future<void> _onScanTapped() async {
    if (_device != null) {
      // Device already exists — confirm replacement
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text('Replace Device',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
            'This will remove your current device and replace it with the new one. Continue?',
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true) return;

      // Delete existing device
      await DatabaseHelper().deleteDevice(_device!.serialNumber);
    }

    if (!mounted) return;

    // Open QR scanner
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );

    if (added == true) {
      await _loadDevice();
      if (!mounted) return;
      // Navigate to Bluetooth after successful scan
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BluetoothConnectionScreen(
            redirectToController: true,
          ),
        ),
      );
    }
  }

  // ── Remove device ─────────────────────────────────────────────────────────

  Future<void> _onRemoveTapped() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Device',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Are you sure you want to remove this device?',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true && _device != null) {
      await DatabaseHelper().deleteDevice(_device!.serialNumber);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('deviceAdded', false);
      await _loadDevice();
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Device',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _device == null
              ? _NoDeviceState(onScan: _onScanTapped)
              : _DeviceExistsState(
                  device:   _device!,
                  onScan:   _onScanTapped,
                  onRemove: _onRemoveTapped,
                ),
    );
  }
}

// ── No device state ───────────────────────────────────────────────────────────

class _NoDeviceState extends StatelessWidget {
  final VoidCallback onScan;
  const _NoDeviceState({required this.onScan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.devices_other_outlined,
                  size: 48, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 24),
            const Text('No device added yet',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 10),
            const Text(
              'Scan the QR code on your Nuetech solar water heater to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Device exists state ───────────────────────────────────────────────────────

class _DeviceExistsState extends StatelessWidget {
  final DeviceModel  device;
  final VoidCallback onScan;
  final VoidCallback onRemove;

  const _DeviceExistsState({
    required this.device,
    required this.onScan,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Device info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.water_heater_outlined,
                          color: Color(0xFF3B82F6), size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name ?? device.serialNumber,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text('Nuetech Solar Water Heater',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF94A3B8))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 16),

                _InfoTile(
                  label: 'Product ID',
                  value: device.productId,
                  icon: Icons.tag_outlined,
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  label: 'Serial Number',
                  value: device.serialNumber,
                  icon: Icons.fingerprint,
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  label: 'Added On',
                  value: _formatDate(device.addedAt),
                  icon: Icons.calendar_today_outlined,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Change device button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan / Change Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Remove device button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Remove Device',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _InfoTile extends StatelessWidget {
  final String   label;
  final String   value;
  final IconData icon;

  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500)),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}