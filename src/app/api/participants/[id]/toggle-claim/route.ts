import { NextRequest, NextResponse } from 'next/server';
import { toggleClaimStatus } from '@/lib/db';

export async function POST(
  req: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params;
    const updated = toggleClaimStatus(id);
    if (!updated) {
      return NextResponse.json({ success: false, error: 'Peserta tidak ditemukan' }, { status: 404 });
    }
    return NextResponse.json({ success: true, participant: updated });
  } catch (error) {
    return NextResponse.json({ success: false, error: String(error) }, { status: 500 });
  }
}
