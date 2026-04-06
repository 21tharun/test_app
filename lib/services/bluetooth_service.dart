import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart' as fbs;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum BleConnectionState { DISCONNECTED, CONNECTING, CONNECTED }
enum SyncStatus { IDLE, SYNCING, SUCCESS, FAILED }

/// Data class returned by the SYNC command.
class SyncData {
  final int? temperature;
  final String? tankTemp;
  final int? coilStatus;
  final String? slot1Start;
  final String? slot1End;
  final String? slot2Start;
  final String? slot2End;

  const SyncData({
    this.temperature,
    this.tankTemp,
    this.coilStatus,
    this.slot1Start,
    this.slot1End,
    this.slot2Start,
    this.slot2End,
  });

  @override
  String toString() =>
      'SyncData(temp=$temperature, tt=$tankTemp, coil=$coilStatus, S1S=$slot1Start, S1E=$slot1End, S2S=$slot2Start, S2E=$slot2End)';
}

/// Unified Bluetooth service supporting both BLE and Classic Bluetooth.
class BleService {
  BleService._() {
    _initAdapterListener();
  }
  static final BleService instance = BleService._();

  // ── BLE state ─────────────────────────────────────────────────────────────
  final ValueNotifier<List<fbp.ScanResult>> scanResults =
      ValueNotifier<List<fbp.ScanResult>>([]);
  final ValueNotifier<bool> isScanning = ValueNotifier<bool>(false);

  // ── Classic BT state ──────────────────────────────────────────────────────
  final ValueNotifier<List<fbs.BluetoothDiscoveryResult>> classicResults =
      ValueNotifier<List<fbs.BluetoothDiscoveryResult>>([]);
  final ValueNotifier<bool> isClassicDiscovering = ValueNotifier<bool>(false);

  // ── Shared connection state ───────────────────────────────────────────────
  
  /// Notifies the UI when new SYNC data is received.
  final ValueNotifier<SyncData?> syncData = ValueNotifier<SyncData?>(null);

  final ValueNotifier<BleConnectionState> connectionStatus =
      ValueNotifier<BleConnectionState>(BleConnectionState.DISCONNECTED);
  
  final ValueNotifier<SyncStatus> syncStatus =
      ValueNotifier<SyncStatus>(SyncStatus.IDLE);

  final ValueNotifier<String?> connectedDeviceName =
      ValueNotifier<String?>(null);

  final ValueNotifier<String?> connectedDeviceAddress =
      ValueNotifier<String?>(null);

  // ── Adapter state (BT on / off) ───────────────────────────────────────────
  final ValueNotifier<fbp.BluetoothAdapterState> adapterState =
      ValueNotifier<fbp.BluetoothAdapterState>(
          fbp.BluetoothAdapterState.unknown);

  static const int rssiThreshold = -100;

  fbp.BluetoothDevice? _connectedBleDevice;
  fbs.BluetoothConnection? _classicConnection;
  StreamSubscription<List<fbp.ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanSub;
  StreamSubscription<fbp.BluetoothConnectionState>? _bleConnSub;
  StreamSubscription<fbs.BluetoothDiscoveryResult>? _discoverySub;
  StreamSubscription<List<int>>? _bleDataSub;

  void _initAdapterListener() {
    fbp.FlutterBluePlus.adapterState.listen((state) {
      adapterState.value = state;
    });
  }

  /// Whether the Bluetooth adapter is currently ON.
  bool get isBluetoothOn =>
      adapterState.value == fbp.BluetoothAdapterState.on;

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<String?> requestPermissions() async {
    if (!Platform.isAndroid) return null;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      // Android 12+
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();

      if (statuses.values.any((s) => !s.isGranted)) {
        return 'Bluetooth permissions are required for scanning and connecting.';
      }
    } else {
      // Android 11 or lower
      final statuses = await [
        Permission.bluetooth,
      ].request();

      if (!statuses[Permission.bluetooth]!.isGranted) {
        return 'Bluetooth permission is required for scanning on this device version.';
      }
    }

    return null;
  }

  // ── Enable Bluetooth ──────────────────────────────────────────────────────

  /// Requests permissions, then opens the system dialog to enable Bluetooth.
  /// Returns null on success / already-on, or an error string.
  Future<String?> enableBluetooth() async {
    final permError = await requestPermissions();
    if (permError != null) return permError;

    if (isBluetoothOn) return 'already_on';

    try {
      await fbp.FlutterBluePlus.turnOn();
      // Wait briefly for adapter state to update
      await Future.delayed(const Duration(milliseconds: 500));
      return null;
    } catch (e) {
      return 'Failed to enable Bluetooth: $e';
    }
  }

  // ── Paired / bonded devices ───────────────────────────────────────────────

  // Filter paired Bluetooth devices to include only Nuetech devices
  Future<List<fbs.BluetoothDevice>> getClassicPairedDevices() async {
    try {
      final bonded = await fbs.FlutterBluetoothSerial.instance.getBondedDevices();
      
      // Filter the bonded list to ensure only Nuetech-branded devices are shown in the UI
      return bonded.where((device) {
        final name = (device.name ?? "").toLowerCase();
        
        // Include only valid Nuetech devices: exclude nameless, generic, or non-matching names
        return name.isNotEmpty && 
               name != "unknown device" && 
               name.startsWith("nuetech");
      }).toList();
    } catch (e) {
      debugPrint('BleService: getClassicPairedDevices error – $e');
      return [];
    }
  }

  // ── BLE scanning ──────────────────────────────────────────────────────────

  Future<String?> startBleScan() async {
    if (isScanning.value) return null;
    final permError = await requestPermissions();
    if (permError != null) return permError;

    final state = await fbp.FlutterBluePlus.adapterState.first;
    if (state != fbp.BluetoothAdapterState.on) {
      return 'Bluetooth is turned off. Please enable it.';
    }

    scanResults.value = [];

    await _scanSub?.cancel();
    // Start BLE scan to discover nearby devices and process results in real-time
    _scanSub = fbp.FlutterBluePlus.onScanResults.listen((results) {
      final seen = <String>{};
      final filteredResults = <fbp.ScanResult>[];
      
      for (final r in results) {
        // Extract device name safely
        final name = r.device.platformName.toLowerCase();
        
        // APPLY FILTER: This is a Nuetech-only device picker.
        // We include only devices with the "nuetech" prefix to reduce UI noise.
        final isNuetech = name.isNotEmpty && 
                         name != "unknown device" && 
                         name.startsWith("nuetech");

        if (isNuetech && r.rssi >= rssiThreshold && seen.add(r.device.remoteId.str)) {
          filteredResults.add(r);
        }
      }
      
      // Update global scanResults notifier with the filtered list
      scanResults.value = filteredResults;
    });

    await _isScanSub?.cancel();
    _isScanSub = fbp.FlutterBluePlus.isScanning.listen((v) {
      isScanning.value = v;
    });

    try {
      await fbp.FlutterBluePlus.startScan(
          timeout: const Duration(seconds: 10));
    } catch (e) {
      await stopBleScan();
      return 'BLE scan failed: $e';
    }
    return null;
  }

  Future<void> stopBleScan() async {
    await fbp.FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    await _isScanSub?.cancel();
    _scanSub = null;
    _isScanSub = null;
    isScanning.value = false;
  }

  // ── Classic BT discovery ──────────────────────────────────────────────────

  Future<String?> startClassicDiscovery() async {
    if (isClassicDiscovering.value) return null;
    classicResults.value = [];
    isClassicDiscovering.value = true;

    try {
      await _discoverySub?.cancel();
      // Start Classic Bluetooth discovery to find legacy devices
      _discoverySub = fbs.FlutterBluetoothSerial.instance
          .startDiscovery()
          .listen(
        (r) {
          final name = (r.device.name ?? "").toLowerCase();
          
          // APPLY FILTER: Filter out any device that does not match the Nuetech brand identifier
          final isNuetech = name.isNotEmpty && 
                           name != "unknown device" && 
                           name.startsWith("nuetech");
          
          if (!isNuetech) return;

          final list = List<fbs.BluetoothDiscoveryResult>.from(
              classicResults.value);
          final idx = list
              .indexWhere((e) => e.device.address == r.device.address);
          if (idx >= 0) {
            list[idx] = r;
          } else {
            list.add(r);
          }
          // Update the reactive classicResults list used by the UI components
          classicResults.value = list;
        },
        onDone: () => isClassicDiscovering.value = false,
        onError: (_) => isClassicDiscovering.value = false,
      );

      Future.delayed(const Duration(seconds: 10), stopClassicDiscovery);
    } catch (e) {
      isClassicDiscovering.value = false;
      return 'Classic scan failed: $e';
    }
    return null;
  }

  Future<void> stopClassicDiscovery() async {
    try {
      await fbs.FlutterBluetoothSerial.instance.cancelDiscovery();
    } catch (_) {}
    await _discoverySub?.cancel();
    _discoverySub = null;
    isClassicDiscovering.value = false;
  }

  // ── Unified scan start / stop ─────────────────────────────────────────────

  Future<String?> startScan() async {
    final bleError = await startBleScan();
    final classicError = await startClassicDiscovery();
    if (bleError != null && classicError != null) {
      return '$bleError\n$classicError';
    }
    return null;
  }

  Future<void> stopScan() async {
    await stopBleScan();
    await stopClassicDiscovery();
  }

  // ── BLE connection ────────────────────────────────────────────────────────

  Future<void> connectToDevice(fbp.BluetoothDevice device) async {
    connectionStatus.value = BleConnectionState.CONNECTING;
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connectedBleDevice = device;
      final name = device.platformName.isNotEmpty
          ? device.platformName
          : 'Unknown Device';
      connectedDeviceName.value = name;
      connectedDeviceAddress.value = device.remoteId.str;
      connectionStatus.value = BleConnectionState.CONNECTED;

      await _bleConnSub?.cancel();
      _bleConnSub = device.connectionState.listen((state) {
        if (state == fbp.BluetoothConnectionState.disconnected) {
          connectionStatus.value = BleConnectionState.DISCONNECTED;
          connectedDeviceName.value = null;
          connectedDeviceAddress.value = null;
          _connectedBleDevice = null;
          syncStatus.value = SyncStatus.IDLE;
        }
      });

      // ── Set up persistent BLE listener ────────────────────────────────────
      final services = await device.discoverServices();
      final buffer = StringBuffer();
      
      for (final s in services) {
        for (final c in s.characteristics) {
          if (c.properties.notify || c.properties.indicate) {
            await c.setNotifyValue(true);
            await _bleDataSub?.cancel();
            _bleDataSub = c.onValueReceived.listen((data) {
              final contentReceived = utf8.decode(data, allowMalformed: true);
              buffer.write(contentReceived);
              final content = buffer.toString().trim();
              if (content.split('"').length >= 11) {
                processIncomingData(content);
                buffer.clear();
              }
            });
            break;
          }
        }
      }
      
      // Automatic initial sync after connection
      await initialSync();
      
    } catch (e) {
      debugPrint('BLE connect failed – $e');
      connectionStatus.value = BleConnectionState.DISCONNECTED;
      connectedDeviceName.value = null;
      connectedDeviceAddress.value = null;
    }
  }

  // ── Classic connection ────────────────────────────────────────────────────

  Future<void> connectClassicDevice(String address, String name) async {
    connectionStatus.value = BleConnectionState.CONNECTING;
    try {
      _classicConnection =
          await fbs.BluetoothConnection.toAddress(address);
      connectedDeviceName.value =
          name.isNotEmpty ? name : 'Unknown Device';
      connectedDeviceAddress.value = address;
      connectionStatus.value = BleConnectionState.CONNECTED;

      // ── Set up persistent Classic listener ────────────────────────────────
      final buffer = StringBuffer();
      _classicConnection!.input?.listen(
        (data) {
          buffer.write(utf8.decode(data, allowMalformed: true));
          final content = buffer.toString().trim();
          if (content.split('"').length >= 11) {
            processIncomingData(content);
            buffer.clear();
          }
        },
        onDone: () {
          if (connectionStatus.value == BleConnectionState.CONNECTED) {
            connectionStatus.value = BleConnectionState.DISCONNECTED;
            connectedDeviceName.value = null;
            connectedDeviceAddress.value = null;
            _classicConnection = null;
            syncStatus.value = SyncStatus.IDLE;
          }
        },
      );
      
      // Automatic initial sync after connection
      await initialSync();
      
    } catch (e) {
      debugPrint('Classic connect failed – $e');
      connectionStatus.value = BleConnectionState.DISCONNECTED;
      connectedDeviceName.value = null;
      connectedDeviceAddress.value = null;
    }
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  Future<void> disconnectDevice() async {
    await _bleConnSub?.cancel();
    _bleConnSub = null;
    await _bleDataSub?.cancel();
    _bleDataSub = null;
    await _connectedBleDevice?.disconnect();
    _connectedBleDevice = null;

    try {
      await _classicConnection?.close();
    } catch (_) {}
    _classicConnection = null;

    connectedDeviceName.value = null;
    connectedDeviceAddress.value = null;
    connectionStatus.value = BleConnectionState.DISCONNECTED;
    syncStatus.value = SyncStatus.IDLE;
  }

  // ── Send command ──────────────────────────────────────────────────────────

  /// Send a string command (e.g. "ST=25") over the active connection.
  /// Returns null on success, error string on failure.
  Future<String?> sendCommand(String command) async {
    final isSync = command == 'SYNC';
    
    // ── Try Classic first ──────────────────────────────────────────────
    if (_classicConnection != null && _classicConnection!.isConnected) {
      try {
        _classicConnection!.output.add(
            Uint8List.fromList(utf8.encode('$command\n')));
        await _classicConnection!.output.allSent;
        if (!isSync) {
          // Background sync after SET command
          unawaited(sendSyncCommand());
        }
        return null;
      } catch (e) {
        debugPrint('Classic send failed: $e');
        return 'Send failed: $e';
      }
    }

    // ── Try BLE write ──────────────────────────────────────────────────
    if (_connectedBleDevice != null) {
      try {
        final services = await _connectedBleDevice!.discoverServices();
        for (final s in services) {
          for (final c in s.characteristics) {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              await c.write(utf8.encode('$command\n'),
                  withoutResponse: c.properties.writeWithoutResponse);
              if (!isSync) {
                // Background sync after SET command
                unawaited(sendSyncCommand());
              }
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

  // ── Incoming Data Processing ──────────────────────────────────────────────

  /// Decodes the `"` delimited sync string.
  /// Format: ST"TT"COILSTATUS"S1SHH"S2SHH"S1SMM"S2SMM"S1EHH"S2EHH"S1EMM"S2EMM
  /// Example: 50"48"1"1"13"0"0"12"23"0"59
  void processIncomingData(String message) {
    try {
      final data = message.trim();
      final parts = data.split('"');
      
      if (parts.length < 11) {
        debugPrint('Invalid controller data received: length=${parts.length}');
        return;
      }

      // Extract using delimited indexes
      final stStr = parts[0];
      final ttStr = parts[1];
      final coilStr = parts[2];
      final s1sh = parts[3];
      final s2sh = parts[4];
      final s1sm = parts[5];
      final s2sm = parts[6];
      final s1eh = parts[7];
      final s2eh = parts[8];
      final s1em = parts[9];
      final s2em = parts[10];

      final temp = int.tryParse(stStr);
      final tankTemp = ttStr; // Keep as string to support "ERR"
      final coilStatus = int.tryParse(coilStr);

      // Format time strings (HH:MM or H:MM) - padding is handled by UI if needed, but let's ensure standard formatting
      String formatTime(String h, String m) => '${h.padLeft(2, '0')}:${m.padLeft(2, '0')}';
      
      final s1s = formatTime(s1sh, s1sm);
      final s1e = formatTime(s1eh, s1em);
      final s2s = formatTime(s2sh, s2sm);
      final s2e = formatTime(s2eh, s2em);

      syncData.value = SyncData(
        temperature: temp,
        tankTemp: tankTemp,
        coilStatus: coilStatus,
        slot1Start: s1s,
        slot1End: s1e,
        slot2Start: s2s,
        slot2End: s2e,
      );
    } catch (e) {
      debugPrint('Error parsing incoming data: $e');
    }
  }

  // ── SYNC command ──────────────────────────────────────────────────────────

  /// Initial sync automatically called on connection.
  Future<void> initialSync() async {
    try {
      await sendSyncCommand();
    } catch (e) {
      debugPrint('Initial sync failed: $e');
      // Failure handled by UI observing syncStatus
    }
  }

  /// Sends "SYNC" to the ESP32 and waits for the listener to pick up new data.
  Future<void> sendSyncCommand() async {
    if (syncStatus.value == SyncStatus.SYNCING) return;
    
    syncStatus.value = SyncStatus.SYNCING;
    
    try {
      final error = await sendCommand('SYNC');
      if (error != null) throw error;

      final completer = Completer<void>();
      void listener() {
        if (!completer.isCompleted) completer.complete();
      }
      
      syncData.addListener(listener);
      try {
        await completer.future.timeout(const Duration(seconds: 5));
        syncStatus.value = SyncStatus.SUCCESS;
        // Briefly keep success state, then revert to idle if needed (though UI handles mapped logic)
        unawaited(Future.delayed(const Duration(seconds: 2), () {
          if (syncStatus.value == SyncStatus.SUCCESS) {
            syncStatus.value = SyncStatus.IDLE;
          }
        }));
      } on TimeoutException {
        syncStatus.value = SyncStatus.FAILED;
        throw 'Sync timeout. No response received.';
      } catch (e) {
        syncStatus.value = SyncStatus.FAILED;
        throw e.toString();
      } finally {
        syncData.removeListener(listener);
      }
    } catch (e) {
      syncStatus.value = SyncStatus.FAILED;
      rethrow;
    }
  }
}


