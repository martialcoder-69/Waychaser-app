import 'dart:async';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:app_usage/app_usage.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Initialize the background service with periodic permission checks
  static Future<void> initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundStart,
        isForegroundMode: true,
        autoStart: true,
      ),
      iosConfiguration: IosConfiguration(),
    );

    await service.startService();
  }

  /// Entry point for background isolate
  @pragma('vm:entry-point')
  static void _onBackgroundStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
    await service.setForegroundNotificationInfo(
      title: "OSM Tracker Running",
      content: "Location tracking is active",
    );
  }

    const channel = AndroidNotificationChannel(
      'location_channel',
      'Location Tracking',
      description: 'This service keeps location tracking alive',
      importance: Importance.low,
    );

    await _notificationsPlugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _notificationsPlugin.show(
      888,
      'Tracking Active',
      'Tracking is running in background',
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
        ),
      ),
    );

    // Periodically recheck permissions
    Timer.periodic(const Duration(minutes: 1), (_) async {
      await checkAndRequestPermissions();
    });
  }
  static Future<bool> _ispermissiongiven() async {
    try{
      final now = DateTime.now();
      final list = await AppUsage().getAppUsage(now.subtract(const Duration(minutes: 5)),now);
      return list.isNotEmpty;
    }catch(e){
      print("Usage access not granted: $e");
      return false;
    }
  }
  /// Check and request all required permissions
  static Future<void> checkAndRequestPermissions() async {
    // Location 
    if (!await Permission.locationWhenInUse.isGranted) {
      await Permission.locationWhenInUse.request();
    }
    if (!await Permission.locationAlways.isGranted) {
      await Permission.locationAlways.request();
    }

    // Phone (for SIM info)
    if (!await Permission.phone.isGranted) {
      await Permission.phone.request();
    }

    // Battery Optimization Ignore
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }

    // GPS On
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      final intent = AndroidIntent(
        action: 'android.settings.LOCATION_SOURCE_SETTINGS',
      );
      await intent.launch();
    }

    final usageintent = AndroidIntent(
      action:"android.settings.USAGE_ACCESS_SETTINGS",
     );
     await usageintent.launch();

     bool granted = false;
     for(int i=0;i<6;i++){
      await Future.delayed(Duration(seconds: 10));
      granted = await _ispermissiongiven();
      if(granted) break;
     }
     if (!granted) {
        print("❌ User did not grant usage access.");
      } else {
      print("✅ Usage access granted.");
      }

    // Battery Optimization Manual Prompt
    final batteryIntent = AndroidIntent(
      action: 'android.settings.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS',
      data: 'package:com.example.Waychaser', // Update with your actual package
    );
    await batteryIntent.launch();
  }
}
