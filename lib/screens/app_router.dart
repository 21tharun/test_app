import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'onboarding_screen.dart';
import 'my_device_screen.dart';
import 'temperature_control_screen.dart';

class AppRouter extends StatefulWidget {
  const AppRouter({super.key});

  @override
  State<AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<AppRouter> {
  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;
    final deviceAdded = prefs.getBool('deviceAdded') ?? false;

    if (!mounted) return;

    Widget destination;

    if (!seenOnboarding) {
      // First-time user → Onboarding
      destination = const OnboardingScreen();
    } else if (!deviceAdded) {
      // Seen onboarding but no device → My Device (empty state)
      // Also double-check DB in case deviceAdded flag was lost
      final devices = await DatabaseHelper().getAllDevices();
      if (devices.isNotEmpty) {
        // Device exists in DB but flag was false — fix it
        await prefs.setBool('deviceAdded', true);
        destination = const TemperatureControlScreen();
      } else {
        destination = const MyDeviceScreen();
      }
    } else {
      // Returning user with device → Controller
      destination = const TemperatureControlScreen();
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Brief loading screen while SharedPreferences are read
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3B82F6),
        ),
      ),
    );
  }
}
