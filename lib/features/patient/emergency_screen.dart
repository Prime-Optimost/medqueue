// Emergency SOS Screen
// One-tap emergency response with GPS location and Google Maps
// Features: Large SOS button, location capture, confirmation dialog, map display

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../services/emergency_service.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  Position? _currentPosition;
  GoogleMapController? _mapController;
  bool _isLoading = false;
  String? _emergencyId;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      final position = await context.read<EmergencyService>().getCurrentLocation();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });

      // Move camera to current location
      if (_mapController != null && _currentPosition != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to get location: $e')),
      );
    }
  }

  Future<void> _triggerSOS() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location not available. Please wait.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await context.read<EmergencyService>().triggerSOS(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );

      setState(() {
        _emergencyId = result.emergencyId;
        _isLoading = false;
      });

      // Show confirmation dialog
      _showConfirmationDialog(result);

    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send SOS: $e')),
      );
    }
  }

  void _showConfirmationDialog(SOSEmergencyResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Emergency Services Notified'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Emergency services have been notified. Help is on the way.'),
            const SizedBox(height: 16),
            Text('Emergency ID: ${result.emergencyId}'),
            Text('Location: ${result.latitude.toStringAsFixed(6)}, ${result.longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            const Text(
              'Stay calm and follow any instructions from emergency responders.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.red,
        automaticallyImplyLeading: false, // Prevent back button
      ),
      body: _isLoading && _currentPosition == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Map Section
                Expanded(
                  flex: 2,
                  child: _currentPosition == null
                      ? const Center(child: Text('Getting your location...'))
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 15,
                          ),
                          onMapCreated: (controller) => _mapController = controller,
                          markers: {
                            Marker(
                              markerId: const MarkerId('current_location'),
                              position: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              infoWindow: const InfoWindow(title: 'Your Location'),
                            ),
                          },
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                ),

                // SOS Button Section
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Tap the button below in case of emergency',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Large SOS Button
                        SizedBox(
                          width: 200,
                          height: 200,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _triggerSOS,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              shape: const CircleBorder(),
                              elevation: 8,
                              shadowColor: Colors.red.shade300,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '🚨',
                                        style: TextStyle(fontSize: 48),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'SOS',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),

                        const SizedBox(height: 32),
                        const Text(
                          'This will alert emergency services and send your location',
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),

                        if (_emergencyId != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Emergency ID: $_emergencyId\nHelp is on the way!',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.green.shade800),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

// Comments for academic documentation:
// - EmergencyScreen: Full-screen red-themed SOS interface
// - GPS integration: Automatic location capture using geolocator
// - Google Maps: Visual display of current location with marker
// - Large SOS button: Prominent emergency trigger with loading states
// - Confirmation dialog: Shows emergency details and reassurance
// - Non-blocking UI: Prevents accidental back navigation during emergency
// - Real-time updates: Displays emergency ID once SOS is triggered