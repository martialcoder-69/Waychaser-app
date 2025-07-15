import 'dart:async';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static StreamSubscription<Position>? _streamSubscription;
  static final StreamController<Map<String, dynamic>> _locationController =
      StreamController<Map<String, dynamic>>.broadcast();
  static Timer? _pollingTimer;

  
  static void startLocationUpdates() {
    // Cancel any existing streams or timers
    _streamSubscription?.cancel();
    _pollingTimer?.cancel();

    // Start location stream
    _streamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0, // Ignore very small movements
      ),
    ).listen(
      (position) {
        _locationController.add(_buildLocationData(position, source: 'stream'));
        _resetPollingTimer(); // Keep the polling alive
      },
      onError: (error) {
        print('Location stream error: $error');
      },
      cancelOnError: false,
    );

    _resetPollingTimer(); // Start fallback polling
  }

  /// Fallback polling every 5 seconds
  static void _resetPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer(const Duration(seconds: 5), () async {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        _locationController.add(_buildLocationData(position, source: 'poll'));
      } catch (e) {
        print('Polling error: $e');
      }
      _resetPollingTimer(); // Schedule next poll
    });
  }

  /// Returns broadcast stream of location updates
  static Stream<Map<String, dynamic>> getLocationStream() {
    return _locationController.stream;
  }

  /// Stops both stream and polling
  static void stopLocationUpdates() {
    _pollingTimer?.cancel();
    _streamSubscription?.cancel();
    // Don't close the stream controller unless the app is exiting completely
    // _locationController.close();
  }

  /// Helper to convert Position to Map
  static Map<String, dynamic> _buildLocationData(Position pos, {required String source}) {
    return {
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'accuracy': pos.accuracy,
      'timestamp': DateTime.now().toIso8601String(),
      'source': source,
    };
  }
}
