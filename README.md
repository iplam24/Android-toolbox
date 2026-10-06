# ⚡ Android Toolbox

> **The Swiss-knife system utility & developer toolkit for Android, built with Flutter 3.47+, Dart 3.13+, Kotlin, and GetX architecture.**

```text
┌──────────────────────────┐
│       ANDROID TOOLBOX    │
│                          │
│  📦 APK       📋 Clipboard│
│                          │
│  📡 Network   🔋 Battery │
│                          │
│  📁 Files     🔐 Privacy │
│                          │
│  ⚙️ ADB       🛠 Tools   │
└──────────────────────────┘
```

---

## 🚀 Key Modules & Capabilities

### 1. 📦 APK Manager (`:feature:apk`)
- **Package Inspector**: List all installed user applications & system apps.
- **Deep Metadata**: Package name, Version Code/Name, Target SDK, Min SDK, APK size, install & update timestamps.
- **APK Extractor**: One-tap extract base APK to `Downloads/AndroidToolbox_APKs/` with direct sharing.
- **Actions**: Launch application, navigate to Android system App Info settings, and uninstall.

### 2. 📋 Clipboard Manager (`:feature:clipboard`)
- **Persistent History**: Auto-saves copied clips with `GetStorage` persistent key-value store.
- **Intelligent Classification**: Detects URLs (`🔗`), Phone Numbers (`📞`), Code Snippets (`💻`), and Plain Text (`📝`).
- **Quick Actions**: One-click re-copy with haptic feedback, pin favorite clips, delete, and **direct conversion into QR codes**.

### 3. 📷 QR & Barcode Studio (`:feature:qr`)
- **Real-Time Scanner**: High-speed camera scanner using Google ML Kit & CameraX.
- **Custom QR Generator**: Generate clean QR codes for URLs, Notes, and **Wi-Fi Auto-Connect** (`WIFI:S:...;T:WPA;P:...;;`).

### 4. 📡 Network Suite (`:feature:network`)
- **Local IP & Adapter Discovery**: Shows IP address, active network interfaces, and gateway details.
- **Real-Time Ping Tool**: Test latency against servers (e.g. `8.8.8.8`, `1.1.1.1`) with live RTT response badges.
- **LAN Port Scanner**: Probes common open ports (`5555` Wireless ADB, `80` HTTP, `443` HTTPS, `8080` Proxy, `22` SSH).

### 5. 🔋 Battery Diagnostics (`:feature:battery`)
- **Advanced Telemetry**: Sticky broadcast listener for battery level, voltage (V), temperature (°C), charging source (AC, USB, Wireless).
- **Power Calculation**: Real-time wattage (W) estimation based on microampere current draw.
- **Safety Overheat Warnings**: Dynamic badge alerts when temperatures exceed safe limits.

### 6. 📁 Local Web Share / File Transfer (`:feature:fileshare`)
- **Embedded Shelf HTTP Server**: Spawns an internal HTTP server on the local Wi-Fi network (e.g. `http://192.168.1.15:8080`).
- **Zero Client Software Needed**: PC, Mac, iPhone, or any browser device on the same Wi-Fi can browse, download, and drag-and-drop upload files to the phone.
- **Instant Connect QR Code**: Displayed on-screen for instant phone-to-phone pairing.

### 7. 🔐 Privacy & Dangerous Permissions Audit (`:feature:privacy`)
- **Permission Auditor**: Scans user-installed applications for high-risk Android permissions (Camera, Microphone, Location, Contacts, SMS, Call Logs, Storage).
- **Risk Score Algorithm**: Classifies applications into High, Medium, and Low risk.
- **Direct Management**: One-tap access to revoke permissions in Android system settings.

### 8. ⚙️ ADB & Developer Tools (`:feature:adb`)
- **Developer Shortcuts**: One-tap access to Android Developer Options and Android 11+ Wireless Debugging settings.
- **Shizuku Detector**: Probes for Shizuku service status.
- **System Logcat Terminal**: Live system logcat reader with keyword filtering and copy-to-clipboard capabilities.

### 9. 🛠 Device Specs & Sensor Tools (`:feature:deviceinfo`)
- **Full Hardware Specs**: Brand, model, board, SoC, RAM stats, internal storage capacity.
- **Live Sensor Telemetry**: Real-time X/Y/Z vector stream for Accelerometer and Gyroscope.
- **Interactive Hardware Tests**: Haptic/vibration actuator test & full-screen RGBW screen dead-pixel tester.

---

## 🏛 Architecture & Project Structure

Organized following the GetX Pattern (`bindings/`, `controllers/`, `views/`):

```text
lib/
├── app/
│   ├── core/
│   │   ├── constants/       # AppColors, AppTheme
│   │   ├── services/        # SystemToolsService (MethodChannel), WebServerService, ClipboardStorageService
│   │   ├── utils/           # Helper utilities
│   │   └── widgets/         # BentoCard, CustomAppBar, SectionHeader
│   ├── data/
│   │   └── models/          # AppPackageModel, BatteryInfoModel, HardwareInfoModel, PrivacyAuditModel...
│   ├── modules/
│   │   ├── home/            # Main 8-Bento dashboard hub
│   │   ├── apk_manager/     # APK extraction & inspection
│   │   ├── clipboard/       # Clipboard history & pins
│   │   ├── qr_tools/        # QR Scanner & Generator
│   │   ├── network_tools/   # IP info, Ping latency & Port scanner
│   │   ├── battery_monitor/ # Real-time battery diagnostics
│   │   ├── file_transfer/   # Local Shelf HTTP Web Share
│   │   ├── privacy_audit/   # Dangerous permissions scanner
│   │   ├── adb_tools/       # Dev options, wireless ADB & logcat
│   │   └── device_info/     # Hardware specs, sensors & screen test
│   └── routes/
│       ├── app_pages.dart   # Page route bindings
│       └── app_routes.dart  # Route constants
└── main.dart
```

---

## 🛠 Build & Run

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run app
flutter run

# Build APK
flutter build apk --debug
```
