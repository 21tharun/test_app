import 'package:flutter/material.dart';
import '../models/device_model.dart';
import '../services/database_helper.dart';
import 'qr_scanner_screen.dart';
// import 'temperature_control_screen.dart'; // uncomment when ready

class SavedDevicesScreen extends StatefulWidget {
  const SavedDevicesScreen({super.key});

  @override
  State<SavedDevicesScreen> createState() => _SavedDevicesScreenState();
}

class _SavedDevicesScreenState extends State<SavedDevicesScreen> {
  List<DeviceModel> _devices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final devices = await DatabaseHelper().getAllDevices();
    setState(() {
      _devices  = devices;
      _isLoading = false;
    });
  }

  Future<void> _openScanner() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (added == true) await _load();
  }

  Future<void> _delete(DeviceModel device) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
            'Remove "${device.name ?? device.serialNumber}" from your devices?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Remove')),
        ],
      ),
    );
    if (ok == true) {
      await DatabaseHelper().deleteDevice(device.serialNumber);
      await _load();
    }
  }

  void _onTap(DeviceModel device) {
    // TODO: navigate to temperature control screen
    // Navigator.push(context, MaterialPageRoute(
    //   builder: (_) => TemperatureControlScreen(device: device),
    // ));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Opening ${device.name ?? device.serialNumber}...'),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'My Devices',
          style: TextStyle(
              color: Color(0xFF1A1F36),
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1F36)),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _devices.isEmpty
              ? _EmptyState(onScan: _openScanner)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _devices.length,
                    itemBuilder: (_, i) => _DeviceCard(
                      device:   _devices[i],
                      onTap:    () => _onTap(_devices[i]),
                      onDelete: () => _delete(_devices[i]),
                    ),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openScanner,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Device card ───────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final DeviceModel  device;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeviceCard({
    required this.device,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.water_drop_outlined,
                      color: Color(0xFF2563EB), size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name ?? device.serialNumber,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Color(0xFF1A1F36)),
                      ),
                      const SizedBox(height: 4),
                      _InfoRow(Icons.tag,         'Product ID', device.productId),
                      const SizedBox(height: 2),
                      _InfoRow(Icons.fingerprint, 'Serial No.', device.serialNumber),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.chevron_right, color: Color(0xFFADB5C7)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: onDelete,
                      child: const Icon(Icons.delete_outline,
                          color: Color(0xFFE53E3E), size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String   label;
  final String   value;
  const _InfoRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF8A94A6)),
        const SizedBox(width: 4),
        Text('$label: ',
            style: const TextStyle(fontSize: 12, color: Color(0xFF8A94A6))),
        Text(value,
            style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF4A5568),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyState({required this.onScan});

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
                  color: const Color(0xFF2563EB).withOpacity(0.08),
                  shape: BoxShape.circle),
              child: const Icon(Icons.devices_other_outlined,
                  size: 48, color: Color(0xFF2563EB)),
            ),
            const SizedBox(height: 24),
            const Text('No devices added',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36))),
            const SizedBox(height: 10),
            const Text(
              'Scan the QR code on your Nuetech device to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF8A94A6), height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onScan,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR to Add Device'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 14),
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

