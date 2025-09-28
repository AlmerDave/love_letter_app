// lib/animations/envelope_animation.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/utils/theme.dart';

class EnvelopeAnimation extends StatefulWidget {
  final Invitation invitation;
  final VoidCallback onAnimationComplete;
  final bool autoStart;

  const EnvelopeAnimation({
    Key? key,
    required this.invitation,
    required this.onAnimationComplete,
    this.autoStart = true,
  }) : super(key: key);

  @override
  State<EnvelopeAnimation> createState() => _EnvelopeAnimationState();
}

class _EnvelopeAnimationState extends State<EnvelopeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _envelopeController;
  late AnimationController _sealController;
  late AnimationController _letterController;
  late AnimationController _heartsController;

  // Envelope animations
  late Animation<double> _envelopeFlipAnimation;
  late Animation<double> _envelopeScaleAnimation;

  // Seal breaking animation
  late Animation<double> _sealBreakAnimation;
  late Animation<double> _sealFadeAnimation;

  // Letter reveal animation
  late Animation<double> _letterSlideAnimation;
  late Animation<double> _letterFadeAnimation;

  // Floating hearts animation
  late Animation<double> _heartsAnimation;

  bool _isAnimating = false;
  bool _showLetter = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startOpeningAnimation();
      });
    }
  }

  void _initializeAnimations() {
    // Envelope opening animation (1.5 seconds)
    _envelopeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _envelopeFlipAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _envelopeController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeInOut),
    ));

    _envelopeScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _envelopeController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    ));

    // Seal breaking animation (0.5 seconds)
    _sealController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _sealBreakAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sealController,
      curve: Curves.easeInOut,
    ));

    _sealFadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _sealController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Letter sliding out animation (1.0 seconds) - DELAYED
    _letterController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _letterSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterController,
      curve: Curves.easeOutBack,
    ));

    _letterFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _letterController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    ));

    // Floating hearts animation (2.5 seconds)
    _heartsController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _heartsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _heartsController,
      curve: Curves.easeOut,
    ));
  }

  Future<void> _startOpeningAnimation() async {
    if (_isAnimating) return;
    
    setState(() {
      _isAnimating = true;
    });

    try {
      // Step 1: Scale and prepare envelope (1.5s)
      await _envelopeController.forward();
      
      // Small delay before seal breaks
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Step 2: Break the seal (1.0s)
      await _sealController.forward();
      
      // Delay before letter appears - envelope should be fully open first
      await Future.delayed(const Duration(milliseconds: 400));
      
      // Step 3: Slide letter out (1.2s)
      setState(() {
        _showLetter = true;
      });
      await _letterController.forward();
      
      // Step 4: Show floating hearts
      _heartsController.forward();
      
      // Wait for hearts to finish, then complete
      await Future.delayed(const Duration(milliseconds: 800));
      widget.onAnimationComplete();
      
    } catch (e) {
      // Handle animation errors gracefully
      print('Animation error: $e');
      widget.onAnimationComplete();
    }
  }

  @override
  void dispose() {
    _envelopeController.dispose();
    _sealController.dispose();
    _letterController.dispose();
    _heartsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320, // Slightly taller to accommodate letter
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Floating hearts background
          if (_isAnimating) _buildFloatingHearts(),
          
          // Main envelope
          _buildEnvelope(),
          
          // Letter sliding out - ONLY show when _showLetter is true
          if (_showLetter && _isAnimating) _buildSlidingLetter(),
          
          // Tap instruction - ONLY show if not auto-starting and not animating
          if (!widget.autoStart && !_isAnimating) _buildTapInstruction(),
        ],
      ),
    );
  }

  Widget _buildEnvelope() {
    return GestureDetector(
      onTap: widget.autoStart ? null : _startOpeningAnimation,
      child: AnimatedBuilder(
        animation: _envelopeController,
        builder: (context, child) {
          return Transform.scale(
            scale: _envelopeScaleAnimation.value,
            child: Container(
              width: 250,
              height: 150,
              child: Stack(
                children: [
                  // Envelope base
                  _buildEnvelopeBase(),
                  
                  // Envelope flap (opens)
                  _buildEnvelopeFlap(),
                  
                  // Wax seal
                  _buildWaxSeal(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEnvelopeBase() {
    return Container(
      width: 250,
      height: 150,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppTheme.blushPink.withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
    );
  }

  Widget _buildEnvelopeFlap() {
    return AnimatedBuilder(
      animation: _envelopeFlipAnimation,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.topCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(_envelopeFlipAnimation.value * 3.14159 * 0.8),
          child: Container(
            width: 250,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryLavender.withOpacity(0.9),
                  AppTheme.blushPink.withOpacity(0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaxSeal() {
    return AnimatedBuilder(
      animation: _sealController,
      builder: (context, child) {
        return Positioned(
          top: 60,
          left: 110,
          child: Transform.scale(
            scale: 1.0 + (_sealBreakAnimation.value * 0.2),
            child: Transform.rotate(
              angle: _sealBreakAnimation.value * 0.3,
              child: Opacity(
                opacity: _sealFadeAnimation.value,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.softGold.withOpacity(0.6),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSlidingLetter() {
    return AnimatedBuilder(
      animation: _letterController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -80 * _letterSlideAnimation.value),
          child: Opacity(
            opacity: _letterFadeAnimation.value,
            child: Container(
              width: 180,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.warmCream,
                borderRadius: BorderRadius.circular(8),
                boxShadow: AppTheme.mediumShadow,
                border: Border.all(
                  color: AppTheme.softGold.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.invitation.title,
                      style: AppTheme.romanticTitle.copyWith(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to read full letter...',
                      style: AppTheme.invitationMessage.copyWith(
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                        color: AppTheme.lightText,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.favorite,
                          size: 12,
                          color: AppTheme.blushPink,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDate(widget.invitation.dateTime),
                            style: AppTheme.statusStyle.copyWith(fontSize: 8),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }

  Widget _buildFloatingHearts() {
    return AnimatedBuilder(
      animation: _heartsAnimation,
      builder: (context, child) {
        return Stack(
          children: List.generate(6, (index) {
            final delay = index * 0.2;
            final progress = (_heartsAnimation.value - delay).clamp(0.0, 1.0);
            final xOffset = (index % 2 == 0 ? -1 : 1) * (20 + index * 10);
            
            return Positioned(
              left: 125 + xOffset + (progress * 10),
              bottom: 50 + (progress * 200),
              child: Opacity(
                opacity: (1.0 - progress).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 0.5 + (progress * 0.5),
                  child: Icon(
                    Icons.favorite,
                    color: AppTheme.blushPink.withOpacity(0.8),
                    size: 16 + (index * 2),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildTapInstruction() {
    return Positioned(
      bottom: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.deepPurple.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.touch_app,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Tap to open letter',
              style: AppTheme.invitationMessage.copyWith(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}