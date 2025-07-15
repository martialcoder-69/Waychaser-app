import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

class Mapping extends StatefulWidget {
  const Mapping({super.key});

  @override
  State<Mapping> createState() => _Mapping();
}

class _Mapping extends State<Mapping> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<Map<String,dynamic>> banks = [];
  List<LatLng> _userroute = [];
  Map<String, List<LatLng>> _timedRoute = {};
  List<String> _navigationStack = [];
  List<Map<String, dynamic>> _branches = [];
  String? _managerID;
  Map<String, List<Map<String, dynamic>>> _tree = {};
  Map<String, Color> _colorlegend = {};
  String? _selectedDate;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  double _currentZoom = 14.0;
  String? _selectedrouteuser;
  

  Future<Map<String, dynamic>> _loadAuth() async {
    final authFile = File('/data/user/0/com.example.Waychaser/app_flutter/bg_auth.json');
    if (!authFile.existsSync()) throw Exception('Auth File Missing');
    return jsonDecode(authFile.readAsStringSync());
  }

  Color _getColorbydate(String date) {
    if (_colorlegend.containsKey(date)) return _colorlegend[date]!;
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.lime,
    ];
    final index = date.hashCode % colors.length;
    _colorlegend[date] = colors[index];
    return colors[index];
  }

  Future<void> _getUsers() async {
    final auth = await _loadAuth();
    final userID = auth['userid'];

    final response = await http.get(
      Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/authmap"),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      final raw = jsonDecode(response.body);
      final Map<String, List<Map<String, dynamic>>> parsedtree = {};
      raw.forEach((key, value) {
        if (value is List) {
          parsedtree[key] = value.map<Map<String, dynamic>>((item) => Map<String, dynamic>.from(item)).toList();
        }
      });

      setState(() {
        _tree = parsedtree;
        _managerID = userID;
        _branches.clear();
        _userroute.clear();

        if (_tree.containsKey(userID)) {
          _navigationStack.add(_managerID!);
          for (var user in _tree[userID]!) {
            if(user['lat']!=null && user['lon']!=null && user['time']!=null && user['userID']!=null){
              print(user['userID']);
              final utctime = DateTime.parse(user['time']);
              final isttime = tz.TZDateTime.from(utctime, tz.getLocation("Asia/Kolkata"));
            _branches.add({
              'lat': user['lat'],
              'lon': user['lon'],
              'time': isttime.toIso8601String(),
              'name': user['userID']
            });
          }
          }
        }
        if (_branches.isNotEmpty && _currentLocation == null) {
          _currentLocation = LatLng(_branches.first['lat'], _branches.first['lon']);
        }
      });
    }
  }

  Set<String> _checksearch(String user) {
    Set<String> users = {};
    final subs = _tree[user];
    if (subs == null) return users;
    for (var i in subs) {
      final toadd = i['userID'];
      if (toadd != null && toadd is String) {
        users.add(toadd);
        users.addAll(_checksearch(toadd));
      }
    }
    return users;
  }

  Future<void> _searchinguser(String? user) async {
    if (user == null || user.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter a valid User ID")));
      return;
    }

    user = user.trim();
    final auth = await _loadAuth();
    final userID = auth['userid'];

    if (_tree.containsKey(userID)) {
      final alloweduser = _checksearch(userID);
      if (!alloweduser.contains(user)) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("This person is not reporting to you")));
        return;
      }

      for (final key in _tree.keys) {
        final subs = _tree[key]!;
        for (var i in subs) {
          if (i['userID'] == user && i['lat'] != null && i['lon'] != null) {
            final lat = i['lat'];
            final lon = i['lon'];
            final latlon = LatLng(lat, lon);
            final utctime = DateTime.parse(i['time']);
            final isttime = tz.TZDateTime.from(utctime, tz.getLocation("Asia/Kolkata"));
            setState(() {
              _managerID = key;
              _navigationStack.add(key);
              _branches = [
                {
                  'lat': i['lat'],
                  'lon': i['lon'],
                  'name': i['userID'],
                  'time': isttime.toIso8601String()
                }
              ];
              _currentLocation = latlon;
              _userroute.clear();
              _timedRoute.clear();
              _colorlegend.clear();
              _selectedDate = null;
            });

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(latlon, _currentZoom);
            });
            return;
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("There is no one reporting to you")),
      );
    }
  }

  Future<void> _initlialmapping(String userID) async {
    final startdate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0);
    final enddate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 23, 59);

    final response = await http.post(
      Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/getmap"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "userID": userID,
        "startDate": startdate.toIso8601String(),
        "endDate": enddate.toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      final jsondata = json.decode(response.body);
      if (jsondata is List) {
        DateTime? lastime;
        final Map<String, List<LatLng>> grouped = {};
        for (var point in jsondata) {
          final utctime = DateTime.parse(point['timestamp']);
          final isttime = tz.TZDateTime.from(utctime, tz.getLocation("Asia/Kolkata"));
          final lat = point['latitude'];
          final lon = point['longitude'];
          final timestamp = isttime;
          if(lastime==null || timestamp.difference(lastime).inMinutes>=120){
            lastime = timestamp;
          }
          final timekey = lastime.toIso8601String().split("T")[1].split(".")[0];
          grouped.putIfAbsent(timekey,()=>[]).add(LatLng(lat, lon));
        }
        setState(() {
          _timedRoute = grouped;
          _userroute = grouped.values.expand((e) => e).toList();
          if (_userroute.isNotEmpty) {
            _currentLocation = _userroute.last;
          }
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_currentLocation!, 14);
        });
      }
    }
  }

  Future<void> _fetchroute(String userID) async {
    _timedRoute.clear();
    _userroute.clear();
    _colorlegend.clear();

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final pickedstarttime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 0, minute: 0),
      );

      final pickedendtime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
      );

      final startime = pickedstarttime ?? const TimeOfDay(hour: 0, minute: 0);
      final endtime = pickedendtime ?? const TimeOfDay(hour: 23, minute: 59);

      final startDate = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        startime.hour,
        startime.minute,
      );

      final endDate = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        endtime.hour,
        endtime.minute,
      );

      _startDate = startDate;
      _endDate = endDate;

      final response = await http.post(
        Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/getmap"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userID": userID,
          "startDate": _startDate!.toIso8601String(),
          "endDate": _endDate!.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, List<LatLng>> grouped = {};
        if(_endDate!.difference(_startDate!).inHours<=24){
          DateTime? lasttime;
          final jsonData = json.decode(response.body);
        if (jsonData is List) {
          for (var point in jsonData) {
            final utctime = DateTime.parse(point['timestamp']);
            final isttime = tz.TZDateTime.from(utctime, tz.getLocation("Asia/Kolkata"));
            final lat = point['latitude'];
            final lon = point['longitude'];
            final timestamp = isttime;
            if(lasttime==null || timestamp.difference(lasttime).inMinutes>=120){
              lasttime = timestamp;
            }
            final timekey = lasttime.toIso8601String().split("T")[1].split(".")[0];
          grouped.putIfAbsent(timekey,()=>[]).add(LatLng(lat, lon)); 
           
          }
        }
        }
        else{
          final jsonData = json.decode(response.body);
        if (jsonData is List) {
          for (var point in jsonData) {
            final utctime = DateTime.parse(point['timestamp']);
            final isttime = tz.TZDateTime.from(utctime, tz.getLocation("Asia/Kolkata"));
            final lat = point['latitude'];
            final lon = point['longitude'];
            final date = isttime.toIso8601String().split("T")[0];
            grouped.putIfAbsent(date, () => []).add(LatLng(lat, lon));
          }
        }
        }

          setState(() {
            _timedRoute = grouped;
            _userroute = grouped.values.expand((e) => e).toList();
            _selectedDate = null;
            if (_userroute.isNotEmpty) {
              _currentLocation = _userroute.last;
            }
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(_currentLocation!, 14);
          });
      }
    }
  }

  void showMappingSheet(String user) {
    setState(() {
      _selectedrouteuser = user;
    });
    showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.7,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const Text(
                    "Viewing today's route",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text("Use the floating button below to pick date/time."),
                ],
              ),
            ),
          );
        },
      );
    },
  );
  }
Future<void> _getBranches() async {
    try {
      final response = await http.get(
        Uri.parse("https://9367d2d45914.ngrok-free.app/api/v2/getBranch"),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          banks = data.map<Map<String, dynamic>>((branch) => {
            'lat': branch['lat'],
            'lon': branch['lon'],
            'name': branch['name'],
          }).toList();
        });
      } else {
        print("Branch fetch failed: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  double _getMarkerSizeFromZoom(double zoom) {
    const double minSize = 20;
    const double maxSize = 50;
    const double minZoom = 2.0;
    const double maxZoom = 18.0;

    double normalizedZoom = ((zoom - minZoom) / (maxZoom - minZoom)).clamp(0.0, 1.0);
    return minSize + (maxSize - minSize) * normalizedZoom;
  }

  @override
  void initState() {
    super.initState();
    _getUsers();
    _getBranches();
  }

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: Colors.lightBlue,
      title: const Center(child: Text("Mapping of Users")),
    ),
    body: Stack(
      children: [
        _currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: _currentZoom,
                  minZoom: 2,
                  maxZoom: 18,
                  onMapEvent: (event) {
                    setState(() {
                      _currentZoom = event.camera.zoom;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.Waychaser',
                    tileProvider:NetworkTileProvider(),
                  ),
                  if (_userroute.isNotEmpty && _timedRoute.isNotEmpty)
                    PolylineLayer(
                      polylines: (_selectedDate == null
                              ? _timedRoute.entries
                              : _timedRoute.entries.where((e) => e.key == _selectedDate))
                          .map((entry) {
                        final date = entry.key;
                        final points = entry.value;
                        final color = _getColorbydate(date);
                        return Polyline(
                          points: points,
                          color: color,
                          strokeWidth: 4.0,
                        );
                      }).toList(),
                    ),
                  if (_userroute.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userroute.last,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                    if (banks.isNotEmpty)
                      MarkerLayer(
                        markers: banks.map((branch) {
                          return Marker(
                            point: LatLng(branch["lat"], branch["lon"]),
                            width: _getMarkerSizeFromZoom(_currentZoom),
                            height: _getMarkerSizeFromZoom(_currentZoom),
                            child: GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text("Branch Info"),
                                    content: Text(branch["name"]),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  ),
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
                  if (_branches.isNotEmpty)
                    MarkerLayer(
                      markers: _branches.map((branch) {
                        final user = branch['name'];
                        final rawtime = branch['time'];
                        final formattime = DateTime.parse(rawtime).toString().split('.').first;
                        return Marker(
                          point: LatLng(branch["lat"], branch["lon"]),
                          width: 80,
                          height: 80,
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                isScrollControlled: true,
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return DraggableScrollableSheet(
                                    initialChildSize: 0.3,
                                    minChildSize: 0.2,
                                    maxChildSize: 0.7,
                                    builder: (context, scrollController) {
                                      return Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.cyanAccent,
                                          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        child: SingleChildScrollView(
                                          controller: scrollController,
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 5,
                                                margin: const EdgeInsets.only(bottom: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[400],
                                                  borderRadius: BorderRadius.circular(2),
                                                ),
                                              ),
                                              Text(
                                                "User: $user",
                                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                              ),
                                              const SizedBox(height: 8),
                                              Text("Last Updated Time: $formattime"),
                                              const SizedBox(height: 24),
                                              if (_navigationStack.length > 1)
                                                ElevatedButton.icon(
                                                  onPressed: () {
                                                    final previousManager = _navigationStack.removeLast();
                                                    setState(() {
                                                      _managerID = previousManager;
                                                      _userroute.clear();
                                                      _branches.clear();
                                                      if (_tree.containsKey(_managerID)) {
                                                        for (var user in _tree[_managerID]!) {
                                                          _branches.add({
                                                            'lat': user['lat'],
                                                            'lon': user['lon'],
                                                            'time': user['time'],
                                                            'name': user['userID']
                                                          });
                                                        }
                                                      }
                                                    });
                                                    Navigator.pop(context);
                                                  },
                                                  icon: const Icon(Icons.arrow_back),
                                                  label: const Text("Go Back"),
                                                ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                children: [
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      Navigator.pop(context);
                                                      _branches.clear();
                                                      _initlialmapping(user);
                                                      showMappingSheet(user);
                                                    },
                                                    icon: const Icon(Icons.map),
                                                    label: const Text("View Mapping"),
                                                  ),
                                                  ElevatedButton.icon(
                                                    onPressed: () {
                                                      if (_tree.containsKey(user) && _tree[user]!.isNotEmpty) {
                                                        Navigator.pop(context);
                                                        setState(() {
                                                          if (_managerID != null) {
                                                            _navigationStack.add(_managerID!);
                                                          }
                                                          _managerID = user;
                                                          _userroute.clear();
                                                          _branches.clear();
                                                          for (var user in _tree[_managerID]!) {
                                                            if(user['lat']!=null && user['lon']!=null && user['time']!=null && user['userID']!=null){
                                                            _branches.add({
                                                              'lat': user['lat'],
                                                              'lon': user['lon'],
                                                              'time': user['time'],
                                                              'name': user['userID']
                                                            });
                                                          }
                                                          }
                                                        });
                                                      } else {
                                                        Navigator.pop(context);
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text("No further Subordinates available")),
                                                        );
                                                      }
                                                    },
                                                    icon: const Icon(Icons.map),
                                                    label: const Text("View Subordinates"),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 24),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.deepPurple,
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        offset: const Offset(0, 2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    user,
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Icon(Icons.person, color: Colors.blue, size: 30),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
        if (_currentLocation != null)
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Enter User Id",
                            border: InputBorder.none,
                          ),
                          onSubmitted: (value) => _searchinguser(value),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          _searchinguser(_searchController.text.trim());
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.search),
                      ),
                    ],
                  ),
                ),
                if (_timedRoute.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 50),
                      child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: _colorlegend.entries.map((entry) {
                        final isSelected = _selectedDate == entry.key;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedDate = entry.key;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? entry.value.withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  margin: const EdgeInsets.only(right: 6),
                                  decoration: BoxDecoration(
                                    color: entry.value,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? Colors.black : Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        if (_selectedDate != null)
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
              icon: const Icon(Icons.clear),
              label: const Text("Reset Filter"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 5,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ),
          if(_selectedrouteuser!=null)
          Positioned(
            bottom: 20,
            right: 20,  
            child: FloatingActionButton.extended(
              backgroundColor: Colors.blue,
              onPressed:(){
                _fetchroute(_selectedrouteuser!); 
              },
              icon: const Icon(Icons.calendar_month),
              label: const Text("Pick Date/Time"), ),
          )
      ],
    ),
  );
}
}