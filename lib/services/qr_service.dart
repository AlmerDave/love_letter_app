// lib/services/qr_service.dart
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:love_letter_app/models/invitation.dart';

class QRService {
  static QRService? _instance;
  static QRService get instance => _instance ??= QRService._();
  QRService._();

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

  // Validate and parse QR code data
  Invitation? parseQRData(String qrData) {
    try {
      final Map<String, dynamic> decoded = json.decode(qrData);
      
      // Validate QR code type
      if (decoded['type'] != 'love_letter_invitation') {
        throw Exception('Invalid QR code type');
      }
      
      // Validate version compatibility
      final version = decoded['version'];
      if (version != '1.0') {
        throw Exception('Incompatible QR code version: $version');
      }
      
      // Parse invitation data
      final invitationData = decoded['data'] as Map<String, dynamic>;
      return Invitation.fromJson(invitationData);
      
    } catch (e) {
      print('Error parsing QR data: $e');
      return null;
    }
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
    try {
      final decoded = json.decode(qrData);
      return decoded['type'] == 'love_letter_invitation' &&
             decoded['version'] == '1.0' &&
             decoded['data'] != null;
    } catch (e) {
      return false;
    }
  }
}