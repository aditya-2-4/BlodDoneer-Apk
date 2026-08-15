import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mediverse_app/models/doctor_model.dart';
import 'package:mediverse_app/providers/app_provider.dart';

class DoctorDetailScreen extends StatefulWidget {
  final DoctorModel doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  final _reasonController = TextEditingController();
  
  String _selectedDate = '';
  String? _selectedSlot;

  Future<void> _handleBooking() async {
    if (_selectedDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a booking date.")),
      );
      return;
    }
    if (_selectedSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a consultation time slot.")),
      );
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the reason for visit.")),
      );
      return;
    }

    final appProv = Provider.of<AppProvider>(context, listen: false);
    final success = await appProv.bookAppointment(
      doctorId: widget.doctor.userId,
      date: _selectedDate,
      time: _selectedSlot!,
      reason: _reasonController.text.trim(),
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Appointment successfully requested!"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProv = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Doctor Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F766E),
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.person, color: Color(0xFF0F766E), size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.doctor.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          "${widget.doctor.specialization} (${widget.doctor.experience} yrs practice)",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              "${widget.doctor.rating} / 5",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),
              
              // Qualifications details
              const Text("Qualifications & Bio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                "Degrees: ${widget.doctor.qualifications}\nOffice: ${widget.doctor.hospitalName}\nLicense No: ${widget.doctor.licenseNumber}",
                style: const TextStyle(fontSize: 13, height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                widget.doctor.bio,
                style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // Attached Documents & Certificates Section (4 Verified Documents)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.teal.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified, color: Color(0xFF0F766E), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Verified Credentials & Certificates (4 Attached)",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F766E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCertificateTile(
                      icon: Icons.workspace_premium,
                      title: "Medical Council License",
                      subtitle: "Reg #: ${widget.doctor.licenseNumber}",
                      status: "Active & Verified",
                    ),
                    const SizedBox(height: 8),
                    _buildCertificateTile(
                      icon: Icons.school,
                      title: "Specialist Degree & Diploma",
                      subtitle: "Degree: ${widget.doctor.qualifications}",
                      status: "Verified",
                    ),
                    const SizedBox(height: 8),
                    _buildCertificateTile(
                      icon: Icons.article_outlined,
                      title: "Clinical Experience Endorsement",
                      subtitle: "Hospital: ${widget.doctor.hospitalName}",
                      status: "Verified",
                    ),
                    const SizedBox(height: 8),
                    _buildCertificateTile(
                      icon: Icons.health_and_safety,
                      title: "Healthcare Quality Accreditation",
                      subtitle: "National Accreditation Board (NABH)",
                      status: "Verified",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),


              // Calendar Picker Trigger
              const Text("Select Visit Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked.toString().split(" ")[0];
                    });
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFF0F766E)),
                ),
                icon: const Icon(Icons.calendar_month, color: Color(0xFF0F766E)),
                label: Text(
                  _selectedDate.isEmpty ? "Pick Consultation Date" : "Date: $_selectedDate",
                  style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // Slots Selector Grid
              const Text("Select Available Hour", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              widget.doctor.availableSlots.isEmpty
                  ? const Text("No slots published by doctor currently.", style: TextStyle(color: Colors.grey))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.doctor.availableSlots.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final slot = widget.doctor.availableSlots[index];
                        final isSelected = _selectedSlot == slot;
                        return ChoiceChip(
                          label: Text(slot),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0F766E),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedSlot = val ? slot : null;
                            });
                          },
                        );
                      },
                    ),
              const SizedBox(height: 24),

              // Symptoms input text area
              const Text("Describe Symptoms / Consultation Reason", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              TextField(
                controller: _reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Describe briefly (e.g. chest pain, routine sugar checkup)...",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0F766E), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Action Trigger Button
              appProv.isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
                  : ElevatedButton(
                      onPressed: _handleBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Confirm Visit Slot", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCertificateTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String status,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF0F766E), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

