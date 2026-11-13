'use client';

import React, { useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { Gift, Sparkles, ArrowRight, ShieldCheck, Smartphone, Trophy, QrCode } from 'lucide-react';

export default function HomePage() {
  const [roomCode, setRoomCode] = useState('');
  const [adminId, setAdminId] = useState<string | null>(null);
  const router = useRouter();

  React.useEffect(() => {
    try {
      const saved = localStorage.getItem('shaking_prize_admin_id');
      if (saved) setAdminId(saved);
    } catch {}
  }, []);

  const handleJoin = (e: React.FormEvent) => {
    e.preventDefault();
    if (!roomCode.trim()) return;
    router.push(`/room/${roomCode.trim().toUpperCase()}`);
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-900 via-indigo-950 to-slate-900 text-white flex flex-col justify-between p-4 sm:p-6">
      {/* Top Navbar */}
      <header className="max-w-4xl w-full mx-auto flex items-center justify-between py-2">
        <div className="flex items-center gap-2">
          <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-amber-400 to-orange-500 flex items-center justify-center shadow-lg shadow-amber-500/20">
            <Gift className="w-6 h-6 text-slate-950" />
          </div>
          <div>
            <h1 className="font-black text-lg tracking-tight">ShakingPrize</h1>
            <p className="text-[10px] text-amber-400/80 font-bold uppercase tracking-wider">
              Marketing Lead Generation
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2">
          {adminId ? (
            <>
              <Link
                href="/admin"
                className="flex items-center gap-1.5 py-2 px-3 rounded-xl bg-blue-500/20 text-blue-300 border border-blue-500/30 text-xs font-bold hover:bg-blue-500/30 transition-all"
              >
                <ShieldCheck className="w-3.5 h-3.5 text-blue-400" />
                @{adminId}
              </Link>
              <button
                onClick={() => {
                  try { localStorage.removeItem('shaking_prize_admin_id'); } catch {}
                  setAdminId(null);
                }}
                className="py-2 px-2.5 rounded-xl bg-rose-500/20 text-rose-300 border border-rose-500/30 hover:bg-rose-500/30 text-xs font-bold transition-all"
              >
                Logout
              </button>
            </>
          ) : (
            <Link
              href="/admin"
              className="flex items-center gap-1.5 py-2 px-3.5 rounded-xl bg-white/10 hover:bg-white/20 text-xs font-bold transition-all border border-white/10 text-slate-200"
            >
              <ShieldCheck className="w-4 h-4 text-amber-400" />
              Panel Admin
            </Link>
          )}
        </div>
      </header>

      {/* Hero Section */}
      <main className="max-w-md w-full mx-auto my-auto py-8 text-center">
        {/* Badge */}
        <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-amber-400/10 border border-amber-400/30 text-amber-300 text-xs font-bold mb-4 animate-pulse">
          <Sparkles className="w-4 h-4" />
          Klaim Hadiah Spesial Kunjungan Kampus
        </div>

        <h2 className="text-3xl sm:text-4xl font-black text-white tracking-tight leading-tight mb-3">
          Masukkan Kode Room <br />
          <span className="bg-gradient-to-r from-amber-400 via-orange-400 to-rose-400 bg-clip-text text-transparent">
            & Dapatkan Hadiahmu!
          </span>
        </h2>

        <p className="text-xs sm:text-sm text-slate-400 max-w-sm mx-auto mb-7">
          Scan QR Code di booth atau masukkan kode room yang diberikan panitia untuk bermain game doorprize.
        </p>

        {/* Room Join Card */}
        <div className="bg-white/10 backdrop-blur-md p-6 rounded-3xl border border-white/15 shadow-2xl">
          {/* Primary CTA: Scan QR */}
          <button
            type="button"
            onClick={() => {
              const code = prompt("Scan QR via kamera Anda atau masukkan URL/Kode QR booth:");
              if (code) {
                let cleanCode = code.trim();
                if (cleanCode.includes('/room/')) {
                  cleanCode = cleanCode.split('/room/')[1]?.split('?')[0]?.split('/')[0] || cleanCode;
                }
                if (cleanCode) router.push(`/room/${cleanCode.toUpperCase()}`);
              }
            }}
            className="w-full py-4 rounded-2xl bg-gradient-to-r from-amber-500 via-orange-500 to-rose-500 text-white font-black text-base shadow-lg shadow-orange-500/30 hover:brightness-110 active:scale-98 transition-all flex items-center justify-center gap-2 uppercase tracking-wider mb-4 cursor-pointer"
          >
            <QrCode className="w-5 h-5" />
            Scan QR di Booth
          </button>

          <div className="flex items-center gap-3 mb-4">
            <div className="h-px flex-1 bg-white/15" />
            <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">
              Atau Masukkan Kode Manual
            </span>
            <div className="h-px flex-1 bg-white/15" />
          </div>

          <form onSubmit={handleJoin} className="space-y-4">
            <div>
              <input
                type="text"
                placeholder="Ketik Kode Room (Contoh: DEMO2026)"
                value={roomCode}
                onChange={(e) => setRoomCode(e.target.value.toUpperCase().replace(/[^A-Z0-9-]/g, ''))}
                className="w-full text-center py-3.5 px-4 rounded-2xl bg-slate-900/80 border-2 border-amber-400/40 text-lg font-mono font-black text-amber-300 placeholder:text-slate-600 focus:outline-hidden focus:border-amber-400 transition-all uppercase tracking-widest shadow-inner"
              />
            </div>

            <button
              type="submit"
              className="w-full py-3.5 rounded-2xl bg-white/10 hover:bg-white/20 border border-white/20 text-white font-bold text-sm transition-all flex items-center justify-center gap-2 uppercase tracking-wider"
            >
              Masuk Room Doorprize
              <ArrowRight className="w-4 h-4" />
            </button>
          </form>

          {/* Quick Demo Access */}
          <div className="mt-5 pt-4 border-t border-white/10 flex items-center justify-between text-xs text-slate-400">
            <span>Coba Room Demo Sekarang:</span>
            <Link
              href="/room/DEMO2026"
              className="font-bold text-amber-400 hover:text-amber-300 underline flex items-center gap-1"
            >
              DEMO2026 ➔
            </Link>
          </div>
        </div>

        {/* 5 Fun Games Preview */}
        <div className="mt-8 grid grid-cols-5 gap-2 max-w-sm mx-auto">
          {[
            { icon: '🎡', label: 'Spin' },
            { icon: '🎫', label: 'Scratch' },
            { icon: '🎰', label: 'Slot' },
            { icon: '⚪', label: 'Capsule' },
            { icon: '🎁', label: 'Shake' },
          ].map((g, i) => (
            <div
              key={i}
              className="p-2 rounded-xl bg-white/5 border border-white/10 text-center flex flex-col items-center"
            >
              <span className="text-xl mb-0.5">{g.icon}</span>
              <span className="text-[10px] text-slate-400 font-semibold">{g.label}</span>
            </div>
          ))}
        </div>
      </main>

      {/* Footer */}
      <footer className="max-w-4xl w-full mx-auto text-center py-4 flex flex-col items-center gap-2 text-xs text-slate-500">
        <a
          href="https://binus.ac.id/semarang/computer-science/"
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-slate-800/80 border border-slate-700/80 text-slate-300 hover:text-white hover:border-amber-500/50 transition-all text-xs shadow-sm hover:scale-102"
        >
          <span>Developed by Computer Science Binus @Semarang</span>
          <span className="inline-flex items-center gap-1 font-bold text-amber-400 bg-amber-400/10 px-2 py-0.5 rounded-full text-[10px]">
            Want to know more? ↗
          </span>
        </a>
        <p>© 2026 ShakingPrize — Solusi Gamifikasi Booth & Registrasi Prospek Siswa</p>
      </footer>
    </div>
  );
}
