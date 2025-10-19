import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> logout() async {
    await SupabaseService.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SmartStudy AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout,
          ),
        ],
      ),
      body: Center(
        child: Text(
          user != null ? 'Welcome, ${user.email}' : 'Welcome, Guest!',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}