'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Plus,
  QrCode,
  Users,
  Gift,
  ArrowRight,
  ShieldCheck,
  Sparkles,
  LogOut,
  Lock,
  User,
  School,
  FileText,
  KeyRound,
  X,
  AlertCircle
} from 'lucide-react';

interface RoomSummary {
  id: string;
  adminId?: string;
  code: string;
  name: string;
  description?: string;
  status: string;
  activeGames: string[];
  prizesCount: number;
  totalStock: number;
  createdAt: string;
}

export default function AdminIndexPage() {
  const [adminId, setAdminId] = useState<string | null>(null);
  const [authChecked, setAuthChecked] = useState(false);

  // Login form state
  const [loginInput, setLoginInput] = useState('admin');
  const [pinInput, setPinInput] = useState('1234');
  const [loginError, setLoginError] = useState('');

  // Rooms state
  const [rooms, setRooms] = useState<RoomSummary[]>([]);
  const [loading, setLoading] = useState(false);
  const [showCreateModal, setShowCreateModal] = useState(false);

  // Form New Room
  const [name, setName] = useState('');
  const [code, setCode] = useState('');
  const [pin, setPin] = useState('1234');
  const [description, setDescription] = useState('');
  const [createError, setCreateError] = useState('');
  const [isCreating, setIsCreating] = useState(false);

  // Check saved admin session on mount
  useEffect(() => {
    try {
      const saved = localStorage.getItem('shaking_prize_admin_id');
      if (saved) {
        setAdminId(saved);
        fetchRooms(saved);
      }
    } catch {
      // ignore
    } finally {
      setAuthChecked(true);
    }
  }, []);

  const fetchRooms = async (currentAdmin?: string) => {
    const effectiveAdmin = currentAdmin || adminId || 'admin';
    try {
      setLoading(true);
      const res = await fetch(`/api/rooms?adminId=${encodeURIComponent(effectiveAdmin)}`);
      const data = await res.json();
      if (data.success) {
        setRooms(data.rooms);
      }
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    const id = loginInput.trim().toLowerCase();
    if (!id) {
      setLoginError('ID Admin wajib diisi');
      return;
    }
    if (!pinInput.trim()) {
      setLoginError('PIN Admin wajib diisi');
      return;
    }

    try {
      localStorage.setItem('shaking_prize_admin_id', id);
    } catch {}
    setAdminId(id);
    setLoginError('');
    fetchRooms(id);
  };

  const handleLogout = () => {
    if (confirm(`Logout dari akun admin @${adminId}?`)) {
      try {
        localStorage.removeItem('shaking_prize_admin_id');
      } catch {}
      setAdminId(null);
      setRooms([]);
    }
  };

  const handleCreateRoom = async (e: React.FormEvent) => {
    e.preventDefault();
    setCreateError('');
    setIsCreating(true);

    try {
      const res = await fetch('/api/rooms', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          adminId: adminId || 'admin',
          name,
          code,
          pin,
          description,
        }),
      });

      const data = await res.json();
      if (!data.success) {
        setCreateError(data.error || 'Gagal membuat room');
        setIsCreating(false);
        return;
      }

      setShowCreateModal(false);
      setName('');
      setCode('');
      setDescription('');
      fetchRooms(adminId || 'admin');
    } catch {
      setCreateError('Gagal menghubungi server');
    } finally {
      setIsCreating(false);
    }
  };

  if (!authChecked) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center">
        <div className="text-amber-400 font-bold text-sm animate-pulse">Memuat...</div>
      </div>
    );
  }

  // View: Admin Login Form
  if (!adminId) {
    return (
      <div className="min-h-screen bg-slate-900 text-slate-100 flex items-center justify-center p-4">
        <div className="max-w-md w-full bg-slate-800 border border-slate-700/80 rounded-3xl p-6 sm:p-8 shadow-2xl">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-tr from-rose-600 to-amber-500 flex items-center justify-center mx-auto mb-4 shadow-lg shadow-rose-500/20">
            <ShieldCheck className="w-8 h-8 text-white" />
          </div>

          <h1 className="text-xl sm:text-2xl font-black text-center text-white tracking-tight">
            Login Admin Marketing
          </h1>
          <p className="text-xs text-slate-400 text-center mt-1.5 mb-6">
            Masuk dengan ID Admin untuk mengakses dan mengelola room event Anda.
          </p>

          {loginError && (
            <div className="p-3 rounded-xl bg-rose-500/20 border border-rose-500/40 text-rose-300 text-xs flex items-center gap-2 mb-4">
              <AlertCircle className="w-4 h-4 shrink-0" />
              <span>{loginError}</span>
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-xs font-bold text-slate-300 mb-1.5">
                ID Admin / Username
              </label>
              <div className="relative">
                <User className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  required
                  placeholder="Contoh: admin, marcomm_smg"
                  value={loginInput}
                  onChange={(e) => setLoginInput(e.target.value)}
                  className="w-full pl-10 pr-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-hidden focus:border-amber-500"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-300 mb-1.5">
                PIN Keamanan
              </label>
              <div className="relative">
                <Lock className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="password"
                  required
                  placeholder="PIN Keamanan (default: 1234)"
                  value={pinInput}
                  onChange={(e) => setPinInput(e.target.value)}
                  className="w-full pl-10 pr-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-xs font-mono text-white focus:outline-hidden focus:border-amber-500"
                />
              </div>
            </div>

            <div className="flex items-center gap-2 pt-1 text-xs text-slate-400">
              <span className="text-[11px]">Pilih Cepat:</span>
              <button
                type="button"
                onClick={() => { setLoginInput('admin'); setPinInput('1234'); }}
                className="px-2.5 py-1 rounded-lg bg-slate-700 hover:bg-slate-600 text-amber-400 font-bold text-[11px]"
              >
                admin (Pusat)
              </button>
              <button
                type="button"
                onClick={() => { setLoginInput('marcomm_smg'); setPinInput('1234'); }}
                className="px-2.5 py-1 rounded-lg bg-slate-700 hover:bg-slate-600 text-sky-400 font-bold text-[11px]"
              >
                marcomm_smg
              </button>
            </div>

            <button
              type="submit"
              className="w-full mt-2 py-3 rounded-xl bg-gradient-to-r from-rose-600 to-amber-500 hover:brightness-110 text-white font-bold text-xs shadow-lg shadow-rose-500/20 active:scale-95 transition-all flex items-center justify-center gap-2"
            >
              <ShieldCheck className="w-4 h-4" />
              Masuk Sebagai Admin
            </button>
          </form>

          <div className="mt-6 pt-4 border-t border-slate-700/60 text-center">
            <Link href="/" className="text-xs text-slate-400 hover:text-white transition-colors">
              ← Kembali ke Beranda
            </Link>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-900 text-slate-100 p-4 sm:p-8">
      <div className="max-w-5xl mx-auto">
        {/* Header */}
        <div className="flex flex-wrap items-center justify-between gap-4 mb-8 border-b border-slate-800 pb-6">
          <div>
            <div className="flex items-center gap-2 mb-2">
              <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-500/20 text-amber-400 border border-amber-500/30">
                <ShieldCheck className="w-3.5 h-3.5" />
                PANEL UTAMA MARKETING
              </div>
              <div className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-bold bg-blue-500/20 text-blue-300 border border-blue-500/30">
                <User className="w-3 h-3" />
                @{adminId}
              </div>
            </div>
            <h1 className="text-2xl sm:text-3xl font-black text-white tracking-tight">
              Manajemen Room Doorprize
            </h1>
            <p className="text-xs sm:text-sm text-slate-400 mt-1">
              Menampilkan room event khusus milik admin <strong className="text-white">@{adminId}</strong>.
            </p>
          </div>

          <div className="flex items-center gap-2.5">
            <Link
              href="/"
              className="py-2.5 px-3.5 rounded-xl border border-slate-700 hover:bg-slate-800 text-xs font-bold text-slate-300 transition-colors"
            >
              Halaman Depan
            </Link>
            <button
              onClick={() => setShowCreateModal(true)}
              className="py-2.5 px-4 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 hover:brightness-110 text-white text-xs font-bold flex items-center gap-1.5 shadow-lg shadow-amber-500/20 active:scale-95 transition-all"
            >
              <Plus className="w-4 h-4" />
              Buat Room Baru
            </button>
            <button
              onClick={handleLogout}
              className="py-2.5 px-3.5 rounded-xl bg-rose-600/20 hover:bg-rose-600/30 text-rose-300 border border-rose-500/40 text-xs font-bold flex items-center gap-1.5 transition-colors"
              title="Keluar dari akun admin"
            >
              <LogOut className="w-3.5 h-3.5" />
              Logout
            </button>
          </div>
        </div>

        {/* Room Grid */}
        {loading ? (
          <div className="text-center py-20 text-slate-500">Memuat daftar room milik @{adminId}...</div>
        ) : rooms.length === 0 ? (
          <div className="text-center py-16 bg-slate-800/40 border border-slate-800 rounded-3xl p-8">
            <Gift className="w-12 h-12 text-slate-600 mx-auto mb-3" />
            <h3 className="text-base font-bold text-slate-300">Belum Ada Room untuk @{adminId}</h3>
            <p className="text-xs text-slate-500 mt-1 mb-4">
              Klik tombol di bawah untuk membuat room doorprize pertamamu!
            </p>
            <button
              onClick={() => setShowCreateModal(true)}
              className="py-2.5 px-4 rounded-xl bg-amber-500 hover:bg-amber-400 text-white text-xs font-bold flex items-center gap-1.5 mx-auto transition-all"
            >
              <Plus className="w-4 h-4" />
              Buat Room Sekarang
            </button>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {rooms.map((room) => (
              <div
                key={room.id}
                className="bg-slate-800/90 border border-slate-700/80 hover:border-amber-500/50 rounded-3xl p-5 flex flex-col justify-between transition-all hover:shadow-xl hover:shadow-amber-500/5 group"
              >
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-mono text-xs font-black px-2.5 py-1 rounded-lg bg-amber-400/20 text-amber-300 border border-amber-400/30">
                      {room.code}
                    </span>
                    <div className="flex items-center gap-1.5">
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-blue-500/20 text-blue-300 font-bold">
                        @{room.adminId || adminId}
                      </span>
                      <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-300 font-bold">
                        {room.status === 'active' ? 'Aktif' : 'Tutup'}
                      </span>
                    </div>
                  </div>

                  <h3 className="text-base font-black text-white group-hover:text-amber-400 transition-colors">
                    {room.name}
                  </h3>
                  {room.description && (
                    <p className="text-xs text-slate-400 mt-1 line-clamp-2">{room.description}</p>
                  )}

                  <div className="mt-4 pt-3 border-t border-slate-700/60 flex items-center justify-between text-xs text-slate-400">
                    <span>Hadiah: <strong className="text-white">{room.prizesCount} Jenis</strong></span>
                    <span>Sisa Stok: <strong className="text-amber-400">{room.totalStock}</strong></span>
                  </div>
                </div>

                <div className="mt-5 pt-3 border-t border-slate-700/60 flex gap-2">
                  <Link
                    href={`/admin/room/${room.code}`}
                    className="flex-1 py-2.5 px-3 rounded-xl bg-slate-700 hover:bg-slate-600 text-white font-bold text-xs flex items-center justify-center gap-1.5 transition-colors"
                  >
                    Buka Panel Admin
                    <ArrowRight className="w-3.5 h-3.5" />
                  </Link>
                  <Link
                    href={`/room/${room.code}`}
                    target="_blank"
                    className="p-2.5 rounded-xl border border-slate-700 hover:bg-slate-800 text-amber-400 font-bold text-xs flex items-center justify-center"
                    title="Buka Link Peserta"
                  >
                    <QrCode className="w-4 h-4" />
                  </Link>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Footer Admin Session Bar */}
        <div className="mt-12 p-4 bg-slate-800/60 border border-slate-800 rounded-2xl flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-rose-500/20 border border-rose-500/30 flex items-center justify-center text-rose-400">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs font-bold text-white">Sesi Admin Aktif: @{adminId}</p>
              <p className="text-[11px] text-slate-400">Data room dan prospek siswa terisolasi khusus akun Anda.</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="py-2 px-4 rounded-xl bg-rose-600/20 hover:bg-rose-600 text-rose-300 hover:text-white border border-rose-500/30 text-xs font-bold flex items-center gap-1.5 transition-colors"
          >
            <LogOut className="w-3.5 h-3.5" />
            Logout Akun Admin
          </button>
        </div>

        {/* Modal Buat Room */}
        {showCreateModal && (
          <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-xs flex items-center justify-center p-4">
            <div className="bg-slate-800 border border-slate-700 rounded-3xl max-w-md w-full p-6 shadow-2xl">
              <div className="flex items-center justify-between mb-2">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-xl bg-amber-500/20 border border-amber-500/30 flex items-center justify-center text-amber-400">
                    <Plus className="w-4 h-4" />
                  </div>
                  <h2 className="text-lg font-black text-white">Buat Room Doorprize Baru</h2>
                </div>
                <button
                  onClick={() => setShowCreateModal(false)}
                  className="p-1 rounded-lg text-slate-400 hover:text-white hover:bg-slate-700"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>

              <div className="mb-4 inline-flex items-center gap-1.5 px-3 py-1 rounded-xl bg-blue-500/10 border border-blue-500/20 text-blue-300 text-[11px] font-bold">
                <User className="w-3 h-3" />
                Room ini dibuat otomatis untuk Admin: @{adminId}
              </div>

              {createError && (
                <div className="p-3 rounded-xl bg-rose-500/20 border border-rose-500/40 text-rose-300 text-xs mb-3 flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0" />
                  <span>{createError}</span>
                </div>
              )}

              <form onSubmit={handleCreateRoom} className="space-y-3.5">
                <div>
                  <label className="block text-xs font-bold text-slate-300 mb-1">
                    Nama Event / Sekolah <span className="text-amber-400">*</span>
                  </label>
                  <div className="relative">
                    <School className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      required
                      placeholder="Contoh: Kunjungan SMAN 1 Denpasar"
                      value={name}
                      onChange={(e) => setName(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-hidden focus:border-amber-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-300 mb-1">
                    Kode Room Unik (Huruf/Angka) <span className="text-amber-400">*</span>
                  </label>
                  <div className="relative">
                    <QrCode className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      required
                      placeholder="Contoh: SMAN1DPS atau EXPO2026"
                      value={code}
                      onChange={(e) => setCode(e.target.value.toUpperCase().replace(/[^A-Z0-9-]/g, ''))}
                      className="w-full pl-9 pr-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-xs font-mono uppercase text-amber-400 font-bold focus:outline-hidden focus:border-amber-500"
                    />
                  </div>
                  <p className="text-[10px] text-slate-500 mt-1">Siswa akan join ke link /room/KODE</p>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-300 mb-1">
                    PIN Admin Khusus Room Ini <span className="text-amber-400">*</span>
                  </label>
                  <div className="relative">
                    <KeyRound className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      required
                      placeholder="Contoh: 1234"
                      value={pin}
                      onChange={(e) => setPin(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-xs font-mono text-white focus:outline-hidden focus:border-amber-500"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-xs font-bold text-slate-300 mb-1">
                    Keterangan Singkat (Opsional)
                  </label>
                  <div className="relative">
                    <FileText className="w-4 h-4 text-slate-500 absolute left-3 top-3" />
                    <textarea
                      rows={2}
                      placeholder="Doorprize stan pameran pendidikan..."
                      value={description}
                      onChange={(e) => setDescription(e.target.value)}
                      className="w-full pl-9 pr-3 py-2.5 bg-slate-900 border border-slate-700 rounded-xl text-xs text-white focus:outline-hidden focus:border-amber-500"
                    />
                  </div>
                </div>

                <div className="pt-2 flex gap-2">
                  <button
                    type="button"
                    onClick={() => setShowCreateModal(false)}
                    className="flex-1 py-2.5 rounded-xl border border-slate-700 text-slate-300 font-bold text-xs hover:bg-slate-700 flex items-center justify-center gap-1.5"
                  >
                    <X className="w-3.5 h-3.5" />
                    Batal
                  </button>
                  <button
                    type="submit"
                    disabled={isCreating}
                    className="flex-1 py-2.5 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 text-white font-bold text-xs shadow hover:brightness-110 flex items-center justify-center gap-1.5"
                  >
                    <Sparkles className="w-3.5 h-3.5" />
                    {isCreating ? 'Menyimpan...' : 'Buat Room'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
