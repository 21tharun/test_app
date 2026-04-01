import 'package:flutter/material.dart';
import '../screens/my_device_screen.dart';
import '../screens/temperature_control_screen.dart';
import '../screens/bluetooth_connection_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/about_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      width: screenWidth * 0.85,
      child: Drawer(
        backgroundColor: const Color(0xFFFFFFFF),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header Card (same style as original)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/test_app_logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Nuetech Controller',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Smart Water Heater',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Menu Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [

                    // ⭐ Controller (Home)
                    _MenuCard(
                      icon: Icons.thermostat,
                      title: 'Controller',
                      subtitle: 'Temperature & scheduler',
                      iconColor: const Color(0xFFF97316),
                      iconBgColor: const Color(0xFFFFEDD5),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const TemperatureControlScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // My Device
                    _MenuCard(
                      icon: Icons.water_drop_outlined,
                      title: 'My Device',
                      subtitle: 'Manage your device',
                      iconColor: const Color(0xFF3B82F6),
                      iconBgColor: const Color(0xFFDBEAFE),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const MyDeviceScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Bluetooth Connect (manual — no auto redirect to controller)
                    _MenuCard(
                      icon: Icons.bluetooth,
                      title: 'Bluetooth Connect',
                      subtitle: 'Pair & manage devices',
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: const Color(0xFFEDE9FE),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BluetoothConnectionScreen(
                              redirectToController: false,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Profile (placeholder)
                    _MenuCard(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: 'Coming soon',
                      iconColor: const Color(0xFF0EA5E9),
                      iconBgColor: const Color(0xFFE0F2FE),
                      onTap: () {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profile — coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // Contact
                    _MenuCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Contact',
                      subtitle: 'Support & feedback',
                      iconColor: const Color(0xFFA855F7),
                      iconBgColor: const Color(0xFFF3E8FF),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ContactScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // About
                    _MenuCard(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App & version info',
                      iconColor: const Color(0xFF10B981),
                      iconBgColor: const Color(0xFFD1FAE5),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor   = const Color(0xFF3B82F6),
    this.iconBgColor = const Color(0xFFDBEAFE),
  });

  final IconData     icon;
  final String       title;
  final String       subtitle;
  final VoidCallback onTap;
  final Color        iconColor;
  final Color        iconBgColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6B7280),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}