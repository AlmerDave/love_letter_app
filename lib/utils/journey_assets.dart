// lib/utils/journey_assets.dart

/// Configuration file for Bubu & Dudu Journey animation assets.
/// Change the file names here to update throughout the app.
class JourneyAssets {
  // ==================== BUBU ANIMATIONS (RIGHT PHONE) ====================
  
  /// Bubu waiting alone, idle state
  static const String bubuIdle = 'assets/images/bubu_dudu_gifs/bubu_idle_1.gif';
  
  /// Bubu gets excited when Dudu signals "I'm here!"
  static const String bubuExcited = 'assets/images/bubu_dudu_gifs/bubu_excited.gif';
  
  /// Bubu running LEFT toward screen edge (looping)
  static const String bubuRunningLeft = 'assets/images/bubu_dudu_gifs/bubu_running_2.gif';
  
  // ==================== DUDU ANIMATIONS (LEFT PHONE) ====================
  
  /// Dudu waiting alone, idle state
  static const String duduIdle = 'assets/images/bubu_dudu_gifs/dudu_idle.gif';
  
  /// Dudu after clicking "I'm here!" button, ready state
  static const String duduReady = 'assets/images/bubu_dudu_gifs/dudu_waiting.gif';
  
  /// Dudu excited, looking RIGHT, waiting for Bubu to arrive
  static const String duduWaiting = 'assets/images/bubu_dudu_gifs/dudu_waiting_2.gif';
  
  // ==================== TOGETHER ANIMATION ====================
  
  /// Both characters together, reunion animation (looping)
  static const String together = 'assets/images/bubu_dudu_gifs/bubu_entering.gif';
  
  // ==================== PLACEHOLDER ====================
  
  /// Fallback placeholder if GIF assets are not yet added
  static const String placeholder = 'assets/images/bubu_dudu_gifs/placeholder.png';
}