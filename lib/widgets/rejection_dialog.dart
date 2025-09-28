// lib/widgets/rejection_dialog.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/utils/bubu_dudu_assets.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/utils/theme.dart';

class RejectionDialog extends StatelessWidget {
  final Invitation invitation;

  const RejectionDialog({
    Key? key,
    required this.invitation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.warmCream,
              AppTheme.primaryLavender.withOpacity(0.3),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AnimatedBubuDudu(theme: BubuDuduTheme.sad, size: 80),
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Are you sure? 🥺',
              style: AppTheme.romanticTitle.copyWith(
                fontSize: 24,
                color: Colors.red.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Message
            Text(
              'I\'ll be really sad if you say no...\nMaybe you could reconsider?',
              style: AppTheme.invitationMessage.copyWith(
                color: AppTheme.darkText,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            // Reminder of the date details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.blushPink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.blushPink.withOpacity(0.4),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    invitation.title,
                    style: AppTheme.dateTimeStyle.copyWith(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_formatDate(invitation.dateTime)} at ${invitation.location}',
                    style: AppTheme.locationStyle,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            Row(
              children: [
                // Reconsider button (goes back without rejecting)
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade400,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Let me think...',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Still reject button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Sorry, no 😢',
                      style: TextStyle(fontWeight: FontWeight.w100),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${months[dateTime.month - 1]} ${dateTime.day}';
  }
}