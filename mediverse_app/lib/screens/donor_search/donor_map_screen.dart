import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:mediverse_app/providers/app_provider.dart';

class DonorMapScreen extends StatefulWidget {
  final Map<String, double> userCoords;
  final bool initialSosTrigger;

  const DonorMapScreen({
    super.key,
    required this.userCoords,
    this.initialSosTrigger = false,
  });

  @override
  State<DonorMapScreen> createState() => _DonorMapScreenState();
}

class _DonorMapScreenState extends State<DonorMapScreen> {
  final MapController _mapController = MapController();
  
  String _selectedBloodGroup = 'All';
  double _selectedRadius = 10.0;
  bool _sosModeActive = false;

  @override
  void initState() {
    super.initState();
    _sosModeActive = widget.initialSosTrigger;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerSearch();
    });
  }

  void _triggerSearch() {
    final appProv = Provider.of<AppProvider>(context, listen: false);
    final lat = widget.userCoords['lat']!;
    final lng = widget.userCoords['lng']!;
    
    if (_sosModeActive) {
      // Map both hospitals and matching donors immediately
      appProv.fetchHospitals(lat: lat, lng: lng, radius: 15.0);
      appProv.fetchDonors(bloodGroup: 'All', lat: lat, lng: lng, radius: 15.0);
    } else {
      appProv.fetchDonors(
        bloodGroup: _selectedBloodGroup,
        lat: lat,
        lng: lng,
        radius: _selectedRadius,
      );
    }
  }

  void _publishEmergencySOS() async {
    final appProv = Provider.of<AppProvider>(context, listen: false);
    final success = await appProv.requestBloodSOS(
      bloodGroup: _selectedBloodGroup == 'All' ? 'O+' : _selectedBloodGroup,
      urgency: 'critical',
      location: widget.userCoords,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency SOS Broadcast successfully sent!"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProv = Provider.of<AppProvider>(context);
    final userLatLng = LatLng(widget.userCoords['lat']!, widget.userCoords['lng']!);

    // Build markers list
    List<Marker> markers = [];
    
    // 1. User Position Marker
    markers.add(
      Marker(
        point: userLatLng,
        width: 60,
        height: 60,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
          ),
          child: const Center(
            child: Icon(Icons.my_location, color: Colors.blue, size: 24),
          ),
        ),
      ),
    );

    // 2. Plot Donors (Red Drops)
    for (var donor in appProv.donors) {
      markers.add(
        Marker(
          point: LatLng(donor.lat, donor.lng),
          width: 45,
          height: 45,
          child: GestureDetector(
            onTap: () => _showDetailsSheet(donor.name, "Blood Group: ${donor.bloodGroup}", donor.phone, true),
            child: const Icon(Icons.water_drop, color: Colors.red, size: 38),
          ),
        ),
      );
    }

    // 3. Plot Hospitals (Green Crosses) if SOS mode is active
    if (_sosModeActive) {
      for (var hosp in appProv.hospitals) {
        markers.add(
          Marker(
            point: LatLng(hosp.lat, hosp.lng),
            width: 45,
            height: 45,
            child: GestureDetector(
              onTap: () => _showDetailsSheet(hosp.name, "Trauma/Emergency Care", hosp.contact, false),
              child: const Icon(Icons.local_hospital, color: Colors.green, size: 38),
            ),
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sosModeActive ? "Emergency SOS Map" : "Blood Donor GPS Finder",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _sosModeActive ? Colors.red : const Color(0xFF0F766E),
        elevation: 0.5,
        actions: [
          // SOS toggle button
          IconButton(
            icon: Icon(
              _sosModeActive ? Icons.health_and_safety : Icons.health_and_safety_outlined,
              color: Colors.red,
            ),
            onPressed: () {
              setState(() {
                _sosModeActive = !_sosModeActive;
              });
              _triggerSearch();
            },
          )
        ],
      ),
      body: Stack(
        children: [
          // Leaflet OSM Map Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: userLatLng,
              initialZoom: 13.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mediverse.app',
              ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Search Filters Card (Visible in Standard Donor Finder Mode)
          if (!_sosModeActive)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  child: Row(
                    children: [
                      // Blood Group Dropdown
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedBloodGroup,
                            items: ['All', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((bg) {
                              return DropdownMenuItem(value: bg, child: Text("Group: $bg"));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBloodGroup = val);
                                _triggerSearch();
                              }
                            },
                          ),
                        ),
                      ),
                      const VerticalDivider(width: 20, thickness: 1),
                      // Radius Slider
                      Expanded(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: _selectedRadius,
                            items: [5.0, 10.0, 25.0, 50.0].map((r) {
                              return DropdownMenuItem(value: r, child: Text("Radius: ${r.toInt()}km"));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedRadius = val);
                                _triggerSearch();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // SOS Command Card (Visible in Emergency SOS Mode)
          if (_sosModeActive)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                color: const Color(0xFFFEF2F2),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emergency_share, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Emergency Broadcast Hub",
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Click below to send push alert commands to all matching blood donors within 15 km.",
                        style: TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _publishEmergencySOS,
                        icon: const Icon(Icons.broadcast_on_home),
                        label: const Text("BROADCAST SOS ALERT"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading overlay
          if (appProv.isLoading)
            const Center(
              child: Card(
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(color: Color(0xFF0F766E)),
                ),
              ),
            )
        ],
      ),
    );
  }

  // Show Bottom sheet containing one-tap contact dialers
  void _showDetailsSheet(String name, String sub, String phone, bool isDonor) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    isDonor ? Icons.water_drop : Icons.local_hospital,
                    color: isDonor ? Colors.red : Colors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          sub,
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "Phone/Emergency Contact: $phone",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Simulating calling $name... ($phone)")),
                  );
                },
                icon: const Icon(Icons.phone),
                label: const Text("Dial Contact Number"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDonor ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
