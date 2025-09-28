// lib/utils/bubu_dudu_assets.dart
import 'package:flutter/material.dart';
import 'dart:math';

/// 💕 Bubu & Dudu Asset Template System with Random Selection
/// This makes it super easy to add your girlfriend's favorite characters!
/// Now with random image picking for variety! 🎲
class BubuDuduAssets {
  
  // 📁 STEP 1: Add your Bubu & Dudu images to assets/images/bubu_dudu/
  // Recommended image names:
  static const String _basePath = 'assets/images/bubu_dudu/';
  
  // 🎲 Random number generator for image selection
  static final Random _random = Random();
  
  // 💕 Romantic & Love themed images (multiple options)
  static const List<String> _loveImages = [
    '${_basePath}bubu_love.jpg',           // Bubu with hearts
    '${_basePath}dudu_love.png',           // Dudu with hearts
    '${_basePath}bubu_dudu_kiss.jpg',      // Kissing scene
    '${_basePath}bubu_dudu_hug.gif',       // Hugging scene
  ];
  
  // 😊 Happy & Excited expressions (multiple options)
  static const List<String> _happyImages = [
    '${_basePath}bubu_happy.jpg',          // Happy Bubu
    '${_basePath}dudu_happy.gif',          // Happy Dudu
  ];
  
  static const List<String> _excitedImages = [
    '${_basePath}bubu_excited.png',        // Excited Bubu
    '${_basePath}dudu_excited.png',        // Excited Dudu
    '${_basePath}bubu_celebrate.png',      // Celebrating Bubu
    '${_basePath}dudu_celebrate.jpg',      // Celebrating Dudu
  ];
  
  // 🥺 Sad & Pleading expressions (multiple options)
  static const List<String> _sadImages = [
    '${_basePath}bubu_sad.jpg',            // Sad Bubu
    '${_basePath}dudu_sad.gif',            // Sad Dudu
    '${_basePath}bubu_pleading.jpg',       // Pleading eyes Bubu
    '${_basePath}dudu_pleading.png',       // Pleading eyes Dudu
  ];
  
  // 🎉 Celebration & Special occasions (multiple options)
  static const List<String> _celebrateImages = [
    '${_basePath}bubu_celebrate.png',      // Celebrating Bubu
    '${_basePath}dudu_celebrate.jpg',      // Celebrating Dudu
    '${_basePath}bubu_dudu_party.gif',     // Party together
    '${_basePath}bubu_excited.png',        // Also can be celebratory
    '${_basePath}dudu_excited.png',        // Also can be celebratory
  ];
  
  // 💌 Letter & Mail themed (multiple options)
  static const List<String> _mailImages = [
    '${_basePath}bubu_mail.png',           // Bubu with letter
    '${_basePath}dudu_mail.png',           // Dudu with letter
    '${_basePath}bubu_dudu_letter.png',    // Reading letter together
  ];
  
  // 🔒 Waiting & Time-locked themed (multiple options)
  static const List<String> _waitingImages = [
    '${_basePath}bubu_waiting.gif',        // Waiting patiently Bubu
    '${_basePath}dudu_waiting.gif',        // Waiting patiently Dudu
    '${_basePath}bubu_dudu_clock.gif',     // With clock/time
  ];

  // 🎲 RANDOM SELECTION METHODS
  
  /// Get a random love-themed image
  static String getRandomLoveImage() {
    return _loveImages[_random.nextInt(_loveImages.length)];
  }
  
  /// Get a random happy-themed image
  static String getRandomHappyImage() {
    return _happyImages[_random.nextInt(_happyImages.length)];
  }
  
  /// Get a random excited-themed image
  static String getRandomExcitedImage() {
    return _excitedImages[_random.nextInt(_excitedImages.length)];
  }
  
  /// Get a random sad-themed image
  static String getRandomSadImage() {
    return _sadImages[_random.nextInt(_sadImages.length)];
  }
  
  /// Get a random celebration-themed image
  static String getRandomCelebrateImage() {
    return _celebrateImages[_random.nextInt(_celebrateImages.length)];
  }
  
  /// Get a random mail-themed image
  static String getRandomMailImage() {
    return _mailImages[_random.nextInt(_mailImages.length)];
  }
  
  /// Get a random waiting-themed image
  static String getRandomWaitingImage() {
    return _waitingImages[_random.nextInt(_waitingImages.length)];
  }

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
  
  // 🎨 Get randomly themed Bubu/Dudu image based on context
  static Widget getThemedImage({
    required BubuDuduTheme theme,
    double size = 40,
    BoxFit fit = BoxFit.contain,
  }) {
    String assetPath;
    IconData fallbackIcon;
    
    switch (theme) {
      case BubuDuduTheme.love:
        assetPath = getRandomLoveImage();
        fallbackIcon = Icons.favorite;
        break;
      case BubuDuduTheme.happy:
        assetPath = getRandomHappyImage();
        fallbackIcon = Icons.sentiment_very_satisfied;
        break;
      case BubuDuduTheme.sad:
        assetPath = getRandomSadImage();
        fallbackIcon = Icons.sentiment_very_dissatisfied;
        break;
      case BubuDuduTheme.excited:
        assetPath = getRandomExcitedImage();
        fallbackIcon = Icons.celebration;
        break;
      case BubuDuduTheme.mail:
        assetPath = getRandomMailImage();
        fallbackIcon = Icons.mail;
        break;
      case BubuDuduTheme.waiting:
        assetPath = getRandomWaitingImage();
        fallbackIcon = Icons.access_time;
        break;
      case BubuDuduTheme.celebrate:
        assetPath = getRandomCelebrateImage();
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

  // 🎯 NEW: Get specific character image (if you want to choose Bubu or Dudu specifically)
  static Widget getBubuImage({
    required BubuDuduTheme theme,
    double size = 40,
    BoxFit fit = BoxFit.contain,
  }) {
    String assetPath;
    IconData fallbackIcon;
    
    switch (theme) {
      case BubuDuduTheme.love:
        assetPath = '${_basePath}bubu_love.jpg';
        fallbackIcon = Icons.favorite;
        break;
      case BubuDuduTheme.happy:
        assetPath = '${_basePath}bubu_happy.jpg';
        fallbackIcon = Icons.sentiment_very_satisfied;
        break;
      case BubuDuduTheme.sad:
        assetPath = '${_basePath}bubu_sad.jpg';
        fallbackIcon = Icons.sentiment_very_dissatisfied;
        break;
      case BubuDuduTheme.excited:
        assetPath = '${_basePath}bubu_excited.png';
        fallbackIcon = Icons.celebration;
        break;
      case BubuDuduTheme.mail:
        assetPath = '${_basePath}bubu_mail.png';
        fallbackIcon = Icons.mail;
        break;
      case BubuDuduTheme.waiting:
        assetPath = '${_basePath}bubu_waiting.png';
        fallbackIcon = Icons.access_time;
        break;
      case BubuDuduTheme.celebrate:
        assetPath = '${_basePath}bubu_celebrate.png';
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

  static Widget getDuduImage({
    required BubuDuduTheme theme,
    double size = 40,
    BoxFit fit = BoxFit.contain,
  }) {
    String assetPath;
    IconData fallbackIcon;
    
    switch (theme) {
      case BubuDuduTheme.love:
        assetPath = '${_basePath}dudu_love.png';
        fallbackIcon = Icons.favorite;
        break;
      case BubuDuduTheme.happy:
        assetPath = '${_basePath}dudu_happy.gif';
        fallbackIcon = Icons.sentiment_very_satisfied;
        break;
      case BubuDuduTheme.sad:
        assetPath = '${_basePath}dudu_sad.gif';
        fallbackIcon = Icons.sentiment_very_dissatisfied;
        break;
      case BubuDuduTheme.excited:
        assetPath = '${_basePath}dudu_excited.png';
        fallbackIcon = Icons.celebration;
        break;
      case BubuDuduTheme.mail:
        assetPath = '${_basePath}dudu_mail.png';
        fallbackIcon = Icons.mail;
        break;
      case BubuDuduTheme.waiting:
        assetPath = '${_basePath}dudu_waiting.gif';
        fallbackIcon = Icons.access_time;
        break;
      case BubuDuduTheme.celebrate:
        assetPath = '${_basePath}dudu_celebrate.jpg';
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

  // 🎲 NEW: Get a random character (Bubu or Dudu) for a theme
  static Widget getRandomCharacterImage({
    required BubuDuduTheme theme,
    double size = 40,
    BoxFit fit = BoxFit.contain,
  }) {
    // Randomly choose between Bubu and Dudu
    bool chooseBubu = _random.nextBool();
    
    if (chooseBubu) {
      return getBubuImage(theme: theme, size: size, fit: fit);
    } else {
      return getDuduImage(theme: theme, size: size, fit: fit);
    }
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

// 💕 Easy-to-use Bubu & Dudu widgets with random selection
class BubuDuduIcon extends StatelessWidget {
  final BubuDuduTheme theme;
  final double size;
  final BoxFit fit;
  final bool useRandomSelection;

  const BubuDuduIcon({
    Key? key,
    required this.theme,
    this.size = 40,
    this.fit = BoxFit.contain,
    this.useRandomSelection = true, // 🎲 Default to random!
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (useRandomSelection) {
      return BubuDuduAssets.getThemedImage(
        theme: theme,
        size: size,
        fit: fit,
      );
    } else {
      // Fallback to first image in each category
      return BubuDuduAssets.getRandomCharacterImage(
        theme: theme,
        size: size,
        fit: fit,
      );
    }
  }
}

// 🎪 Animated Bubu & Dudu widget with cute effects and random selection
class AnimatedBubuDudu extends StatefulWidget {
  final BubuDuduTheme theme;
  final double size;
  final bool animate;
  final bool useRandomSelection;

  const AnimatedBubuDudu({
    Key? key,
    required this.theme,
    this.size = 60,
    this.animate = true,
    this.useRandomSelection = true, // 🎲 Default to random!
  }) : super(key: key);

  @override
  State<AnimatedBubuDudu> createState() => _AnimatedBubuDuduState();
}

class _AnimatedBubuDuduState extends State<AnimatedBubuDudu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;
  late Widget _selectedImage; // 🔒 Store the selected image to prevent changing

  @override
  void initState() {
    super.initState();
    
    // 🔒 Select the image ONCE during initialization
    _selectedImage = BubuDuduIcon(
      theme: widget.theme, 
      size: widget.size,
      useRandomSelection: widget.useRandomSelection,
    );
    
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
      return _selectedImage; // 🔒 Use the pre-selected image
    }

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: _selectedImage, // 🔒 Always use the same selected image
        );
      },
    );
  }
}

// 🎲 NEW: Special widgets for specific character selection
class BubuIcon extends StatelessWidget {
  final BubuDuduTheme theme;
  final double size;
  final BoxFit fit;

  const BubuIcon({
    Key? key,
    required this.theme,
    this.size = 40,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BubuDuduAssets.getBubuImage(
      theme: theme,
      size: size,
      fit: fit,
    );
  }
}

class DuduIcon extends StatelessWidget {
  final BubuDuduTheme theme;
  final double size;
  final BoxFit fit;

  const DuduIcon({
    Key? key,
    required this.theme,
    this.size = 40,
    this.fit = BoxFit.contain,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BubuDuduAssets.getDuduImage(
      theme: theme,
      size: size,
      fit: fit,
    );
  }
}