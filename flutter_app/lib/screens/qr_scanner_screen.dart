import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _hasScanned = false;

  static String extractRoomCode(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return '';

    // Handle URL containing /room/CODE
    if (text.contains('/room/')) {
      final parts = text.split('/room/');
      if (parts.length > 1) {
        final codePart = parts.last.split('?').first.split('#').first.split('/').first.trim();
        if (codePart.isNotEmpty) return codePart.toUpperCase();
      }
    }

    // Handle generic URI
    try {
      final uri = Uri.tryParse(text);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last.trim();
        if (last.isNotEmpty && !last.contains('.')) {
          return last.toUpperCase();
        }
      }
    } catch (_) {}

    return text.toUpperCase();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;

    for (final barcode in capture.barcodes) {
      final rawValue = barcode.rawValue;
      if (rawValue != null && rawValue.trim().isNotEmpty) {
        final code = extractRoomCode(rawValue);
        if (code.isNotEmpty) {
          _hasScanned = true;
          Navigator.pop(context, code);
          break;
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Izin Kamera Diperlukan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pastikan izin kamera diaktifkan di browser atau perangkat Anda untuk memindai QR.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Masukkan Kode Manual Saja'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Custom Dark Vignette & Cutout Overlay
          SafeArea(
            child: Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 24),
                      ),

                      // Title
                      const Text(
                        'Scan QR Booth',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),

                      // Actions: Torch & Flip
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => _controller.toggleTorch(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.flash_on_rounded, size: 20),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            onPressed: () => _controller.switchCamera(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(alpha: 0.5),
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.cameraswitch_rounded, size: 20),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Viewfinder Reticle
                Center(
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFEF4444), width: 2.5),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Corner Guides
                        ..._buildCornerGuides(),

                        // Center Subtle Scan Hint
                        Center(
                          child: Icon(
                            Icons.qr_code_2_rounded,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Helper text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: const Text(
                    'Arahkan kamera ke QR Code di booth',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const Spacer(),

                // Bottom Fallback Button
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.keyboard_rounded, color: Colors.white70, size: 18),
                    label: const Text(
                      'Punya Kode Manual? Ketik di sini',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
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

  List<Widget> _buildCornerGuides() {
    const double length = 22;
    const double thickness = 4;
    const Color color = Color(0xFFF59E0B);

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),

      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      Positioned(
        top: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),

      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        left: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),

      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: length,
          height: thickness,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
      Positioned(
        bottom: 0,
        right: 0,
        child: Container(
          width: thickness,
          height: length,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    ];
  }
}
