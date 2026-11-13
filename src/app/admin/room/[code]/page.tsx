'use client';

import React, { useState, useEffect, use } from 'react';
import { Room, ParticipantLead, PrizeItem, GameType } from '@/lib/types';
import RoomShareCard from '@/components/RoomShareCard';
import * as XLSX from 'xlsx';
import {
  Users,
  Gift,
  QrCode,
  Download,
  Search,
  CheckCircle2,
  Clock,
  ArrowLeft,
  Plus,
  Trash2,
  Lock,
  RefreshCw,
  ExternalLink,
  MessageCircle,
} from 'lucide-react';
import Link from 'next/link';

export default function AdminRoomPage({ params }: { params: Promise<{ code: string }> }) {
  const { code } = use(params);
  const [pin, setPin] = useState('');
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authError, setAuthError] = useState('');

  const [room, setRoom] = useState<Room | null>(null);
  const [participants, setParticipants] = useState<ParticipantLead[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState<'leads' | 'prizes' | 'qr'>('leads');

  // Search & Filter
  const [searchQuery, setSearchQuery] = useState('');
  const [filterClaim, setFilterClaim] = useState<'all' | 'claimed' | 'unclaimed'>('all');

  // Add prize modal / state
  const [newPrizeName, setNewPrizeName] = useState('');
  const [newPrizeStock, setNewPrizeStock] = useState(10);
  const [newPrizeColor, setNewPrizeColor] = useState('#3B82F6');

  // Load session pin if exists
  useEffect(() => {
    const savedPin = sessionStorage.getItem(`admin_pin_${code}`);
    if (savedPin) {
      setPin(savedPin);
      fetchAdminData(savedPin);
    }
  }, [code]);

  const fetchAdminData = async (targetPin: string) => {
    setLoading(true);
    setAuthError('');
    try {
      // 1. Fetch Room with admin details
      const roomRes = await fetch(`/api/rooms/${code}?pin=${targetPin}`);
      const roomData = await roomRes.json();
      if (!roomData.success || !roomData.room.isAdmin) {
        setIsAuthenticated(false);
        setAuthError('PIN Admin tidak tepat!');
        setLoading(false);
        return;
      }

      setRoom(roomData.room);

      // 2. Fetch Participants
      const partRes = await fetch(`/api/rooms/${code}/participants?pin=${targetPin}`);
      const partData = await partRes.json();
      if (partData.success) {
        setParticipants(partData.participants);
      }

      setIsAuthenticated(true);
      sessionStorage.setItem(`admin_pin_${code}`, targetPin);
    } catch {
      setAuthError('Gagal memuat data dari server');
    } finally {
      setLoading(false);
    }
  };

  const handleLogin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!pin) return;
    fetchAdminData(pin);
  };

  // Toggle Claim Status
  const handleToggleClaim = async (leadId: string) => {
    try {
      const res = await fetch(`/api/participants/${leadId}/toggle-claim`, {
        method: 'POST',
      });
      const data = await res.json();
      if (data.success) {
        setParticipants((prev) =>
          prev.map((p) => (p.id === leadId ? data.participant : p))
        );
      }
    } catch (err) {
      console.error('Error toggling claim', err);
    }
  };

  // Update Stock or Prizes
  const handleUpdatePrizes = async (updatedPrizes: PrizeItem[]) => {
    if (!room) return;
    try {
      const res = await fetch(`/api/rooms/${code}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          pin,
          prizes: updatedPrizes,
        }),
      });
      const data = await res.json();
      if (data.success) {
        setRoom(data.room);
      }
    } catch (err) {
      console.error(err);
    }
  };

  // Add new prize item
  const handleAddPrize = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newPrizeName.trim() || !room) return;

    const newPrize: PrizeItem = {
      id: `p-${Date.now()}`,
      name: newPrizeName.trim(),
      initialStock: Number(newPrizeStock),
      currentStock: Number(newPrizeStock),
      color: newPrizeColor,
      weight: 20,
    };

    const updated = [...room.prizes, newPrize];
    handleUpdatePrizes(updated);
    setNewPrizeName('');
    setNewPrizeStock(10);
  };

  // Delete a prize item
  const handleDeletePrize = (prizeId: string) => {
    if (!room || !confirm('Yakin ingin menghapus hadiah ini?')) return;
    const updated = room.prizes.filter((p) => p.id !== prizeId);
    handleUpdatePrizes(updated);
  };

  // Quick stock adjuster (+1 / -1)
  const adjustStock = (prizeId: string, delta: number) => {
    if (!room) return;
    const updated = room.prizes.map((p) => {
      if (p.id === prizeId) {
        const next = Math.max(0, p.currentStock + delta);
        return { ...p, currentStock: next };
      }
      return p;
    });
    handleUpdatePrizes(updated);
  };

  // Toggle Active Game
  const handleToggleGame = async (gameId: GameType) => {
    if (!room) return;
    let nextGames: GameType[];
    if (room.activeGames.includes(gameId)) {
      if (room.activeGames.length === 1) {
        alert('Minimal 1 game harus tetap aktif!');
        return;
      }
      nextGames = room.activeGames.filter((g) => g !== gameId);
    } else {
      nextGames = [...room.activeGames, gameId];
    }

    try {
      const res = await fetch(`/api/rooms/${code}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          pin,
          activeGames: nextGames,
        }),
      });
      const data = await res.json();
      if (data.success) {
        setRoom(data.room);
      }
    } catch (err) {
      console.error(err);
    }
  };

  // Export to Excel
  const handleExportExcel = () => {
    if (participants.length === 0) {
      alert('Belum ada data peserta untuk diekspor');
      return;
    }

    const rows = participants.map((p, idx) => ({
      No: idx + 1,
      'Kode Tiket': p.claimCode,
      'Nama Lengkap': p.fullName,
      'WhatsApp Siswa': p.waNumber,
      'WhatsApp Ortu': p.waParentNumber,
      Email: p.email,
      Kelas: p.grade,
      'Asal Sekolah': p.schoolName,
      'Kota Sekolah': p.schoolCity,
      'Program Studi Diminati': p.studyInterest,
      'Game Dimainkan': p.gamePlayed,
      'Hadiah Dimenangkan': p.prizeWon,
      'Status Klaim': p.isClaimed ? 'SUDAH DIAMBIL' : 'BELUM DIAMBIL',
      'Waktu Daftar': new Date(p.createdAt).toLocaleString('id-ID'),
      'Waktu Klaim': p.claimedAt ? new Date(p.claimedAt).toLocaleString('id-ID') : '-',
    }));

    const worksheet = XLSX.utils.json_to_sheet(rows);
    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Data Leads');

    // Generate buffer & download
    XLSX.writeFile(workbook, `Leads_${code}_${new Date().toISOString().split('T')[0]}.xlsx`);
  };

  // Filtered participants list
  const filteredParticipants = participants.filter((p) => {
    const matchQuery =
      p.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.waNumber.includes(searchQuery) ||
      p.schoolName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.claimCode.toLowerCase().includes(searchQuery.toLowerCase());

    if (!matchQuery) return false;
    if (filterClaim === 'claimed') return p.isClaimed;
    if (filterClaim === 'unclaimed') return !p.isClaimed;
    return true;
  });

  // Login Gate
  if (!isAuthenticated) {
    return (
      <div className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="bg-slate-800 border border-slate-700 p-8 rounded-3xl shadow-2xl max-w-sm w-full text-white text-center">
          <div className="w-14 h-14 bg-amber-500/20 border border-amber-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Lock className="w-7 h-7 text-amber-400" />
          </div>
          <h2 className="text-xl font-black">Panel Admin Room</h2>
          <p className="text-xs text-slate-400 mt-1 mb-5">
            Masukkan PIN Admin untuk room <span className="font-mono text-amber-400 font-bold">{code}</span>
          </p>

          <form onSubmit={handleLogin} className="space-y-4">
            <input
              type="password"
              placeholder="Masukkan PIN (Default: 1234)"
              value={pin}
              onChange={(e) => setPin(e.target.value)}
              className="w-full text-center tracking-widest text-lg font-mono py-3 px-4 bg-slate-900 border border-slate-700 rounded-xl focus:outline-hidden focus:border-amber-500 text-white"
            />

            {authError && <p className="text-xs text-rose-400 font-semibold">{authError}</p>}

            <button
              type="submit"
              disabled={loading}
              className="w-full py-3 bg-gradient-to-r from-amber-500 to-orange-500 text-white font-extrabold rounded-xl shadow-lg hover:brightness-110 active:scale-98 transition-all text-sm"
            >
              {loading ? 'Memverifikasi...' : 'Masuk Dashboard'}
            </button>
          </form>

          <Link
            href="/admin"
            className="inline-block mt-5 text-xs text-slate-400 hover:text-white"
          >
            ← Kembali ke Semua Room
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-slate-100 text-slate-900">
      {/* Top Header */}
      <header className="bg-white border-b border-slate-200 sticky top-0 z-30 shadow-xs">
        <div className="max-w-7xl mx-auto px-4 py-3 flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <Link
              href="/admin"
              className="p-2 rounded-lg hover:bg-slate-100 text-slate-500"
              title="Kembali ke Daftar Room"
            >
              <ArrowLeft className="w-5 h-5" />
            </Link>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-black text-slate-900">{room?.name}</h1>
                <span className="px-2 py-0.5 rounded-full text-xs font-mono font-bold bg-amber-100 text-amber-800">
                  {room?.code}
                </span>
              </div>
              <p className="text-xs text-slate-500">
                Total Leads: <strong className="text-slate-800">{participants.length}</strong> | Hadiah Diambil: <strong className="text-emerald-600">{participants.filter((p) => p.isClaimed).length}</strong>
              </p>
            </div>
          </div>

          {/* Action buttons */}
          <div className="flex items-center gap-2">
            <button
              onClick={() => fetchAdminData(pin)}
              className="p-2.5 rounded-xl border border-slate-300 hover:bg-slate-50 text-slate-600 text-xs font-bold flex items-center gap-1.5"
              title="Refresh Data"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
            </button>

            <button
              onClick={handleExportExcel}
              className="py-2.5 px-4 rounded-xl bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold flex items-center gap-1.5 shadow-sm"
            >
              <Download className="w-4 h-4" />
              Download Excel (.xlsx)
            </button>

            <a
              href={`/room/${code}`}
              target="_blank"
              rel="noreferrer"
              className="py-2.5 px-3 rounded-xl bg-amber-500 hover:bg-amber-600 text-white text-xs font-bold flex items-center gap-1"
            >
              <ExternalLink className="w-4 h-4" />
              Test Play
            </a>
          </div>
        </div>

        {/* Navigation Tabs */}
        <div className="max-w-7xl mx-auto px-4 flex gap-6 border-t border-slate-100 text-xs font-bold">
          <button
            onClick={() => setActiveTab('leads')}
            className={`py-3 flex items-center gap-1.5 border-b-2 transition-all ${
              activeTab === 'leads'
                ? 'border-amber-500 text-amber-600'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <Users className="w-4 h-4" />
            Rekap Data Leads ({participants.length})
          </button>
          <button
            onClick={() => setActiveTab('prizes')}
            className={`py-3 flex items-center gap-1.5 border-b-2 transition-all ${
              activeTab === 'prizes'
                ? 'border-amber-500 text-amber-600'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <Gift className="w-4 h-4" />
            Hadiah & Stok ({room?.prizes.length || 0})
          </button>
          <button
            onClick={() => setActiveTab('qr')}
            className={`py-3 flex items-center gap-1.5 border-b-2 transition-all ${
              activeTab === 'qr'
                ? 'border-amber-500 text-amber-600'
                : 'border-transparent text-slate-500 hover:text-slate-800'
            }`}
          >
            <QrCode className="w-4 h-4" />
            QR Code & Link Booth
          </button>
        </div>
      </header>

      {/* Content Area */}
      <main className="max-w-7xl mx-auto p-4 sm:p-6">
        {/* TAB 1: LEADS REKAP & CLAIM TABLE */}
        {activeTab === 'leads' && (
          <div className="space-y-4">
            {/* Search and Filter Bar */}
            <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs flex flex-wrap items-center justify-between gap-3">
              <div className="relative flex-1 min-w-[240px]">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                <input
                  type="text"
                  placeholder="Cari Nama, No WA, Asal Sekolah, atau Kode Tiket..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs sm:text-sm focus:outline-hidden focus:ring-2 focus:ring-amber-500"
                />
              </div>

              <div className="flex items-center gap-2">
                <span className="text-xs text-slate-500 font-bold">Status:</span>
                <select
                  value={filterClaim}
                  onChange={(e) => setFilterClaim(e.target.value as any)}
                  className="py-2 px-3 bg-slate-50 border border-slate-200 rounded-xl text-xs font-semibold focus:outline-hidden"
                >
                  <option value="all">Semua Status</option>
                  <option value="unclaimed">Belum Diambil</option>
                  <option value="claimed">Sudah Diambil</option>
                </select>
              </div>
            </div>

            {/* Table */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border-collapse">
                  <thead>
                    <tr className="bg-slate-50 border-b border-slate-200 text-slate-500 uppercase tracking-wider font-bold">
                      <th className="p-3">Tiket</th>
                      <th className="p-3">Siswa</th>
                      <th className="p-3">Kontak WA</th>
                      <th className="p-3">Sekolah & Kota</th>
                      <th className="p-3">Minat Prodi</th>
                      <th className="p-3">Hadiah & Game</th>
                      <th className="p-3">Status Klaim</th>
                      <th className="p-3 text-right">Aksi</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredParticipants.length === 0 ? (
                      <tr>
                        <td colSpan={8} className="p-8 text-center text-slate-400">
                          Belum ada peserta yang sesuai dengan pencarian
                        </td>
                      </tr>
                    ) : (
                      filteredParticipants.map((p) => {
                        const cleanWa = p.waNumber.replace(/[^0-9]/g, '');
                        const waUrl = `https://wa.me/${cleanWa.startsWith('0') ? '62' + cleanWa.slice(1) : cleanWa}`;

                        return (
                          <tr key={p.id} className="hover:bg-amber-50/40 transition-colors">
                            {/* Tiket */}
                            <td className="p-3 font-mono font-black text-amber-600 whitespace-nowrap">
                              {p.claimCode}
                            </td>

                            {/* Nama Siswa */}
                            <td className="p-3">
                              <p className="font-bold text-slate-900">{p.fullName}</p>
                              <p className="text-[11px] text-slate-400">{p.email}</p>
                              <span className="inline-block mt-0.5 px-1.5 py-0.2 rounded text-[10px] bg-slate-100 text-slate-600 font-medium">
                                Kelas {p.grade}
                              </span>
                            </td>

                            {/* Kontak WA */}
                            <td className="p-3 whitespace-nowrap space-y-1">
                              <a
                                href={waUrl}
                                target="_blank"
                                rel="noreferrer"
                                className="inline-flex items-center gap-1 font-semibold text-emerald-700 hover:underline"
                              >
                                <MessageCircle className="w-3.5 h-3.5" />
                                {p.waNumber} (Siswa)
                              </a>
                              <p className="text-[11px] text-slate-400">
                                Ortu: {p.waParentNumber}
                              </p>
                            </td>

                            {/* Asal Sekolah */}
                            <td className="p-3">
                              <p className="font-semibold text-slate-800">{p.schoolName}</p>
                              <p className="text-[11px] text-slate-500">{p.schoolCity}</p>
                            </td>

                            {/* Minat Prodi */}
                            <td className="p-3">
                              <span className="font-semibold text-amber-700 bg-amber-50 px-2 py-1 rounded-lg">
                                {p.studyInterest}
                              </span>
                            </td>

                            {/* Hadiah & Game */}
                            <td className="p-3 whitespace-nowrap">
                              <p className="font-bold text-slate-900">{p.prizeWon}</p>
                              <span className="text-[10px] text-slate-400 uppercase font-semibold">
                                Game: {p.gamePlayed}
                              </span>
                            </td>

                            {/* Status Klaim */}
                            <td className="p-3 whitespace-nowrap">
                              {p.isClaimed ? (
                                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-100 text-emerald-800">
                                  <CheckCircle2 className="w-3.5 h-3.5" /> Sudah Diambil
                                </span>
                              ) : (
                                <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[11px] font-bold bg-amber-100 text-amber-800">
                                  <Clock className="w-3.5 h-3.5" /> Belum Diambil
                                </span>
                              )}
                            </td>

                            {/* Action Button */}
                            <td className="p-3 text-right whitespace-nowrap">
                              <button
                                onClick={() => handleToggleClaim(p.id)}
                                className={`px-3 py-1.5 rounded-xl font-bold text-xs transition-all ${
                                  p.isClaimed
                                    ? 'bg-slate-200 text-slate-700 hover:bg-slate-300'
                                    : 'bg-emerald-600 text-white hover:bg-emerald-700 shadow-sm'
                                }`}
                              >
                                {p.isClaimed ? 'Batalkan' : 'Tandai Diambil'}
                              </button>
                            </td>
                          </tr>
                        );
                      })
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* TAB 2: PRIZES & GAME TOGGLES */}
        {activeTab === 'prizes' && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {/* List of Prizes */}
            <div className="md:col-span-2 space-y-4">
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
                <h2 className="text-base font-black text-slate-900 mb-4 flex items-center justify-between">
                  <span>Daftar Hadiah & Stok ({room?.prizes.length})</span>
                  <span className="text-xs font-normal text-slate-400">
                    Total Stok Tersisa: {room?.prizes.reduce((sum, p) => sum + p.currentStock, 0)}
                  </span>
                </h2>

                <div className="space-y-3">
                  {room?.prizes.map((prize) => (
                    <div
                      key={prize.id}
                      className="p-3.5 rounded-xl border border-slate-200 bg-slate-50 flex items-center justify-between gap-3"
                    >
                      <div className="flex items-center gap-3">
                        <div
                          className="w-5 h-5 rounded-full shrink-0 border border-white shadow-xs"
                          style={{ backgroundColor: prize.color }}
                        />
                        <div>
                          <p className="font-bold text-slate-900 text-sm">{prize.name}</p>
                          <p className="text-[11px] text-slate-400">
                            Stok Awal: {prize.initialStock} | Peluang: {prize.weight || 20}%
                          </p>
                        </div>
                      </div>

                      {/* Stock controls */}
                      <div className="flex items-center gap-2">
                        <button
                          onClick={() => adjustStock(prize.id, -1)}
                          className="w-7 h-7 rounded-lg bg-white border border-slate-300 font-bold text-slate-700 hover:bg-slate-100 flex items-center justify-center text-sm"
                        >
                          -
                        </button>
                        <span
                          className={`w-10 text-center font-mono font-bold text-sm ${
                            prize.currentStock === 0 ? 'text-red-500' : 'text-slate-900'
                          }`}
                        >
                          {prize.currentStock}
                        </span>
                        <button
                          onClick={() => adjustStock(prize.id, 1)}
                          className="w-7 h-7 rounded-lg bg-white border border-slate-300 font-bold text-slate-700 hover:bg-slate-100 flex items-center justify-center text-sm"
                        >
                          +
                        </button>

                        <button
                          onClick={() => handleDeletePrize(prize.id)}
                          className="p-1.5 text-slate-400 hover:text-red-600 rounded-lg ml-1"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Game Toggles */}
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
                <h3 className="text-sm font-black text-slate-900 mb-3">
                  Game Doorprize yang Aktif di Room Ini
                </h3>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2.5">
                  {(
                    [
                      { id: 'spinwheel', label: '🎡 Lucky Spin Wheel' },
                      { id: 'scratch', label: '🎫 Scratch Card' },
                      { id: 'slot', label: '🎰 Slot Machine' },
                      { id: 'gashapon', label: '⚪ Gashapon Capsule' },
                      { id: 'shake', label: '🎁 Shake The Box' },
                    ] as const
                  ).map((item) => {
                    const isEnabled = room?.activeGames.includes(item.id);
                    return (
                      <button
                        key={item.id}
                        onClick={() => handleToggleGame(item.id)}
                        className={`p-3 rounded-xl border text-left text-xs font-bold transition-all ${
                          isEnabled
                            ? 'bg-amber-50 border-amber-300 text-amber-900'
                            : 'bg-slate-50 border-slate-200 text-slate-400'
                        }`}
                      >
                        <div className="flex items-center justify-between">
                          <span>{item.label}</span>
                          <span className={`text-[10px] ${isEnabled ? 'text-emerald-600' : 'text-slate-400'}`}>
                            {isEnabled ? 'ON' : 'OFF'}
                          </span>
                        </div>
                      </button>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Form Tambah Hadiah Baru */}
            <div>
              <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-xs">
                <h3 className="text-sm font-black text-slate-900 mb-3 flex items-center gap-1.5">
                  <Plus className="w-4 h-4 text-amber-500" />
                  Tambah Hadiah Baru
                </h3>
                <form onSubmit={handleAddPrize} className="space-y-3">
                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Nama Hadiah
                    </label>
                    <input
                      type="text"
                      required
                      placeholder="Contoh: Powerbank 10.000mAh"
                      value={newPrizeName}
                      onChange={(e) => setNewPrizeName(e.target.value)}
                      className="w-full p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-amber-500"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Stok Awal
                    </label>
                    <input
                      type="number"
                      min={1}
                      required
                      value={newPrizeStock}
                      onChange={(e) => setNewPrizeStock(Number(e.target.value))}
                      className="w-full p-2.5 bg-slate-50 border border-slate-300 rounded-xl text-xs focus:outline-hidden focus:ring-2 focus:ring-amber-500"
                    />
                  </div>

                  <div>
                    <label className="block text-xs font-bold text-slate-700 mb-1">
                      Warna Representasi (untuk Roda)
                    </label>
                    <div className="flex items-center gap-2">
                      <input
                        type="color"
                        value={newPrizeColor}
                        onChange={(e) => setNewPrizeColor(e.target.value)}
                        className="w-10 h-10 rounded-xl cursor-pointer border border-slate-300 p-0.5"
                      />
                      <span className="text-xs font-mono text-slate-500">{newPrizeColor}</span>
                    </div>
                  </div>

                  <button
                    type="submit"
                    className="w-full py-2.5 px-4 bg-amber-500 hover:bg-amber-600 text-white font-bold text-xs rounded-xl shadow-sm transition-all"
                  >
                    Simpan Hadiah
                  </button>
                </form>
              </div>
            </div>
          </div>
        )}

        {/* TAB 3: QR CODE & BOOTH SHARING */}
        {activeTab === 'qr' && (
          <div className="py-6">
            <RoomShareCard roomCode={code} roomName={room?.name || 'Doorprize'} />
          </div>
        )}
      </main>
    </div>
  );
}
