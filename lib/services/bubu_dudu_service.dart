// lib/services/bubu_dudu_service.dart

import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/models/journey_session.dart';

/// Service to manage Bubu & Dudu journey sessions via Firebase Realtime Database.
/// Handles synchronization between two phones in real-time.
class BubuDuduService {
  static BubuDuduService? _instance;
  static BubuDuduService get instance {
    _instance ??= BubuDuduService._();
    return _instance!;
  }

  BubuDuduService._();

  // Hardcoded session ID for the couple
  static const String coupleSessionId = 'couple_session_001';

  DatabaseReference get _sessionRef =>
      FirebaseService.instance.database.child('bubu_dudu_sessions').child(coupleSessionId);

  StreamSubscription<DatabaseEvent>? _sessionSubscription;

  /// Stream controller for session updates
  final _sessionController = StreamController<JourneySession>.broadcast();
  Stream<JourneySession> get sessionStream => _sessionController.stream;

  /// Initialize and listen to session changes
  Future<void> startListening() async {
    // Create initial session if doesn't exist
    final snapshot = await _sessionRef.get();
    if (!snapshot.exists) {
      await resetSession();
    }

    // Listen for changes
    _sessionSubscription = _sessionRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final session = JourneySession.fromMap(coupleSessionId, data);
        _sessionController.add(session);
        print('📡 Session updated: ${session.currentState}');
      }
    });

    print('🎧 Listening to session: $coupleSessionId');
  }

  /// Stop listening to session changes
  void stopListening() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;
    print('🔇 Stopped listening to session');
  }

  /// Reset session to initial state (full reset)
  Future<void> resetSession() async {
    final initialSession = JourneySession.initial(coupleSessionId);
    await _sessionRef.set(initialSession.toMap());
    print('🔄 Session reset to idle');
  }

  /// Update specific fields in the session
  Future<void> updateSession(Map<String, dynamic> updates) async {
    // Add timestamp to all updates
    updates['timestamp'] = DateTime.now().millisecondsSinceEpoch;
    
    await _sessionRef.update(updates);
    print('✅ Session updated: $updates');
  }

  /// Dudu clicks "I'm here!" button
  Future<void> duduReady() async {
    await updateSession({
      'duduReady': true,
      'currentState': 'dudu_ready',
    });
  }

  /// Dudu's phone detected LEFT movement
  Future<void> duduMovedLeft() async {
    await updateSession({
      'duduMovedLeft': true,
    });
    await _checkBothMovedLeft();
  }

  /// Bubu's phone detected LEFT movement
  Future<void> bubuMovedLeft() async {
    await updateSession({
      'bubuMovedLeft': true,
    });
    await _checkBothMovedLeft();
  }

  /// Check if both phones detected LEFT movement (trigger condition)
  Future<void> _checkBothMovedLeft() async {
    final snapshot = await _sessionRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final duduMoved = data['duduMovedLeft'] ?? false;
      final bubuMoved = data['bubuMovedLeft'] ?? false;

      if (duduMoved && bubuMoved) {
        print('🎯 BOTH PHONES MOVED LEFT! Triggering journey...');
        await updateSession({
          'currentState': 'traveling',
        });
      }
    }
  }

  /// Bubu departed from right screen
  Future<void> bubuDeparted() async {
    await updateSession({
      'bubuDeparted': true,
      'currentState': 'bubu_departed',
    });
  }

  /// Bubu arrived on left screen (reunion!)
  Future<void> bubuArrived() async {
    await updateSession({
      'bubuArrived': true,
      'currentState': 'together',
    });
  }

  /// Get current session state once (no listening)
  Future<JourneySession?> getCurrentSession() async {
    final snapshot = await _sessionRef.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return JourneySession.fromMap(coupleSessionId, data);
    }
    return null;
  }

  /// Dispose the service
  void dispose() {
    stopListening();
    _sessionController.close();
  }
}