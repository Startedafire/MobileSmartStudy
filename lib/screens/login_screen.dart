import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  String? errorMessage;

  Future<void> signIn() async {
    // Basic validation first
    if (emailController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter an email');
      return;
    }
    
    if (passwordController.text.trim().isEmpty) {
      setState(() => errorMessage = 'Please enter a password');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });
    
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } on AuthException catch (e) {
      String userFriendlyMessage;
      
      if (e.message.toLowerCase().contains('email not confirmed')) {
        userFriendlyMessage = 'Please check your email and click the confirmation link first.';
        _showEmailNotConfirmedDialog();
        return;
      } else if (e.message.toLowerCase().contains('invalid login credentials') ||
                 e.message.toLowerCase().contains('invalid email or password')) {
        userFriendlyMessage = 'Invalid email or password. Please try again.';
      } else if (e.message.toLowerCase().contains('too many requests')) {
        userFriendlyMessage = 'Too many login attempts. Please wait a moment and try again.';
      } else {
        userFriendlyMessage = e.message;
      }
      
      setState(() => errorMessage = userFriendlyMessage);
    } catch (e) {
      setState(() => errorMessage = 'Network error: Please check your connection and try again.');
      debugPrint('Login error: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void _showEmailNotConfirmedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Email Not Confirmed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.email_outlined, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              'Please check your email and click the confirmation link before signing in.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _resendConfirmation();
            },
            child: const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  Future<void> _resendConfirmation() async {
    final email = emailController.text.trim();
    if (email.isEmpty) return;

    try {
      await SupabaseService.client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirmation email sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                hintText: 'Enter your password',
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
                onPressed: loading ? null : signIn,
                child: loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Login'),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: loading ? null : () => Navigator.pushNamed(context, '/signup'),
              child: const Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }
}