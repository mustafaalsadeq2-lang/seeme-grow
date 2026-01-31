import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/supabase_config.dart';
import 'screens/auth/auth_gate.dart';

const _keyDarkMode = 'dark_mode';

final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔐 Load environment variables
  await dotenv.load(fileName: '.env');

  // 🔹 Initialize Supabase securely
  await SupabaseConfig.initialize();

  // 🌗 Load theme preference
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool(_keyDarkMode) ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const ProviderScope(child: SeeMeGrowApp()));
}

class SeeMeGrowApp extends StatelessWidget {
  const SeeMeGrowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SeeMeGrow',
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            scaffoldBackgroundColor: const Color(0xFFF7F7F8),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
