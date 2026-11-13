import 'dart:math';
import 'package:flutter/material.dart';
import '../services/sound_service.dart';

class SpinWheelWidget extends StatefulWidget {
  final List<dynamic> prizes;
  final String targetPrizeName;
  final VoidCallback onFinish;

  const SpinWheelWidget({
    Key? key,
    required this.prizes,
    required this.targetPrizeName,
    required this.onFinish,
  }) : super(key: key);

  @override
  State<SpinWheelWidget> createState() => _SpinWheelWidgetState();
}

class _SpinWheelWidgetState extends State<SpinWheelWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _currentAngle = 0.0;
  bool _isSpinning = false;
  bool _hasFinished = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _spin() {
    if (_isSpinning || _hasFinished) return;

    final prizes = widget.prizes.isNotEmpty
        ? widget.prizes
        : [
            {'name': 'Hadiah 1', 'color': '#EF4444'},
            {'name': 'Hadiah 2', 'color': '#3B82F6'},
            {'name': 'Hadiah 3', 'color': '#10B981'},
            {'name': 'Hadiah 4', 'color': '#F59E0B'},
          ];

    final int total = prizes.length;
    final double arc = (2 * pi) / total;

    int targetIdx = prizes.indexWhere((p) => p['name'] == widget.targetPrizeName);
    if (targetIdx == -1) targetIdx = 0;

    // Calculate angle so targetIdx lands under top arrow (3*pi/2)
    final double targetCenter = targetIdx * arc + (arc / 2);
    const double pointerAngle = 3 * pi / 2;
    const double extraRotations = 6 * 2 * pi;
    final double finalAngle = extraRotations + (pointerAngle - targetCenter);

    int lastTickIndex = -1;
    _animation = Tween<double>(begin: _currentAngle, end: finalAngle).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _currentAngle = _animation.value;
        });
        final currentTick = (_animation.value / (arc / 2)).floor();
        if (currentTick != lastTickIndex) {
          lastTickIndex = currentTick;
          SoundService.playWheelTick();
        }
      });

    setState(() {
      _isSpinning = true;
    });

    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _isSpinning = false;
        _hasFinished = true;
      });
      SoundService.playWinFanfare();
      Future.delayed(const Duration(milliseconds: 1000), widget.onFinish);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer golden ring
            Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706), Color(0xFF78350F)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 4,
                  )
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: Transform.rotate(
                angle: _currentAngle,
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: WheelPainter(widget.prizes),
                ),
              ),
            ),

            // Top pointer
            Positioned(
              top: 0,
              child: CustomPaint(
                size: const Size(28, 36),
                painter: PointerPainter(),
              ),
            ),

            // Center Pin
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFACC15), width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 6),
                ],
              ),
              child: const Center(
                child: Icon(Icons.star, color: Color(0xFFFACC15), size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isSpinning || _hasFinished ? null : _spin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 8,
          ),
          child: Text(
            _isSpinning
                ? 'SEDANG MEMUTAR...'
                : _hasFinished
                    ? 'SELESAI!'
                    : '🎡 PUTAR RODA SEKARANG!',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class WheelPainter extends CustomPainter {
  final List<dynamic> prizes;

  WheelPainter(this.prizes);

  @override
  void paint(Canvas canvas, Size size) {
    final double center = size.width / 2;
    final double radius = center;
    final int count = prizes.isNotEmpty ? prizes.length : 4;
    final double arc = (2 * pi) / count;

    final defaultColors = [
      const Color(0xFFEF4444),
      const Color(0xFF3B82F6),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];

    for (int i = 0; i < count; i++) {
      Color fill = defaultColors[i % defaultColors.length];
      if (i < prizes.length && prizes[i]['color'] != null) {
        final hex = prizes[i]['color'].toString().replaceAll('#', '');
        if (hex.length == 6) {
          fill = Color(int.parse('FF$hex', radix: 16));
        }
      }

      final paint = Paint()
        ..color = fill
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(center, center), radius: radius),
        i * arc,
        arc,
        true,
        paint,
      );

      // Border line
      final linePaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(center, center),
        Offset(center + radius * cos(i * arc), center + radius * sin(i * arc)),
        linePaint,
      );

      // Text label
      canvas.save();
      canvas.translate(center, center);
      canvas.rotate(i * arc + (arc / 2));

      final text = i < prizes.length ? (prizes[i]['name'] ?? 'Prize') : 'Prize $i';
      final span = TextSpan(
        text: text.length > 14 ? '${text.substring(0, 14)}...' : text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
        ),
      );
      final textPainter = TextPainter(
        text: span,
        textAlign: TextAlign.right,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius - 30);

      textPainter.paint(canvas, Offset(radius - textPainter.width - 15, -textPainter.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFACC15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, paint);

    final borderPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
