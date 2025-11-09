// lib/screens/bubu_dudu_journey_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/utils/journey_assets.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/bubu_dudu_service.dart';
import 'package:love_letter_app/services/motion_service.dart';
import 'package:love_letter_app/services/sound_service.dart';
import 'package:love_letter_app/models/journey_session.dart';

enum UserRole { bubu, dudu, unknown }

enum BubuState { idle, excited, runningLeft, departed }

enum DuduState { idle, ready, waiting, bubuArriving, together }

class BubuDuduJourneyScreen extends StatefulWidget {
  const BubuDuduJourneyScreen({Key? key}) : super(key: key);

  @override
  State<BubuDuduJourneyScreen> createState() => _BubuDuduJourneyScreenState();
}

class _BubuDuduJourneyScreenState extends State<BubuDuduJourneyScreen>
    with WidgetsBindingObserver {
  UserRole _userRole = UserRole.unknown;
  BubuState _bubuState = BubuState.idle;
  DuduState _duduState = DuduState.idle;

  StreamSubscription<JourneySession>? _sessionSubscription;
  bool _hasCheckedRole = false;
  bool _isCheckingRole = true;
  bool _isInitialized = false;

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);

  if (_hasCheckedRole && _userRole != UserRole.unknown) {
    // Already determined valid user → directly reinitialize services
    print('🔁 Returning to journey tab — reinitializing services');
    _initializeServices();
  } else {
    // First-time load or unknown user
    print('🆕 First-time journey tab load — checking user role');
    _checkUserRole();
  }
}

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanup();
    super.dispose();
  }

  /// Called when app lifecycle changes (tab switch detection)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isInitialized) {
        print('🔄 App minimized or tab switched — resetting session and cleaning up');
        _handleTabSwitch();
        _cleanup();
        _isInitialized = false;
      }

      // ✅ After cleanup, re-check role (role may now be known)
      if (_userRole == UserRole.unknown || !_hasCheckedRole) {
        print('🔍 Role not set or not yet checked — checking again after pause');
        _checkUserRole();
      } else {
        print('♻️ Known user detected (${_userRole.name}) — reinitializing services');
        _initializeServices();
      }
    }
  }


  Future<void> _checkUserRole() async {
    await _determineUserRole();
    _hasCheckedRole = true; // ✅ cache role check

    setState(() {
      _isCheckingRole = false;
    });

    if (_userRole != UserRole.unknown) {
      await _initializeServices();
    } else {
      print('⚠️ Unknown user - Journey not initialized');
    }
  }

  /// Initialize Firebase and motion services only for valid users
  Future<void> _initializeServices() async {
    // Step 1: Reset session when entering this screen
    await BubuDuduService.instance.resetSession();

    // Step 2: Start listening to Firebase session
    await BubuDuduService.instance.startListening();

    // Step 3: Subscribe to session changes
    _sessionSubscription = BubuDuduService.instance.sessionStream.listen(_handleSessionUpdate);

    // Step 4: Start motion detection
    MotionService.instance.startListening(
      onLeftDetected: _handleLeftMovementDetected,
    );

    setState(() {
      _isInitialized = true;
    });

    print('✅ Journey screen initialized - Role: $_userRole');
  }

  Future<void> _determineUserRole() async {
    final nickname = await UserService.getNickname();
    final lowerNickname = nickname?.toLowerCase() ?? '';

    if (['jovi', 'jovilyn', 'jovs'].contains(lowerNickname)) {
      _userRole = UserRole.bubu;
      print('💕 User is BUBU (RIGHT phone)');
    } else if (['almer', 'dave', 'almer dave'].contains(lowerNickname)) {
      _userRole = UserRole.dudu;
      print('💕 User is DUDU (LEFT phone)');
    } else {
      _userRole = UserRole.unknown;
      print('⚠️ Unknown nickname: $lowerNickname - Defaulting to observer mode');
    }
  }

  void _handleSessionUpdate(JourneySession session) {
    print('📡 Session update: ${session.currentState}');

    if (_userRole == UserRole.bubu) {
      _updateBubuState(session);
    } else if (_userRole == UserRole.dudu) {
      _updateDuduState(session);
    }
  }

  void _updateBubuState(JourneySession session) {
    setState(() {
      if (session.currentState == 'idle') {
        _bubuState = BubuState.idle;
      } else if (session.duduReady && !session.bothPhonesMovedLeft) {
        // Dudu clicked "I'm here!" - Get excited and run
        if (_bubuState != BubuState.runningLeft) {
          _bubuState = BubuState.excited;
          SoundService.instance.playSound(SoundType.journeyNotification);
          HapticFeedback.mediumImpact();
          
          // After 1 second, start running
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _bubuState = BubuState.runningLeft;
              });
              SoundService.instance.playSound(SoundType.journeyFootsteps);
            }
          });
        }
      } else if (session.bothPhonesMovedLeft) {
        // Both phones pushed LEFT - Depart!
        _bubuState = BubuState.departed;
        SoundService.instance.playSound(SoundType.journeyWhoosh);
        HapticFeedback.heavyImpact();
        
        // Signal departure to Firebase
        Future.delayed(const Duration(milliseconds: 500), () {
          BubuDuduService.instance.bubuDeparted();
        });
      }
    });
  }

  void _updateDuduState(JourneySession session) {
    setState(() {
      if (session.currentState == 'idle') {
        _duduState = DuduState.idle;
      } else if (session.duduReady && !session.bothPhonesMovedLeft) {
        _duduState = DuduState.ready;
      } else if (session.bothPhonesMovedLeft && !session.bubuDeparted) {
        _duduState = DuduState.waiting;
      } else if (session.bubuDeparted) {
        // Bubu is traveling - Show arriving animation
        _duduState = DuduState.bubuArriving;
        SoundService.instance.playSound(SoundType.journeyWhoosh);
        
        // After 2 seconds, reunion!
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _duduState = DuduState.together;
            });
            BubuDuduService.instance.bubuArrived();
            SoundService.instance.playSound(SoundType.journeyReunion);
            HapticFeedback.heavyImpact();
          }
        });
      }
    });
  }

  void _handleLeftMovementDetected() {
    print('⬅️ LEFT movement detected!');
    
    if (_userRole == UserRole.dudu) {
      BubuDuduService.instance.duduMovedLeft();
    } else if (_userRole == UserRole.bubu) {
      BubuDuduService.instance.bubuMovedLeft();
    }
  }

  Future<void> _handleTabSwitch() async {
    // Full reset for BOTH phones
    await BubuDuduService.instance.resetSession();
    
    // Reset local states
    setState(() {
      _bubuState = BubuState.idle;
      _duduState = DuduState.idle;
    });
  }

  void _cleanup() {
    if (_isInitialized) {
      _sessionSubscription?.cancel();
      BubuDuduService.instance.stopListening();
      MotionService.instance.stopListening();
      print('🧹 Journey services cleaned up');
    }

    // ⚠️ Keep role and _hasCheckedRole cached
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking role
    if (_isCheckingRole) {
      return _buildRoleCheckingScreen();
    }

    // Show unknown user screen if role not recognized (don't initialize services)
    if (_userRole == UserRole.unknown) {
      return _buildUnknownUserScreen();
    }

    // Show loading while initializing services
    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    // Show the journey screen
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: SafeArea(
        child: _userRole == UserRole.bubu ? _buildBubuScreen() : _buildDuduScreen(),
      ),
    );
  }

  Widget _buildRoleCheckingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.deepPurple),
            const SizedBox(height: 24),
            Text(
              'Checking your identity...',
              style: AppTheme.invitationMessage.copyWith(
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.deepPurple),
            const SizedBox(height: 24),
            Text(
              'Preparing the journey...',
              style: AppTheme.invitationMessage.copyWith(
                color: AppTheme.darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknownUserScreen() {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 80, color: AppTheme.deepPurple.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                'Unknown User',
                style: AppTheme.romanticTitle.copyWith(
                  color: AppTheme.deepPurple,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'This journey is for Bubu & Dudu only! 💕',
                textAlign: TextAlign.center,
                style: AppTheme.invitationMessage.copyWith(
                  color: AppTheme.darkText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== BUBU SCREEN (RIGHT PHONE) ====================
  
  Widget _buildBubuScreen() {
    return Column(
      children: [
        _buildHeader('Bubu\'s Phone 🐻'),
        Expanded(
          child: Center(
            child: _buildBubuAnimation(),
          ),
        ),
        _buildStateIndicator(_getBubuStateText()),
      ],
    );
  }

  Widget _buildBubuAnimation() {
    String assetPath;
    
    switch (_bubuState) {
      case BubuState.idle:
        assetPath = JourneyAssets.bubuIdle;
        break;
      case BubuState.excited:
        assetPath = JourneyAssets.bubuExcited;
        break;
      case BubuState.runningLeft:
        assetPath = JourneyAssets.bubuRunningLeft;
        break;
      case BubuState.departed:
        return _buildDepartedAnimation();
    }

    return _buildCharacterImage(assetPath);
  }

  String _getBubuStateText() {
    switch (_bubuState) {
      case BubuState.idle:
        return 'Waiting for Dudu... 💭';
      case BubuState.excited:
        return 'Dudu is here! 😊';
      case BubuState.runningLeft:
        return 'Running to Dudu! 🏃‍♀️💨';
      case BubuState.departed:
        return 'Traveling to Dudu\'s phone... ✨';
    }
  }

  // ==================== DUDU SCREEN (LEFT PHONE) ====================
  
  Widget _buildDuduScreen() {
    return Column(
      children: [
        _buildHeader('Dudu\'s Phone 🐰'),
        Expanded(
          child: Center(
            child: _buildDuduAnimation(),
          ),
        ),
        if (_duduState == DuduState.idle) _buildImHereButton(),
        _buildStateIndicator(_getDuduStateText()),
      ],
    );
  }

  Widget _buildDuduAnimation() {
    String assetPath;
    
    switch (_duduState) {
      case DuduState.idle:
        assetPath = JourneyAssets.duduIdle;
        break;
      case DuduState.ready:
        assetPath = JourneyAssets.duduReady;
        break;
      case DuduState.waiting:
        assetPath = JourneyAssets.duduWaiting;
        break;
      case DuduState.bubuArriving:
        return _buildBubuArrivingAnimation();
      case DuduState.together:
        assetPath = JourneyAssets.together;
        break;
    }

    return _buildCharacterImage(assetPath);
  }

  String _getDuduStateText() {
    switch (_duduState) {
      case DuduState.idle:
        return 'Waiting for you to signal... 💭';
      case DuduState.ready:
        return 'Push both phones LEFT! ⬅️';
      case DuduState.waiting:
        return 'Waiting for Bubu to arrive... 💕';
      case DuduState.bubuArriving:
        return 'Bubu is coming! 🌟';
      case DuduState.together:
        return 'Together at last! 💕✨';
    }
  }

  Widget _buildImHereButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: ElevatedButton(
        onPressed: _onImHerePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.deepPurple,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Text(
              'I\'m here! 💕',
              style: AppTheme.romanticTitle.copyWith(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onImHerePressed() {
    BubuDuduService.instance.duduReady();
    SoundService.instance.playSound(SoundType.journeyNotification);
    HapticFeedback.mediumImpact();
  }

  // ==================== SHARED WIDGETS ====================

  Widget _buildHeader(String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite, color: AppTheme.deepPurple, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTheme.romanticTitle.copyWith(
              color: AppTheme.deepPurple,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterImage(String assetPath) {
    return Image.asset(
      assetPath,
      width: 250,
      height: 250,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to placeholder if GIF not found
        return _buildPlaceholder();
      },
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: AppTheme.primaryLavender.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(
        Icons.image_outlined,
        size: 80,
        color: AppTheme.deepPurple.withOpacity(0.3),
      ),
    );
  }

  Widget _buildDepartedAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(-100 * (1 - opacity), 0),
            child: _buildCharacterImage(JourneyAssets.bubuRunningLeft),
          ),
        );
      },
    );
  }

  Widget _buildBubuArrivingAnimation() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 2),
      builder: (context, progress, child) {
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(300 * (1 - progress), 0),
            child: _buildCharacterImage(JourneyAssets.bubuRunningLeft),
          ),
        );
      },
    );
  }

  Widget _buildStateIndicator(String text) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppTheme.invitationMessage.copyWith(
          color: AppTheme.darkText,
          fontSize: 16,
        ),
      ),
    );
  }
}