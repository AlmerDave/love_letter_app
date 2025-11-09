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
import 'package:love_letter_app/animations/shimmer_loading.dart';
import 'package:love_letter_app/animations/floating_hearts_background.dart';
import 'package:love_letter_app/utils/bubu_dudu_assets.dart';
import 'package:love_letter_app/utils/theme.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
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
        // Removed floatingActionButton - now handled by MainNavigation
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
              const SizedBox(height: 100), // Extra padding for bottom nav
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
}