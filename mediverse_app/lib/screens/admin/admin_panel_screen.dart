import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mediverse_app/providers/app_provider.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _qualsController = TextEditingController();
  final _expController = TextEditingController();

  String _selectedSpec = 'Cardiologist';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppProvider>(context, listen: false).fetchNearbySOSRequests();
    });
  }

  // Admin registers doctor profile
  void _submitRegisterDoctor() async {
    if (!_formKey.currentState!.validate()) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Doctor ${_nameController.text} Registered. Password: 'password123'")),
    );
    
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _qualsController.clear();
    _expController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appProv = Provider.of<AppProvider>(context);
    final sosRequests = appProv.sosRequests;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Hospital Administrator Panel", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Role stats metrics card widgets
          Row(
            children: [
              Expanded(
                child: _buildMetricCard("Active SOS", "${sosRequests.length}", Colors.red),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard("Appointments", "${appProv.appointments.length}", Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // FL_Chart Doughnut Representation
          const Text("Registry Distributions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          
          Card(
            color: Colors.white,
            elevation: 0.5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 160,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(color: Colors.teal, value: 35, title: 'Doctors', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          PieChartSectionData(color: Colors.red, value: 40, title: 'Donors', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                          PieChartSectionData(color: Colors.blue, value: 25, title: 'Patients', radius: 40, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle, color: Colors.teal, size: 12),
                      SizedBox(width: 4),
                      Text("Doctors (35%)", style: TextStyle(fontSize: 11)),
                      SizedBox(width: 12),
                      Icon(Icons.circle, color: Colors.red, size: 12),
                      SizedBox(width: 4),
                      Text("Donors (40%)", style: TextStyle(fontSize: 11)),
                      SizedBox(width: 12),
                      Icon(Icons.circle, color: Colors.blue, size: 12),
                      SizedBox(width: 4),
                      Text("Patients (25%)", style: TextStyle(fontSize: 11)),
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Manage Doctors Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text("Manage Staff Doctors", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              TextButton.icon(
                onPressed: () => _showAddDoctorDialog(),
                icon: const Icon(Icons.add, color: Color(0xFF0F766E)),
                label: const Text("Register Staff", style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),

          // SOS blood request tables manager
          const Text("Emergency SOS Broadcasts Log", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),

          sosRequests.isEmpty
              ? const Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text("No emergency requests in queue.", style: TextStyle(color: Colors.grey))),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: sosRequests.length,
                  itemBuilder: (context, index) {
                    final req = sosRequests[index];
                    final requesterName = req['requester_name'] ?? 'Patient';
                    final status = req['status'] ?? 'open';
                    
                    return Card(
                      color: Colors.white,
                      elevation: 0.5,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                      child: ListTile(
                        title: Text("Blood Request: ${req['blood_group']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Requested by: $requesterName\nStatus: ${status.toUpperCase()}"),
                        trailing: status == 'open'
                            ? ElevatedButton(
                                onPressed: () async {
                                  await appProv.resolveBloodSOS(req['id'], 'fulfilled');
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text("Fulfill"),
                              )
                            : const Icon(Icons.check_circle, color: Colors.green),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, Color c) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.between,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                const SizedBox(height: 4),
                Text(val, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            Icon(Icons.query_stats, color: c, size: 28),
          ],
        ),
      ),
    );
  }

  void _showAddDoctorDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Register Staff Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: "Doctor Name (Dr. Jane Smith)"),
                    validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: "Email Account"),
                    validator: (val) => val == null || !val.contains('@') ? "Valid email is required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: "Phone Contact"),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedSpec,
                    decoration: const InputDecoration(labelText: "Specialization"),
                    items: ['Cardiologist', 'Orthopedist', 'Neurologist', 'Gynecologist', 'General Physician'].map((s) {
                      return DropdownMenuItem(value: s, child: Text(s));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSpec = val);
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _qualsController,
                    decoration: const InputDecoration(labelText: "Degrees (MBBS, MD)"),
                    validator: (val) => val == null || val.isEmpty ? "Degrees are required" : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expController,
                    decoration: const InputDecoration(labelText: "Experience (Years)"),
                    keyboardType: TextInputType.number,
                    validator: (val) => val == null || int.tryParse(val) == null ? "Enter valid number" : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: _submitRegisterDoctor,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F766E), foregroundColor: Colors.white),
              child: const Text("Register"),
            ),
          ],
        );
      },
    );
  }
}
