import { NextRequest, NextResponse } from 'next/server';
import { getRoomByCode, registerAndSpin } from '@/lib/db';

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
    const {
      fullName,
      waNumber,
      waParentNumber,
      email,
      grade,
      schoolName,
      schoolCity,
      studyInterest,
      gamePlayed,
    } = body;

    // Validation
    if (!fullName || !waNumber || !waParentNumber || !email || !grade || !schoolName || !schoolCity || !studyInterest) {
      return NextResponse.json(
        { success: false, error: 'Semua 8 data registrasi wajib diisi' },
        { status: 400 }
      );
    }

    const result = registerAndSpin(room.id, {
      fullName: fullName.trim(),
      waNumber: waNumber.trim(),
      waParentNumber: waParentNumber.trim(),
      email: email.trim(),
      grade: grade.trim(),
      schoolName: schoolName.trim(),
      schoolCity: schoolCity.trim(),
      studyInterest: studyInterest.trim(),
      gamePlayed: gamePlayed || 'spinwheel',
    });

    if (!result.success) {
      return NextResponse.json(
        {
          success: false,
          error: result.error,
          alreadyPlayed: result.alreadyPlayed,
          lead: result.lead,
        },
        { status: result.alreadyPlayed ? 409 : 400 }
      );
    }

    return NextResponse.json({
      success: true,
      lead: result.lead,
    });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
