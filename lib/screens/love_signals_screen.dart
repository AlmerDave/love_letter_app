// lib/screens/love_signals_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:love_letter_app/utils/theme.dart';
import 'package:love_letter_app/services/love_signals_service.dart';
import 'package:love_letter_app/services/notification_service_web.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/services/sound_service.dart';
import 'dart:async';
import 'dart:math' as math;

extension StringCapitalization on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

class LoveSignalsScreen extends StatefulWidget {
  const LoveSignalsScreen({Key? key}) : super(key: key);

  @override
  State<LoveSignalsScreen> createState() => _LoveSignalsScreenState();
}

class _LoveSignalsScreenState extends State<LoveSignalsScreen>
    with TickerProviderStateMixin {

  // Daily signal counts
  int _dailyThinkingSent = 0;
  int _dailyThinkingReceived = 0;
  int _dailyHugSent = 0;
  int _dailyHugReceived = 0;
  
  // Signal counts
  int _thinkingSent = 0;
  int _thinkingReceived = 0;
  int _hugSent = 0;
  int _hugReceived = 0;

  // Cooldown timers
  int _thinkingCooldown = 0;
  int _hugCooldown = 0;
  Timer? _cooldownTimer;

  // Recent signals
  List<LoveSignal> _recentSignals = [];
  StreamSubscription? _signalsSubscription;

  // Animation controllers
  late AnimationController _heartBurstController;
  late AnimationController _floatingController;
  bool _showHeartBurst = false;
  String? _lastSignalSender;

  // ✨ NEW: Notification permission state
  String _notificationPermission = 'checking'; // 'checking', 'granted', 'denied', 'default'
  bool _showNotificationBanner = false;

  // ✨ NEW: Debug logs
  List<String> _debugLogs = [];
  bool _showDebugConsole = false;

  @override
  void initState() {
    super.initState();

    // ✨ NEW: Connect debug logging
    NotificationServiceWeb.instance.onDebugLog = (message) {
      _addDebugLog(message);
    };

    _loadData();
    _startCooldownTimer();
    _listenToSignals();
    _initializeAnimations();
    _checkNotificationPermission(); // ✨ NEW
  }

  void _initializeAnimations() {
    _heartBurstController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _floatingController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _heartBurstController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeartBurst = false);
        _heartBurstController.reset();
      }
    });
  }

  void _addDebugLog(String message) {
    setState(() {
      _debugLogs.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_debugLogs.length > 50) {
        _debugLogs.removeLast();
      }
    });
    print(message); // Also print to console
  }

  // Add this method to _LoveSignalsScreenState
  Future<void> _forceTokenRefresh() async {
    _addDebugLog('🔄 Starting token refresh...');
    
    try {
      final hasPermission = await NotificationServiceWeb.instance.hasPermission();
      _addDebugLog('Permission status: $hasPermission');
      
      if (!hasPermission) {
        _addDebugLog('❌ No permission granted');
        _showErrorMessage('Please enable notifications first');
        return;
      }

      _addDebugLog('Calling forceRefreshToken...');
      final success = await NotificationServiceWeb.instance.forceRefreshToken();
      _addDebugLog('forceRefreshToken result: $success');
      
      final token = NotificationServiceWeb.instance.fcmToken;
      _addDebugLog('Token: ${token?.substring(0, 20) ?? "null"}...');
      
      if (success && token != null) {
        _addDebugLog('✅ Token refreshed successfully');
        _showSuccessMessage('✅ Token refreshed!\n${token.substring(0, 30)}...');
      } else {
        _addDebugLog('❌ Failed - success: $success, token: ${token != null}');
        _showErrorMessage('❌ Failed to refresh token');
      }
    } catch (e, stackTrace) {
      _addDebugLog('❌ ERROR: $e');
      _addDebugLog('Stack: ${stackTrace.toString().substring(0, 100)}');
      _showErrorMessage('❌ Error: $e');
    }
  }

  // ✨ ENHANCED: Add detailed system info button
  Future<void> _showSystemInfo() async {
    _addDebugLog('📊 Getting system info...');
    
    final debugInfo = await NotificationServiceWeb.instance.getDebugInfo();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔍 System Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection('Browser API', debugInfo['browser']),
              const Divider(),
              _buildInfoSection('Firebase SDK', debugInfo['firebase']),
              const Divider(),
              _buildInfoSection('Service State', debugInfo['service']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ✨ NEW: Check notification permission status
  Future<void> _checkNotificationPermission() async {
    if (!kIsWeb) {
      setState(() => _showNotificationBanner = false);
      return;
    }

    final status = await NotificationServiceWeb.instance.getPermissionStatus();
    setState(() {
      _notificationPermission = status;
      _showNotificationBanner = (status == 'default' || status == 'denied');
    });
  }

  // ✨ NEW: Request notification permission
  Future<void> _requestNotificationPermission() async {
    setState(() => _notificationPermission = 'requesting');

    final granted = await NotificationServiceWeb.instance.requestPermission();

    if (granted) {
      setState(() {
        _notificationPermission = 'granted';
        _showNotificationBanner = false;
      });
      
      _showSuccessMessage('🔔 Notifications enabled! You\'ll get love signals instantly!');
    } else {
      setState(() {
        _notificationPermission = 'denied';
        _showNotificationBanner = true;
      });
      
      _showErrorMessage('❌ Permission denied. Enable in browser settings to receive notifications.');
    }
  }

  Future<void> _loadData() async {
    // Load all-time counts
    final counts = await LoveSignalsService.instance.getSignalCounts();
    
    // Load daily counts (NEW)
    final dailyCounts = await LoveSignalsService.instance.getDailySignalCounts();
    
    // Load cooldowns
    final thinkingCooldown = await LoveSignalsService.instance
        .getRemainingCooldown(SignalType.thinkingOfYou);
    final hugCooldown = await LoveSignalsService.instance
        .getRemainingCooldown(SignalType.virtualHug);

    if (mounted) {
      setState(() {
        // All-time counts
        _thinkingSent = counts['thinkingSent'] ?? 0;
        _thinkingReceived = counts['thinkingReceived'] ?? 0;
        _hugSent = counts['hugSent'] ?? 0;
        _hugReceived = counts['hugReceived'] ?? 0;
        
        // Daily counts (NEW)
        _dailyThinkingSent = dailyCounts['thinkingSent'] ?? 0;
        _dailyThinkingReceived = dailyCounts['thinkingReceived'] ?? 0;
        _dailyHugSent = dailyCounts['hugSent'] ?? 0;
        _dailyHugReceived = dailyCounts['hugReceived'] ?? 0;
        
        _thinkingCooldown = thinkingCooldown;
        _hugCooldown = hugCooldown;
      });
    }
  }

  void _listenToSignals() {
    _signalsSubscription = LoveSignalsService.instance
        .getMySignals()
        .listen((signals) {
      if (mounted) {
        setState(() {
          _recentSignals = signals.take(10).toList();
        });
        
        // Check for new signal and show animation
        if (signals.isNotEmpty) {
          final latestSignal = signals.first;
          final now = DateTime.now();
          final diff = now.difference(latestSignal.timestamp);
          
          // If signal is less than 5 seconds old, show animation
          if (diff.inSeconds < 5 && !latestSignal.isRead) {
            _showReceivedAnimation(latestSignal);
            LoveSignalsService.instance.markAsRead(latestSignal.id);
          }
        }
      }
    });
  }

  void _showReceivedAnimation(LoveSignal signal) {
    setState(() {
      _showHeartBurst = true;
      _lastSignalSender = signal.senderNickname;
    });
    _heartBurstController.forward();
    
    // Play sound based on signal type
    if (signal.type == SignalType.thinkingOfYou) {
      SoundService.instance.playSound(SoundType.letterUnlock);
    } else {
      SoundService.instance.playSound(SoundType.newLetter);
    }
  }

  void _startCooldownTimer() {
    _cooldownTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      _loadData(); // Reload cooldowns every minute
    });
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _signalsSubscription?.cancel();
    _heartBurstController.dispose();
    _floatingController.dispose();
    super.dispose();
  }

  void _showSendingDialog(SignalType type) {
    final imagePath = type == SignalType.thinkingOfYou 
        ? 'assets/images/bubu_dudu/thinking_signal.gif'
        : 'assets/images/bubu_dudu/hug_signal.gif';
    final emoji = type == SignalType.thinkingOfYou ? '💭' : '😗';
    final message = type == SignalType.thinkingOfYou 
        ? 'Sending your thoughts...' 
        : 'Sending a warm hug...';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SendingDialog(
        imagePath: imagePath,
        emoji: emoji,
        message: message,
      ),
    );
  }

  Future<void> _sendSignal(SignalType type) async {
    // Check cooldown first
    if (type == SignalType.thinkingOfYou && _thinkingCooldown > 0) {
      _showCooldownMessage('thinking', _thinkingCooldown);
      return;
    }
    if (type == SignalType.virtualHug && _hugCooldown > 0) {
      _showCooldownMessage('hug', _hugCooldown);
      return;
    }

    // Show beautiful sending dialog
    _showSendingDialog(type);

    await Future.delayed(const Duration(seconds: 2));

    // Get partner nickname
    final partnerNickname = await LoveSignalsService.instance.getPartnerNickname();
    if (partnerNickname == null) {
      Navigator.pop(context);
      _showErrorMessage('Partner not found. Make sure they have the app!');
      return;
    }

    // Send signal
    final success = await LoveSignalsService.instance.sendSignal(
      type: type,
      partnerNickname: partnerNickname,
    );

    if (success) {
      // Send push notification (web version)
      if (kIsWeb) {
        final myNickname = await UserService.getNickname();
        if (myNickname != null) {
          await NotificationServiceWeb.instance.sendNotificationToPartner(
            signalType: type,
            senderNickname: myNickname,
          );
        }
      }

      // Play success sound
      SoundService.instance.playSound(SoundType.newLetter);

      // Reload data
      await _loadData();

      Navigator.pop(context);
      _showSuccessMessage(
        type == SignalType.thinkingOfYou
            ? '💭 Your partner knows you\'re thinking of them!'
            : '😗 Virtual hug and kisses sent with love!',
      );
    } else {
      Navigator.pop(context);
      _showErrorMessage('Failed to send signal. Try again!');
    }
  }

  // ✨ NEW: Check permission status
  Future<void> _checkPermissionStatus() async {
    _addDebugLog('🔍 === CHECKING PERMISSION STATUS ===');
    
    try {
      final browserStatus = await NotificationServiceWeb.instance.getBrowserPermissionStatus();
      _addDebugLog('🌐 Browser: $browserStatus');
      
      final serviceStatus = await NotificationServiceWeb.instance.getPermissionStatus();
      _addDebugLog('🔥 Service: $serviceStatus');
      
      final hasIt = await NotificationServiceWeb.instance.hasPermission();
      _addDebugLog('✅ hasPermission(): $hasIt');
      
      _addDebugLog('🔍 === CHECK COMPLETE ===');
      
      _showSuccessMessage('Check complete! See logs above.');
    } catch (e) {
      _addDebugLog('❌ Check failed: $e');
      _showErrorMessage('Check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.deepPurple),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '💕 Love Signals',
          style: AppTheme.romanticTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLavender.withOpacity(0.3),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Main content
          RefreshIndicator(
            onRefresh: () async {
              await _loadData();
              await _checkNotificationPermission();
            },
            color: AppTheme.deepPurple,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ✨ Debug Console (only on web)
                  // if (kIsWeb)
                  //   _buildDebugConsole(),
                  
                  // ✨ NEW: Notification permission banner
                  if (kIsWeb && _showNotificationBanner)
                    _buildNotificationBanner(),
                  
                  if (kIsWeb && _showNotificationBanner)
                    const SizedBox(height: 16),

                  // 🔧 DEBUG: Force refresh token button
                  if (kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElevatedButton.icon(
                        onPressed: _forceTokenRefresh,
                        icon: const Icon(Icons.refresh),
                        label: const Text('🔄 Refresh Token'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  // Daily Dashboard at the top
                  _buildDailyDashboard(),
                    
                  const SizedBox(height: 24),

                  // Send buttons
                  _buildSendButton(
                    type: SignalType.thinkingOfYou,
                    imagePath: 'assets/images/bubu_dudu/thinking_icon.png',
                    emoji: '💭',
                    title: 'Sending Warm Thoughts',
                    subtitle: "A small reminder that\n you're cared for",
                    cooldown: _thinkingCooldown,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryLavender,
                        AppTheme.softBlush.withOpacity(0.8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildSendButton(
                    type: SignalType.virtualHug,
                    imagePath: 'assets/images/bubu_dudu/hug_icon.png',
                    emoji: '😗',
                    title: 'Send Virtual Hug and Kisses',
                    subtitle: 'Wrap them in your love from long distances',
                    cooldown: _hugCooldown,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.softBlush,
                        AppTheme.blushPink,
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // All-time Statistics (moved from _buildDashboard)
                  _buildAllTimeStatistics(),

                  const SizedBox(height: 24),

                  // Recent signals
                  _buildRecentSignals(),
                ],
              ),
            ),
          ),

          // Heart burst animation overlay
          if (_showHeartBurst) _buildHeartBurstAnimation(),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, Map<String, dynamic>? data) {
    if (data == null) return const SizedBox();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...data.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '${entry.key}:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: SelectableText(
                    '${entry.value}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDailyDashboard() {
    final today = DateTime.now();
    final formattedDate = '${_getMonthName(today.month)} ${today.day}, ${today.year}';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLavender.withOpacity(0.3),
            AppTheme.softBlush.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryLavender.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Date header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.calendar_today,
                color: AppTheme.deepPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'TODAY - $formattedDate',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepPurple,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Daily signal counts
          Row(
            children: [
              Expanded(
                child: _buildDailySignalCard(
                  emoji: '💭',
                  title: 'Thinking of You',
                  yourCount: _dailyThinkingSent,
                  partnerCount: _dailyThinkingReceived,
                  color: AppTheme.deepPurple,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDailySignalCard(
                  emoji: '💕',
                  title: 'Virtual Hugs & Kisses',
                  yourCount: _dailyHugSent,
                  partnerCount: _dailyHugReceived,
                  color: AppTheme.blushPink,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailySignalCard({
    required String emoji,
    required String title,
    required int yourCount,
    required int partnerCount,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Text(
                    '$yourCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  FutureBuilder<String?>(
                    future: UserService.getNickname(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.toLowerCase().capitalize() ?? 'You',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.lightText,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 30,
                color: Colors.grey.shade300,
              ),
              Column(
                children: [
                  Text(
                    '$partnerCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  FutureBuilder<String?>(
                    future: LoveSignalsService.instance.getPartnerNickname(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data?.toLowerCase().capitalize() ?? 'Partner',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.lightText,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllTimeStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                color: AppTheme.lightText,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'ALL-TIME BB LOVENESS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.lightText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildDashboard(),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  // ✨ ENHANCED: Better debug console with more features
  Widget _buildDebugConsole() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() => _showDebugConsole = !_showDebugConsole);
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade900,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Debug Console',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade700,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_debugLogs.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _showDebugConsole ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          
          // Quick actions (always visible)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.info_outline,
                    label: 'System Info',
                    onPressed: _showSystemInfo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.refresh,
                    label: 'Force Token',
                    onPressed: _forceTokenRefresh,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Check Perm',
                    onPressed: _checkPermissionStatus,
                  ),
                ),
              ],
            ),
          ),
          
          // Logs
          if (_showDebugConsole)
            Container(
              height: 250,
              padding: const EdgeInsets.all(8),
              child: _debugLogs.isEmpty
                  ? const Center(
                      child: Text(
                        'No logs yet...\nUse the buttons above to test',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _debugLogs.length,
                      itemBuilder: (context, index) {
                        final log = _debugLogs[index];
                        Color textColor = Colors.white;
                        
                        if (log.contains('❌') || log.contains('ERROR')) {
                          textColor = Colors.red.shade300;
                        } else if (log.contains('✅') || log.contains('SUCCESS')) {
                          textColor = Colors.green.shade300;
                        } else if (log.contains('⚠️') || log.contains('WARNING')) {
                          textColor = Colors.orange.shade300;
                        } else if (log.contains('📋') || log.contains('1️⃣') || 
                                  log.contains('2️⃣') || log.contains('3️⃣') ||
                                  log.contains('4️⃣') || log.contains('5️⃣')) {
                          textColor = Colors.blue.shade300;
                        }
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: SelectableText(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: textColor,
                              height: 1.3,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          
          // Control buttons
          if (_showDebugConsole)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _debugLogs.clear());
                        _addDebugLog('🗑️ Logs cleared');
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text('Clear'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final logs = _debugLogs.join('\n');
                        await Clipboard.setData(ClipboardData(text: logs));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Logs copied to clipboard!'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 16),
                      label: const Text('Copy'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: const Size(0, 0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        minimumSize: const Size(0, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✨ NEW: Notification permission banner
  Widget _buildNotificationBanner() {
    final isDenied = _notificationPermission == 'denied';
    final isRequesting = _notificationPermission == 'requesting';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDenied 
              ? [Colors.orange.shade300, Colors.orange.shade400]
              : [AppTheme.primaryLavender, AppTheme.softBlush],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.mediumShadow,
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDenied ? Icons.notifications_off : Icons.notifications_active,
              color: isDenied ? Colors.orange : AppTheme.deepPurple,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDenied 
                      ? 'Notifications Blocked'
                      : 'Enable Notifications',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDenied
                      ? 'Enable in browser settings'
                      : 'Get instant love signals!',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          
          // Button
          if (!isDenied)
            TextButton(
              onPressed: isRequesting ? null : _requestNotificationPermission,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isRequesting
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(AppTheme.deepPurple),
                      ),
                    )
                  : Text(
                      'Enable',
                      style: TextStyle(
                        color: AppTheme.deepPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20),
            onPressed: () {
              setState(() => _showNotificationBanner = false);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Text(
            'Love Signal Dashboard',
            style: AppTheme.romanticTitle.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildCounterCard(
                  imagePath: 'assets/images/bubu_dudu/thinking_counter.jpg',
                  emoji: '💭',
                  title: 'Thinking of You',
                  sent: _thinkingSent,
                  received: _thinkingReceived,
                  color: AppTheme.primaryLavender,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCounterCard(
                  imagePath: 'assets/images/bubu_dudu/hug_counter.jpg',
                  emoji: '😗',
                  title: 'Virtual Hugs & Kisses',
                  sent: _hugSent,
                  received: _hugReceived,
                  color: AppTheme.softBlush,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard({
    String? imagePath,
    required String emoji,
    required String title,
    required int sent,
    required int received,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          _buildImageOrEmoji(
            imagePath: imagePath,
            emoji: emoji,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '$sent',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepPurple,
                    ),
                  ),
                  Text(
                    'Sent',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '$received',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.deepPurple,
                    ),
                  ),
                  Text(
                    'Got',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSendButton({
    required SignalType type,
    String? imagePath,
    required String emoji,
    required String title,
    required String subtitle,
    required int cooldown,
    required Gradient gradient,
  }) {
    final canSend = cooldown == 0;

    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, canSend ? math.sin(_floatingController.value * math.pi * 2) * 4 : 0),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: canSend ? () => _sendSignal(type) : null,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: canSend ? gradient : null,
            color: canSend ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(20),
            boxShadow: canSend ? AppTheme.mediumShadow : [],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildImageOrEmoji(
                  imagePath: imagePath,
                  emoji: emoji,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: canSend ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      canSend ? subtitle : 'Available in $cooldown min',
                      style: TextStyle(
                        fontSize: 13,
                        color: canSend 
                            ? Colors.white.withOpacity(0.9)
                            : Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                canSend ? Icons.send : Icons.lock_clock,
                color: canSend ? Colors.white : Colors.grey.shade600,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSignals() {
    if (_recentSignals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            _buildImageOrEmoji(
              imagePath: 'assets/images/bubu_dudu/no_signals.png',
              emoji: '💕',
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'No signals yet',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Send your first love signal! 💕',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Signals',
            style: AppTheme.romanticTitle.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade300),
          ..._recentSignals.map((signal) => _buildSignalItem(signal)),
        ],
      ),
    );
  }

  Widget _buildSignalItem(LoveSignal signal) {
    final imagePath = signal.type == SignalType.thinkingOfYou
        ? 'assets/images/bubu_dudu/thinking_small.png'
        : 'assets/images/bubu_dudu/hug_small.png';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: signal.type == SignalType.thinkingOfYou
                  ? AppTheme.primaryLavender.withOpacity(0.3)
                  : AppTheme.softBlush.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: _buildImageOrEmoji(
                imagePath: imagePath,
                emoji: signal.emoji,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${signal.senderNickname} → ${signal.receiverNickname}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkText,
                  ),
                ),
                Text(
                  _formatTimestamp(signal.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartBurstAnimation() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _heartBurstController,
        builder: (context, child) {
          return Container(
            color: Colors.black.withOpacity(0.3 * (1 - _heartBurstController.value)),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: List.generate(12, (index) {
                      final angle = (index * 30.0) * math.pi / 180;
                      final distance = 100 * _heartBurstController.value;
                      return Transform.translate(
                        offset: Offset(
                          math.cos(angle) * distance,
                          math.sin(angle) * distance,
                        ),
                        child: Opacity(
                          opacity: 1 - _heartBurstController.value,
                          child: _buildImageOrEmoji(
                            imagePath: 'assets/images/bubu_dudu/heart_particle.png',
                            emoji: '💕',
                            size: 30 * (1 + _heartBurstController.value),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 40),
                  FadeTransition(
                    opacity: Tween<double>(begin: 0, end: 1).animate(
                      CurvedAnimation(
                        parent: _heartBurstController,
                        curve: const Interval(0.3, 0.7),
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.strongShadow,
                      ),
                      child: Column(
                        children: [
                          _buildImageOrEmoji(
                            imagePath: 'assets/images/bubu_dudu/love_received.png',
                            emoji: '💕',
                            size: 40,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_lastSignalSender sent',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.darkText,
                            ),
                          ),
                          Text(
                            'you love!',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.deepPurple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageOrEmoji({
    String? imagePath,
    required String emoji,
    required double size,
  }) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            emoji,
            style: TextStyle(fontSize: size * 0.7),
          );
        },
      );
    } else {
      return Text(
        emoji,
        style: TextStyle(fontSize: size * 0.7),
      );
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _showCooldownMessage(String type, int minutes) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏰ Wait $minutes more minutes to send another $type signal'),
        backgroundColor: Colors.orange.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// Sending Dialog (unchanged)
class _SendingDialog extends StatefulWidget {
  final String? imagePath;
  final String emoji;
  final String message;

  const _SendingDialog({
    this.imagePath,
    required this.emoji,
    required this.message,
  });

  @override
  State<_SendingDialog> createState() => _SendingDialogState();
}

class _SendingDialogState extends State<_SendingDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.warmCream,
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: List.generate(6, (index) {
                          final angle = _rotationAnimation.value + (index * math.pi / 3);
                          final radius = 50.0;
                          return Transform.translate(
                            offset: Offset(
                              math.cos(angle) * radius,
                              math.sin(angle) * radius,
                            ),
                            child: Opacity(
                              opacity: 0.6,
                              child: _buildImageOrEmoji(
                                imagePath: 'assets/images/bubu_dudu/heart_particle.png',
                                emoji: '💕',
                                size: 16,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                  
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.primaryLavender.withOpacity(0.3),
                                Colors.transparent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: _buildImageOrEmoji(
                            imagePath: widget.imagePath,
                            emoji: widget.emoji,
                            size: 60,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final delay = index * 0.2;
                      final value = (_controller.value - delay) % 1.0;
                      final opacity = value < 0.5 ? value * 2 : 2 - (value * 2);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Opacity(
                          opacity: opacity.clamp(0.3, 1.0),
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.deepPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                widget.message,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkText,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'With all your love 💕',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.lightText,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOrEmoji({
    String? imagePath,
    required String emoji,
    required double size,
  }) {
    if (imagePath != null && imagePath.isNotEmpty) {
      return Image.asset(
        imagePath,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Text(
            emoji,
            style: TextStyle(fontSize: size * 0.7),
          );
        },
      );
    } else {
      return Text(
        emoji,
        style: TextStyle(fontSize: size * 0.7),
      );
    }
  }
}