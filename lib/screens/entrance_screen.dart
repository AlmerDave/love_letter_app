// lib/screens/entrance_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/screens/main_navigation.dart';
import 'dart:math' as math;

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({Key? key}) : super(key: key);

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen>
    with TickerProviderStateMixin {
  // Password configuration - CHANGE THIS TO YOUR SPECIAL DATE!
  final String correctPassword = "04272024"; // Format: MMDDYYYY (April  27, 2024)
  
  final List<TextEditingController> _controllers = List.generate(8, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());
  
  late AnimationController _heartController;
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late AnimationController _floatingController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _floatingAnimation;
  
  bool _isWrongPassword = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Auto-focus first field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  void _initializeAnimations() {
    _heartController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    
    _shakeAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _floatingAnimation = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _heartController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 7) {
      _focusNodes[index + 1].requestFocus();
    }
    
    // Check if all fields are filled
    if (_controllers.every((controller) => controller.text.isNotEmpty)) {
      _checkPassword();
    }
  }

  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _checkPassword() {
    final enteredPassword = _controllers.map((c) => c.text).join();
    
    if (enteredPassword == correctPassword) {
      _navigateToMainScreen();
    } else {
      _showWrongPassword();
    }
  }

  void _showWrongPassword() {
    setState(() => _isWrongPassword = true);
    _shakeController.forward(from: 0.0);
    
    // Clear all fields after shake animation
    Future.delayed(const Duration(milliseconds: 2000), () {
      for (var controller in _controllers) {
        controller.clear();
      }
      _focusNodes[0].requestFocus();
      setState(() => _isWrongPassword = false);
    });
  }

  void _navigateToMainScreen() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigation(), // ✨ Changed from MainScreen to MainNavigation
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.9, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              ),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryLavender.withOpacity(0.3),
                  AppTheme.warmCream,
                  AppTheme.softBlush.withOpacity(0.4),
                ],
              ),
            ),
          ),

          // Floating hearts - ENHANCED: Infinite looping with AnimationController
          ClipRect(
            child: Stack(
              children: List.generate(15, (index) => FloatingHeart(index: index)),
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Circular photo frame with pulse animation
                      _buildAnimatedPhotoFrame(),
                      const SizedBox(height: 30),

                      // Title with heart emojis
                      AnimatedBuilder(
                        animation: _floatingAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(0, _floatingAnimation.value),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '💕 ',
                              style: TextStyle(fontSize: 28),
                            ),
                            Text(
                              'Made with Love',
                              style: AppTheme.romanticTitle.copyWith(
                                fontSize: 24,
                                color: AppTheme.deepPurple,
                                shadows: [
                                  Shadow(
                                    color: AppTheme.primaryLavender.withOpacity(0.5),
                                    offset: const Offset(0, 3),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              ' 💕',
                              style: TextStyle(fontSize: 28),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter Our Special Date',
                        style: AppTheme.invitationMessage.copyWith(
                          fontSize: 16,
                          color: AppTheme.deepPurple.withOpacity(0.7),
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 40),

                      // Password input container
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              math.sin(_shakeController.value * math.pi * 4) * _shakeAnimation.value,
                              0,
                            ),
                            child: child,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryLavender.withOpacity(0.3),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Date format label
                              Text(
                                'MM - DD - YYYY',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.deepPurple.withOpacity(0.6),
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 18),

                              // Password input fields
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 6,
                                runSpacing: 8,
                                children: [
                                  // MM
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildDigitBox(0),
                                      _buildDigitBox(1),
                                    ],
                                  ),
                                  _buildSeparator(),
                                  // DD
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildDigitBox(2),
                                      _buildDigitBox(3),
                                    ],
                                  ),
                                  _buildSeparator(),
                                  // YYYY
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildDigitBox(4),
                                      _buildDigitBox(5),
                                      _buildDigitBox(6),
                                      _buildDigitBox(7),
                                    ],
                                  ),
                                ],
                              ),

                              if (_isWrongPassword) ...[
                                const SizedBox(height: 18),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade400,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Wrong date! Try again 💔',
                                        style: TextStyle(
                                          color: Colors.red.shade400,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Hint text with emojis
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '✨ Hint: Our Anniversary Date ✨',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.deepPurple.withOpacity(0.5),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    return Container(
      width: 42,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: _isWrongPassword 
            ? Colors.red.shade50
            : AppTheme.primaryLavender.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isWrongPassword
              ? Colors.red.shade300
              : _focusNodes[index].hasFocus
                  ? AppTheme.deepPurple
                  : AppTheme.primaryLavender.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: AppTheme.deepPurple,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) => _onDigitChanged(index, value),
        onTap: () => _controllers[index].selection = TextSelection.fromPosition(
          TextPosition(offset: _controllers[index].text.length),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '-',
        style: TextStyle(
          fontSize: 22,
          color: AppTheme.deepPurple.withOpacity(0.4),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAnimatedPhotoFrame() {
    return AnimatedBuilder(
      animation: _heartController,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (_heartController.value * 0.08),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppTheme.primaryLavender.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.deepPurple.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
                border: Border.all(
                  color: AppTheme.primaryLavender,
                  width: 4,
                ),
              ),
              child: ClipOval(
                child: Container(
                  color: AppTheme.warmCream,
                  child: Image.asset(
                    'assets/images/couple_photo.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.favorite,
                        size: 70,
                        color: AppTheme.deepPurple,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ENHANCED: Separate widget for infinite looping hearts
class FloatingHeart extends StatefulWidget {
  final int index;

  const FloatingHeart({Key? key, required this.index}) : super(key: key);

  @override
  State<FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<FloatingHeart> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late double startX;
  late double size;
  late Color color;
  late double swayAmount;

  @override
  void initState() {
    super.initState();
    final random = math.Random(widget.index);
    
    startX = random.nextDouble();
    size = 15.0 + random.nextDouble() * 25;
    swayAmount = 20 + random.nextDouble() * 20;
    
    color = [
      AppTheme.primaryLavender,
      AppTheme.softBlush,
      AppTheme.deepPurple.withOpacity(0.6),
    ][random.nextInt(3)];
    
    final duration = 3000 + random.nextInt(3000);
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: duration),
    )..repeat(); // Infinite loop!
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: (startX * screenWidth) + 
                (math.sin(_controller.value * 2 * math.pi) * swayAmount),
          bottom: -50 + (_controller.value * (screenHeight + 100)),
          child: Opacity(
            opacity: (1.0 - _controller.value) * 0.6,
            child: Icon(
              Icons.favorite,
              size: size,
              color: color,
            ),
          ),
        );
      },
    );
  }
}