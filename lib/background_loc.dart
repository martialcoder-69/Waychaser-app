import 'dart:convert';
import 'dart:io';
import 'dart:async';


import 'package:Waychaser/Offline_db.dart';
import 'package:app_usage/app_usage.dart';
import 'package:background_locator_2/location_dto.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
//import 'package:intl/intl.dart';
//import 'package:timezone/data/latest.dart' as tz;
//import 'package:timezone/timezone.dart' as tz;
import 'package:network_info_plus/network_info_plus.dart';
import 'package:mobile_number/mobile_number.dart';
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:flutter/services.dart';

const String offlineFileName = 'offline_data.json';
Timer? _retryTimer;
Timer? _watchdogTimer;
final Lock _dblock = Lock();
/// Device Info Model
class DeviceInfoModel {
  final String model;
  final String os;
  final String osVersion;
  final String serial;
  final String ipAddress;

  const DeviceInfoModel({
    required this.model,
    required this.os,
    required this.osVersion,
    required this.serial,
    required this.ipAddress,
  });
}

/// File I/O

Future<File> _getAppUsageFlagFile() async {
  final dir = await getApplicationDocumentsDirectory();
  return File('${dir.path}/app_usage_flag.txt');
}
Future<bool> _wasAppUsageSentToday() async {
  final file = await _getAppUsageFlagFile();
  if (!await file.exists()) return false;

  final lastRunStr = await file.readAsString();
  final lastRunDate = DateTime.tryParse(lastRunStr);
  if (lastRunDate == null) return false;

  final now = DateTime.now();
  return lastRunDate.year == now.year &&
      lastRunDate.month == now.month &&
      lastRunDate.day == now.day;
}
Future<void> _markAppUsageSentToday() async {
  final file = await _getAppUsageFlagFile();
  await file.writeAsString(DateTime.now().toIso8601String());
}
Future<void> runAppUsageOncePerDay() async {
  final alreadySent = await _wasAppUsageSentToday();
  if (alreadySent) {
    print("✅ App usage already sent today.");
    return;
  }
  print("📤 Sending yesterday's app usage...");
  await _getAppusage();
  await _markAppUsageSentToday();
}
Future<List<Map<String, dynamic>>> _readOfflineData() async {
  return await OfflineDB.readall();
}

Future<void> storeOffline(dynamic data) async {
   if (data is !Map<String, dynamic>) {
    print("❌ storeOffline called with invalid type: ${data.runtimeType}");
    return;
  }
  await _dblock.synchronized(() async {
    await  OfflineDB.insert(data);
    print("✅ Data stored in SQLite.");
  });
}


/// Retry logic - batch sending
Future<void> initializeRetryLoop() async {
  print("✅ initializeRetryLoop() started");
  _retryTimer?.cancel();
  _retryTimer = Timer.periodic(const Duration(seconds: 6), (timer) async {
    await _dblock.synchronized(() async {
      final entries = await _readOfflineData();
    if (entries.isEmpty) {
      print("✅ No offline entries to send. Stopping retry loop.");
      return;
    }

    const batchSize = 100;
    final batch = entries.take(batchSize).toList();
    final response = await sendBatchToServer(batch);

    if (response != null && response.statusCode == 200) {
      await OfflineDB.deletefirstN(batch.length);
      print("✅ Sent and removed $batchSize entries from SQLite.");
    } else {
      print("❌ Retry failed, will try again in 5 minutes.");
    }
    });
  });
  }

Future<http.Response?> sendBatchToServer(List<Map<String, dynamic>> batch) async {
  try {
    final response = await http.post(
      Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/store"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(batch),
    );

    print('Batch response: ${response.statusCode} - ${response.body}');
    return response;
  } catch (e) {
    print("Batch send failed: $e");
    return null;
  }
}

/// Watchdog to restart the retry loop
void startWatchdogTimer() {
  _watchdogTimer?.cancel();
  _watchdogTimer = Timer.periodic(const Duration(minutes: 10), (_) {
    print("Watchdog: restarting retry loop and checking state...");
    initializeRetryLoop();
  });
}

/// Device Info
Future<DeviceInfoModel> getDeviceInfo() async {
  final deviceInfoPlugin = DeviceInfoPlugin();
  final networkInfo = NetworkInfo();
  final String ipAddress = await networkInfo.getWifiIP() ?? 'Unavailable';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfoPlugin.androidInfo;
    return DeviceInfoModel(
      model: androidInfo.model,
      os: 'Android',
      osVersion: androidInfo.version.release,
      serial: androidInfo.id,
      ipAddress: ipAddress,
    );
  }

  return const DeviceInfoModel(
    model: 'Unknown',
    os: 'Unknown',
    osVersion: 'Unknown',
    serial: 'Unknown',
    ipAddress: 'Unavailable',
  );
}

/// Load auth
Future<Map<String, dynamic>> _loadAuth() async {
  final authFile = File('/data/user/0/com.example.Waychaser/app_flutter/bg_auth.json');
  if (!authFile.existsSync()) throw Exception('Auth File Missing');
  final Map<String, dynamic> authData = jsonDecode(authFile.readAsStringSync());
  return {'userid': authData['userid'] as String?};
}
Future<Map<String, int>> getAppLaunchCounts() async {
  const platform = MethodChannel('com.waychaser/usage');
  try {
    final result = await platform.invokeMethod<Map>('getLaunchCounts');
    return result!.map((key, value) => MapEntry(key.toString(), int.parse(value.toString())));
  } catch (e) {
    print("Error fetching launch counts: $e");
    return {};
  }
}
Future<void> _getAppusage() async{
  try{final auth = await _loadAuth();
  final user = auth['userid'];

  final deviceinfo = await getDeviceInfo();
   DateTime now = DateTime.now();
   DateTime yesterday = now.subtract(Duration(days: 1));
   DateTime endDate = DateTime(yesterday.year,yesterday.month,yesterday.day,18,0);
   DateTime startDate = DateTime(yesterday.year,yesterday.month,yesterday.day,8,0);

   List<AppUsageInfo> infolist = await AppUsage().getAppUsage(startDate, endDate);
   Map<String,int> launchapps = await getAppLaunchCounts(); 
   final payload = {
    "userID":user,
    "model":deviceinfo.model,
    "serial":deviceinfo.serial,
    'timestamp':DateTime.now().toIso8601String(),
    "apps":infolist.map((i)=>{
      "app":i.packageName,
      "duration":i.usage.inMinutes,
      "launches":launchapps[i.packageName],
    }).toList()
   };

   try{final response = await http.post(
    Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/appUsage"),
    headers: {"Content-Type": "application/json"},
    body:json.encode(payload),
   );
   if(response.statusCode==200){
    print("Appusage sent");
   }
   }catch(e){
    print("Server:$e");
   }

  }catch(e){
    print(e);
  }

}
/// Network status
Future<String> getNetworkStatus() async {
  final result = await Connectivity().checkConnectivity();
  return result.toString();
}

/// Send single entry fallback
Future<http.Response?> sendToServer(Map<String, dynamic> data) async {
  try {
    final response = await http.post(
      Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/store"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    print('Server response: ${response.statusCode} - ${response.body}');
    return response;
  } catch (e) {
    print("Send to server failed: $e");
    return null;
  }
}

/// Callback
@pragma('vm:entry-point')
Future<void> callback(LocationDto data) async {
  print("🔔 Headless callback fired: $data");
  try {
    final auth = await _loadAuth();
    final userId = auth['userid'];

    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    final batteryState = await battery.batteryState;
    final isBatterySaverOn = await battery.isInBatterySaveMode;

    final networkStatus = await getNetworkStatus();
    final deviceInfo = await getDeviceInfo();

    final hasSimPermission = await MobileNumber.hasPhonePermission;
    String simCountryIso = '';
    String simCountryPhonePrefix = '';
    String simDisplayName = '';
    String simNumber = '';
    int simSlotIndex = -1;

    if (hasSimPermission) {
      final simCards = await MobileNumber.getSimCards ?? [];
      if (simCards.isNotEmpty) {
        final sim = simCards.first;
        simCountryIso = sim.countryIso ?? "-1";
        simCountryPhonePrefix = sim.countryPhonePrefix ?? "-1";
        simDisplayName = sim.displayName ?? "-1";
        simNumber = sim.number ?? "-1";
        simSlotIndex = sim.slotIndex ?? -1;
      }
    }

    final networkInfo = NetworkInfo();
    final String wifiIP = await networkInfo.getWifiIP() ?? '';
    final String wifiName = await networkInfo.getWifiName() ?? '';
    final String wifiBSSID = await networkInfo.getWifiBSSID() ?? '';
    final String wifiSubmask = await networkInfo.getWifiSubmask() ?? '';
    final String wifiGatewayIP = await networkInfo.getWifiGatewayIP() ?? '';
    final String wifiBroadcast = await networkInfo.getWifiBroadcast() ?? '';
    final String wifiIPv6 = await networkInfo.getWifiIPv6() ?? '';

    final DateTime istTime = DateTime.now().toUtc();
    final String istTimestamp = istTime.toIso8601String();
    print(istTimestamp);
    final Map<String, dynamic> toSend = {
      'userID': userId,
      'latitude': data.latitude,
      'longitude': data.longitude,
      'accuracy': data.accuracy,
      'speed': data.speed,
      'speedaccuracy': data.speedAccuracy,
      'heading': data.heading,
      'ismocked': data.isMocked,
      'timestamp': istTimestamp,
      'model': deviceInfo.model,
      'os': deviceInfo.os,
      'osVersion': deviceInfo.osVersion,
      'serial': deviceInfo.serial,
      'ipAddress': deviceInfo.ipAddress,
      'batteryLevel': batteryLevel,
      'batteryState': batteryState.toString(),
      'batterySaver': isBatterySaverOn,
      'network': networkStatus,
      'simCountryIso': simCountryIso,
      'simCountryPhonePrefix': simCountryPhonePrefix,
      'simDisplayName': simDisplayName,
      'simNumber': simNumber,
      'simSlotIndex': simSlotIndex,
      'wifiIP': wifiIP,
      'wifiName': wifiName,
      'wifiBSSID': wifiBSSID,
      'wifiSubmask': wifiSubmask,
      'wifiGatewayIP': wifiGatewayIP,
      'wifiBroadcast': wifiBroadcast,
      'wifiIPv6': wifiIPv6,
    };

    final response = await sendToServer(toSend);
    if (response == null || response.statusCode != 200) {
      print("📦 Network failure. Storing data offline...");
      await storeOffline(toSend);
    } else {
      print("Data sent successfully.");
    }
  } catch (e, st) {
    print("Callback error: $e\n$st");
  }
}

@pragma('vm:entry-point')
void initCallback(Map<String, dynamic> params) {
  print("Init callback triggered.");
  startWatchdogTimer();
}

@pragma('vm:entry-point')
void disposeCallback() {
  print("Dispose callback triggered.");
  _retryTimer?.cancel();
  _watchdogTimer?.cancel();
}
