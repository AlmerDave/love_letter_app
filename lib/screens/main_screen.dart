// lib/screens/enhanced_main_screen.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/models/invitation_status.dart';
import 'package:love_letter_app/services/storage_service.dart';
import 'package:love_letter_app/services/sample_data_service.dart';
import 'package:love_letter_app/services/sound_service.dart';
import 'package:love_letter_app/widgets/letter_envelope.dart';
import 'package:love_letter_app/screens/invitation_detail_screen.dart';
import 'package:love_letter_app/screens/qr_scanner_screen.dart';
import 'package:love_letter_app/screens/location_map_screen.dart';
import 'package:love_letter_app/animations/shimmer_loading.dart';
import 'package:love_letter_app/animations/floating_hearts_background.dart';
import 'package:love_letter_app/utils/bubu_dudu_assets.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/location_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:firebase_database/firebase_database.dart';


class EnhancedMainScreen extends StatefulWidget {
  const EnhancedMainScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedMainScreen> createState() => _EnhancedMainScreenState();
}

class _EnhancedMainScreenState extends State<EnhancedMainScreen>
    with TickerProviderStateMixin {
  List<Invitation> _invitations = [];
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInvitations();
    _checkForUnlockedLetters();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadInvitations() async {
    setState(() => _isLoading = true);
    
    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final invitations = await StorageService.instance.getAllInvitations();
      setState(() {
        _invitations = invitations;
        _isLoading = false;
      });

      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorMessage('Failed to load invitations');
    }
  }

  Future<void> _checkForUnlockedLetters() async {
    try {
      final newlyUnlocked = await StorageService.instance.checkForNewlyUnlockedLetters();
      if (newlyUnlocked.isNotEmpty && mounted) {
        SoundService.instance.playSound(SoundType.letterUnlock);
        _showSuccessMessage('${newlyUnlocked.length} letter(s) are now available! 💕');
        await _loadInvitations();
      }
    } catch (e) {
      print('Error checking for unlocked letters: $e');
    }
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

  Future<void> _navigateToQRScanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    
    if (result == true) {
      SoundService.instance.playSound(SoundType.newLetter);
      await _loadInvitations();
      _showSuccessMessage('New letter added! 💕');
    }
  }

  Future<void> _navigateToLocationMap() async {
    try {
      bool hasNickname = await UserService.hasNickname();
      
      if (!hasNickname) {
        final nickname = await _showNicknameDialog();
        if (nickname == null || nickname.isEmpty) {
          return;
        }
        
        await UserService.saveNickname(nickname);
      }

      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        _showErrorMessage('Location permission denied 📍');
        return;
      }

      final userId = await UserService.getUserId();
      final nickname = await UserService.getNickname();
      
      await FirebaseService.instance.locationsRef.child(userId).set({
        'userId': userId,
        'nickname': nickname,
        'lat': position.latitude,
        'lng': position.longitude,
        'isSharing': true,
        'lastUpdated': ServerValue.timestamp,
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LocationMapScreen(),
        ),
      );

    } catch (e) {
      _showErrorMessage('Failed to share location: $e');
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
              style: TextStyle(color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  void _openInvitation(Invitation invitation) async {
    if (!invitation.isAvailable && !invitation.status.canBeOpened) {
      _showErrorMessage('This invitation cannot be opened yet');
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvitationDetailScreen(invitation: invitation),
      ),
    );

    if (result == true) {
      await _loadInvitations();
    }
  }

  Future<void> _addSampleLetter() async {
    try {
      await SampleDataService.addTestInvitation();
      await _loadInvitations();
      _showSuccessMessage('Sample love letter added! 💕');
    } catch (e) {
      _showErrorMessage('Failed to add sample letter');
    }
  }

  List<Invitation> get _availableInvitations {
    return _invitations.where((inv) => inv.isAvailable).toList()
      ..sort((a, b) => a.unlockDateTime.compareTo(b.unlockDateTime));
  }

  List<Invitation> get _lockedInvitations {
    return _invitations.where((inv) => inv.isLocked).toList()
      ..sort((a, b) => a.unlockDateTime.compareTo(b.unlockDateTime));
  }

  List<Invitation> get _completedInvitations {
    return _invitations.where((inv) => 
      inv.status == InvitationStatus.accepted || 
      inv.status == InvitationStatus.completed ||
      inv.status == InvitationStatus.rejected
    ).toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    return FloatingHeartsBackground(
      enabled: true,
      heartCount: 12,
      duration: const Duration(seconds: 8),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: _buildAnimatedAppBar(),
        body: _isLoading 
          ? const LoadingLettersScreen()
          : _buildContent(),
        floatingActionButton: _buildAnimatedFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAnimatedAppBar() {
    return AppBar(
      title: ShimmerLoading(
        isLoading: _isLoading,
        child: Text(
          'Love Letters',
          style: AppTheme.romanticTitle.copyWith(fontSize: 22),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryLavender.withOpacity(0.1),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_invitations.isEmpty) {
      return _buildEnhancedEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: () async {
            await _checkForUnlockedLetters();
            await _loadInvitations();
          },
          color: AppTheme.deepPurple,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            children: [
              if (_availableInvitations.isNotEmpty) ...[
                _buildAnimatedSectionHeader('Available Letters', Icons.favorite, BubuDuduTheme.excited),
                ..._availableInvitations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final invitation = entry.value;
                  return _buildAnimatedLetterCard(invitation, index);
                }).toList(),
                const SizedBox(height: 24),
              ],
              if (_lockedInvitations.isNotEmpty) ...[
                _buildAnimatedSectionHeader('Locked Letters', Icons.lock, BubuDuduTheme.waiting),
                ..._lockedInvitations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final invitation = entry.value;
                  return _buildAnimatedLetterCard(invitation, index + _availableInvitations.length);
                }).toList(),
                const SizedBox(height: 24),
              ],
              if (_completedInvitations.isNotEmpty) ...[
                _buildAnimatedSectionHeader('Memory Box', Icons.archive, BubuDuduTheme.love),
                ..._completedInvitations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final invitation = entry.value;
                  return _buildAnimatedLetterCard(invitation, index + _availableInvitations.length + _lockedInvitations.length);
                }).toList(),
              ],
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedLetterCard(Invitation invitation, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: invitation.isAvailable 
        ? Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.transparent,
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: LetterEnvelope(
              invitation: invitation,
              onTap: () => _openInvitation(invitation),
            ),
          )
        : LetterEnvelope(
            invitation: invitation,
            onTap: () => _openInvitation(invitation),
          ),
    );
  }

  Widget _buildAnimatedSectionHeader(String title, IconData fallbackIcon, BubuDuduTheme theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.primaryLavender.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.primaryLavender.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(fallbackIcon, color: AppTheme.deepPurple, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTheme.dateTimeStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 100,
                color: AppTheme.deepPurple.withOpacity(0.5),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.warmCream.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primaryLavender.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'No Love Letters Yet',
                      style: AppTheme.romanticTitle.copyWith(
                        color: AppTheme.deepPurple,
                        fontSize: 24,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Scan a QR code to receive your first romantic invitation!',
                      textAlign: TextAlign.center,
                      style: AppTheme.invitationMessage.copyWith(
                        color: AppTheme.darkText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSimpleButton(
                    onPressed: _navigateToQRScanner,
                    icon: Icons.qr_code_scanner,
                    label: 'Scan QR',
                    color: AppTheme.deepPurple,
                  ),
                  _buildSimpleButton(
                    onPressed: _addSampleLetter,
                    icon: Icons.favorite,
                    label: 'Add Sample',
                    color: Colors.green.shade400,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: AppTheme.invitationMessage.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    return ScaleTransition(
      scale: _fadeAnimation,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'location',
            onPressed: _navigateToLocationMap,
            backgroundColor: Colors.pink.shade50,
            elevation: 6,
            icon: Icon(
              Icons.favorite,
              color: Colors.pink.shade400,
              size: 24,
            ),
            label: Text(
              'Where Are You?',
              style: AppTheme.invitationMessage.copyWith(
                color: Colors.pink.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          FloatingActionButton.extended(
            heroTag: 'scanner',
            onPressed: _navigateToQRScanner,
            backgroundColor: AppTheme.primaryLavender,
            elevation: 6,
            icon: Icon(
              Icons.qr_code_scanner,
              color: AppTheme.deepPurple,
              size: 24,
            ),
            label: Text(
              'Scan Letter',
              style: AppTheme.invitationMessage.copyWith(
                color: AppTheme.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}