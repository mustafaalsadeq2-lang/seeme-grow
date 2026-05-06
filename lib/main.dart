import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'l10n/app_localizations.dart';
import 'screens/auth/auth_gate.dart';

// Global theme notifier — settings_screen writes to this to toggle dark mode.
final themeNotifier = ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    anonKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const SeeMeGrowApp());
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
          themeMode: mode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(
            colorSchemeSeed: const Color(0xFF0F4F45),
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF7F5F0),
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: const Color(0xFF0F4F45),
            brightness: Brightness.dark,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}
