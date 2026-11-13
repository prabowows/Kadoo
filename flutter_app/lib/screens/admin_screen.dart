import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models.dart';
import '../api_service.dart';
import '../services/sound_service.dart';
import '../services/export_service.dart';
import '../services/firebase_service.dart';
import 'create_room_screen.dart';
import 'room_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String? _currentAdminId;
  bool _checkingAuth = true;

  // Login form controllers
  final TextEditingController _adminIdInputCtrl = TextEditingController(text: 'admin');
  final TextEditingController _pinInputCtrl = TextEditingController(text: '1234');
  bool _obscurePin = true;
  String? _loginError;
  bool _isLoggingIn = false;

  List<Map<String, dynamic>> _rooms = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  @override
  void dispose() {
    _adminIdInputCtrl.dispose();
    _pinInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    setState(() => _checkingAuth = true);
    final savedAdmin = await ApiService.getLoggedInAdmin();
    if (savedAdmin != null && savedAdmin.isNotEmpty) {
      _currentAdminId = savedAdmin;
      _checkingAuth = false;
      _loadRooms();
    } else {
      setState(() {
        _checkingAuth = false;
      });
    }
  }

  Future<void> _loginAdmin() async {
    final adminId = _adminIdInputCtrl.text.trim().toLowerCase();
    final pin = _pinInputCtrl.text.trim();

    if (adminId.isEmpty) {
      setState(() {
        _loginError = 'ID Admin / Username wajib diisi';
      });
      return;
    }

    if (pin.isEmpty) {
      setState(() {
        _loginError = 'PIN Keamanan wajib diisi';
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _loginError = null;
    });

    await ApiService.setLoggedInAdmin(adminId);

    setState(() {
      _currentAdminId = adminId;
      _isLoggingIn = false;
    });

    _loadRooms();
  }

  Future<void> _logoutAdmin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout Admin', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Anda sedang login sebagai @$_currentAdminId.\nKeluar dari sesi manajemen ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService.logoutAdmin();
      setState(() {
        _currentAdminId = null;
        _rooms = [];
      });
    }
  }

  Future<void> _loadRooms() async {
    if (_currentAdminId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rooms = await ApiService.getAllRooms(adminId: _currentAdminId);
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Gagal memuat daftar room: $e';
        _loading = false;
      });
    }
  }

  void _openCreateRoom() async {
    final newRoom = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateRoomScreen(adminId: _currentAdminId),
      ),
    );

    if (newRoom != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room "${newRoom['name']}" berhasil dibuat!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      _loadRooms();
    }
  }

  void _openRoomDetail(Map<String, dynamic> room) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomDetailAdminScreen(
          roomCode: (room['code'] ?? '').toString().toUpperCase(),
          pin: (room['pin'] ?? '1234').toString(),
          initialName: room['name'] ?? '',
        ),
      ),
    ).then((_) => _loadRooms());
  }

  void _showQuickQrModal(Map<String, dynamic> room) {
    final code = (room['code'] ?? 'DEMO2026').toString().toUpperCase();
    final name = room['name'] ?? 'Room Doorprize';
    final shareUrl = 'http://localhost:8080/#/room/$code';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'SCAN UNTUK MAIN DI BOOTH',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      color: Color(0xFFDC2626),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: QrImageView(
                    data: shareUrl,
                    version: QrVersions.auto,
                    size: 220.0,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Text(
                    'KODE: $code',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFFDC2626),
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAuth) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
        ),
      );
    }

    if (_currentAdminId == null) {
      return _buildAdminLoginView();
    }

    int totalPrizes = 0;
    int totalStock = 0;
    for (final r in _rooms) {
      totalPrizes += (r['prizesCount'] ?? (r['prizes'] as List?)?.length ?? 0) as int;
      totalStock += (r['totalStock'] ?? 0) as int;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Panel Manajemen Room',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle_rounded, size: 12, color: Color(0xFFDC2626)),
                const SizedBox(width: 4),
                Text(
                  'Admin: @$_currentAdminId',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Daftar',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _loadRooms,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: _logoutAdmin,
              icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateRoom,
        backgroundColor: const Color(0xFFDC2626),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_rounded, size: 22),
        label: const Text(
          'Buat Room Baru',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadRooms,
          color: const Color(0xFFDC2626),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Overview Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.shield_rounded, color: Color(0xFFEF4444), size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'ADMIN: ${_currentAdminId?.toUpperCase() ?? "ADMIN"}',
                                          style: const TextStyle(
                                            color: Color(0xFFFCA5A5),
                                            fontWeight: FontWeight.w900,
                                            fontSize: 10,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _logoutAdmin,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.logout_rounded, color: Color(0xFFFCA5A5), size: 12),
                                          SizedBox(width: 4),
                                          Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: Color(0xFFFCA5A5),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: _openCreateRoom,
                                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                                label: const Text('Buat Room Baru'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Manajemen Booth & Event Doorprize',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Menampilkan room event & database prospek khusus milik admin @$_currentAdminId.',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          ),
                          const SizedBox(height: 18),

                          // Stats Row
                          Row(
                            children: [
                              _buildStatItem('Room Aktif', _rooms.length.toString(), Icons.meeting_room_rounded),
                              _buildStatItem('Jenis Hadiah', totalPrizes.toString(), Icons.card_giftcard_rounded),
                              _buildStatItem('Total Stok', totalStock.toString(), Icons.inventory_2_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daftar Room Event (${_rooms.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (_rooms.isNotEmpty)
                          TextButton.icon(
                            onPressed: _openCreateRoom,
                            icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFDC2626)),
                            label: const Text(
                              '+ Tambah Event',
                              style: TextStyle(
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rooms List
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFFDC2626)),
                        ),
                      )
                    else if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))),
                      )
                    else if (_rooms.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(Icons.door_back_door_outlined, size: 48, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 12),
                              const Text(
                                'Belum Ada Room Event',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Klik tombol di bawah untuk membuat room doorprize pertamamu!',
                                style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _openCreateRoom,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('Buat Room Sekarang'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _rooms.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final room = _rooms[index];
                          return _buildRoomCard(room);
                        },
                      ),

                    // Admin Session Info & Explicit Logout Action Card
                    Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.admin_panel_settings_rounded,
                              color: Color(0xFFDC2626),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sesi Admin Aktif: @$_currentAdminId',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Room dan database prospek hanya dapat diakses akun ini.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: _logoutAdmin,
                            icon: const Icon(Icons.logout_rounded, size: 15, color: Colors.white),
                            label: const Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              elevation: 1,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF59E0B), size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final code = (room['code'] ?? '').toString().toUpperCase();
    final name = room['name'] ?? 'Room Doorprize';
    final desc = room['description'] ?? '';
    final totalStock = room['totalStock'] ?? 0;
    final prizesCount = room['prizesCount'] ?? (room['prizes'] as List?)?.length ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Text(
                  code,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    fontFamily: 'monospace',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Text(
                      '@${room['adminId'] ?? _currentAdminId ?? 'admin'}',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Aktif',
                      style: TextStyle(
                        color: Color(0xFF065F46),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title & Description
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 14),

          // Metadata row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      '$prizesCount Jenis Hadiah',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_rounded, size: 14, color: Color(0xFFDC2626)),
                    const SizedBox(width: 6),
                    Text(
                      'Sisa Stok: $totalStock',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFDC2626), fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _openRoomDetail(room),
                  icon: const Icon(Icons.tune_rounded, size: 16),
                  label: const Text('Kelola Room & Leads'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _showQuickQrModal(room),
                icon: const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFF0F172A)),
                label: const Text(
                  'QR Booth',
                  style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 11),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xFFF8FAFC),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                tooltip: 'Mainkan Game (Tampilan Siswa)',
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF1F2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.play_arrow_rounded, color: Color(0xFFDC2626)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RoomScreen(roomCode: code)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminLoginView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Login Admin Marketing',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Badge icon
                      Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.admin_panel_settings_rounded,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'Autentikasi Admin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Masuk dengan ID Admin untuk mengakses dan mengelola room booth milik Anda secara terisolasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Error message if any
                      if (_loginError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _loginError!,
                                  style: const TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Admin ID field
                      const Text(
                        'ID Admin / Username',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _adminIdInputCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'Contoh: admin, marcomm_smg',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF94A3B8)),
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
                        ),
                      ),
                      const SizedBox(height: 16),

                      // PIN Admin field
                      const Text(
                        'PIN Keamanan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _pinInputCtrl,
                        obscureText: _obscurePin,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _loginAdmin(),
                        decoration: InputDecoration(
                          hintText: 'Masukkan PIN (default: 1234)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF94A3B8)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                              color: const Color(0xFF94A3B8),
                            ),
                            onPressed: () => setState(() => _obscurePin = !_obscurePin),
                          ),
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
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Preset quick selection chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text(
                            'Preset Cepat:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                          ),
                          ActionChip(
                            label: const Text('admin (Pusat)'),
                            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                            backgroundColor: const Color(0xFFFFF1F2),
                            side: const BorderSide(color: Color(0xFFFECDD3)),
                            onPressed: () {
                              _adminIdInputCtrl.text = 'admin';
                              _pinInputCtrl.text = '1234';
                            },
                          ),
                          ActionChip(
                            label: const Text('marcomm_smg'),
                            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            backgroundColor: const Color(0xFFEFF6FF),
                            side: const BorderSide(color: Color(0xFFBFDBFE)),
                            onPressed: () {
                              _adminIdInputCtrl.text = 'marcomm_smg';
                              _pinInputCtrl.text = '1234';
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Submit button
                      ElevatedButton(
                        onPressed: _isLoggingIn ? null : _loginAdmin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isLoggingIn
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Masuk Sebagai Admin',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                              ),
                      ),

                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF64748B)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Setiap admin hanya mengelola room miliknya sendiri. Admin "marcomm_smg" hanya melihat room miliknya.',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Detailed Room Admin Screen (Leads, Prizes, QR Code)
// -------------------------------------------------------------
class RoomDetailAdminScreen extends StatefulWidget {
  final String roomCode;
  final String pin;
  final String initialName;

  const RoomDetailAdminScreen({
    super.key,
    required this.roomCode,
    required this.pin,
    required this.initialName,
  });

  @override
  State<RoomDetailAdminScreen> createState() => _RoomDetailAdminScreenState();
}

class _RoomDetailAdminScreenState extends State<RoomDetailAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  RoomModel? _room;
  List<ParticipantLead> _participants = [];
  bool _loading = true;
  String? _error;

  // Filter & Verification State
  String _searchQuery = '';
  String _filterStatus = 'all'; // 'all', 'unclaimed', 'claimed'
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _verifyCodeCtrl = TextEditingController();
  StreamSubscription? _participantsSub;
  StreamSubscription? _roomSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _subscribeRealtime();
  }

  void _subscribeRealtime() {
    if (FirebaseService.isInitialized) {
      _participantsSub = FirebaseService.streamParticipants(widget.roomCode).listen((list) {
        if (mounted && list.isNotEmpty) {
          setState(() {
            _participants = list.map((p) => ParticipantLead.fromJson(p)).toList();
          });
        }
      });
      _roomSub = FirebaseService.streamRoom(widget.roomCode).listen((roomData) {
        if (mounted && roomData != null) {
          setState(() {
            _room = RoomModel.fromJson(roomData);
          });
        }
      });
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final roomRes = await ApiService.getRoom(widget.roomCode, pin: widget.pin);
    if (roomRes['success'] == true && roomRes['room'] != null) {
      final partRes = await ApiService.getParticipants(widget.roomCode, widget.pin);
      setState(() {
        _room = RoomModel.fromJson(roomRes['room']);
        if (partRes['participants'] != null) {
          _participants = (partRes['participants'] as List)
              .map((p) => ParticipantLead.fromJson(p))
              .toList();
        }
        _loading = false;
      });
    } else {
      setState(() {
        _error = 'Tidak dapat memuat detail room';
        _loading = false;
      });
    }
  }

  void _toggleClaim(ParticipantLead lead) async {
    final nextState = !lead.isClaimed;
    final ok = await ApiService.toggleClaim(lead.id);
    if (ok) {
      setState(() {
        lead.isClaimed = nextState;
      });
      if (nextState) {
        SoundService.playClaimSuccess();
      }
    }
  }

  void _exportCsv() {
    if (_participants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Belum ada data peserta untuk diunduh.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final StringBuffer buffer = StringBuffer();
    // CSV Header with BOM
    buffer.writeln(
      'No,Kode Tiket,Status Klaim,Hadiah Dimenangkan,Nama Lengkap,No WhatsApp,No WhatsApp Ortu,Email,Kelas,Asal Sekolah,Kota Sekolah,Minat Prodi,Game Dimainkan,Waktu Terdaftar',
    );

    String escapeCsv(String? val) {
      if (val == null) return '""';
      final clean = val.replaceAll('"', '""');
      return '"$clean"';
    }

    for (int i = 0; i < _participants.length; i++) {
      final p = _participants[i];
      final status = p.isClaimed ? 'Sudah Diambil' : 'Belum Diambil';
      buffer.writeln([
        i + 1,
        escapeCsv(p.claimCode),
        escapeCsv(status),
        escapeCsv(p.prizeWon),
        escapeCsv(p.fullName),
        escapeCsv(p.waNumber),
        escapeCsv(p.waParentNumber),
        escapeCsv(p.email),
        escapeCsv(p.grade),
        escapeCsv(p.schoolName),
        escapeCsv(p.schoolCity),
        escapeCsv(p.studyInterest),
        escapeCsv(p.gamePlayed),
        escapeCsv(p.createdAt),
      ].join(','));
    }

    final dateStr = DateTime.now().toIso8601String().substring(0, 10).replaceAll('-', '');
    final filename = 'rekap_pemenang_${widget.roomCode}_$dateStr.csv';
    final success = ExportService.downloadCsv(filename, buffer.toString());

    if (success) {
      SoundService.playClaimSuccess();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Rekap ${_participants.length} pemenang berhasil diunduh ($filename)'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('File $filename siap diekspor (${_participants.length} baris).'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  void _openVerifyDialog() {
    _verifyCodeCtrl.clear();
    ParticipantLead? matchedLead;
    String? searchError;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void doSearch() {
              final query = _verifyCodeCtrl.text.trim().toUpperCase();
              if (query.isEmpty) {
                setDialogState(() {
                  matchedLead = null;
                  searchError = 'Ketik kode tiket terlebih dahulu!';
                });
                return;
              }

              final found = _participants.cast<ParticipantLead?>().firstWhere(
                (p) => p?.claimCode.toUpperCase() == query,
                orElse: () => null,
              );

              setDialogState(() {
                if (found != null) {
                  matchedLead = found;
                  searchError = null;
                } else {
                  matchedLead = null;
                  searchError = 'Kode tiket "$query" tidak ditemukan di room ini!';
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Color(0xFFDC2626), size: 24),
                  SizedBox(width: 8),
                  Text('Verifikasi Tiket Hadiah', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
              content: SizedBox(
                width: 380,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ketik atau scan kode klaim tiket siswa untuk memverifikasi keabsahan sebelum penyerahan hadiah:',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _verifyCodeCtrl,
                              autofocus: true,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                                letterSpacing: 1.5,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Contoh: SP-2026',
                                hintStyle: const TextStyle(fontWeight: FontWeight.normal, letterSpacing: 0),
                                prefixIcon: const Icon(Icons.qr_code_2_rounded, size: 20, color: Color(0xFFDC2626)),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                              onSubmitted: (_) => doSearch(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: doSearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            ),
                            child: const Text('Cek', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      if (searchError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  searchError!,
                                  style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (matchedLead != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: matchedLead!.isClaimed ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    matchedLead!.claimCode,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'monospace',
                                      fontSize: 16,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: matchedLead!.isClaimed ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      matchedLead!.isClaimed ? '✓ Sudah Diambil' : 'Belum Diambil',
                                      style: TextStyle(
                                        color: matchedLead!.isClaimed ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),
                              Text(
                                'Pemenang: ${matchedLead!.fullName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${matchedLead!.schoolName} (${matchedLead!.schoolCity})',
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text('WA: ${matchedLead!.waNumber}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🎁', style: TextStyle(fontSize: 22)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'HADIAH BERHAK DITERIMA:',
                                            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            matchedLead!.prizeWon,
                                            style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w900, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              if (!matchedLead!.isClaimed)
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _toggleClaim(matchedLead!);
                                      setDialogState(() {});
                                      setState(() {});
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF059669),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                                    label: const Text(
                                      'KONFIRMASI SERAHKAN HADIAH',
                                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '✓ Hadiah telah diserahkan & status terverifikasi.',
                                      style: TextStyle(color: Color(0xFF065F46), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Tutup', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _participantsSub?.cancel();
    _roomSub?.cancel();
    _tabController.dispose();
    _searchCtrl.dispose();
    _verifyCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _room?.name ?? widget.initialName;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '$title (${widget.roomCode})',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF64748B)),
            onPressed: _loadData,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    title: const Text('Logout Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Keluar dari sesi manajemen akun admin ini?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal', style: TextStyle(color: Color(0xFF64748B))),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ApiService.logoutAdmin();
                  if (context.mounted) {
                    Navigator.pop(context); // back to admin root
                  }
                }
              },
              icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.white),
              label: const Text(
                'Logout',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFDC2626),
          labelColor: const Color(0xFFDC2626),
          unselectedLabelColor: const Color(0xFF64748B),
          tabs: [
            Tab(text: 'Leads (${_participants.length})'),
            Tab(text: 'Hadiah (${_room?.prizes.length ?? 0})'),
            const Tab(text: 'QR Booth'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFDC2626)))
          : _error != null
              ? Center(child: Text(_error!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLeadsTab(),
                    _buildPrizesTab(),
                    _buildQRTab(),
                  ],
                ),
    );
  }

  Widget _buildLeadsTab() {
    final unclaimedCount = _participants.where((p) => !p.isClaimed).length;
    final claimedCount = _participants.where((p) => p.isClaimed).length;

    // Filter participants based on search query and status filter
    final filteredParticipants = _participants.where((p) {
      if (_filterStatus == 'unclaimed' && p.isClaimed) return false;
      if (_filterStatus == 'claimed' && !p.isClaimed) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final match = p.fullName.toLowerCase().contains(q) ||
            p.claimCode.toLowerCase().contains(q) ||
            p.waNumber.toLowerCase().contains(q) ||
            p.schoolName.toLowerCase().contains(q) ||
            p.prizeWon.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Summary & Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            children: [
              // Statistics Chips
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('TOTAL PESERTA', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            '${_participants.length}',
                            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BELUM DIAMBIL', style: TextStyle(color: Color(0xFFB45309), fontSize: 9, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            '$unclaimedCount',
                            style: const TextStyle(color: Color(0xFFB45309), fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SUDAH KLAIM', style: TextStyle(color: Color(0xFF065F46), fontSize: 9, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(
                            '$claimedCount',
                            style: const TextStyle(color: Color(0xFF065F46), fontSize: 16, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Action Buttons Row: Export CSV & Verify Code
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openVerifyDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: const Text(
                        'VERIFIKASI TIKET',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportCsv,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F172A),
                        side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.file_download_outlined, size: 18, color: Color(0xFF059669)),
                      label: const Text(
                        'EXPORT CSV',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Realtime Search Input
              TextField(
                controller: _searchCtrl,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Cari nama, tiket, WA, atau sekolah...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF94A3B8)),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      selected: _filterStatus == 'all',
                      label: Text('Semua (${_participants.length})'),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: _filterStatus == 'all' ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == 'all' ? Colors.white : const Color(0xFF475569),
                      ),
                      selectedColor: const Color(0xFF0F172A),
                      backgroundColor: const Color(0xFFF1F5F9),
                      checkmarkColor: Colors.white,
                      onSelected: (_) => setState(() => _filterStatus = 'all'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      selected: _filterStatus == 'unclaimed',
                      label: Text('Belum Diambil ($unclaimedCount)'),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: _filterStatus == 'unclaimed' ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == 'unclaimed' ? const Color(0xFF92400E) : const Color(0xFF475569),
                      ),
                      selectedColor: const Color(0xFFFDE68A),
                      backgroundColor: const Color(0xFFFEF3C7),
                      onSelected: (_) => setState(() => _filterStatus = 'unclaimed'),
                    ),
                    const SizedBox(width: 6),
                    FilterChip(
                      selected: _filterStatus == 'claimed',
                      label: Text('Sudah Diambil ($claimedCount)'),
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: _filterStatus == 'claimed' ? FontWeight.bold : FontWeight.normal,
                        color: _filterStatus == 'claimed' ? const Color(0xFF065F46) : const Color(0xFF475569),
                      ),
                      selectedColor: const Color(0xFFA7F3D0),
                      backgroundColor: const Color(0xFFD1FAE5),
                      onSelected: (_) => setState(() => _filterStatus = 'claimed'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Participant List or Empty State
        Expanded(
          child: filteredParticipants.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 48, color: Color(0xFFCBD5E1)),
                        const SizedBox(height: 12),
                        Text(
                          _participants.isEmpty
                              ? 'Belum ada data peserta di room ini'
                              : 'Tidak ada peserta yang cocok dengan filter',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _participants.isEmpty
                              ? 'Siswa yang scan QR ${widget.roomCode} akan tercatat di sini.'
                              : 'Coba ubah kata kunci pencarian atau status filter.',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredParticipants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, idx) {
                    final p = filteredParticipants[idx];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: p.isClaimed ? const Color(0xFFE2E8F0) : const Color(0xFFFDE68A),
                          width: p.isClaimed ? 1 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p.claimCode,
                                  style: const TextStyle(
                                    color: Color(0xFFFDE047),
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _toggleClaim(p),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: p.isClaimed ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: p.isClaimed ? const Color(0xFF6EE7B7) : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        p.isClaimed ? Icons.check_circle_rounded : Icons.pending_rounded,
                                        size: 14,
                                        color: p.isClaimed ? const Color(0xFF047857) : const Color(0xFFB45309),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        p.isClaimed ? 'Sudah Diambil' : 'Klaim Sekarang',
                                        style: TextStyle(
                                          color: p.isClaimed ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            p.fullName,
                            style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${p.schoolName} (${p.schoolCity}) • Kelas ${p.grade}',
                            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Minat: ${p.studyInterest}',
                            style: const TextStyle(color: Color(0xFFB45309), fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          const Divider(color: Color(0xFFF1F5F9), height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Text('🎁 ', style: TextStyle(fontSize: 14)),
                                  Text(
                                    p.prizeWon,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              Text('WA: ${p.waNumber}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPrizesTab() {
    final prizes = _room?.prizes ?? [];
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: prizes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final p = prizes[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: p.color),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                      Text('Stok Awal: ${p.initialStock}', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  'Sisa: ${p.currentStock}',
                  style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQRTab() {
    final code = _room?.code ?? widget.roomCode;
    final shareUrl = 'http://localhost:8080/#/room/$code';

    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFFEE2E2), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'SCAN UNTUK MAIN DI BOOTH',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Color(0xFFDC2626)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _room?.name ?? 'Room Doorprize',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: shareUrl,
              version: QrVersions.auto,
              size: 220.0,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                'Kode Room: $code',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFDC2626),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
