// lib/games/gift_room_game.dart
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
// Import your sound service
import '../services/sound_service.dart';
// Import the sprite-based components
import 'components/player_character.dart';
import 'components/gift_giver_character.dart';
import 'components/sweater_item.dart';

enum GameState {
  playing,
  nearGift,
  openingGift,
  completed,
}

class GiftRoomGame extends FlameGame with TapCallbacks {
  late PlayerCharacter player;
  late GiftGiverCharacter giftGiver;
  late RoomWorld roomWorld;
  late GameUI gameUI;
  
  SweaterItem? sweaterItem;
  GameState gameState = GameState.playing;
  
  // Track if proximity chime was already played
  bool _proximityChimePlayed = false;
  
  // Callback for game completion
  VoidCallback? onGameCompleted;
  
  @override
  Future<void> onLoad() async {
    try {
      await super.onLoad();
      
      print("🎮 Starting game initialization...");
      
      // Add room world (background)
      roomWorld = RoomWorld();
      await add(roomWorld);
      print("✅ Room world added");
      
      // Add player character (sprite-based with directional movement!)
      player = PlayerCharacter();
      await add(player);
      print("✅ Player added");
      
      // Add gift giver character (now sprite-based with animations!)
      giftGiver = GiftGiverCharacter();
      await add(giftGiver);
      print("✅ Gift giver added");
      
      // Add game UI
      gameUI = GameUI();
      await add(gameUI);
      print("✅ Game UI added");
      
      // Set camera
      camera.viewfinder.visibleGameSize = size;
      
      // 🎵 Start background music
      await _startBackgroundMusic();
      
      print("✅ Game loaded successfully!");
      
    } catch (e) {
      print("❌ Error loading game: $e");
    }
  }
  
  /// Start gentle background music for the gift room
  Future<void> _startBackgroundMusic() async {
    try {
      await SoundService.instance.playBackgroundMusic(
        'sounds/gift_room_background.mp3',
        volume: 0.4, // Gentle, non-intrusive volume
      );
      print("🎵 Background music started");
    } catch (e) {
      print("❌ Error starting background music: $e");
    }
  }
  
  @override
  bool onTapDown(TapDownEvent event) {
    try {
      final worldPosition = event.localPosition;
      
      // Check if tap is on gift giver character when near
      if (gameState == GameState.nearGift && _isTapOnGiftGiver(worldPosition)) {
        print("🎁 Tapped on gift giver - interacting with gift");
        interactWithGift();
      } else if (gameState == GameState.playing || gameState == GameState.nearGift) {
        // Normal movement with directional sprites!
        print("🎯 Player moving to: $worldPosition");
        player.moveTo(worldPosition);
      }
    } catch (e) {
      print("❌ Error handling tap: $e");
    }
    return true;
  }
  
  // Helper method to check if tap is on gift giver character
  bool _isTapOnGiftGiver(Vector2 tapPosition) {
    if (!giftGiver.isMounted) return false;
    
    final giftGiverRect = Rect.fromLTWH(
      giftGiver.position.x,
      giftGiver.position.y,
      giftGiver.size.x,
      giftGiver.size.y,
    );
    
    return giftGiverRect.contains(Offset(tapPosition.x, tapPosition.y));
  }
  
  void checkPlayerNearGiftGiver() {
    try {
      if (gameState == GameState.playing || gameState == GameState.nearGift) {
        if (!player.isMounted || !giftGiver.isMounted) return;
        
        final distance = player.position.distanceTo(giftGiver.position);
        
        if (distance < 250.0) {
          if (gameState != GameState.nearGift) {
            gameState = GameState.nearGift;
            gameUI.showInteractionPrompt(true);
            
            // 🎵 Play proximity chime (only once)
            if (!_proximityChimePlayed) {
              _playProximityChime();
              _proximityChimePlayed = true;
            }
            
            print("👥 Player near gift - showing prompt");
          }
        } else {
          if (gameState == GameState.nearGift) {
            gameState = GameState.playing;
            gameUI.showInteractionPrompt(false);
            
            // Reset chime flag when player moves away
            _proximityChimePlayed = false;
            
            print("🚶 Player moved away from gift");
          }
        }
      }
    } catch (e) {
      print("❌ Error checking player position: $e");
    }
  }
  
  /// Play the gentle chime when player approaches gift giver
  Future<void> _playProximityChime() async {
    try {
      await SoundService.instance.playSound(SoundType.proximityChime);
      print("🔔 Proximity chime played");
    } catch (e) {
      print("❌ Error playing proximity chime: $e");
    }
  }
  
  Future<void> interactWithGift() async {
    try {
      if (gameState != GameState.nearGift) return;
      
      gameState = GameState.openingGift;
      gameUI.showInteractionPrompt(false);
      
      print("🎁 Opening gift...");
      
      // Gift giver plays opening animation sequence
      await giftGiver.openGift();
      
      // Create sweater item using sprite component with bounce effect
      try {
        sweaterItem = SweaterItem();
        sweaterItem!.position = Vector2(
          giftGiver.position.x + 100, 
          giftGiver.position.y + 40
        );
        add(sweaterItem!);
        print("👕 Sweater sprite appeared with animation");
      } catch (e) {
        print("❌ Error creating sweater sprite: $e");
        // Fallback to colored rectangle if sprite fails
        final fallbackSweater = RectangleComponent(
          size: Vector2.all(24),
          paint: Paint()..color = Colors.red.withOpacity(0.8),
          position: Vector2(
            giftGiver.position.x + 70, 
            giftGiver.position.y + 10
          ),
        );
        add(fallbackSweater);
        print("👕 Fallback sweater rectangle created");
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Player walks to sweater (with directional movement!)
      // await player.walkToAndPickupSweater(sweaterItem?.position ?? Vector2(
      //   giftGiver.position.x + 150, 
      //   giftGiver.position.y + 10
      // ));

      await player.walkToAndPickupSweater(Vector2(
        giftGiver.position.x + 120, 
        giftGiver.position.y + 70
      ));
      
      // Remove sweater from ground
      if (sweaterItem != null) {
        sweaterItem!.removeFromParent();
      } else {
        // Remove fallback rectangle if it was used
        children.whereType<RectangleComponent>()
            .where((component) => component.paint.color == Colors.red.withOpacity(0.8))
            .forEach((component) => component.removeFromParent());
      }
      
      // Player changes appearance (switches to sweater sprites)
      player.equipSweater();
      
      gameState = GameState.completed;
      
      print("🎉 Game completed!");
      onGameCompleted?.call();
      
    } catch (e) {
      print("❌ Error in gift interaction: $e");
    }
  }
  
  /// Clean up sounds when game is disposed
  @override
  void onRemove() {
    super.onRemove();
    // Stop background music when leaving the game
    SoundService.instance.stopBackgroundMusic();
    print("🔇 Background music stopped");
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    checkPlayerNearGiftGiver();
  }
}

// Room Background with sprite
class RoomWorld extends SpriteComponent {
  @override
  Future<void> onLoad() async {
    try {
      // Load room background sprite
      sprite = await Sprite.load('gift_room/room_background.png');
      
      // Get the game's screen size and match it
      final gameSize = findGame()!.size;
      size = Vector2(gameSize.x, gameSize.y);
      position = Vector2.zero();
      
      print("🏠 Room background sprite loaded");
    } catch (e) {
      print("❌ Failed to load background image: $e");
      // Fallback to colored rectangle if image fails to load
      sprite = null;
      final gameSize = findGame()!.size;
      size = Vector2(gameSize.x, gameSize.y);
      position = Vector2.zero();
      
      // Create a simple colored background as fallback
      add(RectangleComponent(
        size: Vector2(gameSize.x, gameSize.y),
        paint: Paint()..color = Colors.lightBlue.withOpacity(0.3),
      ));
      print("🏠 Fallback room background created");
    }
  }
}

// Simple Game UI
class GameUI extends Component {
  late TextComponent interactionPrompt;
  late RectangleComponent completionOverlay;
  late TextComponent completionMessage;
  
  bool _promptVisible = false;
  bool _completionVisible = false;
  
  @override
  Future<void> onLoad() async {
    // Interaction prompt with white background
    final promptBackground = RectangleComponent(
      size: Vector2(280, 40),
      paint: Paint()..color = Colors.white.withOpacity(0.9),
    );
    promptBackground.position = Vector2(45, 145);
    promptBackground.scale = Vector2.zero();
    add(promptBackground);
    
    interactionPrompt = TextComponent(
      text: 'TAP THE CHARACTER TO OPEN GIFT',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    interactionPrompt.position = Vector2(50, 150);
    interactionPrompt.scale = Vector2.zero();
    add(interactionPrompt);
    
    // Completion overlay
    completionOverlay = RectangleComponent(
      size: Vector2(300, 300),
      paint: Paint()..color = Colors.black.withOpacity(0.7),
    );
    completionOverlay.position = Vector2(50, 200);
    completionOverlay.scale = Vector2.zero();
    add(completionOverlay);
    
    // Completion message (simplified)
    completionMessage = TextComponent(
      text: 'Some gifts are meant to be\nfelt in real life...\n\nThis moment is yours\nto keep forever',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
    completionMessage.position = Vector2(60, 250);
    completionMessage.scale = Vector2.zero();
    add(completionMessage);
    
    print("🖥️ Game UI loaded");
  }
  
  void showInteractionPrompt(bool show) {
    if (_promptVisible == show) return;
    _promptVisible = show;
    
    if (show) {
      // Show both background and text
      children.whereType<RectangleComponent>().first.scale = Vector2.all(1.0);
      interactionPrompt.scale = Vector2.all(1.0);
    } else {
      // Hide both background and text
      children.whereType<RectangleComponent>().first.scale = Vector2.zero();
      interactionPrompt.scale = Vector2.zero();
    }
  }
  
  void showCompletionMessage() {
    if (_completionVisible) return;
    // _completionVisible = true;
    
    // completionOverlay.scale = Vector2.all(1.0);
    
    Future.delayed(const Duration(milliseconds: 300), () {
      completionMessage.scale = Vector2.all(1.0);
    });
  }
  
  void resetUI() {
    _promptVisible = false;
    _completionVisible = false;
    
    interactionPrompt.scale = Vector2.zero();
    completionOverlay.scale = Vector2.zero();
    completionMessage.scale = Vector2.zero();
  }
}