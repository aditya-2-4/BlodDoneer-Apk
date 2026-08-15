import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mediverse_app/providers/auth_provider.dart';
import 'package:mediverse_app/providers/app_provider.dart';
import 'package:mediverse_app/widgets/toast_banner.dart';

// Import target screens
import 'package:mediverse_app/screens/doctor_search/doctor_list_screen.dart';
import 'package:mediverse_app/screens/donor_search/donor_map_screen.dart';
import 'package:mediverse_app/screens/appointments/my_appointments_screen.dart';
import 'package:mediverse_app/screens/profile/profile_screen.dart';
import 'package:mediverse_app/screens/admin/admin_panel_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Pre-fetch basic schedules and slots on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appProv = Provider.of<AppProvider>(context, listen: false);
      appProv.fetchAppointments();
      
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser?.role == 'donor') {
        appProv.fetchNearbySOSRequests();
      }
    });
  }

  // Floating Emergency SOS triggers hospitals & donors overlay search
  void _triggerEmergencySOS(BuildContext context, Map<String, double> userCoords) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DonorMapScreen(
          initialSosTrigger: true,
          userCoords: userCoords,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final appProv = Provider.of<AppProvider>(context);
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Monitor for new mock notifications and drop down the toast overlay
    if (appProv.mockNotifications.isNotEmpty) {
      final latest = appProv.mockNotifications.first;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationOverlay.show(context, latest['title']!, latest['message']!);
        appProv.clearNotifications(); // Reset overlay queue
      });
    }

    // Role-based screens selection
    List<Widget> screens = [];
    List<BottomNavigationBarItem> navItems = [];

    if (user.role == 'patient') {
      screens = [
        _buildPatientOverview(context, user),
        const DoctorListScreen(),
        DonorMapScreen(userCoords: {'lat': user.lat, 'lng': user.lng}),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Overview"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Doctors"),
        BottomNavigationBarItem(icon: Icon(Icons.water_drop, color: Colors.red), label: "Donors"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ];
    } else if (user.role == 'doctor') {
      screens = [
        _buildDoctorOverview(context, user),
        _buildDoctorSlotsManager(context, user),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: "Schedules"),
        BottomNavigationBarItem(icon: Icon(Icons.lock_clock), label: "Active Slots"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ];
    } else if (user.role == 'donor') {
      screens = [
        _buildDonorOverview(context, user),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.broadcast_on_personal), label: "Alerts"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ];
    } else if (user.role == 'admin') {
      screens = [
        const AdminPanelScreen(),
        const ProfileScreen(),
      ];
      navItems = const [
        BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: "Admin panel"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const Icon(Icons.healing, color: Color(0xFFDC2626), size: 24),
            const SizedBox(width: 8),
            Text(
              "MediVerse",
              style: TextStyle(
                color: Colors.teal.shade800,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            Chip(
              backgroundColor: Colors.teal.shade50,
              label: Text(
                user.role.toUpperCase(),
                style: TextStyle(color: Colors.teal.shade900, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
      body: screens.isNotEmpty ? screens[_currentIndex] : const SizedBox.shrink(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF0F766E), // Teal active item
        unselectedItemColor: Colors.slate.shade400,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        onTap: (idx) {
          setState(() => _currentIndex = idx);
        },
        items: navItems,
      ),
      
      // Floating emergency button visible to patient role
      floatingActionButton: user.role == 'patient'
          ? FloatingActionButton.extended(
              onPressed: () => _triggerEmergencySOS(context, {"lat": user.lat, "lng": user.lng}),
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text("SOS EMERGENCY", style: TextStyle(fontWeight: FontWeight.bold)),
              elevation: 8,
            )
          : null,
    );
  }

  /* ========================================================================= */
  /* PATIENT OVERVIEW SCREEN                                                   */
  /* ========================================================================= */
  Widget _buildPatientOverview(BuildContext context, UserModel user) {
    final appProv = Provider.of<AppProvider>(context);
    final patientAppts = appProv.appointments.where((a) => a.patientId == user.id).toList();

    return RefreshIndicator(
      onRefresh: () => appProv.fetchAppointments(),
      color: const Color(0xFF0F766E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome header
              Text(
                "Welcome, ${user.name}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text("MediVerse Smart Patient Dashboard", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),

              // Overview Widgets Cards
              Row(
                children: [
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Scheduled Visits", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            const SizedBox(height: 6),
                            Text(
                              "${patientAppts.length}",
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      color: Colors.white,
                      elevation: 0.5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Mock GPS Coords", style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                            const SizedBox(height: 6),
                            Text(
                              "${user.lat.toStringAsFixed(3)}, ${user.lng.toStringAsFixed(3)}",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Appointments Scheduler List
              const Row(
                children: [
                  Icon(Icons.event_note, color: Color(0xFF0F766E), size: 20),
                  SizedBox(width: 8),
                  Text("Your Clinic Bookings", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              patientAppts.isEmpty
                  ? Card(
                      color: Colors.white,
                      elevation: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text("No appointments scheduled", style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => setState(() => _currentIndex = 1),
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
                              child: const Text("Book Now"),
                            )
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: patientAppts.length,
                      itemBuilder: (context, index) {
                        final appt = patientAppts[index];
                        
                        Color statusColor = Colors.orange;
                        if (appt.status == 'confirmed') statusColor = Colors.green;
                        if (appt.status == 'cancelled') statusColor = Colors.red;

                        return Card(
                          color: Colors.white,
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            title: Text(
                              appt.doctorName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${appt.specialization} | ${appt.hospitalName}", style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Text(
                                  "Reason: ${appt.reason}",
                                  style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Schedule: ${appt.date} at ${appt.time}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                appt.status.toUpperCase(),
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 70), // Padding below FAB
            ],
          ),
        ),
      ),
    );
  }

  /* ========================================================================= */
  /* DOCTOR OVERVIEW SCREEN                                                    */
  /* ========================================================================= */
  Widget _buildDoctorOverview(BuildContext context, UserModel user) {
    final appProv = Provider.of<AppProvider>(context);
    final doctorAppts = appProv.appointments.where((a) => a.doctorId == user.id).toList();

    return RefreshIndicator(
      onRefresh: () => appProv.fetchAppointments(),
      color: const Color(0xFF0F766E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Welcome, ${user.name}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text("Clinic Bookings Manager Panel", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),

              const Row(
                children: [
                  Icon(Icons.assignment, color: Color(0xFF0F766E), size: 20),
                  SizedBox(width: 8),
                  Text("Patient Appointment Logs", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),

              doctorAppts.isEmpty
                  ? Card(
                      color: Colors.white,
                      elevation: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          children: [
                            Icon(Icons.assignment_turned_in, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text("No booking requests registered", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: doctorAppts.length,
                      itemBuilder: (context, index) {
                        final appt = doctorAppts[index];

                        Color statusColor = Colors.orange;
                        if (appt.status == 'confirmed') statusColor = Colors.green;
                        if (appt.status == 'cancelled') statusColor = Colors.red;

                        return Card(
                          color: Colors.white,
                          elevation: 0.5,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.between,
                                  children: [
                                    Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        appt.status.toUpperCase(),
                                        style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text("Contact: ${appt.patientPhone} | ${appt.patientEmail}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text("Proposed Date: ${appt.date} at ${appt.time}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey.shade200),
                                  ),
                                  child: Text(
                                    "Symptoms: ${appt.reason}",
                                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ),
                                
                                // Booking Action Controls
                                if (appt.status == 'pending') ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      OutlinedButton(
                                        onPressed: () => appProv.updateAppointmentStatus(appt.id, 'cancelled'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                        ),
                                        child: const Text("Decline"),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () => appProv.updateAppointmentStatus(appt.id, 'confirmed'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF0F766E),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("Accept Booking"),
                                      ),
                                    ],
                                  )
                                ]
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  /* ========================================================================= */
  /* DOCTOR SLOTS CHECKBOX MANAGER                                             */
  /* ========================================================================= */
  Widget _buildDoctorSlotsManager(BuildContext context, UserModel user) {
    final appProv = Provider.of<AppProvider>(context);
    final allSlots = [
      "08:00 AM", "08:30 AM", "09:00 AM", "09:30 AM",
      "10:00 AM", "10:30 AM", "11:00 AM", "11:30 AM",
      "01:00 PM", "01:30 PM", "02:00 PM", "02:30 PM",
      "03:00 PM", "03:30 PM", "04:00 PM", "04:30 PM",
      "05:00 PM", "05:30 PM"
    ];

    // Mock slots setup (for static demo fallback if profile data is empty)
    final activeSlots = ["09:00 AM", "10:30 AM", "02:00 PM", "04:30 PM"];

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Configure Available Slots",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text("Check the calendar hour cells you want patients to request.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allSlots.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final slot = allSlots[index];
                final isChecked = activeSlots.contains(slot);

                return Container(
                  decoration: BoxDecoration(
                    color: isChecked ? const Color(0xFF0F766E).withOpacity(0.08) : Colors.white,
                    border: Border.all(color: isChecked ? const Color(0xFF0F766E) : Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CheckboxListTile(
                    value: isChecked,
                    title: Text(slot, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    selected: isChecked,
                    activeColor: const Color(0xFF0F766E),
                    onChanged: (val) {
                      // Trigger update slots endpoint (simulated UI toggle)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Schedule updated.")),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Availability hours saved to registry.")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Save Schedule Configuration", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  /* ========================================================================= */
  /* DONOR OVERVIEW SCREEN                                                     */
  /* ========================================================================= */
  Widget _buildDonorOverview(BuildContext context, UserModel user) {
    final appProv = Provider.of<AppProvider>(context);
    final sosAlerts = appProv.sosRequests;

    return RefreshIndicator(
      onRefresh: () => appProv.fetchNearbySOSRequests(),
      color: const Color(0xFF0F766E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Donor Alert Desk",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade900),
              ),
              const SizedBox(height: 4),
              const Text("Urgent broadcasts matching your location and blood type", style: TextStyle(color: Colors.grey, fontSize: 13)),
              const SizedBox(height: 20),

              sosAlerts.isEmpty
                  ? Card(
                      color: Colors.white,
                      elevation: 0.5,
                      child: Padding(
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          children: [
                            const Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            const Text(
                              "No matching emergency broadcasts.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 4),
                            Text("You will receive push notifications if a patient SOS is published within 15 km.", style: TextStyle(color: Colors.grey.shade400, fontSize: 11), textAlign: TextAlign.center)
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sosAlerts.length,
                      itemBuilder: (context, index) {
                        final req = sosAlerts[index];
                        final name = req['requester_name'] ?? 'Patient';
                        final distance = req['distance'] ?? '1.2';
                        final phone = req['requester_phone'] ?? '';

                        return Card(
                          color: const Color(0xFFFEF2F2), // Accent Crimson Soft
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.warning, color: Color(0xFFDC2626), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      "CRITICAL BLOOD SOS: ${req['blood_group']}",
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF991B1B), fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Patient $name needs blood immediately at coordinates location.",
                                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Distance: $distance km away | Urgency: ${req['urgency']?.toUpperCase()}",
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.phone),
                                  label: Text("Contact Requester ($phone)"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFDC2626),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
