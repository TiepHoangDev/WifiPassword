# WifiPass

WifiPass is a **Flutter** application that crowdsources Wi-Fi access points (SSID + password) and lets users:

* Discover hotspots around their current GPS location  
* See which networks are _actually in range_ thanks to a live scan (Android)  
* One-tap connect (Android) / copy password (iOS fallback)  
* Remember when you last connected so trusted networks float to the top  
* Share new hotspots with the community in just a few seconds

The goal is to remove the “What’s the Wi-Fi password?” friction for travellers, digital nomads and everyday users.

---

## ✨ Feature Overview

| Category | Details |
|----------|---------|
| Discovery | Location-aware API call (mocked for now) returns nearby networks, sorted by distance. |
| Live status | Background scan marks SSIDs as **Available** / **Not in range** and shows signal strength. |
| History | “x minutes ago” using `timeago` + secure local storage of last connection. |
| Connect | Programmatic join via `wifi_iot` on Android; graceful fallback on iOS. |
| Share | Form with SSID / password / security type; coordinates auto-attached. |
| Search & Filter | Keyword search, “only available” toggle, sort by distance or recency. |
| Theming | Material 3, dynamic light/dark, Poppins font. |

---

## Screenshots (mock-ups)

| Home list | Network detail | Share form |
|-----------|---------------|------------|
| _Coming soon_ | _Coming soon_ | _Coming soon_ |

---

## 1. Requirements

| Tool | Minimum version |
|------|-----------------|
| Flutter SDK | 3.22 (Dart 3) |
| Android SDK | 33+ |
| Xcode (macOS) | 15.0 (optional, iOS build) |
| Git | latest |

---

## 2. Getting Started

```bash
# Clone
git clone https://github.com/your-org/wifipass.git
cd wifipass

# Install dependencies
flutter pub get

# Run on Android
flutter run -d android
```

_First launch prompts for Location + Wi-Fi permissions – accept them._

### iOS notes

* Apple forbids programmatic Wi-Fi joins. WifiPass will **display & copy** credentials only.  
* Build with Xcode: open `ios/Runner.xcworkspace`, set your team & bundle id, then `flutter run -d ios`.

---

## 3. Usage Guide

1. **Browse**: Nearby hotspots show in a card list with distance, security and signal bars.  
2. **Filter / Search**: Tap the funnel icon to show only available networks or sort.  
3. **Connect**:  
   * Android – tap **Connect**. App calls `wifi_iot` and updates status.  
   * iOS – long-press password to copy, then join in Settings.  
4. **Share**: Press the **＋** FAB, fill the form, hit **Share Wi-Fi**. Coordinates are saved automatically.  
5. **History**: Cards show “Last connected 2 h ago”. Sorting by last connected is available in filters.

---

## 4. Project Structure

```
lib/
 ├─ models/          # Plain Dart data classes
 ├─ services/        # Location, Wi-Fi, storage, API (mock)
 ├─ providers/       # State management (Provider)
 ├─ screens/         # UI pages (Home, Add Wi-Fi)
 ├─ widgets/         # Reusable components
 └─ main.dart        # Theme & root setup
assets/              # Icons / images
```

---

## 5. Technical Deep-Dive

| Layer | Package(s) | Responsibility |
|-------|------------|----------------|
| **State** | `provider` | `WifiProvider` orchestrates services and exposes UI state. |
| **Location** | `geolocator`, `permission_handler` | Fetch & stream GPS, distance calc. |
| **Wi-Fi ops** | `wifi_iot` | Scan, connect, disconnect (Android). |
| **Mock backend** | built-in | Generates 10 random hotspots around user. |
| **Storage** | `shared_preferences`, `flutter_secure_storage` | Persist networks & passwords locally. |

Sequence diagram (simplified):

```
UI → WifiProvider → LocationService
            ↓                ↑
            WifiService → StorageService
            ↓
     WiFi IOT Plugin (Android)
```

---

## 6. Roadmap

1. Replace mock API with real REST backend & moderation  
2. Map view for hotspots  
3. QR code import/export  
4. Account system to sync personal list  
5. Internationalization (intl)

---

## 7. Contributing

Pull requests are welcome!  
1. Fork → feature branch (`feat/my-feature`)  
2. `flutter analyze` and add tests where possible  
3. Open PR with description of **what** & **why**

---

## 8. License

MIT © 2025 WifiPass contributors
