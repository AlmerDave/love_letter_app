// lib/screens/gift_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/games/gift_room_game.dart'; // Import your actual game file

class GiftRoomScreen extends StatefulWidget {
  const GiftRoomScreen({Key? key}) : super(key: key);

  @override
  State<GiftRoomScreen> createState() => _GiftRoomScreenState();
}

class _GiftRoomScreenState extends State<GiftRoomScreen> {
  late GiftRoomGame game;
  bool gameCompleted = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize the game
    game = GiftRoomGame();
    
    // Set up completion callback
    game.onGameCompleted = () {
      setState(() {
        gameCompleted = true;
      });
      
      // Show completion dialog after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _showCompletionDialog();
        }
      });
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "🎁 BB's Room",
          style: AppTheme.romanticTitle.copyWith(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // The game widget
          GameWidget.controlled(gameFactory: () => game),
        ],
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.warmCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '💕 Merry Christmas, bb',
            style: AppTheme.romanticTitle.copyWith(
              fontSize: 22,
              color: AppTheme.deepPurple,
            ),
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "You came into my life like a dream come true, that's why my heart will always choose you",
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.darkText,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLavender.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "The best gifts aren't wrapped in ribbons and bows... they're found in moments like these, where our love grows",
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.deepPurple,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                // Navigator.pop(context); // Go back to more screen
              },
              style: TextButton.styleFrom(
                backgroundColor: AppTheme.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Keep This Memory',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  @override
  void dispose() {
    // Clean up game resources
    game.onGameCompleted = null;
    super.dispose();
  }
}