import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/doctor_model.dart';
import '../../services/appointment_service.dart';
import '../../features/auth/auth_provider.dart';

class BookAppointmentScreen extends StatefulWidget {
  static const routeName = '/book-appointment';
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final AppointmentService _appointmentService = AppointmentService();
  final TextEditingController _reasonController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedTime;
  List<String> _availableSlots = [];
  bool _isLoadingSlots = false;
  bool _isBooking = false;

  DoctorModel? _doctor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _doctor = ModalRoute.of(context)!.settings.arguments as DoctorModel?;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _availableSlots = [];
      });
      _loadSlots();
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedDate == null || _doctor == null) return;
    setState(() => _isLoadingSlots = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      final dateStr = _selectedDate!.toIso8601String().split('T')[0];
      final slots = await _appointmentService.getSlots(token, _doctor!.id, dateStr);
      setState(() {
        _availableSlots = slots;
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDate == null || _selectedTime == null || _doctor == null) return;
    setState(() => _isBooking = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token != null) {
      final dateStr = _selectedDate!.toIso8601String().split('T')[0];
      final success = await _appointmentService.bookAppointment(
        token,
        _doctor!.id,
        dateStr,
        _selectedTime!,
        _reasonController.text.trim(),
      );
      setState(() => _isBooking = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Book with ${_doctor?.fullName ?? ''}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(_selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
            ),
            const SizedBox(height: 16),
            if (_isLoadingSlots) const CircularProgressIndicator(),
            if (_availableSlots.isNotEmpty)
              DropdownButtonFormField<String>(
                value: _selectedTime,
                decoration: const InputDecoration(labelText: 'Select Time Slot'),
                items: _availableSlots.map((slot) {
                  return DropdownMenuItem(value: slot, child: Text(slot));
                }).toList(),
                onChanged: (value) => setState(() => _selectedTime = value),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Reason for visit'),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: (_selectedDate != null && _selectedTime != null && !_isBooking)
                  ? _bookAppointment
                  : null,
              child: _isBooking
                  ? const CircularProgressIndicator()
                  : const Text('Confirm Booking'),
            ),
          ],
        ),
      ),
    );
  }
}
