// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:love_letter_app/services/storage_service.dart';
import 'package:love_letter_app/services/sample_data_service.dart';
import 'package:love_letter_app/services/notification_service_web.dart'; // ✨ Web notifications
import 'package:love_letter_app/screens/entrance_screen.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await FirebaseService.instance.initialize();
    print('✅ Firebase initialized successfully!');
    
    // ✨ Initialize web push notifications
    if (kIsWeb) {
      await NotificationServiceWeb.instance.initialize();
      print('✅ Web notifications initialized!');
    }
  } catch (e) {
    print('❌ Initialization error: $e');
  }
 
  // Initialize storage service
  await StorageService.instance.initialize();
 
  // Load sample data if no letters exist
  await SampleDataService.initializeSampleData();
 
  runApp(const LoveLettersApp());
}

class LoveLettersApp extends StatelessWidget {
  const LoveLettersApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Love Letters',
      theme: AppTheme.lightTheme,
      home: const EntranceScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}