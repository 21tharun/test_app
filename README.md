# Test App – Bluetooth Microcontroller Connector

A feature-rich Flutter application for seamless Bluetooth connectivity and communication with microcontroller devices. This app provides real-time data transmission, QR code scanning, and local database management capabilities.

## 📱 Overview

**Test App** is a cross-platform mobile application built with Flutter that enables users to connect to and interact with Bluetooth-enabled microcontroller devices. It offers an intuitive interface for managing connections, scanning QR codes, and persisting data locally.

### Key Technologies

- **Frontend**: Flutter/Dart (80.9%)
- **Native Modules**: C++ (9.6%), Swift (1%), C (0.6%)
- **Build System**: CMake (7.4%)
- **Markup**: HTML (0.5%)

## ✨ Features

### Bluetooth Connectivity
- **Multiple Bluetooth Libraries**: Support for both `flutter_blue_plus` and `flutter_bluetooth_serial`
- **Device Discovery**: Scan and discover nearby Bluetooth devices
- **Real-time Communication**: Establish and maintain stable connections with microcontrollers
- **Connection Management**: Easy pairing and connection handling

### Device Scanning & Integration
- **QR Code Scanner**: Built-in mobile scanner for quick device registration
- **Device Information**: Retrieve and display device metadata and capabilities
- **App Linking**: Support for deep links and app-to-app communication

### Data Management
- **Local Database**: SQLite integration for persistent local storage
- **Preferences**: Shared preferences for app configuration and user settings
- **File System**: Efficient path management for data storage

### User Interface
- **Material Design**: Modern, responsive UI following Material Design principles
- **Custom Fonts**: Google Fonts integration for enhanced typography
- **Cupertino Icons**: Comprehensive icon library for iOS compatibility
- **Cross-Platform**: Optimized for both iOS and Android platforms

### Permissions & Security
- **Runtime Permissions**: Comprehensive permission handler for Android 12+ and iOS requirements
- **Permission Management**: Granular control over Bluetooth and location permissions
- **Device-Specific Handling**: Adaptive icon generation for Android devices

## 🛠️ Technology Stack

### Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter` | Latest | Core framework |
| `flutter_blue_plus` | ^1.31.15 | Bluetooth Low Energy (BLE) connectivity |
| `flutter_bluetooth_serial` | ^0.4.0 | Classic Bluetooth connectivity |
| `permission_handler` | ^11.3.1 | Runtime permissions management |
| `mobile_scanner` | ^5.2.3 | QR code scanning |
| `device_info_plus` | ^11.3.0 | Device information retrieval |
| `sqflite` | ^2.3.3 | Local SQLite database |
| `shared_preferences` | ^2.2.3 | Key-value storage |
| `google_fonts` | ^8.0.2 | Custom font support |
| `url_launcher` | ^6.3.0 | External link handling |
| `app_links` | ^6.3.2 | Deep linking support |

### Development Dependencies

- `flutter_test` - Unit and widget testing framework
- `flutter_lints` - Lint rules for code quality
- `flutter_launcher_icons` - Icon generation

## 📋 Requirements

### Minimum Versions
- **Flutter SDK**: ^3.4.0
- **Android SDK**: API 21 and above
- **Dart SDK**: 3.4.0 or higher

### Platform-Specific Requirements

**Android:**
- Minimum SDK: API 21
- Bluetooth permissions (runtime)
- Location permissions (for Bluetooth scanning)

**iOS:**
- iOS 11.0 and above
- Bluetooth (NSBluetoothPeripheralUsageDescription)
- Location permissions (if required)

## 🚀 Getting Started

### Prerequisites

Ensure you have the following installed:
- Flutter SDK (3.4.0 or higher)
- Dart SDK (included with Flutter)
- Android Studio or Xcode
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/21tharun/test_app.git
   cd test_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate launcher icons**
   ```bash
   flutter pub run flutter_launcher_icons:main
   ```

4. **Run the app**
   ```bash
   # Debug mode
   flutter run

   # Release mode
   flutter run --release
   ```

### Building for Production

**Android (APK):**
```bash
flutter build apk --release
```

**Android (App Bundle):**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📱 App Architecture

### Project Structure

```
lib/
├── main.dart              # Application entry point
├── screens/               # UI screens and pages
├── widgets/               # Reusable UI components
├── services/              # Bluetooth and data services
├── models/                # Data models
├── utils/                 # Utility functions and helpers
└── database/              # SQLite database management
```

### Key Services

- **Bluetooth Service**: Handles device discovery, connection, and communication
- **Database Service**: Manages SQLite operations and data persistence
- **Device Service**: Retrieves and manages device information
- **Permission Service**: Handles runtime permission requests

## 🔌 Bluetooth Integration

### Supported Devices

- Classic Bluetooth devices (HC-05, HC-06, etc.)
- Bluetooth Low Energy (BLE) devices (nRF52, Arduino 33, etc.)
- Generic microcontroller units with Bluetooth modules

### Communication Protocol

The app supports bidirectional communication with microcontroller devices:
- Real-time data transmission
- Command execution
- Status monitoring

## 💾 Local Database

The app uses SQLite for persistent storage:
- Device connection history
- User preferences
- Application settings
- Device metadata

## 📸 Screenshots & Assets

The app includes custom branding assets:
- `assets/test_app_logo.png` - Application logo (used for app icon and adaptive icon)
- `assets/StartingScreen.png` - Launch screen image

## 🔐 Permissions

The app requires the following permissions:

**Android:**
- `BLUETOOTH` - Connect to Bluetooth devices
- `BLUETOOTH_ADMIN` - Discover and pair devices
- `BLUETOOTH_CONNECT` - Runtime permission (Android 12+)
- `BLUETOOTH_SCAN` - Scan for devices (Android 12+)
- `ACCESS_FINE_LOCATION` - Precise location for BLE scanning
- `ACCESS_COARSE_LOCATION` - Approximate location for BLE scanning

**iOS:**
- `NSBluetoothPeripheralUsageDescription` - Bluetooth access
- `NSBluetoothCentralUsageDescription` - Bluetooth central role
- `NSLocationWhenInUseUsageDescription` - Location access

## 🧪 Testing

Run unit and widget tests:
```bash
flutter test
```

## 📝 Version Information

- **App Version**: 1.0.0
- **Build Number**: 1
- **Flutter SDK**: ^3.4.0
- **Repository ID**: 1195832558

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🐛 Bug Reports & Feature Requests

Found a bug or have a feature request? Please open an issue on the [GitHub Issues](https://github.com/21tharun/test_app/issues) page.

## 📞 Support

For questions or support, please reach out through:
- GitHub Issues: [21tharun/test_app/issues](https://github.com/21tharun/test_app/issues)
- GitHub Discussions: [21tharun/test_app/discussions](https://github.com/21tharun/test_app/discussions)

## 👨‍💻 Author

**Arun** - [21tharun](https://github.com/21tharun)

---

<div align="center">

**Made with ❤️ using Flutter**

⭐ If you find this project useful, please consider giving it a star!

</div>
