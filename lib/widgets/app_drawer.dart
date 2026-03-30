import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine the safe width for the drawer
    final screenWidth = MediaQuery.of(context).size.width;
    
    return SizedBox(
      width: screenWidth * 0.85, // 85% of screen width
      child: Drawer(
        backgroundColor: const Color(0xFFFFFFFF), // White background
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Header Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)], // Soft blue gradients
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
                        color: const Color(0xFF10B981), // Emerald green bg
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
                            'Test App',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'This is a test version',
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
                    _MenuCard(
                      icon: Icons.bluetooth,
                      title: 'Bluetooth Connect',
                      subtitle: 'Pair & manage devices',
                      onTap: () {
                        Navigator.of(context).pop();
                        if (ModalRoute.of(context)?.settings.name != '/bluetooth_connect') {
                          Navigator.of(context).pushReplacementNamed('/bluetooth_connect');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      icon: Icons.thermostat,
                      title: 'Temperature Control',
                      subtitle: 'Set target & monitor',
                      iconColor: const Color(0xFFF97316), // Orange
      iconBgColor: const Color(0xFFFFEDD5), // Light Orange Bg
                      onTap: () {
                        Navigator.of(context).pop();
                        if (ModalRoute.of(context)?.settings.name != '/temperature_control') {
                          Navigator.of(context).pushReplacementNamed('/temperature_control');
                        }
                      },
                    ),

                    const SizedBox(height: 12),
                    _MenuCard(
                      icon: Icons.chat_bubble_outline,
                      title: 'Contact',
                      subtitle: 'Support & feedback',
                      iconColor: const Color(0xFFA855F7), // Purple
                      iconBgColor: const Color(0xFFF3E8FF), // Light Purple Bg
                      onTap: () {
                        Navigator.of(context).pop();
                        if (ModalRoute.of(context)?.settings.name != '/contact') {
                          Navigator.of(context).pushReplacementNamed('/contact');
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    _MenuCard(
                      icon: Icons.info_outline,
                      title: 'About',
                      subtitle: 'App & version info',
                      iconColor: const Color(0xFF10B981), // Green
                      iconBgColor: const Color(0xFFD1FAE5), // Light Green Bg
                      onTap: () {
                        Navigator.of(context).pop();
                        if (ModalRoute.of(context)?.settings.name != '/about') {
                          Navigator.of(context).pushReplacementNamed('/about');
                        }
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
    this.iconColor = const Color(0xFF3B82F6), // Blue
    this.iconBgColor = const Color(0xFFDBEAFE),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;
  final Color iconBgColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF), // White card
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
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
                      color: Color(0xFF0F172A), // Slate 900
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF64748B), // Slate 500
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF6B7280), // Gray-500
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
