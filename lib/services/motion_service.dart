// lib/services/motion_service.dart

import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Service to detect LEFT movement using device accelerometer.
/// Detects negative X acceleration (LEFT direction).
class MotionService {
  static MotionService? _instance;
  static MotionService get instance {
    _instance ??= MotionService._();
    return _instance!;
  }

  MotionService._();

  // Hardcoded threshold for LEFT movement detection
  static const double _leftMovementThreshold = -15.0;
  
  // Debounce duration to prevent multiple triggers
  static const Duration _debounceDuration = Duration(seconds: 1);

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastTriggerTime;
  
  /// Callback when LEFT movement is detected
  Function? onLeftMovementDetected;

  /// Start listening for accelerometer events
  void startListening({required Function onLeftDetected}) {
    onLeftMovementDetected = onLeftDetected;
    
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      _handleAccelerometerEvent(event);
    });

    print('🎯 Motion detection started (threshold: $_leftMovementThreshold)');
  }

  /// Stop listening to accelerometer
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    onLeftMovementDetected = null;
    print('🛑 Motion detection stopped');
  }

  /// Handle accelerometer data
  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Check if X acceleration is negative (LEFT movement) and exceeds threshold
    if (event.x < _leftMovementThreshold) {
      // Check debounce - only trigger once per second
      final now = DateTime.now();
      if (_lastTriggerTime == null || 
          now.difference(_lastTriggerTime!) > _debounceDuration) {
        
        _lastTriggerTime = now;
        
        print('⬅️ LEFT MOVEMENT DETECTED! (X: ${event.x.toStringAsFixed(2)})');
        
        // Trigger callback
        onLeftMovementDetected?.call();
        
        // Optional: Add haptic feedback
        HapticFeedback.mediumImpact();
      }
    }
  }

  /// Manually reset debounce timer (useful for testing or manual triggers)
  void resetDebounce() {
    _lastTriggerTime = null;
  }

  /// Check if motion detection is currently active
  bool get isListening => _accelerometerSubscription != null;

  /// Dispose the service
  void dispose() {
    stopListening();
  }
}