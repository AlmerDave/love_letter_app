// lib/widgets/invitation_card.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/utils/theme.dart';

class InvitationCard extends StatelessWidget {
  final Invitation invitation;

  const InvitationCard({
    Key? key,
    required this.invitation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: AppTheme.letterCardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Center(
            child: Text(
              invitation.title,
              style: AppTheme.romanticTitle,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Decorative divider
          Center(
            child: Container(
              width: 60,
              height: 2,
              decoration: BoxDecoration(
                gradient: AppTheme.goldGradient,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Message
          Text(
            invitation.message,
            style: AppTheme.invitationMessage,
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Date and Time
          _buildInfoRow(
            icon: Icons.calendar_today,
            label: 'Date & Time',
            value: _formatDateTime(invitation.dateTime),
          ),
          
          const SizedBox(height: 16),
          
          // Location
          _buildInfoRow(
            icon: Icons.location_on,
            label: 'Location',
            value: invitation.location,
          ),
          
          const SizedBox(height: 24),
          
          // Romantic signature
          Center(
            child: Column(
              children: [
                Text(
                  'Love You,',
                  style: AppTheme.locationStyle.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '💕 BB LAAABBBSSS 💕',
                  style: AppTheme.dateTimeStyle.copyWith(
                    color: AppTheme.blushPink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLavender.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryLavender.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.deepPurple,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTheme.statusStyle.copyWith(
                    color: AppTheme.lightText,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTheme.dateTimeStyle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    final month = months[dateTime.month - 1];
    final day = dateTime.day;
    final year = dateTime.year;
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    
    String period = hour >= 12 ? 'PM' : 'AM';
    int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    
    return '$month $day, $year at $displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
}