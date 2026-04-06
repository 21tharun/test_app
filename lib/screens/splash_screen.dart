import 'dart:async';
import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        _navigate();
      }
    });
  }

  void _navigate() {
    final ble = BleService.instance;
    final isConnected = ble.connectionStatus.value == BleConnectionState.CONNECTED;

    Navigator.of(context).pushReplacementNamed(
      isConnected ? '/temperature_control' : '/bluetooth_connect',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Solid white background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // App Logo
            Image.asset(
              'assets/test_app_logo.png',
              width: 160, // Slightly larger for emphasis as it's the only element
              height: 160,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }
}


