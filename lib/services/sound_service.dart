// lib/services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';

/// Enum to define the different types of sound effects in the app.
enum SoundType {
  letterUnlock,
  newLetter,
  accepted,
  letterRejected, // Sound for when a letter is rejected
  tap,
  
  // ==================== BUBU & DUDU JOURNEY SOUNDS ====================
  journeyNotification,  // When Dudu clicks "I'm here!"
  journeyFootsteps,     // While Bubu runs LEFT
  journeyReunion,       // When reunited 💕
  journeyWhoosh,        // When Bubu disappears/enters
}

/// A singleton service to manage and play sound effects.
/// This ensures we use a single audio player instance throughout the app.
class SoundService {
  // Private constructor for the singleton pattern.
  SoundService._privateConstructor();
  static final SoundService instance = SoundService._privateConstructor();

  final AudioPlayer _player = AudioPlayer();

  /// Plays a sound based on the given [SoundType].
  ///
  /// It maps the enum to a specific asset path and plays the sound.
  /// Make sure you have the corresponding .mp3 files in your `assets/sounds/` directory.
  Future<void> playSound(SoundType type) async {
    String? soundPath;
    switch (type) {
      case SoundType.letterUnlock:
        // A magical chime for when a locked letter becomes available.
        soundPath = 'sounds/unlock_chime.mp3';
        break;
      case SoundType.newLetter:
        // An exciting sound for when a new letter is added via QR code.
        soundPath = 'sounds/new_letter.mp3';
        break;
      case SoundType.accepted:
        // A happy, celebratory sound for accepting an invitation.
        soundPath = 'sounds/accepted.mp3';
        break;
      case SoundType.letterRejected:
        // A soft, sad sound for when an invitation is rejected.
        soundPath = 'sounds/rejected.mp3';
        break;
      case SoundType.tap:
        // A subtle tap sound for UI interactions (optional).
        soundPath = 'sounds/tap.mp3';
        break;
        
      // ==================== JOURNEY SOUNDS ====================
      case SoundType.journeyNotification:
        // Notification sound when Dudu clicks "I'm here!"
        soundPath = 'sounds/journey_notification.mp3';
        break;
      case SoundType.journeyFootsteps:
        // Footsteps sound while Bubu runs LEFT
        soundPath = 'sounds/journey_footsteps.mp3';
        break;
      case SoundType.journeyReunion:
        // Celebration sound when Bubu and Dudu reunite
        soundPath = 'sounds/journey_reunion.mp3';
        break;
      case SoundType.journeyWhoosh:
        // Whoosh sound when Bubu disappears/enters screen
        soundPath = 'sounds/journey_whoosh.mp3';
        break;
    }

    try {
      // Use a low-latency player for short sound effects.
      await _player.play(AssetSource(soundPath), mode: PlayerMode.lowLatency);
    } catch (e) {
      // Log any errors if the sound fails to play.
      print("Error playing sound '$soundPath': $e");
    }
  }

  void dispose() => _player.dispose();
}