import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mediverse_app/providers/auth_provider.dart';
import 'package:mediverse_app/services/location_service.dart';
import 'package:mediverse_app/screens/home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  // Doctor properties
  final _qualificationsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _licenseController = TextEditingController();
  final _feeController = TextEditingController();
  final _bioController = TextEditingController();

  String _selectedRole = 'patient';
  String _selectedBloodGroup = 'O+';
  String _selectedSpecialization = 'General Physician';
  String _lastDonatedDate = '';
  
  Map<String, double> _currentCoords = {"lat": 12.9716, "lng": 77.5946};
  bool _detectingLocation = false;

  @override
  void initState() {
    super.initState();
    _detectLocation();
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    final coords = await LocationService.getCurrentCoordinates();
    setState(() {
      _currentCoords = coords;
      _detectingLocation = false;
    });
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    final success = await auth.register(
      role: _selectedRole,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      phone: _phoneController.text.trim(),
      location: _currentCoords,
      bloodGroup: _selectedRole == 'donor' ? _selectedBloodGroup : null,
      specialization: _selectedRole == 'doctor' ? _selectedSpecialization : null,
      qualifications: _selectedRole == 'doctor' ? _qualificationsController.text.trim() : null,
      experience: _selectedRole == 'doctor' ? int.tryParse(_experienceController.text) : null,
      bio: _selectedRole == 'doctor' ? _bioController.text.trim() : null,
    );

    if (success && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? "Registration failed."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F766E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Role Picker Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: "Select Account Role",
                    prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF0F766E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'patient', child: Text("Patient / General User")),
                    DropdownMenuItem(value: 'donor', child: Text("Emergency Blood Donor")),
                    DropdownMenuItem(value: 'doctor', child: Text("Medical Practitioner / Doctor")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
                const SizedBox(height: 20),

                // Standard Info Fields
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF0F766E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Name is required" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF0F766E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || !val.contains('@') ? "Enter a valid email" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Secure Password",
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF0F766E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.length < 6 ? "Min 6 characters required" : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Contact Number",
                    prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF0F766E)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Phone is required" : null,
                ),
                const SizedBox(height: 20),

                // Donor Dynamic Form Content
                if (_selectedRole == 'donor') ...[
                  const Text("Donor Profile Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedBloodGroup,
                    decoration: InputDecoration(
                      labelText: "Blood Group",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'].map((bg) {
                      return DropdownMenuItem(value: bg, child: Text(bg));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBloodGroup = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Last Donated Date (Optional)",
                      hintText: _lastDonatedDate.isEmpty ? "YYYY-MM-DD" : _lastDonatedDate,
                      prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF0F766E)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() {
                          _lastDonatedDate = picked.toString().split(" ")[0];
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Doctor Dynamic Form Content
                if (_selectedRole == 'doctor') ...[
                  const Text("Clinical Practitioner Registry Settings", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialization,
                    decoration: InputDecoration(
                      labelText: "Practice Specialization",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ['Cardiologist', 'Orthopedist', 'Neurologist', 'Gynecologist', 'General Physician'].map((spec) {
                      return DropdownMenuItem(value: spec, child: Text(spec));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedSpecialization = val);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _qualificationsController,
                    decoration: InputDecoration(
                      labelText: "Medical Qualifications",
                      hintText: "e.g., MD, DM (Cardiology)",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Enter your degrees" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _experienceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Years of Active Practice",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || int.tryParse(val) == null ? "Enter a valid number" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _licenseController,
                    decoration: InputDecoration(
                      labelText: "Professional Registry License ID",
                      hintText: "MCI-78912-CARD",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Registry ID is required" : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _feeController,
                    decoration: InputDecoration(
                      labelText: "Consultation Fee Label",
                      hintText: "\$40",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _bioController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: "Short Professional Biography",
                      hintText: "Describe your clinical profile...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Location detection indicator
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.my_location, color: Color(0xFF0F766E)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "GPS Location Detected:\nLat ${_currentCoords['lat']?.toStringAsFixed(4)}, Lng ${_currentCoords['lng']?.toStringAsFixed(4)}",
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      _detectingLocation
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : IconButton(
                              icon: const Icon(Icons.refresh, color: Color(0xFF0F766E)),
                              onPressed: _detectLocation,
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                auth.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
                    : ElevatedButton(
                        onPressed: _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Register Account", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
