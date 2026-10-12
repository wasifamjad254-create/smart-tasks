import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final ApiService apiService = ApiService();

  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await apiService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.data['message'] ?? 'Registration successful'),
        ),
      );

      // Registration returns a token.
      // Return to the previous screen with success.
      Navigator.pop(context, true);
    } on DioException catch (e) {
      if (!mounted) return;

      final data = e.response?.data;
      String message = 'Registration failed. Please try again.';

      if (data is Map && data['errors'] is Map) {
        final errors = data['errors'] as Map;
        if (errors.isNotEmpty) {
          final firstError = errors.values.first;

          if (firstError is List && firstError.isNotEmpty) {
            message = firstError.first.toString();
          }
        }
      } else if (data is Map && data['message'] != null) {
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
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 6, 25, 28),
          child: Center(
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
                      child: const Icon(Icons.person_add_alt_1_rounded, color: purple, size: 29),
                    ),
                    const SizedBox(height: 23),
                    const Text('Create your account', style: TextStyle(color: ink, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -.6)),
                    const SizedBox(height: 8),
                    const Text('A few details and you’re ready to get organized.', style: TextStyle(color: muted, fontSize: 14, height: 1.5)),
                    const SizedBox(height: 26),
                    const Text('Full name', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: nameController,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(hintText: 'Enter your name', prefixIcon: Icon(Icons.person_outline_rounded)),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    const Text('Email address', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                    const Text('Phone number', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(hintText: 'Enter your phone number', prefixIcon: Icon(Icons.phone_outlined)),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return 'Please enter your phone number';
                        if (value.replaceAll(RegExp(r'[^0-9]'), '').length < 10) return 'Please enter a valid phone number';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Password', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'At least 8 characters',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
                          icon: Icon(isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please enter your password';
                        if (value.length < 8) return 'Password must be at least 8 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('Confirm password', style: TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: !isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Enter your password again',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => isConfirmPasswordVisible = !isConfirmPasswordVisible),
                          icon: Icon(isConfirmPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Please confirm your password';
                        if (value != passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : register,
                        child: isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('Create account'), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, size: 18)]),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(color: muted, fontSize: 13)),
                          TextButton(onPressed: isLoading ? null : () => Navigator.pop(context), child: const Text('Log in')),
                        ],
                      ),
                    ),
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
