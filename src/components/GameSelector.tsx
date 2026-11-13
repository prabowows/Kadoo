'use client';

import React from 'react';
import { GameType } from '@/lib/types';
import { Sparkles, Smartphone, ChevronRight } from 'lucide-react';

interface GameSelectorProps {
  activeGames: GameType[];
  onSelectGame: (game: GameType) => void;
}

interface GameOption {
  id: GameType;
  title: string;
  tagline: string;
  icon: string;
  gradient: string;
  badge?: string;
  isMobileSpecial?: boolean;
}

const ALL_GAMES: GameOption[] = [
  {
    id: 'spinwheel',
    title: 'Lucky Spin Wheel',
    tagline: 'Putar roda keberuntungan dan uji hoki kamu!',
    icon: '🎡',
    gradient: 'from-amber-500 to-orange-600',
    badge: 'Populer',
  },
  {
    id: 'scratch',
    title: 'Scratch Card',
    tagline: 'Gosok kartu emas virtual dan temukan hadiahnya!',
    icon: '🎫',
    gradient: 'from-yellow-500 to-amber-700',
    badge: 'Seru',
  },
  {
    id: 'slot',
    title: 'Arcade Slot Machine',
    tagline: 'Tarik tuas jackpot 3-reel khas kasino arcade!',
    icon: '🎰',
    gradient: 'from-rose-500 to-red-700',
  },
  {
    id: 'gashapon',
    title: 'Gashapon Capsule',
    tagline: 'Putar tuas kran, dapatkan kapsul hadiah kejutan!',
    icon: '⚪',
    gradient: 'from-teal-500 to-cyan-700',
  },
  {
    id: 'shake',
    title: 'Shake The Box (Kocok Kado)',
    tagline: 'Goyangkan HP-mu langsung sampai kado meledak terbuka!',
    icon: '🎁',
    gradient: 'from-purple-500 to-indigo-700',
    badge: 'Sensasi HP',
    isMobileSpecial: true,
  },
];

export default function GameSelector({ activeGames, onSelectGame }: GameSelectorProps) {
  const availableGames = ALL_GAMES.filter((g) => activeGames.includes(g.id));

  return (
    <div className="w-full max-w-md mx-auto space-y-3 p-2">
      <div className="text-center mb-4">
        <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-black bg-amber-100 text-amber-800 border border-amber-300">
          <Sparkles className="w-3.5 h-3.5" />
          DOORPRIZE GAME HUB
        </span>
        <h2 className="text-xl font-extrabold text-gray-900 mt-1">Pilih Game Keberuntunganmu</h2>
        <p className="text-xs text-gray-500">Pilih salah satu game untuk menentukan hadiah yang kamu dapatkan!</p>
      </div>

      <div className="space-y-3">
        {availableGames.map((game) => (
          <button
            key={game.id}
            onClick={() => onSelectGame(game.id)}
            className="w-full p-4 rounded-2xl bg-white border border-gray-200 hover:border-amber-400 hover:shadow-xl transition-all flex items-center justify-between text-left group active:scale-98"
          >
            <div className="flex items-center gap-3.5">
              {/* Icon Bubble */}
              <div
                className={`w-13 h-13 rounded-2xl bg-gradient-to-br ${game.gradient} flex items-center justify-center text-2xl shadow-md text-white shrink-0 group-hover:scale-110 transition-transform`}
              >
                {game.icon}
              </div>

              <div>
                <div className="flex items-center gap-2">
                  <h3 className="font-extrabold text-gray-900 text-sm sm:text-base group-hover:text-amber-600 transition-colors">
                    {game.title}
                  </h3>
                  {game.badge && (
                    <span className="px-2 py-0.5 rounded-full text-[10px] font-black bg-amber-100 text-amber-800 border border-amber-200">
                      {game.badge}
                    </span>
                  )}
                  {game.isMobileSpecial && (
                    <span className="inline-flex items-center gap-0.5 px-1.5 py-0.5 rounded-full text-[9px] font-bold bg-purple-100 text-purple-700">
                      <Smartphone className="w-2.5 h-2.5" /> HP
                    </span>
                  )}
                </div>
                <p className="text-xs text-gray-500 mt-0.5 leading-snug">{game.tagline}</p>
              </div>
            </div>

            <ChevronRight className="w-5 h-5 text-gray-300 group-hover:text-amber-500 group-hover:translate-x-1 transition-all shrink-0 ml-2" />
          </button>
        ))}
      </div>
    </div>
  );
}
