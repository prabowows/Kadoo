'use client';

import React, { useState } from 'react';
import { ParticipantLead } from '@/lib/types';
import { CheckCircle2, Clock, Copy, Share2, Ticket, Sparkles } from 'lucide-react';

interface ClaimTicketProps {
  lead: ParticipantLead;
  roomName: string;
  roomCode: string;
}

export default function ClaimTicket({ lead, roomName, roomCode }: ClaimTicketProps) {
  const [copied, setCopied] = useState(false);

  const handleCopyCode = () => {
    navigator.clipboard.writeText(lead.claimCode);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleShare = () => {
    if (navigator.share) {
      navigator.share({
        title: `Tiket Doorprize - ${lead.prizeWon}`,
        text: `Hore! Saya mendapatkan ${lead.prizeWon} di acara ${roomName}! Kode Tiket: ${lead.claimCode}`,
        url: window.location.href,
      }).catch(() => {});
    } else {
      handleCopyCode();
    }
  };

  return (
    <div className="w-full max-w-sm mx-auto my-4">
      {/* Decorative Ticket Container */}
      <div className="bg-white rounded-3xl shadow-2xl border-2 border-amber-300 overflow-hidden relative">
        {/* Top Header */}
        <div className="bg-gradient-to-r from-amber-500 via-orange-500 to-rose-500 p-5 text-white text-center relative">
          <div className="inline-flex items-center gap-1.5 px-3 py-0.5 rounded-full text-[11px] font-black bg-white/20 backdrop-blur-xs mb-2">
            <Sparkles className="w-3.5 h-3.5" />
            TIKET RESMI DOORPRIZE
          </div>
          <h2 className="text-xl font-black drop-shadow">{roomName}</h2>
          <p className="text-xs text-amber-100 font-medium mt-0.5">Room: {roomCode}</p>

          {/* Scallop cutout dots */}
          <div className="absolute -bottom-3 left-0 right-0 flex justify-between px-2">
            {Array.from({ length: 14 }).map((_, i) => (
              <div key={i} className="w-3 h-3 rounded-full bg-white" />
            ))}
          </div>
        </div>

        {/* Ticket Body */}
        <div className="p-6 pt-7 text-center">
          {/* Prize Announcement */}
          <p className="text-xs uppercase font-bold text-gray-400 tracking-wider">
            Selamat, Kamu Memenangkan:
          </p>
          <div className="mt-2 py-3 px-4 rounded-2xl bg-gradient-to-br from-amber-50 via-yellow-50 to-orange-50 border-2 border-amber-300">
            <span className="text-4xl block mb-1">🎁</span>
            <h3 className="text-2xl font-black text-gray-900 leading-tight">
              {lead.prizeWon}
            </h3>
          </div>

          {/* Claim Code Section */}
          <div className="mt-5 p-3 rounded-xl bg-slate-900 text-white flex items-center justify-between">
            <div className="text-left">
              <span className="text-[10px] text-gray-400 uppercase font-semibold block">
                KODE KLAIM BOOTH
              </span>
              <span className="text-xl font-mono font-black text-amber-400 tracking-widest">
                {lead.claimCode}
              </span>
            </div>
            <button
              onClick={handleCopyCode}
              className="p-2 rounded-lg bg-slate-800 hover:bg-slate-700 text-amber-300 text-xs flex items-center gap-1 font-semibold"
            >
              <Copy className="w-4 h-4" />
              {copied ? 'Tersalin' : 'Salin'}
            </button>
          </div>

          {/* Status Badge */}
          <div className="mt-4 flex items-center justify-center">
            {lead.isClaimed ? (
              <div className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-emerald-100 text-emerald-800 font-bold text-xs border border-emerald-300">
                <CheckCircle2 className="w-4 h-4 text-emerald-600" />
                SUDAH DIAMBIL DI BOOTH
              </div>
            ) : (
              <div className="inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-amber-100 text-amber-800 font-bold text-xs border border-amber-300 animate-pulse">
                <Clock className="w-4 h-4 text-amber-600" />
                BELUM DIAMBIL (Tunjukkan ke Panitia)
              </div>
            )}
          </div>

          {/* Participant Details Summary */}
          <div className="mt-5 border-t border-dashed border-gray-200 pt-4 text-left text-xs space-y-1.5 text-gray-600">
            <div className="flex justify-between">
              <span className="text-gray-400">Pemenang:</span>
              <span className="font-semibold text-gray-800">{lead.fullName}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Asal Sekolah:</span>
              <span className="font-semibold text-gray-800">{lead.schoolName} ({lead.schoolCity})</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">Minat Prodi:</span>
              <span className="font-semibold text-amber-700">{lead.studyInterest}</span>
            </div>
            <div className="flex justify-between">
              <span className="text-gray-400">WhatsApp:</span>
              <span className="font-semibold text-gray-800">{lead.waNumber}</span>
            </div>
          </div>

          {/* Action buttons */}
          <div className="mt-6 flex gap-2">
            <button
              onClick={handleShare}
              className="flex-1 py-3 px-4 rounded-xl bg-gradient-to-r from-amber-500 to-orange-500 text-white font-bold text-xs flex items-center justify-center gap-2 shadow-md hover:brightness-105 active:scale-95"
            >
              <Share2 className="w-4 h-4" />
              Bagikan / Simpan
            </button>
          </div>

          <p className="text-[11px] text-gray-400 mt-3">
            Tunjukkan layar ini kepada petugas di booth untuk mengambil hadiahmu!
          </p>
        </div>
      </div>
    </div>
  );
}
