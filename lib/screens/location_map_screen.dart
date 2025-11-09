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

class _LocationMapScreenState extends State<LocationMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  List<Polyline> _polylines = [];
  String? _currentUserId;
  bool _isSharing = true;
  StreamSubscription? _locationsSubscription;
  double? _distanceInMeters;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    _currentUserId = await UserService.getUserId();
    _listenToLocations();
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

    locationsData.forEach((userId, userData) {
      final userMap = Map<String, dynamic>.from(userData);
      
      if (userMap['isSharing'] == true) {
        final lat = userMap['lat'] as double;
        final lng = userMap['lng'] as double;
        final nickname = userMap['nickname'] as String;
        final position = LatLng(lat, lng);

        positions.add(position);

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
                  // Cute pin with heart
                  Container(
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
                  ),
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
      
      // Many kiss emojis densely packed - always 20-30 kisses regardless of distance
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
    });

    // Center map to show all markers
    if (positions.isNotEmpty) {
      _centerMapOnMarkers(positions);
    }
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
        content: Text(
          isYou ? '📍 You are here!' : '💕 $nickname is here!',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: isYou ? Colors.pink.shade400 : Colors.purple.shade400,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _refreshMyLocation() async {
    try {
      final position = await LocationService.getCurrentLocation();
      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to get location')),
          );
        }
        return;
      }

      final nickname = await UserService.getNickname();
      
      await FirebaseService.instance.locationsRef
          .child(_currentUserId!)
          .update({
        'lat': position.latitude,
        'lng': position.longitude,
        'lastUpdated': ServerValue.timestamp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('📍 Location updated!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      print('Error refreshing location: $e');
    }
  }

  @override
  void dispose() {
    _locationsSubscription?.cancel();
    
    // Stop sharing when leaving screen
    if (_currentUserId != null) {
      FirebaseService.instance.locationsRef
          .child(_currentUserId!)
          .update({'isSharing': false});
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Where Are You? 💕',
          style: AppTheme.romanticTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.primaryLavender.withOpacity(0.3),
        elevation: 0,
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
          
          // People count indicator
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
                    _markers.length == 2 
                      ? 'Both online 💕'
                      : 'Only you 💕',
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
          
          // Refresh location button
          Positioned(
            bottom: 100,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'refresh',
              onPressed: _refreshMyLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              child: Icon(
                Icons.my_location,
                color: AppTheme.deepPurple,
              ),
            ),
          ),
        ],
      ),
    );
  }
}