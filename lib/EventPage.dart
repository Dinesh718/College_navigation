import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:loginui/event.dart';

class EventsMapPage extends StatefulWidget {
  const EventsMapPage({super.key});

  @override
  State<EventsMapPage> createState() => _EventsMapPageState();
}

class _EventsMapPageState extends State<EventsMapPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final MapController _mapController = MapController();
  LatLng? _selectedEventLocation;
  Map<String, dynamic>? _selectedEventDetails;
  bool _showAllEvents = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Events Map'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 10,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(_showAllEvents ? Icons.filter_alt : Icons.filter_alt_off),
            onPressed: () {
              setState(() {
                _showAllEvents = !_showAllEvents;
              });
            },
            tooltip: _showAllEvents ? 'Show only upcoming' : 'Show all events',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to another page (e.g., a new page for event details or a form)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventPage()), // Replace `OtherPage()` with the actual page widget
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white), // Plus icon to represent adding
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(9.8856057, 78.0792341),
              initialZoom: 15,
              onTap: (_, __) {
                setState(() {
                  _selectedEventLocation = null;
                  _selectedEventDetails = null;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.events_map',
              ),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('events').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const MarkerLayer(markers: []);
                  }

                  final now = DateTime.now();
                  final events = snapshot.data!.docs.where((doc) {
                    if (_showAllEvents) return true;
                    final event = doc.data() as Map<String, dynamic>;
                    if (event['date'] == null) return false;
                    final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']);
                    return eventDate.isAfter(now) || 
                           eventDate.isAtSameMomentAs(now);
                  }).toList();

                  return MarkerLayer(
                    markers: events.map((doc) {
                      final event = doc.data() as Map<String, dynamic>;
                      final geoPoint = event['location'] as GeoPoint;
                      final location = LatLng(geoPoint.latitude, geoPoint.longitude);
                      final isSelected = _selectedEventLocation == location;
                      final isPast = event['date'] != null && 
                          DateFormat('yyyy-MM-dd').parse(event['date']).isBefore(now);

                      return Marker(
                        point: location,
                        width: isSelected ? 60 : 50,
                        height: isSelected ? 60 : 50,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedEventLocation = location;
                              _selectedEventDetails = event;
                            });
                            _mapController.move(location, _mapController.camera.zoom);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue : 
                                    isPast ? Colors.grey : Colors.redAccent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isSelected ? Icons.star : Icons.event,
                                color: Colors.white,
                                size: isSelected ? 30 : 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
          if (_selectedEventDetails != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: EventDetailsCard(
                event: _selectedEventDetails!,
                onClose: () {
                  setState(() {
                    _selectedEventLocation = null;
                    _selectedEventDetails = null;
                  });
                },
              ),
            ),
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Text(
                'Tap on markers for details',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventDetailsCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback onClose;

  const EventDetailsCard({
    super.key,
    required this.event,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isPast = event['date'] != null && 
        DateFormat('yyyy-MM-dd').parse(event['date']).isBefore(now);

    return Card(
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isPast ? Colors.grey.shade300 : Colors.blue.shade100,
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        event['name'] ?? 'Untitled Event',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isPast ? Colors.grey.shade700 : Colors.blue,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: onClose,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (event['description'] != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      event['description'],
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ),
                const Divider(height: 20, thickness: 1),
                if (event['date'] != null)
                  _buildDetailRow(
                    Icons.calendar_today,
                    DateFormat('EEE, MMM d, y').format(
                      DateFormat('yyyy-MM-dd').parse(event['date']),
                    ),
                    isPast ? Colors.grey : Colors.blue,
                  ),
                if (event['location'] != null)
                  _buildDetailRow(
                    Icons.location_on,
                    '${(event['location'] as GeoPoint).latitude.toStringAsFixed(6)}, '
                        '${(event['location'] as GeoPoint).longitude.toStringAsFixed(6)}',
                    Colors.redAccent,
                  ),
                const SizedBox(height: 8),
                if (isPast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'PAST EVENT',
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}