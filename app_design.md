# WifiPass – App Design Document

A lightweight Flutter application that lets users discover, connect, and share Wi-Fi networks around them.

---

## 1. Product Vision
WifiPass removes the “What’s the Wi-Fi password?” friction by crowdsourcing hotspots and letting users join them with one tap.

* Crowd-sourced list of networks with SSID & password  
* Location-aware results ranked by distance & availability  
* Remember last connection time so trusted networks float to the top  
* Quick flow to contribute new networks and help the community

---

## 2. Target Users & Use-cases

| Persona          | Situation                | Goal                                         |
|------------------|--------------------------|----------------------------------------------|
| Digital Nomad    | Arrives at a café        | Connect without asking staff                 |
| Traveller        | At an airport lounge     | Filter only “in-range” networks              |
| Local Resident   | Wants to help neighbours | Share home Wi-Fi so guests can join easily   |

---

## 3. Core Features

1. **Location fetch** (Geolocator) → call API / mock service for nearby Wi-Fi list  
2. **Local Wi-Fi scan** (Android) → mark which SSIDs are **Available**  
3. **Card list** shows  
   * SSID & security type  
   * Signal icon, distance chip  
   * Last connected “x minutes ago” (timeago)  
4. **Detail sheet** with full meta + copy password / connect button  
5. **Floating Action Button** → “Share Wi-Fi” form  
6. **Local storage** keeps custom networks & timestamps  
7. Material 3 light/dark theme, Poppins typography

---

## 4. App Flow

```text
 ┌─────────────┐
 │ Splash/init │
 └────┬────────┘
      ▼
 ┌─────────────┐
 │ HomeScreen  │  ← Refresh / Search / Filter
 └─┬───────────┘
   │tap card
   ▼
 ┌───────────────┐
 │ NetworkSheet  │  (Draggable)
 └─┬─────────────┘
   │FAB
   ▼
 ┌───────────────┐
 │ AddWifiScreen │
 └───────────────┘
```

---

## 5. Screen Mock-ups (Low-fidelity)

### 5.1 HomeScreen

```
┌─ AppBar ──────────────────────┐
│ WifiPass        [🔍] [☰]      │
└───────────────────────────────┘

[📶 ][Home_Cafe_WiFi]  WPA2      0.12 km
 Last connected: 5 m ago      [Connect]

[📶 ][Airport_Free_WiFi] Open    2.1 km
 Not in range                 [Connect]

[📶 ][MyHome5G] WPA2            0.00 km
 Connected                     [Connected✓]

          (+)  Floating Button
```

### 5.2 Network Detail Sheet

```
╭───────╮
│  ▄▄▄  │  SSID: Home_Cafe_WiFi
╰───────╯
Security: WPA2
Password: ••••••••
Last Connected: 5 minutes ago
Location: 37.77, -122.42  (0.12 km)

[Connect]   [Disconnect]
```

### 5.3 AddWifiScreen

```
SSID  [_____________] (wifi icon)
Pass  [_____________] (lock icon 👁)
Sec.  [WPA2 ▼]

[ Share Wi-Fi ]  (primary)
[   Cancel    ]  (outline)
```

---

## 6. UX & UI Guidelines

* 8 dp grid, 12 dp cards, 16 dp screen padding  
* Primary Color: #2196F3  
  Secondary: #03DAC6  
* Icons: Material `wifi`, `network_wifi_3_bar`, `wifi_off`  
* Typography:  
  * TitleLarge – 22 sp, Poppins SemiBold  
  * BodyMedium – 14 sp  
* Animations: subtle fade on list refresh, bottom-sheet spring

---

## 7. Technical Snapshot

* **State**: Provider (`WifiProvider`)  
* **Services**:  
  * LocationService – Geolocator + permission_handler  
  * WifiService – wifi_iot + mock API  
  * StorageService – SharedPrefs + SecureStorage  
* **Model**: `WifiNetwork` with JSON helpers  
* **Error Handling**: permission dialogs, snackbars, retry buttons

---

## 8. Error & Edge Cases

| Scenario                              | Handling                                                        |
|---------------------------------------|-----------------------------------------------------------------|
| Location permission denied            | Explain why needed, show settings button                        |
| Wi-Fi scan not allowed (iOS)          | Hide “Available” filter, offer copy password only               |
| Connection failed                     | Snackbar with reason & retry                                    |
| No hotspots nearby                    | Friendly empty-state illustration + “Share Wi-Fi” suggestion    |

---

## 9. Roadmap & Future Ideas

1. Real backend with crowd moderation & rating  
2. Account system to sync personal lists  
3. QR-code share / scan  
4. Offline caching with expiry & refresh interval  
5. Map view of hotspots

---

## 10. Assets

Place SVG icons or PNGs in `assets/icons/` and illustrations in `assets/images/`.  
Update `pubspec.yaml` accordingly.

---

_End of design document_
