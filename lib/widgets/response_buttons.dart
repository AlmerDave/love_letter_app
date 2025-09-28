// lib/widgets/response_buttons.dart
import 'package:flutter/material.dart';
import 'package:love_letter_app/utils/theme.dart';

class ResponseButtons extends StatelessWidget {
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ResponseButtons({
    Key? key,
    required this.onAccept,
    required this.onReject,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Accept Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onAccept,
            style: AppTheme.acceptButtonStyle,
            icon: const Icon(Icons.favorite, size: 24),
            label: const Text(
              'Yes, I\'d love to! 💕',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Reject Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: onReject,
            style: AppTheme.rejectButtonStyle,
            icon: const Icon(Icons.close, size: 24),
            label: const Text(
              'Maybe another time...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}