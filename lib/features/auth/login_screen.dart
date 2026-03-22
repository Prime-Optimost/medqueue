import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MedQueue Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Email or Phone'),
                validator: (value) => (value == null || value.isEmpty) ? 'Enter email or phone' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => (value == null || value.isEmpty) ? 'Enter password' : null,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() => _isLoading = true);
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final loggedIn = await authProvider.login(
                            _usernameController.text.trim(),
                            _passwordController.text.trim(),
                          );
                          setState(() => _isLoading = false);

                          if (loggedIn) {
                            final role = authProvider.user?.role ?? 'patient';
                            final route =
                                role == 'doctor' ? '/doctor-dashboard' : role == 'admin' ? '/admin-dashboard' : '/patient-dashboard';
                            Navigator.pushReplacementNamed(context, route);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Login failed: invalid credentials')),
                            );
                          }
                        }
                      },
                child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                child: const Text('Create account'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
