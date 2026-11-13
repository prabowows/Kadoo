import { NextRequest, NextResponse } from 'next/server';
import { getRoomByCode, updateRoom, deleteRoom } from '@/lib/db';

export async function GET(
  req: NextRequest,
  { params }: { params: Promise<{ code: string }> }
) {
  try {
    const { code } = await params;
    const room = getRoomByCode(code);
    if (!room) {
      return NextResponse.json({ success: false, error: 'Room tidak ditemukan' }, { status: 404 });
    }

    const { searchParams } = new URL(req.url);
    const pin = searchParams.get('pin');

    // If matching PIN provided, return full room with admin data
    const isAdmin = pin === room.pin;

    return NextResponse.json({
      success: true,
      room: {
        id: room.id,
        code: room.code,
        name: room.name,
        description: room.description,
        status: room.status,
        activeGames: room.activeGames,
        createdAt: room.createdAt,
        // For players, provide prize names and colors (needed for wheel/game rendering)
        prizes: room.prizes.map((p) => ({
          id: p.id,
          name: p.name,
          color: p.color,
          available: p.currentStock > 0,
          ...(isAdmin ? { initialStock: p.initialStock, currentStock: p.currentStock, weight: p.weight } : {}),
        })),
        isAdmin,
      },
    });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}

export async function PUT(
  req: NextRequest,
  { params }: { params: Promise<{ code: string }> }
) {
  try {
    const { code } = await params;
    const room = getRoomByCode(code);
    if (!room) {
      return NextResponse.json({ success: false, error: 'Room tidak ditemukan' }, { status: 404 });
    }

    const body = await req.json();
    const { pin, name, prizes, activeGames, status, description } = body;

    if (pin !== room.pin) {
      return NextResponse.json({ success: false, error: 'PIN Admin tidak sesuai' }, { status: 403 });
    }

    const updated = updateRoom(room.id, {
      ...(name ? { name } : {}),
      ...(description !== undefined ? { description } : {}),
      ...(prizes ? { prizes } : {}),
      ...(activeGames ? { activeGames } : {}),
      ...(status ? { status } : {}),
    });

    return NextResponse.json({ success: true, room: updated });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}

export async function DELETE(
  req: NextRequest,
  { params }: { params: Promise<{ code: string }> }
) {
  try {
    const { code } = await params;
    const room = getRoomByCode(code);
    if (!room) {
      return NextResponse.json({ success: false, error: 'Room tidak ditemukan' }, { status: 404 });
    }

    const body = await req.json();
    if (body.pin !== room.pin) {
      return NextResponse.json({ success: false, error: 'PIN Admin tidak valid' }, { status: 403 });
    }

    deleteRoom(room.id);
    return NextResponse.json({ success: true, message: 'Room berhasil dihapus' });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
