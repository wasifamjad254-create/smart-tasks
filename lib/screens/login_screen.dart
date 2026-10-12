import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../services/api_service.dart';
import 'register_screen.dart';
import 'tasks_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final ApiService apiService = ApiService();

  bool isPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiService.login(
        emailController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.data['message'] ?? 'Login successful')),
      );

      // Open the Tasks screen after successful login.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TasksScreen()),
      );
    } on DioException catch (e) {
      if (!mounted) return;

      final data = e.response?.data;
      String message = 'Login failed. Please try again.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF17213B);
    const muted = Color(0xFF7B8298);
    const purple = Color(0xFF6558F5);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(25, 8, 25, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(color: const Color(0xFFEFEDFF), borderRadius: BorderRadius.circular(19)),
                      child: const Icon(Icons.lock_open_rounded, color: purple, size: 29),
                    ),
                    const SizedBox(height: 25),
                    const Text('Welcome back', style: TextStyle(color: ink, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -.7)),
                    const SizedBox(height: 8),
                    const Text('Log in to pick up where you left off.', style: TextStyle(color: muted, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 32),
                    const Text('Email address', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your email';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) return 'Please enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text('Password', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 9),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                          icon: Icon(isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Please enter your password' : null,
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        child: isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Log in'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 18)]),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("New to SmartTasks? ", style: TextStyle(color: muted, fontSize: 13)),
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Create account'),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    const Center(child: Text('YOUR TASKS, ALL IN ONE PLACE', style: TextStyle(color: Color(0xFF9AA0B2), fontSize: 10, letterSpacing: 1.1, fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
