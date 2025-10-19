import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool loading = false;
  String? errorMessage;

  Future<void> signUp() async {
    // Basic validation first
    if (nameController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter your name');
      return;
    }
    
    if (emailController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter an email');
      return;
    }
    
    if (!emailController.text.trim().contains('@')) {
      setState(() => errorMessage = 'Please enter a valid email address');
      return;
    }
    
    if (passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter a password');
      return;
    }
    
    if (passwordController.text.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (confirmPasswordController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please confirm your password');
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() => errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });
    
    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final password = passwordController.text.trim();
      
      debugPrint('Attempting signup for: $email with name: $name');
      
      // Direct signup with display name (no pre-check since email confirmation is disabled)
      final res = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': name,
          'full_name': name,
        },
      );

      debugPrint('Signup successful for: ${res.user?.email}');
      debugPrint('User display name: ${res.user?.userMetadata?['display_name']}');

      if (!mounted) return;

      if (res.user != null) {
        // Since email confirmation is disabled, go directly to login
        _showSuccessAndGoToLogin();
      } else {
        setState(() => errorMessage = 'Failed to create account. Please try again.');
      }
      
    } on AuthException catch (e) {
      debugPrint('Signup AuthException: ${e.message}');
      debugPrint('Signup AuthException status: ${e.statusCode}');
      
      String userFriendlyMessage;
      if (e.message.toLowerCase().contains('user already registered') || 
          e.message.toLowerCase().contains('email already registered') ||
          e.message.toLowerCase().contains('already been registered') ||
          e.message.toLowerCase().contains('user with this email already exists') ||
          e.message.toLowerCase().contains('email address already in use') ||
          e.statusCode == '422' ||
          e.statusCode == '400') {
        userFriendlyMessage = 'An account with this email already exists. Please try signing in instead.';
      } else if (e.message.toLowerCase().contains('invalid email')) {
        userFriendlyMessage = 'Please enter a valid email address.';
      } else if (e.message.toLowerCase().contains('weak password') ||
                 e.message.toLowerCase().contains('password')) {
        userFriendlyMessage = 'Password is too weak. Please use at least 6 characters.';
      } else if (e.message.toLowerCase().contains('rate limit') ||
                 e.message.toLowerCase().contains('too many')) {
        userFriendlyMessage = 'Too many attempts. Please wait a moment and try again.';
      } else {
        userFriendlyMessage = 'Signup error: ${e.message}';
      }
      
      setState(() => errorMessage = userFriendlyMessage);
    } catch (e) {
      debugPrint('General signup exception: $e');
      setState(() => errorMessage = 'Network error: Please check your connection and try again.');
    } finally {
      setState(() => loading = false);
    }
  }

  void _showSuccessAndGoToLogin() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Welcome ${nameController.text.trim()}! Account created successfully!')),
    );
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40), // Add some top spacing
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Enter your full name',
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
                hintText: 'Enter your email',
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              textCapitalization: TextCapitalization.none,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
                hintText: 'At least 6 characters',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
                hintText: 'Re-enter your password',
              ),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : signUp,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Create Account'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: loading ? null : () => Navigator.pushNamed(context, '/login'),
              child: const Text('Already have an account? Login'),
            ),
            const SizedBox(height: 40), // Add some bottom spacing
          ],
        ),
      ),
    );
  }
}