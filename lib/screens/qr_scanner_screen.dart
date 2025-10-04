// lib/screens/qr_scanner_screen.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:love_letter_app/services/qr_service.dart';
import 'package:love_letter_app/services/storage_service.dart';
import 'package:love_letter_app/utils/theme.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({Key? key}) : super(key: key);

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  late MobileScannerController controller;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onBarcodeDetected(BarcodeCapture capture) async {
    if (_isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final qrData = barcode.rawValue;
    
    if (qrData == null || qrData.isEmpty) return;

    setState(() => _isProcessing = true);
    
    try {
      // Validate and parse QR data
      final invitation = QRService.instance.parseQRData(qrData);
      if (invitation == null) {
        _showError('Invalid love letter QR code');
        return;
      }

      // Check if invitation already exists
      final existing = await StorageService.instance.getInvitationById(invitation.id);
      if (existing != null) {
        _showError('This love letter has already been added');
        return;
      }

      // Save the invitation
      final success = await StorageService.instance.saveInvitation(invitation);
      if (success) {
        _showSuccess('Love letter received! 💕');
        // Return to main screen with success flag
        Navigator.pop(context, true);
      } else {
        _showError('Failed to save love letter');
      }
      
    } catch (e) {
      _showError('Error processing QR code: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade400,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade400,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleFlash() async {
    await controller.toggleTorch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Love Letter'),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          if (!kIsWeb) // Flash only available on mobile
            IconButton(
              icon: const Icon(Icons.flash_on, color: Colors.white),
              onPressed: _toggleFlash,
            ),
        ],
      ),
      body: _buildScanner(),
    );
  }

  Widget _buildScanner() {
    return Stack(
      children: [
        // Mobile Scanner - Works on both web and mobile!
        MobileScanner(
          controller: controller,
          onDetect: _onBarcodeDetected,
          errorBuilder: (context, error) {
            return _buildErrorView(error.errorDetails?.message ?? 'Camera error');
          },
        ),
        
        // Custom overlay
        Container(
          decoration: ShapeDecoration(
            shape: QrScannerOverlayShape(
              borderColor: AppTheme.softGold,
              borderRadius: 16,
              borderLength: 30,
              borderWidth: 8,
              cutOutSize: 250,
            ),
          ),
        ),
        
        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.7),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.softGold),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing love letter...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Instructions
        Positioned(
          bottom: 100,
          left: 0,
          right: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code_scanner,
                  color: AppTheme.softGold,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Point your camera at the QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  kIsWeb 
                    ? 'Allow camera access when prompted by your browser 📷'
                    : 'Make sure the QR code is clearly visible within the frame',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorView(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 80,
              color: Colors.white70,
            ),
            const SizedBox(height: 24),
            const Text(
              'Camera Access Required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (kIsWeb) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.softGold.withOpacity(0.3),
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📱 Web Camera Tips:',
                      style: TextStyle(
                        color: AppTheme.softGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Allow camera access in your browser\n'
                      '• Use HTTPS or localhost\n'
                      '• Works best on Chrome, Firefox, Safari\n'
                      '• Check browser camera permissions',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, false),
              style: AppTheme.secondaryButtonStyle,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Letters'),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom overlay shape for scanner
class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double borderLength;
  final double borderRadius;
  final double cutOutSize;

  const QrScannerOverlayShape({
    this.borderColor = Colors.white,
    this.borderWidth = 4.0,
    this.borderLength = 40,
    this.borderRadius = 0,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path path = Path()..addRect(rect);
    
    final center = rect.center;
    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    path.addRRect(RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)));
    return path;
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final center = rect.center;
    final cutOutRect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    // Draw corner brackets
    final corners = [
      cutOutRect.topLeft,
      cutOutRect.topRight,
      cutOutRect.bottomLeft,
      cutOutRect.bottomRight,
    ];

    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      canvas.drawPath(_createCornerPath(corner, i), paint);
    }
  }

  Path _createCornerPath(Offset corner, int cornerIndex) {
    final path = Path();
    
    switch (cornerIndex) {
      case 0: // Top-left
        path.moveTo(corner.dx - borderLength, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy + borderLength);
        break;
      case 1: // Top-right
        path.moveTo(corner.dx + borderLength, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy + borderLength);
        break;
      case 2: // Bottom-left
        path.moveTo(corner.dx - borderLength, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy - borderLength);
        break;
      case 3: // Bottom-right
        path.moveTo(corner.dx + borderLength, corner.dy);
        path.lineTo(corner.dx, corner.dy);
        path.lineTo(corner.dx, corner.dy - borderLength);
        break;
    }
    
    return path;
  }

  @override
  ShapeBorder scale(double t) => QrScannerOverlayShape(
    borderColor: borderColor,
    borderWidth: borderWidth,
    borderLength: borderLength,
    borderRadius: borderRadius,
    cutOutSize: cutOutSize,
  );
}