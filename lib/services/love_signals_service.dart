// lib/services/love_signals_service.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SignalType {
  thinkingOfYou,
  virtualHug,
}

class LoveSignal {
  final String id;
  final String senderNickname;
  final String receiverNickname;
  final SignalType type;
  final DateTime timestamp;
  final bool isRead;

  LoveSignal({
    required this.id,
    required this.senderNickname,
    required this.receiverNickname,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });

  factory LoveSignal.fromMap(String id, Map<String, dynamic> map) {
    return LoveSignal(
      id: id,
      senderNickname: map['senderNickname'] ?? '',
      receiverNickname: map['receiverNickname'] ?? '',
      type: map['type'] == 'thinkingOfYou' 
          ? SignalType.thinkingOfYou 
          : SignalType.virtualHug,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderNickname': senderNickname,
      'receiverNickname': receiverNickname,
      'type': type == SignalType.thinkingOfYou ? 'thinkingOfYou' : 'virtualHug',
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
    };
  }

  String get emoji => type == SignalType.thinkingOfYou ? '💭' : '💕';
  
  String get title => type == SignalType.thinkingOfYou 
      ? 'Thinking of You' 
      : 'Virtual Hug & Kisses';
      
  String get message => type == SignalType.thinkingOfYou
      ? 'is thinking of you right now 💭✨'
      : 'sent you a warm hug and kisses! 😗💕';
}

class LoveSignalsService {
  static LoveSignalsService? _instance;
  static LoveSignalsService get instance {
    _instance ??= LoveSignalsService._();
    return _instance!;
  }

  LoveSignalsService._();

  // Cooldown durations (in minutes)
  static const int thinkingOfYouCooldown = 0; // 1 hour
  static const int virtualHugCooldown = 0; // 30 minutes

  // Storage keys for last sent times
  static const String _lastThinkingKey = 'last_thinking_of_you';
  static const String _lastHugKey = 'last_virtual_hug';

  /// Get Firebase reference for signals
  DatabaseReference get _signalsRef => 
      FirebaseService.instance.database.child('love_signals');

  /// Send a love signal
  Future<bool> sendSignal({
    required SignalType type,
    required String partnerNickname,
  }) async {
    try {
      // Check cooldown
      final canSend = await canSendSignal(type);
      if (!canSend) {
        print('⏰ Signal on cooldown');
        return false;
      }

      // Get sender nickname
      final myNickname = await UserService.getNickname();
      if (myNickname == null) {
        print('❌ No nickname found');
        return false;
      }

      // Create signal
      final signal = LoveSignal(
        id: _signalsRef.push().key!,
        senderNickname: myNickname.toLowerCase(),
        receiverNickname: partnerNickname.toLowerCase(),
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
      );

      // Save to Firebase
      await _signalsRef.child(signal.id).set(signal.toMap());

      // Update last sent time
      await _updateLastSentTime(type);

      print('✅ Signal sent: ${signal.emoji} from $myNickname to $partnerNickname');
      return true;

    } catch (e) {
      print('❌ Error sending signal: $e');
      return false;
    }
  }

  /// Check if user can send a signal (cooldown check)
  Future<bool> canSendSignal(SignalType type) async {
    final lastSentTime = await getLastSentTime(type);
    if (lastSentTime == null) return true;

    final cooldownMinutes = type == SignalType.thinkingOfYou 
        ? thinkingOfYouCooldown 
        : virtualHugCooldown;

    final difference = DateTime.now().difference(lastSentTime);
    return difference.inMinutes >= cooldownMinutes;
  }

  /// Get remaining cooldown time in minutes
  Future<int> getRemainingCooldown(SignalType type) async {
    final lastSentTime = await getLastSentTime(type);
    if (lastSentTime == null) return 0;

    final cooldownMinutes = type == SignalType.thinkingOfYou 
        ? thinkingOfYouCooldown 
        : virtualHugCooldown;

    final difference = DateTime.now().difference(lastSentTime);
    final remaining = cooldownMinutes - difference.inMinutes;
    
    return remaining > 0 ? remaining : 0;
  }

  /// Get last sent time for a signal type
  Future<DateTime?> getLastSentTime(SignalType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == SignalType.thinkingOfYou ? _lastThinkingKey : _lastHugKey;
    final timestamp = prefs.getInt(key);
    
    if (timestamp == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  /// Update last sent time
  Future<void> _updateLastSentTime(SignalType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = type == SignalType.thinkingOfYou ? _lastThinkingKey : _lastHugKey;
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  /// Get signals for current user (sent + received)
  Stream<List<LoveSignal>> getMySignals() async* {
    final myNickname = await UserService.getNickname();
    if (myNickname == null) {
      yield [];
      return;
    }

    final lowercaseNickname = myNickname.toLowerCase();

    yield* _signalsRef.onValue.map((event) {
      if (event.snapshot.value == null) return <LoveSignal>[];

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      final signals = <LoveSignal>[];

      data.forEach((id, signalData) {
        final signal = LoveSignal.fromMap(id, Map<String, dynamic>.from(signalData));
        
        // Include if user is sender or receiver
        if (signal.senderNickname == lowercaseNickname || 
            signal.receiverNickname == lowercaseNickname) {
          signals.add(signal);
        }
      });

      // Sort by timestamp (newest first)
      signals.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return signals;
    });
  }

  /// Get signal counts (sent/received)
  Future<Map<String, int>> getSignalCounts() async {
    final myNickname = await UserService.getNickname();
    if (myNickname == null) {
      return {
        'thinkingSent': 0,
        'thinkingReceived': 0,
        'hugSent': 0,
        'hugReceived': 0,
      };
    }

    final lowercaseNickname = myNickname.toLowerCase();
    
    final snapshot = await _signalsRef.once();
    if (snapshot.snapshot.value == null) {
      return {
        'thinkingSent': 0,
        'thinkingReceived': 0,
        'hugSent': 0,
        'hugReceived': 0,
      };
    }

    final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
    
    int thinkingSent = 0;
    int thinkingReceived = 0;
    int hugSent = 0;
    int hugReceived = 0;

    data.forEach((id, signalData) {
      final signal = LoveSignal.fromMap(id, Map<String, dynamic>.from(signalData));
      
      if (signal.senderNickname == lowercaseNickname) {
        // Sent by me
        if (signal.type == SignalType.thinkingOfYou) {
          thinkingSent++;
        } else {
          hugSent++;
        }
      } else if (signal.receiverNickname == lowercaseNickname) {
        // Received by me
        if (signal.type == SignalType.thinkingOfYou) {
          thinkingReceived++;
        } else {
          hugReceived++;
        }
      }
    });

    return {
      'thinkingSent': thinkingSent,
      'thinkingReceived': thinkingReceived,
      'hugSent': hugSent,
      'hugReceived': hugReceived,
    };
  }

  /// Mark signal as read
  Future<void> markAsRead(String signalId) async {
    await _signalsRef.child(signalId).update({'isRead': true});
  }

  /// Get partner's nickname (the other person who's not you)
  Future<String?> getPartnerNickname() async {
    final myNickname = await UserService.getNickname();
    if (myNickname == null) return null;

    final lowercaseNickname = myNickname.toLowerCase();

    // Get all users from locations
    final snapshot = await FirebaseService.instance.locationsRef.once();
    if (snapshot.snapshot.value == null) return null;

    final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
    
    for (var userData in data.values) {
      final userMap = Map<String, dynamic>.from(userData);
      final nickname = (userMap['nickname'] as String?)?.toLowerCase();
      
      if (nickname != null && nickname != lowercaseNickname) {
        return nickname;
      }
    }

    return null;
  }
}