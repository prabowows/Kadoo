'use client';

import React, { useState, useEffect, use } from 'react';
import { Room, GameType, ParticipantLead } from '@/lib/types';
import RegistrationForm from '@/components/RegistrationForm';
import GameSelector from '@/components/GameSelector';
import SpinWheelGame from '@/components/games/SpinWheelGame';
import ScratchCardGame from '@/components/games/ScratchCardGame';
import SlotMachineGame from '@/components/games/SlotMachineGame';
import GashaponGame from '@/components/games/GashaponGame';
import ShakeBoxGame from '@/components/games/ShakeBoxGame';
import ClaimTicket from '@/components/ClaimTicket';
import { Sparkles, Trophy, ArrowLeft, AlertTriangle } from 'lucide-react';
import Link from 'next/link';

type Step = 'form' | 'select_game' | 'playing' | 'ticket';

export default function RoomPage({ params }: { params: Promise<{ code: string }> }) {
  const { code } = use(params);
  const [room, setRoom] = useState<Room | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Form State
  const [formData, setFormData] = useState<any | null>(null);
  const [selectedGame, setSelectedGame] = useState<GameType>('spinwheel');
  const [step, setStep] = useState<Step>('form');

  // Outcome
  const [leadResult, setLeadResult] = useState<ParticipantLead | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  // Fetch Room data
  useEffect(() => {
    async function fetchRoom() {
      try {
        setLoading(true);
        const res = await fetch(`/api/rooms/${code}`);
        const data = await res.json();
        if (!data.success) {
          setError(data.error || 'Room tidak ditemukan');
        } else {
          setRoom(data.room);
        }
      } catch (err) {
        setError('Gagal memuat data room');
      } finally {
        setLoading(false);
      }
    }
    fetchRoom();
  }, [code]);

  // Handle Form Submit -> Go to Game Select
  const handleFormSubmit = async (data: any) => {
    setIsSubmitting(true);
    setError(null);

    // Pre-check if WA already played
    try {
      const checkRes = await fetch(`/api/rooms/${code}/check-wa`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ waNumber: data.waNumber }),
      });
      const checkData = await checkRes.json();
      if (checkData.alreadyPlayed && checkData.participant) {
        setLeadResult(checkData.participant);
        setStep('ticket');
        setIsSubmitting(false);
        return;
      }
    } catch {
      // Continue if network fails
    }

    setFormData(data);
    setStep('select_game');
    setIsSubmitting(false);
  };

  // User chooses a game
  const handleSelectGame = async (game: GameType) => {
    setSelectedGame(game);
    setIsSubmitting(true);
    setError(null);

    try {
      // Submit registration and lock in the prize at backend
      const res = await fetch(`/api/rooms/${code}/play`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          gamePlayed: game,
        }),
      });

      const json = await res.json();
      if (!json.success) {
        if (json.alreadyPlayed && json.lead) {
          setLeadResult(json.lead);
          setStep('ticket');
          return;
        }
        setError(json.error || 'Terjadi kesalahan saat memproses hadiah');
        return;
      }

      setLeadResult(json.lead);
      setStep('playing');
    } catch {
      setError('Koneksi internet bermasalah');
    } finally {
      setIsSubmitting(false);
    }
  };

  // When game completes animation
  const handleGameFinish = () => {
    setStep('ticket');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-amber-500 border-t-transparent rounded-full animate-spin mx-auto mb-3" />
          <p className="text-sm font-semibold text-gray-600">Memuat Room Doorprize...</p>
        </div>
      </div>
    );
  }

  if (error && !room) {
    return (
      <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4">
        <div className="bg-white p-6 rounded-3xl shadow-xl max-w-sm text-center border border-red-200">
          <AlertTriangle className="w-12 h-12 text-red-500 mx-auto mb-3" />
          <h2 className="text-lg font-black text-gray-900 mb-1">Room Tidak Ditemukan</h2>
          <p className="text-xs text-gray-500 mb-5">{error}</p>
          <Link
            href="/"
            className="inline-block py-2.5 px-6 rounded-xl bg-amber-500 text-white font-bold text-xs shadow hover:bg-amber-600"
          >
            Kembali ke Beranda
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-b from-amber-500/10 via-slate-50 to-orange-500/10 py-6 px-4">
      {/* Top Banner */}
      <div className="max-w-md mx-auto mb-6 text-center">
        <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-black bg-gradient-to-r from-amber-500 to-orange-500 text-white shadow-sm mb-2">
          <Trophy className="w-3.5 h-3.5" />
          DOORPRIZE BOOTH KAMPUS
        </div>
        <h1 className="text-2xl font-black text-gray-900 tracking-tight leading-tight">
          {room?.name}
        </h1>
        {room?.description && (
          <p className="text-xs text-gray-600 mt-1 max-w-xs mx-auto">{room.description}</p>
        )}
      </div>

      {/* Main Card Container */}
      <div className="max-w-md mx-auto bg-white/95 backdrop-blur-md rounded-3xl shadow-xl border border-amber-200/80 p-5 sm:p-7 relative overflow-hidden">
        {step === 'form' && (
          <div>
            <div className="text-center mb-5">
              <h2 className="text-lg font-extrabold text-gray-900">Form Registrasi Siswa</h2>
              <p className="text-xs text-gray-500 mt-0.5">
                Isi data diri kamu untuk langsung bermain game doorprize!
              </p>
            </div>
            <RegistrationForm
              onSubmit={handleFormSubmit}
              isLoading={isSubmitting}
              errorMessage={error}
            />
          </div>
        )}

        {step === 'select_game' && (
          <div>
            <button
              onClick={() => setStep('form')}
              className="text-xs text-gray-500 hover:text-gray-800 flex items-center gap-1 mb-3 font-semibold"
            >
              <ArrowLeft className="w-3.5 h-3.5" /> Edit Data Diri
            </button>
            <GameSelector
              activeGames={room?.activeGames || ['spinwheel']}
              onSelectGame={handleSelectGame}
            />
          </div>
        )}

        {step === 'playing' && leadResult && (
          <div className="flex flex-col items-center">
            <h2 className="text-lg font-black text-gray-900 mb-1 text-center">
              Ayo Mainkan Game Keberuntunganmu!
            </h2>
            <p className="text-xs text-gray-500 mb-4 text-center">
              Halo, <span className="font-bold text-amber-600">{leadResult.fullName}</span>!
            </p>

            {selectedGame === 'spinwheel' && (
              <SpinWheelGame
                prizes={room?.prizes || []}
                targetPrizeName={leadResult.prizeWon}
                onFinish={handleGameFinish}
              />
            )}

            {selectedGame === 'scratch' && (
              <ScratchCardGame
                prizeName={leadResult.prizeWon}
                onFinish={handleGameFinish}
              />
            )}

            {selectedGame === 'slot' && (
              <SlotMachineGame
                prizeName={leadResult.prizeWon}
                allPrizes={room?.prizes || []}
                onFinish={handleGameFinish}
              />
            )}

            {selectedGame === 'gashapon' && (
              <GashaponGame
                prizeName={leadResult.prizeWon}
                onFinish={handleGameFinish}
              />
            )}

            {selectedGame === 'shake' && (
              <ShakeBoxGame
                prizeName={leadResult.prizeWon}
                onFinish={handleGameFinish}
              />
            )}
          </div>
        )}

        {step === 'ticket' && leadResult && (
          <div>
            <ClaimTicket
              lead={leadResult}
              roomName={room?.name || 'Doorprize'}
              roomCode={room?.code || ''}
            />
          </div>
        )}
      </div>

      {/* Footer Branding */}
      <footer className="text-center mt-8 text-xs text-gray-400">
        <p>ShakingPrize — Sistem Gamifikasi & Rekap Leads Marketing</p>
      </footer>
    </div>
  );
}
