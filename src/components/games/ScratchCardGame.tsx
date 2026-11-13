'use client';

import React, { useRef, useEffect, useState } from 'react';
import { sounds } from '@/lib/audio';
import confetti from 'canvas-confetti';
import { Sparkles } from 'lucide-react';

interface ScratchCardProps {
  prizeName: string;
  onFinish: () => void;
  isLocked?: boolean;
}

export default function ScratchCardGame({
  prizeName,
  onFinish,
  isLocked = false,
}: ScratchCardProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [percentScratched, setPercentScratched] = useState(0);
  const [isRevealed, setIsRevealed] = useState(false);
  const isDrawingRef = useRef(false);
  const lastSoundTimeRef = useRef(0);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Create glamorous gold scratch layer
    const width = canvas.width;
    const height = canvas.height;

    const grad = ctx.createLinearGradient(0, 0, width, height);
    grad.addColorStop(0, '#D4AF37');
    grad.addColorStop(0.3, '#FFDF73');
    grad.addColorStop(0.5, '#AA771C');
    grad.addColorStop(0.8, '#FFDF73');
    grad.addColorStop(1, '#8B6508');

    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, width, height);

    // Add subtle text pattern
    ctx.fillStyle = 'rgba(0, 0, 0, 0.15)';
    ctx.font = 'bold 16px sans-serif';
    ctx.textAlign = 'center';
    for (let y = 30; y < height; y += 40) {
      for (let x = 60; x < width; x += 120) {
        ctx.fillText('★ GOSOK DISINI ★', x, y);
      }
    }

    // Add border
    ctx.strokeStyle = '#FFFFFF';
    ctx.lineWidth = 4;
    ctx.strokeRect(4, 4, width - 8, height - 8);
  }, []);

  const scratch = (clientX: number, clientY: number) => {
    if (isRevealed || isLocked) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const x = clientX - rect.left;
    const y = clientY - rect.top;

    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    ctx.arc(x, y, 22, 0, Math.PI * 2);
    ctx.fill();

    // Throttled sound
    const now = Date.now();
    if (now - lastSoundTimeRef.current > 90) {
      sounds.playScratch();
      lastSoundTimeRef.current = now;
    }

    // Calculate percent scratched periodically
    checkPercent();
  };

  const checkPercent = () => {
    const canvas = canvasRef.current;
    if (!canvas || isRevealed) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Sample every 16th pixel for performance
    const width = canvas.width;
    const height = canvas.height;
    const imgData = ctx.getImageData(0, 0, width, height);
    const data = imgData.data;
    let transparentCount = 0;
    const step = 16;
    const totalSamples = (width * height) / step;

    for (let i = 0; i < data.length; i += 4 * step) {
      if (data[i + 3] < 128) {
        transparentCount++;
      }
    }

    const pct = Math.min(100, Math.round((transparentCount / totalSamples) * 100));
    setPercentScratched(pct);

    if (pct >= 45 && !isRevealed) {
      revealFull();
    }
  };

  const revealFull = () => {
    setIsRevealed(true);
    setPercentScratched(100);
    const canvas = canvasRef.current;
    if (canvas) {
      const ctx = canvas.getContext('2d');
      if (ctx) {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
      }
    }
    sounds.playWin();
    confetti({
      particleCount: 75,
      spread: 70,
      origin: { y: 0.6 },
    });
    setTimeout(() => {
      onFinish();
    }, 1200);
  };

  // Mouse & Touch events
  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    isDrawingRef.current = true;
    scratch(e.clientX, e.clientY);
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDrawingRef.current) return;
    scratch(e.clientX, e.clientY);
  };

  const handleMouseUp = () => {
    isDrawingRef.current = false;
  };

  const handleTouchStart = (e: React.TouchEvent<HTMLCanvasElement>) => {
    isDrawingRef.current = true;
    if (e.touches[0]) {
      scratch(e.touches[0].clientX, e.touches[0].clientY);
    }
  };

  const handleTouchMove = (e: React.TouchEvent<HTMLCanvasElement>) => {
    if (!isDrawingRef.current) return;
    if (e.touches[0]) {
      scratch(e.touches[0].clientX, e.touches[0].clientY);
    }
  };

  const handleTouchEnd = () => {
    isDrawingRef.current = false;
  };

  return (
    <div className="flex flex-col items-center justify-center p-4 select-none">
      <div className="text-center mb-3">
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-100 text-amber-800 border border-amber-300">
          <Sparkles className="w-3.5 h-3.5 text-amber-600" />
          Gosok Layar Emas di Bawah Ini
        </span>
      </div>

      {/* Card Wrapper */}
      <div className="relative w-[320px] h-[200px] rounded-2xl overflow-hidden shadow-2xl border-4 border-amber-400 bg-gradient-to-br from-indigo-900 via-purple-900 to-slate-900 flex items-center justify-center p-4">
        {/* Prize Content Underneath */}
        <div className="flex flex-col items-center text-center px-4">
          <span className="text-3xl mb-1">🎁</span>
          <p className="text-xs font-semibold text-yellow-300 uppercase tracking-widest">
            Selamat Kamu Mendapatkan
          </p>
          <h3 className="text-xl font-extrabold text-white mt-1 drop-shadow-md">
            {prizeName}
          </h3>
        </div>

        {/* Scratchable Canvas Layer on Top */}
        <canvas
          ref={canvasRef}
          width={320}
          height={200}
          onMouseDown={handleMouseDown}
          onMouseMove={handleMouseMove}
          onMouseUp={handleMouseUp}
          onMouseLeave={handleMouseUp}
          onTouchStart={handleTouchStart}
          onTouchMove={handleTouchMove}
          onTouchEnd={handleTouchEnd}
          className={`absolute inset-0 cursor-pointer touch-none transition-opacity duration-700 ${
            isRevealed ? 'opacity-0 pointer-events-none' : 'opacity-100'
          }`}
        />
      </div>

      {/* Progress */}
      <div className="w-[320px] mt-4 flex items-center justify-between text-xs text-gray-500 font-medium">
        <span>Tergosok: {percentScratched}%</span>
        {percentScratched > 20 && !isRevealed && (
          <button
            onClick={revealFull}
            className="text-amber-600 font-bold underline hover:text-amber-700"
          >
            Buka Langsung
          </button>
        )}
      </div>
      <p className="text-xs text-gray-400 mt-1">Usapkan jari atau mouse ke atas kartu emas</p>
    </div>
  );
}
