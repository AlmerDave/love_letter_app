// lib/animations/gradient_animations.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/utils/theme.dart';

class AnimatedGradientContainer extends StatefulWidget {
  final Widget child;
  final List<Color> colors;
  final Duration duration;
  final BorderRadius? borderRadius;
  final bool animate;

  const AnimatedGradientContainer({
    Key? key,
    required this.child,
    required this.colors,
    this.duration = const Duration(seconds: 3),
    this.borderRadius,
    this.animate = true,
  }) : super(key: key);

  @override
  State<AnimatedGradientContainer> createState() => _AnimatedGradientContainerState();
}

class _AnimatedGradientContainerState extends State<AnimatedGradientContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: widget.colors,
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        );
      },
    );
  }
}

// Romantic gradient presets
class RomanticGradients {
  static const List<Color> loveGradient = [
    AppTheme.blushPink,
    AppTheme.primaryLavender,
    AppTheme.softGold,
  ];

  static const List<Color> sunsetGradient = [
    Color(0xFFFFB6C1), // Light pink
    Color(0xFFFFD700), // Gold
    Color(0xFFFF69B4), // Hot pink
  ];

  static const List<Color> dreamGradient = [
    AppTheme.primaryLavender,
    AppTheme.warmCream,
    AppTheme.blushPink,
  ];

  static const List<Color> enchantedGradient = [
    Color(0xFFE6E6FA), // Lavender
    Color(0xFFDDA0DD), // Plum
    Color(0xFFFFB6C1), // Light pink
  ];
}

// Floating gradient orbs for background effect
class FloatingGradientOrbs extends StatefulWidget {
  final int orbCount;
  final Duration duration;

  const FloatingGradientOrbs({
    Key? key,
    this.orbCount = 5,
    this.duration = const Duration(seconds: 8),
  }) : super(key: key);

  @override
  State<FloatingGradientOrbs> createState() => _FloatingGradientOrbsState();
}

class _FloatingGradientOrbsState extends State<FloatingGradientOrbs>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.orbCount,
      (index) => AnimationController(
        duration: Duration(
          milliseconds: widget.duration.inMilliseconds + (index * 500),
        ),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<Offset>(
        begin: const Offset(-0.5, 1.5),
        end: const Offset(1.5, -0.5),
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      ));
    }).toList();

    for (var controller in _controllers) {
      controller.repeat();
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: _animations.asMap().entries.map((entry) {
        final index = entry.key;
        final animation = entry.value;
        
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            return Positioned.fill(
              child: FractionalTranslation(
                translation: animation.value,
                child: Container(
                  width: 100 + (index * 20),
                  height: 100 + (index * 20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        RomanticGradients.loveGradient[index % 3].withOpacity(0.1),
                        RomanticGradients.loveGradient[index % 3].withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }
}

// Pulsing gradient border effect
class PulsingGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final List<Color> colors;
  final Duration duration;

  const PulsingGradientBorder({
    Key? key,
    required this.child,
    this.borderWidth = 2.0,
    this.colors = RomanticGradients.loveGradient,
    this.duration = const Duration(milliseconds: 2000),
  }) : super(key: key);

  @override
  State<PulsingGradientBorder> createState() => _PulsingGradientBorderState();
}

class _PulsingGradientBorderState extends State<PulsingGradientBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: widget.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Container(
            margin: EdgeInsets.all(widget.borderWidth),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16 - widget.borderWidth),
              color: Colors.white,
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

// Animated background for the entire app
class RomanticAnimatedBackground extends StatelessWidget {
  final Widget child;

  const RomanticAnimatedBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFFAF6F7),
                Color(0xFFF5F0F3),
              ],
            ),
          ),
        ),
        
        // Floating orbs
        const FloatingGradientOrbs(orbCount: 4),
        
        // Content
        child,
      ],
    );
  }
}