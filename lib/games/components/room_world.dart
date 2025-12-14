// lib/games/components/room_world.dart
import 'package:flame/components.dart';

class RoomWorld extends SpriteComponent {
  @override
  Future<void> onLoad() async {
    // Load room background
    sprite = await Sprite.load('gift_room/room_background.png');
    
    // Set room size - adjust based on your room design
    size = Vector2(800, 600);
    position = Vector2.zero();
  }
  
  /// Check if a position is within room boundaries
  bool isPositionValid(Vector2 position) {
    // Simple boundary check - adjust margins as needed
    const margin = 20.0;
    
    return position.x >= margin && 
           position.x <= size.x - margin &&
           position.y >= margin && 
           position.y <= size.y - margin;
  }
  
  /// Get a valid position within room bounds
  Vector2 clampToRoom(Vector2 position) {
    const margin = 20.0;
    
    return Vector2(
      position.x.clamp(margin, size.x - margin),
      position.y.clamp(margin, size.y - margin),
    );
  }
}