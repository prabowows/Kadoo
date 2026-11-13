import { NextRequest, NextResponse } from 'next/server';
import { getRoomByCode, getParticipantsByRoom } from '@/lib/db';

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

    if (pin !== room.pin) {
      return NextResponse.json({ success: false, error: 'PIN Admin tidak valid' }, { status: 403 });
    }

    const participants = getParticipantsByRoom(room.id);
    return NextResponse.json({
      success: true,
      roomName: room.name,
      roomCode: room.code,
      participants,
    });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
