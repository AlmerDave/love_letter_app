// lib/animations/floating_hearts.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:love_letter_app/utils/theme.dart';

class FloatingHearts extends StatefulWidget {
  final bool isAnimating;
  final Duration duration;
  final int heartCount;
  final VoidCallback? onComplete;

  const FloatingHearts({
    Key? key,
    required this.isAnimating,
    this.duration = const Duration(milliseconds: 3000),
    this.heartCount = 12,
    this.onComplete,
  }) : super(key: key);

  @override
  State<FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<FloatingHearts>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<HeartParticle> _hearts;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _initializeHearts();

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  void _initializeHearts() {
    final random = math.Random();
    _hearts = List.generate(widget.heartCount, (index) {
      return HeartParticle(
        startX: random.nextDouble(),
        startY: 1.0, // Start from bottom
        endX: random.nextDouble(),
        endY: -0.2, // Float off top
        size: 12.0 + random.nextDouble() * 16.0,
        rotation: random.nextDouble() * 2 * math.pi,
        color: _getRandomHeartColor(random),
        delay: random.nextDouble() * 0.5,
        swayAmplitude: 20 + random.nextDouble() * 40,
        swayFrequency: 1 + random.nextDouble() * 2,
      );
    });
  }

  Color _getRandomHeartColor(math.Random random) {
    final colors = [
      AppTheme.blushPink,
      AppTheme.primaryLavender,
      AppTheme.softGold,
      Colors.red.shade300,
      Colors.pink.shade200,
      Colors.purple.shade200,
    ];
    return colors[random.nextInt(colors.length)];
  }

  @override
  void didUpdateWidget(FloatingHearts oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _startAnimation();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _stopAnimation();
    }
  }

  void _startAnimation() {
    _controller.reset();
    _initializeHearts();
    _controller.forward();
  }

  void _stopAnimation() {
    _controller.stop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isAnimating) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: HeartsPainter(
            hearts: _hearts,
            progress: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class HeartParticle {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double rotation;
  final Color color;
  final double delay;
  final double swayAmplitude;
  final double swayFrequency;

  HeartParticle({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.rotation,
    required this.color,
    required this.delay,
    required this.swayAmplitude,
    required this.swayFrequency,
  });

  Offset getPosition(double progress, Size canvasSize) {
    // Apply delay
    final delayedProgress = (progress - delay).clamp(0.0, 1.0);
    
    if (delayedProgress <= 0) {
      return Offset(startX * canvasSize.width, startY * canvasSize.height);
    }

    // Eased vertical movement
    final easedProgress = Curves.easeOut.transform(delayedProgress);
    final y = startY + (endY - startY) * easedProgress;

    // Horizontal sway
    final swayOffset = math.sin(delayedProgress * swayFrequency * 2 * math.pi) * 
                     swayAmplitude * (1 - delayedProgress);
    final x = startX + (endX - startX) * delayedProgress * 0.3 + 
              swayOffset / canvasSize.width;

    return Offset(
      x * canvasSize.width,
      y * canvasSize.height,
    );
  }

  double getOpacity(double progress) {
    final delayedProgress = (progress - delay).clamp(0.0, 1.0);
    
    if (delayedProgress <= 0) return 0.0;
    if (delayedProgress <= 0.1) return delayedProgress * 10; // Fade in
    if (delayedProgress >= 0.8) return (1.0 - delayedProgress) * 5; // Fade out
    return 1.0;
  }

  double getScale(double progress) {
    final delayedProgress = (progress - delay).clamp(0.0, 1.0);
    
    if (delayedProgress <= 0) return 0.0;
    if (delayedProgress <= 0.2) {
      // Scale up with bounce
      return Curves.elasticOut.transform(delayedProgress * 5);
    }
    return 1.0 - delayedProgress * 0.3; // Gradually shrink
  }
}

class HeartsPainter extends CustomPainter {
  final List<HeartParticle> hearts;
  final double progress;

  HeartsPainter({
    required this.hearts,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final heart in hearts) {
      final position = heart.getPosition(progress, size);
      final opacity = heart.getOpacity(progress);
      final scale = heart.getScale(progress);

      if (opacity <= 0 || scale <= 0) continue;

      final paint = Paint()
        ..color = heart.color.withOpacity(opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(heart.rotation);
      canvas.scale(scale);

      // Draw heart shape
      _drawHeart(canvas, paint, heart.size);

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

    // Add shine effect
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
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
  bool shouldRepaint(HeartsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Utility widget for easy integration
class HeartCelebration extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  const HeartCelebration({
    Key? key,
    required this.child,
    required this.trigger,
    this.onComplete,
  }) : super(key: key);

  @override
  State<HeartCelebration> createState() => _HeartCelebrationState();
}

class _HeartCelebrationState extends State<HeartCelebration> {
  bool _isAnimating = false;

  @override
  void didUpdateWidget(HeartCelebration oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.trigger && !oldWidget.trigger) {
      _startCelebration();
    }
  }

  void _startCelebration() {
    setState(() {
      _isAnimating = true;
    });
  }

  void _onAnimationComplete() {
    setState(() {
      _isAnimating = false;
    });
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: FloatingHearts(
            isAnimating: _isAnimating,
            onComplete: _onAnimationComplete,
          ),
        ),
      ],
    );
  }
}