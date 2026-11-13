import 'package:flutter/material.dart';
import '../api_service.dart';

class CreateRoomScreen extends StatefulWidget {
  final String? adminId;
  const CreateRoomScreen({super.key, this.adminId});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _PrizeDraft {
  String id;
  String name;
  int stock;
  String colorHex;

  _PrizeDraft({
    required this.id,
    required this.name,
    required this.stock,
    required this.colorHex,
  });
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _codeCtrl = TextEditingController();
  final TextEditingController _pinCtrl = TextEditingController(text: '1234');
  final TextEditingController _descCtrl = TextEditingController();

  bool _isSaving = false;
  String? _errorMessage;

  // Selected games
  final Map<String, bool> _activeGames = {
    'spinwheel': true,
    'scratch': true,
    'slot': true,
    'gashapon': true,
    'shake': true,
  };

  final List<Map<String, String>> _availableGames = [
    {'id': 'spinwheel', 'icon': '🎡', 'name': 'Spin Wheel'},
    {'id': 'scratch', 'icon': '🎫', 'name': 'Scratch Card'},
    {'id': 'slot', 'icon': '🎰', 'name': 'Slot Machine'},
    {'id': 'gashapon', 'icon': '⚪', 'name': 'Gashapon Capsule'},
    {'id': 'shake', 'icon': '🎁', 'name': 'Shake Box'},
  ];

  // Prizes
  final List<_PrizeDraft> _prizes = [
    _PrizeDraft(id: 'p1', name: 'Smartwatch Keren', stock: 2, colorHex: '#EF4444'),
    _PrizeDraft(id: 'p2', name: 'Tumbler Stainless Exclusive', stock: 15, colorHex: '#3B82F6'),
    _PrizeDraft(id: 'p3', name: 'Kaos Kampus Trendy', stock: 20, colorHex: '#10B981'),
    _PrizeDraft(id: 'p4', name: 'Totebag Kanvas', stock: 30, colorHex: '#F59E0B'),
    _PrizeDraft(id: 'p5', name: 'Sticker Pack & Pulpen Gel', stock: 50, colorHex: '#8B5CF6'),
  ];

  final List<String> _colorPalette = [
    '#EF4444',
    '#F97316',
    '#F59E0B',
    '#10B981',
    '#06B6D4',
    '#3B82F6',
    '#8B5CF6',
    '#EC4899',
  ];

  void _addPrize() {
    setState(() {
      final idx = _prizes.length + 1;
      final color = _colorPalette[idx % _colorPalette.length];
      _prizes.add(
        _PrizeDraft(
          id: 'p$idx',
          name: 'Hadiah $idx',
          stock: 10,
          colorHex: color,
        ),
      );
    });
  }

  void _removePrize(int index) {
    if (_prizes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimal harus ada 1 jenis hadiah')),
      );
      return;
    }
    setState(() {
      _prizes.removeAt(index);
    });
  }

  void _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedGameIds = _activeGames.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedGameIds.isEmpty) {
      setState(() {
        _errorMessage = 'Pilih minimal 1 jenis game doorprize yang aktif';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final prizesPayload = _prizes.map((p) => {
      'id': p.id,
      'name': p.name.trim(),
      'initialStock': p.stock,
      'currentStock': p.stock,
      'color': p.colorHex,
      'weight': 20,
    }).toList();

    final payload = {
      'name': _nameCtrl.text.trim(),
      'code': _codeCtrl.text.trim().toUpperCase(),
      'pin': _pinCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'activeGames': selectedGameIds,
      'prizes': prizesPayload,
    };

    final result = await ApiService.createRoom(payload, adminId: widget.adminId);

    if (result['success'] == true) {
      if (mounted) {
        Navigator.pop(context, result['room']);
      }
    } else {
      if (mounted) {
        setState(() {
          _errorMessage = result['error'] ?? 'Gagal membuat room';
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Buat Room Doorprize Baru',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
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

                    // Top Hero Card
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
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
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.4)),
                            ),
                            child: const Icon(
                              Icons.add_business_rounded,
                              color: Color(0xFFFCA5A5),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Setup Room Booth Baru',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    if (widget.adminId != null) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF3B82F6).withValues(alpha: 0.25),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.4)),
                                        ),
                                        child: Text(
                                          '@${widget.adminId}',
                                          style: const TextStyle(
                                            color: Color(0xFF93C5FD),
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tentukan kode QR room, 5 opsi mini-game, dan stok doorprize yang siap dibagikan di booth.',
                                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Section 1: Informasi Event
                    _buildSectionCard(
                      title: '1. Detail Event & Booth',
                      subtitle: 'Tentukan nama acara dan kode akses room',
                      icon: Icons.event_note_rounded,
                      children: [
                        TextFormField(
                          controller: _nameCtrl,
                          decoration: InputDecoration(
                            labelText: 'Nama Event / Sekolah *',
                            hintText: 'Contoh: Kunjungan SMAN 1 Semarang',
                            prefixIcon: const Icon(Icons.school_rounded, color: Color(0xFFDC2626)),
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
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Nama event wajib diisi';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: _codeCtrl,
                                textCapitalization: TextCapitalization.characters,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  color: Color(0xFFDC2626),
                                  letterSpacing: 1.5,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Kode Room Unik *',
                                  hintText: 'CONTOH: SMAN1SMG',
                                  helperText: 'Kode akses peserta & QR',
                                  prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFDC2626)),
                                  filled: true,
                                  fillColor: const Color(0xFFFFF1F2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFFECDD3)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFFECDD3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                                  ),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Kode room wajib diisi';
                                  }
                                  if (val.trim().length < 3) {
                                    return 'Minimal 3 karakter';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _pinCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: 'PIN Admin *',
                                  hintText: '1234',
                                  helperText: 'Akses kelola',
                                  prefixIcon: const Icon(Icons.pin_rounded, color: Color(0xFFDC2626)),
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
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _descCtrl,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Deskripsi Event (Opsional)',
                            hintText: 'Doorprize stan pameran pendidikan...',
                            prefixIcon: const Icon(Icons.description_rounded, color: Color(0xFF94A3B8)),
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
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Pilihan Game Aktif
                    _buildSectionCard(
                      title: '2. Pilihan Game Doorprize',
                      subtitle: 'Pilih game yang dapat dimainkan siswa di room ini',
                      icon: Icons.sports_esports_rounded,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _availableGames.map((game) {
                            final isSelected = _activeGames[game['id']] ?? false;
                            return FilterChip(
                              selected: isSelected,
                              showCheckmark: false,
                              avatar: Text(game['icon']!, style: const TextStyle(fontSize: 16)),
                              label: Text(game['name']!),
                              labelStyle: TextStyle(
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 12,
                              ),
                              backgroundColor: Colors.white,
                              selectedColor: const Color(0xFFDC2626),
                              side: BorderSide(
                                color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              onSelected: (val) {
                                setState(() {
                                  _activeGames[game['id']!] = val;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Hadiah & Stok
                    _buildSectionCard(
                      title: '3. Daftar Hadiah & Kuota Stok',
                      subtitle: 'Atur item doorprize, kuota stok, dan warna hadiah',
                      icon: Icons.card_giftcard_rounded,
                      action: TextButton.icon(
                        onPressed: _addPrize,
                        icon: const Icon(Icons.add_circle_outline, size: 16, color: Color(0xFFDC2626)),
                        label: const Text(
                          'Tambah Hadiah',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _prizes.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final prize = _prizes[index];
                            final color = Color(
                              int.parse('FF${prize.colorHex.replaceAll('#', '')}', radix: 16),
                            );

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  // Color Indicator & Picker Menu
                                  PopupMenuButton<String>(
                                    tooltip: 'Ganti Warna',
                                    onSelected: (hex) {
                                      setState(() {
                                        prize.colorHex = hex;
                                      });
                                    },
                                    itemBuilder: (context) {
                                      return _colorPalette.map((hex) {
                                        final c = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                                        return PopupMenuItem(
                                          value: hex,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: BoxDecoration(shape: BoxShape.circle, color: c),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(hex, style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        );
                                      }).toList();
                                    },
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: color,
                                        border: Border.all(color: Colors.white, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Nama Hadiah
                                  Expanded(
                                    flex: 3,
                                    child: TextFormField(
                                      initialValue: prize.name,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        hintText: 'Nama Hadiah',
                                        prefixIcon: Icon(Icons.card_giftcard_rounded, size: 16, color: Color(0xFFDC2626)),
                                        prefixIconConstraints: BoxConstraints(minWidth: 24, maxHeight: 20),
                                        border: InputBorder.none,
                                      ),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      onChanged: (val) => prize.name = val,
                                    ),
                                  ),

                                  // Stok Input
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      initialValue: prize.stock.toString(),
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        isDense: true,
                                        labelText: 'Stok',
                                        prefixIcon: const Icon(Icons.inventory_2_outlined, size: 13, color: Color(0xFF64748B)),
                                        prefixIconConstraints: const BoxConstraints(minWidth: 20, maxHeight: 18),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFFDC2626),
                                        fontSize: 12,
                                      ),
                                      onChanged: (val) {
                                        prize.stock = int.tryParse(val) ?? 0;
                                      },
                                    ),
                                  ),

                                  // Delete Button
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFF94A3B8)),
                                    onPressed: () => _removePrize(index),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Submit Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                            label: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _saveRoom,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.rocket_launch_rounded, size: 18, color: Colors.white),
                            label: Text(
                              _isSaving ? 'Menyimpan...' : 'BUAT & AKTIFKAN ROOM',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 3,
                              shadowColor: const Color(0xFFDC2626).withValues(alpha: 0.35),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: const Color(0xFFDC2626), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}
