import { NextRequest, NextResponse } from 'next/server';
import { getRoomByCode, findParticipantByWa } from '@/lib/db';

export async function POST(
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
    const { waNumber } = body;
    if (!waNumber) {
      return NextResponse.json({ success: false, error: 'Nomor WA wajib diisi' }, { status: 400 });
    }

    const participant = findParticipantByWa(room.id, waNumber);
    if (participant) {
      return NextResponse.json({
        success: true,
        alreadyPlayed: true,
        participant,
      });
    }

    return NextResponse.json({ success: true, alreadyPlayed: false });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
