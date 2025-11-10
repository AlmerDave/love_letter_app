// lib/services/motion_service.dart
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

enum UserRole { bubu, dudu, unknown }

/// Detects LEFT movement using accelerometer, with role-based sensitivity.
class MotionService {
  static MotionService? _instance;
  static MotionService get instance => _instance ??= MotionService._();

  MotionService._();

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  DateTime? _lastTriggerTime;
  Function? onLeftMovementDetected;

  // Role-based thresholds (approximate distances)
  static const double _bubuThreshold = -1.5; // needs larger move (~5cm)
  static const double _duduThreshold = -1.0; // small move (~2cm)

  // Debounce time
  static const Duration _debounceDuration = Duration(seconds: 1);

  double _activeThreshold = -4.5;
  UserRole? _activeRole;

  /// Start listening for accelerometer events, using the given userRole
  void startListening({
    required Function onLeftDetected,
    required String userRole,
  }) {
    stopListening();

    onLeftMovementDetected = onLeftDetected;

    switch (userRole.toLowerCase()) {
      case 'bubu':
        _activeThreshold = _bubuThreshold;
        _activeRole = UserRole.bubu;
        break;
      case 'dudu':
        _activeThreshold = _duduThreshold;
        _activeRole = UserRole.dudu;
        break;
      default:
        print('⚠️ Unknown user role — motion detection disabled');
        return;
    }

    _accelerometerSubscription =
        accelerometerEvents.listen(_handleAccelerometerEvent);

    print('🎯 Motion detection started for $userRole (threshold: $_activeThreshold)');
  }

  /// Stop listening and cleanup
  void stopListening() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    onLeftMovementDetected = null;
    print('🛑 Motion detection stopped');
  }

  void _handleAccelerometerEvent(AccelerometerEvent event) {
    // Detect leftward movement based on role-specific threshold
    if (event.x < _activeThreshold) {
      final now = DateTime.now();
      if (_lastTriggerTime == null ||
          now.difference(_lastTriggerTime!) > _debounceDuration) {
        _lastTriggerTime = now;

        print(
            '⬅️ LEFT MOVEMENT DETECTED (${_activeRole?.name} - X: ${event.x.toStringAsFixed(2)})');

        onLeftMovementDetected?.call();
        HapticFeedback.mediumImpact();
      }
    }
  }

  bool get isListening => _accelerometerSubscription != null;

  void resetDebounce() => _lastTriggerTime = null;

  void dispose() => stopListening();
}
