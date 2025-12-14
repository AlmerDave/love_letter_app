// lib/games/components/gift_giver_character.dart
import 'package:flame/components.dart';

class GiftGiverCharacter extends SpriteAnimationComponent {
  static const double spriteSize = 125.0;
  
  late SpriteAnimation idleWithBoxAnimation;
  late SpriteAnimation openingBoxAnimation;
  late SpriteAnimation idleEmptyAnimation;
  
  bool hasGift = true;
  
  @override
  Future<void> onLoad() async {
    size = Vector2.all(spriteSize);
    position = Vector2(50, 400); // Positioned in room
    
    await _loadAnimations();
    animation = idleWithBoxAnimation;
  }
  
  Future<void> _loadAnimations() async {
    // Load sprite sheets
    final idleWithBoxSprite = await Sprite.load('gift_room/giver_with_box.png');
    final openingBoxSprite = await Sprite.load('gift_room/giver_opening_box.png');
    final idleEmptySprite = await Sprite.load('gift_room/giver_idle_empty.png');
    
    // Create animations
    idleWithBoxAnimation = SpriteAnimation.spriteList(
      [idleWithBoxSprite], 
      stepTime: 1.0
    );
    
    openingBoxAnimation = SpriteAnimation.spriteList(
      [openingBoxSprite], 
      stepTime: 0.5
    );
    
    idleEmptyAnimation = SpriteAnimation.spriteList(
      [idleEmptySprite], 
      stepTime: 1.0
    );
  }
  
  /// Play gift opening animation sequence
  Future<void> openGift() async {
    if (!hasGift) return;
    
    // Switch to opening animation
    animation = openingBoxAnimation;
    
    // Wait for opening animation
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Switch to empty hands
    animation = idleEmptyAnimation;
    hasGift = false;
  }
}