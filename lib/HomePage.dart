import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:http/http.dart' as http;
import 'package:loginui/EventPage.dart';
import 'package:loginui/ReportPage.dart';
import 'package:loginui/chatbotPage.dart';
import 'package:loginui/loginpage.dart';
import 'package:google_nav_bar/google_nav_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    const OpenstreetmapScreen(),
    EventsMapPage(),
    ReportPage(),
    Chatbotpage()
  ];

  Future<void> _logout() async {
    try {
      // Replace this with your own logout logic if needed
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
     Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => LoginPage()),
);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCE Campus Navigation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 12),
          child: GNav(
            rippleColor: Colors.grey[300]!,
            hoverColor: Colors.grey[100]!,
            gap: 8,
            activeColor: Colors.blue,
            iconSize: 24,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            duration: const Duration(milliseconds: 400),
            tabBackgroundColor: Colors.blue.withOpacity(0.1),
            color: Colors.black,
            tabs: const [
              GButton(
                icon: Icons.home,
                text: 'Home',
              ),
              GButton(
                icon: Icons.event,
                text: 'Events',
              ),
              GButton(
                icon: Icons.report,
                text: 'Reports',
              ),
              GButton(
                icon: Icons.chat,
                text: 'Chatbot',
                )
            ],
            selectedIndex: _selectedIndex,
            onTabChange: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }
}

class OpenstreetmapScreen extends StatefulWidget {
  const OpenstreetmapScreen({super.key});

  @override
  State<OpenstreetmapScreen> createState() => _OpenstreetmapScreenState();
}

class _OpenstreetmapScreenState extends State<OpenstreetmapScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  final TextEditingController _locationController = TextEditingController();
  bool isLoading = true;
  LatLng? _currentLocation;
  LatLng? _destination;
  List<LatLng> _route = [];

  static const LatLng tceMainGate = LatLng(9.8856057, 78.0792341);
  static const LatLng tceBackGate = LatLng(9.8815505, 78.0835262);
  static const double tceMinLat = 9.8815505;
  static const double tceMaxLat = 9.8856057;
  static const double tceMinLon = 78.0792341;
  static const double tceMaxLon = 78.0835262;

  final Map<String, LatLng> tceLocations = {
    'Main Gate': tceMainGate,
    'Back Gate': tceBackGate,
    'Library': LatLng(9.8828636, 78.0813346),
    'CSE Department': LatLng(9.8827853, 78.0837391),
    'ECE Department': LatLng(9.8828305, 78.0827020),
    'Mechanical Department': LatLng(9.8823177, 78.0813295),
    'Civil Department': LatLng(9.8822372, 78.0828511),
    'Auditorium': LatLng(9.8826191, 78.0821901),
    'Cafeteria': LatLng(9.8833921, 78.0832190),
    'Hostel': LatLng(9.8852718, 78.0798636),
    'Sports Complex': LatLng(9.8873816, 78.0810274),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds(
            LatLng(tceMinLat, tceMinLon),
            LatLng(tceMaxLat, tceMaxLon),
          ),
          padding: EdgeInsets.all(40),
        ),
      );
    });
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    if (!await _checkPermissions()) return;
    _location.onLocationChanged.listen((LocationData locationData) {
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation =
              LatLng(locationData.latitude!, locationData.longitude!);
          isLoading = false;
        });
      }
    });
  }

  Future<void> fetchCoordinatesPoint(String location) async {
    if (tceLocations.containsKey(location)) {
      setState(() {
        _destination = tceLocations[location];
      });
      await fetchRoute();
      return;
    }

    final url = Uri.parse(
        "https://nominatim.openstreetmap.org/search?q=$location&format=json&limit=1");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        if (lat >= tceMinLat && lat <= tceMaxLat &&
            lon >= tceMinLon && lon <= tceMaxLon) {
          setState(() {
            _destination = LatLng(lat, lon);
          });
          await fetchRoute();
        } else {
          errorMessage('Location is outside TCE campus.');
        }
      } else {
        errorMessage('Location not found.');
      }
    } else {
      errorMessage('Failed to fetch location.');
    }
  }

  void decodePolyline(String encodedPolyline) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> decodedPoints =
        polylinePoints.decodePolyline(encodedPolyline);
    setState(() {
      _route = decodedPoints
          .map((point) => LatLng(point.latitude, point.longitude))
          .toList();
    });
  }

  Future<void> fetchRoute() async {
    if (_currentLocation == null || _destination == null) {
      errorMessage('Current location or destination not available');
      return;
    }

    if (!_isWithinTCE(_currentLocation!) || !_isWithinTCE(_destination!)) {
      errorMessage('Navigation only allowed within TCE campus.');
      return;
    }

    try {
      final url = Uri.parse(
        "http://router.project-osrm.org/route/v1/driving/"
        "${_currentLocation!.longitude},${_currentLocation!.latitude};"
        "${_destination!.longitude},${_destination!.latitude}"
        "?overview=full&geometries=polyline"
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          decodePolyline(geometry);
        } else {
          errorMessage('No route found.');
        }
      } else {
        errorMessage('Failed to fetch route.');
      }
    } catch (e) {
      errorMessage('Error fetching route: $e');
    }
  }

  bool _isWithinTCE(LatLng point) {
    return point.latitude >= tceMinLat &&
        point.latitude <= tceMaxLat &&
        point.longitude >= tceMinLon &&
        point.longitude <= tceMaxLon;
  }

  Future<bool> _checkPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return false;
    }
    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _userCurrentLocation() async {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 18);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Current Location not available")),
      );
    }
  }

  void errorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: tceMainGate,
              initialZoom: 16,
              minZoom: 15,
              maxZoom: 20,
            ),
            children: [
              TileLayer(
                urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              ),
              CurrentLocationLayer(
                style: LocationMarkerStyle(
                  marker: const DefaultLocationMarker(
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.white,
                    ),
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
                      width: 50,
                      height: 50,
                      child: const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              if (_currentLocation != null &&
                  _destination != null &&
                  _route.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _route,
                      strokeWidth: 5,
                      color: Colors.red,
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 10,
            right: 10,
            left: 10,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      hintText: 'Enter TCE location (e.g., Library)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'search',
                  onPressed: () {
                    fetchCoordinatesPoint(_locationController.text.trim());
                  },
                  mini: true,
                  child: const Icon(Icons.search),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  heroTag: 'currentLocation',
                  onPressed: _userCurrentLocation,
                  mini: true,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
