import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models.dart';
import '../api_service.dart';
import '../widgets/spin_wheel_widget.dart';
import '../widgets/scratch_card_widget.dart';
import '../widgets/slot_machine_widget.dart';
import '../widgets/gashapon_widget.dart';
import '../widgets/shake_box_widget.dart';
import '../widgets/claim_ticket_widget.dart';

enum RoomStep { form, selectGame, playing, ticket }

class RoomScreen extends StatefulWidget {
  final String roomCode;

  const RoomScreen({Key? key, required this.roomCode}) : super(key: key);

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  RoomModel? _room;
  bool _loading = true;
  String? _error;
  RoomStep _step = RoomStep.form;

  // Form Controllers
  final _nameCtrl = TextEditingController();
  final _waCtrl = TextEditingController();
  final _waParentCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _grade = '12';
  final _schoolNameCtrl = TextEditingController();
  final _schoolCityCtrl = TextEditingController();
  String _studyInterest = 'Informatika / Ilmu Komputer';

  String _selectedGame = 'spinwheel';
  ParticipantLead? _leadResult;
  bool _submitting = false;

  final List<String> _studyPrograms = [
    'Informatika / Ilmu Komputer',
    'Sistem Informasi',
    'Teknik Elektro / Robotika',
    'Desain Komunikasi Visual (DKV)',
    'Bisnis Digital / E-Commerce',
    'Manajemen & Kewirausahaan',
    'Akuntansi & Keuangan',
    'Ilmu Komunikasi / Broadcasting',
    'Hubungan Internasional',
    'Kedokteran / Farmasi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    _fetchRoom();
  }

  void _fetchRoom() async {
    setState(() => _loading = true);
    final res = await ApiService.getRoom(widget.roomCode);
    if (res['success'] == true && res['room'] != null) {
      setState(() {
        _room = RoomModel.fromJson(res['room']);
        _loading = false;
      });
    } else {
      setState(() {
        _error = res['error'] ?? 'Room tidak ditemukan';
        _loading = false;
      });
    }
  }

  void _submitForm() {
    if (_nameCtrl.text.trim().isEmpty ||
        _waCtrl.text.trim().isEmpty ||
        _waParentCtrl.text.trim().isEmpty ||
        _emailCtrl.text.trim().isEmpty ||
        _schoolNameCtrl.text.trim().isEmpty ||
        _schoolCityCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua 8 data registrasi wajib diisi!'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    setState(() {
      _step = RoomStep.selectGame;
    });
  }

  void _chooseGameAndPlay(String gameId) async {
    setState(() {
      _selectedGame = gameId;
      _submitting = true;
    });

    final payload = {
      'fullName': _nameCtrl.text.trim(),
      'waNumber': _waCtrl.text.trim(),
      'waParentNumber': _waParentCtrl.text.trim(),
      'email': _emailCtrl.text.trim(),
      'grade': _grade,
      'schoolName': _schoolNameCtrl.text.trim(),
      'schoolCity': _schoolCityCtrl.text.trim(),
      'studyInterest': _studyInterest,
      'gamePlayed': gameId,
    };

    final res = await ApiService.registerAndPlay(widget.roomCode, payload);
    setState(() => _submitting = false);

    if (res['success'] == true && res['lead'] != null) {
      setState(() {
        _leadResult = ParticipantLead.fromJson(res['lead']);
        _step = RoomStep.playing;
      });
    } else if (res['alreadyPlayed'] == true && res['lead'] != null) {
      setState(() {
        _leadResult = ParticipantLead.fromJson(res['lead']);
        _step = RoomStep.ticket;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor WA ini sudah pernah bermain. Ini tiketmu!'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['error'] ?? 'Terjadi kesalahan sistem'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Lottie.asset(
                  'assets/lottie/gift_box.json',
                  fit: BoxFit.contain,
                  repeat: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Memuat Room Doorprize...',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _room == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 54),
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(
          color: const Color(0xFF0F172A),
          onPressed: () {
            if (_step != RoomStep.form && _step != RoomStep.ticket) {
              setState(() => _step = RoomStep.form);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(
          _room?.name ?? 'Doorprize',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildBody(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case RoomStep.form:
        return _buildForm();
      case RoomStep.selectGame:
        return _buildGameSelector();
      case RoomStep.playing:
        return _buildGamePlayer();
      case RoomStep.ticket:
        return ClaimTicketWidget(
          lead: _leadResult!,
          roomName: _room?.name ?? 'Doorprize',
          roomCode: widget.roomCode,
        );
    }
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Red Gift Ribbon Line
          Container(
            width: double.infinity,
            height: 6,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Form Registrasi Siswa',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Center(
                  child: Text(
                    'Isi identitas diri untuk klaim kesempatan doorprize',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),

                // Nama Lengkap
                _buildTextField('Nama Lengkap', _nameCtrl, Icons.person, 'Contoh: Ahmad Fauzan'),
                const SizedBox(height: 12),

                // WA Siswa
                _buildTextField('Nomor WhatsApp Aktif Siswa', _waCtrl, Icons.phone, '081234567890', isPhone: true),
                const SizedBox(height: 12),

                // WA Ortu
                _buildTextField('Nomor WhatsApp Orang Tua / Wali', _waParentCtrl, Icons.phone_android, '08xxxxxxxxxx', isPhone: true),
                const SizedBox(height: 12),

                // Email
                _buildTextField('Email Siswa', _emailCtrl, Icons.email, 'nama@gmail.com', isEmail: true),
                const SizedBox(height: 12),

                // Kelas
                const Text(
                  'Kelas Saat Ini',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _grade,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.school, color: Color(0xFFDC2626), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: '12', child: Text('Kelas 12 SMA / SMK / MA')),
                    DropdownMenuItem(value: '11', child: Text('Kelas 11 SMA / SMK / MA')),
                    DropdownMenuItem(value: '10', child: Text('Kelas 10 SMA / SMK / MA')),
                    DropdownMenuItem(value: 'Alumni / Gap Year', child: Text('Alumni / Gap Year')),
                  ],
                  onChanged: (v) => setState(() => _grade = v!),
                ),
                const SizedBox(height: 12),

                // Asal Sekolah & Kota
                Row(
                  children: [
                    Expanded(child: _buildTextField('Asal Sekolah', _schoolNameCtrl, Icons.account_balance, 'SMAN 1')),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField('Kota Sekolah', _schoolCityCtrl, Icons.location_on, 'Surabaya')),
                  ],
                ),
                const SizedBox(height: 12),

                // Program Studi
                const Text(
                  'Program Studi Diminati',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _studyInterest,
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    prefixIcon: const Icon(Icons.auto_stories, color: Color(0xFFDC2626), size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                    ),
                  ),
                  items: _studyPrograms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                  onChanged: (v) => setState(() => _studyInterest = v!),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'LANJUT PILIH GAME DOORPRIZE ➔',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
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

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, String hint, {bool isPhone = false, bool isEmail = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF334155), fontSize: 11, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: ctrl,
          keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
          style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            prefixIcon: Icon(icon, color: const Color(0xFFDC2626), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildGameSelector() {
    final games = [
      {'id': 'spinwheel', 'title': 'Lucky Spin Wheel', 'desc': 'Putar roda keberuntungan!', 'icon': '🎡', 'color': Colors.red},
      {'id': 'scratch', 'title': 'Scratch Card', 'desc': 'Gosok kartu emas virtual!', 'icon': '🎫', 'color': Colors.amber},
      {'id': 'slot', 'title': 'Arcade Slot Machine', 'desc': 'Tarik tuas jackpot 3-reel!', 'icon': '🎰', 'color': Colors.pink},
      {'id': 'gashapon', 'title': 'Gashapon Capsule', 'desc': 'Putar tuas kapsul kejutan!', 'icon': '⚪', 'color': Colors.teal},
      {'id': 'shake', 'title': 'Shake The Box', 'desc': 'Goyang HP untuk membuka kado!', 'icon': '🎁', 'color': Colors.redAccent},
    ];

    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
              onPressed: () => setState(() => _step = RoomStep.form),
            ),
            const Text(
              'Kembali ke Form',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Pilih Game Keberuntunganmu',
          style: TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih salah satu game untuk menentukan hadiah yang kamu dapatkan',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        const SizedBox(height: 20),

        if (_submitting)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Lottie.asset(
                    'assets/lottie/gift_box.json',
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Menyiapkan Kado Keberuntunganmu...',
                  style: TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: games.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, idx) {
              final g = games[idx];
              return InkWell(
                onTap: () => _chooseGameAndPlay(g['id'] as String),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Center(
                          child: Text(g['icon'] as String, style: const TextStyle(fontSize: 26)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              g['title'] as String,
                              style: const TextStyle(
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              g['desc'] as String,
                              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildGamePlayer() {
    final prizeName = _leadResult?.prizeWon ?? 'Hadiah Menarik';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Text(
            'Halo, ${_leadResult?.fullName ?? 'Peserta'}!',
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Mainkan Sekarang untuk Membuka Kado!',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 24),

        if (_selectedGame == 'spinwheel')
          SpinWheelWidget(
            prizes: _room?.prizes.map((p) => p.toJson()).toList() ?? [],
            targetPrizeName: prizeName,
            onFinish: () => setState(() => _step = RoomStep.ticket),
          )
        else if (_selectedGame == 'scratch')
          ScratchCardWidget(
            prizeName: prizeName,
            onFinish: () => setState(() => _step = RoomStep.ticket),
          )
        else if (_selectedGame == 'slot')
          SlotMachineWidget(
            prizeName: prizeName,
            onFinish: () => setState(() => _step = RoomStep.ticket),
          )
        else if (_selectedGame == 'gashapon')
          GashaponWidget(
            prizeName: prizeName,
            onFinish: () => setState(() => _step = RoomStep.ticket),
          )
        else
          ShakeBoxWidget(
            prizeName: prizeName,
            onFinish: () => setState(() => _step = RoomStep.ticket),
          ),
      ],
    );
  }
}
