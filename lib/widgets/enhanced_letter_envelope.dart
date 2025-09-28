// lib/widgets/enhanced_letter_envelope.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/models/invitation_status.dart';
import 'package:love_letter_app/utils/theme.dart';

class EnhancedLetterEnvelope extends StatefulWidget {
  final Invitation invitation;
  final VoidCallback onTap;

  const EnhancedLetterEnvelope({
    Key? key,
    required this.invitation,
    required this.onTap,
  }) : super(key: key);

  @override
  State<EnhancedLetterEnvelope> createState() => _EnhancedLetterEnvelopeState();
}

class _EnhancedLetterEnvelopeState extends State<EnhancedLetterEnvelope>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    
    // Hover animation
    _hoverController = AnimationController(
      duration: AppTheme.fastAnimation,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));
    
    _elevationAnimation = Tween<double>(
      begin: 4.0,
      end: 12.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOut,
    ));

    // Pulse animation for available letters
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Shimmer animation for locked letters
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    
    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.linear,
    ));

    _startAppropriateAnimation();
  }

  void _startAppropriateAnimation() {
    if (widget.invitation.isAvailable) {
      // Pulse animation for available letters
      _pulseController.repeat(reverse: true);
    } else if (widget.invitation.isLocked) {
      // Shimmer animation for locked letters
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onHoverStart() {
    setState(() => _isHovered = true);
    _hoverController.forward();
  }

  void _onHoverEnd() {
    setState(() => _isHovered = false);
    _hoverController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _pulseAnimation,
          _shimmerAnimation,
        ]),
        builder: (context, child) {
          double scale = _scaleAnimation.value;
          if (widget.invitation.isAvailable) {
            scale *= _pulseAnimation.value;
          }

          return Transform.scale(
            scale: scale,
            child: Material(
              elevation: _elevationAnimation.value,
              borderRadius: BorderRadius.circular(16),
              child: MouseRegion(
                onEnter: (_) => _onHoverStart(),
                onExit: (_) => _onHoverEnd(),
                child: GestureDetector(
                  onTapDown: (_) => _onHoverStart(),
                  onTapUp: (_) => _onHoverEnd(),
                  onTapCancel: () => _onHoverEnd(),
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(20.0),
                    decoration: _getEnvelopeDecoration(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildEnvelopeIcon(),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.invitation.title,
                                    style: AppTheme.romanticTitle.copyWith(fontSize: 18),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.invitation.status.displayName,
                                    style: AppTheme.statusStyle.copyWith(
                                      color: AppTheme.getStatusColor(widget.invitation.status.name),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusIcon(),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDateTimeInfo(),
                        if (widget.invitation.isLocked) ...[
                          const SizedBox(height: 8),
                          _buildCountdown(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  BoxDecoration _getEnvelopeDecoration() {
    BoxDecoration baseDecoration;
    
    if (widget.invitation.isLocked) {
      baseDecoration = AppTheme.lockedEnvelopeDecoration;
    } else {
      switch (widget.invitation.status) {
        case InvitationStatus.accepted:
          baseDecoration = BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade100, Colors.green.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.green.shade200),
          );
          break;
        case InvitationStatus.rejected:
          baseDecoration = BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red.shade100, Colors.red.shade50],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade200),
          );
          break;
        default:
          baseDecoration = AppTheme.envelopeDecoration;
      }
    }

    // Add shimmer effect for locked letters
    if (widget.invitation.isLocked) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: [
            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      );
    }

    // Add glow effect for available letters
    if (widget.invitation.isAvailable && _isHovered) {
      return baseDecoration.copyWith(
        boxShadow: [
          BoxShadow(
            color: AppTheme.softGold.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
          ...AppTheme.mediumShadow,
        ],
      );
    }

    return baseDecoration;
  }

  Widget _buildEnvelopeIcon() {
    IconData iconData;
    Color iconColor;

    if (widget.invitation.isLocked) {
      iconData = Icons.lock;
      iconColor = Colors.grey.shade600;
    } else {
      switch (widget.invitation.status) {
        case InvitationStatus.pending:
          iconData = Icons.mail;
          iconColor = AppTheme.deepPurple;
          break;
        case InvitationStatus.accepted:
          iconData = Icons.favorite;
          iconColor = Colors.green.shade600;
          break;
        case InvitationStatus.rejected:
          iconData = Icons.heart_broken;
          iconColor = Colors.red.shade600;
          break;
        case InvitationStatus.completed:
          iconData = Icons.check_circle;
          iconColor = Colors.blue.shade600;
          break;
        default:
          iconData = Icons.mail_outline;
          iconColor = AppTheme.lightText;
      }
    }

    return AnimatedContainer(
      duration: AppTheme.fastAnimation,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(_isHovered ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 24),
    );
  }

  Widget _buildStatusIcon() {
    if (widget.invitation.isLocked) {
      return Icon(
        Icons.schedule,
        color: Colors.grey.shade600,
        size: 20,
      );
    }

    if (widget.invitation.isAvailable) {
      return AnimatedContainer(
        duration: AppTheme.fastAnimation,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.softGold.withOpacity(_isHovered ? 0.3 : 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.touch_app,
          color: AppTheme.deepPurple,
          size: 16,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDateTimeInfo() {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 16,
          color: AppTheme.lightText,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDateTime(widget.invitation.dateTime),
          style: AppTheme.locationStyle.copyWith(fontSize: 14),
        ),
        const SizedBox(width: 16),
        Icon(
          Icons.location_on,
          size: 16,
          color: AppTheme.lightText,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.invitation.location,
            style: AppTheme.locationStyle.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    final timeLeft = widget.invitation.timeUntilUnlock;
    String countdownText;

    if (timeLeft.inDays > 0) {
      countdownText = '${timeLeft.inDays}d ${timeLeft.inHours % 24}h remaining';
    } else if (timeLeft.inHours > 0) {
      countdownText = '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m remaining';
    } else if (timeLeft.inMinutes > 0) {
      countdownText = '${timeLeft.inMinutes}m remaining';
    } else {
      countdownText = 'Available now!';
    }

    return AnimatedContainer(
      duration: AppTheme.fastAnimation,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.softGold.withOpacity(_isHovered ? 0.3 : 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            size: 14,
            color: AppTheme.deepPurple,
          ),
          const SizedBox(width: 4),
          Text(
            countdownText,
            style: AppTheme.statusStyle.copyWith(
              color: AppTheme.deepPurple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}