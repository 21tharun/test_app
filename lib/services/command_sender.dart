import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;

/// Mixin-style extension on BleService is not practical here,
/// so we instead create a helper that uses the BleService internals.
/// This file exposes a single function used by the temperature slider.
///
/// Sends a raw string command to whichever connection is currently active
/// (Classic BT preferred, falls back to BLE write-without-response).
class BluetoothCommandSender {
  BluetoothCommandSender._();
  static final BluetoothCommandSender instance = BluetoothCommandSender._();

  /// Send [command] (e.g. "ST=25") over the active connection.
  /// Returns null on success, or an error string.
  Future<String?> send(String command, {
    fbs.BluetoothConnection? classicConnection,
    fbp.BluetoothDevice? bleDevice,
  }) async {
    // ── Try Classic first ────────────────────────────────────────────────
    if (classicConnection != null && classicConnection.isConnected) {
      try {
        classicConnection.output.add(
            Uint8List.fromList(utf8.encode('$command\n')));
        await classicConnection.output.allSent;
        return null;
      } catch (e) {
        debugPrint('Classic send failed: $e');
        return 'Send failed: $e';
      }
    }

    // ── Try BLE write ────────────────────────────────────────────────────
    if (bleDevice != null) {
      try {
        final services = await bleDevice.discoverServices();
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              await c.write(utf8.encode('$command\n'),
                  withoutResponse: c.properties.writeWithoutResponse);
              return null;
            }
          }
        }
        return 'No writable characteristic found on BLE device.';
      } catch (e) {
        debugPrint('BLE send failed: $e');
        return 'BLE send failed: $e';
      }
    }

    return 'No active connection.';
  }
}


