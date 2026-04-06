import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/device_model.dart';
import '../services/database_helper.dart';

const String _fallbackStoreUrl =
    'https://play.google.com/store/apps/details?id=com.nuetech.testapp';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Entry point ───────────────────────────────────────────────────────────

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;
    final raw = capture.barcodes.first.rawValue;
    if (raw == null) return;
    setState(() => _isProcessing = true);
    _processQr(raw.trim());
  }

  // ── Main router ───────────────────────────────────────────────────────────
  //
  //  Path A → URL QR  (https://...)
  //           ├─ has pid + sn  → extract params → save device ✅
  //           └─ missing params → fallback bottom sheet (Play Store)
  //
  //  Path B → JSON QR  ({ "type": "nuetech_device", ... })
  //           ├─ valid fields  → save device ✅
  //           └─ invalid       → error snackbar
  //
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _processQr(String raw) async {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      await _handleUrlQr(raw);
    } else {
      await _handleJsonQr(raw);
    }
  }

  // ── Path A: URL QR ────────────────────────────────────────────────────────

  Future<void> _handleUrlQr(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      _showError('Invalid QR Code');
      return;
    }

    final String? pid = uri.queryParameters['pid'];
    final String? sn  = uri.queryParameters['sn'];

    // Valid device URL — has both pid and sn
    if (pid != null && pid.isNotEmpty && sn != null && sn.isNotEmpty) {
      await _saveDevice(
        sn:   sn,
        pid:  pid,
        name: uri.queryParameters['name'],
      );
      return;
    }

    // URL exists but missing device params — show Play Store fallback
    await _showFallbackSheet(url);
  }

  // ── Path B: JSON QR ───────────────────────────────────────────────────────

  Future<void> _handleJsonQr(String raw) async {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      _showError('Invalid QR Code');
      return;
    }

    final String? type = data['type'] as String?;
    final String? sn   = data['sn']   as String?;
    final String? pid  = data['pid']  as String?;

    if (type != 'nuetech_device' || sn == null || sn.isEmpty ||
        pid == null || pid.isEmpty) {
      _showError('Invalid QR Code');
      return;
    }

    await _saveDevice(
      sn:      sn,
      pid:     pid,
      name:    data['name']    as String?,
      addedAt: data['addedAt'] as String?,
    );
  }

  // ── Shared save logic ─────────────────────────────────────────────────────

  Future<void> _saveDevice({
    required String sn,
    required String pid,
    String? name,
    String? addedAt,
  }) async {
    final device = DeviceModel(
      serialNumber: sn,
      productId:    pid,
      name:         name,
      addedAt:      addedAt ?? DateTime.now().toIso8601String(),
    );

    final inserted = await DatabaseHelper().addDevice(device);
    if (!mounted) return;

    if (inserted) {
      // Mark device as added for app routing
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('deviceAdded', true);
      if (!mounted) return;
      _showSuccess(device);
    } else {
      // Duplicate device
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Device $sn is already added.'),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
      ));
      // Reset so user can scan again
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Fallback bottom sheet (no pid/sn in URL) ──────────────────────────────

  Future<void> _showFallbackSheet(String url) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.blue.shade50, shape: BoxShape.circle),
              child: Icon(Icons.open_in_new,
                  color: Colors.blue.shade700, size: 32),
            ),
            const SizedBox(height: 16),
            const Text('Open App Link?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('This QR links to the app. Open it in the Play Store?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.shop),
                label: const Text('Open Play Store'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  final uri = Uri.parse(_fallbackStoreUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
          ],
        ),
      ),
    );

    // Reset scanner after sheet is dismissed
    if (mounted) setState(() => _isProcessing = false);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red.shade700,
      behavior: SnackBarBehavior.floating,
    ));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  void _showSuccess(DeviceModel device) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle, color: Colors.white),
        const SizedBox(width: 10),
        const Text('Device Added Successfully'),
      ]),
      backgroundColor: Colors.green.shade700,
      behavior: SnackBarBehavior.floating,
    ));
    Navigator.pop(context, true);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan Device QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Torch',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          _ScanOverlay(),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.qr_code_scanner, color: Colors.white70, size: 20),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Point at the QR code on your Nuetech device',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                  child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }
}

// ── Scan overlay ──────────────────────────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: MediaQuery.of(context).size,
      painter: _OverlayPainter(260),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final double size;
  _OverlayPainter(this.size);

  @override
  void paint(Canvas canvas, Size s) {
    final cx   = s.width / 2;
    final cy   = s.height / 2 - 40;
    final half = size / 2;
    final rect = Rect.fromLTRB(cx - half, cy - half, cx + half, cy + half);

    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, s.width, s.height))
        ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)))
        ..fillType = PathFillType.evenOdd,
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    final bp = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const bl = 24.0;
    for (final pts in [
      [Offset(rect.left, rect.top + bl),     rect.topLeft,     Offset(rect.left + bl, rect.top)],
      [Offset(rect.right - bl, rect.top),    rect.topRight,    Offset(rect.right, rect.top + bl)],
      [Offset(rect.left, rect.bottom - bl),  rect.bottomLeft,  Offset(rect.left + bl, rect.bottom)],
      [Offset(rect.right - bl, rect.bottom), rect.bottomRight, Offset(rect.right, rect.bottom - bl)],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(pts[0].dx, pts[0].dy)
          ..lineTo(pts[1].dx, pts[1].dy)
          ..lineTo(pts[2].dx, pts[2].dy),
        bp,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

