import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../models/device_model.dart';
import '../services/database_helper.dart';

/// Call [DeepLinkHandler.init] once inside your root widget's [initState].
/// It handles both cold-start links (app launched via link) and
/// hot links (link received while app is already running).
class DeepLinkHandler {
  DeepLinkHandler._();

  static StreamSubscription<Uri>? _sub;
  static final AppLinks _appLinks = AppLinks();

  /// Initialize deep link listening.
  /// [context] must be a [BuildContext] that can show a SnackBar.
  static Future<void> init(BuildContext context) async {
    // ── Cold start: app opened via deep link ─────────────────────────────
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        await _handleUri(initialUri, context);
      }
    } catch (e) {
      debugPrint('DeepLinkHandler cold-start error: $e');
    }

    // ── Hot link: app already running, new link arrives ───────────────────
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) async {
        await _handleUri(uri, context);
      },
      onError: (e) => debugPrint('DeepLinkHandler stream error: $e'),
    );
  }

  /// Dispose the stream — call from your root widget's [dispose].
  static void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Core handler ──────────────────────────────────────────────────────────

  static Future<void> _handleUri(Uri uri, BuildContext context) async {
    debugPrint('DeepLinkHandler received: $uri');

    // Accepts both:
    //   https://21tharun.github.io/testing-links/device?pid=NT001&sn=SN001   (App Link)
    //   nuetech://device?pid=NT001&sn=SN001             (custom scheme)
    final bool isAppLink =
        (uri.scheme == 'https' && uri.host == '21tharun.github.io' && uri.path == '/testing-links/device');
    final bool isCustomScheme =
        (uri.scheme == 'nuetech' && uri.host == 'device');

    if (!isAppLink && !isCustomScheme) return;

    final String? pid = uri.queryParameters['pid'];
    final String? sn  = uri.queryParameters['sn'];

    if (pid == null || pid.isEmpty || sn == null || sn.isEmpty) {
      _showSnackbar(context, 'Invalid device link: missing parameters.',
          isError: true);
      return;
    }

    final device = DeviceModel(
      serialNumber: sn,
      productId:    pid,
      addedAt:      DateTime.now().toIso8601String(),
    );

    final inserted = await DatabaseHelper().addDevice(device);

    if (!context.mounted) return;

    if (inserted) {
      _showSnackbar(context, 'Device $sn added successfully!');
    } else {
      _showSnackbar(context, 'Device $sn is already in your list.',
          isError: false, isWarning: true);
    }
  }

  // ── Snackbar helper ───────────────────────────────────────────────────────

  static void _showSnackbar(
    BuildContext context,
    String message, {
    bool isError   = false,
    bool isWarning = false,
  }) {
    final color = isError
        ? Colors.red.shade700
        : isWarning
            ? Colors.orange.shade700
            : Colors.green.shade700;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ]),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ));
  }
}