import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/bluetooth_service.dart';
import '../services/database_helper.dart';
import '../widgets/main_app_bar.dart';
import 'app_drawer.dart';
import '../widgets/time_picker_wheel.dart';
import 'bluetooth_connection_screen.dart';

class TemperatureControlScreen extends StatefulWidget {
  const TemperatureControlScreen({super.key});

  @override
  State<TemperatureControlScreen> createState() =>
      _TemperatureControlScreenState();
}

class _TemperatureControlScreenState extends State<TemperatureControlScreen>
    with SingleTickerProviderStateMixin {
  final BleService _ble = BleService.instance;

  double _temperature = 25;
  bool _syncing = false;
  bool _settingTemp = false;
  bool _isSliding = false;
  bool _isEditingSlot1 = false;
  bool _isEditingSlot2 = false;

  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  // Dynamic title from stored device
  String _deviceTitle = 'Nuetech Controller';

  TimeOfDay? _s1Start;
  TimeOfDay? _s1End;
  TimeOfDay? _s2Start;
  TimeOfDay? _s2End;

  static const int MIN_SLOT_DURATION = 30;
  String? _s1Error;
  String? _s2Error;
  bool _isValidSlot1 = true;
  bool _isValidSlot2 = true;

  @override
  void initState() {
    super.initState();
    _ble.syncData.addListener(_onSyncDataUpdated);
    _ble.syncStatus.addListener(_onSyncStatusUpdated);
    _loadDeviceTitle();
    _checkBluetoothOnOpen();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _glowAnimation = CurvedAnimation(parent: _glowController, curve: Curves.linear);

    final initialData = _ble.syncData.value;
    if (initialData != null) {
      _temperature = initialData.temperature?.toDouble() ?? _temperature;
    }
  }

  @override
  void dispose() {
    _ble.syncData.removeListener(_onSyncDataUpdated);
    _ble.syncStatus.removeListener(_onSyncStatusUpdated);
    _glowController.dispose();
    super.dispose();
  }

  // ── Load device name for AppBar title ────────────────────────────────────

  Future<void> _loadDeviceTitle() async {
    final devices = await DatabaseHelper().getAllDevices();
    if (devices.isNotEmpty && mounted) {
      setState(() {
        _deviceTitle = devices.first.name ??
            devices.first.serialNumber;
      });
    }
  }

  // ── Bluetooth pre-check on screen open ───────────────────────────────────

  void _checkBluetoothOnOpen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final connected =
          _ble.connectionStatus.value == BleConnectionState.CONNECTED;
      if (!connected && mounted) {
        _showNotConnectedDialog();
      }
    });
  }

  void _showNotConnectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Device Not Connected',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
          'Please connect via Bluetooth to use the controller.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BluetoothConnectionScreen(
                    redirectToController: true,
                  ),
                ),
              );
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  // ── Everything below is UNCHANGED from original ───────────────────────────

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) return null;
    final parts = timeStr.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) return TimeOfDay(hour: h, minute: m);
    }
    return null;
  }

  void _onSyncDataUpdated() {
    final sd = _ble.syncData.value;
    if (sd != null && !_isSliding) {
      if (mounted &&
          _temperature != (sd.temperature?.toDouble() ?? _temperature)) {
        setState(() =>
            _temperature = sd.temperature?.toDouble() ?? _temperature);
      }
      if (!_isEditingSlot1) {
        setState(() {
          _s1Start = _parseTime(sd.slot1Start) ?? _s1Start;
          _s1End = _parseTime(sd.slot1End) ?? _s1End;
        });
      }
      if (!_isEditingSlot2) {
        setState(() {
          _s2Start = _parseTime(sd.slot2Start) ?? _s2Start;
          _s2End = _parseTime(sd.slot2End) ?? _s2End;
        });
      }
      _validateSlots();
    }
  }

  void _onSyncStatusUpdated() {
    if (_ble.syncStatus.value == SyncStatus.SUCCESS) {
      _glowController.forward(from: 0.0);
    } else if (_ble.syncStatus.value == SyncStatus.FAILED && !_settingTemp) {
      // Only show general sync failure if we are NOT in a SET update flow
      // as the SET flow handles its own specific retry logic.
      _showSyncFailedDialog();
    }
  }

  void _showSyncFailedDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sync Failed', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Could not sync with device. Please check connection and try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _ble.sendSyncCommand().catchError((e) {
                // Error already handled by notification
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _validateSlots() {
    setState(() {
      _s1Error = null;
      _s2Error = null;
      _isValidSlot1 = true;
      _isValidSlot2 = true;

      if (_s1Start != null && _s1End != null) {
        final startMin = _s1Start!.hour * 60 + _s1Start!.minute;
        final endMin = _s1End!.hour * 60 + _s1End!.minute;
        final duration = endMin - startMin;
        if (startMin < 0 || endMin > 12 * 60) {
          _s1Error = 'Slot 1 time must be between 00:00 and 12:00';
          _isValidSlot1 = false;
        } else if (duration < MIN_SLOT_DURATION) {
          _s1Error = 'Minimum slot duration must be 30 minutes';
          _isValidSlot1 = false;
        } else if (duration > 180) {
          _s1Error = 'Maximum slot duration must be 3 hours';
          _isValidSlot1 = false;
        }
      }

      if (_s2Start != null && _s2End != null) {
        final startMin = _s2Start!.hour * 60 + _s2Start!.minute;
        final endMin = _s2End!.hour * 60 + _s2End!.minute;
        final duration = endMin - startMin;
        if (startMin < 12 * 60 || endMin > 24 * 60) {
          _s2Error = 'Slot 2 time must be between 12:00 and 24:00';
          _isValidSlot2 = false;
        } else if (duration < MIN_SLOT_DURATION) {
          _s2Error = 'Minimum slot duration must be 30 minutes';
          _isValidSlot2 = false;
        } else if (duration > 180) {
          _s2Error = 'Maximum slot duration must be 3 hours';
          _isValidSlot2 = false;
        }
      }
    });
  }

  void _showCenterAlert(String message, bool isSuccess) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 48,
        ),
        content: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16)),
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


  Future<void> _setTemperature() async {
    // 🚫 Prevent multiple simultaneous SET operations
    if (_settingTemp || _ble.syncStatus.value == SyncStatus.SYNCING) return;

    setState(() => _settingTemp = true);

    try {
      // Step 1: Send payload to device
      final command = 'ST=${_temperature.round()}';
      final error = await _ble.sendCommand(command);

      if (error != null) {
        _handleUpdateFailure("Send failed: $error", () => _setTemperature());
        return;
      }

      // Step 2: App-controlled processing delay (FINAL 1.5s)
      await Future.delayed(const Duration(milliseconds: 2500));

      // Step 3: Trigger sync AFTER device finishes processing
      try {
        await _ble.sendSyncCommand();
        // Step 4: Keep interaction locked during success feedback (aligned with flow)
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        _handleUpdateFailure("Sync verification failed. Retry?", () => _setTemperature());
      }
    } finally {
      if (mounted) setState(() => _settingTemp = false);
    }
  }

  void _handleUpdateFailure(String message, VoidCallback onRetry) {
    if (!mounted) return;
    
    // Reset state since sync failed
    setState(() => _settingTemp = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Device update failed', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              onRetry();
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Color get _dynamicColor {
    if (_temperature < 30) return const Color(0xFF3B82F6);
    if (_temperature < 40) return const Color(0xFFF59E0B);
    if (_temperature < 50) return const Color(0xFFF97316);
    return const Color(0xFFEF4444);
  }

  IconData get _dynamicIcon {
    if (_temperature < 30) return Icons.ac_unit;
    if (_temperature < 40) return Icons.wb_sunny_outlined;
    if (_temperature < 50) return Icons.wb_sunny;
    return Icons.local_fire_department;
  }

  String get _dynamicText {
    if (_temperature < 30) return 'Cold';
    if (_temperature < 40) return 'Warm';
    if (_temperature < 50) return 'Hot';
    return 'Very Hot';
  }

  Animation<double> get _glowOpacity => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.35), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.0), weight: 50),
      ]).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

  Animation<double> get _glowBorder => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 2.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 2.0, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

  Animation<double> get _glowSpread => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: 6.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 50),
      ]).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

  Animation<double> get _glowBlur => TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 6.0, end: 14.0), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 14.0, end: 6.0), weight: 50),
      ]).animate(CurvedAnimation(parent: _glowController, curve: Curves.easeOut));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MainAppBar(title: _deviceTitle), // ← dynamic title
      drawer: const AppDrawer(),
      body: SafeArea(
        child: ValueListenableBuilder<SyncData?>(
          valueListenable: _ble.syncData,
          builder: (context, syncData, child) {
            final connected = _ble.connectionStatus.value ==
                BleConnectionState.CONNECTED;
            final displayTank = syncData?.tankTemp ?? '--';
            final displayCoil = syncData?.coilStatus ?? -1;

            return SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Upper Card: Temperature Control ──────────────────
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value),
                            blurRadius: _glowBlur.value,
                            spreadRadius: _glowSpread.value,
                          ),
                        ],
                      ),
                      child: Card(
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value > 0 ? 0.8 : 0.0),
                            width: _glowBorder.value,
                          ),
                        ),
                        // Fallback edge color when not glowing
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Row(
                                  children: [
                                    Icon(_dynamicIcon,
                                        color: _dynamicColor, size: 22),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'TEMPERATURE CONTROL',
                                          style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.0,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          colors: [
                                            _dynamicColor.withValues(
                                                alpha: 0.7),
                                            _dynamicColor
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.bottomLeft,
                                            child: Text(
                                              '${_temperature.round()}',
                                              style:
                                                  GoogleFonts.jetBrainsMono(
                                                fontSize: 84,
                                                height: 1.0,
                                                fontWeight: FontWeight.w400,
                                                color:
                                                    const Color(0xFF0F172A),
                                              ),
                                            ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          top: 12.0, right: 16.0),
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            LinearGradient(
                                          colors: [
                                            _dynamicColor,
                                            _dynamicColor.withValues(
                                                alpha: 0.8)
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ).createShader(bounds),
                                        child: Text(
                                          '°C',
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w400,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Set point',
                                      style: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 13)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(_dynamicIcon,
                                          color: _dynamicColor, size: 16),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(_dynamicText,
                                              style: TextStyle(
                                                  color: _dynamicColor,
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    activeTrackColor: _dynamicColor,
                                    inactiveTrackColor:
                                        const Color(0xFFE2E8F0),
                                    trackHeight: 8,
                                    thumbColor: Colors.white,
                                    thumbShape:
                                        const RoundSliderThumbShape(
                                            enabledThumbRadius: 12,
                                            elevation: 6),
                                    overlayColor: _dynamicColor
                                        .withValues(alpha: 0.3),
                                    activeTickMarkColor: Colors.transparent,
                                    inactiveTickMarkColor:
                                        Colors.transparent,
                                  ),
                                  child: Slider(
                                    value: _temperature.clamp(20, 60),
                                    min: 20,
                                    max: 60,
                                    divisions: 40,
                                    onChangeStart: (v) =>
                                        _isSliding = true,
                                    onChangeEnd: (v) =>
                                        _isSliding = false,
                                    onChanged: (v) =>
                                        setState(() => _temperature = v),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: (connected && !_settingTemp)
                                      ? _setTemperature
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color(0xFF3B82F6),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20),
                                  ),
                                  child: const Text('SET',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _glowController,
                                    builder: (context, child) => Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value > 0 ? 0.8 : 0.0),
                                          width: _glowBorder.value,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value),
                                            blurRadius: _glowBlur.value,
                                            spreadRadius: _glowSpread.value,
                                          ),
                                        ],
                                      ),
                                      foregroundDecoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: child,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.water_drop, color: Color(0xFF6B7280), size: 16),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text('TANK TEMP',
                                                    style: TextStyle(
                                                        color: Color(0xFF6B7280),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text('$displayTank °C',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.jetBrainsMono(
                                                  color: const Color(0xFF0F172A),
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.w500)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: AnimatedBuilder(
                                    animation: _glowController,
                                    builder: (context, child) => Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value > 0 ? 0.8 : 0.0),
                                          width: _glowBorder.value,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value),
                                            blurRadius: _glowBlur.value,
                                            spreadRadius: _glowSpread.value,
                                          ),
                                        ],
                                      ),
                                      foregroundDecoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: child,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: const [
                                            Icon(Icons.adjust, color: Color(0xFF6B7280), size: 16),
                                            SizedBox(width: 4),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text('COIL STATUS',
                                                    style: TextStyle(
                                                        color: Color(0xFF6B7280),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        letterSpacing: 0.5)),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            displayCoil == 1
                                                ? 'ON'
                                                : displayCoil == 0
                                                    ? 'OFF'
                                                    : displayCoil == 2
                                                        ? 'Error'
                                                        : '--',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.jetBrainsMono(
                                              color: displayCoil == 1
                                                  ? const Color(0xFF10B981)
                                                  : displayCoil == 2
                                                      ? const Color(0xFFEF4444)
                                                      : const Color(0xFF6B7280),
                                              fontSize: 24,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSlotSchedulerSection(connected),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _setSlot(int slotNumber) async {
    // 🚫 Prevent parallel slot updates or temp updates
    if (_settingTemp || _ble.syncStatus.value == SyncStatus.SYNCING) return;

    _validateSlots();
    final isValid = slotNumber == 1 ? _isValidSlot1 : _isValidSlot2;
    if (!isValid) return;

    final start = slotNumber == 1 ? _s1Start : _s2Start;
    final end = slotNumber == 1 ? _s1End : _s2End;

    if (start == null || end == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select both start and end times.')));
      return;
    }

    setState(() => _settingTemp = true);

    try {
      final startStr =
          '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
      final endStr =
          '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

      // Step 1: Send Start time
      final err1 = await _ble.sendCommand('S${slotNumber}S=$startStr');
      if (err1 != null) {
        _handleUpdateFailure("Send failed: $err1", () => _setSlot(slotNumber));
        return;
      }

      await Future.delayed(const Duration(milliseconds: 200));

      // Step 2: Send End time
      final err2 = await _ble.sendCommand('S${slotNumber}E=$endStr');
      if (err2 != null) {
        _handleUpdateFailure("Send failed: $err2", () => _setSlot(slotNumber));
        return;
      }

      // Step 3: App-controlled processing delay (FINAL 1.5s)
      await Future.delayed(const Duration(milliseconds: 1500));

      // Step 4: Trigger sync AFTER device finishes processing
      try {
        await _ble.sendSyncCommand();
        // Step 5: Keep interaction locked during success feedback
        await Future.delayed(const Duration(seconds: 2));
      } catch (e) {
        _handleUpdateFailure("Sync verification failed. Retry?", () => _setSlot(slotNumber));
      }
    } finally {
      if (mounted) setState(() => _settingTemp = false);
    }
  }

  Widget _buildSlotSchedulerSection(bool connected) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 2),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              Icon(Icons.schedule, color: Color(0xFF475569), size: 18),
              SizedBox(width: 8),
              Text(
                'SLOT TIME SCHEDULER',
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSlotCard(
            label: 'SLOT 1',
            slot: 1,
            start: _s1Start,
            end: _s1End,
            enabled: connected,
            isValid: _isValidSlot1,
            error: _s1Error,
            onStartTap: () => _pickTime(1, true),
            onEndTap: () => _pickTime(1, false),
            onSet: () => _setSlot(1),
          ),
          const SizedBox(height: 16),
          _buildSlotCard(
            label: 'SLOT 2',
            slot: 2,
            start: _s2Start,
            end: _s2End,
            enabled: connected,
            isValid: _isValidSlot2,
            error: _s2Error,
            onStartTap: () => _pickTime(2, true),
            onEndTap: () => _pickTime(2, false),
            onSet: () => _setSlot(2),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard({
    required String label,
    required int slot,
    required TimeOfDay? start,
    required TimeOfDay? end,
    required bool enabled,
    required bool isValid,
    required String? error,
    required VoidCallback onStartTap,
    required VoidCallback onEndTap,
    required VoidCallback onSet,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
          child: Text(label,
              style: const TextStyle(
                  color: Color(0xFF1E3A8A),
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, child) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value),
                  blurRadius: _glowBlur.value,
                  spreadRadius: _glowSpread.value,
                ),
              ],
            ),
            child: Card(
              margin: EdgeInsets.zero,
              elevation: 1,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF3B82F6).withValues(alpha: _glowOpacity.value > 0 ? 0.8 : 0.0),
                  width: _glowBorder.value,
                ),
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12.0, vertical: 16.0),
                  child: child,
                ),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    _buildTimeSelector(
                        label: 'START',
                        slot: slot,
                        isStart: true,
                        time: start,
                        onTap: onStartTap),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Icon(Icons.arrow_forward,
                          size: 16, color: Color(0xFF94A3B8)),
                    ),
                    _buildTimeSelector(
                        label: 'END',
                        slot: slot,
                        isStart: false,
                        time: end,
                        onTap: onEndTap),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                height: 48,
                child: ElevatedButton(
                  onPressed: (enabled && isValid) ? onSet : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF94A3B8),
                    elevation: (enabled && isValid) ? 2 : 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('SET',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          letterSpacing: 0.5)),
                ),
              ),
            ],
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 12.0),
            child: Text(error,
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
          ),
      ],
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required int slot,
    required bool isStart,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    final hh = time?.hour.toString().padLeft(2, '0') ?? '00';
    final mm = time?.minute.toString().padLeft(2, '0') ?? '00';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 6.0),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTimeBox(hh, onTap),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(':',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569))),
            ),
            _buildTimeBox(mm, onTap),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeBox(String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        constraints: const BoxConstraints(minWidth: 44),
        child: Center(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E40AF))),
        ),
      ),
    );
  }

  Future<void> _pickTime(int slot, bool isStart) async {
    final initialTime = slot == 1
        ? (isStart ? _s1Start : _s1End)
        : (isStart ? _s2Start : _s2End);

    if (slot == 1)
      _isEditingSlot1 = true;
    else
      _isEditingSlot2 = true;

    final t = await showDialog<TimeOfDay>(
      context: context,
      builder: (context) {
        int currentHour = initialTime?.hour ?? 0;
        int currentMin = initialTime?.minute ?? 0;
        int minH = (slot == 1) ? 0 : 12;
        int maxH = (slot == 1) ? 12 : 23;

        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TimePickerWheel(
                  enabled: true,
                  initialHour: currentHour,
                  initialMinute: currentMin,
                  minHour: minH,
                  maxHour: maxH,
                  onTimeChanged: (h, m) {
                    currentHour = h;
                    currentMin = m;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xFF3B82F6))),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(
                          TimeOfDay(
                              hour: currentHour, minute: currentMin)),
                      child: const Text('OK',
                          style: TextStyle(
                              fontSize: 16, color: Color(0xFF3B82F6))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (slot == 1)
      _isEditingSlot1 = false;
    else
      _isEditingSlot2 = false;

    if (t != null) {
      setState(() {
        if (slot == 1) {
          if (isStart) {
            _s1Start = t;
            _s1End =
                TimeOfDay(hour: (t.hour + 3) % 24, minute: t.minute);
          } else {
            _s1End = t;
          }
        } else {
          if (isStart) {
            _s2Start = t;
            _s2End =
                TimeOfDay(hour: (t.hour + 3) % 24, minute: t.minute);
          } else {
            _s2End = t;
          }
        }
      });
      _validateSlots();
    }
  }
}
