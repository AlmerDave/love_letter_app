// lib/screens/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/screens/main_screen.dart';
import 'package:love_letter_app/screens/more_screen.dart';
import 'package:love_letter_app/screens/qr_scanner_screen.dart';
import 'package:love_letter_app/screens/bubu_dudu_journey_screen.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/sound_service.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  bool _isCheckingNickname = true;
  bool _hasNickname = false;

  @override
  void initState() {
    super.initState();
    _checkNicknameOnStart();
  }

  Future<void> _checkNicknameOnStart() async {
    final hasNickname = await UserService.hasNickname();
    
    if (!hasNickname) {
      // Force nickname dialog - no cancel option
      final nickname = await _showMandatoryNicknameDialog();
      if (nickname != null && nickname.isNotEmpty) {
        await UserService.saveNickname(nickname);
      }
    }
    
    setState(() {
      _hasNickname = true;
      _isCheckingNickname = false;
    });
  }
  
  // Screens for each tab
  final List<Widget> _screens = [
    const MainScreen(),
    const MoreScreen(), // ✨ Changed from LocationMapScreenWrapper to MoreScreen
    const BubuDuduJourneyScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Show loading screen while checking nickname
    if (_isCheckingNickname) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.deepPurple),
              const SizedBox(height: 24),
              Text(
                'Loading...',
                style: TextStyle(
                  color: AppTheme.darkText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
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
        onTap: (index) {
          // Simple tab switching - no special handling needed
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
            icon: Icon(Icons.grid_view_rounded), // ✨ Changed icon
            activeIcon: Icon(Icons.grid_view), // ✨ Changed icon
            label: 'More', // ✨ Changed label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            activeIcon: Icon(Icons.pets),
            label: 'Bubu&Dudu',
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

  Future<String?> _showMandatoryNicknameDialog() async {
    String nickname = '';
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevent Android back button
        child: AlertDialog(
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
                'Welcome! What\'s your name? 💕',
                style: AppTheme.romanticTitle.copyWith(
                  fontSize: 20,
                  color: AppTheme.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Required to continue',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
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
            onChanged: (value) {
              nickname = value;
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                Navigator.pop(context, value);
              }
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (nickname.isNotEmpty) {
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