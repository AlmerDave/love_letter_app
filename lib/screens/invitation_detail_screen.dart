// lib/screens/invitation_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/models/invitation_status.dart';
import 'package:love_letter_app/services/storage_service.dart';
import 'package:love_letter_app/widgets/invitation_card.dart';
import 'package:love_letter_app/services/sound_service.dart';
import 'package:love_letter_app/widgets/response_buttons.dart';
import 'package:love_letter_app/widgets/rejection_dialog.dart';
import 'package:love_letter_app/animations/envelope_animation.dart';
import 'package:love_letter_app/animations/floating_hearts.dart';
import 'package:love_letter_app/utils/bubu_dudu_assets.dart';
import 'package:love_letter_app/utils/theme.dart';

class InvitationDetailScreen extends StatefulWidget {
  final Invitation invitation;

  const InvitationDetailScreen({
    Key? key,
    required this.invitation,
  }) : super(key: key);

  @override
  State<InvitationDetailScreen> createState() => _InvitationDetailScreenState();
}

class _InvitationDetailScreenState extends State<InvitationDetailScreen> {
  late Invitation _currentInvitation;
  bool _isUpdating = false;
  bool _showEnvelopeAnimation = true;
  bool _showHeartCelebration = false;
  bool _showContent = false; // ✅ NEW: Controls when to show the invitation card

  @override
  void initState() {
    super.initState();
    _currentInvitation = widget.invitation;
  }

  Future<void> _handleAccept() async {
    setState(() => _isUpdating = true);

    try {
      final success = await StorageService.instance.updateInvitationStatus(
        _currentInvitation.id,
        InvitationStatus.accepted,
      );

      if (success) {
        setState(() {
          _currentInvitation = _currentInvitation.copyWith(
            status: InvitationStatus.accepted,
          );
          SoundService.instance.playSound(SoundType.accepted);
          _showHeartCelebration = true; // 🎉 Trigger beautiful heart animation!
        });
        
        _showSuccessMessage('Invitation accepted! 💕');
        
        // Wait for heart animation to complete before going back
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorMessage('Failed to accept invitation');
      }
    } catch (e) {
      _showErrorMessage('Error accepting invitation');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _handleReject() async {
    // Show the cute "Are you sure?" dialog first
    final shouldReject = await _showRejectionDialog();
    if (!shouldReject) return;

    setState(() => _isUpdating = true);

    try {
      final success = await StorageService.instance.updateInvitationStatus(
        _currentInvitation.id,
        InvitationStatus.rejected,
      );

      if (success) {
        setState(() {
          _currentInvitation = _currentInvitation.copyWith(
            status: InvitationStatus.rejected,
          );
          SoundService.instance.playSound(SoundType.letterRejected);
        });
        
        _showErrorMessage('Maybe reconsider? 🥺');
        
        // Wait a moment then go back
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        _showErrorMessage('Failed to reject invitation');
      }
    } catch (e) {
      _showErrorMessage('Error rejecting invitation');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  Future<bool> _showRejectionDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RejectionDialog(
        invitation: _currentInvitation,
      ),
    );
    return result ?? false;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get _canRespond {
    return _currentInvitation.status == InvitationStatus.pending ||
           _currentInvitation.status == InvitationStatus.rejected;
  }

  @override
  Widget build(BuildContext context) {
    return HeartCelebration(
      trigger: _showHeartCelebration,
      onComplete: () {
        setState(() {
          _showHeartCelebration = false;
        });
      },
      child: Scaffold(
        backgroundColor: AppTheme.warmCream.withOpacity(0.3),
        appBar: AppBar(
          title: const Text('Love Letter'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, false),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ✨ MAGICAL ENVELOPE ANIMATION (New in Phase 2!)
                  if (_showEnvelopeAnimation)
                    EnvelopeAnimation(
                      invitation: _currentInvitation,
                      onAnimationComplete: () {
                        setState(() {
                          _showEnvelopeAnimation = false;
                          _showContent = true; // ✅ Show content AFTER animation
                        });
                      },
                    )
                  else
                    _buildSimpleHeader(),
                  
                  // ✅ ONLY show content after envelope animation completes
                  if (_showContent) ...[
                    const SizedBox(height: 24),
                    
                    // Beautiful invitation content card
                    InvitationCard(invitation: _currentInvitation),
                    
                    const SizedBox(height: 32),
                    
                    // Response buttons (if user can respond)
                    if (_canRespond && !_isUpdating)
                      ResponseButtons(
                        onAccept: _handleAccept,
                        onReject: _handleReject,
                      ),
                    
                    // Loading indicator
                    if (_isUpdating)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: CircularProgressIndicator(),
                      ),
                    
                    // Status message for completed invitations
                    if (!_canRespond)
                      _buildStatusMessage(),
                  ],
                  
                  // Extra bottom padding to prevent overflow
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Simple header shown after envelope animation completes
  Widget _buildSimpleHeader() {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBubuDudu(theme: _getStatusTheme(), size: 80),
          const SizedBox(height: 12),
          Text(
            _getStatusText(),
            style: AppTheme.invitationMessage.copyWith(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Status message for letters that can't be responded to
  Widget _buildStatusMessage() {
    String message;
    Color color;

    switch (_currentInvitation.status) {
      case InvitationStatus.accepted:
        message = 'You accepted this invitation 😎👌🔥! Looking forward to our date 💕😘';
        color = Colors.green.shade600;
        break;
      case InvitationStatus.completed:
        message = 'Yieeeee nag rerecall kaa! 💕😘';
        color = Colors.blue.shade600;
        break;
      default:
        message = 'This invitation has already been responded to. ⏳';
        color = AppTheme.lightText;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: AppTheme.invitationMessage.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get appropriate Bubu & Dudu theme based on status
  BubuDuduTheme _getStatusTheme() {
    switch (_currentInvitation.status) {
      case InvitationStatus.pending:
        return BubuDuduTheme.mail;
      case InvitationStatus.accepted:
        return BubuDuduTheme.love;
      case InvitationStatus.rejected:
        return BubuDuduTheme.sad;
      case InvitationStatus.completed:
        return BubuDuduTheme.happy;
      default:
        return BubuDuduTheme.mail;
    }
  }

  // Get appropriate text based on status
  String _getStatusText() {
    switch (_currentInvitation.status) {
      case InvitationStatus.pending:
        return 'Letter Opened';
      case InvitationStatus.accepted:
        return 'Accepted with Love';
      case InvitationStatus.rejected:
        return 'Needs Reconsideration';
      case InvitationStatus.completed:
        return 'Beautiful Memory';
      default:
        return 'Love Letter';
    }
  }
}