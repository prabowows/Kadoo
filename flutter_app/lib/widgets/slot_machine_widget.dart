import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SlotMachineWidget extends StatefulWidget {
  final String prizeName;
  final VoidCallback onFinish;

  const SlotMachineWidget({
    Key? key,
    required this.prizeName,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<SlotMachineWidget> createState() => _SlotMachineWidgetState();
}

class _SlotMachineWidgetState extends State<SlotMachineWidget> {
  final List<String> _icons = ['🎁', '⭐', '💎', '🏆', '🎉', '🔥', '👑'];
  List<String> _reels = ['🎁', '🎁', '🎁'];
  bool _isSpinning = false;
  bool _hasFinished = false;

  void _spin() {
    if (_isSpinning || _hasFinished) return;

    setState(() {
      _isSpinning = true;
    });

    final random = Random();
    int ticks = 0;
    Timer.periodic(const Duration(milliseconds: 90), (timer) {
      ticks++;
      if (mounted) {
        setState(() {
          _reels = [
            _icons[random.nextInt(_icons.length)],
            _icons[random.nextInt(_icons.length)],
            _icons[random.nextInt(_icons.length)],
          ];
        });
        SoundService.playSlotSpin();
      }

      if (ticks > 28) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _reels = ['🎁', '🎁', '🎁'];
            _isSpinning = false;
            _hasFinished = true;
          });
          SoundService.playSlotStop();
          SoundService.playWinFanfare();
          Future.delayed(const Duration(milliseconds: 1000), widget.onFinish);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFF991B1B), Color(0xFF7F1D1D)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFFACC15), width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFACC15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '★ JACKPOT SPINNER ★',
                  style: TextStyle(
                    color: Color(0xFF7F1D1D),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Reels Window
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFDE047), width: 3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _reels.map((icon) {
                    return Container(
                      width: 72,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          icon,
                          style: const TextStyle(fontSize: 40),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Flashing Lights
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSpinning
                          ? (index % 2 == 0 ? Colors.yellow : Colors.greenAccent)
                          : Colors.amber,
                      boxShadow: const [
                        BoxShadow(color: Colors.amber, blurRadius: 6),
                      ],
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _isSpinning || _hasFinished ? null : _spin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: const Color(0xFF78350F),
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          child: Text(
            _isSpinning
                ? 'SPINNING...'
                : _hasFinished
                    ? 'JACKPOT!'
                    : '🎰 TARIK TUAS / SPIN!',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
