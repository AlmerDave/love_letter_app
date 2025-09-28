// lib/main.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/services/storage_service.dart';
import 'package:love_letter_app/services/sample_data_service.dart';
import 'package:love_letter_app/screens/main_screen.dart';
import 'package:love_letter_app/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
      home: const EnhancedMainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}