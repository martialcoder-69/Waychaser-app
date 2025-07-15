import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:Waychaser/UserMapping.dart';
import 'package:background_locator_2/settings/locator_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart' hide AndroidSettings, LocationAccuracy;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:Waychaser/Mapping.dart';
import 'package:Waychaser/background_loc.dart';
import 'package:Waychaser/permission_service.dart';
import 'package:Waychaser/presentation/pages/Loginpage.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:background_locator_2/background_locator.dart';
import 'package:background_locator_2/settings/android_settings.dart';
import 'package:path_provider/path_provider.dart';
import 'package:Waychaser/location_service.dart';
import 'package:url_launcher/url_launcher.dart';

//import 'widgets/search_controls.dart';

class OpenStreetMapScreen extends StatefulWidget {
  const OpenStreetMapScreen({super.key});

  @override
  State<OpenStreetMapScreen> createState() => _OSMState();
}

class _OSMState extends State<OpenStreetMapScreen> with WidgetsBindingObserver {
  static String? FinalUser;
  final MapController _mapController = MapController();
  StreamSubscription<Map<String, dynamic>>? _locationSubscription;
  StreamSubscription<ServiceStatus>? _serviceStatusSubscription;
  List<Map<String,dynamic>> _branches = [];
  double _currentzoom = 14.0;

  bool isLoading = true;
  bool showRoute = true;
  bool isTracking = false;

  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];


  Future<void> _getBranches() async{
    try{
      final response = await http.get(
        Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/getBranch"),
        headers: {"Content-Type": "application/json"}
      );

      if(response.statusCode == 200){
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _branches = data.map<Map<String,dynamic>>((branch)=>{
            'lat': branch['lat'],
            'lon': branch['lon'],
            'name': branch['name']
          }).toList();
        });
      }
      else{
        print(response.statusCode);
      }
    }catch(e){
      print("Error bring lat lon");
      print("$e");
    }
  }

  Future<bool> _initializeTokenAndUser() async {
      try {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bg_auth.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      FinalUser = data['userid'];
      return FinalUser != null;
    }
    return false;
  } catch (e) {
    print("Failed to load user ID: $e");
    return false;
  }
  }

  Future<bool> _ensureLocationPermission() async {
    PermissionStatus status = await Permission.locationAlways.status;
    if (!status.isGranted) {
      status = await Permission.locationAlways.request();
    }
    return status.isGranted;
  }

  void _keepChecking() {
    bool isPrevious = false;
    _serviceStatusSubscription = Geolocator.getServiceStatusStream().listen((status) {
      if (status == ServiceStatus.disabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location has been turned OFF")));
        }
        isPrevious = false;
      } else if (status == ServiceStatus.enabled && !isPrevious) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location has been turned ON")));
        }
        _checkAndStartLocation();
        isPrevious = true;
      }
    });
  }

  Future<void> _saveAuth(String userid) async {
    final dir = await getApplicationDocumentsDirectory();
    final f = File('${dir.path}/bg_auth.json');
    await f.writeAsString(jsonEncode({'userid': userid}), mode: FileMode.write);
  }

  Future<void> _startBackgroundUpdates() async {
    if (await Permission.locationAlways.isGranted) {
      await _saveAuth(FinalUser!);
      await BackgroundLocator.initialize();
      await BackgroundLocator.registerLocationUpdate(
        callback,
        initCallback: initCallback,
        initDataCallback: {"userID": FinalUser},
        disposeCallback: disposeCallback,
        androidSettings: AndroidSettings(
          accuracy: LocationAccuracy.HIGH,
          interval: 5,
          distanceFilter: 0,
          client: LocationClient.google,
          wakeLockTime: 3600,
          androidNotificationSettings: AndroidNotificationSettings(
            notificationChannelName: 'Location Tracking',
            notificationTitle: 'Tracking Location',
            notificationMsg: 'Your location is being tracked',
            notificationBigMsg: 'Location tracking active',
            notificationIcon: 'ic_launcher',
          ),
        ),
      );
    }
  }

  Future<void> _checkAndStartLocation() async {
    if (isTracking) return;

    _keepChecking();
    await _locationSubscription?.cancel();

    if (await _ensureLocationPermission()) {
      isTracking = true;
      LocationService.startLocationUpdates();
      _locationSubscription = LocationService.getLocationStream().listen((locationData) {
        final lat = locationData['latitude'];
        final lon = locationData['longitude'];
        setState(() {
          _currentLocation = LatLng(lat, lon);
          isLoading = false;
        });
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location permission is required.")));
    }
  }

  

  

  Future<void> _userCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 14);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Current location not available")));
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state){
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      //_stopForegroundUpdates();
     // _startBackgroundUpdates();
    }
    if (state == AppLifecycleState.detached) {
      print("App is being killed");
      _stopBackgroundUpdates();
    } 
    else if (state == AppLifecycleState.resumed) {
      _checkAndStartLocation();
      //_startBackgroundUpdates();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(Duration.zero, () async {
    final initialized = await _initializeTokenAndUser(); // get FinalUser
    if (initialized) {
      await _tocheckpermissions();
      await _checkAndStartLocation();

      // Start background updates only after user ID and permissions are ready
      await _togetranches();
      await initializeRetryLoop();
      await _startBackgroundUpdates();
      await runAppUsageOncePerDay();

    }
  });
}
  Future<void> _togetranches()async{
    await _getBranches();
  }
  Future<void> _tocheckpermissions() async{
    await PermissionService.checkAndRequestPermissions();
  }
  

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopForegroundUpdates();
    _stopBackgroundUpdates();
    super.dispose();
  }

  void _stopForegroundUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    _serviceStatusSubscription?.cancel();
    _serviceStatusSubscription = null;
    LocationService.stopLocationUpdates();
    isTracking = false;
  }

  void _stopBackgroundUpdates() {
    BackgroundLocator.unRegisterLocationUpdate();
  }
  Future<void> _opengoogle() async{
    if (_currentLocation == null || _destination == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location not available")));
    return;
  }

  //final origin = '${_currentLocation!.latitude},${_currentLocation!.longitude}';
  final dest = '${_destination!.latitude},${_destination!.longitude}';

  final url = Uri.parse(
    'google.navigation:q=$dest&mode=d',
  );

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open Google Maps")));
  }
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.lightBlue),
            child: Text(
              'Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            leading: Icon(Icons.person),
            title: const Text('User'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
              MaterialPageRoute(builder: (context)=> const Usermapping()),);
            },
          ),
          ListTile(
            leading: Icon(Icons.admin_panel_settings),
            title: const Text('View Mapping'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Mapping()),
              );
            },
          ),
        ],
      ),
    ),
    appBar: AppBar(
      backgroundColor: Colors.lightBlue,
      automaticallyImplyLeading: false,
      title: const Text("Live Tracker"),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      actions: [
  IconButton(
    icon: const Icon(Icons.logout),
    tooltip: "Logout",
    onPressed: () async {
      // Stop updates
      _stopForegroundUpdates();
      _stopBackgroundUpdates();

      // Optional: Clear local auth file if needed
      final dir = await getApplicationDocumentsDirectory();
      final authFile = File('${dir.path}/bg_auth.json');
      if (await authFile.exists()) {
        await authFile.delete();
      }

      // Navigate back to login screen
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Loginpage()),
          (Route<dynamic> route) => false,
        );
      }
    },
  )
],

    ),
    body: Stack(
      children: [
        _currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: _currentzoom,
                  minZoom: 2,
                  maxZoom: 18,
                  onMapEvent: (event){
                    setState(() {
                      _currentzoom = event.camera.zoom;
                    });
                  }
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.Waychaser',
                    tileProvider: NetworkTileProvider(),
                  ),
                  CurrentLocationLayer(
                    style: LocationMarkerStyle(
                      marker: const DefaultLocationMarker(
                        child: Icon(Icons.location_pin, color: Colors.red, size: 35),
                      ),
                      markerSize: const Size(35, 35),
                      markerDirection: MarkerDirection.heading,
                    ),
                  ),
                  if (_destination != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _destination!,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag, color: Colors.green, size: 40),
                        ),
                      ],
                    ),
                    if (_branches.isNotEmpty)
  MarkerLayer(
    markers: _branches.map((branch) {
      return Marker(
        point: LatLng(branch["lat"], branch["lon"]),
        width: _getMarkerSizeFromZoom(_currentzoom),
        height: _getMarkerSizeFromZoom(_currentzoom),
        child: GestureDetector(
          onTap: () {
            showModalBottomSheet(
              isScrollControlled: true,
              context: context, 
              backgroundColor: Colors.transparent,
              builder:(context){
                return DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.2,
                  maxChildSize: 0.7,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.cyanAccent,
                        borderRadius: BorderRadius.vertical(top:Radius.circular(20)),
                      ),
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Container(
                              width:40,
                              height: 8,
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              "Name:${branch['name']}",
                              style: const TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                            ),
                            Row(
                              mainAxisAlignment:MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed:(){
                                    setState(() {
                                      _destination = LatLng(branch['lat'], branch['lon']);
                                    });
                                    _opengoogle();
                                  } ,
                                  icon: const Icon(Icons.rocket), 
                                  label: Text("Get Route to ${branch['name']}"))
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                  );
              }
            );
          },
          child: Image.asset(
            'assets/image/bankicon.png',
            width:40,
            height:40,
            fit:BoxFit.contain,
          )
        ),
      );
    }).toList(),
  ),
                  if (showRoute && _route.isNotEmpty)
                    PolylineLayer(
                      polylines: [
                        Polyline(points: _route, color: Colors.blue, strokeWidth: 4.0),
                      ],
                    ),
                ],
              ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      elevation: 0,
      onPressed: _userCurrentLocation,
      backgroundColor: Colors.blue,
      child: const Icon(Icons.my_location, size: 30, color: Colors.white),
    ),
  );
}

  double _getMarkerSizeFromZoom(double zoom) {
  // Define min and max sizes
  const double minSize = 20;
  const double maxSize = 50;

  // Define the zoom range (adjust if needed)
  const double minZoom = 2.0;
  const double maxZoom = 18.0;

  // Normalize zoom to 0–1 scale
  double normalizedZoom = ((zoom - minZoom) / (maxZoom - minZoom)).clamp(0.0, 1.0);

  // Size increases as you zoom in
  return minSize + (maxSize - minSize) * normalizedZoom;
}

}