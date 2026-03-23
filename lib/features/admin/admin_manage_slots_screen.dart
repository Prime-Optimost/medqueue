// Admin Manage Slots Screen
// Slot management interface for doctors' availability scheduling
// Allows admins to create, modify, and delete appointment slots

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/widgets/error_snackbar.dart';
import '../../core/widgets/loading_button.dart';
import '../../services/admin_service.dart';

class AdminManageSlotsScreen extends StatefulWidget {
  static const routeName = AppConstants.manageSlotsRoute;
  const AdminManageSlotsScreen({super.key});

  @override
  State<AdminManageSlotsScreen> createState() => _AdminManageSlotsScreenState();
}

class _AdminManageSlotsScreenState extends State<AdminManageSlotsScreen> {
  List<DoctorSlot> _doctorSlots = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _doctorController = TextEditingController();
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _maxPatientsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  @override
  void dispose() {
    _doctorController.dispose();
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _maxPatientsController.dispose();
    super.dispose();
  }

  Future<void> _loadSlots() async {
    setState(() => _isLoading = true);

    try {
      final slots = await context.read<AdminService>().getDoctorSlots();
      setState(() {
        _doctorSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ErrorSnackbar.show(context, 'Failed to load slots: $e');
    }
  }

  Future<void> _addSlot() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final slot = DoctorSlot(
        id: 0, // Will be assigned by backend
        doctorId: int.parse(_doctorController.text),
        date: DateTime.parse(_dateController.text),
        startTime: _startTimeController.text,
        endTime: _endTimeController.text,
        maxPatients: int.parse(_maxPatientsController.text),
        availableSlots: int.parse(_maxPatientsController.text),
      );

      await context.read<AdminService>().createSlot(slot);
      _clearForm();
      _loadSlots();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.show(context, 'Failed to create slot: $e');
    }
  }

  Future<void> _deleteSlot(int slotId) async {
    try {
      await context.read<AdminService>().deleteSlot(slotId);
      _loadSlots();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Slot deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ErrorSnackbar.show(context, 'Failed to delete slot: $e');
    }
  }

  void _clearForm() {
    _doctorController.clear();
    _dateController.clear();
    _startTimeController.clear();
    _endTimeController.clear();
    _maxPatientsController.clear();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      _dateController.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _selectTime(TextEditingController controller) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      controller.text = picked.format(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Doctor Slots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSlots,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSlots,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Add New Slot Form
                    _buildAddSlotForm(),

                    const SizedBox(height: 24),

                    // Existing Slots List
                    _buildSlotsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAddSlotForm() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Slot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Doctor ID
              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: 'Doctor ID',
                  hintText: 'Enter doctor ID',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter doctor ID';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Date
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'Select date',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a date';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Start Time
              TextFormField(
                controller: _startTimeController,
                decoration: InputDecoration(
                  labelText: 'Start Time',
                  hintText: 'Select start time',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selectTime(_startTimeController),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select start time';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // End Time
              TextFormField(
                controller: _endTimeController,
                decoration: InputDecoration(
                  labelText: 'End Time',
                  hintText: 'Select end time',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () => _selectTime(_endTimeController),
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select end time';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Max Patients
              TextFormField(
                controller: _maxPatientsController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Patients',
                  hintText: 'Enter max patients per slot',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter maximum patients';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid number greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Add Button
              SizedBox(
                width: double.infinity,
                child: LoadingButton(
                  onPressed: _addSlot,
                  text: 'Add Slot',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotsList() {
    if (_doctorSlots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No slots available'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Existing Slots',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        ..._doctorSlots.map((slot) => Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Doctor ID: ${slot.doctorId}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(slot.id),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      slot.date.toLocal().toString().split(' ')[0],
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${slot.startTime} - ${slot.endTime}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Max Patients: ${slot.maxPatients}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Available: ${slot.availableSlots}',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: slot.availableSlots > 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _showDeleteConfirmation(int slotId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Slot'),
        content: const Text('Are you sure you want to delete this slot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSlot(slotId);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// Comments for academic documentation:
// - AdminManageSlotsScreen: Complete slot management for doctor scheduling
// - Form-based slot creation with validation
// - CRUD operations for slot management
// - Date/time picker integration
// - Confirmation dialogs for destructive actions
// - Real-time availability tracking
// - Data structured for backend integration