# WifiPass App Architecture

This document outlines the architecture of the WifiPass Flutter application, showing how different components interact with each other.

## Architecture Overview

The app follows a layered architecture pattern with clear separation of concerns:

1. **UI Layer**: Screens and widgets that display information to users and handle interactions
2. **State Management Layer**: Providers that manage application state and business logic
3. **Service Layer**: Services that handle data operations, device features, and external APIs
4. **Model Layer**: Data models that represent core business entities

## Component Diagram

flowchart TB
    %% Define node styles
    classDef modelClass fill:#4672b4,color:white,stroke:#333,stroke-width:1px
    classDef serviceClass fill:#47956f,color:white,stroke:#333,stroke-width:1px
    classDef providerClass fill:#de953e,color:white,stroke:#333,stroke-width:1px
    classDef uiClass fill:#8b251e,color:white,stroke:#333,stroke-width:1px
    
    %% UI Layer
    subgraph UI["UI Layer"]
        HomeScreen["HomeScreen<br>• Display WiFi networks<br>• Search & filter<br>• Connect to networks"]
        AddWifiScreen["AddWifiScreen<br>• Form to share new WiFi<br>• Validate inputs"]
        WifiListItem["WifiListItem Widget<br>• Reusable network card"]
    end
    
    %% State Management Layer
    subgraph StateManagement["State Management Layer"]
        WifiProvider["WifiProvider<br>• Manage WiFi networks state<br>• Handle network operations<br>• Track loading states"]
    end
    
    %% Service Layer
    subgraph Services["Service Layer"]
        WifiService["WifiService<br>• Get shared networks<br>• Connect to networks<br>• Scan available networks"]
        LocationService["LocationService<br>• Get current location<br>• Request permissions<br>• Calculate distances"]
        StorageService["StorageService<br>• Save/load networks<br>• Secure password storage<br>• Track connection history"]
    end
    
    %% Model Layer
    subgraph Models["Model Layer"]
        WifiNetwork["WifiNetwork<br>• Network data structure<br>• JSON serialization<br>• Helper methods"]
    end
    
    %% External Dependencies
    subgraph External["External Dependencies"]
        WiFiPlugin["wifi_iot Plugin<br>• Native WiFi operations"]
        GeolocatorPlugin["Geolocator Plugin<br>• Native location services"]
        Storage["SharedPreferences<br>Flutter Secure Storage<br>• Local data persistence"]
    end
    
    %% Connections
    HomeScreen --> WifiProvider
    AddWifiScreen --> WifiProvider
    HomeScreen --> WifiListItem
    
    WifiProvider --> WifiService
    WifiProvider --> LocationService
    WifiProvider --> StorageService
    
    WifiService --> WifiNetwork
    WifiService --> WiFiPlugin
    WifiService --> StorageService
    
    LocationService --> GeolocatorPlugin
    
    StorageService --> Storage
    StorageService --> WifiNetwork
    
    %% Apply styles
    WifiNetwork:::modelClass
    WifiService:::serviceClass
    LocationService:::serviceClass
    StorageService:::serviceClass
    WifiProvider:::providerClass
    HomeScreen:::uiClass
    AddWifiScreen:::uiClass
    WifiListItem:::uiClass

## Data Flow

1. **App Initialization**:
   - `main.dart` initializes services and providers
   - `WifiProvider` loads initial data through services

2. **Network Discovery Flow**:
   - `HomeScreen` displays networks from `WifiProvider`
   - `LocationService` provides current coordinates
   - `WifiService` fetches networks near those coordinates
   - `WifiService` also scans for available networks (Android only)
   - Networks are displayed with availability status and connection history

3. **Connection Flow**:
   - User taps "Connect" on a network card
   - `WifiProvider.connectToNetwork()` is called
   - `WifiService` uses the `wifi_iot` plugin to connect
   - `StorageService` updates the last connection time
   - UI is updated to show connected status

4. **Share WiFi Flow**:
   - User navigates to `AddWifiScreen`
   - Form collects SSID, password, and security type
   - `WifiProvider.shareWifiNetwork()` is called
   - `LocationService` attaches current coordinates
   - `StorageService` saves the network locally
   - Network is added to the list in `WifiProvider`

## Key Design Patterns

1. **Repository Pattern**: Services act as repositories for different data domains
2. **Provider Pattern**: State management using ChangeNotifier
3. **Dependency Injection**: Services are injected into providers
4. **Separation of Concerns**: Clear boundaries between UI, business logic, and data access

## Error Handling

Error handling flows through the layers:
1. Services catch and log errors
2. Providers translate errors into user-friendly messages
3. UI displays error states and retry options
