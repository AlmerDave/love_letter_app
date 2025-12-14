// lib/games/components/game_ui.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flame/effects.dart';

class GameUI extends Component {
  late TextComponent interactionPrompt;
  late RectangleComponent completionOverlay;
  late TextComponent completionMessage;
  
  bool _promptVisible = false;
  bool _completionVisible = false;
  
  @override
  Future<void> onLoad() async {
    // Interaction prompt
    interactionPrompt = TextComponent(
      text: '💝 Tap to open gift',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(1, 1),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );
    interactionPrompt.position = Vector2(300, 200);
    interactionPrompt.scale = Vector2.zero(); // Hidden initially
    add(interactionPrompt);
    
    // Completion overlay
    completionOverlay = RectangleComponent(
      size: Vector2(600, 400),
      paint: Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill,
    );
    completionOverlay.position = Vector2(100, 100);
    completionOverlay.scale = Vector2.zero(); // Hidden initially
    add(completionOverlay);
    
    // Completion message
    completionMessage = TextComponent(
      text: 'Some gifts are meant to be\nfelt in real life... 💕\n\nThis moment is yours\nto keep forever',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
    completionMessage.position = Vector2(150, 200);
    completionMessage.scale = Vector2.zero(); // Hidden initially
    add(completionMessage);
  }
  
  /// Show/hide interaction prompt
  void showInteractionPrompt(bool show) {
    if (_promptVisible == show) return;
    
    _promptVisible = show;
    
    if (show) {
      interactionPrompt.add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.3, curve: Curves.elasticOut),
        ),
      );
    } else {
      interactionPrompt.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(duration: 0.2),
        ),
      );
    }
  }
  
  /// Show completion message overlay
  void showCompletionMessage() {
    if (_completionVisible) return;
    
    _completionVisible = true;
    
    // Fade in overlay
    completionOverlay.add(
      ScaleEffect.to(
        Vector2.all(1.0),
        EffectController(duration: 0.5, curve: Curves.easeInOut),
      ),
    );
    
    // Fade in message with delay
    Future.delayed(const Duration(milliseconds: 300), () {
      completionMessage.add(
        ScaleEffect.to(
          Vector2.all(1.0),
          EffectController(duration: 0.8, curve: Curves.elasticOut),
        ),
      );
    });
  }
  
  /// Reset UI elements (for game reset)
  void resetUI() {
    _promptVisible = false;
    _completionVisible = false;
    
    interactionPrompt.scale = Vector2.zero();
    completionOverlay.scale = Vector2.zero();
    completionMessage.scale = Vector2.zero();
  }
}