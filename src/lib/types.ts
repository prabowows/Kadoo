export interface PrizeItem {
  id: string;
  name: string;
  initialStock: number;
  currentStock: number;
  color: string;
  icon?: string;
  weight?: number; // probability weight
}

export type GameType = 'spinwheel' | 'scratch' | 'slot' | 'gashapon' | 'shake';

export interface Room {
  id: string;
  adminId?: string;
  code: string;
  name: string;
  description?: string;
  pin: string;
  status: 'active' | 'closed';
  prizes: PrizeItem[];
  activeGames: GameType[];
  createdAt: string;
}

export interface ParticipantLead {
  id: string;
  roomId: string;
  fullName: string;
  waNumber: string;
  waParentNumber: string;
  email: string;
  grade: string;
  schoolName: string;
  schoolCity: string;
  studyInterest: string;
  gamePlayed: GameType;
  prizeWon: string;
  prizeId: string;
  claimCode: string;
  isClaimed: boolean;
  claimedAt: string | null;
  createdAt: string;
}

export interface RegisterAndPlayRequest {
  roomId: string;
  fullName: string;
  waNumber: string;
  waParentNumber: string;
  email: string;
  grade: string;
  schoolName: string;
  schoolCity: string;
  studyInterest: string;
  gamePlayed: GameType;
}
