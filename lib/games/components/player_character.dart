// lib/games/components/player_character.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

enum PlayerDirection { front, back, left, right }

class PlayerCharacter extends SpriteAnimationComponent {
  static const double speed = 100.0;
  static const double spriteSize = 100.0;
  
  // Directional animations - normal state
  late SpriteAnimation idleFrontAnimation;
  late SpriteAnimation walkFrontAnimation;
  late SpriteAnimation idleBackAnimation;
  late SpriteAnimation walkBackAnimation;
  late SpriteAnimation idleLeftAnimation;
  late SpriteAnimation walkLeftAnimation;
  
  // Sweater animations (front only)
  late SpriteAnimation idleSweaterAnimation;
  late SpriteAnimation walkSweaterAnimation;
  
  Vector2? targetPosition;
  bool isMoving = false;
  bool hasSweater = false;
  PlayerDirection currentDirection = PlayerDirection.front;
  
  @override
  Future<void> onLoad() async {
    size = Vector2.all(spriteSize);
    position = Vector2(300, 700); // Starting position
    anchor = Anchor.center; // ADD THIS LINE - fixes the teleporting issue
    
    await _loadAnimations();
    animation = idleFrontAnimation;
  }
  
  Future<void> _loadAnimations() async {
    try {
      // Load front-facing sprites
      final idleFrontSprite = await Sprite.load('gift_room/player_idle.png');
      final walkFrontSprite1 = await Sprite.load('gift_room/player_walk_1.png');
      final walkFrontSprite2 = await Sprite.load('gift_room/player_walk_2.png');
      
      // Load back-facing sprites
      final idleBackSprite = await Sprite.load('gift_room/player_idle_behind.png');
      final walkBackSprite1 = await Sprite.load('gift_room/player_walking_behind_1.png');
      final walkBackSprite2 = await Sprite.load('gift_room/player_walking_behind_2.png');
      
      // Load left-facing sprites
      final idleLeftSprite = await Sprite.load('gift_room/player_idle_left.png');
      final walkLeftSprite1 = await Sprite.load('gift_room/player_walking_left_1.png');
      final walkLeftSprite2 = await Sprite.load('gift_room/player_walking_left_2.png');
      
      // Load sweater sprite (front only)
      final idleSweaterSprite = await Sprite.load('gift_room/player_idle_sweater.png');
      
      // Create front animations
      idleFrontAnimation = SpriteAnimation.spriteList([idleFrontSprite], stepTime: 1.0);
      walkFrontAnimation = SpriteAnimation.spriteList(
        [walkFrontSprite1, walkFrontSprite2], 
        stepTime: 0.3,
        loop: true,
      );
      
      // Create back animations
      idleBackAnimation = SpriteAnimation.spriteList([idleBackSprite], stepTime: 1.0);
      walkBackAnimation = SpriteAnimation.spriteList(
        [walkBackSprite1, walkBackSprite2], 
        stepTime: 0.3,
        loop: true,
      );
      
      // Create left animations
      idleLeftAnimation = SpriteAnimation.spriteList([idleLeftSprite], stepTime: 1.0);
      walkLeftAnimation = SpriteAnimation.spriteList(
        [walkLeftSprite1, walkLeftSprite2], 
        stepTime: 0.3,
        loop: true,
      );
      
      // Create sweater animations (front only)
      idleSweaterAnimation = SpriteAnimation.spriteList([idleSweaterSprite], stepTime: 1.0);
      walkSweaterAnimation = SpriteAnimation.spriteList(
        [walkFrontSprite1, walkFrontSprite2], // Use front walking sprites with sweater
        stepTime: 0.3,
        loop: true,
      );
      
      print("✅ All player animations loaded successfully");
      
    } catch (e) {
      print("❌ Error loading player animations: $e");
      // Fallback to a basic animation if sprites fail to load
      await _createFallbackAnimations();
    }
  }
  
  Future<void> _createFallbackAnimations() async {
    // Create simple colored rectangle animations as fallback
    try {
      final fallbackSprite = await Sprite.load('gift_room/player_idle.png');
      
      idleFrontAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 1.0);
      walkFrontAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 0.3);
      idleBackAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 1.0);
      walkBackAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 0.3);
      idleLeftAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 1.0);
      walkLeftAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 0.3);
      idleSweaterAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 1.0);
      walkSweaterAnimation = SpriteAnimation.spriteList([fallbackSprite], stepTime: 0.3);
    } catch (e2) {
      print("❌ Complete failure loading sprites: $e2");
    }
  }
  
  /// Determine direction based on movement vector
  PlayerDirection _getDirectionFromMovement(Vector2 direction) {
    // Prioritize vertical movement as requested
    if (direction.y.abs() > 0.3) {
      return direction.y > 0 ? PlayerDirection.front : PlayerDirection.back;
    }
    // Only use horizontal if vertical is minimal
    return direction.x < 0 ? PlayerDirection.left : PlayerDirection.right;
  }
  
  /// Set animation based on direction and state
  void _setAnimationForDirection(PlayerDirection direction, bool walking) {
    currentDirection = direction;
    
    // If player has sweater, always use front-facing animations
    if (hasSweater) {
      animation = walking ? walkSweaterAnimation : idleSweaterAnimation;
      scale.x = 1.0; // No flipping with sweater
      return;
    }
    
    // Normal directional animations
    switch (direction) {
      case PlayerDirection.front:
        animation = walking ? walkFrontAnimation : idleFrontAnimation;
        scale.x = 1.0;
        break;
      case PlayerDirection.back:
        animation = walking ? walkBackAnimation : idleBackAnimation;
        scale.x = 1.0;
        break;
      case PlayerDirection.left:
        animation = walking ? walkLeftAnimation : idleLeftAnimation;
        scale.x = 1.0; // Normal orientation
        break;
      case PlayerDirection.right:
        animation = walking ? walkLeftAnimation : idleLeftAnimation;
        scale.x = -1.0; // Flip horizontally for right direction
        break;
    }
  }
  
  /// Move player to target position with directional animation
  void moveTo(Vector2 target) {
    targetPosition = target.clone();
    isMoving = true;
    
    // Calculate direction and set appropriate walking animation
    final direction = (targetPosition! - position).normalized();
    final facingDirection = _getDirectionFromMovement(direction);
    
    _setAnimationForDirection(facingDirection, true); // true = walking
    
    print("🎯 Player moving ${facingDirection.name} to: $target");
  }
  
  /// Walk to sweater and pick it up (special sequence)
  Future<void> walkToAndPickupSweater(Vector2 sweaterPos) async {
    // Walk to sweater position
    moveTo(sweaterPos);
    
    // Wait until player reaches the sweater
    while (isMoving) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    
    // Brief pause for pickup
    await Future.delayed(const Duration(milliseconds: 300));
  }
  
  /// Equip the sweater (change appearance to front-facing)
  void equipSweater() {
    hasSweater = true;
    currentDirection = PlayerDirection.front; // Force front direction with sweater
    _setAnimationForDirection(PlayerDirection.front, false); // false = idle
    print("👕 Player equipped sweater - now front-facing");
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (isMoving && targetPosition != null) {
      final direction = (targetPosition! - position).normalized();
      final velocity = direction * speed * dt;
      
      // Check if we've reached the target
      if (position.distanceTo(targetPosition!) < 5.0) {
        position = targetPosition!.clone();
        isMoving = false;
        targetPosition = null;
        
        // Switch back to idle animation (keep current direction)
        _setAnimationForDirection(currentDirection, false); // false = idle
      } else {
        position += velocity;
      }
    }
  }
}