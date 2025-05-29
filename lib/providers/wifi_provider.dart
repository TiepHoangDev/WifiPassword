import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/wifi_network_model.dart';
import '../services/wifi_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';

enum WifiLoadingState {
  initial,
  loading,
  loaded,
  error,
}

class WifiProvider extends ChangeNotifier {
  final WifiService wifiService;
  final LocationService locationService;
  final StorageService storageService;
  
  List<WiFiNetworkModel> _networks = [];
  List<String> _availableNetworks = [];
  String? _currentSSID;
  WifiLoadingState _loadingState = WifiLoadingState.initial;
  String? _errorMessage;
  Timer? _refreshTimer;
  StreamSubscription<Position>? _locationSubscription;
  
  // Getters
  List<WiFiNetworkModel> get networks => _networks;
  List<WiFiNetworkModel> get availableNetworks => _networks.where(
    (network) => _availableNetworks.contains(network.ssid)
  ).toList();
  WifiLoadingState get loadingState => _loadingState;
  String? get errorMessage => _errorMessage;
  String? get currentSSID => _currentSSID;
  bool get isConnecting => _isConnecting;
  
  bool _isConnecting = false;
  
  WifiProvider({
    required this.wifiService,
    required this.locationService,
    required this.storageService,
  }) {
    // Initialize
    _init();
  }
  
  // Initialize the provider
  Future<void> _init() async {
    await locationService.init();
    await _loadNetworks();
    await _refreshAvailableNetworks();
    await _checkCurrentConnection();
    
    // Start listening to location updates
    _locationSubscription = locationService.locationStream.listen((position) {
      _loadNetworks(); // Reload networks when location changes
    });
    
    // Set up periodic refresh
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshAvailableNetworks();
      _checkCurrentConnection();
    });
  }
  
  // Load networks based on current location
  Future<void> _loadNetworks() async {
    _loadingState = WifiLoadingState.loading;
    notifyListeners();
    
    try {
      // Get current location
      final position = await locationService.getCurrentLocation();
      
      if (position != null) {
        // Load networks from service
        _networks = await wifiService.getSharedWifiNetworks(
          latitude: position.latitude,
          longitude: position.longitude,
          radius: 2.0, // 2km radius
        );
        
        _loadingState = WifiLoadingState.loaded;
      } else {
        // No location available, try to load without location
        _networks = await wifiService.getSharedWifiNetworks();
        _loadingState = WifiLoadingState.loaded;
      }
    } catch (e) {
      _errorMessage = 'Failed to load WiFi networks: $e';
      _loadingState = WifiLoadingState.error;
      debugPrint(_errorMessage);
    }
    
    notifyListeners();
  }
  
  // Refresh the list of available networks
  Future<void> _refreshAvailableNetworks() async {
    try {
      _availableNetworks = await wifiService.getAvailableNetworks();
      notifyListeners();
    } catch (e) {
      debugPrint('Error refreshing available networks: $e');
    }
  }
  
  // Check current WiFi connection
  Future<void> _checkCurrentConnection() async {
    try {
      _currentSSID = await wifiService.getCurrentSSID();
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking current connection: $e');
    }
  }
  
  // Connect to a WiFi network
  Future<bool> connectToNetwork(WiFiNetworkModel network) async {
    _isConnecting = true;
    notifyListeners();
    
    try {
      final result = await wifiService.connectToNetwork(network);
      
      if (result) {
        // Update current SSID
        _currentSSID = network.ssid;
        
        // Refresh available networks
        await _refreshAvailableNetworks();
      }
      
      _isConnecting = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isConnecting = false;
      _errorMessage = 'Failed to connect to network: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Disconnect from current network
  Future<bool> disconnect() async {
    try {
      final result = await wifiService.disconnect();
      
      if (result) {
        _currentSSID = null;
        await _refreshAvailableNetworks();
        notifyListeners();
      }
      
      return result;
    } catch (e) {
      _errorMessage = 'Failed to disconnect: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Share a new WiFi network
  Future<WiFiNetworkModel?> shareWifiNetwork({
    required String ssid,
    required String password,
    String? securityType,
  }) async {
    try {
      // Get current location
      final position = await locationService.getCurrentLocation();
      
      if (position == null) {
        _errorMessage = 'Location unavailable. Cannot share WiFi network.';
        notifyListeners();
        return null;
      }
      
      // Share the network
      final network = await wifiService.shareWifiNetwork(
        ssid: ssid,
        password: password,
        latitude: position.latitude,
        longitude: position.longitude,
        securityType: securityType,
      );
      
      // Add to networks list
      _networks.add(network);
      notifyListeners();
      
      return network;
    } catch (e) {
      _errorMessage = 'Failed to share WiFi network: $e';
      notifyListeners();
      return null;
    }
  }
  
  // Refresh all data
  Future<void> refresh() async {
    await _loadNetworks();
    await _refreshAvailableNetworks();
    await _checkCurrentConnection();
  }
  
  // Filter networks by search query
  List<WiFiNetworkModel> searchNetworks(String query) {
    if (query.isEmpty) {
      return _networks;
    }
    
    return _networks.where((network) => 
      network.ssid.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }
  
  // Get networks sorted by last connection time
  List<WiFiNetworkModel> getNetworksByLastConnected() {
    final sortedNetworks = List<WiFiNetworkModel>.from(_networks);
    
    sortedNetworks.sort((a, b) {
      if (a.lastConnected == null && b.lastConnected == null) {
        return 0;
      }
      
      if (a.lastConnected == null) {
        return 1;
      }
      
      if (b.lastConnected == null) {
        return -1;
      }
      
      return b.lastConnected!.compareTo(a.lastConnected!);
    });
    
    return sortedNetworks;
  }
  
  // Check if a network is available in current scan
  bool isNetworkAvailable(String ssid) {
    return _availableNetworks.contains(ssid);
  }
  
  // Get network by ID
  WiFiNetworkModel? getNetworkById(String id) {
    try {
      return _networks.firstWhere((network) => network.id == id);
    } catch (e) {
      return null;
    }
  }
  
  // Get network by SSID
  WiFiNetworkModel? getNetworkBySSID(String ssid) {
    try {
      return _networks.firstWhere((network) => network.ssid == ssid);
    } catch (e) {
      return null;
    }
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _locationSubscription?.cancel();
    super.dispose();
  }
}
