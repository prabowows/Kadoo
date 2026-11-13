'use client';

import React, { useRef, useEffect, useState } from 'react';
import { PrizeItem } from '@/lib/types';
import { sounds } from '@/lib/audio';
import confetti from 'canvas-confetti';

interface SpinWheelProps {
  prizes: { id: string; name: string; color: string }[];
  targetPrizeName: string;
  onFinish: () => void;
  isLocked?: boolean;
}

export default function SpinWheelGame({
  prizes,
  targetPrizeName,
  onFinish,
  isLocked = false,
}: SpinWheelProps) {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [isSpinning, setIsSpinning] = useState(false);
  const [hasFinished, setHasFinished] = useState(false);

  // If prizes is empty, fallback
  const validPrizes = prizes.length > 0 ? prizes : [
    { id: '1', name: 'Hadiah 1', color: '#EF4444' },
    { id: '2', name: 'Hadiah 2', color: '#3B82F6' },
    { id: '3', name: 'Hadiah 3', color: '#10B981' },
    { id: '4', name: 'Hadiah 4', color: '#F59E0B' },
  ];

  const totalSegments = validPrizes.length;
  const arcSize = (2 * Math.PI) / totalSegments;
  const currentAngleRef = useRef(0);

  // Draw wheel on canvas
  const drawWheel = (angle: number) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const size = canvas.width;
    const center = size / 2;
    const radius = center - 12;

    ctx.clearRect(0, 0, size, size);

    // Save and rotate
    ctx.save();
    ctx.translate(center, center);
    ctx.rotate(angle);

    for (let i = 0; i < totalSegments; i++) {
      const startAngle = i * arcSize;
      const endAngle = startAngle + arcSize;
      const prize = validPrizes[i];

      // Draw segment slice
      ctx.beginPath();
      ctx.moveTo(0, 0);
      ctx.arc(0, 0, radius, startAngle, endAngle);
      ctx.closePath();
      ctx.fillStyle = prize.color || `hsl(${(i * 360) / totalSegments}, 75%, 55%)`;
      ctx.fill();

      // Border line
      ctx.strokeStyle = '#ffffff';
      ctx.lineWidth = 3;
      ctx.stroke();

      // Draw text
      ctx.save();
      ctx.rotate(startAngle + arcSize / 2);
      ctx.textAlign = 'right';
      ctx.fillStyle = '#ffffff';
      ctx.font = 'bold 13px system-ui, sans-serif';
      ctx.shadowColor = 'rgba(0,0,0,0.5)';
      ctx.shadowBlur = 4;

      // Truncate long text
      const maxLen = 16;
      const text = prize.name.length > maxLen ? prize.name.substring(0, maxLen) + '...' : prize.name;
      ctx.fillText(text, radius - 20, 5);
      ctx.restore();
    }

    ctx.restore();

    // Center pin circle
    ctx.beginPath();
    ctx.arc(center, center, 24, 0, 2 * Math.PI);
    ctx.fillStyle = '#1E293B';
    ctx.fill();
    ctx.lineWidth = 4;
    ctx.strokeStyle = '#FACC15';
    ctx.stroke();

    ctx.beginPath();
    ctx.arc(center, center, 8, 0, 2 * Math.PI);
    ctx.fillStyle = '#FACC15';
    ctx.fill();
  };

  useEffect(() => {
    drawWheel(currentAngleRef.current);
  }, [prizes]);

  const spin = () => {
    if (isSpinning || hasFinished || isLocked) return;
    setIsSpinning(true);

    // Find target prize index
    let targetIndex = validPrizes.findIndex((p) => p.name === targetPrizeName);
    if (targetIndex === -1) targetIndex = 0;

    // Pointer is at the top (angle -Math.PI / 2 or 270 deg)
    // We want the target segment to align with 270 deg (top pointer)
    const targetCenterAngle = targetIndex * arcSize + arcSize / 2;
    const pointerAngle = (3 * Math.PI) / 2; // top pointer

    // We calculate extra full rotations (e.g. 5 to 7 full circles)
    const extraRotations = 6 * 2 * Math.PI;
    const finalAngle = extraRotations + (pointerAngle - targetCenterAngle);

    const startTime = performance.now();
    const duration = 5000; // 5 seconds
    const startAngle = currentAngleRef.current % (2 * Math.PI);
    const totalRotationNeeded = finalAngle - startAngle;

    let lastTickAngle = startAngle;

    const animate = (currentTime: number) => {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);

      // Ease out cubic
      const easeOut = 1 - Math.pow(1 - progress, 3);
      const current = startAngle + totalRotationNeeded * easeOut;
      currentAngleRef.current = current;

      // Play tick sound when crossing segment boundaries
      if (Math.abs(current - lastTickAngle) >= arcSize * 0.8) {
        sounds.playTick();
        lastTickAngle = current;
      }

      drawWheel(current);

      if (progress < 1) {
        requestAnimationFrame(animate);
      } else {
        setIsSpinning(false);
        setHasFinished(true);
        sounds.playWin();
        confetti({
          particleCount: 80,
          spread: 70,
          origin: { y: 0.6 },
        });
        setTimeout(() => {
          onFinish();
        }, 1200);
      }
    };

    requestAnimationFrame(animate);
  };

  return (
    <div className="flex flex-col items-center justify-center p-4">
      {/* Wheel Container */}
      <div className="relative mb-6">
        {/* Pointer Triangle at Top */}
        <div className="absolute -top-3 left-1/2 -translate-x-1/2 z-20 w-0 h-0 border-l-[14px] border-l-transparent border-r-[14px] border-r-transparent border-t-[28px] border-t-yellow-400 drop-shadow-md" />

        {/* Canvas Wheel */}
        <div className="p-2 rounded-full bg-gradient-to-tr from-amber-400 via-yellow-300 to-amber-500 shadow-2xl">
          <canvas
            ref={canvasRef}
            width={340}
            height={340}
            className="rounded-full shadow-inner bg-slate-900 max-w-[85vw] max-h-[85vw]"
          />
        </div>
      </div>

      {/* Action Button */}
      <button
        onClick={spin}
        disabled={isSpinning || hasFinished || isLocked}
        className={`px-8 py-4 rounded-2xl font-black text-lg tracking-wider uppercase transition-all shadow-lg active:scale-95 ${
          isSpinning || hasFinished
            ? 'bg-gray-400 text-gray-200 cursor-not-allowed'
            : 'bg-gradient-to-r from-amber-500 via-orange-500 to-red-500 text-white hover:brightness-110 animate-bounce'
        }`}
      >
        {isSpinning ? 'Sedang Memutar...' : hasFinished ? 'Selesai!' : '🎡 PUTAR RODA SEKARANG!'}
      </button>
      <p className="text-xs text-gray-500 mt-2">Ketuk tombol untuk memutar roda keberuntunganmu</p>
    </div>
  );
}
