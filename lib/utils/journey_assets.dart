// lib/utils/journey_assets.dart

/// Configuration file for Bubu & Dudu Journey animation assets.
/// Change the file names here to update throughout the app.
class JourneyAssets {
  // ==================== TIMING CONFIGURATION ====================
  
  /// Duration (in seconds) for each IDLE gif before switching to next
  static const int idleGifDuration = 6;
  
  /// Duration (in seconds) for each TOGETHER gif before switching to next
  static const int togetherGifDuration = 6;
  
  // ==================== BUBU IDLE ANIMATIONS (Multiple GIFs) ====================
  
  static const List<String> bubuIdleGifs = [
    'assets/images/bubu_dudu_gifs/bubu_idle_1.gif',
    'assets/images/bubu_dudu_gifs/bubu_idle_2.gif',
    'assets/images/bubu_dudu_gifs/bubu_idle_3.gif',
    'assets/images/bubu_dudu_gifs/bubu_idle_4.gif',
    // Add more bubu idle GIFs here as needed
  ];
  
  // ==================== DUDU IDLE ANIMATIONS (Multiple GIFs) ====================
  
  static const List<String> duduIdleGifs = [
    'assets/images/bubu_dudu_gifs/dudu_idle.gif',
    'assets/images/bubu_dudu_gifs/dudu_idle_1.gif',
    'assets/images/bubu_dudu_gifs/dudu_idle_2.gif',
    'assets/images/bubu_dudu_gifs/dudu_idle_3.gif',
    // Add more dudu idle GIFs here as needed
  ];
  
  // ==================== SINGLE STATE ANIMATIONS ====================
  
  /// Bubu gets excited when Dudu signals "I'm here!" (single GIF)
  static const String bubuExcited = 'assets/images/bubu_dudu_gifs/bubu_excited.gif';
  
  /// Bubu running LEFT toward screen edge (looping)
  static const String bubuRunningLeft = 'assets/images/bubu_dudu_gifs/bubu_running_2.gif';
  
  /// Dudu after clicking "I'm here!" button, ready state (single GIF)
  static const String duduReady = 'assets/images/bubu_dudu_gifs/dudu_waiting_2.gif';
  
  /// Dudu excited, looking RIGHT, waiting for Bubu to arrive
  static const String duduWaiting = 'assets/images/bubu_dudu_gifs/dudu_waiting.gif';
  
  /// Bubu arriving on Dudu's phone (slides in from right)
  static const String bubuArriving = 'assets/images/bubu_dudu_gifs/bubu_running_2.gif';

  static const String reunionAnimation = 'assets/images/bubu_dudu_gifs/bubu_entering.gif';
  
  // ==================== TOGETHER ANIMATIONS (Multiple GIFs) ====================
  
  static const List<String> togetherGifs = [
    'assets/images/bubu_dudu_gifs/bubu_dudu_together.gif',
    'assets/images/bubu_dudu_gifs/bubu_dudu_together_1.gif',
    'assets/images/bubu_dudu_gifs/bubu_dudu_together_2.gif',
    'assets/images/bubu_dudu_gifs/bubu_dudu_together_3.gif',
    'assets/images/bubu_dudu_gifs/bubu_dudu_together_4.gif',
    // Add more together GIFs here as needed
  ];
  
  // ==================== PLACEHOLDER ====================
  
  /// Fallback placeholder if GIF assets are not yet added
  static const String placeholder = 'assets/images/bubu_dudu_gifs/placeholder.png';
}