import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/wifi_network_model.dart';
import 'storage_service.dart';

class WifiService {
  final StorageService _storageService;
  final Random _random = Random();
  final Uuid _uuid = const Uuid();
  
  // Mock API endpoint (would be replaced with a real API in production)
  static const String _mockApiEndpoint = 'https://api.example.com/wifi';
  
  // Flag to determine if we're using mock data
  final bool _useMockData = true;
  
  WifiService(this._storageService);
  
  // Get shared WiFi networks from API or mock data
  Future<List<WiFiNetworkModel>> getSharedWifiNetworks({
    double? latitude,
    double? longitude,
    double radius = 1.0, // Default radius in kilometers
  }) async {
    if (_useMockData) {
      return _getMockWifiNetworks(latitude, longitude);
    } else {
      // In a real app, this would call an actual API
      try {
        final response = await http.get(
          Uri.parse('$_mockApiEndpoint?lat=$latitude&lng=$longitude&radius=$radius'),
        );
        
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          return data.map((json) => WiFiNetworkModel.fromJson(json as Map<String, dynamic>)).toList();
        } else {
          throw Exception('Failed to load WiFi networks: ${response.statusCode}');
        }
      } catch (e) {
        debugPrint('Error fetching WiFi networks: $e');
        // Fall back to mock data on error
        return _getMockWifiNetworks(latitude, longitude);
      }
    }
  }
  
  // Generate mock WiFi networks for testing
  Future<List<WiFiNetworkModel>> _getMockWifiNetworks(double? latitude, double? longitude) async {
    // Use provided location or default to a random location
    final lat = latitude ?? (37.7749 + (_random.nextDouble() * 0.1 - 0.05));
    final lng = longitude ?? (-122.4194 + (_random.nextDouble() * 0.1 - 0.05));
    
    // Get locally saved networks
    final savedNetworks = await _storageService.getWifiNetworks();
    
    // Generate some random networks
    final mockNetworks = List.generate(
      10, // Generate 10 mock networks
      (index) {
        final networkLat = lat + (_random.nextDouble() * 0.02 - 0.01);
        final networkLng = lng + (_random.nextDouble() * 0.02 - 0.01);
        
        // Calculate a random time in the past for last connection
        final lastConnected = _random.nextBool()
            ? DateTime.now().subtract(Duration(
                minutes: _random.nextInt(60),
                hours: _random.nextInt(24),
                days: _random.nextInt(30),
              ))
            : null;
        
        // Security types
        final securityTypes = ['WPA2', 'WPA', 'WPA/WPA2', 'Open', 'WEP'];
        
        return WiFiNetworkModel(
          id: _uuid.v4(),
          ssid: 'WiFi_${_getRandomName()}_$index',
          password: _generateRandomPassword(10 + _random.nextInt(6)),
          latitude: networkLat,
          longitude: networkLng,
          lastConnected: lastConnected,
          securityType: securityTypes[_random.nextInt(securityTypes.length)],
          signalStrength: -(_random.nextInt(60) + 30), // Between -30 and -90 dBm
          createdBy: 'user_${_random.nextInt(1000)}',
          createdAt: DateTime.now().subtract(Duration(days: _random.nextInt(365))),
          distanceFromUser: latitude != null && longitude != null
              ? WiFiNetworkModel.calculateDistance(latitude, longitude, networkLat, networkLng)
              : null,
        );
      },
    );
    
    // Combine saved and mock networks, ensuring no duplicates by SSID
    final allNetworks = [...savedNetworks];
    
    for (final mockNetwork in mockNetworks) {
      if (!allNetworks.any((network) => network.ssid == mockNetwork.ssid)) {
        allNetworks.add(mockNetwork);
      }
    }
    
    // Sort by distance if location is provided
    if (latitude != null && longitude != null) {
      for (final network in allNetworks) {
        network.distanceFromUser = WiFiNetworkModel.calculateDistance(
          latitude, longitude, network.latitude, network.longitude);
      }
      
      allNetworks.sort((a, b) {
        final distA = a.distanceFromUser ?? double.infinity;
        final distB = b.distanceFromUser ?? double.infinity;
        return distA.compareTo(distB);
      });
    }
    
    return allNetworks;
  }
  
  // Get currently available WiFi networks (scan)
  Future<List<String>> getAvailableNetworks() async {
    try {
      // Check if WiFi is enabled
      if (!(await WiFiForIoTPlugin.isEnabled())) {
        await WiFiForIoTPlugin.setEnabled(true);
        // Wait for WiFi to initialize
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Scan for networks (Android only)
      // Note: We're not using canStartScan() as it's not available in the current API
      try {
        // Start scan directly
        await WiFiForIoTPlugin.forceWifiUsage(true);
        
        // Get scan results
        final scanResults = await WiFiForIoTPlugin.loadWifiList();
        
        // Extract SSIDs
        return scanResults
            .map((result) => result.ssid ?? '')
            .where((ssid) => ssid.isNotEmpty)
            .toList();
      } catch (e) {
        debugPrint('Error during WiFi scan: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Error scanning for WiFi networks: $e');
      // Return empty list on error
      return [];
    }
  }
  
  // Connect to a WiFi network
  Future<bool> connectToNetwork(WiFiNetworkModel network) async {
    try {
      // Check if WiFi is enabled
      if (!(await WiFiForIoTPlugin.isEnabled())) {
        await WiFiForIoTPlugin.setEnabled(true);
        // Wait for WiFi to initialize
        await Future.delayed(const Duration(seconds: 2));
      }
      
      // Determine security type
      NetworkSecurity security;
      
      switch (network.securityType?.toUpperCase() ?? '') {
        case 'WPA':
        case 'WPA2':
        case 'WPA/WPA2':
          security = NetworkSecurity.WPA;
          break;
        case 'WEP':
          security = NetworkSecurity.WEP;
          break;
        default:
          security = NetworkSecurity.NONE;
      }
      
      // Connect to the network
      final result = await WiFiForIoTPlugin.connect(
        network.ssid,
        password: network.password,
        security: security,
      );
      
      if (result) {
        // Update last connected time in storage
        await _storageService.updateLastConnected(network.id);
        debugPrint('Successfully connected to ${network.ssid}');
      } else {
        debugPrint('Failed to connect to ${network.ssid}');
      }
      
      return result;
    } catch (e) {
      debugPrint('Error connecting to WiFi network: $e');
      return false;
    }
  }
  
  // Disconnect from current WiFi network
  Future<bool> disconnect() async {
    try {
      return await WiFiForIoTPlugin.disconnect();
    } catch (e) {
      debugPrint('Error disconnecting from WiFi: $e');
      return false;
    }
  }
  
  // Get current connection info
  Future<String?> getCurrentSSID() async {
    try {
      return await WiFiForIoTPlugin.getSSID();
    } catch (e) {
      debugPrint('Error getting current SSID: $e');
      return null;
    }
  }
  
  // Share a new WiFi network
  Future<WiFiNetworkModel> shareWifiNetwork({
    required String ssid,
    required String password,
    required double latitude,
    required double longitude,
    String? securityType,
  }) async {
    // Create a new network
    final network = WiFiNetworkModel(
      id: _uuid.v4(),
      ssid: ssid,
      password: password,
      latitude: latitude,
      longitude: longitude,
      securityType: securityType ?? 'WPA2',
      createdAt: DateTime.now(),
      lastConnected: null, // Not connected yet
    );
    
    // Save to local storage
    await _storageService.saveWifiNetwork(network);
    
    // In a real app, this would also send the network to the API
    // await _sendNetworkToApi(network);
    
    return network;
  }
  
  // Check if a network is available in the current scan
  Future<bool> isNetworkAvailable(String ssid) async {
    final availableNetworks = await getAvailableNetworks();
    return availableNetworks.contains(ssid);
  }
  
  // Helper method to generate a random name for mock networks
  String _getRandomName() {
    final names = [
      'Home', 'Office', 'Cafe', 'Library', 'Restaurant', 
      'Hotel', 'Airport', 'School', 'University', 'Mall',
      'Park', 'Station', 'Gym', 'Studio', 'Shop',
      'Market', 'Plaza', 'Center', 'Hub', 'Spot'
    ];
    
    return names[_random.nextInt(names.length)];
  }
  
  // Helper method to generate a random password
  String _generateRandomPassword(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()';
    return String.fromCharCodes(
      List.generate(length, (_) => chars.codeUnitAt(_random.nextInt(chars.length)))
    );
  }
  
  // In a real app, this would send the network to an API
  Future<void> _sendNetworkToApi(WiFiNetworkModel network) async {
    try {
      final response = await http.post(
        Uri.parse(_mockApiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(network.toJson()),
      );
      
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to share WiFi network: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sharing WiFi network: $e');
      // Handle error (maybe retry later)
    }
  }
}
