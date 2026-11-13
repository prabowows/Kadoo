import { NextRequest, NextResponse } from 'next/server';
import { getAllRooms, createRoom, getRoomByCode } from '@/lib/db';

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const adminId = searchParams.get('adminId');
    const rooms = getAllRooms(adminId);
    // Return sanitized rooms
    const safeRooms = rooms.map((r) => ({
      id: r.id,
      adminId: r.adminId || 'admin',
      code: r.code,
      name: r.name,
      description: r.description,
      status: r.status,
      activeGames: r.activeGames,
      prizesCount: r.prizes.length,
      totalStock: r.prizes.reduce((sum, p) => sum + p.currentStock, 0),
      createdAt: r.createdAt,
    }));
    return NextResponse.json({ success: true, rooms: safeRooms });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { name, code, pin, prizes, activeGames, description, adminId } = body;

    if (!name || !code || !pin) {
      return NextResponse.json(
        { success: false, error: 'Nama Room, Kode Room, dan PIN wajib diisi' },
        { status: 400 }
      );
    }

    // Check if code already exists
    const existing = getRoomByCode(code);
    if (existing) {
      return NextResponse.json(
        { success: false, error: `Kode Room "${code.toUpperCase()}" sudah digunakan. Pilih kode lain.` },
        { status: 400 }
      );
    }

    const newRoom = createRoom({
      adminId: (adminId || 'admin').trim().toLowerCase(),
      code: code.trim().toUpperCase(),
      name: name.trim(),
      description: description || '',
      pin: pin.trim(),
      status: 'active',
      prizes: prizes && prizes.length > 0 ? prizes : [
        { id: 'p1', name: 'Hadiah Utama', initialStock: 5, currentStock: 5, color: '#EF4444', weight: 10 },
        { id: 'p2', name: 'Merchandise Eksklusif', initialStock: 20, currentStock: 20, color: '#3B82F6', weight: 30 },
        { id: 'p3', name: 'Sticker & Pin Keren', initialStock: 50, currentStock: 50, color: '#10B981', weight: 60 }
      ],
      activeGames: activeGames || ['spinwheel', 'scratch', 'slot', 'gashapon', 'shake'],
    });

    return NextResponse.json({ success: true, room: newRoom });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
