import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  debugPrint('🚀 [main] Starting app...');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🚀 [main] WidgetsBinding initialized');

  try {
    debugPrint('🚀 [main] Loading .env...');
    await dotenv.load(fileName: '.env');
    debugPrint('🚀 [main] .env loaded successfully');

    debugPrint('🚀 [main] Running app...');
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            color: Colors.white,
            child: const Center(
              child: Text(
                'SEEME GROW',
                style: TextStyle(fontSize: 24, color: Colors.black),
              ),
            ),
          ),
        ),
      ),
    );
  } catch (e, stack) {
    debugPrint('❌ [main] Error during initialization: $e');
    debugPrint('❌ [main] Stack trace: $stack');
    runApp(MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade100,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Startup Error:\n$e',
              style: const TextStyle(color: Colors.red, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ));
  }
}
