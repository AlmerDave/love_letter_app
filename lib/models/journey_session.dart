// lib/models/journey_session.dart

/// Represents the current state of a Bubu & Dudu journey session.
/// This model maps to the Firebase Realtime Database structure.
class JourneySession {
  final String sessionId;
  final bool duduReady;           // Dudu clicked "I'm here!"
  final bool duduMovedLeft;       // Dudu's phone detected LEFT movement
  final bool bubuMovedLeft;       // Bubu's phone detected LEFT movement
  final bool bubuDeparted;        // Bubu disappeared from right screen
  final bool bubuArrived;         // Bubu arrived on left screen
  final String currentState;      // Overall state: idle/running/traveling/together
  final int timestamp;

  JourneySession({
    required this.sessionId,
    this.duduReady = false,
    this.duduMovedLeft = false,
    this.bubuMovedLeft = false,
    this.bubuDeparted = false,
    this.bubuArrived = false,
    this.currentState = 'idle',
    required this.timestamp,
  });

  /// Create a JourneySession from Firebase snapshot data
  factory JourneySession.fromMap(String sessionId, Map<dynamic, dynamic> map) {
    return JourneySession(
      sessionId: sessionId,
      duduReady: map['duduReady'] ?? false,
      duduMovedLeft: map['duduMovedLeft'] ?? false,
      bubuMovedLeft: map['bubuMovedLeft'] ?? false,
      bubuDeparted: map['bubuDeparted'] ?? false,
      bubuArrived: map['bubuArrived'] ?? false,
      currentState: map['currentState'] ?? 'idle',
      timestamp: map['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'duduReady': duduReady,
      'duduMovedLeft': duduMovedLeft,
      'bubuMovedLeft': bubuMovedLeft,
      'bubuDeparted': bubuDeparted,
      'bubuArrived': bubuArrived,
      'currentState': currentState,
      'timestamp': timestamp,
    };
  }

  /// Create an initial/reset session
  factory JourneySession.initial(String sessionId) {
    return JourneySession(
      sessionId: sessionId,
      duduReady: false,
      duduMovedLeft: false,
      bubuMovedLeft: false,
      bubuDeparted: false,
      bubuArrived: false,
      currentState: 'idle',
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if both phones detected LEFT movement (trigger condition)
  bool get bothPhonesMovedLeft => duduMovedLeft && bubuMovedLeft;

  /// Copy with method for state updates
  JourneySession copyWith({
    String? sessionId,
    bool? duduReady,
    bool? duduMovedLeft,
    bool? bubuMovedLeft,
    bool? bubuDeparted,
    bool? bubuArrived,
    String? currentState,
    int? timestamp,
  }) {
    return JourneySession(
      sessionId: sessionId ?? this.sessionId,
      duduReady: duduReady ?? this.duduReady,
      duduMovedLeft: duduMovedLeft ?? this.duduMovedLeft,
      bubuMovedLeft: bubuMovedLeft ?? this.bubuMovedLeft,
      bubuDeparted: bubuDeparted ?? this.bubuDeparted,
      bubuArrived: bubuArrived ?? this.bubuArrived,
      currentState: currentState ?? this.currentState,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}