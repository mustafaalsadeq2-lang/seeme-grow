import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/supabase_config.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Load environment variables
  await dotenv.load(fileName: '.env');

  // 🔹 Initialize Supabase securely
  await SupabaseConfig.initialize();

  runApp(const ProviderScope(child: SeeMeGrowApp()));
}

class SeeMeGrowApp extends StatelessWidget {
  const SeeMeGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SeeMeGrow',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: const Color(0xFFF7F7F8),
      ),
      home: AuthGate(),
    );
  }
}
