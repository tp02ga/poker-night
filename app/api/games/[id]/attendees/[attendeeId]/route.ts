import { NextRequest, NextResponse } from "next/server";
import { PrismaClient } from "@prisma/client";
import { getUserIdFromToken } from "@/lib/auth";

const prisma = new PrismaClient();

export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string; attendeeId: string } }
) {
  const gameId = Number.parseInt(params.id);
  const attendeeId = Number.parseInt(params.attendeeId);
  const userId = await getUserIdFromToken(request);

  if (!userId) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  try {
    const game = await prisma.game.findUnique({
      where: { id: gameId },
      include: { host: true },
    });

    if (!game) {
      return NextResponse.json({ error: "Game not found" }, { status: 404 });
    }

    if (game.host.id !== userId) {
      return NextResponse.json(
        { error: "Only the host can remove attendees" },
        { status: 403 }
      );
    }

    await prisma.attendee.delete({
      where: { id: attendeeId },
    });

    // Check if there's someone on the waitlist to move up
    const waitlistAttendee = await prisma.attendee.findFirst({
      where: { gameId, waitlist: true },
      orderBy: { signedUpAt: "asc" },
    });

    if (waitlistAttendee) {
      await prisma.attendee.update({
        where: { id: waitlistAttendee.id },
        data: { waitlist: false },
      });
    }

    return NextResponse.json({ message: "Attendee removed successfully" });
  } catch (error) {
    console.error("Error removing attendee:", error);
    return NextResponse.json(
      { error: "Internal server error" },
      { status: 500 }
    );
  }
}
