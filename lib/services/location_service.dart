import 'dart:async';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  loc.Location? _location;
  Timer? _backgroundTimer;
  StreamController<loc.LocationData>? _locationController;
  bool _isTracking = true;
  bool _isInitialized = false;

  // Stream to listen to location updates
  Stream<loc.LocationData>? get locationStream => _locationController?.stream;
  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;

  // Initialize the location service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _location = loc.Location();
      _locationController = StreamController<loc.LocationData>.broadcast();

      // Check if location service is enabled
      bool serviceEnabled = await _location!.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location!.requestService();
        if (!serviceEnabled) {
          return false;
        }
      }

      // Check for location permissions
      loc.PermissionStatus permissionGranted = await _location!.hasPermission();
      if (permissionGranted == loc.PermissionStatus.denied) {
        permissionGranted = await _location!.requestPermission();
        if (permissionGranted != loc.PermissionStatus.granted) {
          return false;
        }
      }

      // Configure location settings
      await _location!.changeSettings(
        accuracy: loc.LocationAccuracy.high,
        interval: 1000, // Update every 1000ms (1 second)
        distanceFilter: 0, // Update regardless of distance moved
      );

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing location service: $e');
      return false;
    }
  }

  // Start background location tracking
  Future<bool> startBackgroundTracking({int intervalSeconds = 5}) async {
    if (_isTracking || _location == null) return false;

    try {
      // Enable background mode
      await _location!.enableBackgroundMode(enable: true);

      // Start periodic location updates
      _backgroundTimer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) async {
        await _updateLocation();
      });

      _isTracking = true;
      print('Background location tracking started');
      return true;
    } catch (e) {
      print('Error starting background tracking: $e');
      return false;
    }
  }

  // Stop background location tracking
  Future<void> stopBackgroundTracking() async {
    if (!_isTracking) return;

    try {
      _backgroundTimer?.cancel();
      _backgroundTimer = null;

      if (_location != null) {
        await _location!.enableBackgroundMode(enable: false);
      }

      _isTracking = false;
      print('Background location tracking stopped');
    } catch (e) {
      print('Error stopping background tracking: $e');
    }
  }

  // Get current location once with smart caching
  Future<loc.LocationData?> getCurrentLocation() async {
    if (_location == null) {
      // Try to get recent cached location first (within last 30 seconds)
      final cachedLocation = await getCachedLocationInRange(
        timeRange: Duration(seconds: 30),
        minAccuracy: 100, // 100 meters accuracy
      );
      
      if (cachedLocation != null) {
        print('Using cached location from ${DateTime.fromMillisecondsSinceEpoch(cachedLocation.time?.toInt() ?? 0)}');
        return cachedLocation;
      }
      
      // Fallback to last saved location
      final savedLocation = await getLastSavedLocation();
      if (savedLocation != null) {
        print('Using last saved location');
        return savedLocation;
      }
      
      return null;
    }

    try {
      final currentLocation = await _location!.getLocation();
      
      // Save new location data
      await _saveLocationToPreferences(currentLocation);
      await _saveLocationToHistory(currentLocation);
      
      return currentLocation;
    } catch (e) {
      print('Error getting current location: $e');
      
      // Try cached location in case of error
      final cachedLocation = await getCachedLocationInRange(
        timeRange: Duration(minutes: 5), // Allow older cache in case of error
      );
      
      if (cachedLocation != null) {
        print('Using cached location due to error');
        return cachedLocation;
      }
      
      // Final fallback to last saved location
      final savedLocation = await getLastSavedLocation();
      return savedLocation;
    }
  }

  // Auto-start background tracking after permission is granted
  Future<bool> initializeAndStartTracking({int intervalSeconds = 5}) async {
    bool initialized = await initialize();
    if (!initialized) {
      print('Failed to initialize location service');
      return false;
    }

    // Automatically start background tracking
    bool trackingStarted = await startBackgroundTracking(intervalSeconds: intervalSeconds);
    if (trackingStarted) {
      print('Location service initialized and background tracking started automatically');
      return true;
    } else {
      print('Location service initialized but failed to start background tracking');
      return false;
    }
  }

  // Internal method to update location
  Future<void> _updateLocation() async {
    if (_location == null || _locationController == null) return;

    try {
      final currentLocation = await _location!.getLocation();
      
      // Add to stream
      if (!_locationController!.isClosed) {
        _locationController!.add(currentLocation);
      }

      // Save location data to SharedPreferences (current location)
      await _saveLocationToPreferences(currentLocation);

      // Save location to history cache
      await _saveLocationToHistory(currentLocation);

      // Save location data (implement based on your needs)
      await _saveLocationData(currentLocation);
      
      print('Location updated: ${currentLocation.latitude}, ${currentLocation.longitude}');
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  // Save location data to your preferred storage
  Future<void> _saveLocationData(loc.LocationData location) async {
    // TODO: Implement based on your requirements
    // Examples:
    // - Save to SharedPreferences
    // - Save to local SQLite database
    // - Send to Firebase Firestore
    // - Send to your REST API
    
    final timestamp = DateTime.now();
    print('Saving location at $timestamp: ${location.latitude}, ${location.longitude}');
    
    // Example implementation for Firebase Firestore:
    /*
    try {
      await FirebaseFirestore.instance.collection('user_locations').add({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'altitude': location.altitude,
        'heading': location.heading,
        'speed': location.speed,
        'timestamp': timestamp,
        'userId': 'your_user_id_here',
      });
    } catch (e) {
      print('Error saving to Firestore: $e');
    }
    */
  }

  // Location history cache management
  static const int MAX_CACHED_LOCATIONS = 100;
  static const String LOCATION_HISTORY_KEY = 'location_history';

  // Save location to history cache
  Future<void> _saveLocationToHistory(loc.LocationData location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(LOCATION_HISTORY_KEY) ?? [];
      
      // Create location entry with timestamp
      final locationEntry = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy': location.accuracy,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'speed': location.speed,
        'heading': location.heading,
      };
      
      // Convert to JSON string
      final locationJson = locationEntry.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}:${e.value}')
          .join(',');
      
      // Add to beginning of list (most recent first)
      history.insert(0, locationJson);
      
      // Keep only last MAX_CACHED_LOCATIONS entries
      if (history.length > MAX_CACHED_LOCATIONS) {
        history = history.take(MAX_CACHED_LOCATIONS).toList();
      }
      
      await prefs.setStringList(LOCATION_HISTORY_KEY, history);
      print('Location saved to history cache: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      print('Error saving location to history: $e');
    }
  }

  // Get location history from cache
  Future<List<loc.LocationData>> getLocationHistory({int limit = 10}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> history = prefs.getStringList(LOCATION_HISTORY_KEY) ?? [];
      
      List<loc.LocationData> locations = [];
      
      for (String locationString in history.take(limit)) {
        try {
          Map<String, dynamic> locationMap = {};
          
          for (String pair in locationString.split(',')) {
            List<String> keyValue = pair.split(':');
            if (keyValue.length == 2) {
              String key = keyValue[0];
              String value = keyValue[1];
              
              if (key == 'timestamp') {
                locationMap[key] = int.tryParse(value);
              } else {
                locationMap[key] = double.tryParse(value);
              }
            }
          }
          
          if (locationMap['latitude'] != null && locationMap['longitude'] != null) {
            locations.add(loc.LocationData.fromMap(locationMap));
          }
        } catch (e) {
          print('Error parsing cached location: $e');
        }
      }
      
      return locations;
    } catch (e) {
      print('Error getting location history: $e');
      return [];
    }
  }

  // Clear location history cache
  Future<void> clearLocationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(LOCATION_HISTORY_KEY);
      print('Location history cleared');
    } catch (e) {
      print('Error clearing location history: $e');
    }
  }

  // Get cached location within specified time range
  Future<loc.LocationData?> getCachedLocationInRange({
    required Duration timeRange,
    double? minAccuracy
  }) async {
    try {
      final history = await getLocationHistory(limit: 50);
      final cutoffTime = DateTime.now().subtract(timeRange).millisecondsSinceEpoch;
      
      for (loc.LocationData location in history) {
        // Check if location is within time range
        final locationTime = location.time?.toInt() ?? 0;
        if (locationTime >= cutoffTime) {
          // Check accuracy if specified
          if (minAccuracy != null && location.accuracy != null) {
            if (location.accuracy! <= minAccuracy) {
              return location;
            }
          } else {
            return location;
          }
        }
      }
    } catch (e) {
      print('Error getting cached location in range: $e');
    }
    return null;
  }

  // Get the last saved location from SharedPreferences
  Future<loc.LocationData?> getLastSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('last_latitude');
      final longitude = prefs.getDouble('last_longitude');
      final timestamp = prefs.getInt('last_timestamp');
      
      if (latitude != null && longitude != null) {
        return loc.LocationData.fromMap({
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': timestamp,
          'accuracy': prefs.getDouble('last_accuracy'),
          'altitude': prefs.getDouble('last_altitude'),
          'heading': prefs.getDouble('last_heading'),
          'speed': prefs.getDouble('last_speed'),
        });
      }
    } catch (e) {
      print('Error getting last saved location: $e');
    }
    return null;
  }

  // Save location to SharedPreferences
  Future<void> _saveLocationToPreferences(loc.LocationData location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('last_latitude', location.latitude ?? 0);
      await prefs.setDouble('last_longitude', location.longitude ?? 0);
      await prefs.setInt('last_timestamp', DateTime.now().millisecondsSinceEpoch);
      
      if (location.accuracy != null) {
        await prefs.setDouble('last_accuracy', location.accuracy!);
      }
      if (location.altitude != null) {
        await prefs.setDouble('last_altitude', location.altitude!);
      }
      if (location.heading != null) {
        await prefs.setDouble('last_heading', location.heading!);
      }
      if (location.speed != null) {
        await prefs.setDouble('last_speed', location.speed!);
      }
    } catch (e) {
      print('Error saving location to preferences: $e');
    }
  }

  // Dispose resources
  void dispose() {
    _backgroundTimer?.cancel();
    _locationController?.close();
    _isTracking = false;
  }
}
