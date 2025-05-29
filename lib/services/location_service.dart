import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Position? _currentPosition;
  final StreamController<Position> _locationController = StreamController<Position>.broadcast();

  // Stream to listen to location updates
  Stream<Position> get locationStream => _locationController.stream;

  // Get the last known position
  Position? get currentPosition => _currentPosition;

  // Initialize the location service
  Future<void> init() async {
    await _checkPermissions();
    await getCurrentLocation();
  }

  // Check and request location permissions
  Future<bool> _checkPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled
      debugPrint('Location services are disabled.');
      return false;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Request location permission
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied
        debugPrint('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are permanently denied
      debugPrint('Location permissions are permanently denied, we cannot request permissions.');
      
      // Try to open app settings so the user can enable permissions
      await openAppSettings();
      return false;
    }

    return true;
  }

  // Get the current location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await _checkPermissions();
      
      if (!hasPermission) {
        return null;
      }

      // Get the current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      _currentPosition = position;
      _locationController.add(position);
      
      return position;
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }

  // Start listening to location updates
  Future<void> startLocationUpdates() async {
    final hasPermission = await _checkPermissions();
    
    if (!hasPermission) {
      return;
    }

    // Get location updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen((Position position) {
      _currentPosition = position;
      _locationController.add(position);
    });
  }

  // Stop listening to location updates
  void stopLocationUpdates() {
    // No need to explicitly stop the stream in this implementation
    // as we're not storing the subscription
  }

  // Calculate distance between two points (in kilometers)
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  // Calculate distance from current location to a point
  double? distanceFromCurrentLocation(double lat, double lon) {
    if (_currentPosition == null) {
      return null;
    }
    
    return calculateDistance(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lon,
    );
  }

  // Dispose resources
  void dispose() {
    _locationController.close();
  }
}
