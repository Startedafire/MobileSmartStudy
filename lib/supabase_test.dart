import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bhvisxadsibfeymwnmdx.supabase.co', // <-- replace
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJodmlzeGFkc2liZmV5bXdubWR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzMTk3ODMsImV4cCI6MjA3NDg5NTc4M30.qgtqDS2cZ6028neWDuCxm674H9NslS04OjFmhEaLQJw',            // <-- replace
  );

  runApp(const SupabaseTestApp());
}

class SupabaseTestApp extends StatelessWidget {
  const SupabaseTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Supabase Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final supabase = Supabase.instance.client;
  String result = "Press the button to test connection";

  Future<void> testConnection() async {
    try {
      // Latest syntax: await select() directly
      final response = await supabase.from('uploaded_files').select();

      // response is List<dynamic>, cast to List<Map<String, dynamic>>
      final data = (response as List).cast<Map<String, dynamic>>();

      setState(() {
        result = "Success! ${data.length} rows found.";
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supabase Connection Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(result, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: testConnection,
              child: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
