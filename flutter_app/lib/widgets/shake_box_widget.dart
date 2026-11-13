import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/sound_service.dart';

class ShakeBoxWidget extends StatefulWidget {
  final String prizeName;
  final VoidCallback onFinish;

  const ShakeBoxWidget({
    Key? key,
    required this.prizeName,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<ShakeBoxWidget> createState() => _ShakeBoxWidgetState();
}

class _ShakeBoxWidgetState extends State<ShakeBoxWidget>
    with SingleTickerProviderStateMixin {
  int _shakeCount = 0;
  final int _targetShakes = 12;
  bool _hasFinished = false;
  StreamSubscription? _accelerometerSub;
  late AnimationController _wiggleController;

  @override
  void initState() {
    super.initState();
    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: -0.1,
      upperBound: 0.1,
    );

    // Listen to accelerometer if mobile
    if (!kIsWeb) {
      try {
        _accelerometerSub = accelerometerEventStream().listen((event) {
          final double magnitude = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          if (magnitude > 18) {
            _incrementShake();
          }
        });
      } catch (e) {
        // sensor fallback
      }
    }
  }

  @override
  void dispose() {
    _accelerometerSub?.cancel();
    _wiggleController.dispose();
    super.dispose();
  }

  void _incrementShake() {
    if (_hasFinished) return;

    _wiggleController.forward(from: 0).then((_) => _wiggleController.reverse());
    SoundService.playShakeRattle();

    setState(() {
      _shakeCount++;
      if (_shakeCount >= _targetShakes) {
        _hasFinished = true;
        SoundService.playWinFanfare();
        Future.delayed(const Duration(milliseconds: 1000), widget.onFinish);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double pct = (_shakeCount / _targetShakes).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                kIsWeb ? Icons.mouse : Icons.smartphone,
                size: 16,
                color: const Color(0xFFDC2626),
              ),
              const SizedBox(width: 6),
              Text(
                kIsWeb
                    ? 'Mode Desktop: Kocok Kado dengan Tap / Klik Cepat!'
                    : 'Goyangkan Smartphone Kamu!',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 3D Gift Box with Wiggle
        GestureDetector(
          onTap: _incrementShake,
          child: AnimatedBuilder(
            animation: _wiggleController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _wiggleController.value,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFEE2E2), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _hasFinished
                        ? const Text('🎉', style: TextStyle(fontSize: 80))
                        : Lottie.asset(
                            'assets/lottie/gift_box.json',
                            width: 140,
                            height: 140,
                            fit: BoxFit.contain,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 18),

        // Progress Bar
        SizedBox(
          width: 260,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 12,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(pct * 100).toInt()}% Terbuka ($_shakeCount/$_targetShakes Kocokan)',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: _hasFinished ? null : _incrementShake,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.4),
          ),
          child: Text(
            _hasFinished
                ? 'KADO BERHASIL DIBUKA!'
                : kIsWeb
                    ? '🖱️ KLIK CEPAT KOCOK KADO!'
                    : '📱 GOYANGKAN HP ATAU TAP!',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
          ),
        ),
      ],
    );
  }
}
