import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api_service.dart';
import '../services/export_service.dart';
import 'room_screen.dart';
import 'admin_screen.dart';
import 'qr_scanner_screen.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocusNode = FocusNode();
  String? _loggedInAdmin;

  @override
  void initState() {
    super.initState();
    _checkAdminSession();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocusNode.dispose();
    super.dispose();
  }

  Future<void> _checkAdminSession() async {
    final admin = await ApiService.getLoggedInAdmin();
    if (mounted) {
      setState(() {
        _loggedInAdmin = admin;
      });
    }
  }

  void _openAdmin() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminScreen()),
    );
    _checkAdminSession();
  }

  void _openBinusCsUrl() {
    const url = 'https://binus.ac.id/semarang/computer-science/';
    ExportService.openExternalUrl(url);
    try {
      launchUrl(Uri.parse(url), webOnlyWindowName: '_blank');
    } catch (_) {}
  }

  void _joinRoom(String code) {
    if (code.trim().isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomScreen(roomCode: code.trim().toUpperCase()),
      ),
    );
  }

  Future<void> _openQrScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QrScannerScreen()),
    );
    if (scannedCode != null && scannedCode.trim().isNotEmpty) {
      final code = scannedCode.trim().toUpperCase();
      _codeController.text = code;
      _joinRoom(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFCFB), // Luxury Warm Alabaster
      body: SizedBox.expand(
        child: Stack(
          children: [
            // Decorative background glowing auras
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEE2E2).withValues(alpha: 0.35),
                ),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.3),
                ),
              ),
            ),

            // Top luxury ribbon stripe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                      Color(0xFFB91C1C),
                      Color(0xFFF59E0B),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        // Top Navbar / Admin Shortcut
                        Align(
                          alignment: Alignment.topRight,
                          child: _loggedInAdmin != null
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: _openAdmin,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.shield_rounded, size: 15, color: Color(0xFFDC2626)),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '@$_loggedInAdmin',
                                                  style: const TextStyle(
                                                    color: Color(0xFF0F172A),
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFFECDD3)),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(14),
                                          onTap: () async {
                                            await ApiService.logoutAdmin();
                                            _checkAdminSession();
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.logout_rounded, size: 14, color: Color(0xFFDC2626)),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Logout',
                                                  style: TextStyle(
                                                    color: Color(0xFFDC2626),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(14),
                                      onTap: _openAdmin,
                                      child: const Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.shield_outlined, size: 16, color: Color(0xFFDC2626)),
                                            SizedBox(width: 6),
                                            Text(
                                              'Panel Admin',
                                              style: TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),

                        // Lottie Animated Gift Box with Soft Backdrop Halo
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 170,
                              height: 170,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    const Color(0xFFFEE2E2).withValues(alpha: 0.65),
                                    const Color(0xFFFEF3C7).withValues(alpha: 0.35),
                                    Colors.transparent,
                                  ],
                                  radius: 0.65,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: Lottie.asset(
                                'assets/lottie/gift_box.json',
                                fit: BoxFit.contain,
                                repeat: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // App Name: Kadoo
                        const Text(
                          'Kadoo',
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Tagline Pill Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Roll Your Luck! 🎲',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Subtitle
                        const Text(
                          'Scan QR di booth atau masukkan kode event\nuntuk membuka hadiah doorprizemu!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Gift Box Join Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              // Decorative Gift Ribbon Top Line
                              Container(
                                width: double.infinity,
                                height: 5,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFF59E0B)],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Mulai Bermain Doorprize',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Scan QR langsung di booth atau ketik kode event',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                    ),
                                    const SizedBox(height: 18),

                                    // Primary CTA: Scan QR Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: _openQrScanner,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFFDC2626),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          elevation: 4,
                                          shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.35),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.qr_code_scanner_rounded, size: 22),
                                            SizedBox(width: 10),
                                            Text(
                                              'SCAN QR DI BOOTH',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 14,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // Divider "ATAU KETIK KODE MANUAL"
                                    Row(
                                      children: [
                                        Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                                        const Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            'ATAU KETIK KODE MANUAL',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF94A3B8),
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                        Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Room Code Input with scanner suffix
                                    TextField(
                                      controller: _codeController,
                                      focusNode: _codeFocusNode,
                                      keyboardType: TextInputType.text,
                                      textInputAction: TextInputAction.go,
                                      textAlign: TextAlign.center,
                                      autofocus: false,
                                      autocorrect: false,
                                      enableSuggestions: false,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                        UpperCaseTextFormatter(),
                                      ],
                                      onChanged: (val) {
                                        setState(() {});
                                      },
                                      onSubmitted: (val) => _joinRoom(val),
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'CONTOH: DEMO2026',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFFCBD5E1),
                                          fontSize: 13,
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFFFF1F2),
                                        suffixIcon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_codeController.text.isNotEmpty)
                                              IconButton(
                                                icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8), size: 18),
                                                tooltip: 'Hapus',
                                                onPressed: () {
                                                  _codeController.clear();
                                                  setState(() {});
                                                },
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFDC2626), size: 20),
                                              tooltip: 'Scan QR Code',
                                              onPressed: _openQrScanner,
                                            ),
                                          ],
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFFFECDD3)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    // Action Button for Manual Code
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () => _joinRoom(_codeController.text),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFDC2626),
                                          side: const BorderSide(color: Color(0xFFFECDD3), width: 1.5),
                                          backgroundColor: const Color(0xFFFFF1F2),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'MASUK DENGAN KODE',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            SizedBox(width: 6),
                                            Icon(Icons.arrow_forward_rounded, size: 16),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),

                                    // Quick Demo Pill Chip
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Coba room demo sekarang: ',
                                            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
                                          ),
                                          GestureDetector(
                                            onTap: () => _joinRoom('DEMO2026'),
                                            child: const Text(
                                              'DEMO2026',
                                              style: TextStyle(
                                                color: Color(0xFFDC2626),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 11,
                                                letterSpacing: 1,
                                                decoration: TextDecoration.underline,
                                              ),
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
                        const SizedBox(height: 24),

                        // 5 Mini-Games Badges Row
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const [
                              _GameBadge(icon: '🎡', label: 'Spin Wheel'),
                              _GameBadge(icon: '🎫', label: 'Scratch'),
                              _GameBadge(icon: '🎰', label: 'Jackpot'),
                              _GameBadge(icon: '⚪', label: 'Capsule'),
                              _GameBadge(icon: '🎁', label: 'Shake Box'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Footer Credit with Clickable CTA to Binus CS Semarang
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: _openBinusCsUrl,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.school_rounded, color: Color(0xFFDC2626), size: 16),
                                      SizedBox(width: 6),
                                      Text(
                                        'Developed by Computer Science Binus @Semarang',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Want to know more?',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.open_in_new_rounded, size: 11, color: Color(0xFF2563EB)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Generous bottom spacing so footer never hits edge or gets cut off
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameBadge extends StatelessWidget {
  final String icon;
  final String label;

  const _GameBadge({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFECDD3)),
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
