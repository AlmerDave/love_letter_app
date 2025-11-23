// lib/screens/location_map_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:love_letter_app/services/firebase_service.dart';
import 'package:love_letter_app/services/location_service.dart';
import 'package:love_letter_app/services/user_service.dart';
import 'package:love_letter_app/utils/theme.dart';

class LocationMapScreen extends StatefulWidget {
  const LocationMapScreen({Key? key}) : super(key: key);

  @override
  State<LocationMapScreen> createState() => _LocationMapScreenState();
}

class _LocationMapScreenState extends State<LocationMapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  String? _currentUserId;
  bool _isSharing = true;
  bool _isInitialLoading = true; // ✨ NEW: Track initial loading
  bool _isRefreshing = false; // ✨ NEW: Track manual refresh
  StreamSubscription? _locationsSubscription;
  Timer? _locationUpdateTimer;
  double? _distanceInMeters;
  int _peopleOnline = 0; // ✨ NEW: Track actual people count (not kiss emojis)
  DateTime? _lastUpdateTime; // ✨ NEW: Track last update time
  
  // ✨ NEW: Animation controller for pulse effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializePulseAnimation();
    _initializeMapWithLoading();
  }

  void _initializePulseAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  /// ✨ NEW: Initialize with loading screen
  Future<void> _initializeMapWithLoading() async {
    try {
      _currentUserId = await UserService.getUserId();
      
      // Get initial location immediately
      await _updateMyLocation(silent: true, isInitial: true);
      
      // Start listening to Firebase
      _listenToLocations();
      
      // Start periodic updates
      _startLocationUpdates();
      
      // Wait a bit for Firebase to sync
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isInitialLoading = false;
        });
        _showErrorMessage('Failed to initialize map: $e');
      }
    }
  }

  /// ✨ UPDATED: Periodically update location every 10 seconds while screen is active
  void _startLocationUpdates() {
    _locationUpdateTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) async {
        if (_isSharing && mounted && !_isInitialLoading) {
          await _updateMyLocation(silent: true);
        }
      },
    );
  }

  void _listenToLocations() {
    _locationsSubscription = FirebaseService.instance.locationsRef
        .onValue
        .listen((event) {
      if (event.snapshot.value == null) return;

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);
      _updateMarkers(data);
    });
  }

  void _updateMarkers(Map<String, dynamic> locationsData) {
    List<Marker> newMarkers = [];
    List<LatLng> positions = [];
    List<Polyline> newPolylines = [];
    int peopleCount = 0; // ✨ NEW: Count actual people, not markers

    locationsData.forEach((userId, userData) {
      final userMap = Map<String, dynamic>.from(userData);
      
      if (userMap['isSharing'] == true) {
        final lat = userMap['lat'] as double;
        final lng = userMap['lng'] as double;
        final nickname = userMap['nickname'] as String;
        final position = LatLng(lat, lng);

        positions.add(position);
        peopleCount++; // ✨ Increment people count

        // Choose color based on if it's current user
        final isCurrentUser = userId == _currentUserId;
        final markerColor = isCurrentUser ? Colors.pink : Colors.purple;

        newMarkers.add(
          Marker(
            point: position,
            width: 80,
            height: 80,
            child: GestureDetector(
              onTap: () {
                _showMarkerInfo(nickname, isCurrentUser);
              },
              child: Column(
                children: [
                  // Cute pin with heart + pulse animation for current user
                  isCurrentUser
                      ? AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: child,
                            );
                          },
                          child: _buildMarkerPin(markerColor),
                        )
                      : _buildMarkerPin(markerColor),
                  // Nickname below pin
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: markerColor, width: 1.5),
                    ),
                    child: Text(
                      nickname,
                      style: TextStyle(
                        color: markerColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });

    // Draw kiss emojis between markers if there are exactly 2 people
    if (positions.length == 2) {
      _distanceInMeters = _calculateDistance(positions[0], positions[1]);
      
      // Many kiss emojis densely packed - always 30 kisses
      final numberOfKisses = 30;
      
      for (int i = 1; i < numberOfKisses; i++) {
        final ratio = i / numberOfKisses;
        final lat = positions[0].latitude + (positions[1].latitude - positions[0].latitude) * ratio;
        final lng = positions[0].longitude + (positions[1].longitude - positions[0].longitude) * ratio;
        
        newMarkers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 25,
            height: 25,
            child: const Text(
              '😘',
              style: TextStyle(fontSize: 16),
            ),
          ),
        );
      }
    } else {
      _distanceInMeters = null;
    }

    setState(() {
      _markers = newMarkers;
      _polylines = newPolylines;
      _peopleOnline = peopleCount; // ✨ NEW: Store people count
    });

    // Center map to show all markers
    if (positions.isNotEmpty) {
      _centerMapOnMarkers(positions);
    }
  }

  Widget _buildMarkerPin(Color markerColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: markerColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: markerColor.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  // Calculate distance between two points in meters
  double _calculateDistance(LatLng point1, LatLng point2) {
    const distance = Distance();
    return distance.as(LengthUnit.Meter, point1, point2);
  }

  // Format distance for display
  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(2)} km';
    }
  }

  void _centerMapOnMarkers(List<LatLng> positions) {
    if (positions.isEmpty) return;

    // Calculate bounds
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (var pos in positions) {
      if (pos.latitude < minLat) minLat = pos.latitude;
      if (pos.latitude > maxLat) maxLat = pos.latitude;
      if (pos.longitude < minLng) minLng = pos.longitude;
      if (pos.longitude > maxLng) maxLng = pos.longitude;
    }

    // Add some padding
    final latPadding = (maxLat - minLat) * 0.2;
    final lngPadding = (maxLng - minLng) * 0.2;

    final bounds = LatLngBounds(
      LatLng(minLat - latPadding, minLng - lngPadding),
      LatLng(maxLat + latPadding, maxLng + lngPadding),
    );

    // Fit map to bounds
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _showMarkerInfo(String nickname, bool isYou) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isYou ? Icons.person : Icons.favorite,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isYou ? '📍 You are here!' : '💕 $nickname is here!',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        backgroundColor: isYou ? Colors.pink.shade400 : Colors.purple.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// ✨ UPDATED: Better UX with loading state and feedback
  Future<void> _updateMyLocation({bool silent = false, bool isInitial = false}) async {
    if (!silent) {
      setState(() {
        _isRefreshing = true;
      });
    }

    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        if (!silent && mounted) {
          _showErrorMessage('Failed to get location');
        }
        return;
      }

      await FirebaseService.instance.locationsRef
          .child(_currentUserId!)
          .update({
        'lat': position.latitude,
        'lng': position.longitude,
        'isSharing': true,
        'lastUpdated': ServerValue.timestamp,
      });

      // Update last update time
      setState(() {
        _lastUpdateTime = DateTime.now();
      });

      // ✨ Trigger pulse animation on successful update
      if (!isInitial) {
        _pulseController.forward().then((_) => _pulseController.reverse());
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text('📍 Location updated!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error updating location: $e');
      if (!silent && mounted) {
        _showErrorMessage('Error: $e');
      }
    } finally {
      if (!silent && mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  /// ✨ CRITICAL: Stop sharing when user leaves the screen
  Future<void> _stopSharing() async {
    if (_currentUserId == null) return;

    try {
      await FirebaseService.instance.locationsRef
          .child(_currentUserId!)
          .update({'isSharing': false});
      
      print('🛑 Stopped sharing location for user: $_currentUserId');
    } catch (e) {
      print('Error stopping location sharing: $e');
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// ✨ NEW: Format last update time
  String _getLastUpdateText() {
    if (_lastUpdateTime == null) return 'Just now';
    
    final difference = DateTime.now().difference(_lastUpdateTime!);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return '${difference.inHours}h ago';
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions and timers
    _locationsSubscription?.cancel();
    _locationUpdateTimer?.cancel();
    _pulseController.dispose();
    
    // ✨ CRITICAL: Stop sharing location when leaving screen (fire and forget)
    _stopSharing();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✨ NEW: Show loading screen on initial load
    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: AppTheme.warmCream,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated heart
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.2),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.favorite,
                      size: 80,
                      color: AppTheme.deepPurple,
                    ),
                  );
                },
                onEnd: () {
                  // Loop animation
                  if (mounted && _isInitialLoading) {
                    setState(() {});
                  }
                },
              ),
              const SizedBox(height: 32),
              CircularProgressIndicator(
                color: AppTheme.deepPurple,
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              Text(
                'Finding your location... 💕',
                style: AppTheme.romanticTitle.copyWith(
                  fontSize: 18,
                  color: AppTheme.deepPurple,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.deepPurple),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Where Are You? 💕',
          style: AppTheme.romanticTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLavender.withOpacity(0.3),
        elevation: 0,
        actions: [
          // Stop sharing button
          IconButton(
            icon: Icon(
              _isSharing ? Icons.visibility : Icons.visibility_off,
              color: _isSharing ? AppTheme.deepPurple : Colors.grey,
            ),
            onPressed: () async {
              setState(() {
                _isSharing = !_isSharing;
              });
              
              if (_isSharing) {
                await _updateMyLocation();
              } else {
                await _stopSharing();
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        _isSharing ? Icons.visibility : Icons.visibility_off,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSharing 
                            ? '👀 Location sharing enabled' 
                            : '🙈 Location sharing disabled',
                      ),
                    ],
                  ),
                  backgroundColor: _isSharing ? Colors.green : Colors.grey,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // OpenStreetMap
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(14.5995, 120.9842), // Manila
              initialZoom: 12,
              minZoom: 3,
              maxZoom: 18,
            ),
            children: [
              // Tile layer - this loads the map tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.love_letter_app',
                tileBuilder: (context, widget, tile) {
                  // Add a subtle pink tint for romantic vibe
                  return ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.pink.withOpacity(0.05),
                      BlendMode.srcOver,
                    ),
                    child: widget,
                  );
                },
              ),
              // Polyline layer (line between markers)
              PolylineLayer(
                polylines: _polylines,
              ),
              // Markers layer
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          
          // ✨ UPDATED: People count indicator with correct count
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite, color: Colors.pink.shade400, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _peopleOnline >= 2 
                      ? 'Both online 💕'
                      : 'Only you 😭',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Distance indicator (when 2 people are sharing)
          if (_distanceInMeters != null)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.deepPurple,
                      AppTheme.primaryLavender,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.deepPurple.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.straight, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _formatDistance(_distanceInMeters!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      ' apart',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // ✨ UPDATED: Refresh location button with loading state
          Positioned(
            bottom: 100, // ✨ Fixed: Moved up to avoid bottom nav
            right: 24,
            child: Column(
              children: [
                // Last update timestamp
                if (_lastUpdateTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getLastUpdateText(),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                // Refresh button with loading state
                FloatingActionButton(
                  heroTag: 'refresh',
                  onPressed: _isRefreshing ? null : () => _updateMyLocation(),
                  backgroundColor: _isRefreshing 
                      ? Colors.grey.shade300 
                      : Colors.white,
                  elevation: 4,
                  child: _isRefreshing
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.deepPurple,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          Icons.my_location,
                          color: AppTheme.deepPurple,
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}