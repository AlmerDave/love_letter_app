// lib/services/qr_service.dart
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';
import 'package:love_letter_app/models/invitation_status.dart';
import 'package:uuid/uuid.dart';

class QRService {
  static QRService? _instance;
  static QRService get instance => _instance ??= QRService._();
  QRService._();

  final _uuid = const Uuid();

  // Generate QR code for invitation
  String generateQRData(Invitation invitation) {
    try {
      final qrData = {
        'type': 'love_letter_invitation',
        'version': '1.0',
        'data': invitation.toJson(),
        'generated_at': DateTime.now().toIso8601String(),
      };
      return json.encode(qrData);
    } catch (e) {
      throw Exception('Failed to generate QR data: $e');
    }
  }

  // Main parsing method - cascading parsers
  Invitation? parseQRData(String qrData) {
    if (qrData.isEmpty) return null;

    return _tryFullJSON(qrData) ??
           _tryPlainTextFormat(qrData) ??
           _trySmartExtraction(qrData);
  }

  // Parser 1: Full JSON format (original)
  Invitation? _tryFullJSON(String qrData) {
    try {
      if (!qrData.trim().startsWith('{')) return null;
      
      final Map<String, dynamic> decoded = json.decode(qrData);
      
      if (decoded['type'] != 'love_letter_invitation') {
        return null;
      }
      
      final version = decoded['version'];
      if (version != '1.0') {
        return null;
      }
      
      final invitationData = decoded['data'] as Map<String, dynamic>;
      return Invitation.fromJson(invitationData);
      
    } catch (e) {
      return null;
    }
  }

  // Parser 2: Plain text key-value format
  Invitation? _tryPlainTextFormat(String qrData) {
    try {
      final lines = qrData.trim().split('\n');
      Map<String, String> fields = {};
      
      for (var line in lines) {
        line = line.trim();
        if (line.isEmpty) continue;
        
        if (line.contains(':')) {
          final colonIndex = line.indexOf(':');
          String key = line.substring(0, colonIndex).trim().toLowerCase();
          String value = line.substring(colonIndex + 1).trim();
          
          // Normalize key names
          key = _normalizeKey(key);
          
          if (value.isNotEmpty) {
            fields[key] = value;
          }
        }
      }
      
      if (fields.containsKey('title') || fields.containsKey('message')) {
        return _buildInvitationFromFields(fields);
      }
    } catch (e) {
      print('Plain text parser error: $e');
      return null;
    }
    return null;
  }

  // Parser 3: Smart regex extraction (last resort)
  Invitation? _trySmartExtraction(String qrData) {
    try {
      Map<String, String> fields = {};
      
      // Extract title
      fields['title'] = _extractWithRegex(qrData, [
        r'title[:\s]+([^\n]+)',
        r'subject[:\s]+([^\n]+)',
        r'event[:\s]+([^\n]+)',
      ]) ?? '';
      
      // Extract message
      fields['message'] = _extractWithRegex(qrData, [
        r'message[:\s]+([^\n]+)',
        r'msg[:\s]+([^\n]+)',
        r'text[:\s]+([^\n]+)',
        r'note[:\s]+([^\n]+)',
      ]) ?? '';
      
      // Extract location
      fields['location'] = _extractWithRegex(qrData, [
        r'location[:\s]+([^\n]+)',
        r'place[:\s]+([^\n]+)',
        r'venue[:\s]+([^\n]+)',
        r'loc[:\s]+([^\n]+)',
      ]) ?? '';
      
      // Extract date
      fields['datetime'] = _extractWithRegex(qrData, [
        r'date(?:time)?[:\s]+([^\n]+)',
        r'when[:\s]+([^\n]+)',
        r'event\s*date[:\s]+([^\n]+)',
      ]) ?? '';
      
      // Extract unlock date
      fields['unlockdatetime'] = _extractWithRegex(qrData, [
        r'unlock(?:\s*date)?(?:time)?[:\s]+([^\n]+)',
        r'open(?:\s*on)?[:\s]+([^\n]+)',
        r'available[:\s]+([^\n]+)',
      ]) ?? '';
      
      if (fields['title']?.isNotEmpty == true || 
          fields['message']?.isNotEmpty == true) {
        return _buildInvitationFromFields(fields);
      }
    } catch (e) {
      print('Smart extraction error: $e');
      return null;
    }
    return null;
  }

  // Helper: Extract using multiple regex patterns
  String? _extractWithRegex(String text, List<String> patterns) {
    text = text.toLowerCase();
    for (var pattern in patterns) {
      try {
        final regex = RegExp(pattern, caseSensitive: false, multiLine: true);
        final match = regex.firstMatch(text);
        if (match != null && match.groupCount > 0) {
          final value = match.group(1)?.trim();
          if (value != null && value.isNotEmpty) {
            return value;
          }
        }
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  // Helper: Normalize key names
  String _normalizeKey(String key) {
    key = key.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    
    // Map alternative key names to standard ones
    const keyMap = {
      'subject': 'title',
      'event': 'title',
      'heading': 'title',
      'msg': 'message',
      'text': 'message',
      'note': 'message',
      'content': 'message',
      'place': 'location',
      'venue': 'location',
      'loc': 'location',
      'where': 'location',
      'when': 'datetime',
      'eventdate': 'datetime',
      'date': 'datetime',
      'time': 'datetime',
      'datetime': 'datetime',
      'unlock': 'unlockdatetime',
      'open': 'unlockdatetime',
      'openon': 'unlockdatetime',
      'available': 'unlockdatetime',
      'unlockdate': 'unlockdatetime',
      'image': 'imageurl',
      'img': 'imageurl',
      'picture': 'imageurl',
      'photo': 'imageurl',
    };
    
    return keyMap[key] ?? key;
  }

  // Helper: Build invitation from extracted fields
  Invitation _buildInvitationFromFields(Map<String, String> fields) {
    return Invitation(
      id: fields['id'] ?? _uuid.v4(),
      
      title: fields['title']?.isNotEmpty == true 
          ? fields['title']! 
          : 'Love Letter',
      
      message: fields['message']?.isNotEmpty == true 
          ? fields['message']! 
          : 'You have received a love letter!',
      
      location: fields['location']?.isNotEmpty == true 
          ? fields['location']! 
          : 'To be announced',
      
      dateTime: _parseFlexibleDate(fields['datetime']) ?? 
                DateTime.now().add(const Duration(days: 7)),
      
      unlockDateTime: _parseFlexibleDate(fields['unlockdatetime']) ?? 
                      DateTime.now(),
      
      status: _parseStatus(fields['status']) ?? InvitationStatus.pending,
      
      createdAt: _parseFlexibleDate(fields['createdat']) ?? DateTime.now(),
      
      imageUrl: fields['imageurl'],
    );
  }

  // Helper: Parse flexible date formats
  DateTime? _parseFlexibleDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    
    dateStr = dateStr.trim();
    
    // Try ISO format first
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      // Continue to other formats
    }
    
    // Try common formats
    try {
      // Format: 2025-11-15 3:00 PM or 2025-11-15 15:00
      final pattern1 = RegExp(
        r'(\d{4})-(\d{1,2})-(\d{1,2})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?',
        caseSensitive: false,
      );
      var match = pattern1.firstMatch(dateStr);
      if (match != null) {
        int year = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int day = int.parse(match.group(3)!);
        int hour = int.parse(match.group(4)!);
        int minute = int.parse(match.group(5)!);
        int second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        String? ampm = match.group(7)?.toUpperCase();
        
        if (ampm != null) {
          if (ampm == 'PM' && hour < 12) hour += 12;
          if (ampm == 'AM' && hour == 12) hour = 0;
        }
        
        return DateTime(year, month, day, hour, minute, second);
      }
      
      // Format: 11/15/2025 15:00 or 11/15/2025 3:00 PM
      final pattern2 = RegExp(
        r'(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?',
        caseSensitive: false,
      );
      match = pattern2.firstMatch(dateStr);
      if (match != null) {
        int month = int.parse(match.group(1)!);
        int day = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        int hour = int.parse(match.group(4)!);
        int minute = int.parse(match.group(5)!);
        int second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        String? ampm = match.group(7)?.toUpperCase();
        
        if (ampm != null) {
          if (ampm == 'PM' && hour < 12) hour += 12;
          if (ampm == 'AM' && hour == 12) hour = 0;
        }
        
        return DateTime(year, month, day, hour, minute, second);
      }
      
      // Format: Nov 15, 2025 3:00 PM
      final pattern3 = RegExp(
        r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[a-z]*\s+(\d{1,2}),?\s+(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)?',
        caseSensitive: false,
      );
      match = pattern3.firstMatch(dateStr);
      if (match != null) {
        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };
        int month = months[match.group(1)!.toLowerCase().substring(0, 3)]!;
        int day = int.parse(match.group(2)!);
        int year = int.parse(match.group(3)!);
        int hour = int.parse(match.group(4)!);
        int minute = int.parse(match.group(5)!);
        int second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
        String? ampm = match.group(7)?.toUpperCase();
        
        if (ampm != null) {
          if (ampm == 'PM' && hour < 12) hour += 12;
          if (ampm == 'AM' && hour == 12) hour = 0;
        }
        
        return DateTime(year, month, day, hour, minute, second);
      }
      
      // Format: 2025-11-15 (date only)
      final pattern4 = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
      match = pattern4.firstMatch(dateStr);
      if (match != null) {
        int year = int.parse(match.group(1)!);
        int month = int.parse(match.group(2)!);
        int day = int.parse(match.group(3)!);
        return DateTime(year, month, day);
      }
      
    } catch (e) {
      print('Date parsing error: $e');
    }
    
    return null;
  }

  // Helper: Parse status
  InvitationStatus? _parseStatus(String? statusStr) {
    if (statusStr == null || statusStr.isEmpty) return null;
    
    statusStr = statusStr.toLowerCase().trim();
    
    // Remove "InvitationStatus." prefix if present
    if (statusStr.startsWith('invitationstatus.')) {
      statusStr = statusStr.substring('invitationstatus.'.length);
    }
    
    for (var status in InvitationStatus.values) {
      if (status.toString().toLowerCase().endsWith(statusStr)) {
        return status;
      }
    }
    
    return null;
  }

  // Create QR code widget
  Widget buildQRCodeWidget({
    required Invitation invitation,
    double size = 200.0,
    Color foregroundColor = Colors.black,
    Color backgroundColor = Colors.white,
  }) {
    try {
      final qrData = generateQRData(invitation);
      
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              spreadRadius: 2.0,
            ),
          ],
        ),
        child: QrImageView(
          data: qrData,
          size: size,
          foregroundColor: foregroundColor,
          backgroundColor: backgroundColor,
          errorCorrectionLevel: QrErrorCorrectLevel.H,
          padding: const EdgeInsets.all(8.0),
        ),
      );
    } catch (e) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'QR Generation Failed',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  // Validate QR data before processing
  bool isValidQRData(String qrData) {
    return parseQRData(qrData) != null;
  }
}