// lib/services/sound_service.dart
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

/// Enum to define the different types of sound effects in the app.
enum SoundType {
  letterUnlock,
  newLetter,
  accepted,
  letterRejected,
  tap,
  
  // ==================== BUBU & DUDU JOURNEY SOUNDS ====================
  journeyNotification,
  journeyImhere,        // When Dudu clicks "I'm here!"  
  journeyFootsteps,     // While Bubu runs LEFT
  journeyReunion,       // When reunited 💕
  journeyWhoosh,        // When Bubu disappears/enters
}

/// A singleton service to manage and play sound effects.
class SoundService {
  SoundService._privateConstructor();
  static final SoundService instance = SoundService._privateConstructor();

  // Separate players for different audio purposes
  final AudioPlayer _sfxPlayer = AudioPlayer();      // For sound effects
  final AudioPlayer _musicPlayer = AudioPlayer();    // For background music
  
  Timer? _stopTimer;  // Timer to track scheduled sound stops

  /// Plays a regular sound effect (full duration, no control).
  /// Used for UI sounds like taps, unlocks, etc.
  Future<void> playSound(SoundType type) async {
    String? soundPath;
    switch (type) {
      case SoundType.letterUnlock:
        soundPath = 'sounds/unlock_chime.mp3';
        break;
      case SoundType.newLetter:
        soundPath = 'sounds/new_letter.mp3';
        break;
      case SoundType.accepted:
        soundPath = 'sounds/accepted.mp3';
        break;
      case SoundType.letterRejected:
        soundPath = 'sounds/rejected.mp3';
        break;
      case SoundType.tap:
        soundPath = 'sounds/tap.mp3';
        break;
      default:
        print("Warning: ${type.name} should use playJourneySound() instead");
        return;
    }

    try {
      await _sfxPlayer.play(AssetSource(soundPath), mode: PlayerMode.lowLatency);
    } catch (e) {
      print("Error playing sound '$soundPath': $e");
    }
  }

  /// Plays journey-related sounds with optional duration control and looping.
  /// 
  /// [type] - The journey sound to play
  /// [duration] - Optional duration to play. If null, plays the entire sound.
  /// [loop] - If true, loops the sound indefinitely until stopped
  /// 
  /// Example:
  /// - playJourneySound(SoundType.journeyFootsteps, loop: true) → loops forever
  /// - playJourneySound(SoundType.journeyWhoosh) → plays once
  Future<void> playJourneySound(SoundType type, {Duration? duration, bool loop = false}) async {
    String? soundPath;
    switch (type) {
      case SoundType.journeyNotification:
        soundPath = 'sounds/accepted.mp3';
        break;
      case SoundType.journeyImhere:
        soundPath = 'sounds/journey_notification.mp3';
        break;
      case SoundType.journeyFootsteps:
        soundPath = 'sounds/journey_footsteps.mp3';
        break;
      case SoundType.journeyReunion:
        soundPath = 'sounds/journey_reunion.mp3';
        break;
      case SoundType.journeyWhoosh:
        soundPath = 'sounds/journey_whoosh.mp3';
        break;
      default:
        print("Warning: ${type.name} is not a journey sound");
        return;
    }

    try {
      // Cancel any existing stop timer from previous sound
      _stopTimer?.cancel();
      
      // Set release mode based on loop parameter
      if (loop) {
        await _sfxPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        await _sfxPlayer.setReleaseMode(ReleaseMode.release);
      }
      
      // Play the sound
      await _sfxPlayer.play(AssetSource(soundPath), mode: PlayerMode.lowLatency);
      
      // If duration is specified and not looping, schedule the sound to stop
      if (duration != null && !loop) {
        _stopTimer = Timer(duration, () {
          _sfxPlayer.stop();
        });
      }
    } catch (e) {
      print("Error playing journey sound '$soundPath': $e");
    }
  }

  /// Stops any currently playing journey sound.
  /// Useful for manually interrupting a sound.
  Future<void> stopJourneySound() async {
    _stopTimer?.cancel();
    await _sfxPlayer.stop();
  }

  /// Plays journey background music on loop indefinitely.
  /// Only stops when reset button is pressed or manually stopped.
  Future<void> playJourneyBackgroundMusic() async {
    try {
      await _musicPlayer.setVolume(0.3); // Quieter than SFX
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource('sounds/journey_background.mp3'));
    } catch (e) {
      print("Error playing journey background music: $e");
    }
  }

  /// Plays background music on loop.
  /// 
  /// [assetPath] - Path to the music file (e.g., 'sounds/background_music.mp3')
  /// [volume] - Volume level from 0.0 to 1.0 (default: 0.5)
  Future<void> playBackgroundMusic(String assetPath, {double volume = 0.5}) async {
    try {
      await _musicPlayer.setVolume(volume);
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.play(AssetSource(assetPath));
    } catch (e) {
      print("Error playing background music '$assetPath': $e");
    }
  }

  /// Stops the background music.
  Future<void> stopBackgroundMusic() async {
    await _musicPlayer.stop();
  }

  /// Pauses the background music (can be resumed later).
  Future<void> pauseBackgroundMusic() async {
    await _musicPlayer.pause();
  }

  /// Resumes the background music if it was paused.
  Future<void> resumeBackgroundMusic() async {
    await _musicPlayer.resume();
  }

  /// Sets the volume for background music.
  /// [volume] should be between 0.0 (mute) and 1.0 (full volume)
  Future<void> setMusicVolume(double volume) async {
    await _musicPlayer.setVolume(volume.clamp(0.0, 1.0));
  }

  Future<void> resetJourneySounds() async {
    _stopTimer?.cancel();
    await _sfxPlayer.stop();
    await _sfxPlayer.release();
    // Player will auto-reinitialize on next play() call with audioplayers
  }

  void dispose() {
    _stopTimer?.cancel();
    _sfxPlayer.dispose();
    _musicPlayer.dispose();
  }
}