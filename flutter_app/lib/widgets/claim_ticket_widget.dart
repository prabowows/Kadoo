import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models.dart';
import '../services/sound_service.dart';

class ClaimTicketWidget extends StatefulWidget {
  final ParticipantLead lead;
  final String roomName;
  final String roomCode;

  const ClaimTicketWidget({
    Key? key,
    required this.lead,
    required this.roomName,
    required this.roomCode,
  }) : super(key: key);

  @override
  State<ClaimTicketWidget> createState() => _ClaimTicketWidgetState();
}

class _ClaimTicketWidgetState extends State<ClaimTicketWidget> {
  bool _copied = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    // Trigger confetti burst & victory fanfare
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      SoundService.playWinFanfare();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _copy() {
    Clipboard.setData(ClipboardData(text: widget.lead.claimCode));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kode tiket berhasil disalin!'),
        backgroundColor: Color(0xFFDC2626),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Center(
          child: Container(
            width: 350,
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Red Ribbon Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '★ TIKET RESMI KLAIM DOORPRIZE ★',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.roomName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Room Event: ${widget.roomCode}',
                        style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
                  child: Column(
                    children: [
                      const Text(
                        'SELAMAT, KAMU MEMENANGKAN:',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Prize Box
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
                        ),
                        child: Column(
                          children: [
                            const Text('🎁', style: TextStyle(fontSize: 38)),
                            const SizedBox(height: 6),
                            Text(
                              widget.lead.prizeWon,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFDC2626),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // QR Code Redemption & Claim Code Box
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            // Scannable QR Code
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: QrImageView(
                                data: widget.lead.claimCode,
                                version: QrVersions.auto,
                                size: 120,
                                eyeStyle: const QrEyeStyle(
                                  eyeShape: QrEyeShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                                dataModuleStyle: const QrDataModuleStyle(
                                  dataModuleShape: QrDataModuleShape.square,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'KODE KLAIM BOOTH',
                              style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget.lead.claimCode,
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: const EdgeInsets.all(6),
                                  onPressed: _copy,
                                  icon: Icon(
                                    _copied ? Icons.check_circle_rounded : Icons.copy_rounded,
                                    color: const Color(0xFFFDE047),
                                    size: 18,
                                  ),
                                  tooltip: 'Salin Kode',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: widget.lead.isClaimed
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: widget.lead.isClaimed
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.lead.isClaimed
                                  ? Icons.check_circle_rounded
                                  : Icons.stars_rounded,
                              size: 16,
                              color: widget.lead.isClaimed
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.lead.isClaimed
                                  ? 'SUDAH DIAMBIL DI BOOTH'
                                  : 'BELUM DIAMBIL (Tunjukkan ke Panitia)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: widget.lead.isClaimed
                                    ? const Color(0xFF065F46)
                                    : const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Participant Summary
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildRow('Pemenang:', widget.lead.fullName),
                            const SizedBox(height: 4),
                            _buildRow('Sekolah:', '${widget.lead.schoolName} (${widget.lead.schoolCity})'),
                            const SizedBox(height: 4),
                            _buildRow('Minat Prodi:', widget.lead.studyInterest),
                            const SizedBox(height: 4),
                            _buildRow('WhatsApp:', widget.lead.waNumber),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tunjukkan QR/kode tiket ini ke panitia di booth Computer Science Binus @Semarang untuk mengambil hadiah fisik.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 10, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Confetti Emitter Overlay
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [
            Color(0xFFEF4444),
            Color(0xFF3B82F6),
            Color(0xFF10B981),
            Color(0xFFF59E0B),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
          numberOfParticles: 35,
          gravity: 0.2,
          emissionFrequency: 0.05,
        ),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
