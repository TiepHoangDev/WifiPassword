import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/wifi_network_model.dart';

class StorageService {
  static const String _wifiNetworksKey = 'wifi_networks';
  static const String _passwordPrefix = 'wifi_password_';
  
  late SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }
  
  // Save a WiFi network to local storage
  Future<void> saveWifiNetwork(WiFiNetworkModel network) async {
    // Get current networks
    final networks = await getWifiNetworks();
    
    // Check if network already exists (by ID)
    final existingIndex = networks.indexWhere((n) => n.id == network.id);
    
    if (existingIndex >= 0) {
      // Update existing network
      networks[existingIndex] = network;
    } else {
      // Add new network
      networks.add(network);
    }
    
    // Save networks data (except passwords)
    await _saveNetworksList(networks);
    
    // Save password securely
    await _secureStorage.write(
      key: _passwordPrefix + network.id,
      value: network.password,
    );
  }
  
  // Get all saved WiFi networks
  Future<List<WiFiNetworkModel>> getWifiNetworks() async {
    final networksJson = _prefs.getStringList(_wifiNetworksKey) ?? [];
    
    final networks = <WiFiNetworkModel>[];
    
    for (final jsonStr in networksJson) {
      try {
        final networkData = json.decode(jsonStr) as Map<String, dynamic>;
        final id = networkData['id'] as String;
        
        // Get password from secure storage
        final password = await _secureStorage.read(key: _passwordPrefix + id) ?? '';
        
        // Create network object with password
        final network = WiFiNetworkModel.fromJson({
          ...networkData,
          'password': password,
        });
        
        networks.add(network);
      } catch (e) {
        debugPrint('Error parsing WiFi network: $e');
      }
    }
    
    return networks;
  }
  
  // Update last connection time for a network
  Future<void> updateLastConnected(String networkId) async {
    final networks = await getWifiNetworks();
    final index = networks.indexWhere((network) => network.id == networkId);
    
    if (index >= 0) {
      // Update the last connected time to now
      final updatedNetwork = networks[index].withUpdatedConnectionTime();
      networks[index] = updatedNetwork;
      
      // Save the updated networks list
      await _saveNetworksList(networks);
    }
  }
  
  // Delete a WiFi network
  Future<void> deleteWifiNetwork(String networkId) async {
    final networks = await getWifiNetworks();
    networks.removeWhere((network) => network.id == networkId);
    
    // Save the updated networks list
    await _saveNetworksList(networks);
    
    // Remove password from secure storage
    await _secureStorage.delete(key: _passwordPrefix + networkId);
  }
  
  // Clear all stored networks
  Future<void> clearAllNetworks() async {
    await _prefs.remove(_wifiNetworksKey);
    
    // Clear all passwords from secure storage
    // Note: This is a simplified approach. In a production app,
    // you might want to only clear WiFi-related keys.
    await _secureStorage.deleteAll();
  }
  
  // Helper method to save the networks list without passwords
  Future<void> _saveNetworksList(List<WiFiNetworkModel> networks) async {
    final networksJson = networks.map((network) {
      final json = network.toJson();
      // Don't store password in SharedPreferences
      json.remove('password');
      return jsonEncode(json);
    }).toList();
    
    await _prefs.setStringList(_wifiNetworksKey, networksJson);
  }
  
  // Get the last connection time for a specific network
  Future<DateTime?> getLastConnectedTime(String networkId) async {
    final networks = await getWifiNetworks();
    final network = networks.firstWhere(
      (n) => n.id == networkId,
      orElse: () => WiFiNetworkModel(
        id: networkId,
        ssid: '',
        password: '',
        latitude: 0,
        longitude: 0,
        createdAt: DateTime.now(),
      ),
    );
    
    return network.lastConnected;
  }
  
  // Check if a network exists in storage
  Future<bool> networkExists(String ssid) async {
    final networks = await getWifiNetworks();
    return networks.any((network) => network.ssid == ssid);
  }
}
