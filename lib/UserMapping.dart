import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class Usermapping extends StatefulWidget{
  const Usermapping({super.key});

  @override
  State<Usermapping> createState() => _Usermapping();
  
}

class _Usermapping extends State<Usermapping> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  List<LatLng> _userroute = [];
  List<Map<String, dynamic>> _branches = [];
  String? _currentUserId;
  Map<String,List<LatLng>> _timedRoute = {};
  Map<String,Color> _colorlegend = {};
  String? _selectedDate;
  DateTime? _startDate;
  DateTime? _endDate;
  double _currentZoom = 14.0;
  Color _getColorbydate(String date){
    if(_colorlegend.containsKey(date))return _colorlegend[date]!;
    final colors=[
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
    final index = date.hashCode%colors.length;
    _colorlegend[date] = colors[index];
    return colors[index];
  }
  Future<void> _loadAuthAndUser() async {
    final authFile = File('/data/user/0/com.example.Waychaser/app_flutter/bg_auth.json');
    if (!authFile.existsSync()) throw Exception('Auth File Missing');
    final Map<String, dynamic> authData = jsonDecode(authFile.readAsStringSync());
    _currentUserId = authData['userid'];
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
          _branches = data.map<Map<String, dynamic>>((branch) => {
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

  Future<void> _fetchroute(String userID) async {
    try {
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
        final dynamic jsonData = json.decode(response.body);
        Map<String,List<LatLng>> _groupedDate = {};
        if (jsonData is List) {
         for(var pos in jsonData){
          final lat = pos['latitude'];
          final lon = pos['longitude'];
          final timestamp = pos['timestamp'];
          final date = DateTime.parse(timestamp).toIso8601String().split("T")[0];
          _groupedDate.putIfAbsent(date, ()=>[]).add(LatLng(lat, lon));
         }
        }
        setState(() {
          _timedRoute = _groupedDate;
          _userroute = _groupedDate.values.expand((e)=>e).toList();
          if (_userroute.isNotEmpty) {
            _currentLocation = _userroute.last;
          }
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _mapController.move(_currentLocation!, 14);
        });
      }
    } catch (e) {
      print(e);
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
    _loadAuthAndUser();
    _getBranches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        title: const Center(child: Text("Mapping of Your Activity")),
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
                      tileProvider: NetworkTileProvider(),
                    ),
                    PolylineLayer(
                      polylines:(_selectedDate== null
                        ? _timedRoute.entries
                        :_timedRoute.entries.where((e)=>e.key == _selectedDate))
                       .map((entry){
                        final keys = entry.key;
                        final points = entry.value;
                        final color = _getColorbydate(keys);
                        return Polyline(
                          points: points,
                          color: color,
                          strokeWidth: 4,
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
                    if (_branches.isNotEmpty)
                      MarkerLayer(
                        markers: _branches.map((branch) {
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
                  ],
                ),

          // Date Range Picker
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(DateTime.now().year - 1),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  final pickedstarttime = await showTimePicker(
                    context: context, 
                    initialTime: const TimeOfDay(hour: 0, minute: 0));
                  
                  final pickedendtime = await showTimePicker(
                    context: context, 
                    initialTime: const TimeOfDay(hour: 23, minute: 59));
                  
                  final starttime = pickedstarttime ?? const TimeOfDay(hour: 0, minute: 0);
                  final endtime = pickedendtime ?? const TimeOfDay(hour: 23, minute: 59);

                  final startdate = DateTime(
                    picked.start.year,
                    picked.start.month,
                    picked.start.day,
                    starttime.hour,
                    starttime.minute,
                  );
                  final enddate = DateTime(
                    picked.end.year,
                    picked.end.month,
                    picked.end.day,
                    endtime.hour,
                    endtime.minute,
                  );
                  setState(() {
                    _startDate = startdate;
                    _endDate = enddate;
                  });
                }
              },
              child: Text(
                _startDate == null || _endDate == null
                    ? "Select Date Range"
                    : "${_startDate!.toString().substring(0, 16)} to ${_endDate!.toString().substring(0, 16)}",
              ),
            ),
          ),

          // Submit button
          Positioned(
            top: 70,
            left: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () {
                if (_currentUserId == null || _startDate == null || _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select a date range")),
                  );
                  return;
                }

                if (_startDate!.isAfter(_endDate!)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Start date cannot be after end date")),
                  );
                  return;
                }

                _fetchroute(_currentUserId!);
              },
              child: const Text("Show My Activity"),
            ),
          ),
          if(_timedRoute.isNotEmpty)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: _colorlegend.entries.map((entry){
                      final iselected = _selectedDate==entry.key;
                      return GestureDetector(
                        onTap: (){
                          setState(() {
                            _selectedDate = entry.key;
                          });
                        },
                      child:Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6,vertical: 4),
                        decoration: BoxDecoration(
                          color: iselected ? entry.value.withOpacity(0.2):Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      child:Row(
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
                              style: TextStyle(fontSize: 12,
                              fontWeight: iselected ? FontWeight.bold:FontWeight.normal,
                              color: iselected ? Colors.black : Colors.grey[800],
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
              if (_selectedDate != null)
                  Positioned(
                  bottom: 20,
                  right: 20,
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
        ],
      ),
    );
  }
} 
  
