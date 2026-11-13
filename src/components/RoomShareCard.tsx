'use client';

import React, { useEffect, useState } from 'react';
import QRCode from 'qrcode';
import { Copy, Check, ExternalLink, QrCode as QrIcon } from 'lucide-react';

interface RoomShareCardProps {
  roomCode: string;
  roomName: string;
}

export default function RoomShareCard({ roomCode, roomName }: RoomShareCardProps) {
  const [qrUrl, setQrUrl] = useState<string>('');
  const [copied, setCopied] = useState(false);
  const [shareLink, setShareLink] = useState('');

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const url = `${window.location.origin}/room/${roomCode}`;
      setShareLink(url);
      QRCode.toDataURL(url, {
        width: 320,
        margin: 2,
        color: {
          dark: '#1E293B',
          light: '#FFFFFF',
        },
      }).then(setQrUrl).catch(console.error);
    }
  }, [roomCode]);

  const handleCopy = () => {
    navigator.clipboard.writeText(shareLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="bg-white rounded-3xl p-6 border-2 border-amber-300 shadow-xl max-w-sm mx-auto text-center">
      <div className="inline-flex items-center gap-1 px-3 py-1 rounded-full text-xs font-black bg-amber-100 text-amber-800 mb-2">
        <QrIcon className="w-3.5 h-3.5" />
        SCAN UNTUK MAIN
      </div>
      <h3 className="text-lg font-black text-gray-900">{roomName}</h3>
      <p className="text-xs text-gray-500 mb-4">Kode Room: <span className="font-mono font-bold text-amber-600">{roomCode}</span></p>

      {/* QR Display */}
      <div className="p-3 bg-amber-50 rounded-2xl border border-amber-200 inline-block shadow-inner mb-4">
        {qrUrl ? (
          <img src={qrUrl} alt={`QR Code ${roomCode}`} className="w-56 h-56 rounded-xl" />
        ) : (
          <div className="w-56 h-56 bg-gray-100 animate-pulse rounded-xl flex items-center justify-center text-xs text-gray-400">
            Membuat QR...
          </div>
        )}
      </div>

      <div className="space-y-2">
        <div className="p-2.5 bg-gray-50 rounded-xl border border-gray-200 flex items-center justify-between text-xs font-mono text-gray-600 break-all text-left">
          <span className="truncate mr-2">{shareLink}</span>
          <button
            onClick={handleCopy}
            className="p-1.5 rounded-lg bg-amber-500 text-white shrink-0 hover:bg-amber-600 font-sans font-bold flex items-center gap-1 text-[11px]"
          >
            {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
            {copied ? 'Disalin' : 'Salin'}
          </button>
        </div>

        <a
          href={`/room/${roomCode}`}
          target="_blank"
          rel="noreferrer"
          className="w-full py-2.5 px-4 rounded-xl bg-slate-900 text-white text-xs font-bold flex items-center justify-center gap-1.5 hover:bg-slate-800 transition-colors"
        >
          <ExternalLink className="w-3.5 h-3.5" />
          Buka Tampilan Peserta
        </a>
      </div>
    </div>
  );
}
