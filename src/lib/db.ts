import fs from 'fs';
import path from 'path';
import { Room, ParticipantLead, PrizeItem } from './types';

const DATA_DIR = path.join(process.cwd(), 'data');
const DB_FILE = path.join(DATA_DIR, 'db.json');

interface DatabaseSchema {
  rooms: Room[];
  participants: ParticipantLead[];
}

const DEFAULT_PRIZES: PrizeItem[] = [
  { id: 'p1', name: 'Smartwatch Keren', initialStock: 2, currentStock: 2, color: '#EF4444', weight: 5 },
  { id: 'p2', name: 'Tumbler Stainless Exclusive', initialStock: 15, currentStock: 15, color: '#3B82F6', weight: 20 },
  { id: 'p3', name: 'Kaos Kampus Trendy', initialStock: 20, currentStock: 20, color: '#10B981', weight: 25 },
  { id: 'p4', name: 'Totebag Kanvas', initialStock: 30, currentStock: 30, color: '#F59E0B', weight: 30 },
  { id: 'p5', name: 'Sticker Pack & Pulpen Gel', initialStock: 50, currentStock: 50, color: '#8B5CF6', weight: 40 },
  { id: 'p6', name: 'Gantungan Kunci & Pin', initialStock: 100, currentStock: 100, color: '#EC4899', weight: 50 },
];

const DEFAULT_DEMO_ROOM: Room = {
  id: 'room-demo',
  code: 'DEMO2026',
  name: 'Education Expo 2026 - Booth Kampus',
  description: 'Doorprize spesial kunjungan booth pameran pendidikan',
  pin: '1234',
  status: 'active',
  prizes: DEFAULT_PRIZES,
  activeGames: ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'],
  createdAt: new Date().toISOString(),
};

function ensureDataFile(): DatabaseSchema {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }

  if (!fs.existsSync(DB_FILE)) {
    const initialData: DatabaseSchema = {
      rooms: [DEFAULT_DEMO_ROOM],
      participants: [],
    };
    fs.writeFileSync(DB_FILE, JSON.stringify(initialData, null, 2), 'utf-8');
    return initialData;
  }

  try {
    const raw = fs.readFileSync(DB_FILE, 'utf-8');
    return JSON.parse(raw) as DatabaseSchema;
  } catch {
    const initialData: DatabaseSchema = {
      rooms: [DEFAULT_DEMO_ROOM],
      participants: [],
    };
    fs.writeFileSync(DB_FILE, JSON.stringify(initialData, null, 2), 'utf-8');
    return initialData;
  }
}

function saveData(data: DatabaseSchema): void {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }
  fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
}

// Room Operations
export function getAllRooms(adminId?: string | null): Room[] {
  const db = ensureDataFile();
  if (!adminId || adminId.trim() === '') {
    return db.rooms;
  }
  const cleanAdminId = adminId.trim().toLowerCase();
  return db.rooms.filter((r) => {
    const ownerId = (r.adminId || 'admin').toLowerCase();
    return ownerId === cleanAdminId;
  });
}

export function getRoomByCode(code: string): Room | null {
  const db = ensureDataFile();
  const normalized = code.trim().toUpperCase();
  return db.rooms.find((r) => r.code.toUpperCase() === normalized) || null;
}

export function getRoomById(id: string): Room | null {
  const db = ensureDataFile();
  return db.rooms.find((r) => r.id === id) || null;
}

export function createRoom(data: Omit<Room, 'id' | 'createdAt'>): Room {
  const db = ensureDataFile();
  const id = `room-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`;
  const newRoom: Room = {
    ...data,
    id,
    code: data.code.trim().toUpperCase(),
    createdAt: new Date().toISOString(),
  };
  db.rooms.push(newRoom);
  saveData(db);
  return newRoom;
}

export function updateRoom(id: string, updates: Partial<Room>): Room | null {
  const db = ensureDataFile();
  const index = db.rooms.findIndex((r) => r.id === id);
  if (index === -1) return null;

  db.rooms[index] = {
    ...db.rooms[index],
    ...updates,
    code: updates.code ? updates.code.trim().toUpperCase() : db.rooms[index].code,
  };
  saveData(db);
  return db.rooms[index];
}

export function deleteRoom(id: string): boolean {
  const db = ensureDataFile();
  const initialLength = db.rooms.length;
  db.rooms = db.rooms.filter((r) => r.id !== id);
  if (db.rooms.length !== initialLength) {
    db.participants = db.participants.filter((p) => p.roomId !== id);
    saveData(db);
    return true;
  }
  return false;
}

// Participant & Prize Operations
export function getParticipantsByRoom(roomId: string): ParticipantLead[] {
  const db = ensureDataFile();
  return db.participants.filter((p) => p.roomId === roomId);
}

export function findParticipantByWa(roomId: string, waNumber: string): ParticipantLead | null {
  const db = ensureDataFile();
  const cleanWa = waNumber.replace(/[^0-9]/g, '');
  return (
    db.participants.find(
      (p) => p.roomId === roomId && p.waNumber.replace(/[^0-9]/g, '') === cleanWa
    ) || null
  );
}

// Select a prize based on remaining stock & weights
export function drawPrizeForRoom(room: Room): PrizeItem | null {
  const availablePrizes = room.prizes.filter((p) => p.currentStock > 0);
  if (availablePrizes.length === 0) return null;

  // Weighted random
  const totalWeight = availablePrizes.reduce((sum, p) => sum + (p.weight || 10), 0);
  let randomVal = Math.random() * totalWeight;

  for (const prize of availablePrizes) {
    const weight = prize.weight || 10;
    if (randomVal <= weight) {
      return prize;
    }
    randomVal -= weight;
  }

  return availablePrizes[availablePrizes.length - 1];
}

export function registerAndSpin(
  roomId: string,
  participantData: {
    fullName: string;
    waNumber: string;
    waParentNumber: string;
    email: string;
    grade: string;
    schoolName: string;
    schoolCity: string;
    studyInterest: string;
    gamePlayed: ParticipantLead['gamePlayed'];
  }
): { success: boolean; lead?: ParticipantLead; error?: string; alreadyPlayed?: boolean } {
  const db = ensureDataFile();
  const roomIndex = db.rooms.findIndex((r) => r.id === roomId);
  if (roomIndex === -1) {
    return { success: false, error: 'Room tidak ditemukan' };
  }

  const room = db.rooms[roomIndex];
  if (room.status !== 'active') {
    return { success: false, error: 'Room ini saat ini sedang tidak aktif / ditutup.' };
  }

  // Check duplicate WA in this room
  const cleanWa = participantData.waNumber.replace(/[^0-9]/g, '');
  const existing = db.participants.find(
    (p) => p.roomId === roomId && p.waNumber.replace(/[^0-9]/g, '') === cleanWa
  );
  if (existing) {
    return {
      success: false,
      alreadyPlayed: true,
      lead: existing,
      error: 'Nomor WhatsApp ini sudah pernah mengikuti doorprize di room ini.',
    };
  }

  // Draw prize
  const prize = drawPrizeForRoom(room);
  if (!prize) {
    return {
      success: false,
      error: 'Mohon maaf, stok semua hadiah pada room ini sudah habis!',
    };
  }

  // Decrement prize stock in room
  const prizeIndex = room.prizes.findIndex((p) => p.id === prize.id);
  if (prizeIndex !== -1) {
    room.prizes[prizeIndex].currentStock = Math.max(0, room.prizes[prizeIndex].currentStock - 1);
  }

  // Generate 6-char claim code
  const claimCode = `SP-${Math.floor(1000 + Math.random() * 9000)}`;

  const newLead: ParticipantLead = {
    id: `lead-${Date.now()}-${Math.random().toString(36).substring(2, 7)}`,
    roomId,
    ...participantData,
    prizeWon: prize.name,
    prizeId: prize.id,
    claimCode,
    isClaimed: false,
    claimedAt: null,
    createdAt: new Date().toISOString(),
  };

  db.participants.push(newLead);
  db.rooms[roomIndex] = room;
  saveData(db);

  return { success: true, lead: newLead };
}

export function toggleClaimStatus(leadId: string): ParticipantLead | null {
  const db = ensureDataFile();
  const index = db.participants.findIndex((p) => p.id === leadId);
  if (index === -1) return null;

  const current = db.participants[index];
  const isClaimed = !current.isClaimed;
  db.participants[index] = {
    ...current,
    isClaimed,
    claimedAt: isClaimed ? new Date().toISOString() : null,
  };
  saveData(db);
  return db.participants[index];
}
