'use client';

import React, { useState, useEffect } from 'react';
import { sounds } from '@/lib/audio';
import confetti from 'canvas-confetti';
import { Dna, Gift, Sparkles, Trophy, Zap, Star, Heart } from 'lucide-react';

interface SlotMachineProps {
  prizeName: string;
  allPrizes: { id: string; name: string }[];
  onFinish: () => void;
  isLocked?: boolean;
}

const ICONS = ['🎁', '⭐', '💎', '🏆', '🎉', '🔥', '👑'];

export default function SlotMachineGame({
  prizeName,
  allPrizes,
  onFinish,
  isLocked = false,
}: SlotMachineProps) {
  const [reels, setReels] = useState<string[]>(['🎁', '🎁', '🎁']);
  const [isSpinning, setIsSpinning] = useState(false);
  const [hasFinished, setHasFinished] = useState(false);

  const spin = () => {
    if (isSpinning || hasFinished || isLocked) return;
    setIsSpinning(true);

    const spinDuration = 3500;
    const intervalTime = 80;
    let ticks = 0;

    const interval = setInterval(() => {
      ticks++;
      // Randomize icons during spin
      setReels([
        ICONS[Math.floor(Math.random() * ICONS.length)],
        ICONS[Math.floor(Math.random() * ICONS.length)],
        ICONS[Math.floor(Math.random() * ICONS.length)],
      ]);
      if (ticks % 2 === 0) {
        sounds.playTick();
      }
    }, intervalTime);

    // Stop reels sequentially
    setTimeout(() => {
      clearInterval(interval);
      // All 3 reels hit jackpot match!
      setReels(['🎁', '🎁', '🎁']);
      setIsSpinning(false);
      setHasFinished(true);

      sounds.playWin();
      confetti({
        particleCount: 90,
        spread: 80,
        origin: { y: 0.6 },
      });

      setTimeout(() => {
        onFinish();
      }, 1500);
    }, spinDuration);
  };

  return (
    <div className="flex flex-col items-center justify-center p-4">
      {/* Slot Machine Casing */}
      <div className="relative bg-gradient-to-b from-red-600 via-rose-700 to-red-900 p-6 rounded-3xl shadow-2xl border-4 border-yellow-400 w-[330px]">
        {/* Machine Header */}
        <div className="text-center mb-4">
          <div className="inline-block bg-yellow-400 text-red-900 font-black text-sm uppercase px-4 py-1 rounded-full shadow tracking-wider">
            ★ JACKPOT SPINNER ★
          </div>
        </div>

        {/* 3 Reels Display Window */}
        <div className="flex items-center justify-between gap-3 bg-slate-900 p-4 rounded-2xl border-4 border-amber-300 shadow-inner">
          {reels.map((icon, idx) => (
            <div
              key={idx}
              className={`flex-1 h-24 bg-gradient-to-b from-gray-100 to-white rounded-xl flex items-center justify-center text-4xl shadow-md border-2 border-gray-300 transition-all ${
                isSpinning ? 'animate-pulse scale-95 blur-[0.5px]' : 'scale-100'
              }`}
            >
              {icon}
            </div>
          ))}
        </div>

        {/* Flashing lights */}
        <div className="flex justify-center gap-3 mt-4">
          {[1, 2, 3, 4, 5].map((i) => (
            <div
              key={i}
              className={`w-3.5 h-3.5 rounded-full ${
                isSpinning
                  ? i % 2 === 0
                    ? 'bg-yellow-300 animate-ping'
                    : 'bg-green-400 animate-pulse'
                  : 'bg-yellow-400 shadow-[0_0_8px_#facc15]'
              }`}
            />
          ))}
        </div>

        {/* Lever & Button */}
        <div className="mt-6 flex flex-col items-center">
          <button
            onClick={spin}
            disabled={isSpinning || hasFinished || isLocked}
            className={`w-full py-4 rounded-2xl font-black text-lg tracking-wider uppercase transition-all shadow-xl active:scale-95 ${
              isSpinning || hasFinished
                ? 'bg-gray-500 text-gray-300 cursor-not-allowed'
                : 'bg-gradient-to-r from-yellow-400 via-amber-400 to-orange-500 text-red-950 hover:brightness-110 animate-bounce'
            }`}
          >
            {isSpinning ? 'SPINNING...' : hasFinished ? 'JACKPOT!' : '🎰 TARIK TUAS / SPIN!'}
          </button>
        </div>
      </div>

      <p className="text-xs text-gray-500 mt-3">Tekan tombol untuk memutar 3 slot hadiah</p>
    </div>
  );
}
