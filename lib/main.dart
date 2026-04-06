import 'package:flutter/material.dart';
import 'screens/app_router.dart';
import 'screens/bluetooth_connection_screen.dart';
import 'screens/temperature_control_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/my_device_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuetech Controller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const AppRouter(),
      routes: {
        '/bluetooth_connect': (_) => const BluetoothConnectionScreen(),
        '/temperature_control': (_) => const TemperatureControlScreen(),
        '/about': (_) => const AboutScreen(),
        '/contact': (_) => const ContactScreen(),
        '/qr_scanner': (_) => const QrScannerScreen(),
        '/onboarding': (_) => const OnboardingScreen(),
        '/my_device': (_) => const MyDeviceScreen(),
      },
    );
  }
}

