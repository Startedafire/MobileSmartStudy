import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    testConnection();
  }

  Future<void> testConnection() async {
    try {
      final response = await supabase.from('uploaded_files').select();
      print('Connected! Rows: ${response.length}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connected! Rows: ${response.length}')),
      );
    } catch (e) {
      print('Connection failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test Supabase Connection')),
      body: const Center(child: Text('Check console or SnackBar for result')),
    );
  }
}
