// lib/games/components/sweater_item.dart
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class SweaterItem extends SpriteComponent {
  static const double spriteSize = 80.0;
  
  @override
  Future<void> onLoad() async {
    // Load sweater sprite
    sprite = await Sprite.load('gift_room/sweater_item.png');
    size = Vector2.all(spriteSize);
    
    // Add a subtle bounce effect when it appears
    add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(
          duration: 0.3,
          reverseDuration: 0.3,
          curve: Curves.elasticOut,
        ),
      ),
    );
  }
}