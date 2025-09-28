// lib/widgets/letter_envelope.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/models/invitation_status.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/utils/bubu_dudu_assets.dart';

class LetterEnvelope extends StatelessWidget {
  final Invitation invitation;
  final VoidCallback onTap;

  const LetterEnvelope({
    Key? key,
    required this.invitation,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                            invitation.title,
                            style: AppTheme.romanticTitle.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            invitation.status.displayName,
                            style: AppTheme.statusStyle.copyWith(
                              color: AppTheme.getStatusColor(invitation.status.name),
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
                if (invitation.isLocked) ...[
                  const SizedBox(height: 8),
                  _buildCountdown(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _getEnvelopeDecoration() {
    if (invitation.isLocked) {
      return AppTheme.lockedEnvelopeDecoration;
    }
    
    switch (invitation.status) {
      case InvitationStatus.accepted:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade100, Colors.green.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.green.shade200),
        );
      case InvitationStatus.rejected:
        return BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red.shade100, Colors.red.shade50],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        );
      default:
        return AppTheme.envelopeDecoration;
    }
  }

  Widget _buildEnvelopeIcon() {
    BubuDuduTheme theme;

    if (invitation.isLocked) {
      theme = BubuDuduTheme.waiting;
    } else {
      switch (invitation.status) {
        case InvitationStatus.pending:
          theme = BubuDuduTheme.mail;
          break;
        case InvitationStatus.accepted:
          theme = BubuDuduTheme.love;
          break;
        case InvitationStatus.rejected:
          theme = BubuDuduTheme.sad;
          break;
        case InvitationStatus.completed:
          theme = BubuDuduTheme.happy;
          break;
        default:
          theme = BubuDuduTheme.mail;
      }
    }

    // Use your custom BubuDuduIcon widget!
    return BubuDuduIcon(theme: theme, size: 32);
  }

  Widget _buildStatusIcon() {
    if (invitation.isLocked) {
      return Icon(
        Icons.schedule,
        color: Colors.grey.shade600,
        size: 20,
      );
    }

    if (invitation.isAvailable) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppTheme.softGold.withOpacity(0.2),
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
          _formatDateTime(invitation.dateTime),
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
            invitation.location,
            style: AppTheme.locationStyle.copyWith(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdown() {
    final timeLeft = invitation.timeUntilUnlock;
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.softGold.withOpacity(0.2),
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