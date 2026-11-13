import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class GashaponWidget extends StatefulWidget {
  final String prizeName;
  final VoidCallback onFinish;

  const GashaponWidget({
    Key? key,
    required this.prizeName,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<GashaponWidget> createState() => _GashaponWidgetState();
}

class _GashaponWidgetState extends State<GashaponWidget> {
  double _crankAngle = 0.0;
  bool _capsuleDropped = false;
  bool _hasFinished = false;

  final List<Color> _capsuleColors = [
    Colors.red,
    Colors.blue,
    Colors.amber,
    Colors.purple,
    Colors.green,
    Colors.pink,
  ];

  void _turnCrank() {
    if (_capsuleDropped || _hasFinished) return;

    SoundService.playWheelTick();
    setState(() {
      _crankAngle += pi;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _capsuleDropped = true;
        });
        SoundService.playSlotStop();
      }
    });
  }

  void _openCapsule() {
    if (!_capsuleDropped || _hasFinished) return;
    setState(() {
      _hasFinished = true;
    });
    SoundService.playWinFanfare();
    Future.delayed(const Duration(milliseconds: 1000), widget.onFinish);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF0F766E), Color(0xFF115E59)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF5EEAD4), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.teal.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '★ GASHAPON DOX ★',
                  style: TextStyle(
                    color: Color(0xFF115E59),
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Glass Dome with Capsules
              Container(
                width: 220,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(100),
                    bottom: Radius.circular(20),
                  ),
                  border: Border.all(color: Colors.white60, width: 3),
                ),
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: _capsuleColors.map((color) {
                        return Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [color, Colors.white],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Controls (Dispenser Hole & Crank)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF134E4A),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Output hole
                    Container(
                      width: 80,
                      height: 70,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.shade300, width: 2),
                      ),
                      child: Center(
                        child: _capsuleDropped && !_hasFinished
                            ? GestureDetector(
                                onTap: _openCapsule,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [Colors.redAccent, Colors.white],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    boxShadow: [
                                      BoxShadow(color: Colors.amber, blurRadius: 8),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'TAP!',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : const Text(
                                'Kapsul',
                                style: TextStyle(color: Colors.white38, fontSize: 11),
                              ),
                      ),
                    ),

                    // Turn Crank
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _turnCrank,
                          child: AnimatedRotation(
                            turns: _crankAngle / (2 * pi),
                            duration: const Duration(milliseconds: 400),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [Color(0xFFFDE047), Color(0xFFD97706)],
                                ),
                                boxShadow: [
                                  BoxShadow(color: Colors.black38, blurRadius: 6),
                                ],
                              ),
                              child: const Icon(Icons.sync, color: Color(0xFF78350F), size: 30),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'PUTAR KRAN',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_capsuleDropped && !_hasFinished)
          const Text(
            '👆 Kapsul keluar! Ketuk kapsul untuk membuka!',
            style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13),
          )
        else
          const Text(
            'Putar kran kuning untuk menjatuhkan kapsul doorprize',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }
}
