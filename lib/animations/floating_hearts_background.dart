// lib/animations/floating_hearts_background.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:love_letter_app/utils/theme.dart';

class FloatingHeartsBackground extends StatefulWidget {
  final Widget child;
  final int heartCount;
  final Duration duration;
  final bool enabled;

  const FloatingHeartsBackground({
    Key? key,
    required this.child,
    this.heartCount = 8,
    this.duration = const Duration(seconds: 12),
    this.enabled = true,
  }) : super(key: key);

  @override
  State<FloatingHeartsBackground> createState() => _FloatingHeartsBackgroundState();
}

class _FloatingHeartsBackgroundState extends State<FloatingHeartsBackground>
    with TickerProviderStateMixin {
  late List<HeartParticleBackground> _hearts;
  late List<BurstHeartParticle> _burstHearts;
  late List<AnimationController> _controllers;
  late List<AnimationController> _burstControllers;

  @override
  void initState() {
    super.initState();
    _initializeHearts();
    _burstHearts = [];
    _burstControllers = [];
  }

void _initializeHearts() {
  final random = math.Random();
  _controllers = [];
  _hearts = [];

  for (int i = 0; i < widget.heartCount; i++) {
    final controller = AnimationController(
      duration: Duration(
        milliseconds: widget.duration.inMilliseconds + random.nextInt(4000),
      ),
      vsync: this,
    );
    
    _controllers.add(controller);
    
    _hearts.add(HeartParticleBackground(
      controller: controller,
      startX: random.nextDouble(),
      startY: 1.1, // ✅ Start slightly closer to screen
      endX: random.nextDouble(),
      endY: -0.1, // ✅ End slightly closer to screen
      size: 10.0 + random.nextDouble() * 16.0, // ✅ Bigger hearts
      opacity: 0.2 + random.nextDouble() * 0.4, // ✅ More visible opacity
      swayAmplitude: 30 + random.nextDouble() * 50,
      color: _getRandomHeartColor(random),
      delay: random.nextDouble() * 2.0, // ✅ Shorter delay
    ));

    // Start with random delay - make it shorter
    Future.delayed(Duration(milliseconds: random.nextInt(1000)), () {
      if (mounted && widget.enabled) {
        controller.repeat();
      }
    });
  }
}

Color _getRandomHeartColor(math.Random random) {
  final colors = [
    AppTheme.blushPink.withOpacity(0.6),        // ✅ More opaque
    AppTheme.primaryLavender.withOpacity(0.5),  // ✅ More opaque
    AppTheme.softGold.withOpacity(0.4),         // ✅ More opaque
    Colors.pink.shade300.withOpacity(0.5),      // ✅ More opaque
    Colors.purple.shade300.withOpacity(0.4),    // ✅ More opaque
    Colors.red.shade200.withOpacity(0.5),       // ✅ Added red hearts
  ];
  return colors[random.nextInt(colors.length)];
}

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var controller in _burstControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return GestureDetector(
      onTapDown: _handleTap,
      child: Stack(
      children: [
        // Background hearts
        Positioned.fill(
          child: CustomPaint(
            painter: FloatingHeartsPainter(
                hearts: _hearts, burstHearts: _burstHearts),
          ),
        ),
        // Content on top
        widget.child,
      ],
      ),
    );
  }

  void _handleTap(TapDownDetails details) {
    final random = math.Random();
    final tapPosition = details.localPosition;
    const burstCount = 7;

    for (int i = 0; i < burstCount; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 1200),
        vsync: this,
      );
      _burstControllers.add(controller);

      final particle = BurstHeartParticle(
        controller: controller,
        startPosition: tapPosition,
        angle: random.nextDouble() * 2 * math.pi,
        speed: 40 + random.nextDouble() * 60,
        size: 6.0 + random.nextDouble() * 8.0,
        color: _getRandomHeartColor(random),
      );
      _burstHearts.add(particle);

      controller.forward().whenComplete(() {
        // Clean up after animation
        if (mounted) {
          setState(() {
            _burstHearts.remove(particle);
            _burstControllers.remove(controller);
            controller.dispose();
          });
        }
      });
    }
  }
}

class HeartParticleBackground {
  final AnimationController controller;
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double opacity;
  final double swayAmplitude;
  final Color color;
  final double delay;

  HeartParticleBackground({
    required this.controller,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.opacity,
    required this.swayAmplitude,
    required this.color,
    required this.delay,
  });

  Offset getPosition(Size canvasSize) {
    final progress = controller.value;
    final delayedProgress = ((progress * 3) - delay).clamp(0.0, 1.0);
    
    if (delayedProgress <= 0) {
      return Offset(startX * canvasSize.width, canvasSize.height + 50);
    }

    // Smooth vertical movement
    final easedProgress = Curves.easeInOut.transform(delayedProgress);
    final y = startY + (endY - startY) * easedProgress;

    // Gentle horizontal sway
    final swayOffset = math.sin(delayedProgress * 2 * math.pi) * 
                     swayAmplitude * (1 - delayedProgress * 0.5);
    final x = startX + (endX - startX) * delayedProgress * 0.2 + 
              swayOffset / canvasSize.width;

    return Offset(
      x * canvasSize.width,
      y * canvasSize.height,
    );
  }

  double getOpacity() {
    final progress = controller.value;
    final delayedProgress = ((progress * 3) - delay).clamp(0.0, 1.0);
    
    if (delayedProgress <= 0) return 0.0;
    if (delayedProgress <= 0.1) return (delayedProgress * 10) * opacity;
    if (delayedProgress >= 0.8) return ((1.0 - delayedProgress) * 5) * opacity;
    return opacity;
  }

  double getScale() {
    final progress = controller.value;
    final delayedProgress = ((progress * 3) - delay).clamp(0.0, 1.0);
    
    if (delayedProgress <= 0) return 0.0;
    if (delayedProgress <= 0.2) {
      return Curves.elasticOut.transform(delayedProgress * 5) * 0.8;
    }
    return 0.8 + (delayedProgress * 0.2); // Slightly grow as it rises
  }
}

class BurstHeartParticle {
  final AnimationController controller;
  final Offset startPosition;
  final double angle;
  final double speed;
  final double size;
  final Color color;

  BurstHeartParticle({
    required this.controller,
    required this.startPosition,
    required this.angle,
    required this.speed,
    required this.size,
    required this.color,
  });

  Offset getPosition() {
    final progress = Curves.easeOut.transform(controller.value);
    final distance = progress * speed;
    
    // Add gravity effect
    final gravity = 50 * progress * progress;

    return Offset(
      startPosition.dx + math.cos(angle) * distance,
      startPosition.dy + math.sin(angle) * distance + gravity,
    );
  }

  double getOpacity() {
    final progress = controller.value;
    if (progress < 0.2) return progress * 5; // Fade in
    return (1.0 - (progress - 0.2) / 0.8).clamp(0.0, 1.0); // Fade out
  }

  double getScale() {
    final progress = controller.value;
    if (progress < 0.3) {
      return Curves.elasticOut.transform(progress / 0.3);
    }
    return (1.0 - (progress - 0.3) / 0.7).clamp(0.0, 1.0); // Shrink
  }
}

class FloatingHeartsPainter extends CustomPainter {
  final List<HeartParticleBackground> hearts;
  final List<BurstHeartParticle> burstHearts;

  FloatingHeartsPainter({
    required this.hearts,
    required this.burstHearts,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final heart in hearts) {
      final position = heart.getPosition(size);
      final opacity = heart.getOpacity();
      final scale = heart.getScale();

      if (opacity <= 0 || scale <= 0) continue;

      final paint = Paint()
        ..color = heart.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.scale(scale);

      // Draw heart shape
      _drawHeart(canvas, paint, heart.size);

      canvas.restore();
    }

    for (final burstHeart in burstHearts) {
      final position = burstHeart.getPosition();
      final opacity = burstHeart.getOpacity();
      final scale = burstHeart.getScale();

      if (opacity <= 0 || scale <= 0) continue;

      final paint = Paint()
        ..color = burstHeart.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.scale(scale);
      _drawHeart(canvas, paint, burstHeart.size);
      canvas.restore();
    }
  }

  void _drawHeart(Canvas canvas, Paint paint, double size) {
    final path = Path();
    final halfSize = size * 0.5;

    // Create heart shape
    path.moveTo(0, halfSize * 0.3);
    
    // Left curve
    path.cubicTo(
      -halfSize * 0.6, -halfSize * 0.3,
      -halfSize, halfSize * 0.1,
      0, halfSize,
    );
    
    // Right curve
    path.cubicTo(
      halfSize, halfSize * 0.1,
      halfSize * 0.6, -halfSize * 0.3,
      0, halfSize * 0.3,
    );

    canvas.drawPath(path, paint);

    // Add subtle shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final shinePath = Path();
    shinePath.moveTo(-halfSize * 0.2, halfSize * 0.1);
    shinePath.cubicTo(
      -halfSize * 0.3, -halfSize * 0.1,
      -halfSize * 0.1, -halfSize * 0.2,
      0, halfSize * 0.2,
    );

    canvas.drawPath(shinePath, shinePaint);
  }

  @override
  bool shouldRepaint(FloatingHeartsPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}

// Enhanced romantic background that combines floating hearts with subtle gradients
class RomanticHeartsBackground extends StatelessWidget {
  final Widget child;
  final bool showHearts;
  final int heartCount;

  const RomanticHeartsBackground({
    Key? key,
    required this.child,
    this.showHearts = true,
    this.heartCount = 8,
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
        
        // Subtle gradient orbs (very faint)
        if (showHearts)
          Positioned.fill(
            child: CustomPaint(
              painter: SubtleOrbsPainter(),
            ),
          ),
        
        // Floating hearts
        FloatingHeartsBackground(
          enabled: showHearts,
          heartCount: heartCount,
          child: child,
        ),
      ],
    );
  }
}

// Very subtle background orbs
class SubtleOrbsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw very subtle orbs at fixed positions
    final orbs = [
      {'x': 0.2, 'y': 0.3, 'size': 100.0, 'color': AppTheme.primaryLavender.withOpacity(0.03)},
      {'x': 0.8, 'y': 0.7, 'size': 80.0, 'color': AppTheme.blushPink.withOpacity(0.02)},
      {'x': 0.6, 'y': 0.2, 'size': 120.0, 'color': AppTheme.softGold.withOpacity(0.01)},
    ];

    for (final orb in orbs) {
      paint.color = orb['color'] as Color;
      canvas.drawCircle(
        Offset(
          (orb['x'] as double) * size.width,
          (orb['y'] as double) * size.height,
        ),
        orb['size'] as double,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}