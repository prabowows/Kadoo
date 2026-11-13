import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class ScratchCardWidget extends StatefulWidget {
  final String prizeName;
  final VoidCallback onFinish;

  const ScratchCardWidget({
    Key? key,
    required this.prizeName,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<ScratchCardWidget> createState() => _ScratchCardWidgetState();
}

class _ScratchCardWidgetState extends State<ScratchCardWidget> {
  final List<Offset> _points = [];
  bool _isRevealed = false;

  void _addPoint(Offset localPosition) {
    if (_isRevealed) return;
    if (_points.length % 5 == 0) {
      SoundService.playScratch();
    }
    setState(() {
      _points.add(localPosition);
      if (_points.length > 55) {
        _isRevealed = true;
        SoundService.playWinFanfare();
        Future.delayed(const Duration(milliseconds: 1000), widget.onFinish);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.shade400),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
              SizedBox(width: 6),
              Text(
                'Gosok Kartu Emas di Bawah Ini',
                style: TextStyle(
                  color: Color(0xFF78350F),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 320,
          height: 190,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFACC15), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Revealed Background Underneath
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF312E81), Color(0xFF4C1D95), Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎁', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 4),
                      const Text(
                        'SELAMAT KAMU MENDAPATKAN',
                        style: TextStyle(
                          color: Color(0xFFFDE047),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          widget.prizeName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scratchable Layer
              if (!_isRevealed)
                GestureDetector(
                  onPanUpdate: (details) => _addPoint(details.localPosition),
                  onPanDown: (details) => _addPoint(details.localPosition),
                  child: CustomPaint(
                    size: const Size(320, 190),
                    painter: ScratchPainter(_points),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!_isRevealed && _points.length > 15)
          TextButton(
            onPressed: () {
              setState(() {
                _isRevealed = true;
              });
              Future.delayed(const Duration(milliseconds: 1000), widget.onFinish);
            },
            child: const Text(
              'Buka Langsung',
              style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          )
        else
          const Text(
            'Usapkan jari atau kursor ke atas kartu emas',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
      ],
    );
  }
}

class ScratchPainter extends CustomPainter {
  final List<Offset> points;

  ScratchPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Metallic gold paint
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFD4AF37), Color(0xFFFFDF73), Color(0xFFAA771C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), goldPaint);

    // Text on foil
    const textStyle = TextStyle(
      color: Colors.black26,
      fontSize: 14,
      fontWeight: FontWeight.w900,
      letterSpacing: 2,
    );
    final textSpan = TextSpan(text: '★ GOSOK DISINI ★', style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2),
    );

    // Erase points
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear
      ..strokeWidth = 40
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 22, clearPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ScratchPainter oldDelegate) => true;
}
