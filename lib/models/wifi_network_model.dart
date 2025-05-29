import 'package:flutter/foundation.dart';
import 'dart:math';

class WiFiNetworkModel {
  final String id; // Unique identifier
  final String ssid; // Network name
  final String password;
  final double latitude;
  final double longitude;
  final DateTime? lastConnected; // When the user last connected to this network
  final String? securityType; // WPA, WPA2, WEP, Open, etc.
  final int? signalStrength; // Signal strength in dBm (if available)
  final String? createdBy; // User who shared this network (for future use)
  final DateTime createdAt; // When this network was added to the database
  
  // Distance from user's current location (not stored, calculated on demand)
  double? distanceFromUser;

  WiFiNetworkModel({
    required this.id,
    required this.ssid,
    required this.password,
    required this.latitude,
    required this.longitude,
    this.lastConnected,
    this.securityType,
    this.signalStrength,
    this.createdBy,
    required this.createdAt,
    this.distanceFromUser,
  });

  // Create a network from JSON (for loading from storage or API)
  factory WiFiNetworkModel.fromJson(Map<String, dynamic> json) {
    return WiFiNetworkModel(
      id: json['id'] as String,
      ssid: json['ssid'] as String,
      password: json['password'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      lastConnected: json['lastConnected'] != null 
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
      securityType: json['securityType'] as String?,
      signalStrength: json['signalStrength'] as int?,
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      distanceFromUser: json['distanceFromUser'] as double?,
    );
  }

  // Convert network to JSON (for saving to storage or API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ssid': ssid,
      'password': password,
      'latitude': latitude,
      'longitude': longitude,
      'lastConnected': lastConnected?.toIso8601String(),
      'securityType': securityType,
      'signalStrength': signalStrength,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      // We don't store distanceFromUser as it's calculated on demand
    };
  }

  // Create a copy of this network with updated properties
  WiFiNetworkModel copyWith({
    String? id,
    String? ssid,
    String? password,
    double? latitude,
    double? longitude,
    DateTime? lastConnected,
    String? securityType,
    int? signalStrength,
    String? createdBy,
    DateTime? createdAt,
    double? distanceFromUser,
  }) {
    return WiFiNetworkModel(
      id: id ?? this.id,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      lastConnected: lastConnected ?? this.lastConnected,
      securityType: securityType ?? this.securityType,
      signalStrength: signalStrength ?? this.signalStrength,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
    );
  }

  // Update the last connected time to now
  WiFiNetworkModel withUpdatedConnectionTime() {
    return copyWith(lastConnected: DateTime.now());
  }

  // Calculate distance between two coordinates (in kilometers)
  // This is a simplified version - consider using a geolocation package for more accuracy
  static double calculateDistance(
    double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 - 
      (cos((lat2 - lat1) * p) / 2) + 
      cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  // For debugging purposes
  @override
  String toString() {
    return 'WiFiNetworkModel(id: $id, ssid: $ssid, password: $password, '
           'latitude: $latitude, longitude: $longitude, '
           'lastConnected: $lastConnected)';
  }
}
