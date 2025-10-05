import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_tabs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://bhvisxadsibfeymwnmdx.supabase.co', // replace with your URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJodmlzeGFkc2liZmV5bXdubWR4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkzMTk3ODMsImV4cCI6MjA3NDg5NTc4M30.qgtqDS2cZ6028neWDuCxm674H9NslS04OjFmhEaLQJw',          // replace with anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartStudy AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainTabsScreen(),
    );
  }
}
