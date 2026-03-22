import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import 'auth_provider.dart';

class OTPScreen extends StatefulWidget {
  static const routeName = '/otp';
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController _otpController = TextEditingController(text: '123456');
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments;
    final user = args is UserModel ? args : null;

    return Scaffold(
      appBar: AppBar(title: const Text('OTP Verification')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Enter OTP sent to your phone. (Mock: 123456)'),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'OTP'),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user context')));
                        return;
                      }
                      setState(() => _isLoading = true);
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      final verification = await authProvider.verifyOtp(user.id, _otpController.text.trim());
                      setState(() => _isLoading = false);

                      if (verification) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP verified')));
                        Navigator.pushReplacementNamed(context, '/login');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP invalid')));
                      }
                    },
              child: _isLoading ? const CircularProgressIndicator() : const Text('Verify OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
