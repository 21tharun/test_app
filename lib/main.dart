import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/bluetooth_connection_screen.dart';
import 'screens/device_list_screen.dart';
import 'screens/temperature_control_screen.dart';
import 'screens/about_screen.dart';
import 'screens/contact_screen.dart';
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
      title: 'Test App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/bluetooth_connect': (_) => const BluetoothConnectionScreen(),
        '/device_scan': (_) => const DeviceListScreen(),
        '/temperature_control': (_) => const TemperatureControlScreen(),
        '/about': (_) => const AboutScreen(),
        '/contact': (_) => const ContactScreen(),
      },
    );
  }
}
