'use client';

import React, { useState } from 'react';
import { sounds } from '@/lib/audio';
import confetti from 'canvas-confetti';
import { RotateCw } from 'lucide-react';

interface GashaponProps {
  prizeName: string;
  onFinish: () => void;
  isLocked?: boolean;
}

const CAPSULES = [
  'bg-gradient-to-b from-red-500 to-white',
  'bg-gradient-to-b from-blue-500 to-white',
  'bg-gradient-to-b from-amber-400 to-white',
  'bg-gradient-to-b from-emerald-500 to-white',
  'bg-gradient-to-b from-purple-500 to-white',
  'bg-gradient-to-b from-pink-500 to-white',
];

export default function GashaponGame({
  prizeName,
  onFinish,
  isLocked = false,
}: GashaponProps) {
  const [crankRotated, setCrankRotated] = useState(0);
  const [capsuleDropped, setCapsuleDropped] = useState(false);
  const [isOpening, setIsOpening] = useState(false);
  const [hasFinished, setHasFinished] = useState(false);

  const turnCrank = () => {
    if (capsuleDropped || isOpening || hasFinished || isLocked) return;

    sounds.playShake();
    setCrankRotated((prev) => prev + 360);

    setTimeout(() => {
      sounds.playPop();
      setCapsuleDropped(true);
    }, 600);
  };

  const openCapsule = () => {
    if (!capsuleDropped || isOpening || hasFinished) return;
    setIsOpening(true);
    sounds.playWin();

    confetti({
      particleCount: 85,
      spread: 75,
      origin: { y: 0.6 },
    });

    setTimeout(() => {
      setHasFinished(true);
      setTimeout(() => {
        onFinish();
      }, 1200);
    }, 800);
  };

  return (
    <div className="flex flex-col items-center justify-center p-4">
      {/* Gashapon Machine Housing */}
      <div className="w-[300px] bg-gradient-to-b from-teal-500 to-cyan-700 rounded-3xl p-5 shadow-2xl border-4 border-cyan-300 flex flex-col items-center">
        {/* Machine Title */}
        <div className="bg-yellow-300 text-teal-900 font-black text-xs px-3 py-1 rounded-full uppercase tracking-wider mb-3 shadow">
          ★ GASHAPON DOX ★
        </div>

        {/* Glass Dome with bouncing balls */}
        <div className="w-52 h-44 rounded-t-full rounded-b-2xl bg-cyan-100/30 backdrop-blur-xs border-4 border-white/60 p-3 relative overflow-hidden flex flex-wrap items-end justify-center gap-2 shadow-inner">
          {CAPSULES.map((colorClass, idx) => (
            <div
              key={idx}
              className={`w-9 h-9 rounded-full ${colorClass} shadow-md border border-white transform transition-transform ${
                crankRotated > 0 ? 'animate-bounce' : ''
              }`}
              style={{
                animationDelay: `${idx * 0.1}s`,
              }}
            />
          ))}
        </div>

        {/* Chute & Crank section */}
        <div className="w-full bg-teal-800 rounded-2xl p-4 mt-3 flex items-center justify-between border-2 border-teal-600 shadow-inner">
          {/* Output chute */}
          <div className="w-24 h-20 bg-slate-900 rounded-xl border-2 border-teal-400/50 flex items-center justify-center relative overflow-hidden">
            {capsuleDropped && !hasFinished && (
              <button
                onClick={openCapsule}
                className="w-12 h-12 rounded-full bg-gradient-to-b from-rose-500 to-white border-2 border-white shadow-lg animate-bounce flex items-center justify-center cursor-pointer hover:scale-105 active:scale-95"
                title="Klik untuk membuka kapsul!"
              >
                <span className="text-[10px] font-bold text-rose-800">TAP!</span>
              </button>
            )}
            {!capsuleDropped && (
              <span className="text-[11px] text-gray-500 font-medium text-center px-1">
                Kapsul keluar disini
              </span>
            )}
          </div>

          {/* Rotary Crank */}
          <div className="flex flex-col items-center">
            <button
              onClick={turnCrank}
              disabled={capsuleDropped || isOpening || hasFinished || isLocked}
              className={`w-16 h-16 rounded-full bg-gradient-to-tr from-amber-400 to-yellow-300 border-4 border-white shadow-xl flex items-center justify-center transition-transform duration-700 active:scale-90 ${
                capsuleDropped ? 'opacity-60 cursor-not-allowed' : 'hover:scale-105 cursor-pointer'
              }`}
              style={{
                transform: `rotate(${crankRotated}deg)`,
              }}
            >
              <RotateCw className="w-7 h-7 text-amber-900" />
            </button>
            <span className="text-[10px] text-teal-100 font-bold mt-1 uppercase">
              {capsuleDropped ? 'Terbuka' : 'Putar Kran'}
            </span>
          </div>
        </div>
      </div>

      {capsuleDropped && !hasFinished && (
        <p className="text-sm font-bold text-amber-600 mt-4 animate-pulse">
          👆 Kapsul keluar! Ketuk kapsul di dalam lubang untuk membuka!
        </p>
      )}

      {!capsuleDropped && (
        <p className="text-xs text-gray-500 mt-3">
          Ketuk kran putar kuning untuk mengeluarkan kapsul doorprize
        </p>
      )}
    </div>
  );
}
