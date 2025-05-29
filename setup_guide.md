# WifiPass – Setup Guide

Follow this guide to **clone, configure, and run** the WifiPass Flutter application on **Android** and **iOS** devices.

---

## 1. Prerequisites

| Tool | Minimum Version | Notes |
|------|-----------------|-------|
| Flutter SDK | 3.22.0 (Dart 3) | `flutter --version` to verify |
| Android Studio | Flamingo / 2023.3 | Includes Android SDK 33+ |
| Xcode (macOS only) | 15.0 | Needed for iOS build & simulators |
| Git | latest | Clone repository |
| Device / Emulator | Android 8.0+, iOS 14+ | Physical device preferred for Wi-Fi tests |

> **Tip:** Run `flutter doctor` after installing the SDK to check that all tool-chains are green.

---

## 2. Clone the Repository

```bash
git clone https://github.com/your-org/wifipass.git
cd wifipass
```

---

## 3. Install Dependencies

```bash
flutter pub get
```

Flutter downloads every package listed in `pubspec.yaml`.

---

## 4. Platform-specific Setup

### 4.1 Android

1. **Enable developer options** on your phone and turn on **USB debugging**.  
   (Or start an Android Emulator in Android Studio.)
2. **Accept licences** (first time only):

   ```bash
   flutter doctor --android-licenses
   ```
3. **Run**:

   ```bash
   flutter run -d android
   ```

   Grant **Location** and **Nearby Wi-Fi** permissions when prompted.

### 4.2 iOS (macOS only)

Apple blocks programmatic Wi-Fi joins; WifiPass will **display & copy** credentials instead of auto-connecting.

1. Install CocoaPods if missing:

   ```bash
   sudo gem install cocoapods
   ```
2. In the project root:

   ```bash
   cd ios
   pod install
   cd ..
   ```
3. Open `ios/Runner.xcworkspace` in Xcode **once**:
   - In *Targets › Runner › Signing & Capabilities* select your **Team**.
   - Change the *Bundle Identifier* to something unique (e.g. `com.yourname.wifipass`).
4. Back in the terminal:

   ```bash
   flutter run -d ios
   ```

---

## 5. Directory Structure (quick glance)

```
lib/
 ├─ models/        # Plain Dart data classes
 ├─ services/      # Location, Wi-Fi, storage, mock API
 ├─ providers/     # State management (Provider)
 ├─ screens/       # UI pages
 ├─ widgets/       # Reusable components
 └─ main.dart      # App entry, theme
assets/
 └─ images/ icons/ # (empty placeholders)
```

---

## 6. Common Issues & Fixes

| Symptom | Fix |
|---------|-----|
| `Location permission denied forever` toast | Settings → Apps → WifiPass → Permissions → enable *Location*. |
| `WiFiForIoTPlugin: cannot scan` on Android 13+ | Ensure **Nearby Wi-Fi** permission is granted. |
| iOS build fails “Pods not installed” | `cd ios && pod install`, then try again. |
| Android build fails Kotlin/Gradle | Run *Android Studio* → *Project Upgrade* wizard. |

---

## 7. Next Steps

* Switch `_useMockData` to **false** in `lib/services/wifi_service.dart` when you have a real backend.
* Generate a release APK:

  ```bash
  flutter build apk --release
  ```

* Archive for TestFlight/App Store: open Xcode → *Product › Archive* and follow the wizard.

Happy coding! 🎉
