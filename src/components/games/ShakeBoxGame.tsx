'use client';

import React, { useState, useEffect, useRef } from 'react';
import { sounds } from '@/lib/audio';
import confetti from 'canvas-confetti';
import { Smartphone, MousePointerClick, Sparkles } from 'lucide-react';

interface ShakeBoxProps {
  prizeName: string;
  onFinish: () => void;
  isLocked?: boolean;
}

export default function ShakeBoxGame({
  prizeName,
  onFinish,
  isLocked = false,
}: ShakeBoxProps) {
  const [shakeCount, setShakeCount] = useState(0);
  const targetShakes = 12; // 12 shakes or rapid clicks
  const [isMobile, setIsMobile] = useState(false);
  const [permissionGranted, setPermissionGranted] = useState(false);
  const [hasFinished, setHasFinished] = useState(false);
  const lastShakeTimeRef = useRef(0);
  const lastAccRef = useRef({ x: 0, y: 0, z: 0 });

  // Detect mobile user agent
  useEffect(() => {
    const ua = navigator.userAgent || '';
    const mobile = /Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(ua);
    setIsMobile(mobile);
  }, []);

  // Request motion permission (iOS 13+)
  const requestMotionPermission = async () => {
    if (
      typeof window !== 'undefined' &&
      typeof (DeviceMotionEvent as unknown as { requestPermission?: () => Promise<string> }).requestPermission === 'function'
    ) {
      try {
        const response = await (DeviceMotionEvent as unknown as { requestPermission: () => Promise<string> }).requestPermission();
        if (response === 'granted') {
          setPermissionGranted(true);
        } else {
          alert('Izin sensor gerak tidak diberikan. Kamu masih bisa mengocok dengan tap/klik cepat!');
        }
      } catch (err) {
        console.error(err);
      }
    } else {
      setPermissionGranted(true);
    }
  };

  // Device motion listener
  useEffect(() => {
    if (!isMobile) return;

    const handleMotion = (event: DeviceMotionEvent) => {
      if (hasFinished || isLocked) return;
      const acc = event.accelerationIncludingGravity;
      if (!acc || acc.x === null || acc.y === null || acc.z === null) return;

      const deltaX = Math.abs(acc.x - lastAccRef.current.x);
      const deltaY = Math.abs(acc.y - lastAccRef.current.y);
      const deltaZ = Math.abs(acc.z - lastAccRef.current.z);

      lastAccRef.current = { x: acc.x, y: acc.y, z: acc.z };

      const totalDelta = deltaX + deltaY + deltaZ;
      const now = Date.now();

      if (totalDelta > 18 && now - lastShakeTimeRef.current > 200) {
        lastShakeTimeRef.current = now;
        sounds.playShake();

        setShakeCount((prev) => {
          const next = prev + 1;
          if (next >= targetShakes) {
            triggerWin();
          }
          return next;
        });
      }
    };

    window.addEventListener('devicemotion', handleMotion);
    return () => {
      window.removeEventListener('devicemotion', handleMotion);
    };
  }, [isMobile, hasFinished, isLocked]);

  const handleManualShake = () => {
    if (hasFinished || isLocked) return;
    sounds.playShake();
    setShakeCount((prev) => {
      const next = prev + 1;
      if (next >= targetShakes) {
        triggerWin();
      }
      return next;
    });
  };

  const triggerWin = () => {
    setHasFinished(true);
    sounds.playWin();

    confetti({
      particleCount: 100,
      spread: 90,
      origin: { y: 0.6 },
    });

    setTimeout(() => {
      onFinish();
    }, 1400);
  };

  const progressPct = Math.min(100, Math.round((shakeCount / targetShakes) * 100));

  return (
    <div className="flex flex-col items-center justify-center p-4">
      {/* Device Mode Badge */}
      <div className="mb-3">
        {isMobile ? (
          <div className="flex flex-col items-center gap-1.5">
            <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-100 text-emerald-800 border border-emerald-300">
              <Smartphone className="w-3.5 h-3.5 text-emerald-600" />
              Sensor Gerak Smartphone Aktif
            </span>
            {!permissionGranted && typeof window !== 'undefined' && typeof (DeviceMotionEvent as unknown as { requestPermission?: unknown }).requestPermission === 'function' && (
              <button
                onClick={requestMotionPermission}
                className="text-xs bg-emerald-600 text-white px-3 py-1 rounded-lg font-bold"
              >
                Aktifkan Sensor Goyang (iOS)
              </button>
            )}
          </div>
        ) : (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-800 border border-blue-300">
            <MousePointerClick className="w-3.5 h-3.5 text-blue-600" />
            Mode Desktop: Kocok dengan Klik Cepat!
          </span>
        )}
      </div>

      {/* 3D Gift Box Animation */}
      <div
        onClick={handleManualShake}
        className={`relative w-48 h-48 my-4 flex items-center justify-center cursor-pointer select-none transition-transform duration-150 ${
          hasFinished
            ? 'scale-110'
            : shakeCount > 0
            ? 'animate-[wiggle_0.2s_ease-in-out_infinite]'
            : 'hover:scale-105 active:scale-95'
        }`}
      >
        {/* Glow */}
        <div className="absolute inset-0 bg-amber-400/20 blur-xl rounded-full" />

        {/* Gift Box Graphic */}
        <div className="relative text-8xl drop-shadow-2xl">
          {hasFinished ? '🎉' : '🎁'}
        </div>
      </div>

      {/* Shake Progress Bar */}
      <div className="w-[280px] bg-gray-200 rounded-full h-4 overflow-hidden shadow-inner border border-gray-300 mt-2">
        <div
          className="bg-gradient-to-r from-amber-500 to-rose-500 h-full transition-all duration-200"
          style={{ width: `${progressPct}%` }}
        />
      </div>
      <p className="text-xs font-bold text-gray-600 mt-2">
        {progressPct}% Terbuka ({shakeCount}/{targetShakes} Kocokan)
      </p>

      {/* Button fallback / prompt */}
      <button
        onClick={handleManualShake}
        disabled={hasFinished || isLocked}
        className={`mt-4 px-6 py-3 rounded-xl font-bold text-sm tracking-wide transition-all shadow-md active:scale-95 ${
          hasFinished
            ? 'bg-gray-400 text-white cursor-not-allowed'
            : 'bg-gradient-to-r from-amber-500 to-rose-500 text-white hover:brightness-105'
        }`}
      >
        {hasFinished
          ? 'Kado Berhasil Terbuka!'
          : isMobile
          ? '📱 Goyangkan HP atau Tap Disini!'
          : '🖱️ Klik Cepat untuk Mengocok Kado!'}
      </button>

      <p className="text-[11px] text-gray-400 mt-2 text-center max-w-xs">
        {isMobile
          ? 'Goyangkan smartphone kamu sampai bar penuh untuk membuka hadiah'
          : 'Klik tombol di atas berkali-kali dengan cepat sampai kado meledak terbuka'}
      </p>
    </div>
  );
}
