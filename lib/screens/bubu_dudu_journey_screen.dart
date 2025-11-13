// lib/screens/bubu_dudu_journey_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/utils/journey_assets.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/bubu_dudu_service.dart';
import 'package:love_letter_app/services/sound_service.dart';
import 'package:love_letter_app/models/journey_session.dart';

enum UserRole { bubu, dudu, unknown }

enum BubuState { idle, excited, runningLeft, departed }

enum DuduState { idle, ready, waiting, bubuArriving, reunionAnimation, together }

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
  bool _bubuArrivalSequenceStarted = false;

  StreamSubscription<JourneySession>? _sessionSubscription;
  bool _hasCheckedRole = false;
  bool _isCheckingRole = true;
  bool _isInitialized = false;

  // GIF cycling indices
  int _bubuIdleIndex = 0;
  int _duduIdleIndex = 0;
  int _togetherIndex = 0;

  // Timers for GIF cycling
  Timer? _bubuIdleTimer;
  Timer? _duduIdleTimer;
  Timer? _togetherTimer;

  // Swipe gesture detection
  bool _isSwipeEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (_hasCheckedRole && _userRole != UserRole.unknown) {
      print('🔁 Returning to journey tab — reinitializing services');
      _initializeServices();
    } else {
      print('🆕 First-time journey tab load — checking user role');
      _checkUserRole();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAllTimers();
    _cleanup();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
  }

  void _pauseServices() {
    if (_isInitialized) {
      _stopAllTimers();
      print('⏸️ Services paused');
    }
  }

  void _resumeServices() {
    if (_isInitialized && _userRole != UserRole.unknown) {
      _startAppropriateTimer();
      print('▶️ Services resumed');
    }
  }

  Future<void> _checkUserRole() async {
    await _determineUserRole();
    _hasCheckedRole = true;

    setState(() {
      _isCheckingRole = false;
    });

    if (_userRole != UserRole.unknown) {
      await _initializeServices();
    } else {
      print('⚠️ Unknown user - Journey not initialized');
    }
  }

  Future<void> _initializeServices() async {
    await BubuDuduService.instance.resetSession();
    await BubuDuduService.instance.startListening();
    _sessionSubscription = BubuDuduService.instance.sessionStream.listen(_handleSessionUpdate);

    setState(() {
      _isInitialized = true;
    });

    _startAppropriateTimer();

    // Add this line:
    // SoundService.instance.playJourneyBackgroundMusic();

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
        if (_bubuState != BubuState.idle) {
          _bubuState = BubuState.idle;
          _isSwipeEnabled = false;
          SoundService.instance.stopJourneySound();
          _startBubuIdleTimer();
        }
      } else if (session.duduReady && !session.bothPhonesMovedLeft) {
        if (_bubuState != BubuState.runningLeft) {
          _stopAllTimers();
          _bubuState = BubuState.excited;
          _isSwipeEnabled = true;
          HapticFeedback.mediumImpact();
          
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _bubuState = BubuState.runningLeft;
              });
              SoundService.instance.playJourneySound(SoundType.journeyFootsteps, loop: true);
            }
          });
        }
      } else if (session.bothPhonesMovedLeft) {
        _stopAllTimers();
        _isSwipeEnabled = false;
        _bubuState = BubuState.departed;
        SoundService.instance.stopJourneySound();
        SoundService.instance.playJourneySound(SoundType.journeyWhoosh);
        HapticFeedback.heavyImpact();
        
        Future.delayed(const Duration(milliseconds: 500), () {
          BubuDuduService.instance.bubuDeparted();
        });
      }
    });
  }

  void _updateDuduState(JourneySession session) {
    setState(() {
      if (session.currentState == 'idle') {
        if (_duduState != DuduState.idle) {
          _duduState = DuduState.idle;
          SoundService.instance.stopJourneySound();
          _startDuduIdleTimer();
        }
      } else if (session.duduReady && !session.bothPhonesMovedLeft) {
        _stopAllTimers();
        _duduState = DuduState.ready;
      } else if (session.bothPhonesMovedLeft && !session.bubuDeparted) {
        _stopAllTimers();
        _duduState = DuduState.waiting;
      } else if (session.bubuDeparted) {
        if (_bubuArrivalSequenceStarted) return;
        _bubuArrivalSequenceStarted = true;
        _stopAllTimers();

        _duduState = DuduState.bubuArriving;

        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted) return;

          setState(() {
            _duduState = DuduState.reunionAnimation;
          });
          
          SoundService.instance.playJourneySound(SoundType.journeyReunion, loop: true);

          Future.delayed(const Duration(milliseconds: 1600), () {
            if (!mounted) return;

            setState(() {
              _duduState = DuduState.together;
            });

            BubuDuduService.instance.bubuArrived();
            HapticFeedback.heavyImpact();
            _startTogetherTimer();
          });
        });
      }
    });
  }

  void _handleSwipeLeft() {
    if (!_isSwipeEnabled || _userRole != UserRole.bubu) return;
    
    print('👆 Swipe LEFT detected!');
    BubuDuduService.instance.bubuMovedLeft();
    _isSwipeEnabled = false;
  }

  Future<void> _showResetDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: AppTheme.warmCream,
        title: Column(
          children: [
            Icon(Icons.refresh, color: AppTheme.deepPurple, size: 48),
            const SizedBox(height: 12),
            Text(
              'Reset Journey?',
              style: AppTheme.romanticTitle.copyWith(
                fontSize: 20,
                color: AppTheme.deepPurple,
              ),
            ),
          ],
        ),
        content: Text(
          'This will restart the journey for both phones. 🔄',
          textAlign: TextAlign.center,
          style: AppTheme.invitationMessage.copyWith(
            color: AppTheme.darkText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleManualReset();
    }
  }

  Future<void> _handleManualReset() async {
    _stopAllTimers();
    SoundService.instance.resetJourneySounds();
    SoundService.instance.stopJourneySound();
    SoundService.instance.stopBackgroundMusic();
    await BubuDuduService.instance.resetSession();
    setState(() {
      _bubuState = BubuState.idle;
      _duduState = DuduState.idle;
      _bubuIdleIndex = 0;
      _duduIdleIndex = 0;
      _togetherIndex = 0;
      _bubuArrivalSequenceStarted = false;
      _isSwipeEnabled = false;
    });
    _startAppropriateTimer();
    SoundService.instance.playJourneySound(SoundType.journeyNotification);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Journey reset! 🔄'),
        backgroundColor: AppTheme.deepPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _cleanup() {
    if (_isInitialized) {
      _sessionSubscription?.cancel();
      BubuDuduService.instance.stopListening();
      _stopAllTimers();
      print('🧹 Journey services cleaned up');
    }
  }

  // ==================== TIMER MANAGEMENT ====================

  void _startAppropriateTimer() {
    if (_userRole == UserRole.bubu && _bubuState == BubuState.idle) {
      _startBubuIdleTimer();
    } else if (_userRole == UserRole.dudu) {
      if (_duduState == DuduState.idle) {
        _startDuduIdleTimer();
      } else if (_duduState == DuduState.together) {
        _startTogetherTimer();
      }
    }
  }

  void _startBubuIdleTimer() {
    _bubuIdleTimer?.cancel();
    if (JourneyAssets.bubuIdleGifs.length > 1) {
      _bubuIdleTimer = Timer.periodic(
        Duration(seconds: JourneyAssets.idleGifDuration),
        (timer) {
          if (mounted && _bubuState == BubuState.idle) {
            setState(() {
              _bubuIdleIndex = (_bubuIdleIndex + 1) % JourneyAssets.bubuIdleGifs.length;
            });
          }
        },
      );
    }
  }

  void _startDuduIdleTimer() {
    _duduIdleTimer?.cancel();
    if (JourneyAssets.duduIdleGifs.length > 1) {
      _duduIdleTimer = Timer.periodic(
        Duration(seconds: JourneyAssets.idleGifDuration),
        (timer) {
          if (mounted && _duduState == DuduState.idle) {
            setState(() {
              _duduIdleIndex = (_duduIdleIndex + 1) % JourneyAssets.duduIdleGifs.length;
            });
          }
        },
      );
    }
  }

  void _startTogetherTimer() {
    _togetherTimer?.cancel();
    if (JourneyAssets.togetherGifs.length > 1) {
      _togetherTimer = Timer.periodic(
        Duration(seconds: JourneyAssets.togetherGifDuration),
        (timer) {
          if (mounted && _duduState == DuduState.together) {
            setState(() {
              _togetherIndex = (_togetherIndex + 1) % JourneyAssets.togetherGifs.length;
            });
          }
        },
      );
    }
  }

  void _stopAllTimers() {
    _bubuIdleTimer?.cancel();
    _duduIdleTimer?.cancel();
    _togetherTimer?.cancel();
    _bubuIdleTimer = null;
    _duduIdleTimer = null;
    _togetherTimer = null;
  }

  // ==================== BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRole) {
      return _buildRoleCheckingScreen();
    }

    if (_userRole == UserRole.unknown) {
      return _buildUnknownUserScreen();
    }

    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

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
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
          _handleSwipeLeft();
        }
      },
      child: Column(
        children: [
          _buildHeader('Bubu\'s Phone'),
          Expanded(
            child: Center(
              child: _buildBubuAnimation(),
            ),
          ),
          _buildStateIndicator(_getBubuStateText()),
        ],
      ),
    );
  }

  Widget _buildBubuAnimation() {
    String assetPath;
    
    switch (_bubuState) {
      case BubuState.idle:
        assetPath = JourneyAssets.bubuIdleGifs[_bubuIdleIndex];
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
        return 'Swipe LEFT to go to Dudu! 👆⬅️';
      case BubuState.departed:
        return 'Traveling to Dudu\'s phone... ✨';
    }
  }

  // ==================== DUDU SCREEN (LEFT PHONE) ====================
  
  Widget _buildDuduScreen() {
    return Column(
      children: [
        _buildHeader('Dudu\'s Phone'),
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
        assetPath = JourneyAssets.duduIdleGifs[_duduIdleIndex];
        break;
      case DuduState.ready:
        assetPath = JourneyAssets.duduReady;
        break;
      case DuduState.waiting:
        assetPath = JourneyAssets.duduWaiting;
        break;
      case DuduState.bubuArriving:
        return _buildBubuArrivingAnimation();
      case DuduState.reunionAnimation:
        assetPath = JourneyAssets.reunionAnimation;
        break;
      case DuduState.together:
        assetPath = JourneyAssets.togetherGifs[_togetherIndex];
        break;
    }

    return _buildCharacterImage(assetPath);
  }

  String _getDuduStateText() {
    switch (_duduState) {
      case DuduState.idle:
        return 'Waiting for you to signal... 💭';
      case DuduState.ready:
        return 'Waiting for Bubu to swipe... 💕';
      case DuduState.waiting:
        return 'Waiting for Bubu to arrive... 💕';
      case DuduState.bubuArriving:
        return 'Bubu is coming! 🌟';
      case DuduState.reunionAnimation:
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
    BubuDuduService.instance.duduMovedLeft();
    SoundService.instance.playJourneySound(SoundType.journeyImhere);
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 40),
          Row(
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
          IconButton(
            icon: Icon(Icons.refresh, color: AppTheme.deepPurple),
            onPressed: _showResetDialog,
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
            child: _buildCharacterImage(JourneyAssets.bubuArriving),
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