// lib/utils/bubu_dudu_assets.dart
import 'package:flutter/material.dart';

/// 💕 Bubu & Dudu Asset Template System
/// This makes it super easy to add your girlfriend's favorite characters!
class BubuDuduAssets {
  
  // 📁 STEP 1: Add your Bubu & Dudu images to assets/images/bubu_dudu/
  // Recommended image names:
  static const String _basePath = 'assets/images/bubu_dudu/';
  
  // 💕 Romantic & Love themed images
  static const String bubuLove = '${_basePath}bubu_love.jpg';           // Bubu with hearts
  static const String duduLove = '${_basePath}dudu_love.jpg';           // Dudu with hearts
  static const String bubuDuduKiss = '${_basePath}bubu_dudu_kiss.jpg';  // Kissing scene
  static const String bubuDuduHug = '${_basePath}bubu_dudu_hug.jpg';    // Hugging scene
  
  // 😊 Happy & Excited expressions
  static const String bubuHappy = '${_basePath}bubu_happy.jpg';         // Happy Bubu
  static const String duduHappy = '${_basePath}dudu_happy.jpg';         // Happy Dudu
  static const String bubuExcited = '${_basePath}bubu_excited.jpg';     // Excited Bubu
  static const String duduExcited = '${_basePath}dudu_excited.jpg';     // Excited Dudu
  
  // 🥺 Sad & Pleading expressions (for rejection dialog)
  static const String bubuSad = '${_basePath}bubu_sad.jpg';             // Sad Bubu
  static const String duduSad = '${_basePath}dudu_sad.jpg';             // Sad Dudu
  static const String bubuPleading = '${_basePath}bubu_pleading.jpg';   // Pleading eyes
  static const String duduPleading = '${_basePath}dudu_pleading.jpg';   // Pleading eyes
  
  // 🎉 Celebration & Special occasions
  static const String bubuCelebrate = '${_basePath}bubu_celebrate.png'; // Celebrating
  static const String duduCelebrate = '${_basePath}dudu_celebrate.png'; // Celebrating
  static const String bubuDuduParty = '${_basePath}bubu_dudu_party.png'; // Party together
  
  // 💌 Letter & Mail themed
  static const String bubuMail = '${_basePath}bubu_mail.jpg';           // Bubu with letter
  static const String duduMail = '${_basePath}dudu_mail.jpg';           // Dudu with letter
  static const String bubuDuduLetter = '${_basePath}bubu_dudu_letter.jpg'; // Reading letter together
  
  // 🔒 Waiting & Time-locked themed
  static const String bubuWaiting = '${_basePath}bubu_waiting.jpg';     // Waiting patiently
  static const String duduWaiting = '${_basePath}dudu_waiting.jpg';     // Waiting patiently
  static const String bubuDuduClock = '${_basePath}bubu_dudu_clock.jpg'; // With clock/time
  
  // 🎭 Helper method to safely load images with fallback
  static Widget safeImage({
    required String assetPath,
    required IconData fallbackIcon,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    Color? fallbackColor,
  }) {
    return Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image not found
        return Icon(
          fallbackIcon,
          size: width ?? height ?? 24,
          color: fallbackColor,
        );
      },
    );
  }
  
  // 🎨 Get themed Bubu/Dudu image based on context
  static Widget getThemedImage({
    required BubuDuduTheme theme,
    double size = 40,
    BoxFit fit = BoxFit.contain,
  }) {
    String assetPath;
    IconData fallbackIcon;
    
    switch (theme) {
      case BubuDuduTheme.love:
        assetPath = bubuDuduKiss;
        fallbackIcon = Icons.favorite;
        break;
      case BubuDuduTheme.happy:
        assetPath = bubuDuduHug;
        fallbackIcon = Icons.sentiment_very_satisfied;
        break;
      case BubuDuduTheme.sad:
        assetPath = bubuSad;
        fallbackIcon = Icons.sentiment_very_dissatisfied;
        break;
      case BubuDuduTheme.excited:
        assetPath = bubuExcited;
        fallbackIcon = Icons.celebration;
        break;
      case BubuDuduTheme.mail:
        assetPath = bubuMail;
        fallbackIcon = Icons.mail;
        break;
      case BubuDuduTheme.waiting:
        assetPath = bubuWaiting;
        fallbackIcon = Icons.access_time;
        break;
      case BubuDuduTheme.celebrate:
        assetPath = bubuCelebrate;
        fallbackIcon = Icons.party_mode;
        break;
    }
    
    return safeImage(
      assetPath: assetPath,
      fallbackIcon: fallbackIcon,
      width: size,
      height: size,
      fit: fit,
    );
  }
}

// 🎭 Theme enum for different contexts
enum BubuDuduTheme {
  love,        // For accepted invitations, romantic moments
  happy,       // For general positive states
  sad,         // For rejection dialog, sad moments
  excited,     // For available letters, celebrations
  mail,        // For letter/envelope contexts
  waiting,     // For locked letters, countdown
  celebrate,   // For special occasions, achievements
}

// 💕 Easy-to-use Bubu & Dudu widgets
class BubuDuduIcon extends StatelessWidget {
  final BubuDuduTheme theme;
  final double size;
  final BoxFit fit;

  const BubuDuduIcon({
    Key? key,
    required this.theme,
    this.size = 40,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BubuDuduAssets.getThemedImage(
      theme: theme,
      size: size,
      fit: fit,
    );
  }
}

// 🎪 Animated Bubu & Dudu widget with cute effects
class AnimatedBubuDudu extends StatefulWidget {
  final BubuDuduTheme theme;
  final double size;
  final bool animate;

  const AnimatedBubuDudu({
    Key? key,
    required this.theme,
    this.size = 60,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AnimatedBubuDudu> createState() => _AnimatedBubuDuduState();
}

class _AnimatedBubuDuduState extends State<AnimatedBubuDudu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticInOut,
    ));

    if (widget.animate) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return BubuDuduIcon(theme: widget.theme, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: BubuDuduIcon(theme: widget.theme, size: widget.size),
        );
      },
    );
  }
}