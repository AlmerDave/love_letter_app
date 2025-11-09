// lib/screens/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/screens/main_screen.dart';
import 'package:love_letter_app/screens/location_map_screen.dart';
import 'package:love_letter_app/screens/qr_scanner_screen.dart';
import 'package:love_letter_app/screens/bubu_dudu_journey_screen.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/location_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/sound_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isHandlingLocationTap = false;
  
  // Screens for each tab
  final List<Widget> _screens = [
    const MainScreen(),
    const LocationMapScreenWrapper(), // Wrapper to handle navigation logic
    const BubuDuduJourneyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _buildScanFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) async {
          // Only handle if switching TO location tab (not already on it) and not already processing
          if (index == 1 && _currentIndex != 1 && !_isHandlingLocationTap) {
            _isHandlingLocationTap = true;
            final success = await _handleLocationTabTap();
            _isHandlingLocationTap = false;
            
            if (!success) {
              setState(() {
                _currentIndex = 0;
              });
              return;
            }
          }
          
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.deepPurple,
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Letters',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on_outlined),
            activeIcon: Icon(Icons.location_on),
            label: 'Where are you?',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_rounded),  // Changed from grid to heart
            activeIcon: Icon(Icons.favorite),
            label: 'Journey',  // Changed from 'More' to 'Journey'
          ),
        ],
      ),
    );
  }

  Widget _buildScanFAB() {
    return FloatingActionButton(
      onPressed: _navigateToQRScanner,
      backgroundColor: AppTheme.deepPurple,
      elevation: 8,
      child: const Icon(
        Icons.qr_code_scanner,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Future<void> _navigateToQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    
    if (result == true) {
      SoundService.instance.playSound(SoundType.newLetter);
      _showSuccessMessage('New letter added! 💕');
      // Refresh the letters screen if we're on it
      if (_currentIndex == 0) {
        setState(() {}); // Trigger rebuild to refresh EnhancedMainScreen
      }
    }
  }

  Future<bool> _handleLocationTabTap() async {
    try {
      // Step 1: Check if user has nickname locally
      bool hasNickname = await UserService.hasNickname();
      
      String? nickname;
      if (!hasNickname) {
        nickname = await _showNicknameDialog();
        if (nickname == null || nickname.isEmpty) {
          return false; // User cancelled
        }
        // Save locally (will be stored as lowercase)
        await UserService.saveNickname(nickname);
      } else {
        nickname = await UserService.getNickname();
      }

      // Step 2: Get current location
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showErrorMessage('Location permission denied 📍');
        return false;
      }

      // Step 3: Convert nickname to lowercase for comparison
      final lowercaseNickname = nickname!.trim().toLowerCase();

      // Step 4: Check if nickname exists in Firebase
      final snapshot = await FirebaseService.instance.locationsRef
          .orderByChild('nickname')
          .equalTo(lowercaseNickname)
          .once();

      if (snapshot.snapshot.value != null) {
        // Step 5A: Nickname EXISTS - Update existing entry
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        final existingUserId = data.keys.first;
        
        await FirebaseService.instance.locationsRef
            .child(existingUserId)
            .update({
          'lat': position.latitude,
          'lng': position.longitude,
          'isSharing': true,
          'lastUpdated': ServerValue.timestamp,
        });

        // Store this userId locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_device_id', existingUserId);
        
        print('🔄 Updated existing location for nickname: $lowercaseNickname');
        
      } else {
        // Step 5B: Nickname DOES NOT exist - Create new entry
        final userId = await UserService.getUserId();
        
        await FirebaseService.instance.locationsRef.child(userId).set({
          'userId': userId,
          'nickname': lowercaseNickname,
          'lat': position.latitude,
          'lng': position.longitude,
          'isSharing': true,
          'lastUpdated': ServerValue.timestamp,
        });
        
        print('✨ Created new location entry for nickname: $lowercaseNickname');
      }

      return true; // Success, allow tab switch
      
    } catch (e) {
      _showErrorMessage('Failed to share location: $e');
      return false;
    }
  }

  Future<String?> _showNicknameDialog() async {
    String? nickname;
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppTheme.warmCream,
        title: Column(
          children: [
            Icon(
              Icons.favorite,
              color: AppTheme.deepPurple,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'What\'s your name? 💕',
              style: AppTheme.romanticTitle.copyWith(
                fontSize: 20,
                color: AppTheme.deepPurple,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: TextField(
          autofocus: true,
          textAlign: TextAlign.center,
          style: AppTheme.invitationMessage.copyWith(fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Enter your nickname',
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.primaryLavender),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppTheme.deepPurple, width: 2),
            ),
          ),
          onChanged: (value) => nickname = value,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context, value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nickname != null && nickname!.isNotEmpty) {
                Navigator.pop(context, nickname);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Continue',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Wrapper for LocationMapScreen to remove its own app bar
class LocationMapScreenWrapper extends StatelessWidget {
  const LocationMapScreenWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const LocationMapScreen();
  }
}