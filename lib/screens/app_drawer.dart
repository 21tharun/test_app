import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../screens/my_device_screen.dart';
import '../screens/temperature_control_screen.dart';
import '../screens/bluetooth_connection_screen.dart';
import '../screens/contact_screen.dart';
import '../screens/about_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://docs.google.com/document/d/1XW_1yq9yidpXREdD-FqW3e7vT3_6A7E8/view');
    try {
      if (!await launchUrl(url, mode: LaunchMode.platformDefault)) {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width,
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30, left: 24, right: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Image.asset(
                        'assets/test_app_logo.png',
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Nuetech Controller',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Text(
                      'Smart Water Heater System',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),

          // ── Menu List ─────────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              children: [
                _SectionHeader(title: 'MAIN'),
                _DrawerItem(
                  icon: Icons.thermostat_outlined,
                  title: 'Controller',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const TemperatureControlScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.water_drop_outlined,
                  title: 'My Device',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MyDeviceScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.bluetooth_outlined,
                  title: 'Bluetooth Connect',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BluetoothConnectionScreen()),
                    );
                  },
                ),

                const SizedBox(height: 10),
                _SectionHeader(title: 'SUPPORT'),
                _DrawerItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Contact Us',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ContactScreen()),
                    );
                  },
                ),
                _DrawerItem(
                  icon: Icons.info_outline,
                  title: 'About App',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AboutScreen()),
                    );
                  },
                ),

                const SizedBox(height: 10),
                _SectionHeader(title: 'LEGAL'),
                _DrawerItem(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy Policy',
                  onTap: () {
                    Navigator.pop(context);
                    _launchPrivacyPolicy();
                  },
                ),
              ],
            ),
          ),

          // ── Footer ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Version 2.0.4',
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          onTap: onTap,
          hoverColor: const Color(0xFFF1F5F9),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ],
    );
  }
}
