// lib/screens/more_screen.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/screens/location_map_screen.dart';
import 'package:love_letter_app/screens/love_signals_screen.dart';
import 'package:love_letter_app/services/location_service.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        title: Text(
          '✨ More Features',
          style: AppTheme.romanticTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLavender.withOpacity(0.3),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2, // 2 columns
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.95, // ✨ FIXED: Slightly taller to prevent overflow
            children: [
              // Find Your Partner Location Card (ACTIVE)
              _FeatureCard(
                imagePath: 'assets/images/bubu_dudu/location_feature.gif',
                fallbackIcon: Icons.location_on,
                title: 'Find Your\nPartner',
                subtitle: 'See where they are 💕',
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryLavender,
                    AppTheme.softBlush,
                  ],
                ),
                onTap: () => _handleLocationFeature(context),
                isComingSoon: false, // Active feature!
              ),

              // Love Signals Feature Card (ACTIVE)
              _FeatureCard(
                imagePath: 'assets/images/bubu_dudu/love_signals_feature.gif',
                fallbackIcon: Icons.favorite,
                title: 'Love\nSignals',
                subtitle: 'Send hugs & thoughts 💭',
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.softBlush,
                    AppTheme.blushPink,
                  ],
                ),
                onTap: () => _handleLoveSignals(context),
                isComingSoon: false, // Active feature!
              ),

              // Placeholder 2 - Special Dates (GRAYED OUT)
              _FeatureCard(
                imagePath: 'assets/images/bubu_dudu/calendar_feature.gif',
                fallbackIcon: Icons.calendar_today,
                title: 'Please\nWait',
                subtitle: 'Coming soon 📅',
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade300, // ✨ Grayed out
                    Colors.grey.shade400,
                  ],
                ),
                onTap: () => _showComingSoon(context),
                isComingSoon: true,
              ),

              // Placeholder 3 - Voice Messages (GRAYED OUT)
              _FeatureCard(
                imagePath: 'assets/images/bubu_dudu/voice_feature.gif',
                fallbackIcon: Icons.mic,
                title: 'Please\nWait',
                subtitle: 'Coming soon 🎤',
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.grey.shade300, // ✨ Grayed out
                    Colors.grey.shade400,
                  ],
                ),
                onTap: () => _showComingSoon(context),
                isComingSoon: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleLoveSignals(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoveSignalsScreen(),
      ),
    );
  }

  Future<void> _handleLocationFeature(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.deepPurple),
              const SizedBox(height: 16),
              Text(
                'Getting your location...',
                style: TextStyle(color: AppTheme.darkText),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Step 1: Get nickname
      final nickname = await UserService.getNickname();
      if (nickname == null || nickname.isEmpty) {
        Navigator.pop(context); // Close loading
        _showErrorMessage(context, 'Nickname not found. Please restart app.');
        return;
      }

      // Step 2: Get current location
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        Navigator.pop(context); // Close loading
        _showErrorMessage(context, 'Location permission denied 📍');
        return;
      }

      // Step 3: Convert nickname to lowercase for comparison
      final lowercaseNickname = nickname.trim().toLowerCase();

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

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to map screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LocationMapScreen(),
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Close loading
      _showErrorMessage(context, 'Failed to get location: $e');
    }
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✨ This feature is coming soon!'),
        backgroundColor: AppTheme.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Feature Card Widget with Bubu & Dudu Image Support
class _FeatureCard extends StatelessWidget {
  final String? imagePath; // Path to Bubu & Dudu GIF/image
  final IconData fallbackIcon; // Icon to show if image fails to load
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;
  final bool isComingSoon;

  const _FeatureCard({
    this.imagePath,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
    this.isComingSoon = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isComingSoon 
                  ? Colors.grey.withOpacity(0.15) // ✨ Lighter shadow for grayed cards
                  : AppTheme.deepPurple.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14), // ✨ FIXED: Reduced padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // ✨ FIXED: Prevent overflow
                children: [
                  // Bubu & Dudu Image or Icon
                  _buildImageOrIcon(),
                  const SizedBox(height: 10), // ✨ FIXED: Reduced spacing
                  
                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14, // ✨ FIXED: Slightly smaller
                      fontWeight: FontWeight.bold,
                      color: isComingSoon ? Colors.grey.shade700 : Colors.white,
                      height: 1.1, // ✨ FIXED: Tighter line height
                    ),
                  ),
                  const SizedBox(height: 4), // ✨ FIXED: Reduced spacing
                  
                  // Subtitle
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10, // ✨ FIXED: Slightly smaller
                      color: isComingSoon 
                          ? Colors.grey.shade600 
                          : Colors.white.withOpacity(0.9),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build image widget with fallback to icon
  Widget _buildImageOrIcon() {
    if (imagePath != null) {
      return Container(
        width: 70, // ✨ FIXED: Slightly smaller to fit better
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isComingSoon ? 0.7 : 0.9), // ✨ Less opaque for grayed cards
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipOval(
          child: ColorFiltered(
            colorFilter: isComingSoon
                ? ColorFilter.mode(
                    Colors.grey.withOpacity(0.5), // ✨ Gray filter for coming soon images
                    BlendMode.saturation,
                  )
                : const ColorFilter.mode(
                    Colors.transparent,
                    BlendMode.multiply,
                  ),
            child: Image.asset(
              imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to icon if image not found
                return _buildFallbackIcon();
              },
            ),
          ),
        ),
      );
    } else {
      return _buildFallbackIcon();
    }
  }

  /// Icon fallback when image is not available
  Widget _buildFallbackIcon() {
    return Container(
      width: 70, // ✨ FIXED: Match image size
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isComingSoon ? 0.7 : 0.9), // ✨ Less opaque for grayed cards
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        fallbackIcon,
        size: 32, // ✨ FIXED: Slightly smaller icon
        color: isComingSoon ? Colors.grey.shade600 : AppTheme.deepPurple, // ✨ Gray for coming soon
      ),
    );
  }
}