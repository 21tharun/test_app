import 'package:flutter/material.dart';
import '../widgets/main_app_bar.dart';
import 'app_drawer.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Center(
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 48,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Test App — Internal Validation Version',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'This is a test version of the application used for internal testing and Play Store submission validation. It is a smart controller for solar water heaters, allowing you to set schedules and targets via Bluetooth.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF475569),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
                      ),
                      const Text(
                        'App Description',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'The Test App connects your smartphone to the solar water heater controller using Bluetooth. It allows users to configure heating schedules and set temperature targets for efficient and automated water heating.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF475569),
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 32),
                      const Center(
                        child: Text(
                          'Test Version: No personal data sharing.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


